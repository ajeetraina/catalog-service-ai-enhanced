const express = require('express');
const { createCagentClient } = require('../services/cagent-client');
const router = express.Router();

const cagentClient = createCagentClient();

// Get agent health status
router.get('/health', async (req, res) => {
  try {
    const health = await cagentClient.getHealthStatus();
    res.json({
      success: true,
      data: health
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get agent health',
      error: error.message
    });
  }
});

// Get agent information
router.get('/info', async (req, res) => {
  try {
    const info = await cagentClient.getAgentInfo();
    res.json({
      success: true,
      data: info
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get agent info',
      error: error.message
    });
  }
});

module.exports = router;
