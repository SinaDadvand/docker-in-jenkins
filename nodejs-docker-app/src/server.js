// Main application server with comprehensive functionality
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// Create Express application instance
const app = express();

// Get port from environment variable or default to 3000
const port = process.env.PORT || 3000;

// Get application configuration from environment
const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  appVersion: process.env.APP_VERSION || '1.0.0',
  buildNumber: process.env.BUILD_NUMBER || 'unknown',
  buildTimestamp: process.env.BUILD_TIMESTAMP || new Date().toISOString()
};

// Middleware setup
app.use(helmet());           // Security headers
app.use(cors());            // Enable CORS
app.use(morgan('combined')); // Request logging
app.use(express.json());    // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Root endpoint - Main application information
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Jenkins Docker Demo!',
    application: 'jenkins-docker-demo',
    version: config.appVersion,
    build: {
      number: config.buildNumber,
      timestamp: config.buildTimestamp,
      environment: config.nodeEnv
    },
    server: {
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      pid: process.pid,
      memory: process.memoryUsage(),
      platform: process.platform,
      nodeVersion: process.version
    },
    docker: {
      containerized: process.env.RUNNING_IN_DOCKER === 'true',
      hostname: process.env.HOSTNAME || 'unknown'
    }
  });
});

// Health check endpoint - Essential for container orchestration
app.get('/health', (req, res) => {
  const healthCheck = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: config.appVersion,
    build: config.buildNumber,
    checks: {
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      platform: process.platform
    }
  };
  
  // Simulate health check logic
  const memoryUsage = process.memoryUsage().rss / 1024 / 1024; // MB
  if (memoryUsage > 500) { // Alert if using more than 500MB
    healthCheck.status = 'warning';
    healthCheck.warnings = ['High memory usage'];
  }
  
  res.status(200).json(healthCheck);
});

// Readiness endpoint - Kubernetes readiness probe
app.get('/ready', (req, res) => {
  // Check if application is ready to serve traffic
  const readinessCheck = {
    status: 'ready',
    timestamp: new Date().toISOString(),
    services: {
      database: 'connected',  // Simulated
      cache: 'connected',     // Simulated
      external_api: 'available' // Simulated
    }
  };
  
  res.status(200).json(readinessCheck);
});

// Metrics endpoint - For monitoring and observability
app.get('/metrics', (req, res) => {
  const metrics = {
    requests_total: Math.floor(Math.random() * 1000),
    requests_per_second: Math.floor(Math.random() * 50),
    response_time_avg: Math.floor(Math.random() * 100) + 50,
    memory_usage_mb: Math.floor(process.memoryUsage().rss / 1024 / 1024),
    cpu_usage_percent: Math.floor(Math.random() * 50) + 10,
    uptime_seconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString()
  };
  
  res.json(metrics);
});

// API endpoint for testing - Returns build information
app.get('/api/info', (req, res) => {
  res.json({
    api_version: 'v1',
    build_info: config,
    endpoints: [
      { path: '/', method: 'GET', description: 'Application information' },
      { path: '/health', method: 'GET', description: 'Health check' },
      { path: '/ready', method: 'GET', description: 'Readiness check' },
      { path: '/metrics', method: 'GET', description: 'Application metrics' },
      { path: '/api/info', method: 'GET', description: 'API information' }
    ]
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error occurred:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: config.nodeEnv === 'development' ? err.message : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// 404 handler for unknown routes
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    timestamp: new Date().toISOString()
  });
});

// Start server
const server = app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Jenkins Docker Demo server starting...`);
  console.log(`📊 Environment: ${config.nodeEnv}`);
  console.log(`🏷️  Version: ${config.appVersion}`);
  console.log(`🔢 Build: ${config.buildNumber}`);
  console.log(`⏰ Build Time: ${config.buildTimestamp}`);
  console.log(`🌐 Server running on port ${port}`);
  console.log(`🔗 Access at: http://localhost:${port}`);
  console.log(`💓 Health check: http://localhost:${port}/health`);
  console.log(`✅ Ready check: http://localhost:${port}/ready`);
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed successfully');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed successfully');
    process.exit(0);
  });
});

// Export app for testing
module.exports = app;