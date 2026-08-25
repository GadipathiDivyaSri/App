const { sendError } = require('../utils/response');

/**
 * Approved Administrative Roles
 */
const ADMIN_ROLES = new Set(['SUPER_ADMIN', 'ADMIN', 'SUPPORT_AGENT', 'MODERATOR']);

/**
 * Allowed Non-Private Operational Admin Permissions
 */
const ALLOWED_ADMIN_PERMISSIONS = new Set([
  'READ_ACCOUNT_METADATA',
  'READ_SUBSCRIPTION_METADATA',
  'READ_AGGREGATE_ANALYTICS',
  'MANAGE_SUPPORT_TICKETS',
  'MANAGE_USER_STATUS',
  'MANAGE_APP_SETTINGS',
  'MANAGE_ADMINS',
]);

/**
 * Forbidden Private Permissions (Must NEVER be granted or allowed)
 */
const FORBIDDEN_PRIVATE_PERMISSIONS = new Set([
  'ALL',
  'READ_ALL',
  'FULL_DATABASE_ACCESS',
  'VIEW_USER_DATA',
  'READ_JOURNAL',
  'READ_EXPENSES',
  'READ_GOALS',
  'READ_HABITS',
  'READ_STUDY_DATA',
  'READ_CAREER_DATA',
  'READ_CALENDAR',
  'READ_TASKS',
  'READ_PRIVATE_CONTENT',
]);

/**
 * Strict Server Authorization Middleware for Administrative Operations
 * @param {string} requiredPermission - Explicit operational permission required
 */
function authorizeAdminPermission(requiredPermission) {
  return (req, res, next) => {
    // 1. Ensure user is authenticated
    if (!req.user || !req.user.id) {
      return sendError(res, 'Authentication required for administrative endpoints.', 'UNAUTHORIZED', 401);
    }

    // 2. Ensure user possesses an approved administrative role
    const userRole = req.user.role;
    if (!userRole || !ADMIN_ROLES.has(userRole)) {
      return sendError(res, 'Access denied: Administrative privileges required.', 'FORBIDDEN_ROLE', 403);
    }

    // 3. Reject any attempt to request forbidden private permissions
    if (FORBIDDEN_PRIVATE_PERMISSIONS.has(requiredPermission)) {
      return sendError(
        res,
        'Security Violation: Access to private user content is strictly prohibited by Zero-Admin-Access architecture.',
        'FORBIDDEN_PRIVATE_ACCESS',
        403
      );
    }

    // 4. Ensure required permission is an approved operational permission
    if (!ALLOWED_ADMIN_PERMISSIONS.has(requiredPermission)) {
      return sendError(res, 'Invalid operational administrative permission specified.', 'INVALID_PERMISSION', 403);
    }

    // 5. Verify Active Account Status
    const isActive = req.user.is_active ?? true;
    if (!isActive) {
      return sendError(res, 'Administrator account is deactivated.', 'ACCOUNT_DEACTIVATED', 403);
    }

    // Attach verified admin context
    req.admin = {
      id: req.user.id,
      role: userRole,
      permissionGranted: requiredPermission,
    };

    next();
  };
}

module.exports = {
  authorizeAdminPermission,
  ADMIN_ROLES,
  ALLOWED_ADMIN_PERMISSIONS,
  FORBIDDEN_PRIVATE_PERMISSIONS,
};
