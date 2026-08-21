import React, { useState, useEffect, useMemo } from 'react';
import {
  Bell,
  Plus,
  Search,
  CheckCircle2,
  XCircle,
  Clock,
  FileText,
  AlertTriangle,
  RefreshCw,
  Eye,
  Trash2,
  Smartphone,
  ExternalLink,
  ShieldCheck,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { notificationService } from '../../services/notificationService';
import {
  AppNotification,
  NotificationStats,
  NotificationStatus,
  NotificationTarget,
  FCMStatus,
} from '../../types';
import { Badge } from '../../components/common/Badge';
import { Modal } from '../../components/common/Modal';

interface NotificationsPageProps {
  onCreateNotification: () => void;
}

export const NotificationsPage: React.FC<NotificationsPageProps> = ({
  onCreateNotification,
}) => {
  const { adminUser } = useAuth();

  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [stats, setStats] = useState<NotificationStats>({
    totalNotifications: 0,
    sentCount: 0,
    successfulCount: 0,
    failedCount: 0,
    scheduledCount: 0,
    draftCount: 0,
    fcmConfigured: false,
  });
  const [fcmStatus, setFcmStatus] = useState<FCMStatus>({
    isConfigured: false,
    statusText: '',
  });

  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'ALL' | NotificationStatus>('ALL');
  const [targetFilter, setTargetFilter] = useState<'ALL' | NotificationTarget>('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Selected Notification for Detail Modal
  const [selectedNotif, setSelectedNotif] = useState<AppNotification | null>(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);

  // Delete Confirmation
  const [notifToDelete, setNotifToDelete] = useState<AppNotification | null>(null);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // FCM Config modal (for configuring/testing FCM readiness)
  const [fcmModalOpen, setFcmModalOpen] = useState(false);
  const [fcmServerKeyInput, setFcmServerKeyInput] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [list, statData] = await Promise.all([
        notificationService.getNotifications(),
        notificationService.getNotificationStats(),
      ]);
      setNotifications(list);
      setStats(statData);
      setFcmStatus(notificationService.getFCMStatus());
    } catch (err) {
      console.error('Error loading notification data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDetail = (notif: AppNotification) => {
    setSelectedNotif(notif);
    setDetailModalOpen(true);
  };

  const handlePromptDelete = (e: React.MouseEvent, notif: AppNotification) => {
    e.stopPropagation();
    setNotifToDelete(notif);
    setDeleteModalOpen(true);
  };

  const executeDelete = async () => {
    if (!notifToDelete) return;
    setDeleting(true);
    try {
      await notificationService.deleteNotification(
        notifToDelete.id,
        adminUser?.id || 'adm-001',
        adminUser?.email || 'admin@wrindhaos.com'
      );
      setDeleteModalOpen(false);
      setNotifToDelete(null);
      await loadData();
    } catch (err) {
      console.error('Failed to delete notification:', err);
    } finally {
      setDeleting(false);
    }
  };

  const handleToggleFcmDemo = (enable: boolean) => {
    if (enable) {
      notificationService.updateFCMStatus(
        true,
        'FCM server credentials active (Cloud Messaging v1 API connected).'
      );
    } else {
      notificationService.updateFCMStatus(
        false,
        'FCM is not configured. Server credentials must be set in server environment variables.'
      );
    }
    setFcmStatus(notificationService.getFCMStatus());
    setFcmModalOpen(false);
    loadData();
  };

  // Filtered list
  const filteredNotifications = useMemo(() => {
    return notifications.filter((n) => {
      if (statusFilter !== 'ALL' && n.status !== statusFilter) return false;
      if (targetFilter !== 'ALL' && n.target !== targetFilter) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesTitle = n.title.toLowerCase().includes(q);
        const matchesMsg = n.message.toLowerCase().includes(q);
        const matchesAdmin = (n.created_by_email || '').toLowerCase().includes(q);
        if (!matchesTitle && !matchesMsg && !matchesAdmin) return false;
      }
      return true;
    });
  }, [notifications, statusFilter, targetFilter, searchQuery]);

  const renderStatusBadge = (status: NotificationStatus) => {
    switch (status) {
      case 'SENT':
        return (
          <Badge variant="green" size="sm" className="inline-flex items-center gap-1 font-semibold">
            <CheckCircle2 className="w-3 h-3" />
            Sent
          </Badge>
        );
      case 'SCHEDULED':
        return (
          <Badge variant="blue" size="sm" className="inline-flex items-center gap-1 font-semibold">
            <Clock className="w-3 h-3" />
            Scheduled
          </Badge>
        );
      case 'DRAFT':
        return (
          <Badge variant="gray" size="sm" className="inline-flex items-center gap-1 font-semibold">
            <FileText className="w-3 h-3" />
            Draft
          </Badge>
        );
      case 'FAILED':
        return (
          <Badge variant="red" size="sm" className="inline-flex items-center gap-1 font-semibold">
            <XCircle className="w-3 h-3" />
            Failed
          </Badge>
        );
    }
  };

  const renderTargetBadge = (target: NotificationTarget) => {
    switch (target) {
      case 'ALL':
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-zinc-100 text-zinc-800 border border-zinc-200">
            All Users
          </span>
        );
      case 'FREE':
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">
            Free Users
          </span>
        );
      case 'PRO':
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">
            Pro Users
          </span>
        );
    }
  };

  return (
    <div className="p-4 sm:p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-zinc-900 tracking-tight">
            Notifications
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 mt-0.5">
            Broadcast essential announcements, system updates, and reminders to WrindhaOS students.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            onClick={() => setFcmModalOpen(true)}
            className={`inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold border transition-all ${
              fcmStatus.isConfigured
                ? 'border-emerald-200 bg-emerald-50 text-emerald-800 hover:bg-emerald-100'
                : 'border-amber-200 bg-amber-50 text-amber-800 hover:bg-amber-100'
            }`}
          >
            <span
              className={`w-2 h-2 rounded-full ${
                fcmStatus.isConfigured ? 'bg-emerald-500' : 'bg-amber-500 animate-pulse'
              }`}
            />
            <span>{fcmStatus.isConfigured ? 'FCM Connected' : 'FCM is not configured'}</span>
          </button>

          <button
            onClick={onCreateNotification}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs"
          >
            <Plus className="w-4 h-4" />
            <span>Create Notification</span>
          </button>
        </div>
      </div>

      {/* FCM Not Configured Banner */}
      {!fcmStatus.isConfigured && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 text-amber-950 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div className="space-y-0.5">
              <p className="text-xs sm:text-sm font-bold text-amber-950">FCM is not configured.</p>
              <p className="text-xs text-amber-800">
                Push notifications require Firebase Cloud Messaging server credentials. Live delivery is currently bypassed and recorded with accurate delivery state.
              </p>
            </div>
          </div>
          <button
            onClick={() => setFcmModalOpen(true)}
            className="self-start sm:self-auto px-3 py-1.5 rounded-lg bg-amber-200/80 hover:bg-amber-300/80 text-amber-950 font-semibold text-xs transition-colors shrink-0"
          >
            Configure FCM
          </button>
        </div>
      )}

      {/* Notification Dashboard Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {/* Card 1: Total Sent */}
        <div className="bg-white p-4 sm:p-5 rounded-xl border border-zinc-200/80 shadow-xs">
          <div className="flex items-center justify-between text-zinc-400 mb-2">
            <span className="text-xs font-medium uppercase tracking-wider text-[11px] text-zinc-400">
              Notifications Sent
            </span>
            <Bell className="w-4 h-4 text-zinc-500" />
          </div>
          <div className="text-xl sm:text-2xl font-bold text-zinc-900">{stats.sentCount}</div>
          <div className="text-[11px] text-zinc-500 mt-1">Broadcasted to devices</div>
        </div>

        {/* Card 2: Successful */}
        <div className="bg-white p-4 sm:p-5 rounded-xl border border-zinc-200/80 shadow-xs">
          <div className="flex items-center justify-between text-zinc-400 mb-2">
            <span className="text-xs font-medium uppercase tracking-wider text-[11px] text-zinc-400">
              Successful
            </span>
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="text-xl sm:text-2xl font-bold text-zinc-900">
            {fcmStatus.isConfigured ? stats.successfulCount : 'Delivery data unavailable'}
          </div>
          <div className="text-[11px] text-zinc-500 mt-1">
            {fcmStatus.isConfigured ? 'Delivered via FCM' : 'FCM unconfigured'}
          </div>
        </div>

        {/* Card 3: Failed */}
        <div className="bg-white p-4 sm:p-5 rounded-xl border border-zinc-200/80 shadow-xs">
          <div className="flex items-center justify-between text-zinc-400 mb-2">
            <span className="text-xs font-medium uppercase tracking-wider text-[11px] text-zinc-400">
              Failed
            </span>
            <XCircle className="w-4 h-4 text-rose-500" />
          </div>
          <div className="text-xl sm:text-2xl font-bold text-zinc-900">{stats.failedCount}</div>
          <div className="text-[11px] text-zinc-500 mt-1">Transmission failures</div>
        </div>

        {/* Card 4: Scheduled / Drafts */}
        <div className="bg-white p-4 sm:p-5 rounded-xl border border-zinc-200/80 shadow-xs">
          <div className="flex items-center justify-between text-zinc-400 mb-2">
            <span className="text-xs font-medium uppercase tracking-wider text-[11px] text-zinc-400">
              Scheduled & Drafts
            </span>
            <Clock className="w-4 h-4 text-blue-500" />
          </div>
          <div className="text-xl sm:text-2xl font-bold text-zinc-900">
            {stats.scheduledCount + stats.draftCount}
          </div>
          <div className="text-[11px] text-zinc-500 mt-1">
            {stats.scheduledCount} scheduled, {stats.draftCount} drafts
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white rounded-xl border border-zinc-200/80 p-4 shadow-xs flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        {/* Status Tabs */}
        <div className="flex items-center gap-1 overflow-x-auto pb-1 sm:pb-0">
          {[
            { key: 'ALL', label: 'All' },
            { key: 'SENT', label: 'Sent' },
            { key: 'SCHEDULED', label: 'Scheduled' },
            { key: 'DRAFT', label: 'Drafts' },
            { key: 'FAILED', label: 'Failed' },
          ].map((tab) => {
            const isSelected = statusFilter === tab.key;
            return (
              <button
                key={tab.key}
                onClick={() => setStatusFilter(tab.key as any)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap ${
                  isSelected
                    ? 'bg-zinc-900 text-white shadow-xs'
                    : 'text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Target Filter & Search */}
        <div className="flex items-center gap-2.5">
          <select
            value={targetFilter}
            onChange={(e) => setTargetFilter(e.target.value as any)}
            aria-label="Filter notifications by target audience"
            className="px-3 py-1.5 rounded-lg border border-zinc-300 text-xs font-medium text-zinc-700 bg-white focus:outline-none focus:ring-2 focus:ring-zinc-900"
          >
            <option value="ALL">All Audiences</option>
            <option value="FREE">Free Users</option>
            <option value="PRO">Pro Users</option>
          </select>

          <div className="relative flex-1 sm:w-64">
            <Search className="w-3.5 h-3.5 text-zinc-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search notifications..."
              className="w-full pl-8 pr-3 py-1.5 rounded-lg border border-zinc-300 text-xs focus:outline-none focus:ring-2 focus:ring-zinc-900"
            />
          </div>

          <button
            onClick={loadData}
            title="Refresh list"
            aria-label="Refresh notification list"
            className="p-2 rounded-lg border border-zinc-300 text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 transition-colors"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Notifications Table */}
      <div className="bg-white rounded-xl border border-zinc-200/80 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-zinc-50 border-b border-zinc-200/80 text-zinc-500 font-semibold uppercase tracking-wider text-[10px]">
              <tr>
                <th className="px-4 py-3.5">Notification</th>
                <th className="px-4 py-3.5">Target</th>
                <th className="px-4 py-3.5">Status</th>
                <th className="px-4 py-3.5">Sent / Scheduled Date</th>
                <th className="px-4 py-3.5">Sent By</th>
                <th className="px-4 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200/80 text-zinc-700">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-zinc-400">
                    <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-zinc-400" />
                    Loading notifications...
                  </td>
                </tr>
              ) : filteredNotifications.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-zinc-400">
                    <Bell className="w-8 h-8 mx-auto mb-2 text-zinc-300" />
                    <p className="font-medium text-zinc-600">No notifications found</p>
                    <p className="text-[11px] text-zinc-400 mt-0.5">
                      Create your first broadcast notification to engage students.
                    </p>
                  </td>
                </tr>
              ) : (
                filteredNotifications.map((notif) => (
                  <tr
                    key={notif.id}
                    onClick={() => handleOpenDetail(notif)}
                    className="hover:bg-zinc-50/80 cursor-pointer transition-colors"
                  >
                    <td className="px-4 py-3.5 max-w-xs">
                      <div className="font-semibold text-zinc-900 truncate">{notif.title}</div>
                      <div className="text-[11px] text-zinc-500 truncate mt-0.5">
                        {notif.message}
                      </div>
                    </td>

                    <td className="px-4 py-3.5 whitespace-nowrap">
                      {renderTargetBadge(notif.target)}
                    </td>

                    <td className="px-4 py-3.5 whitespace-nowrap">
                      {renderStatusBadge(notif.status)}
                    </td>

                    <td className="px-4 py-3.5 whitespace-nowrap text-zinc-600">
                      {notif.sent_at ? (
                        <div>
                          <div className="font-medium text-zinc-800">
                            {new Date(notif.sent_at).toLocaleDateString()}
                          </div>
                          <div className="text-[10px] text-zinc-400">
                            {new Date(notif.sent_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </div>
                        </div>
                      ) : notif.scheduled_at ? (
                        <div>
                          <div className="font-medium text-blue-700">
                            {new Date(notif.scheduled_at).toLocaleDateString()}
                          </div>
                          <div className="text-[10px] text-blue-500">
                            {new Date(notif.scheduled_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </div>
                        </div>
                      ) : (
                        <span className="text-zinc-400">—</span>
                      )}
                    </td>

                    <td className="px-4 py-3.5 whitespace-nowrap">
                      <div className="font-medium text-zinc-900">{notif.created_by_email || 'admin@wrindhaos.com'}</div>
                      <div className="text-[10px] text-zinc-400">
                        {new Date(notif.created_at).toLocaleDateString()}
                      </div>
                    </td>

                    <td className="px-4 py-3.5 text-right whitespace-nowrap">
                      <div className="flex items-center justify-end gap-1.5" onClick={(e) => e.stopPropagation()}>
                        <button
                          onClick={() => handleOpenDetail(notif)}
                          title="View Details"
                          aria-label={`View details for ${notif.title}`}
                          className="p-1.5 rounded-md text-zinc-500 hover:text-zinc-900 hover:bg-zinc-100 transition-colors"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={(e) => handlePromptDelete(e, notif)}
                          title="Delete"
                          aria-label={`Delete notification ${notif.title}`}
                          className="p-1.5 rounded-md text-zinc-400 hover:text-rose-600 hover:bg-rose-50 transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Notification Detail Modal */}
      <Modal
        isOpen={detailModalOpen}
        onClose={() => setDetailModalOpen(false)}
        title="Notification Details"
      >
        {selectedNotif && (
          <div className="space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-zinc-200">
              <div className="flex items-center gap-2">
                {renderTargetBadge(selectedNotif.target)}
                {renderStatusBadge(selectedNotif.status)}
              </div>
              <span className="text-xs text-zinc-400 font-mono">ID: {selectedNotif.id}</span>
            </div>

            {/* Title & Message */}
            <div className="space-y-1.5">
              <h3 className="text-base font-bold text-zinc-900">{selectedNotif.title}</h3>
              <p className="text-xs text-zinc-700 bg-zinc-50 p-3 rounded-lg border border-zinc-200 leading-relaxed">
                {selectedNotif.message}
              </p>
            </div>

            {/* Delivery Stats Breakdown */}
            <div className="p-3.5 rounded-xl bg-zinc-50 border border-zinc-200 space-y-2 text-xs">
              <div className="font-bold text-zinc-900 uppercase tracking-wider text-[10px]">
                Delivery Information
              </div>

              <div className="grid grid-cols-2 gap-2 text-zinc-600">
                <div>
                  <span className="text-zinc-400">Total Targets:</span>{' '}
                  <strong className="text-zinc-900">
                    {selectedNotif.delivery_stats?.total_targets ?? '—'}
                  </strong>
                </div>
                <div>
                  <span className="text-zinc-400">Successful:</span>{' '}
                  <strong className="text-emerald-700">
                    {selectedNotif.status === 'SENT'
                      ? selectedNotif.delivery_stats?.successful ?? '—'
                      : 0}
                  </strong>
                </div>
                <div>
                  <span className="text-zinc-400">Failed:</span>{' '}
                  <strong className="text-rose-700">
                    {selectedNotif.delivery_stats?.failed ?? (selectedNotif.status === 'FAILED' ? 'All' : 0)}
                  </strong>
                </div>
                <div>
                  <span className="text-zinc-400">FCM Configured:</span>{' '}
                  <strong className="text-zinc-900">
                    {selectedNotif.delivery_stats?.fcm_configured ? 'Yes' : 'No'}
                  </strong>
                </div>
              </div>

              {selectedNotif.delivery_stats?.error_message && (
                <div className="pt-2 border-t border-zinc-200/80 text-[11px] text-amber-800">
                  <span className="font-semibold text-amber-900">Status Details:</span>{' '}
                  {selectedNotif.delivery_stats.error_message}
                </div>
              )}
            </div>

            {/* Timestamps & Admin Info */}
            <div className="text-[11px] text-zinc-500 space-y-1 pt-1">
              <div>
                Created: <span className="text-zinc-800">{new Date(selectedNotif.created_at).toLocaleString()}</span>
              </div>
              {selectedNotif.sent_at && (
                <div>
                  Sent At: <span className="text-zinc-800">{new Date(selectedNotif.sent_at).toLocaleString()}</span>
                </div>
              )}
              {selectedNotif.scheduled_at && (
                <div>
                  Scheduled For: <span className="text-blue-700">{new Date(selectedNotif.scheduled_at).toLocaleString()}</span>
                </div>
              )}
              <div>
                Created By: <span className="text-zinc-800">{selectedNotif.created_by_email || 'admin@wrindhaos.com'}</span>
              </div>
            </div>

            <div className="flex justify-end pt-3 border-t border-zinc-100">
              <button
                type="button"
                onClick={() => setDetailModalOpen(false)}
                className="px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800"
              >
                Close
              </button>
            </div>
          </div>
        )}
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        title="Delete Notification"
      >
        <div className="space-y-4">
          <p className="text-xs sm:text-sm text-zinc-600">
            Are you sure you want to delete this notification record?
          </p>
          {notifToDelete && (
            <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200 text-xs font-semibold text-zinc-900">
              {notifToDelete.title}
            </div>
          )}
          <div className="flex items-center justify-end gap-2.5 pt-2">
            <button
              type="button"
              onClick={() => setDeleteModalOpen(false)}
              className="px-4 py-2 rounded-lg border border-zinc-300 text-xs font-semibold text-zinc-700 hover:bg-zinc-50"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={executeDelete}
              disabled={deleting}
              className="px-4 py-2 rounded-lg bg-rose-600 text-white text-xs font-semibold hover:bg-rose-700 disabled:opacity-50"
            >
              {deleting ? 'Deleting...' : 'Confirm Delete'}
            </button>
          </div>
        </div>
      </Modal>

      {/* FCM Configuration Setup Modal */}
      <Modal
        isOpen={fcmModalOpen}
        onClose={() => setFcmModalOpen(false)}
        title="Firebase Cloud Messaging (FCM) Integration"
      >
        <div className="space-y-4">
          <div className="p-3.5 rounded-xl bg-zinc-50 border border-zinc-200 text-xs space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-zinc-700">Current Status:</span>
              <Badge
                variant={fcmStatus.isConfigured ? 'green' : 'amber'}
                size="sm"
                className="font-semibold"
              >
                {fcmStatus.isConfigured ? 'Active & Configured' : 'FCM is not configured'}
              </Badge>
            </div>
            <p className="text-[11px] text-zinc-500 leading-relaxed">
              {fcmStatus.details}
            </p>
          </div>

          <div className="space-y-2">
            <label className="block text-xs font-semibold text-zinc-700">
              Backend Server Integration Details
            </label>
            <p className="text-xs text-zinc-600 leading-relaxed">
              In accordance with security best practices, Firebase server credentials (e.g. Firebase Admin SDK service account key or <code className="bg-zinc-100 px-1.5 py-0.5 rounded font-mono text-[11px]">FIREBASE_SERVICE_ACCOUNT</code>) must remain server-side and never be exposed to frontend code.
            </p>
          </div>

          <div className="pt-3 border-t border-zinc-100 flex flex-wrap items-center justify-between gap-2">
            <button
              type="button"
              onClick={() => handleToggleFcmDemo(!fcmStatus.isConfigured)}
              className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors ${
                fcmStatus.isConfigured
                  ? 'border border-zinc-300 text-zinc-700 hover:bg-zinc-100'
                  : 'bg-zinc-900 text-white hover:bg-zinc-800'
              }`}
            >
              {fcmStatus.isConfigured ? 'Simulate FCM Disconnect' : 'Enable FCM Connected Mode'}
            </button>

            <button
              type="button"
              onClick={() => setFcmModalOpen(false)}
              className="px-4 py-2 rounded-lg border border-zinc-300 text-xs font-semibold text-zinc-700 hover:bg-zinc-50"
            >
              Done
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
