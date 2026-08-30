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
  TODO: 'todo',
  CALENDAR: 'calendar',
  HABITS: 'habits',
  SUBJECTS: 'subjects',
  GOALS: 'goals',
  ACHIEVEMENTS: 'achievements',
  EISENHOWER_MATRIX: 'eisenhowerMatrix',
  PRIORITY_MATRIX: 'priorityMatrix',
  CAREER_TRAJECTORY: 'careerTrajectory',
  FINANCE: 'finance',
  ANALYTICS: 'analytics',
  FOCUS_CENTRE: 'focusCentre',
};

// Plan Entitlements & Features Matrix
const PLAN_LIMITS = {
  [PLANS.FREE]: {
    plan: PLANS.FREE,
    adsEnabled: true,
    features: {
      [FEATURES.TODO]: { enabled: true, limit: null }, // Full Standard Access
      [FEATURES.CALENDAR]: { enabled: true, limit: null }, // Full Standard Access
      [FEATURES.HABITS]: { enabled: true, limit: 2 }, // Maximum 2 active habits
      [FEATURES.SUBJECTS]: { enabled: true, limit: 2 }, // Maximum 2 active subjects
      [FEATURES.GOALS]: { enabled: true, limit: 2 }, // Maximum 2 active goals
      [FEATURES.ACHIEVEMENTS]: { enabled: true, limit: null }, // Free users can add achievements/milestones
      [FEATURES.EISENHOWER_MATRIX]: { enabled: false, limit: null }, // Locked for Free
      [FEATURES.PRIORITY_MATRIX]: { enabled: false, limit: null }, // Locked for Free
      [FEATURES.CAREER_TRAJECTORY]: { enabled: false, limit: null }, // Locked for Free
      [FEATURES.FINANCE]: { enabled: false, limit: null }, // Locked for Free
      [FEATURES.ANALYTICS]: { enabled: false, limit: null }, // Locked for Free
      [FEATURES.FOCUS_CENTRE]: { enabled: false, limit: null }, // Locked for Free
    },
  },
  [PLANS.PREMIUM]: {
    plan: PLANS.PREMIUM,
    adsEnabled: false,
    features: {
      [FEATURES.TODO]: { enabled: true, limit: null },
      [FEATURES.CALENDAR]: { enabled: true, limit: null },
      [FEATURES.HABITS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.SUBJECTS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.GOALS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.ACHIEVEMENTS]: { enabled: true, limit: null }, // Unlimited
      [FEATURES.EISENHOWER_MATRIX]: { enabled: true, limit: null }, // Full Pro Access
      [FEATURES.PRIORITY_MATRIX]: { enabled: true, limit: null }, // Full Pro Access
      [FEATURES.CAREER_TRAJECTORY]: { enabled: true, limit: null }, // Full Pro Access
      [FEATURES.FINANCE]: { enabled: true, limit: null }, // Full Pro Access
      [FEATURES.ANALYTICS]: { enabled: true, limit: null }, // Full Pro Access
      [FEATURES.FOCUS_CENTRE]: { enabled: true, limit: null }, // Full Pro Access
    },
  },
};

module.exports = {
  PLANS,
  SUBSCRIPTION_STATUSES,
  FEATURES,
  PLAN_LIMITS,
};
