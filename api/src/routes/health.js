const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'catalog-api',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    cagent_endpoint: process.env.CAGENT_API_URL
  });
});

module.exports = router;
