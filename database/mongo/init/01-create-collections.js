// Initialize MongoDB collections for agent history and analytics

db = db.getSiblingDB('agent_history');

// Create evaluations collection with indexes
db.createCollection('evaluations');
db.evaluations.createIndex({ "request_id": 1 }, { unique: true });
db.evaluations.createIndex({ "timestamp": -1 });
db.evaluations.createIndex({ "product_data.category": 1 });
db.evaluations.createIndex({ "evaluation_result.decision": 1 });
db.evaluations.createIndex({ "evaluation_result.score": -1 });

// Create product_status_changes collection
db.createCollection('product_status_changes');
db.product_status_changes.createIndex({ "product_id": 1 });
db.product_status_changes.createIndex({ "timestamp": -1 });

// Create agent_performance collection
db.createCollection('agent_performance');
db.agent_performance.createIndex({ "agent_name": 1, "timestamp": -1 });

// Insert sample evaluation record
db.evaluations.insertOne({
    request_id: "sample_eval_001",
    product_data: {
        vendorName: "NVIDIA",
        productName: "Jetson Nano Developer Kit",
        description: "AI development board for edge computing",
        price: 199.0,
        category: "Electronics"
    },
    evaluation_result: {
        score: 87,
        decision: "APPROVED",
        reasoning: "Strong technical specifications with competitive pricing",
        confidence_level: 0.92
    },
    processing_time_ms: 3200,
    timestamp: new Date(),
    source: "setup_script"
});

print("MongoDB collections and indexes created successfully");
