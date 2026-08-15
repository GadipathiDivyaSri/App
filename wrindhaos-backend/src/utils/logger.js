/**
 * Secure Logging Helper (Redacts OTPs and sensitive fields)
 */
function info(message, meta = {}) {
  const sanitizedMeta = redactSensitiveFields(meta);
  console.log(`[INFO] ${new Date().toISOString()} - ${message}`, Object.keys(sanitizedMeta).length ? sanitizedMeta : '');
}

function warn(message, meta = {}) {
  const sanitizedMeta = redactSensitiveFields(meta);
  console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, Object.keys(sanitizedMeta).length ? sanitizedMeta : '');
}

function error(message, err = {}, meta = {}) {
  const sanitizedMeta = redactSensitiveFields(meta);
  console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, err.message || err, Object.keys(sanitizedMeta).length ? sanitizedMeta : '');
}

function redactSensitiveFields(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  const clone = { ...obj };
  const sensitiveKeys = ['otp', 'code', 'password', 'privateKey', 'serviceAccountKey', 'purchaseToken'];

  for (const key of Object.keys(clone)) {
    if (sensitiveKeys.some(sk => key.toLowerCase().includes(sk.toLowerCase()))) {
      clone[key] = '[REDACTED]';
    } else if (typeof clone[key] === 'object') {
      clone[key] = redactSensitiveFields(clone[key]);
    }
  }
  return clone;
}

module.exports = {
  info,
  warn,
  error,
};
