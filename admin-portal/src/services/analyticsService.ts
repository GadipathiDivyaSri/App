import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoUsers,
  getDemoSubscriptions,
  getDemoAppEvents,
  addDemoAppEvent,
} from '../lib/supabase';
import {
  AnalyticsDateRange,
  AnalyticsSummary,
  ProductUsageMetric,
  MostUsedFeature,
  UserGrowthPoint,
  WrindhaUser,
  AppEvent,
} from '../types';
import { auditService } from './auditService';

export const analyticsService = {
  /**
   * Fetches comprehensive aggregated product analytics according to the selected date range.
   * Real database data is queried from Supabase when connected; fallback to local verified dataset.
   */
  async getAnalyticsSummary(range: AnalyticsDateRange = '30d'): Promise<AnalyticsSummary> {
    const days = range === '7d' ? 7 : range === '30d' ? 30 : 90;
    const now = new Date();
    const startDate = new Date(now.getTime() - days * 86400000);
    const previousPeriodStartDate = new Date(now.getTime() - 2 * days * 86400000);
    const previousPeriodEndDate = startDate;

    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    let users: WrindhaUser[] = [];
    let events: AppEvent[] = [];
    let hasLiveEventsTable = false;

    if (isConfigured && supabase) {
      try {
        // 1. Fetch users from live Supabase
        const { data: dbUsers, error: usersError } = await supabase
          .from('users')
          .select('*')
          .order('created_at', { ascending: true });

        if (!usersError && dbUsers) {
          users = dbUsers as WrindhaUser[];
        }

        // 2. Fetch app_events if the table exists
        const { data: dbEvents, error: eventsError } = await supabase
          .from('app_events')
          .select('*')
          .order('created_at', { ascending: false });

        if (!eventsError && dbEvents) {
          events = dbEvents as AppEvent[];
          hasLiveEventsTable = true;
        }
      } catch (err) {
        console.warn('Live analytics query fallback to local store:', err);
      }
    }

    // Fallback if live database empty or not configured
    if (users.length === 0) {
      users = getDemoUsers();
    }
    if (events.length === 0 && !hasLiveEventsTable) {
      events = getDemoAppEvents();
    }

    // ----------------------------------------------------
    // 1. Total & New Users Calculations
    // ----------------------------------------------------
    const totalUsers = users.length;

    const newUsersList = users.filter((u) => {
      const created = new Date(u.created_at);
      return created >= startDate && created <= now;
    });
    const newUsers = newUsersList.length;

    const previousPeriodUsersList = users.filter((u) => {
      const created = new Date(u.created_at);
      return created >= previousPeriodStartDate && created < previousPeriodEndDate;
    });
    const newUsersPreviousPeriod = previousPeriodUsersList.length;

    let growthPct: number | null = null;
    if (newUsersPreviousPeriod > 0) {
      growthPct = Number((((newUsers - newUsersPreviousPeriod) / newUsersPreviousPeriod) * 100).toFixed(1));
    } else if (newUsers > 0) {
      growthPct = 100.0;
    } else {
      growthPct = 0.0;
    }
    const growthIsPositive = growthPct >= 0;

    // ----------------------------------------------------
    // 2. Active Users (DAU & WAU)
    // ----------------------------------------------------
    const oneDayAgo = new Date(now.getTime() - 24 * 3600000);
    const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000);

    const activeUserIds24h = new Set<string>();
    const activeUserIds7d = new Set<string>();

    let usersWithActivityTimestamp = 0;

    users.forEach((u) => {
      if (u.last_active_at) {
        usersWithActivityTimestamp++;
        const lastActive = new Date(u.last_active_at);
        if (lastActive >= oneDayAgo) {
          activeUserIds24h.add(u.id);
        }
        if (lastActive >= sevenDaysAgo) {
          activeUserIds7d.add(u.id);
        }
      }
    });

    events.forEach((evt) => {
      const evtTime = new Date(evt.created_at);
      if (evtTime >= oneDayAgo && evt.user_id) {
        activeUserIds24h.add(evt.user_id);
      }
      if (evtTime >= sevenDaysAgo && evt.user_id) {
        activeUserIds7d.add(evt.user_id);
      }
    });

    const hasActiveUserData = usersWithActivityTimestamp > 0 || events.length > 0;
    const dau = hasActiveUserData ? activeUserIds24h.size : null;
    const wau = hasActiveUserData ? activeUserIds7d.size : null;
    const activeUserNotice = hasActiveUserData
      ? undefined
      : 'Active-user analytics require an activity tracking source.';

    // ----------------------------------------------------
    // 3. Plan Distribution & Pro Conversion Rate
    // ----------------------------------------------------
    const freeUsersCount = users.filter((u) => u.plan === 'Free' || !u.plan).length;
    const proUsersCount = users.filter((u) => u.plan === 'Pro').length;
    const totalEligibleUsers = totalUsers;

    const freeUsersPct = totalUsers > 0 ? Number(((freeUsersCount / totalUsers) * 100).toFixed(1)) : 0;
    const proUsersPct = totalUsers > 0 ? Number(((proUsersCount / totalUsers) * 100).toFixed(1)) : 0;

    const hasProPlan = true;
    const conversionRate = totalEligibleUsers > 0
      ? Number(((proUsersCount / totalEligibleUsers) * 100).toFixed(1))
      : null;

    // ----------------------------------------------------
    // 4. Basic Retention (7-Day Returning User Rate)
    // ----------------------------------------------------
    const eligibleForRetentionUsers = users.filter((u) => {
      const created = new Date(u.created_at);
      return created <= sevenDaysAgo;
    });

    let retention7dRate: number | null = null;
    let hasRetentionData = false;
    let retentionNotice: string | undefined = undefined;

    if (eligibleForRetentionUsers.length > 0 && hasActiveUserData) {
      const returningUsers = eligibleForRetentionUsers.filter((u) => activeUserIds7d.has(u.id));
      retention7dRate = Number(((returningUsers.length / eligibleForRetentionUsers.length) * 100).toFixed(1));
      hasRetentionData = true;
    } else {
      hasRetentionData = false;
      retentionNotice = 'Retention data is not available yet. Tracking requires session heartbeats from the Flutter mobile app.';
    }

    // ----------------------------------------------------
    // 5. User Growth Time Series Chart
    // ----------------------------------------------------
    const growthChart: UserGrowthPoint[] = [];
    const dateMap = new Map<string, number>();

    // Build continuous daily sequence
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 86400000);
      const key = d.toISOString().split('T')[0];
      dateMap.set(key, 0);
    }

    // Bucket new users
    users.forEach((u) => {
      if (u.created_at) {
        const key = u.created_at.split('T')[0];
        if (dateMap.has(key)) {
          dateMap.set(key, (dateMap.get(key) || 0) + 1);
        }
      }
    });

    // Calculate daily and cumulative counts
    let runningTotalBeforeRange = users.filter((u) => new Date(u.created_at) < startDate).length;
    let cumulative = runningTotalBeforeRange;

    dateMap.forEach((newCount, dateStr) => {
      cumulative += newCount;
      const dateObj = new Date(dateStr + 'T00:00:00');
      const label = dateObj.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
      });
      growthChart.push({
        date: dateStr,
        label,
        newUsers: newCount,
        cumulativeUsers: cumulative,
      });
    });

    // ----------------------------------------------------
    // 6. Basic Product Usage Metrics
    // ----------------------------------------------------
    const eventCounts = new Map<string, number>();
    events.forEach((evt) => {
      const name = evt.event_name.toUpperCase();
      eventCounts.set(name, (eventCounts.get(name) || 0) + 1);
    });

    const productUsage: ProductUsageMetric[] = [
      {
        metricKey: 'study_sessions_completed',
        label: 'Focus Sessions Completed',
        category: 'Focus & Timer',
        count: eventCounts.get('STUDY_SESSION_COMPLETED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (STUDY_SESSION_COMPLETED)',
      },
      {
        metricKey: 'study_sessions_started',
        label: 'Focus Sessions Started',
        category: 'Focus & Timer',
        count: eventCounts.get('STUDY_SESSION_STARTED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (STUDY_SESSION_STARTED)',
      },
      {
        metricKey: 'pomodoro_sessions',
        label: 'Pomodoro Sessions Completed',
        category: 'Focus & Timer',
        count: eventCounts.get('POMODORO_COMPLETED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (POMODORO_COMPLETED)',
      },
      {
        metricKey: 'tasks_created',
        label: 'Tasks Created',
        category: 'Tasks & Habits',
        count: eventCounts.get('TASK_CREATED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (TASK_CREATED)',
      },
      {
        metricKey: 'tasks_completed',
        label: 'Tasks Completed',
        category: 'Tasks & Habits',
        count: eventCounts.get('TASK_COMPLETED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (TASK_COMPLETED)',
      },
      {
        metricKey: 'habits_created',
        label: 'Habits Created',
        category: 'Tasks & Habits',
        count: eventCounts.get('HABIT_CREATED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (HABIT_CREATED)',
      },
      {
        metricKey: 'goals_created',
        label: 'Goals Created',
        category: 'Goals & Planning',
        count: eventCounts.get('GOAL_CREATED') ?? 0,
        isTracked: true,
        sourceTableOrEvent: 'app_events (GOAL_CREATED)',
      },
      {
        metricKey: 'journal_entries',
        label: 'Journal Entries Written',
        category: 'Goals & Planning',
        count: null,
        isTracked: false,
        sourceTableOrEvent: 'Awaiting JOURNAL_ENTRY_CREATED event telemetry from Flutter app',
        missingNotice: 'Event not tracked in mobile app yet.',
      },
    ];

    // ----------------------------------------------------
    // 7. Most Used Features Ranking
    // ----------------------------------------------------
    const featureMap: Record<string, { featureName: string; eventName: string }> = {
      STUDY_SESSION_COMPLETED: { featureName: 'Study Planner', eventName: 'STUDY_SESSION_COMPLETED' },
      STUDY_SESSION_STARTED: { featureName: 'Study Planner', eventName: 'STUDY_SESSION_STARTED' },
      POMODORO_COMPLETED: { featureName: 'Pomodoro Timer', eventName: 'POMODORO_COMPLETED' },
      TASK_COMPLETED: { featureName: 'Task Manager (To-Do)', eventName: 'TASK_COMPLETED' },
      TASK_CREATED: { featureName: 'Task Manager (To-Do)', eventName: 'TASK_CREATED' },
      HABIT_CREATED: { featureName: 'Daily Habit Tracker', eventName: 'HABIT_CREATED' },
      GOAL_CREATED: { featureName: 'Goal Planner', eventName: 'GOAL_CREATED' },
    };

    const aggregatedFeatures = new Map<string, number>();
    let totalFeatureEvents = 0;

    events.forEach((evt) => {
      const mapped = featureMap[evt.event_name.toUpperCase()];
      if (mapped) {
        aggregatedFeatures.set(mapped.featureName, (aggregatedFeatures.get(mapped.featureName) || 0) + 1);
        totalFeatureEvents++;
      }
    });

    const mostUsedFeatures: MostUsedFeature[] = [];
    if (totalFeatureEvents > 0) {
      aggregatedFeatures.forEach((count, featureName) => {
        mostUsedFeatures.push({
          featureName,
          eventName: 'Aggregated feature telemetry',
          count,
          pct: Number(((count / totalFeatureEvents) * 100).toFixed(1)),
        });
      });
      mostUsedFeatures.sort((a, b) => b.count - a.count);
    }

    const hasFeatureTracking = events.length > 0;
    const featureTrackingNotice = hasFeatureTracking
      ? undefined
      : 'Feature usage analytics require event tracking.';

    return {
      range,
      generatedAt: new Date().toISOString(),
      totalUsers,
      newUsers,
      newUsersPreviousPeriod,
      growthPct,
      growthIsPositive,
      dau,
      wau,
      hasActiveUserData,
      activeUserNotice,
      totalEligibleUsers,
      freeUsersCount,
      freeUsersPct,
      proUsersCount,
      proUsersPct,
      hasProPlan,
      conversionRate,
      retention7dRate,
      hasRetentionData,
      retentionNotice,
      growthChart,
      productUsage,
      mostUsedFeatures,
      hasFeatureTracking,
      featureTrackingNotice,
      hasPaymentIntegration: false,
      revenueNotice: 'Payment analytics will become available after payment integration.',
    };
  },

  /**
   * Records an audit log entry when an admin views product analytics.
   */
  async logAnalyticsView(adminEmail: string): Promise<void> {
    try {
      await auditService.logAction(
        'ANALYTICS_VIEWED',
        undefined,
        undefined,
        {
          timestamp: new Date().toISOString(),
          context: 'Admin viewed Product Growth & Usage Analytics',
        },
        adminEmail
      );
    } catch (err) {
      console.warn('Failed to record analytics viewed audit:', err);
    }
  },
};
