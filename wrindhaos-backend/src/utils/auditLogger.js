const { supabaseAdmin, mockStore } = require('../config/supabase');
const logger = require('./logger');

const SENSITIVE_KEYS = new Set([
  'password',
  'otp',
  'token',
  'jwt',
  'body_content',
  'journal',
  'journal_entries',
  'expense_details',
  'notes',
  'description',
  'goal_title',
  'habit_title',
]);

/**
 * Sanitize details payload to redact sensitive private user fields
 */
function sanitizeAuditPayload(details) {
  if (!details || typeof details !== 'object') return details;
  
  const sanitized = {};
  for (const [key, val] of Object.entries(details)) {
    if (SENSITIVE_KEYS.has(key.toLowerCase())) {
      sanitized[key] = '[REDACTED_PRIVATE_CONTENT]';
    } else if (val && typeof val === 'object' && !Array.isArray(val)) {
      sanitized[key] = sanitizeAuditPayload(val);
    } else {
      sanitized[key] = val;
    }
  }
  return sanitized;
}

/**
 * Record Audit Log Event (Sanitized & Redacted)
 */
async function logAuditEvent(userId, eventType, details = {}, ipAddress = null) {
  try {
    const cleanDetails = sanitizeAuditPayload(details);

    const auditRecord = {
      user_id: userId || null,
      event_type: eventType,
      details: cleanDetails,
      ip_address: ipAddress,
      created_at: new Date().toISOString(),
    };

    if (supabaseAdmin) {
      await supabaseAdmin.from('audit_logs').insert(auditRecord);
    } else {
      mockStore.auditLogs.push(auditRecord);
    }

    logger.info(`[AUDIT LOG] ${eventType}`, { userId, ipAddress });
  } catch (err) {
    logger.error('Failed to log audit event', err, { eventType, userId });
  }
}

module.exports = {
  logAuditEvent,
  sanitizeAuditPayload,
};
