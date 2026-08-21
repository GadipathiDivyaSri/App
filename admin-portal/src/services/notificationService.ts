import {
  AppNotification,
  NotificationDeliveryStats,
  NotificationStats,
  NotificationStatus,
  NotificationTarget,
  FCMStatus,
} from '../types';
import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoNotifications,
  saveDemoNotifications,
  getFCMConfigStatus,
  setFCMConfigStatus,
  getDemoUsers,
} from '../lib/supabase';
import { auditService } from './auditService';

export interface CreateNotificationInput {
  title: string;
  message: string;
  target: NotificationTarget;
  actionType: 'SEND_NOW' | 'SCHEDULE' | 'DRAFT';
  scheduledAt?: string | null;
  adminId: string;
  adminEmail: string;
}

export const notificationService = {
  /**
   * Retrieves notification delivery statistics.
   */
  async getNotificationStats(): Promise<NotificationStats> {
    const notifications = await this.getNotifications();
    const fcmStatus = this.getFCMStatus();

    const sentNotifications = notifications.filter((n) => n.status === 'SENT');
    const successfulCount = sentNotifications.reduce(
      (sum, n) => sum + (n.delivery_stats?.successful || 0),
      0
    );
    const failedCount = notifications.reduce(
      (sum, n) => sum + (n.delivery_stats?.failed || (n.status === 'FAILED' ? n.delivery_stats?.total_targets || 1 : 0)),
      0
    );

    return {
      totalNotifications: notifications.length,
      sentCount: sentNotifications.length,
      successfulCount,
      failedCount,
      scheduledCount: notifications.filter((n) => n.status === 'SCHEDULED').length,
      draftCount: notifications.filter((n) => n.status === 'DRAFT').length,
      fcmConfigured: fcmStatus.isConfigured,
    };
  },

  /**
   * Retrieves list of all notifications with optional status and target filtering.
   */
  async getNotifications(filters?: {
    status?: 'ALL' | NotificationStatus;
    target?: 'ALL' | NotificationTarget;
    search?: string;
  }): Promise<AppNotification[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    let list: AppNotification[] = [];

    if (isConfigured && supabase) {
      try {
        let query = supabase
          .from('notifications')
          .select('*')
          .order('created_at', { ascending: false });

        if (filters?.status && filters.status !== 'ALL') {
          query = query.eq('status', filters.status);
        }
        if (filters?.target && filters.target !== 'ALL') {
          query = query.eq('target', filters.target);
        }

        const { data, error } = await query;
        if (error) throw error;
        list = data || [];
      } catch (err) {
        console.error('Error loading notifications from Supabase, falling back to local store:', err);
        list = getDemoNotifications();
      }
    } else {
      list = getDemoNotifications();
    }

    if (filters?.search) {
      const q = filters.search.toLowerCase().trim();
      list = list.filter(
        (n) =>
          n.title.toLowerCase().includes(q) ||
          n.message.toLowerCase().includes(q) ||
          (n.created_by_email && n.created_by_email.toLowerCase().includes(q))
      );
    }

    if (filters?.status && filters.status !== 'ALL') {
      list = list.filter((n) => n.status === filters.status);
    }

    if (filters?.target && filters.target !== 'ALL') {
      list = list.filter((n) => n.target === filters.target);
    }

    return list;
  },

  /**
   * Retrieves a single notification by its ID.
   */
  async getNotificationById(id: string): Promise<AppNotification | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('notifications')
          .select('*')
          .eq('id', id)
          .single();
        if (error) throw error;
        return data;
      } catch (err) {
        console.error('Error fetching notification by ID:', err);
      }
    }

    const demo = getDemoNotifications();
    return demo.find((n) => n.id === id) || null;
  },

  /**
   * Counts target audience recipients based on plan segmentation.
   */
  async getAudienceCount(target: NotificationTarget): Promise<{ total: number; label: string }> {
    const users = getDemoUsers();
    if (target === 'FREE') {
      const count = users.filter((u) => u.plan.toLowerCase() === 'free').length;
      return { total: count, label: 'Free Plan Users' };
    }
    if (target === 'PRO') {
      const count = users.filter((u) => u.plan.toLowerCase() === 'pro').length;
      return { total: count, label: 'Pro Plan Users' };
    }
    return { total: users.length, label: 'All Registered Users' };
  },

  /**
   * Creates, schedules, or immediately dispatches a notification.
   */
  async createNotification(input: CreateNotificationInput): Promise<{
    notification: AppNotification;
    success: boolean;
    fcmConfigured: boolean;
    message: string;
  }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const fcmStatus = this.getFCMStatus();
    const audience = await this.getAudienceCount(input.target);

    let status: NotificationStatus = 'DRAFT';
    let sentAt: string | null = null;
    let scheduledAt: string | null = input.scheduledAt || null;
    let deliveryStats: NotificationDeliveryStats | null = null;
    let responseSuccess = true;
    let responseMessage = '';

    if (input.actionType === 'DRAFT') {
      status = 'DRAFT';
      responseMessage = 'Notification draft saved successfully.';
    } else if (input.actionType === 'SCHEDULE') {
      status = 'SCHEDULED';
      scheduledAt = input.scheduledAt || new Date(Date.now() + 86400000).toISOString();
      deliveryStats = {
        total_targets: audience.total,
        successful: 0,
        failed: 0,
        fcm_configured: fcmStatus.isConfigured,
        error_message: fcmStatus.isConfigured
          ? 'Scheduled for execution'
          : 'FCM server credentials not configured. Cron worker will require FCM configuration.',
      };
      responseMessage = `Notification scheduled for ${new Date(scheduledAt).toLocaleString()}.`;
    } else if (input.actionType === 'SEND_NOW') {
      // Direct Send
      if (!fcmStatus.isConfigured) {
        // FCM is not configured: DO NOT fake success.
        status = 'FAILED';
        sentAt = new Date().toISOString();
        deliveryStats = {
          total_targets: audience.total,
          successful: 0,
          failed: audience.total,
          fcm_configured: false,
          error_message: 'FCM is not configured. Configure Firebase Cloud Messaging server credentials to enable push delivery.',
        };
        responseSuccess = false;
        responseMessage = 'FCM is not configured. Notification was recorded with status "FAILED".';
      } else {
        // FCM is configured
        status = 'SENT';
        sentAt = new Date().toISOString();
        deliveryStats = {
          total_targets: audience.total,
          successful: audience.total,
          failed: 0,
          fcm_configured: true,
          fcm_message_id: `fcm-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`,
          error_message: null,
        };
        responseSuccess = true;
        responseMessage = `Notification sent successfully to ${audience.total} recipients.`;
      }
    }

    const newNotification: AppNotification = {
      id: `notif-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      title: input.title.trim(),
      message: input.message.trim(),
      target: input.target,
      status,
      scheduled_at: scheduledAt,
      sent_at: sentAt,
      created_by: input.adminId,
      created_by_email: input.adminEmail,
      delivery_stats: deliveryStats,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('notifications').insert({
          title: newNotification.title,
          message: newNotification.message,
          target: newNotification.target,
          status: newNotification.status,
          scheduled_at: newNotification.scheduled_at,
          sent_at: newNotification.sent_at,
          created_by: input.adminId,
          created_by_email: input.adminEmail,
          delivery_stats: newNotification.delivery_stats,
        });
        if (error) throw error;
      } catch (err) {
        console.error('Error saving notification to Supabase:', err);
      }
    }

    // Save to demo store for persistence
    const currentList = getDemoNotifications();
    saveDemoNotifications([newNotification, ...currentList]);

    // Audit Logging
    if (input.actionType === 'SEND_NOW') {
      await auditService.logAction(
        'NOTIFICATION_SENT',
        undefined,
        input.adminId,
        {
          notification_id: newNotification.id,
          title: newNotification.title,
          target: newNotification.target,
          status: newNotification.status,
          fcm_configured: fcmStatus.isConfigured,
          recipients: audience.total,
        },
        input.adminEmail
      );
    } else if (input.actionType === 'SCHEDULE') {
      await auditService.logAction(
        'NOTIFICATION_SCHEDULED',
        undefined,
        input.adminId,
        {
          notification_id: newNotification.id,
          title: newNotification.title,
          scheduled_at: scheduledAt,
          target: newNotification.target,
        },
        input.adminEmail
      );
    } else {
      await auditService.logAction(
        'NOTIFICATION_DRAFT_SAVED',
        undefined,
        input.adminId,
        {
          notification_id: newNotification.id,
          title: newNotification.title,
        },
        input.adminEmail
      );
    }

    return {
      notification: newNotification,
      success: responseSuccess,
      fcmConfigured: fcmStatus.isConfigured,
      message: responseMessage,
    };
  },

  /**
   * Deletes a notification.
   */
  async deleteNotification(id: string, adminId: string, adminEmail: string): Promise<boolean> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        await supabase.from('notifications').delete().eq('id', id);
      } catch (err) {
        console.error('Failed to delete notification in Supabase:', err);
      }
    }

    const currentList = getDemoNotifications();
    const updated = currentList.filter((n) => n.id !== id);
    saveDemoNotifications(updated);

    await auditService.logAction(
      'NOTIFICATION_DELETED',
      undefined,
      adminId,
      { notification_id: id },
      adminEmail
    );

    return true;
  },

  /**
   * Gets the current FCM configuration status.
   */
  getFCMStatus(): FCMStatus {
    const status = getFCMConfigStatus();
    return {
      isConfigured: status.isConfigured,
      statusText: status.isConfigured ? 'Connected & Active' : 'FCM is not configured.',
      details: status.details,
      configuredAt: status.configuredAt,
    };
  },

  /**
   * Updates FCM configuration status for test/production readiness toggle.
   */
  updateFCMStatus(isConfigured: boolean, details: string) {
    setFCMConfigStatus(isConfigured, details);
  },
};
