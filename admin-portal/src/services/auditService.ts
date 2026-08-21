import { getSupabaseClient, getSupabaseCredentials, getDemoAuditLogs, addDemoAuditLog } from '../lib/supabase';
import { AdminAuditLog, AuditAction } from '../types';

export const auditService = {
  /**
   * Logs an administrative action in the admin_audit_logs table.
   */
  async logAction(
    action: AuditAction,
    targetUserId?: string,
    adminId?: string,
    metadata: Record<string, unknown> = {},
    adminEmail?: string,
    targetUserEmail?: string
  ): Promise<void> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const effectiveAdminId = adminId || 'adm-001';

    if (isConfigured && supabase) {
      try {
        await supabase.from('admin_audit_logs').insert({
          admin_id: effectiveAdminId,
          action,
          target_user_id: targetUserId || null,
          metadata,
          timestamp: new Date().toISOString(),
        });
      } catch (err) {
        console.error('Failed to write admin audit log to Supabase:', err);
      }
      return;
    }

    // Demo Mode Logging
    const newLog: AdminAuditLog = {
      id: `audit-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      admin_id: effectiveAdminId,
      admin_email: adminEmail || 'admin@wrindhaos.com',
      action,
      target_user_id: targetUserId,
      target_user_email: targetUserEmail,
      timestamp: new Date().toISOString(),
      metadata,
    };
    addDemoAuditLog(newLog);
  },


  /**
   * Fetches audit history for a specific user or global admin actions.
   */
  async getAuditLogsForUser(userId: string): Promise<AdminAuditLog[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('admin_audit_logs')
          .select('*')
          .eq('target_user_id', userId)
          .order('timestamp', { ascending: false });

        if (error) {
          console.warn('Could not query admin_audit_logs:', error.message);
          return [];
        }
        return (data || []) as AdminAuditLog[];
      } catch {
        return [];
      }
    }

    // Demo Mode
    const allLogs = getDemoAuditLogs();
    return allLogs.filter((l) => l.target_user_id === userId);
  },

  /**
   * Fetches all recent audit logs.
   */
  async getRecentLogs(limit = 20): Promise<AdminAuditLog[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('admin_audit_logs')
          .select('*')
          .order('timestamp', { ascending: false })
          .limit(limit);

        if (error) throw error;
        return (data || []) as AdminAuditLog[];
      } catch (err) {
        console.warn('Could not fetch recent logs from Supabase:', err);
      }
    }

    const allLogs = getDemoAuditLogs();
    return allLogs.slice(0, limit);
  },
};

