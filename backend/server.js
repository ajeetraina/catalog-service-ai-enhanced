const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

let products = [];
let productId = 1;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/api/products', (req, res) => {
  res.json({ products });
});

app.post('/api/products', (req, res) => {
  const { name, description, price, vendor } = req.body;
  const product = {
    id: productId++,
    name,
    description,
    price,
    vendor,
    ai_score: Math.floor(Math.random() * 30) + 70,
    created_at: new Date()
  };
  products.push(product);
  res.json({ success: true, product });
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});
