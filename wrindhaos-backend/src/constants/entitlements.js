const PLANS = {
  FREE: 'FREE',
  PREMIUM: 'PREMIUM',
};

const SUBSCRIPTION_STATUSES = {
  ACTIVE: 'ACTIVE',
  CANCELLED: 'CANCELLED',
  EXPIRED: 'EXPIRED',
  PAUSED: 'PAUSED',
  PENDING: 'PENDING',
  GRACE_PERIOD: 'GRACE_PERIOD',
  ON_HOLD: 'ON_HOLD',
};

const FEATURES = {
  EISENHOWER_MATRIX: 'eisenhowerMatrix',
  CALENDAR: 'calendar',
  TODO: 'todo',
  HABITS: 'habits',
  SUBJECTS: 'subjects',
  GOALS: 'goals',
  CAREER_TRAJECTORY: 'careerTrajectory',
  ANALYTICS: 'analytics',
  FOCUS_CENTRE: 'focusCentre',
};

// Plan Entitlements & Features Matrix
const PLAN_LIMITS = {
  [PLANS.FREE]: {
    plan: PLANS.FREE,
    adsEnabled: true,
    features: {
      [FEATURES.EISENHOWER_MATRIX]: { enabled: true, limit: null },
      [FEATURES.CALENDAR]: { enabled: true, limit: null },
      [FEATURES.TODO]: { enabled: true, limit: null },
      [FEATURES.HABITS]: { enabled: true, limit: 2 }, // Maximum 2 active habits
      [FEATURES.SUBJECTS]: { enabled: true, limit: 2 }, // Maximum 2 active subjects
      [FEATURES.GOALS]: { enabled: true, limit: 2 },
      [FEATURES.CAREER_TRAJECTORY]: { enabled: true, limit: null },
      [FEATURES.ANALYTICS]: { enabled: true, limit: null },
      [FEATURES.FOCUS_CENTRE]: { enabled: true, limit: null },
    },
  },
  [PLANS.PREMIUM]: {
    plan: PLANS.PREMIUM,
    adsEnabled: false,
    features: {
      [FEATURES.EISENHOWER_MATRIX]: { enabled: true, limit: null },
      [FEATURES.CALENDAR]: { enabled: true, limit: null },
      [FEATURES.TODO]: { enabled: true, limit: null },
      [FEATURES.HABITS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.SUBJECTS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.GOALS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.CAREER_TRAJECTORY]: { enabled: true, limit: null },
      [FEATURES.ANALYTICS]: { enabled: true, limit: null },
      [FEATURES.FOCUS_CENTRE]: { enabled: true, limit: null },
    },
  },
};

module.exports = {
  PLANS,
  SUBSCRIPTION_STATUSES,
  FEATURES,
  PLAN_LIMITS,
};
