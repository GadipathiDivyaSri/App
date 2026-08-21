import { FeatureConfigItem, SubscriptionPlan } from '../types';

export const WRINDHA_DEFAULT_FEATURES: FeatureConfigItem[] = [
  {
    feature_key: 'study_planner',
    name: 'Study Planner',
    description: 'Comprehensive academic study schedule, revision blocks, and exam prep roadmap.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Basic access (1 active roadmap)',
    pro_limit: 'Unlimited roadmaps & auto-scheduling',
  },
  {
    feature_key: 'subjects',
    name: 'Subjects',
    description: 'Academic course management, lecture tracks, syllabus logs, and resource tags.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Up to 4 active subjects',
    pro_limit: 'Unlimited course modules & tagging',
  },
  {
    feature_key: 'timetable',
    name: 'Timetable',
    description: 'Weekly schedule grid, class alert reminders, and conflict detection.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Standard weekly grid',
    pro_limit: 'Dynamic timetable with calendar sync',
  },
  {
    feature_key: 'todo',
    name: 'To-Do',
    description: 'Daily action lists, subtask breakdowns, and quick capture widgets.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Basic list access',
    pro_limit: 'Unlimited lists, smart tags & recurring tasks',
  },
  {
    feature_key: 'focus_centre',
    name: 'Focus Centre',
    description: 'Pomodoro timer, deep work logging, ambient sounds, and anti-distraction intervals.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Standard 25/5 min timer',
    pro_limit: 'Custom intervals & deep analytics',
  },
  {
    feature_key: 'habits',
    name: 'Habits',
    description: 'Daily streak tracking, habit loops, consistency heatmaps, and reflections.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Up to 3 active habits',
    pro_limit: 'Unlimited habit streaks & analytics',
  },
  {
    feature_key: 'goals',
    name: 'Goals',
    description: 'Quarterly & semester objective setting with key milestone linkage.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Up to 2 active goals',
    pro_limit: 'Unlimited goals & OKR frameworks',
  },
  {
    feature_key: 'milestones',
    name: 'Milestones',
    description: 'Major project checkpoints, deadline tracking, and deliverable targets.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Not configured',
    pro_limit: 'Expanded milestone dependencies',
  },
  {
    feature_key: 'priority_matrix',
    name: 'Priority Matrix',
    description: 'Urgency-importance quadrant classification and high-impact sorting.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Not configured',
    pro_limit: 'Full priority scoring engine',
  },
  {
    feature_key: 'eisenhower_matrix',
    name: 'Eisenhower Matrix',
    description: '4-quadrant decision matrix (Do, Decide, Delegate, Delete) for daily focus.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Not configured',
    pro_limit: 'Expanded task triage & automation',
  },
  {
    feature_key: 'kanban',
    name: 'Kanban',
    description: 'Visual workflow boards with custom stages, WIP limits, and cards.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: '1 board (up to 3 columns)',
    pro_limit: 'Unlimited boards, swimlanes & custom filters',
  },
  {
    feature_key: 'journal',
    name: 'Journal',
    description: 'Daily gratitude, study reflections, productivity review, and logs.',
    free_enabled: true,
    pro_enabled: true,
    free_limit: 'Basic daily entries',
    pro_limit: 'Rich markdown entries, prompts & mood tracking',
  },
  {
    feature_key: 'finance',
    name: 'Finance',
    description: 'Student budgeting, daily expense tracking, and allowance management.',
    free_enabled: false,
    pro_enabled: true,
    free_limit: 'Not configured',
    pro_limit: 'Full expense tracker & monthly budget reports',
  },
  {
    feature_key: 'career',
    name: 'Career',
    description: 'Internship applications, resume skill logs, and interview preparation tracks.',
    free_enabled: false,
    pro_enabled: true,
    free_limit: 'Not configured',
    pro_limit: 'Application pipeline & career roadmap tools',
  },
];

export const INITIAL_PLANS: SubscriptionPlan[] = [
  {
    id: 'plan-free-001',
    name: 'Free',
    slug: 'free',
    description: 'Essential student productivity tools and daily study organization for every learner.',
    price: 0,
    currency: 'INR',
    billing_period: 'none',
    is_active: true,
    trial_duration_days: null,
    features: WRINDHA_DEFAULT_FEATURES,
    limits: {
      study_roadmaps: 1,
      subjects: 4,
      habits: 3,
      goals: 2,
      kanban_boards: 1,
    },
    created_at: new Date(Date.now() - 180 * 86400000).toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: 'plan-pro-002',
    name: 'Pro',
    slug: 'pro',
    description: 'Complete high-performance operating system with unrestricted study, habit, and career tooling.',
    price: 49,
    currency: 'INR',
    billing_period: 'monthly',
    is_active: true,
    trial_duration_days: 7, // Configurable trial duration
    features: WRINDHA_DEFAULT_FEATURES,
    limits: {
      study_roadmaps: 'unlimited',
      subjects: 'unlimited',
      habits: 'unlimited',
      goals: 'unlimited',
      kanban_boards: 'unlimited',
    },
    created_at: new Date(Date.now() - 180 * 86400000).toISOString(),
    updated_at: new Date().toISOString(),
  },
];

export interface DefaultFeatureItem {
  key: string;
  name: string;
  description: string;
  defaultEnabledFree: boolean;
  defaultEnabledPro: boolean;
  defaultLimitFree: string;
  defaultLimitPro: string;
}

export const DEFAULT_FEATURES: DefaultFeatureItem[] = WRINDHA_DEFAULT_FEATURES.map((f) => ({
  key: f.feature_key,
  name: f.name,
  description: f.description,
  defaultEnabledFree: f.free_enabled,
  defaultEnabledPro: f.pro_enabled,
  defaultLimitFree: f.free_limit,
  defaultLimitPro: f.pro_limit,
}));

