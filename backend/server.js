require('dotenv').config();

const http = require('http');
const url = require('url');

const { mockDB } = require('./supabase_config');

const {
  send2FAOTP,
  verify2FAOTP,
  resend2FAOTP,
  verifyGoogleToken
} = require('./services/auth_2fa');

const {
  sendFCMPushNotification,
  processAdMobReward
} = require('./services/fcm_notifications');

const PORT = process.env.PORT || 3000;


// ---------------------------------------------------------
// Helper: Send JSON Response
// ---------------------------------------------------------
function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  });

  res.end(JSON.stringify(data));
}


// ---------------------------------------------------------
// Helper: Parse JSON Request Body
// ---------------------------------------------------------
function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';

    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        resolve({});
      }
    });
  });
}


// ---------------------------------------------------------
// CREATE SERVER
// ---------------------------------------------------------
const server = http.createServer(async (req, res) => {

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const method = req.method.toUpperCase();


  // -------------------------------------------------------
  // CORS PRE-FLIGHT
  // -------------------------------------------------------
  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });

    return res.end();
  }


  // -------------------------------------------------------
  // REQUEST BODY
  // -------------------------------------------------------
  const body =
    method === 'POST' || method === 'PATCH'
      ? await parseBody(req)
      : {};


  // =======================================================
  // HEALTH CHECK
  // =======================================================
  if (path === '/api/health' && method === 'GET') {

    return sendJSON(res, 200, {
      status: 'ONLINE',
      app: 'Wrindha OS Backend API Service',
      stack: 'Node.js Native HTTP + Supabase + 2FA OTP + FCM + AdMob',
      timestamp: new Date().toISOString()
    });
  }


  // =======================================================
  // AUTH: SEND OTP
  // =======================================================
  if (path === '/api/auth/send-otp' && method === 'POST') {

    const { contact } = body;

    if (!contact) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Contact address/phone required.'
      });
    }

    try {

      const result = await send2FAOTP(contact);

      return sendJSON(res, 200, result);

    } catch (error) {

      console.error('[SEND OTP ERROR]', error);

      return sendJSON(res, 500, {
        success: false,
        message: 'Failed to send OTP.'
      });
    }
  }


  // =======================================================
  // AUTH: RESEND OTP
  // =======================================================
  if (path === '/api/auth/resend-otp' && method === 'POST') {

    const { sessionId, contact } = body;

    if (!sessionId && !contact) {
      return sendJSON(res, 400, {
        success: false,
        message: 'Session ID or contact is required.'
      });
    }

    try {
      const result = await resend2FAOTP(sessionId, contact);

      if (!result.success) {
        return sendJSON(res, 400, result);
      }

      return sendJSON(res, 200, result);

    } catch (error) {
      console.error('[RESEND OTP ERROR]', error);
      return sendJSON(res, 500, {
        success: false,
        message: 'Failed to resend OTP.'
      });
    }
  }


  // =======================================================
  // AUTH: VERIFY OTP
  // =======================================================
  if (path === '/api/auth/verify-otp' && method === 'POST') {

    const { sessionId, code } = body;

    if (!sessionId || !code) {

      return sendJSON(res, 400, {
        success: false,
        message: 'Session ID and OTP code required.'
      });
    }

    try {

      const result = await verify2FAOTP(sessionId, code);

      return sendJSON(res, 200, result);

    } catch (error) {

      console.error('[VERIFY OTP ERROR]', error);

      return sendJSON(res, 500, {
        success: false,
        message: 'OTP verification failed.'
      });
    }
  }


  // =======================================================
  // AUTH: GOOGLE SSO
  // =======================================================
  if (path === '/api/auth/google' && method === 'POST') {

    const { googleToken } = body;

    const result = verifyGoogleToken(
      googleToken || 'demo_google_token'
    );

    return sendJSON(res, 200, result);
  }


  // =======================================================
  // TASKS: LIST
  // =======================================================
  if (path === '/api/tasks' && method === 'GET') {

    return sendJSON(res, 200, {
      success: true,
      tasks: mockDB.tasks
    });
  }


  // =======================================================
  // TASKS: CREATE
  // =======================================================
  if (path === '/api/tasks' && method === 'POST') {

    const {
      title,
      category,
      dueDateLabel
    } = body;

    const newTask = {
      id: `t_${Date.now()}`,
      title: title || 'New Task',
      category: category || 'Personal Growth',
      dueDateLabel: dueDateLabel || 'Today',
      isCompleted: false
    };

    mockDB.tasks.push(newTask);

    return sendJSON(res, 201, {
      success: true,
      task: newTask
    });
  }


  // =======================================================
  // EXPENSES: LIST
  // =======================================================
  if (path === '/api/expenses' && method === 'GET') {

    return sendJSON(res, 200, {
      success: true,
      expenses: mockDB.expenses
    });
  }


  // =======================================================
  // MILESTONES: LIST
  // =======================================================
  if (path === '/api/milestones' && method === 'GET') {

    return sendJSON(res, 200, {
      success: true,
      milestones: mockDB.milestones
    });
  }


  // =======================================================
  // FCM PUSH NOTIFICATION
  // =======================================================
  if (
    path === '/api/notifications/push' &&
    method === 'POST'
  ) {

    const {
      deviceToken,
      title,
      message
    } = body;

    const result = sendFCMPushNotification(
      deviceToken || 'token_123',
      title || 'Wrindha OS Alert',
      message || 'Time to review your study goal!'
    );

    return sendJSON(res, 200, result);
  }


  // =======================================================
  // ADMOB REWARD
  // =======================================================
  if (
    path === '/api/admob/claim-reward' &&
    method === 'POST'
  ) {

    const {
      userId,
      rewardType,
      amount
    } = body;

    const result = processAdMobReward(
      userId || 'u_1',
      rewardType,
      amount
    );

    return sendJSON(res, 200, result);
  }


  // =======================================================
  // 404
  // =======================================================
  return sendJSON(res, 404, {
    success: false,
    message: 'Endpoint not found'
  });

});


// ---------------------------------------------------------
// START SERVER
// ---------------------------------------------------------
server.listen(PORT, () => {

  console.log('===================================================');
  console.log(`🚀 Wrindha OS Native Backend Service running on port ${PORT}`);
  console.log(`📡 Health Check: http://localhost:${PORT}/api/health`);
  console.log('🔐 2FA OTP & Google SSO Authentication Engine Active');
  console.log('💬 FCM Push Notifications & AdMob Reward Engine Active');
  console.log('===================================================');

});