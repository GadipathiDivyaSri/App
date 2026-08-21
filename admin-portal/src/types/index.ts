export type AdminRole = 'SUPER_ADMIN' | 'SUPPORT_AGENT' | 'FINANCE_ADMIN' | 'MODERATOR';

export interface AdminUser {
  id: string;
  user_id?: string;
  name?: string;
  full_name?: string;
  email: string;
  role: AdminRole;
  permissions?: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type UserPlan = 'FREE' | 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY' | 'Free' | 'Pro' | 'Student';
export type UserStatus = 'active' | 'inactive' | 'suspended';

export interface WrindhaUser {
  id: string;
  user_id?: string;
  name: string;
  display_name?: string;
  email: string;
  phone?: string | null;
  phone_number?: string | null;
  plan: UserPlan | string;
  subscription_plan?: 'FREE' | 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY' | string;
  status: UserStatus;
  focus_score?: number;
  active_streak?: number;
  avatar_url?: string | null;
  email_verified?: boolean;
  phone_verified?: boolean;
  login_method?: string | null;
  app_version?: string | null;
  device_info?: string | null;
  created_at: string;
  updated_at?: string | null;
  last_login_at?: string | null;
  last_active_at?: string | null;
  metadata?: {
    school?: string;
    major?: string;
    graduation_year?: number | string;
    bio?: string;
    timezone?: string;
    suspension_reason?: string;
    suspended_at?: string;
    suspended_by?: string;
    restored_at?: string;
    restored_by?: string;
    [key: string]: unknown;
  };
}

export interface UserModeration {
  id: string;
  user_id: string;
  is_banned: boolean;
  ban_reason?: string | null;
  banned_by?: string | null;
  banned_at: string;
  unbanned_at?: string | null;
}

export interface UserActivityLog {
  id: string;
  user_id: string;
  action: string;
  details: string;
  ip_address?: string | null;
  created_at: string;
}

export type DeletionRequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'COMPLETED';

export interface AccountDeletionRequest {
  id: string;
  user_id: string;
  requested_by: string;
  requested_by_email?: string;
  reason: string;
  status: DeletionRequestStatus;
  created_at: string;
  processed_at?: string | null;
  processed_by?: string | null;
  user_name?: string;
  user_email?: string;
}

export type AuditAction =
  | 'USER_VIEWED'
  | 'USER_SUSPENDED'
  | 'USER_RESTORED'
  | 'DELETION_REQUESTED'
  | 'PLAN_CREATED'
  | 'PLAN_UPDATED'
  | 'PLAN_DEACTIVATED'
  | 'PLAN_PRICE_CHANGED'
  | 'PLAN_FEATURES_CHANGED'
  | 'SUBSCRIPTION_VIEWED'
  | 'CONTENT_CREATED'
  | 'CONTENT_UPDATED'
  | 'CONTENT_PUBLISHED'
  | 'CONTENT_UNPUBLISHED'
  | 'CONTENT_ARCHIVED'
  | 'CONTENT_DELETED'
  | 'NOTIFICATION_CREATED'
  | 'NOTIFICATION_SENT'
  | 'NOTIFICATION_SCHEDULED'
  | 'NOTIFICATION_DRAFT_SAVED'
  | 'NOTIFICATION_DELETED'
  | 'MAINTENANCE_ENABLED'
  | 'MAINTENANCE_DISABLED'
  | 'APP_VERSION_CHANGED'
  | 'FORCE_UPDATE_CHANGED'
  | 'SUPPORT_SETTINGS_CHANGED'
  | 'LEGAL_SETTINGS_CHANGED'
  | 'GENERAL_SETTINGS_CHANGED'
  | 'WEBSITE_SETTINGS_UPDATED'
  | 'HOMEPAGE_UPDATED'
  | 'LEGAL_DOCUMENT_CREATED'
  | 'LEGAL_DOCUMENT_UPDATED'
  | 'LEGAL_DOCUMENT_PUBLISHED'
  | 'LEGAL_DOCUMENT_UNPUBLISHED'
  | 'ANALYTICS_VIEWED';

export interface AdminAuditLog {
  id: string;
  admin_id: string;
  admin_email?: string;
  action: AuditAction;
  target_user_id?: string;
  target_user_email?: string;
  timestamp: string;
  metadata?: Record<string, unknown>;
}

export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  freeUsers: number;
  proUsers: number | string; // "Not configured" if no pro plan data
  userGrowth: {
    date: string;
    label: string;
    count: number;
  }[];
}

export type RegistrationDateFilter = 'all' | 'today' | '7d' | '30d' | '90d' | 'custom';
export type LastActiveFilter = 'all' | 'today' | '7d' | '30d' | 'inactive_30d';
export type SortField = 'name' | 'created_at' | 'last_active_at' | 'status';
export type SortOrder = 'asc' | 'desc';

export interface UserFilters {
  status: 'all' | UserStatus;
  plan: 'all' | 'Free' | 'Pro';
  registrationDate: RegistrationDateFilter;
  customStartDate?: string;
  customEndDate?: string;
  lastActive: LastActiveFilter;
}

export interface PaginationParams {
  page: number;
  pageSize: number;
  search?: string;
  filters?: UserFilters;
  sortField?: SortField;
  sortOrder?: SortOrder;
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// ==========================================
// PHASE 3: SUBSCRIPTION & PLAN MANAGEMENT TYPES
// ==========================================

export type PlanSlug = 'free' | 'pro';
export type BillingPeriod = 'none' | 'monthly';
export type SubscriptionStatus = 'ACTIVE' | 'TRIALING' | 'CANCELLED' | 'EXPIRED' | 'PAST_DUE';

export interface FeatureConfigItem {
  feature_key: string;
  name: string;
  description: string;
  free_enabled: boolean;
  pro_enabled: boolean;
  free_limit: string;
  pro_limit: string;
}

export interface PlanFeatureConfig {
  feature_key: string;
  name: string;
  description: string;
  enabled: boolean;
  limit: string;
}

export interface SubscriptionPlan {
  id: string;
  name: string; // 'Free' or 'Pro'
  slug: PlanSlug;
  description: string;
  price: number; // 0 for Free, 49 for Pro
  currency: string; // 'INR'
  billing_period: BillingPeriod;
  is_active: boolean;
  trial_duration_days?: number | null; // e.g. 7 or null
  trial_period_days?: number | null; // alias for compatibility
  features: any[];
  limits: Record<string, string | number | boolean>;
  created_at: string;
  updated_at: string;
}

export interface TimelineEvent {
  id: string;
  title: string;
  description: string;
  timestamp: string;
  type: 'created' | 'plan_change' | 'trial_start' | 'payment' | 'cancellation' | 'expiration';
}


export interface GooglePlaySubscription {
  id: string;
  user_id: string;
  package_name: string;
  subscription_id: string;
  purchase_token: string;
  status: 'ACTIVE' | 'CANCELED' | 'EXPIRED' | 'PAUSED';
  auto_renewing: boolean;
  expiry_timestamp: string;
  verified_at?: string;
  created_at: string;
}

export interface PaymentHistoryRecord {
  id: string;
  user_id: string;
  google_order_id: string;
  amount_micros: number;
  currency: string;
  payment_state: string;
  purchase_timestamp: string;
  created_at: string;
}

export interface UserSubscription {
  id: string;
  user_id: string;
  plan_id: string;
  status: SubscriptionStatus;
  started_at: string;
  package_name?: string;
  subscription_id?: string;
  purchase_token?: string;
  google_order_id?: string;
  amount_micros?: number;
  trial_started_at?: string | null;
  trial_ends_at?: string | null;
  current_period_start?: string | null;
  current_period_end?: string | null;
  cancelled_at?: string | null;
  ended_at?: string | null;
  created_at: string;
  updated_at: string;
  // Joined/augmented fields for administrative presentation
  user?: WrindhaUser;
  plan?: SubscriptionPlan;
}

export interface SubscriptionKPIs {
  totalUsers: number;
  freeUsers: number;
  proUsers: number;
  trialUsers: number;
  activePro: number;
  cancelled: number;
  expired: number;
}

export interface SubscriptionFilters {
  plan: 'all' | 'free' | 'pro';
  status: 'all' | SubscriptionStatus;
  dateRange: 'all' | 'today' | '7d' | '30d' | '90d' | 'custom';
  customStartDate?: string;
  customEndDate?: string;
}

export type SubscriptionSortField =
  | 'user_name'
  | 'plan'
  | 'status'
  | 'started_at'
  | 'current_period_end'
  | 'created_at';

export interface SubscriptionQueryParams {
  page: number;
  pageSize: number;
  search?: string;
  filters?: SubscriptionFilters;
  sortField?: SubscriptionSortField;
  sortOrder?: SortOrder;
}

// ==========================================
// PHASE 4: APP CONTENT MANAGEMENT TYPES
// ==========================================

export type ContentStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export interface CareerCategory {
  id: string;
  name: string;
  description: string;
  icon?: string | null;
  order: number;
  status: ContentStatus;
  created_at: string;
  updated_at: string;
  // Computed
  paths_count?: number;
}

export interface CareerPath {
  id: string;
  category_id: string;
  name: string;
  description: string;
  skills: string[];
  order: number;
  status: ContentStatus;
  created_at: string;
  updated_at: string;
  // Joined / computed
  category?: CareerCategory;
  milestones_count?: number;
}

export interface CareerMilestone {
  id: string;
  career_path_id: string;
  title: string;
  description: string;
  order: number;
  status: ContentStatus;
  created_at: string;
  updated_at: string;
  // Joined / computed
  career_path?: CareerPath;
}

export interface ContentFilterParams {
  search?: string;
  status?: 'ALL' | ContentStatus;
  category_id?: string;
  career_path_id?: string;
}

// ==========================================
// PHASE 5: NOTIFICATIONS & APP SETTINGS TYPES
// ==========================================

export type NotificationTarget = 'ALL' | 'FREE' | 'PRO';
export type NotificationStatus = 'DRAFT' | 'SCHEDULED' | 'SENT' | 'FAILED';

export interface NotificationDeliveryStats {
  total_targets: number;
  successful: number;
  failed: number;
  fcm_configured?: boolean;
  fcm_message_id?: string | null;
  error_message?: string | null;
}

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  target: NotificationTarget;
  status: NotificationStatus;
  scheduled_at?: string | null;
  sent_at?: string | null;
  created_by: string;
  created_by_email?: string | null;
  delivery_stats?: NotificationDeliveryStats | null;
  created_at: string;
  updated_at: string;
}

export interface NotificationStats {
  totalNotifications: number;
  sentCount: number;
  successfulCount: number;
  failedCount: number;
  scheduledCount: number;
  draftCount: number;
  fcmConfigured: boolean;
}

export interface FCMStatus {
  isConfigured: boolean;
  statusText: string;
  details?: string;
  configuredAt?: string | null;
}

export interface GeneralSettings {
  app_name: string;
  tagline?: string;
  support_email: string;
  support_phone?: string;
  website_url?: string;
}

export interface AppVersionSettings {
  minimum_supported_version: string;
  latest_version: string;
  force_update: boolean;
  maintenance_mode: boolean;
  maintenance_message: string;
}

export interface SupportSettings {
  support_email: string;
  support_website?: string;
  help_center_url?: string;
}

export interface LegalSettings {
  privacy_policy_url: string;
  terms_conditions_url: string;
  refund_policy_url?: string;
  account_deletion_url?: string;
  grievance_contact?: string;
}

export interface AppSettings {
  id: string;
  general: GeneralSettings;
  app_version: AppVersionSettings;
  support: SupportSettings;
  legal: LegalSettings;
  updated_at: string;
  updated_by?: string;
}

// ==========================================
// PHASE 6: WEBSITE & LEGAL MANAGEMENT TYPES
// ==========================================

export type LegalDocumentStatus = 'DRAFT' | 'PUBLISHED';

export type LegalDocumentSlug =
  | 'privacy-policy'
  | 'terms'
  | 'refund-policy'
  | 'account-deletion'
  | 'contact'
  | 'cookies'
  | 'copyright';

export interface LegalDocument {
  id: string;
  slug: LegalDocumentSlug | string;
  title: string;
  description?: string;
  content: string;
  status: LegalDocumentStatus;
  public_url: string;
  version?: string;
  created_at: string;
  updated_at: string;
  updated_by?: string;
  updated_by_email?: string;
}

export interface LegalSummaryStats {
  totalRequired: number;
  publishedCount: number;
  draftCount: number;
  missingCount: number;
  allPublished: boolean;
  missingDocuments: string[];
}

export interface WebsiteGeneralSettings {
  website_name: string;
  website_url: string;
  short_description: string;
  support_email: string;
  contact_phone?: string;
}

export interface WebsiteHomepageSettings {
  hero_headline: string;
  hero_description: string;
  primary_cta_text: string;
  primary_cta_url: string;
  secondary_cta_text?: string;
  secondary_cta_url?: string;
}

export interface WebsiteAppLinksSettings {
  google_play_url?: string;
  android_apk_url?: string;
  web_app_url?: string;
}

export interface WebsiteContactSettings {
  support_email: string;
  business_email: string;
  grievance_email: string;
  contact_page_url: string;
  physical_address?: string;
}

export interface WebsiteSettings {
  id: string;
  general: WebsiteGeneralSettings;
  homepage: WebsiteHomepageSettings;
  app_links: WebsiteAppLinksSettings;
  contact: WebsiteContactSettings;
  updated_at: string;
  updated_by?: string;
}

// ==========================================
// PHASE 7: BASIC PRODUCT ANALYTICS TYPES
// ==========================================

export type AnalyticsDateRange = '7d' | '30d' | '90d';

export type AppEventName =
  | 'LOGIN'
  | 'STUDY_SESSION_STARTED'
  | 'STUDY_SESSION_COMPLETED'
  | 'TASK_CREATED'
  | 'TASK_COMPLETED'
  | 'HABIT_CREATED'
  | 'GOAL_CREATED'
  | 'POMODORO_COMPLETED'
  | 'ACADEMIC_TOPIC_VIEWED'
  | 'CAREER_ROADMAP_VIEWED';

export interface AppEvent {
  id: string;
  user_id: string;
  event_name: AppEventName | string;
  metadata?: Record<string, unknown> | null;
  created_at: string;
}

export interface UserGrowthPoint {
  date: string;
  label: string;
  newUsers: number;
  cumulativeUsers: number;
}

export interface ProductUsageMetric {
  metricKey: string;
  label: string;
  category: 'Focus & Timer' | 'Tasks & Habits' | 'Goals & Planning' | 'System';
  count: number | null;
  isTracked: boolean;
  sourceTableOrEvent: string;
  missingNotice?: string;
}

export interface MostUsedFeature {
  featureName: string;
  eventName: string;
  count: number;
  pct: number;
}

export interface AnalyticsSummary {
  range: AnalyticsDateRange;
  generatedAt: string;

  // Core KPI Cards
  totalUsers: number;
  newUsers: number;
  newUsersPreviousPeriod: number;
  growthPct: number | null; // e.g. +38.9%
  growthIsPositive: boolean;

  // Active Users
  dau: number | null; // Daily Active Users (past 24h)
  wau: number | null; // Weekly Active Users (past 7d)
  hasActiveUserData: boolean;
  activeUserNotice?: string;

  // Pro & Subscription Metrics
  totalEligibleUsers: number;
  freeUsersCount: number;
  freeUsersPct: number;
  proUsersCount: number;
  proUsersPct: number;
  hasProPlan: boolean;
  conversionRate: number | null; // e.g. 5.2%
  conversionNotice?: string;

  // Basic Retention
  retention7dRate: number | null; // 7-day returning rate
  hasRetentionData: boolean;
  retentionNotice?: string;

  // User Growth Time Series
  growthChart: UserGrowthPoint[];

  // Product Usage Breakdown
  productUsage: ProductUsageMetric[];

  // Most Used Features
  mostUsedFeatures: MostUsedFeature[];
  hasFeatureTracking: boolean;
  featureTrackingNotice?: string;

  // Revenue Placeholder
  hasPaymentIntegration: boolean;
  revenueNotice: string;
}

// ==========================================
// APP DATA & USER PRODUCTIVITY MODULE TYPES
// (Matching 003_complete_wrindhaos_schema.sql)
// ==========================================

export interface UserNotificationSettings {
  user_id: string;
  push_notifications_enabled: boolean;
  email_notifications_enabled: boolean;
  preferred_reminder_time: string;
  habit_reminders_enabled: boolean;
  expense_alerts_enabled: boolean;
  study_reminders_enabled: boolean;
  updated_at: string;
}

export interface UserReferral {
  id: string;
  referrer_id: string;
  referee_id?: string | null;
  referral_code: string;
  status: 'PENDING' | 'COMPLETED' | 'EXPIRED';
  reward_xp: number;
  created_at: string;
}

export interface AppHabit {
  id: string;
  user_id: string;
  title: string;
  description?: string | null;
  frequency: 'DAILY' | 'WEEKDAYS' | 'WEEKENDS' | 'CUSTOM';
  preferred_time: string;
  icon_name: string;
  color_hex: string;
  is_archived: boolean;
  created_at: string;
}

export interface AppHabitLog {
  id: string;
  habit_id: string;
  user_id: string;
  completed_date: string;
  completed_at: string;
}

export interface AppHabitStreak {
  habit_id: string;
  user_id: string;
  current_streak_days: number;
  longest_streak_days: number;
  last_completed_date?: string | null;
}

export interface AppHabitReward {
  id: string;
  user_id: string;
  reward_title: string;
  badge_type: 'EARLY_BIRD' | 'ON_FIRE' | 'CONSISTENT_MASTER';
  badge_icon: string;
  unlocked_at: string;
}

export interface MonthlyBudget {
  id: string;
  user_id: string;
  budget_month: string;
  total_budget_amount: number;
  currency: string;
  created_at: string;
}

export interface ExpenseCategory {
  id: string;
  user_id: string;
  category_name: string;
  icon_name: string;
  color_hex: string;
}

export interface AppExpense {
  id: string;
  user_id: string;
  category_id?: string | null;
  category_name: string;
  title: string;
  amount: number;
  expense_date: string;
  payment_method: string;
  created_at: string;
}

export interface AppGoal {
  id: string;
  user_id: string;
  goal_title: string;
  pyramid_level: 'SHORT_TERM' | 'MEDIUM_TERM' | 'LONG_TERM';
  target_date?: string | null;
  progress_percentage: number;
  is_completed: boolean;
  created_at: string;
}

export interface AppMilestone {
  id: string;
  user_id: string;
  goal_id?: string | null;
  title: string;
  description?: string | null;
  category: string;
  target_date?: string | null;
  status: 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED';
  completion_percentage: number;
  created_at: string;
}

export interface EisenhowerTask {
  id: string;
  user_id: string;
  title: string;
  description?: string | null;
  quadrant: 'DO_FIRST' | 'SCHEDULE' | 'DELEGATE' | 'DONT_DO';
  due_date?: string | null;
  is_completed: boolean;
  created_at: string;
}

export interface PriorityMatrixTask {
  id: string;
  user_id: string;
  title: string;
  description?: string | null;
  priority_level: 'HIGH_PRIORITY' | 'MEDIUM_PRIORITY' | 'LOW_PRIORITY';
  due_date?: string | null;
  preferred_time?: string | null;
  is_completed: boolean;
  created_at: string;
}

export interface JournalEntry {
  id: string;
  user_id: string;
  title: string;
  body_content: string;
  entry_date: string;
  mood_rating: 'GREAT' | 'GOOD' | 'NEUTRAL' | 'STRESSED' | 'LOW';
  created_at: string;
  updated_at: string;
}

export interface CareerLevel {
  level_number: number;
  level_title: string;
  xp_required: number;
  description?: string | null;
}

export interface CareerNode {
  id: string;
  user_id: string;
  node_title: string;
  level_number: number;
  node_order: number;
  description?: string | null;
  skills_unlocked?: string | null;
  status: 'LOCKED' | 'AVAILABLE' | 'COMPLETED';
  completed_at?: string | null;
  created_at: string;
}

export interface AppSubject {
  id: string;
  user_id: string;
  subject_name: string;
  subject_code?: string | null;
  color_hex: string;
  mastery_percentage: number;
  created_at: string;
}

export interface AppUnit {
  id: string;
  subject_id: string;
  user_id: string;
  unit_title: string;
  unit_order: number;
  description?: string | null;
  mastery_percentage: number;
  created_at: string;
}

export interface AppTopic {
  id: string;
  unit_id: string;
  user_id: string;
  topic_title: string;
  topic_order: number;
  resource_url?: string | null;
  is_completed: boolean;
  completed_at?: string | null;
  created_at: string;
}

export interface StudySession {
  id: string;
  user_id: string;
  subject_id?: string | null;
  duration_minutes: number;
  focus_xp_earned: number;
  session_date: string;
  created_at: string;
}

export interface TimeTableSlot {
  id: string;
  user_id: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  activity_title: string;
  activity_type: 'STUDY' | 'WORK' | 'BREAK' | 'REVISION';
  created_at: string;
}

export interface CalendarScheduleEvent {
  id: string;
  user_id: string;
  title: string;
  description?: string | null;
  event_date: string;
  start_time: string;
  end_time: string;
  location: string;
  event_type: 'FOCUS_SESSION' | 'MEETING' | 'TASK' | 'STUDY';
  is_completed: boolean;
  created_at: string;
}

export interface TodoTask {
  id: string;
  user_id: string;
  title: string;
  category: string;
  due_date?: string | null;
  preferred_time?: string | null;
  is_completed: boolean;
  created_at: string;
}

export interface UserDailyAnalytic {
  id: string;
  user_id: string;
  record_date: string;
  tasks_completed_count: number;
  habits_completed_count: number;
  study_duration_minutes: number;
  total_expense_amount: number;
  daily_focus_score: number;
}
