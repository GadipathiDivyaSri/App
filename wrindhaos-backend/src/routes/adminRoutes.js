const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { authorizeAdminPermission } = require('../middleware/adminAuthMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

router.use(authenticateUser);

// Operational Dashboard & Accounts (No Private User Content Access)
router.get('/dashboard', authorizeAdminPermission('READ_AGGREGATE_ANALYTICS'), adminController.getAdminDashboardStats);
router.get('/users', authorizeAdminPermission('READ_ACCOUNT_METADATA'), adminController.getUsersList);
router.get('/users/:id', authorizeAdminPermission('READ_ACCOUNT_METADATA'), adminController.getUserDetails);

// Account Moderation & Plan Overrides
router.patch('/users/:id/override-plan', authorizeAdminPermission('MANAGE_USER_STATUS'), validateBody(['plan']), adminController.overrideUserPlan);
router.post('/users/:id/ban', authorizeAdminPermission('MANAGE_USER_STATUS'), adminController.banUserAccount);
router.post('/users/:id/unban', authorizeAdminPermission('MANAGE_USER_STATUS'), adminController.unbanUserAccount);

// Operational Subscriptions Monitor & Audit Logs
router.get('/subscriptions', authorizeAdminPermission('READ_SUBSCRIPTION_METADATA'), adminController.getSubscriptionsList);
router.get('/audit-logs', authorizeAdminPermission('MANAGE_ADMINS'), adminController.getAdminAuditLogs);

// System App Settings & Feature Flags
router.get('/settings', authorizeAdminPermission('MANAGE_APP_SETTINGS'), adminController.getAppSettings);
router.patch('/settings', authorizeAdminPermission('MANAGE_APP_SETTINGS'), adminController.updateAppSettings);

module.exports = router;
