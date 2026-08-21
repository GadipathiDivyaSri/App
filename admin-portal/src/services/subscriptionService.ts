import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoUsers,
  getDemoPlans,
  saveDemoPlans,
  getDemoSubscriptions,
  saveDemoSubscriptions,
} from '../lib/supabase';
import {
  SubscriptionPlan,
  UserSubscription,
  SubscriptionKPIs,
  SubscriptionQueryParams,
  PaginatedResult,
  PlanSlug,
  WrindhaUser,
} from '../types';
import { INITIAL_PLANS } from '../lib/defaultPlanData';
import { auditService } from './auditService';

export const subscriptionService = {
  /**
   * Fetches accurate Subscription KPIs directly from database/storage.
   */
  async getSubscriptionKPIs(): Promise<SubscriptionKPIs> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        // Fetch total users count
        const { count: totalCount } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true });

        // Fetch plans to map IDs
        const { data: plansData } = await supabase.from('subscription_plans').select('id, slug');
        const freePlanId = plansData?.find((p) => p.slug === 'free')?.id;
        const proPlanId = plansData?.find((p) => p.slug === 'pro')?.id;

        // Count user_subscriptions by statuses
        const { count: activeProCount } = await supabase
          .from('user_subscriptions')
          .select('*', { count: 'exact', head: true })
          .eq('plan_id', proPlanId || '')
          .eq('status', 'ACTIVE');

        const { count: trialCount } = await supabase
          .from('user_subscriptions')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'TRIALING');

        const { count: cancelledCount } = await supabase
          .from('user_subscriptions')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'CANCELLED');

        const { count: expiredCount } = await supabase
          .from('user_subscriptions')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'EXPIRED');

        // Total Pro subscribers (Active, Trialing, Cancelled, Expired)
        const { count: totalProSubscriptions } = await supabase
          .from('user_subscriptions')
          .select('*', { count: 'exact', head: true })
          .eq('plan_id', proPlanId || '');

        const totalUsers = totalCount || 0;
        const proUsers = totalProSubscriptions || 0;
        // Default users without active Pro subscription are on Free
        const freeUsers = Math.max(0, totalUsers - proUsers);

        return {
          totalUsers,
          freeUsers,
          proUsers,
          trialUsers: trialCount || 0,
          activePro: activeProCount || 0,
          cancelled: cancelledCount || 0,
          expired: expiredCount || 0,
        };
      } catch (err) {
        console.error('Error querying subscription KPIs from Supabase:', err);
      }
    }

    // Demo Mode KPI calculation
    await new Promise((resolve) => setTimeout(resolve, 150));
    const allUsers = getDemoUsers();
    const allSubs = getDemoSubscriptions();
    const plans = getDemoPlans();
    const proPlan = plans.find((p) => p.slug === 'pro') || INITIAL_PLANS[1];

    const proSubs = allSubs.filter((s) => s.plan_id === proPlan.id);
    const totalUsers = allUsers.length;
    const proUsers = proSubs.length;
    const freeUsers = Math.max(0, totalUsers - proUsers);
    const trialUsers = allSubs.filter((s) => s.status === 'TRIALING').length;
    const activePro = allSubs.filter((s) => s.plan_id === proPlan.id && s.status === 'ACTIVE').length;
    const cancelled = allSubs.filter((s) => s.status === 'CANCELLED').length;
    const expired = allSubs.filter((s) => s.status === 'EXPIRED').length;

    return {
      totalUsers,
      freeUsers,
      proUsers,
      trialUsers,
      activePro,
      cancelled,
      expired,
    };
  },

  /**
   * Fetches paginated subscription records with user and plan details.
   */
  async getSubscriptions(params: SubscriptionQueryParams): Promise<PaginatedResult<UserSubscription>> {
    const {
      page = 1,
      pageSize = 20,
      search = '',
      filters,
      sortField = 'created_at',
      sortOrder = 'desc',
    } = params;

    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        let query = supabase
          .from('user_subscriptions')
          .select('*, user:users(*), plan:subscription_plans(*)', { count: 'exact' });

        // Filter: Plan
        if (filters?.plan && filters.plan !== 'all') {
          const { data: matchedPlan } = await supabase
            .from('subscription_plans')
            .select('id')
            .eq('slug', filters.plan)
            .single();

          if (matchedPlan) {
            query = query.eq('plan_id', matchedPlan.id);
          }
        }

        // Filter: Status
        if (filters?.status && filters.status !== 'all') {
          query = query.eq('status', filters.status);
        }

        // Filter: Date Range
        if (filters?.dateRange && filters.dateRange !== 'all') {
          const now = new Date();
          if (filters.dateRange === 'today') {
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
            query = query.gte('started_at', startOfDay);
          } else if (filters.dateRange === '7d') {
            const d = new Date(now.getTime() - 7 * 86400000).toISOString();
            query = query.gte('started_at', d);
          } else if (filters.dateRange === '30d') {
            const d = new Date(now.getTime() - 30 * 86400000).toISOString();
            query = query.gte('started_at', d);
          } else if (filters.dateRange === '90d') {
            const d = new Date(now.getTime() - 90 * 86400000).toISOString();
            query = query.gte('started_at', d);
          } else if (filters.dateRange === 'custom') {
            if (filters.customStartDate) {
              query = query.gte('started_at', new Date(filters.customStartDate).toISOString());
            }
            if (filters.customEndDate) {
              const end = new Date(filters.customEndDate);
              end.setHours(23, 59, 59, 999);
              query = query.lte('started_at', end.toISOString());
            }
          }
        }

        // Pagination
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;
        query = query.range(from, to);

        const { data, count, error } = await query;
        if (error) throw new Error(error.message);

        let results = (data || []) as UserSubscription[];

        // In-memory search filtering if text search is provided
        if (search && search.trim()) {
          const q = search.trim().toLowerCase();
          results = results.filter((sub) => {
            const userName = sub.user?.name?.toLowerCase() || '';
            const userEmail = sub.user?.email?.toLowerCase() || '';
            const userId = sub.user_id?.toLowerCase() || '';
            const subId = sub.id?.toLowerCase() || '';
            return userName.includes(q) || userEmail.includes(q) || userId.includes(q) || subId.includes(q);
          });
        }

        const total = count || results.length;
        return {
          data: results,
          total,
          page,
          pageSize,
          totalPages: Math.ceil(total / pageSize) || 1,
        };
      } catch (err) {
        console.error('Error fetching live subscriptions from Supabase:', err);
      }
    }

    // Demo Mode implementation
    await new Promise((resolve) => setTimeout(resolve, 150));
    const allUsers = getDemoUsers();
    const allPlans = getDemoPlans();
    let allSubs = getDemoSubscriptions();

    // Reconcile and augment demo subscriptions
    const augmentedSubs: UserSubscription[] = allSubs.map((sub) => {
      const user = allUsers.find((u) => u.id === sub.user_id);
      const plan = allPlans.find((p) => p.id === sub.plan_id) || allPlans[0];
      return {
        ...sub,
        user,
        plan,
      };
    });

    let filtered = [...augmentedSubs];

    // Search filter
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter((sub) => {
        const nameMatch = sub.user?.name?.toLowerCase().includes(q);
        const emailMatch = sub.user?.email?.toLowerCase().includes(q);
        const userIdMatch = sub.user_id?.toLowerCase().includes(q);
        const subIdMatch = sub.id?.toLowerCase().includes(q);
        return Boolean(nameMatch || emailMatch || userIdMatch || subIdMatch);
      });
    }

    // Plan filter
    if (filters?.plan && filters.plan !== 'all') {
      filtered = filtered.filter((sub) => sub.plan?.slug === filters.plan);
    }

    // Status filter
    if (filters?.status && filters.status !== 'all') {
      filtered = filtered.filter((sub) => sub.status === filters.status);
    }

    // Date range filter
    if (filters?.dateRange && filters.dateRange !== 'all') {
      const now = Date.now();
      filtered = filtered.filter((sub) => {
        const startTime = new Date(sub.started_at).getTime();
        if (filters.dateRange === 'today') {
          return now - startTime <= 86400000;
        } else if (filters.dateRange === '7d') {
          return now - startTime <= 7 * 86400000;
        } else if (filters.dateRange === '30d') {
          return now - startTime <= 30 * 86400000;
        } else if (filters.dateRange === '90d') {
          return now - startTime <= 90 * 86400000;
        } else if (filters.dateRange === 'custom') {
          const start = filters.customStartDate ? new Date(filters.customStartDate).getTime() : 0;
          const end = filters.customEndDate ? new Date(filters.customEndDate).getTime() + 86400000 : Infinity;
          return startTime >= start && startTime <= end;
        }
        return true;
      });
    }

    // Sorting
    filtered.sort((a, b) => {
      let valA: string | number = '';
      let valB: string | number = '';

      if (sortField === 'user_name') {
        valA = a.user?.name || '';
        valB = b.user?.name || '';
      } else if (sortField === 'plan') {
        valA = a.plan?.name || '';
        valB = b.plan?.name || '';
      } else if (sortField === 'status') {
        valA = a.status;
        valB = b.status;
      } else if (sortField === 'started_at' || sortField === 'created_at') {
        const timeA = new Date(a.started_at).getTime();
        const timeB = new Date(b.started_at).getTime();
        return sortOrder === 'asc' ? timeA - timeB : timeB - timeA;
      } else if (sortField === 'current_period_end') {
        const timeA = a.current_period_end ? new Date(a.current_period_end).getTime() : 0;
        const timeB = b.current_period_end ? new Date(b.current_period_end).getTime() : 0;
        return sortOrder === 'asc' ? timeA - timeB : timeB - timeA;
      }

      if (typeof valA === 'string' && typeof valB === 'string') {
        return sortOrder === 'asc' ? valA.localeCompare(valB) : valB.localeCompare(valA);
      }
      return 0;
    });

    const total = filtered.length;
    const totalPages = Math.ceil(total / pageSize) || 1;
    const startIndex = (page - 1) * pageSize;
    const paginatedData = filtered.slice(startIndex, startIndex + pageSize);

    return {
      data: paginatedData,
      total,
      page,
      pageSize,
      totalPages,
    };
  },

  /**
   * Fetches single subscription by ID and logs SUBSCRIPTION_VIEWED.
   */
  async getSubscriptionById(
    id: string,
    adminId?: string,
    adminEmail?: string
  ): Promise<UserSubscription | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('user_subscriptions')
          .select('*, user:users(*), plan:subscription_plans(*)')
          .eq('id', id)
          .single();

        if (error || !data) return null;

        const sub = data as UserSubscription;
        if (adminId) {
          await auditService.logAction(
            'SUBSCRIPTION_VIEWED',
            sub.user_id,
            adminId,
            { subscription_id: id, plan_slug: sub.plan?.slug },
            adminEmail,
            sub.user?.email
          );
        }

        return sub;
      } catch (err) {
        console.error('Error fetching subscription by ID from Supabase:', err);
      }
    }

    // Demo Mode
    await new Promise((resolve) => setTimeout(resolve, 150));
    const allUsers = getDemoUsers();
    const allPlans = getDemoPlans();
    const allSubs = getDemoSubscriptions();

    const sub = allSubs.find((s) => s.id === id);
    if (!sub) return null;

    const user = allUsers.find((u) => u.id === sub.user_id);
    const plan = allPlans.find((p) => p.id === sub.plan_id) || allPlans[0];

    const result: UserSubscription = {
      ...sub,
      user,
      plan,
    };

    if (adminId) {
      await auditService.logAction(
        'SUBSCRIPTION_VIEWED',
        result.user_id,
        adminId,
        { subscription_id: id, plan_slug: result.plan?.slug },
        adminEmail,
        result.user?.email
      );
    }

    return result;
  },

  /**
   * Fetches user subscription by user ID or creates default Free record.
   */
  async getSubscriptionByUserId(userId: string): Promise<UserSubscription | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('user_subscriptions')
          .select('*, user:users(*), plan:subscription_plans(*)')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();

        if (data) return data as UserSubscription;

        // If user has no record in user_subscriptions, fetch user & free plan to synthesize default
        const { data: userData } = await supabase.from('users').select('*').eq('id', userId).single();
        const { data: freePlan } = await supabase
          .from('subscription_plans')
          .select('*')
          .eq('slug', 'free')
          .single();


        if (userData && freePlan) {
          return {
            id: `sub-default-${userId.substring(0, 8)}`,
            user_id: userId,
            plan_id: freePlan.id,
            status: 'ACTIVE',
            started_at: userData.created_at,
            current_period_start: null,
            current_period_end: null,
            trial_started_at: null,
            trial_ends_at: null,
            cancelled_at: null,
            ended_at: null,
            created_at: userData.created_at,
            updated_at: userData.updated_at || userData.created_at,
            user: userData as WrindhaUser,
            plan: freePlan as SubscriptionPlan,
          };
        }
      } catch (err) {
        console.error('Error fetching user subscription from Supabase:', err);
      }
    }

    // Demo Mode
    await new Promise((resolve) => setTimeout(resolve, 100));
    const allUsers = getDemoUsers();
    const allPlans = getDemoPlans();
    const allSubs = getDemoSubscriptions();

    const user = allUsers.find((u) => u.id === userId);
    if (!user) return null;

    const sub = allSubs.find((s) => s.user_id === userId);
    const freePlan = allPlans.find((p) => p.slug === 'free') || allPlans[0];

    if (sub) {
      const plan = allPlans.find((p) => p.id === sub.plan_id) || freePlan;
      return { ...sub, user, plan };
    }

    return {
      id: `sub-default-${userId}`,
      user_id: userId,
      plan_id: freePlan.id,
      status: 'ACTIVE',
      started_at: user.created_at,
      current_period_start: null,
      current_period_end: null,
      trial_started_at: null,
      trial_ends_at: null,
      cancelled_at: null,
      ended_at: null,
      created_at: user.created_at,
      updated_at: user.updated_at || user.created_at,
      user,
      plan: freePlan,
    };
  },

  /**
   * Fetches all available subscription plans (Free and Pro only).
   */
  async getPlans(): Promise<SubscriptionPlan[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('subscription_plans')
          .select('*')
          .order('price', { ascending: true });

        if (error) throw new Error(error.message);
        if (data && data.length > 0) return data as SubscriptionPlan[];
      } catch (err) {
        console.error('Error fetching plans from Supabase:', err);
      }
    }

    return getDemoPlans();
  },

  /**
   * Fetches a single plan by slug ('free' or 'pro').
   */
  async getPlanBySlug(slug: PlanSlug): Promise<SubscriptionPlan | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('subscription_plans')
          .select('*')
          .eq('slug', slug)
          .single();

        if (error) throw new Error(error.message);
        if (data) return data as SubscriptionPlan;
      } catch (err) {
        console.error('Error fetching plan by slug from Supabase:', err);
      }
    }

    const plans = getDemoPlans();
    return plans.find((p) => p.slug === slug) || null;
  },

  /**
   * Updates plan configuration, features, and pricing with strict validation and audit logging.
   */
  async updatePlan(
    planId: string,
    updates: Partial<SubscriptionPlan>,
    adminId?: string,
    adminEmail?: string
  ): Promise<{ success: boolean; error?: string; plan?: SubscriptionPlan }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const effectiveAdminId = adminId || 'adm-001';

    // Retrieve current plan to inspect changes
    let currentPlan: SubscriptionPlan | null = null;
    if (isConfigured && supabase) {
      const { data } = await supabase.from('subscription_plans').select('*').eq('id', planId).single();
      currentPlan = data as SubscriptionPlan | null;
    } else {
      const plans = getDemoPlans();
      currentPlan = plans.find((p) => p.id === planId) || null;
    }

    if (!currentPlan) {
      return { success: false, error: 'Plan record not found.' };
    }

    // Safety rule: Free plan price cannot be changed from 0
    if (currentPlan.slug === 'free' && updates.price !== undefined && updates.price !== 0) {
      return { success: false, error: 'The Free plan price is permanently locked at ₹0.' };
    }

    const now = new Date().toISOString();
    const payload = {
      ...updates,
      updated_at: now,
    };

    // Live Supabase update
    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('subscription_plans')
          .update(payload)
          .eq('id', planId)
          .select()
          .single();

        if (error) throw new Error(error.message);

        // Audit Logging
        if (updates.price !== undefined && updates.price !== currentPlan.price) {
          await auditService.logAction(
            'PLAN_PRICE_CHANGED',
            undefined,
            effectiveAdminId,
            {
              plan_id: planId,
              plan_slug: currentPlan.slug,
              previous_price: currentPlan.price,
              new_price: updates.price,
              currency: currentPlan.currency,
              timestamp: now,
            },
            adminEmail
          );
        }

        if (updates.features) {
          await auditService.logAction(
            'PLAN_FEATURES_CHANGED',
            undefined,
            effectiveAdminId,
            {
              plan_id: planId,
              plan_slug: currentPlan.slug,
              feature_count: updates.features.length,
            },
            adminEmail
          );
        }

        await auditService.logAction(
          'PLAN_UPDATED',
          undefined,
          effectiveAdminId,
          {
            plan_id: planId,
            plan_slug: currentPlan.slug,
            updated_fields: Object.keys(updates),
          },
          adminEmail
        );

        return { success: true, plan: data as SubscriptionPlan };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to update plan in database.';
        return { success: false, error: msg };
      }
    }

    // Demo Mode Update
    const plans = getDemoPlans();
    const idx = plans.findIndex((p) => p.id === planId);
    if (idx === -1) return { success: false, error: 'Plan not found.' };

    const updatedPlan: SubscriptionPlan = {
      ...plans[idx],
      ...payload,
    };
    plans[idx] = updatedPlan;
    saveDemoPlans(plans);

    // Audit Logging
    if (updates.price !== undefined && updates.price !== currentPlan.price) {
      await auditService.logAction(
        'PLAN_PRICE_CHANGED',
        undefined,
        effectiveAdminId,
        {
          plan_id: planId,
          plan_slug: currentPlan.slug,
          previous_price: currentPlan.price,
          new_price: updates.price,
          currency: currentPlan.currency,
          timestamp: now,
        },
        adminEmail
      );
    }

    if (updates.features) {
      await auditService.logAction(
        'PLAN_FEATURES_CHANGED',
        undefined,
        effectiveAdminId,
        {
          plan_id: planId,
          plan_slug: currentPlan.slug,
          feature_count: updates.features.length,
        },
        adminEmail
      );
    }

    await auditService.logAction(
      'PLAN_UPDATED',
      undefined,
      effectiveAdminId,
      {
        plan_id: planId,
        plan_slug: currentPlan.slug,
        updated_fields: Object.keys(updates),
      },
      adminEmail
    );

    return { success: true, plan: updatedPlan };
  },
};
