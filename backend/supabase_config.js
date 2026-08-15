// Supabase Native REST Client & Local Database Persistence Configuration
const https = require('https');

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://xyzproductivedb.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mockkey';

/**
 * Native HTTP REST helper for Supabase PostgREST API
 */
function querySupabase(table, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    try {
      const url = new URL(`${SUPABASE_URL}/rest/v1/${table}`);
      const options = {
        method: method,
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
      };

      const req = https.request(url, options, (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            resolve({ raw: data });
          }
        });
      });

      req.on('error', (err) => resolve({ error: err.message }));
      if (body) req.write(JSON.stringify(body));
      req.end();
    } catch (err) {
      resolve({ error: err.message });
    }
  });
}

// In-Memory Fallback & Cache Database
const mockDB = {
  users: [
    {
      id: 'u_1',
      name: 'Alex Johnson',
      email: 'alex.johnson@example.com',
      phone: '+919876543210',
      focusScore: 92,
      activeStreak: 14,
      isPremium: true,
      xp: 2450,
    },
  ],
  tasks: [
    {
      id: 't_1',
      title: 'Finalize roadmap presentation',
      category: 'Career Roadmap',
      dueDateLabel: 'Today',
      isCompleted: false,
    },
    {
      id: 't_2',
      title: 'Update study timetable',
      category: 'Studies',
      dueDateLabel: 'Tomorrow',
      isCompleted: false,
    },
  ],
  expenses: [
    {
      id: 'e_1',
      title: 'Lunch with Client',
      category: 'Food & Drinks • 10:30 AM',
      amount: '- ₹45.20',
      isIncome: false,
    },
    {
      id: 'e_2',
      title: 'Freelance Payout',
      category: 'Income • Dec 10',
      amount: '+ ₹1,200.00',
      isIncome: true,
    },
  ],
  milestones: [
    {
      id: 'm_1',
      category: 'PROJECT ALPHA',
      title: 'Successfully Launched Beta Version',
      date: 'Oct 24',
      badge: 'High Impact',
    },
  ],
  otpStore: {}, // Stores 2FA OTP tokens { contact: { code, expiresAt } }
};

module.exports = {
  querySupabase,
  mockDB,
};
