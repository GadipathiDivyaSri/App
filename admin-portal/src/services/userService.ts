import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoUsers,
  saveDemoUsers,
  DEMO_USER_ACTIVITIES,
  getDemoDeletionRequests,
  addDemoDeletionRequest,
} from '../lib/supabase';
import {
  WrindhaUser,
  DashboardStats,
  PaginationParams,
  PaginatedResult,
  UserActivityLog,
  AccountDeletionRequest,
} from '../types';
import { auditService } from './auditService';

export const userService = {
  /**
   * Fetches dashboard metrics including total users, active users, plan breakdown, and growth timeline.
   */
  async getDashboardStats(range: '7d' | '30d' | '90d' = '30d'): Promise<DashboardStats> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { count: totalCount, error: totalError } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true });

        if (totalError) throw new Error(totalError.message);

        const { count: activeCount } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'active');

        const { count: freeCount } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('plan', 'Free');

        const { count: proCount } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('plan', 'Pro');

        const proUsersDisplay = proCount !== null ? proCount : 0;

        const days = range === '7d' ? 7 : range === '30d' ? 30 : 90;
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days);

        const { data: usersWithinRange } = await supabase
          .from('users')
          .select('created_at')
          .gte('created_at', startDate.toISOString())
          .order('created_at', { ascending: true });

        let userGrowth: { date: string; label: string; count: number }[] = [];

        if (usersWithinRange && usersWithinRange.length > 0) {
          const dateMap = new Map<string, number>();

          for (let i = days - 1; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = d.toISOString().split('T')[0];
            dateMap.set(dateStr, 0);
          }

          usersWithinRange.forEach((u) => {
            if (u.created_at) {
              const dateStr = u.created_at.split('T')[0];
              if (dateMap.has(dateStr)) {
                dateMap.set(dateStr, (dateMap.get(dateStr) || 0) + 1);
              }
            }
          });

          userGrowth = Array.from(dateMap.entries()).map(([dateStr, count]) => {
            const dateObj = new Date(dateStr);
            return {
              date: dateStr,
              label: dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
              count,
            };
          });
        }

        return {
          totalUsers: totalCount || 0,
          activeUsers: activeCount || 0,
          freeUsers: freeCount || 0,
          proUsers: proUsersDisplay,
          userGrowth,
        };
      } catch (err) {
        console.error('Error fetching live stats:', err);
        throw err;
      }
    }

    // Demo Mode Fallback
    await new Promise((resolve) => setTimeout(resolve, 200));
    const allUsers = getDemoUsers();
    const totalUsers = allUsers.length;
    const activeUsers = allUsers.filter((u) => u.status === 'active').length;
    const freeUsers = allUsers.filter((u) => u.plan === 'Free').length;
    const proUsers = allUsers.filter((u) => u.plan === 'Pro').length;


    const days = range === '7d' ? 7 : range === '30d' ? 30 : 90;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const usersWithinRange = allUsers.filter(
      (u) => new Date(u.created_at).getTime() >= startDate.getTime()
    );

    const dateMap = new Map<string, number>();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      dateMap.set(dateStr, 0);
    }

    usersWithinRange.forEach((u) => {
      const dateStr = u.created_at.split('T')[0];
      if (dateMap.has(dateStr)) {
        dateMap.set(dateStr, (dateMap.get(dateStr) || 0) + 1);
      }
    });

    const userGrowth = Array.from(dateMap.entries()).map(([dateStr, count]) => {
      const dateObj = new Date(dateStr);
      return {
        date: dateStr,
        label: dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
        count,
      };
    });

    return {
      totalUsers,
      activeUsers,
      freeUsers,
      proUsers,
      userGrowth,
    };
  },

  /**
   * Fetches latest registered users.
   */
  async getRecentUsers(limit: number = 5): Promise<WrindhaUser[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('users')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(limit);

        if (error) throw new Error(error.message);
        return (data || []) as WrindhaUser[];
      } catch (err) {
        console.error('Error fetching recent users from Supabase:', err);
        throw err;
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 150));
    return [...getDemoUsers()]
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
      .slice(0, limit);
  },

  /**
   * Complete Server-Side User Management Query: Search, Multiple Filters, Sorting, Pagination.
   */
  async getUsers(params: PaginationParams): Promise<PaginatedResult<WrindhaUser>> {
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
        let query = supabase.from('users').select('*', { count: 'exact' });

        // 1. Debounced Search (Name, Email, Phone, ID)
        if (search && search.trim()) {
          const s = search.trim();
          query = query.or(`name.ilike.%${s}%,email.ilike.%${s}%,phone.ilike.%${s}%,id.eq.${s}`);
        }

        // 2. Status Filter
        if (filters?.status && filters.status !== 'all') {
          query = query.eq('status', filters.status);
        }

        // 3. Plan Filter
        if (filters?.plan && filters.plan !== 'all') {
          query = query.eq('plan', filters.plan);
        }

        // 4. Registration Date Filter
        if (filters?.registrationDate && filters.registrationDate !== 'all') {
          const now = new Date();
          if (filters.registrationDate === 'today') {
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
            query = query.gte('created_at', startOfDay);
          } else if (filters.registrationDate === '7d') {
            const d = new Date(now.getTime() - 7 * 86400000).toISOString();
            query = query.gte('created_at', d);
          } else if (filters.registrationDate === '30d') {
            const d = new Date(now.getTime() - 30 * 86400000).toISOString();
            query = query.gte('created_at', d);
          } else if (filters.registrationDate === '90d') {
            const d = new Date(now.getTime() - 90 * 86400000).toISOString();
            query = query.gte('created_at', d);
          } else if (filters.registrationDate === 'custom') {
            if (filters.customStartDate) {
              query = query.gte('created_at', new Date(filters.customStartDate).toISOString());
            }
            if (filters.customEndDate) {
              const end = new Date(filters.customEndDate);
              end.setHours(23, 59, 59, 999);
              query = query.lte('created_at', end.toISOString());
            }
          }
        }

        // 5. Last Active Filter
        if (filters?.lastActive && filters.lastActive !== 'all') {
          const now = new Date();
          if (filters.lastActive === 'today') {
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
            query = query.gte('last_active_at', startOfDay);
          } else if (filters.lastActive === '7d') {
            const d = new Date(now.getTime() - 7 * 86400000).toISOString();
            query = query.gte('last_active_at', d);
          } else if (filters.lastActive === '30d') {
            const d = new Date(now.getTime() - 30 * 86400000).toISOString();
            query = query.gte('last_active_at', d);
          } else if (filters.lastActive === 'inactive_30d') {
            const d = new Date(now.getTime() - 30 * 86400000).toISOString();
            query = query.or(`last_active_at.lt.${d},last_active_at.is.null`);
          }
        }

        // 6. Sorting
        query = query.order(sortField, { ascending: sortOrder === 'asc' });

        // 7. Pagination Range
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;
        query = query.range(from, to);

        const { data, count, error } = await query;
        if (error) throw new Error(error.message);

        const total = count || 0;
        return {
          data: (data || []) as WrindhaUser[],
          total,
          page,
          pageSize,
          totalPages: Math.ceil(total / pageSize) || 1,
        };
      } catch (err) {
        console.error('Error in live getUsers:', err);
        throw err;
      }
    }

    // Demo Mode: Local Simulation with strict multi-filter and sorting
    await new Promise((resolve) => setTimeout(resolve, 200));
    let filtered = [...getDemoUsers()];

    // Search filter
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter((u) => {
        const matchesName = u.name.toLowerCase().includes(q);
        const matchesEmail = u.email.toLowerCase().includes(q);
        const matchesPhone = u.phone?.toLowerCase().includes(q);
        const matchesId = u.id.toLowerCase().includes(q);
        return matchesName || matchesEmail || Boolean(matchesPhone) || matchesId;
      });
    }

    // Status filter
    if (filters?.status && filters.status !== 'all') {
      filtered = filtered.filter((u) => u.status === filters.status);
    }

    // Plan filter
    if (filters?.plan && filters.plan !== 'all') {
      filtered = filtered.filter((u) => u.plan === filters.plan);
    }

    // Registration Date Filter
    if (filters?.registrationDate && filters.registrationDate !== 'all') {
      const now = new Date().getTime();
      filtered = filtered.filter((u) => {
        const userTime = new Date(u.created_at).getTime();
        if (filters.registrationDate === 'today') {
          return now - userTime <= 86400000;
        } else if (filters.registrationDate === '7d') {
          return now - userTime <= 7 * 86400000;
        } else if (filters.registrationDate === '30d') {
          return now - userTime <= 30 * 86400000;
        } else if (filters.registrationDate === '90d') {
          return now - userTime <= 90 * 86400000;
        } else if (filters.registrationDate === 'custom') {
          const start = filters.customStartDate ? new Date(filters.customStartDate).getTime() : 0;
          const end = filters.customEndDate ? new Date(filters.customEndDate).getTime() + 86400000 : Infinity;
          return userTime >= start && userTime <= end;
        }
        return true;
      });
    }

    // Last Active Filter
    if (filters?.lastActive && filters.lastActive !== 'all') {
      const now = new Date().getTime();
      filtered = filtered.filter((u) => {
        if (!u.last_active_at) {
          return filters.lastActive === 'inactive_30d';
        }
        const activeTime = new Date(u.last_active_at).getTime();
        const diff = now - activeTime;
        if (filters.lastActive === 'today') {
          return diff <= 86400000;
        } else if (filters.lastActive === '7d') {
          return diff <= 7 * 86400000;
        } else if (filters.lastActive === '30d') {
          return diff <= 30 * 86400000;
        } else if (filters.lastActive === 'inactive_30d') {
          return diff > 30 * 86400000;
        }
        return true;
      });
    }

    // Sorting
    filtered.sort((a, b) => {
      let valA = a[sortField] ?? '';
      let valB = b[sortField] ?? '';

      if (sortField === 'created_at' || sortField === 'last_active_at') {
        const timeA = valA ? new Date(valA as string).getTime() : 0;
        const timeB = valB ? new Date(valB as string).getTime() : 0;
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
   * Fetches single user by ID and records USER_VIEWED audit log.
   */
  async getUserById(id: string, adminId?: string, adminEmail?: string): Promise<WrindhaUser | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('users')
          .select('*')
          .eq('id', id)
          .single();

        if (error || !data) return null;

        if (adminId) {
          await auditService.logAction('USER_VIEWED', id, adminId, { reason: 'Admin profile inspection' }, adminEmail, data.email);
        }

        return data as WrindhaUser;
      } catch (err) {
        console.error('Error fetching user by ID from Supabase:', err);
        return null;
      }
    }

    // Demo Mode
    await new Promise((resolve) => setTimeout(resolve, 150));
    const users = getDemoUsers();
    const user = users.find((u) => u.id === id) || null;

    if (user && adminId) {
      await auditService.logAction('USER_VIEWED', id, adminId, { reason: 'Admin profile inspection' }, adminEmail, user.email);
    }

    return user;
  },

  /**
   * Suspends a user account, records suspension reason in metadata, and creates an audit log.
   */
  async suspendUser(
    userId: string,
    reason: string,
    adminId: string,
    adminEmail?: string
  ): Promise<{ success: boolean; error?: string }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const now = new Date().toISOString();
        const { error } = await supabase
          .from('users')
          .update({
            status: 'suspended',
            updated_at: now,
          })
          .eq('id', userId);

        if (error) throw new Error(error.message);

        await auditService.logAction(
          'USER_SUSPENDED',
          userId,
          adminId,
          { reason, suspended_at: now },
          adminEmail
        );

        return { success: true };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to suspend account.';
        return { success: false, error: msg };
      }
    }

    // Demo Mode suspension
    await new Promise((resolve) => setTimeout(resolve, 300));
    const users = getDemoUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx === -1) return { success: false, error: 'User not found.' };

    const now = new Date().toISOString();
    users[idx] = {
      ...users[idx],
      status: 'suspended',
      updated_at: now,
      metadata: {
        ...users[idx].metadata,
        suspension_reason: reason,
        suspended_at: now,
        suspended_by: adminId,
      },
    };
    saveDemoUsers(users);

    await auditService.logAction(
      'USER_SUSPENDED',
      userId,
      adminId,
      { reason, suspended_at: now },
      adminEmail,
      users[idx].email
    );

    return { success: true };
  },

  /**
   * Restores a suspended user account back to active status and logs the audit event.
   */
  async restoreUser(
    userId: string,
    adminId: string,
    adminEmail?: string
  ): Promise<{ success: boolean; error?: string }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const now = new Date().toISOString();
        const { error } = await supabase
          .from('users')
          .update({
            status: 'active',
            updated_at: now,
          })
          .eq('id', userId);

        if (error) throw new Error(error.message);

        await auditService.logAction(
          'USER_RESTORED',
          userId,
          adminId,
          { restored_at: now },
          adminEmail
        );

        return { success: true };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to restore account.';
        return { success: false, error: msg };
      }
    }

    // Demo Mode restoration
    await new Promise((resolve) => setTimeout(resolve, 300));
    const users = getDemoUsers();
    const idx = users.findIndex((u) => u.id === userId);
    if (idx === -1) return { success: false, error: 'User not found.' };

    const now = new Date().toISOString();
    users[idx] = {
      ...users[idx],
      status: 'active',
      updated_at: now,
      metadata: {
        ...users[idx].metadata,
        restored_at: now,
        restored_by: adminId,
      },
    };
    saveDemoUsers(users);

    await auditService.logAction(
      'USER_RESTORED',
      userId,
      adminId,
      { restored_at: now },
      adminEmail,
      users[idx].email
    );

    return { success: true };
  },

  /**
   * Submits an account deletion request to the account_deletion_requests table and logs the audit event.
   */
  async requestAccountDeletion(
    userId: string,
    reason: string,
    adminId: string,
    adminEmail?: string
  ): Promise<{ success: boolean; error?: string }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('account_deletion_requests').insert({
          user_id: userId,
          requested_by: adminId,
          reason: reason.trim(),
          status: 'PENDING',
          created_at: new Date().toISOString(),
        });

        if (error) throw new Error(error.message);

        await auditService.logAction(
          'DELETION_REQUESTED',
          userId,
          adminId,
          { reason },
          adminEmail
        );

        return { success: true };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to create deletion request.';
        return { success: false, error: msg };
      }
    }

    // Demo Mode deletion request
    await new Promise((resolve) => setTimeout(resolve, 300));
    const users = getDemoUsers();
    const user = users.find((u) => u.id === userId);

    const newReq: AccountDeletionRequest = {
      id: `del-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      user_id: userId,
      requested_by: adminId,
      requested_by_email: adminEmail || 'admin@wrindhaos.com',
      reason: reason.trim(),
      status: 'PENDING',
      created_at: new Date().toISOString(),
      user_name: user?.name,
      user_email: user?.email,
    };
    addDemoDeletionRequest(newReq);

    await auditService.logAction(
      'DELETION_REQUESTED',
      userId,
      adminId,
      { reason },
      adminEmail,
      user?.email
    );

    return { success: true };
  },

  /**
   * Retrieves deletion requests for a specific user.
   */
  async getDeletionRequestsForUser(userId: string): Promise<AccountDeletionRequest[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('account_deletion_requests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (error) return [];
        return (data || []) as AccountDeletionRequest[];
      } catch {
        return [];
      }
    }

    const reqs = getDemoDeletionRequests();
    return reqs.filter((r) => r.user_id === userId);
  },

  /**
   * Fetches real user activities from database.
   */
  async getUserActivities(userId: string): Promise<UserActivityLog[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('user_activities')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(30);

        if (error) return [];
        return (data || []) as UserActivityLog[];
      } catch {
        return [];
      }
    }

    // Demo Mode
    await new Promise((resolve) => setTimeout(resolve, 150));
    return DEMO_USER_ACTIVITIES[userId] || [];
  },
};
