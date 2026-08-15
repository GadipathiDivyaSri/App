const crypto = require('crypto');
const config = require('../config/env');

const ALGORITHM = 'aes-256-gcm';
// Derives 32-byte encryption key from environment JWT secret or master key
const ENCRYPTION_KEY = crypto.scryptSync(config.jwt.secret || 'wrindhaos_master_security_key_2026', 'wrindhaos_salt', 32);

/**
 * Encrypt Sensitive User Free-Text Field (AES-256-GCM)
 * Produces encrypted hex string for zero-read developer protection
 * @param {string} text Plaintext content
 * @returns {string} Encrypted ciphertext token
 */
function encryptText(text) {
  if (!text || typeof text !== 'string') return text;
  
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag().toString('hex');
  
  // Format: iv:authTag:encryptedCiphertext
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

/**
 * Decrypt Sensitive User Free-Text Field for Authorized Owner
 * @param {string} cipherText Encrypted ciphertext token
 * @returns {string} Plaintext content
 */
function decryptText(cipherText) {
  if (!cipherText || typeof cipherText !== 'string' || !cipherText.includes(':')) return cipherText;

  try {
    const parts = cipherText.split(':');
    if (parts.length !== 3) return cipherText;

    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encrypted = parts[2];

    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    // If text was not encrypted with this algorithm, return as is
    return cipherText;
  }
}

module.exports = {
  encryptText,
  decryptText,
};
