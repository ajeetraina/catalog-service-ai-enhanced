import express from 'express';
import cors from 'cors';
import axios from 'axios';
import { MongoClient } from 'mongodb';
import { Kafka } from 'kafkajs';
import dotenv from 'dotenv';
import SecurityMiddleware from './security-middleware.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 7777;

app.use(cors());
app.use(express.json());

// Initialize security middleware
const security = new SecurityMiddleware();

// Rate limiting middleware (simple in-memory store)
const rateLimitStore = new Map();
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX = parseInt(process.env.RATE_LIMIT_RPM) || 60;

function rateLimitMiddleware(req, res, next) {
  const key = req.ip || 'unknown';
  const now = Date.now();
  
  if (!rateLimitStore.has(key)) {
    rateLimitStore.set(key, []);
  }
  
  const requests = rateLimitStore.get(key);
  
  // Remove old requests outside the window
  const validRequests = requests.filter(time => now - time < RATE_LIMIT_WINDOW);
  
  if (validRequests.length >= RATE_LIMIT_MAX) {
    return res.status(429).json({
      success: false,
      error: 'Rate limit exceeded',
      details: {
        limit: RATE_LIMIT_MAX,
        window_ms: RATE_LIMIT_WINDOW,
        current_count: validRequests.length
      }
    });
  }
  
  validRequests.push(now);
  rateLimitStore.set(key, validRequests);
  
  console.log(`📊 Rate limit: ${validRequests.length}/${RATE_LIMIT_MAX} for ${key}`);
  next();
}

// MongoDB connection
const mongoClient = new MongoClient(
  process.env.MONGODB_URL || 'mongodb://admin:admin@mongodb:27017/agent_history?authSource=admin'
);

// Docker Model Runner configuration
const modelRunnerUrl = process.env.MODEL_RUNNER_URL || 'http://model-runner.docker.internal';
const defaultModel = process.env.MODEL_RUNNER_MODEL || process.env.AI_DEFAULT_MODEL || 'ai/llama3.2:latest';

console.log('🤖 Agent Service Configuration:');
console.log(`   Model Runner URL: ${modelRunnerUrl}`);
console.log(`   Default Model: ${defaultModel}`);
console.log(`   Security Enabled: ${process.env.MCP_SECURITY_ENABLED}`);

// Kafka setup
const kafka = new Kafka({
  clientId: 'agent-service',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
});

let producer;
try {
  producer = kafka.producer();
} catch (error) {
  console.warn('⚠️ Kafka producer initialization failed:', error.message);
}

// Configuration
const VENDOR_EVALUATION_THRESHOLD = parseInt(process.env.VENDOR_EVALUATION_THRESHOLD) || 70;

// Import the original evaluation logic
const originalAppModule = await import('./app.js');

// Routes with interceptors
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    model_runner_url: modelRunnerUrl,
    model: defaultModel,
    threshold: VENDOR_EVALUATION_THRESHOLD,
    security_enabled: process.env.MCP_SECURITY_ENABLED === 'true',
    interceptors: {
      security: process.env.MCP_SECURITY_ENABLED === 'true',
      rate_limiting: true,
      audit: process.env.MCP_AUDIT_ENABLED === 'true'
    }
  });
});

// Protected evaluation endpoint with interceptors
app.post('/products/evaluate', 
  rateLimitMiddleware,
  security.validateRequest.bind(security),
  async (req, res) => {
    const startTime = Date.now();
    console.log('\n📝 New product evaluation request (WITH INTERCEPTORS):', JSON.stringify(req.body, null, 2));
    
    try {
      const product = req.body;
      
      // Validate required fields
      if (!product.productName || !product.description) {
        const errorResult = {
          success: false,
          error: 'Missing required fields: productName and description are required'
        };
        
        // Log audit
        await security.logAudit(req, res, errorResult);
        
        return res.status(400).json(errorResult);
      }
      
      // Create comprehensive evaluation prompt
      const evaluationPrompt = `You are an expert product evaluator for an AI-enhanced e-commerce catalog service.

Evaluate this product submission and respond with a JSON object in exactly this format:

{
  "score": <number between 0-100>,
  "decision": "APPROVED" or "REJECTED",
  "reasoning": "<detailed explanation of the evaluation>",
  "category_match": "<assessment of how well the product fits its category>",
  "market_potential": "High" or "Medium" or "Low"
}

Product Details:
- Vendor: ${product.vendorName}
- Product Name: ${product.productName}
- Description: ${product.description}
- Price: $${product.price}
- Category: ${product.category || 'Not specified'}

Evaluation Criteria (100 points total):
- Product innovation and quality (25 points)
- Market demand and competitiveness (25 points)
- Description clarity and completeness (20 points)
- Price appropriateness for market (15 points)
- Vendor credibility indicators (15 points)

Minimum passing score: ${VENDOR_EVALUATION_THRESHOLD}/100

Important: Respond ONLY with the JSON object, no additional text before or after.`;

      const messages = [
        {
          role: 'system',
          content: 'You are a professional product evaluation AI. Always respond with valid JSON in the exact format requested. Do not include any text outside the JSON object.'
        },
        {
          role: 'user',
          content: evaluationPrompt
        }
      ];
      
      // Call Docker Model Runner (import the function from original app.js)
      const callModel = originalAppModule.callModel;
      const parseEvaluation = originalAppModule.parseEvaluation;
      
      const aiResponse = await callModel(messages);
      
      // Parse and validate evaluation
      const evaluation = parseEvaluation(aiResponse, product);
      evaluation.processing_time_ms = Date.now() - startTime;
      evaluation.intercepted = true;
      evaluation.security_score = req.security?.risk_score || 0;
      
      console.log(`🎯 AI Evaluation Result (WITH INTERCEPTORS):`);
      console.log(`   Score: ${evaluation.score}/100`);
      console.log(`   Decision: ${evaluation.decision}`);
      console.log(`   Security Risk: ${evaluation.security_score}`);
      console.log(`   Processing Time: ${evaluation.processing_time_ms}ms`);
      
      // Store in MongoDB (optional)
      try {
        await mongoClient.connect();
        const db = mongoClient.db('agent_history');
        await db.collection('evaluations').insertOne({
          product,
          evaluation,
          raw_ai_response: aiResponse,
          timestamp: new Date(),
          agent_version: '2.0-with-interceptors',
          security: req.security
        });
        console.log('💾 Evaluation stored in MongoDB');
      } catch (dbError) {
        console.warn('⚠️ MongoDB storage failed (continuing):', dbError.message);
      }
      
      // Publish to Kafka (optional)
      try {
        if (producer) {
          await producer.send({
            topic: 'product-evaluations',
            messages: [{
              key: product.productName || 'unknown',
              value: JSON.stringify({
                product,
                evaluation,
                timestamp: new Date().toISOString(),
                intercepted: true
              })
            }]
          });
          console.log('📡 Evaluation published to Kafka');
        }
      } catch (kafkaError) {
        console.warn('⚠️ Kafka publish failed (continuing):', kafkaError.message);
      }
      
      // Return successful evaluation
      const result = {
        success: true,
        evaluation,
        metadata: {
          processing_time_ms: evaluation.processing_time_ms,
          agent: 'agent-service-with-interceptors-v2.0',
          model: defaultModel,
          endpoint: modelRunnerUrl,
          timestamp: new Date().toISOString(),
          intercepted: true,
          security: req.security
        }
      };
      
      // Log audit
      await security.logAudit(req, res, result);
      
      res.json(result);
      
    } catch (error) {
      console.error('❌ Evaluation failed:', error);
      
      // Return error with fallback evaluation
      const processingTime = Date.now() - startTime;
      
      const errorResult = {
        success: false,
        error: error.message,
        fallback_evaluation: {
          score: 75,
          decision: 'APPROVED',
          reasoning: 'Automatic approval due to AI service error - manual review recommended',
          category_match: 'Unable to assess due to system error',
          market_potential: 'Medium',
          error: true,
          evaluation_method: 'error_fallback',
          processing_time_ms: processingTime
        },
        metadata: {
          error_occurred: true,
          timestamp: new Date().toISOString(),
          suggested_action: 'Check Docker Model Runner service and try again',
          intercepted: true
        }
      };
      
      // Log audit
      await security.logAudit(req, res, errorResult);
      
      res.status(500).json(errorResult);
    }
  }
);

// Import other routes from original app.js
app.get('/agents', originalAppModule.getAgents);
app.get('/test-model-runner', originalAppModule.testModelRunner);
app.post('/test-evaluation', originalAppModule.testEvaluation);

// Graceful startup
async function start() {
  try {
    console.log('\n🚀 Starting Agent Service WITH INTERCEPTORS...');
    
    // Connect to MongoDB (optional)
    try {
      await mongoClient.connect();
      console.log('✅ MongoDB connected');
    } catch (error) {
      console.warn('⚠️ MongoDB connection failed (continuing without it):', error.message);
    }
    
    // Connect to Kafka (optional)
    try {
      if (producer) {
        await producer.connect();
        console.log('✅ Kafka producer connected');
      }
    } catch (error) {
      console.warn('⚠️ Kafka connection failed (continuing without it):', error.message);
    }
    
    // Start server
    app.listen(PORT, () => {
      console.log('\n' + '='.repeat(80));
      console.log(`🛡️  Agent Service WITH INTERCEPTORS READY`);
      console.log(`🌐 Server: http://localhost:${PORT}`);
      console.log(`🧠 AI Model: ${defaultModel}`);
      console.log(`🔗 Model Runner: ${modelRunnerUrl}`);
      console.log(`📊 Evaluation threshold: ${VENDOR_EVALUATION_THRESHOLD}/100`);
      console.log(`🛡️  Security: ${process.env.MCP_SECURITY_ENABLED === 'true' ? 'ENABLED' : 'DISABLED'}`);
      console.log(`🔧 Test endpoint: GET http://localhost:${PORT}/test-model-runner`);
      console.log(`🎯 Evaluation endpoint: POST http://localhost:${PORT}/products/evaluate`);
      console.log('='.repeat(80));
    });
    
  } catch (error) {
    console.error('💥 Failed to start Agent Service:', error);
    process.exit(1);
  }
}

start().catch(console.error);
