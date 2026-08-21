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
const expenseRoutes = require('./routes/expenseRoutes');
const referralRoutes = require('./routes/referralRoutes');

const app = express();

// Security Middlewares (Configured to allow inline styles/scripts for admin portal)
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(generalRateLimiter);

// Serve Admin Web Portal Static Files
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));

// Serve WrindhaOS Flutter Web Application Assets with no-cache headers to ensure immediate live updates
const webAppPath = path.join(__dirname, '../../build/web');
const staticOptions = {
  etag: false,
  maxAge: 0,
  setHeaders: (res) => {
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
  },
};
app.use('/app', express.static(webAppPath, staticOptions));
app.use(express.static(webAppPath, staticOptions));

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
app.use('/api/v1/expenses', expenseRoutes);
app.use('/api/v1/referrals', referralRoutes);

// Compatibility aliases for /api/...
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks', todoRoutes);
app.use('/api/todos', todoRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/calendar', calendarRoutes);

// SPA Web App & Admin Portal HTML Route Fallback
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/admin') && req.accepts('html')) {
    return res.sendFile(path.join(__dirname, '../public/admin/index.html'));
  }
  if (!req.path.startsWith('/api') && req.accepts('html')) {
    return res.sendFile(path.join(webAppPath, 'index.html'));
  }
  next();
});

// Fallback 404 Route Handler for API requests
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
