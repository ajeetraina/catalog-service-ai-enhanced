import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { Pool } from 'pg';
import { Kafka } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connection
const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL || 
    'postgresql://postgres:postgres@localhost:5432/catalog_db',
});

// Kafka setup
const kafka = new Kafka({
  clientId: 'catalog-service',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
});

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM products LIMIT 100');
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Catalog API running on port ${PORT}`);
});
