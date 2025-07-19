// Comprehensive test suite for the Node.js application
const request = require('supertest');
const app = require('../src/server');

// Test suite for main application endpoints
describe('Jenkins Docker Demo Application', () => {
  
  // Test root endpoint
  describe('GET /', () => {
    it('should return application information', async () => {
      const response = await request(app)
        .get('/')
        .expect(200)
        .expect('Content-Type', /json/);
      
      // Verify response structure
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('application', 'jenkins-docker-demo');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('build');
      expect(response.body).toHaveProperty('server');
      expect(response.body).toHaveProperty('docker');
    });
    
    it('should include build information', async () => {
      const response = await request(app).get('/');
      
      expect(response.body.build).toHaveProperty('number');
      expect(response.body.build).toHaveProperty('timestamp');
      expect(response.body.build).toHaveProperty('environment');
    });
  });
  
  // Test health check endpoint
  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200)
        .expect('Content-Type', /json/);
      
      expect(response.body).toHaveProperty('status');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('checks');
    });
    
    it('should include system checks', async () => {
      const response = await request(app).get('/health');
      
      expect(response.body.checks).toHaveProperty('memory');
      expect(response.body.checks).toHaveProperty('cpu');
      expect(response.body.checks).toHaveProperty('platform');
    });
  });
  
  // Test readiness endpoint
  describe('GET /ready', () => {
    it('should return readiness status', async () => {
      const response = await request(app)
        .get('/ready')
        .expect(200)
        .expect('Content-Type', /json/);
      
      expect(response.body).toHaveProperty('status', 'ready');
      expect(response.body).toHaveProperty('services');
    });
    
    it('should include service status', async () => {
      const response = await request(app).get('/ready');
      
      expect(response.body.services).toHaveProperty('database');
      expect(response.body.services).toHaveProperty('cache');
      expect(response.body.services).toHaveProperty('external_api');
    });
  });
  
  // Test metrics endpoint
  describe('GET /metrics', () => {
    it('should return application metrics', async () => {
      const response = await request(app)
        .get('/metrics')
        .expect(200)
        .expect('Content-Type', /json/);
      
      expect(response.body).toHaveProperty('requests_total');
      expect(response.body).toHaveProperty('memory_usage_mb');
      expect(response.body).toHaveProperty('uptime_seconds');
    });
  });
  
  // Test API info endpoint
  describe('GET /api/info', () => {
    it('should return API information', async () => {
      const response = await request(app)
        .get('/api/info')
        .expect(200)
        .expect('Content-Type', /json/);
      
      expect(response.body).toHaveProperty('api_version');
      expect(response.body).toHaveProperty('endpoints');
      expect(Array.isArray(response.body.endpoints)).toBe(true);
    });
  });
  
  // Test 404 handling
  describe('GET /nonexistent', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app)
        .get('/nonexistent')
        .expect(404)
        .expect('Content-Type', /json/);
      
      expect(response.body).toHaveProperty('error', 'Not Found');
    });
  });
});