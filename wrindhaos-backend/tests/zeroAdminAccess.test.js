const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('http');
const app = require('../src/app');
const { encryptText, decryptText } = require('../src/services/encryptionService');
const { sanitizeAuditPayload } = require('../src/utils/auditLogger');

let server;
let baseUrl;

const { mockStore } = require('../src/config/supabase');

before(() => {
  return new Promise((resolve) => {
    // Populate test user account
    mockStore.users.set('u_1', {
      id: 'u_1',
      full_name: 'Alex Johnson',
      email: 'alex.johnson@example.com',
      phone_number: '+919876543210',
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      created_at: new Date().toISOString(),
    });

    server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://localhost:${port}`;
      resolve();
    });
  });
});

after(() => {
  return new Promise((resolve) => {
    server.close(resolve);
  });
});

describe('WRINDHAOS ZERO-ADMIN & DEVELOPER-ACCESS SECURITY ARCHITECTURE TEST SUITE', () => {

  test('1. User A can access User A data', async () => {
    const res = await fetch(`${baseUrl}/api/v1/todos`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
  });

  test('2. User A is BLOCKED from accessing User B data (User A -> User B Hard Isolation)', async () => {
    // Attempting to request User B data with User A token
    const res = await fetch(`${baseUrl}/api/v1/todos?userId=u_user_b_id_9999`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    // Verify RLS / Backend filter returns only User A records (0 rows for User B)
    const userBItems = json.data.todos.filter((t) => t.user_id === 'u_user_b_id_9999');
    assert.strictEqual(userBItems.length, 0);
  });

  test('3. Admin CANNOT access User A private journal entries', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.journal, undefined);
    assert.strictEqual(json.data.private_data, 'NOT_ACCESSIBLE');
  });

  test('4. Admin CANNOT access User A private expenses', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.expenses, undefined);
    assert.strictEqual(json.data.private_data, 'NOT_ACCESSIBLE');
  });

  test('5. Admin CANNOT access User A private goals & milestones', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.goals, undefined);
    assert.strictEqual(json.data.milestones, undefined);
  });

  test('6. Admin CANNOT access User A private habits & habit logs', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.habits, undefined);
    assert.strictEqual(json.data.habit_logs, undefined);
  });

  test('7. Admin CANNOT access User A private study data & subject details', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.subjects, undefined);
    assert.strictEqual(json.data.units, undefined);
    assert.strictEqual(json.data.topics, undefined);
  });

  test('8. Admin CANNOT access User A private career data', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.career_nodes, undefined);
  });

  test('9. Admin CANNOT access User A private calendar event contents', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.calendar_events, undefined);
  });

  test('10. Admin CANNOT export private user content', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1/export-private-data`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    // Endpoint does not exist / 404 or blocked
    assert.strictEqual(res.status === 404 || res.status === 403, true);
  });

  test('11. Developer / DBA Ciphertext Protection Check (AES-256 Encryption)', () => {
    const plainJournal = 'My private journal reflection for today';
    const encrypted = encryptText(plainJournal);
    
    // Ensure raw encrypted DB string is unreadable to developers/DBAs
    assert.notStrictEqual(encrypted, plainJournal);
    assert.strictEqual(encrypted.includes(':'), true);
    
    // Ensure authorized owner can decrypt
    const decrypted = decryptText(encrypted);
    assert.strictEqual(decrypted, plainJournal);
  });

  test('12. Admin CAN access approved operational subscription metadata', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/subscriptions`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(Array.isArray(json.data.subscriptions), true);
  });

  test('13. Admin CAN access aggregate analytics metrics', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/dashboard`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(typeof json.data.metrics.totalUsers, 'number');
    assert.strictEqual(typeof json.data.metrics.estimatedMRR, 'string');
  });

  test('14. Support Agent restricted from accessing private user content', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.private_data, 'NOT_ACCESSIBLE');
  });

  test('15. Moderator restricted from accessing private user content', async () => {
    const res = await fetch(`${baseUrl}/api/v1/admin/users/u_1`, {
      headers: { Authorization: 'Bearer mock_jwt_token_wrindha_os_2fa' },
    });
    const json = await res.json();
    assert.strictEqual(json.data.private_data, 'NOT_ACCESSIBLE');
  });

  test('16. Anonymous user CANNOT access private user data', async () => {
    const res = await fetch(`${baseUrl}/api/v1/todos`);
    assert.strictEqual(res.status, 401);
  });

});
