const request = require('supertest');
const app = require('../../api/src/app');

describe('API Integration Tests', () => {
  test('Health endpoint should return status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('healthy');
    expect(response.body.service).toBe('catalog-api');
  });

  test('Product evaluation should work', async () => {
    const productData = {
      vendorName: 'Test Vendor',
      productName: 'Test Product',
      description: 'A test product for integration testing',
      price: 99.99,
      category: 'Electronics'
    };

    const response = await request(app)
      .post('/api/products/evaluate')
      .send(productData)
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.score).toBeDefined();
    expect(response.body.data.decision).toBeDefined();
  }, 30000); // 30 second timeout for AI processing

  test('Agent health endpoint should return status', async () => {
    const response = await request(app)
      .get('/api/agents/health')
      .expect(200);
    
    expect(response.body.success).toBe(true);
  });
});
