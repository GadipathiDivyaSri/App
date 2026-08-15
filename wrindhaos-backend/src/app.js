const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const { generalRateLimiter } = require('./middleware/rateLimitMiddleware');
const { globalErrorHandler } = require('./middleware/errorMiddleware');

// Route Imports
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const todoRoutes = require('./routes/todoRoutes');
const habitRoutes = require('./routes/habitRoutes');
const subjectRoutes = require('./routes/subjectRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const eisenhowerRoutes = require('./routes/eisenhowerRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes');
const entitlementRoutes = require('./routes/entitlementRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');
const userPrivacyRoutes = require('./routes/userPrivacyRoutes');

const app = express();

// Security Middlewares (Configured to allow inline styles/scripts for admin portal)
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(generalRateLimiter);

// Serve Admin Web Portal Static Files
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));

// Health Check Endpoint (Render & Monitoring)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'WrindhaOS Backend & Admin Engine',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Swagger Documentation Schema Endpoint
const swaggerSchema = require('../swagger.json');
app.get('/api-docs', (req, res) => {
  res.json(swaggerSchema);
});

// API Version 1 Routes (/api/v1/)
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/todos', todoRoutes);
app.use('/api/v1/habits', habitRoutes);
app.use('/api/v1/subjects', subjectRoutes);
app.use('/api/v1/calendar', calendarRoutes);
app.use('/api/v1/eisenhower', eisenhowerRoutes);
app.use('/api/v1/subscriptions', subscriptionRoutes);
app.use('/api/v1/entitlements', entitlementRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/privacy', userPrivacyRoutes);

// Fallback 404 Route Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: `The requested endpoint ${req.method} ${req.originalUrl} does not exist on WrindhaOS API.`,
    },
  });
});

// Centralized Error Handling Middleware
app.use(globalErrorHandler);

module.exports = app;
