const http = require('http');
const url = require('url');
const { mockDB } = require('./supabase_config');
const { send2FAOTP, verify2FAOTP, verifyGoogleToken } = require('./services/auth_2fa');
const { sendFCMPushNotification, processAdMobReward } = require('./services/fcm_notifications');

const PORT = process.env.PORT || 3000;

// Helper to send JSON responses with CORS headers
function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data));
}

// Parse request body JSON
function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk.toString()));
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        resolve({});
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const method = req.method.toUpperCase();

  // Handle CORS Preflight
  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  const body = method === 'POST' || method === 'PATCH' || method === 'DELETE' ? await parseBody(req) : {};

  // ---------------------------------------------------------------------------
  // ROUTES
  // ---------------------------------------------------------------------------

  // Health Check
  if (path === '/api/health' && method === 'GET') {
    return sendJSON(res, 200, {
      status: 'ONLINE',
      app: 'Wrindha OS Backend API Service',
      stack: 'Node.js Native HTTP + Supabase + 2FA OTP + FCM + AdMob',
      timestamp: new Date().toISOString(),
    });
  }

  // Auth: Trigger 2FA OTP
  if (path === '/api/auth/send-otp' && method === 'POST') {
    const { contact } = body;
    if (!contact) {
      return sendJSON(res, 400, { success: false, message: 'Contact address/phone required.' });
    }
    const result = send2FAOTP(contact);
    return sendJSON(res, 200, result);
  }

  // Auth: Verify 2FA OTP
  if (path === '/api/auth/verify-otp' && method === 'POST') {
    const { contact, code } = body;
    if (!contact || !code) {
      return sendJSON(res, 400, { success: false, message: 'Contact and OTP code required.' });
    }
    const result = verify2FAOTP(contact, code);
    return sendJSON(res, 200, result);
  }

  // Auth: Google SSO
  if (path === '/api/auth/google' && method === 'POST') {
    const { googleToken } = body;
    const result = verifyGoogleToken(googleToken || 'demo_google_token');
    return sendJSON(res, 200, result);
  }

  // Auth / User: Permanently Delete Account and Data
  if ((path === '/api/user/delete-account' || path === '/api/auth/delete-account' || path === '/api/users/me') && (method === 'DELETE' || method === 'POST')) {
    const authHeader = req.headers['authorization'] || '';
    const userId = body.userId || parsedUrl.query.userId || (authHeader.startsWith('Bearer ') ? 'u_1' : 'u_1');
    const contact = body.contact || parsedUrl.query.contact;

    // Remove user record
    mockDB.users = mockDB.users.filter((u) => {
      if (userId && u.id === userId) return false;
      if (contact && (u.email === contact || u.phone === contact)) return false;
      return true;
    });

    // Remove OTP tokens if contact matched
    if (contact && mockDB.otpStore[contact]) {
      delete mockDB.otpStore[contact];
    }

    // Clean up user specific data from mockDB
    mockDB.tasks = mockDB.tasks.filter((t) => t.userId !== userId);
    mockDB.expenses = mockDB.expenses.filter((e) => e.userId !== userId);
    mockDB.milestones = mockDB.milestones.filter((m) => m.userId !== userId);

    console.log(`[ACCOUNT DELETED] Permanently removed user account: userId=${userId}, contact=${contact}`);

    return sendJSON(res, 200, {
      success: true,
      message: 'Your account and all associated user data have been permanently deleted.',
    });
  }

  // Tasks: List
  if (path === '/api/tasks' && method === 'GET') {
    return sendJSON(res, 200, { success: true, tasks: mockDB.tasks });
  }

  // Tasks: Create
  if (path === '/api/tasks' && method === 'POST') {
    const { title, category, dueDateLabel } = body;
    const newTask = {
      id: `t_${Date.now()}`,
      title: title || 'New Task',
      category: category || 'Personal Growth',
      dueDateLabel: dueDateLabel || 'Today',
      isCompleted: false,
    };
    mockDB.tasks.push(newTask);
    return sendJSON(res, 201, { success: true, task: newTask });
  }

  // Expenses: List
  if (path === '/api/expenses' && method === 'GET') {
    return sendJSON(res, 200, { success: true, expenses: mockDB.expenses });
  }

  // Milestones: List
  if (path === '/api/milestones' && method === 'GET') {
    return sendJSON(res, 200, { success: true, milestones: mockDB.milestones });
  }

  // FCM Push Notification Trigger
  if (path === '/api/notifications/push' && method === 'POST') {
    const { deviceToken, title, message } = body;
    const result = sendFCMPushNotification(
      deviceToken || 'token_123',
      title || 'Wrindha OS Alert',
      message || 'Time to review your study goal!'
    );
    return sendJSON(res, 200, result);
  }

  // AdMob Reward Processing
  if (path === '/api/admob/claim-reward' && method === 'POST') {
    const { userId, rewardType, amount } = body;
    const result = processAdMobReward(userId || 'u_1', rewardType, amount);
    return sendJSON(res, 200, result);
  }

  // Fallback 404
  return sendJSON(res, 404, { success: false, message: 'Endpoint not found' });
});

server.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`🚀 Wrindha OS Native Backend Service running on port ${PORT}`);
  console.log(`📡 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🔐 2FA OTP & Google SSO Authentication Engine Active`);
  console.log(`💬 FCM Push Notifications & AdMob Reward Engine Active`);
  console.log(`===================================================`);
});
