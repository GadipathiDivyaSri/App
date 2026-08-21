import React, { useState, useEffect } from 'react';
import {
  Bell,
  ArrowLeft,
  Calendar,
  Clock,
  Users,
  Send,
  Save,
  AlertTriangle,
  CheckCircle2,
  Smartphone,
  Info,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { notificationService } from '../../services/notificationService';
import { NotificationTarget, FCMStatus } from '../../types';
import { Modal } from '../../components/common/Modal';

interface CreateNotificationPageProps {
  onBack: () => void;
  onSuccess: () => void;
}

export const CreateNotificationPage: React.FC<CreateNotificationPageProps> = ({
  onBack,
  onSuccess,
}) => {
  const { adminUser } = useAuth();

  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState<NotificationTarget>('ALL');
  const [actionType, setActionType] = useState<'SEND_NOW' | 'SCHEDULE' | 'DRAFT'>('SEND_NOW');
  const [scheduledDate, setScheduledDate] = useState('');
  const [scheduledTime, setScheduledTime] = useState('');
  const [audienceCount, setAudienceCount] = useState<{ total: number; label: string }>({
    total: 0,
    label: '',
  });

  const [fcmStatus, setFcmStatus] = useState<FCMStatus>({
    isConfigured: false,
    statusText: '',
  });
  const [loading, setLoading] = useState(false);
  const [confirmModalOpen, setConfirmModalOpen] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(
    null
  );

  useEffect(() => {
    loadAudience(target);
    const status = notificationService.getFCMStatus();
    setFcmStatus(status);

    // Set default schedule time (tomorrow 10:00 AM)
    const tomorrow = new Date(Date.now() + 86400000);
    const yyyy = tomorrow.getFullYear();
    const mm = String(tomorrow.getMonth() + 1).padStart(2, '0');
    const dd = String(tomorrow.getDate()).padStart(2, '0');
    setScheduledDate(`${yyyy}-${mm}-${dd}`);
    setScheduledTime('10:00');
  }, [target]);

  const loadAudience = async (t: NotificationTarget) => {
    const aud = await notificationService.getAudienceCount(t);
    setAudienceCount(aud);
  };

  const handleTargetChange = (newTarget: NotificationTarget) => {
    setTarget(newTarget);
    loadAudience(newTarget);
  };

  const handleInitiateSubmit = (type: 'SEND_NOW' | 'SCHEDULE' | 'DRAFT') => {
    setActionType(type);
    setFeedback(null);

    if (!title.trim() || !message.trim()) {
      setFeedback({
        type: 'error',
        message: 'Notification title and message are required.',
      });
      return;
    }

    if (type === 'SCHEDULE') {
      if (!scheduledDate || !scheduledTime) {
        setFeedback({
          type: 'error',
          message: 'Please select a valid scheduled date and time.',
        });
        return;
      }
      const targetTime = new Date(`${scheduledDate}T${scheduledTime}:00`);
      if (isNaN(targetTime.getTime()) || targetTime.getTime() <= Date.now()) {
        setFeedback({
          type: 'error',
          message: 'Scheduled date and time must be in the future.',
        });
        return;
      }
    }

    if (type === 'SEND_NOW') {
      setConfirmModalOpen(true);
    } else {
      executeCreation(type);
    }
  };

  const executeCreation = async (type: 'SEND_NOW' | 'SCHEDULE' | 'DRAFT') => {
    setConfirmModalOpen(false);
    setLoading(true);
    setFeedback(null);

    let scheduledAtIso: string | null = null;
    if (type === 'SCHEDULE') {
      scheduledAtIso = new Date(`${scheduledDate}T${scheduledTime}:00`).toISOString();
    }

    try {
      const result = await notificationService.createNotification({
        title,
        message,
        target,
        actionType: type,
        scheduledAt: scheduledAtIso,
        adminId: adminUser?.id || 'adm-001',
        adminEmail: adminUser?.email || 'admin@wrindhaos.com',
      });

      if (!result.success && type === 'SEND_NOW') {
        setFeedback({
          type: 'error',
          message: result.message,
        });
      } else {
        setFeedback({
          type: 'success',
          message: result.message,
        });
        setTimeout(() => {
          onSuccess();
        }, 1200);
      }
    } catch (err: any) {
      setFeedback({
        type: 'error',
        message: err?.message || 'An unexpected error occurred while creating the notification.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4 sm:p-8 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <button
            onClick={onBack}
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-zinc-500 hover:text-zinc-900 transition-colors mb-2"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            Back to Notifications
          </button>
          <h1 className="text-xl sm:text-2xl font-bold text-zinc-900 tracking-tight">
            Create Notification
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 mt-0.5">
            Compose and broadcast critical announcements to WrindhaOS students.
          </p>
        </div>
      </div>

      {/* FCM Status Warning if not configured */}
      {!fcmStatus.isConfigured && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 text-xs sm:text-sm flex items-start gap-3 shadow-xs">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div className="space-y-1">
            <p className="font-semibold text-amber-950">Firebase Cloud Messaging (FCM) is not configured</p>
            <p className="text-amber-800 leading-relaxed text-xs">
              Sending notifications immediately will register the notification with status <span className="font-mono font-bold">FAILED</span> and delivery data unavailable. Firebase server credentials must be configured in your backend environment to transmit live push messages to client devices.
            </p>
          </div>
        </div>
      )}

      {feedback && (
        <div
          className={`p-4 rounded-xl border text-xs sm:text-sm flex items-start gap-3 shadow-xs ${
            feedback.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
              : 'bg-rose-50 border-rose-200 text-rose-900'
          }`}
        >
          {feedback.type === 'success' ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          ) : (
            <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />
          )}
          <p className="font-medium leading-relaxed">{feedback.message}</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Editor (2 cols) */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl border border-zinc-200/80 p-5 sm:p-6 shadow-xs space-y-5">
            <h2 className="text-sm font-bold text-zinc-900 uppercase tracking-wider text-[11px] text-zinc-400">
              Notification Details
            </h2>

            {/* Title */}
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Notification Title <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g., New Term Curriculum Available"
                maxLength={100}
                className="w-full px-3.5 py-2.5 rounded-lg border border-zinc-300 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:border-zinc-900 transition-all"
              />
              <div className="flex justify-between items-center mt-1 text-[11px] text-zinc-400">
                <span>Keep titles concise and action-oriented</span>
                <span>{title.length}/100</span>
              </div>
            </div>

            {/* Message Body */}
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Message Body <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                placeholder="Write the full message text sent to user devices..."
                maxLength={500}
                className="w-full px-3.5 py-2.5 rounded-lg border border-zinc-300 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:border-zinc-900 transition-all resize-none"
              />
              <div className="flex justify-between items-center mt-1 text-[11px] text-zinc-400">
                <span>Direct push notification content</span>
                <span>{message.length}/500</span>
              </div>
            </div>

            {/* Target Audience Selector */}
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-2">
                Target Audience <span className="text-rose-500">*</span>
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {[
                  { key: 'ALL', title: 'All Users', desc: 'Broadcast to everyone' },
                  { key: 'FREE', title: 'Free Users', desc: 'Students on Free plan' },
                  { key: 'PRO', title: 'Pro Users', desc: 'Active Pro subscribers' },
                ].map((item) => {
                  const isSelected = target === item.key;
                  return (
                    <button
                      key={item.key}
                      type="button"
                      onClick={() => handleTargetChange(item.key as NotificationTarget)}
                      className={`p-3.5 rounded-xl border text-left transition-all ${
                        isSelected
                          ? 'border-zinc-900 bg-zinc-900 text-white shadow-xs'
                          : 'border-zinc-200 bg-zinc-50/60 hover:bg-zinc-100/60 text-zinc-700'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-xs font-bold">{item.title}</span>
                        <Users className={`w-3.5 h-3.5 ${isSelected ? 'text-zinc-300' : 'text-zinc-400'}`} />
                      </div>
                      <p className={`text-[11px] ${isSelected ? 'text-zinc-300' : 'text-zinc-500'}`}>
                        {item.desc}
                      </p>
                    </button>
                  );
                })}
              </div>
              <div className="mt-2.5 flex items-center gap-2 text-xs text-zinc-500 bg-zinc-50 p-2.5 rounded-lg border border-zinc-100">
                <Info className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                <span>
                  Current audience estimate: <strong className="text-zinc-900">{audienceCount.total} users</strong> ({audienceCount.label})
                </span>
              </div>
            </div>

            {/* Schedule Section */}
            <div className="pt-4 border-t border-zinc-100">
              <label className="block text-xs font-semibold text-zinc-700 mb-2">
                Schedule Delivery (Optional)
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <div className="relative">
                    <Calendar className="w-4 h-4 text-zinc-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="date"
                      value={scheduledDate}
                      onChange={(e) => setScheduledDate(e.target.value)}
                      className="w-full pl-9 pr-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
                    />
                  </div>
                </div>
                <div>
                  <div className="relative">
                    <Clock className="w-4 h-4 text-zinc-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="time"
                      value={scheduledTime}
                      onChange={(e) => setScheduledTime(e.target.value)}
                      className="w-full pl-9 pr-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
                    />
                  </div>
                </div>
              </div>
              <p className="text-[11px] text-zinc-400 mt-1.5">
                Local system time. Scheduled notifications will be processed by the backend cron worker.
              </p>
            </div>

            {/* Action Buttons */}
            <div className="pt-4 border-t border-zinc-100 flex flex-wrap items-center justify-between gap-3">
              <button
                type="button"
                onClick={() => handleInitiateSubmit('DRAFT')}
                disabled={loading}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-zinc-300 text-xs font-semibold text-zinc-700 hover:bg-zinc-100 transition-colors disabled:opacity-50"
              >
                <Save className="w-3.5 h-3.5" />
                Save as Draft
              </button>

              <div className="flex items-center gap-2.5">
                <button
                  type="button"
                  onClick={() => handleInitiateSubmit('SCHEDULE')}
                  disabled={loading}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-zinc-800 bg-zinc-800 text-white text-xs font-semibold hover:bg-zinc-700 transition-colors disabled:opacity-50"
                >
                  <Calendar className="w-3.5 h-3.5" />
                  Schedule Delivery
                </button>

                <button
                  type="button"
                  onClick={() => handleInitiateSubmit('SEND_NOW')}
                  disabled={loading}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs disabled:opacity-50"
                >
                  <Send className="w-3.5 h-3.5" />
                  Send Now
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Live Device Preview (1 col) */}
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-zinc-200/80 p-5 shadow-xs">
            <div className="flex items-center gap-2 mb-4 pb-3 border-b border-zinc-100 text-zinc-900 font-bold text-xs">
              <Smartphone className="w-4 h-4 text-zinc-500" />
              <span>Mobile Notification Preview</span>
            </div>

            {/* Mock Phone Frame Notification */}
            <div className="p-4 rounded-xl bg-zinc-900 text-white shadow-md border border-zinc-800 space-y-2">
              <div className="flex items-center justify-between text-[11px] text-zinc-400">
                <div className="flex items-center gap-1.5">
                  <div className="w-4 h-4 rounded bg-white text-zinc-900 flex items-center justify-center font-bold text-[9px]">
                    W
                  </div>
                  <span className="font-semibold text-zinc-300">WrindhaOS</span>
                </div>
                <span>now</span>
              </div>

              <div className="space-y-1">
                <p className="text-xs font-bold text-white line-clamp-1">
                  {title || 'Notification Title Preview'}
                </p>
                <p className="text-[11px] text-zinc-300 leading-relaxed line-clamp-3">
                  {message || 'Notification body text will appear here on students’ device lock screens and notification centers.'}
                </p>
              </div>
            </div>

            <div className="mt-4 pt-3 border-t border-zinc-100 text-[11px] text-zinc-500 space-y-1.5">
              <div className="flex justify-between">
                <span>Target:</span>
                <span className="font-semibold text-zinc-900">{target} Users</span>
              </div>
              <div className="flex justify-between">
                <span>Recipients:</span>
                <span className="font-semibold text-zinc-900">{audienceCount.total}</span>
              </div>
              <div className="flex justify-between">
                <span>FCM Status:</span>
                <span className={`font-semibold ${fcmStatus.isConfigured ? 'text-emerald-600' : 'text-amber-600'}`}>
                  {fcmStatus.isConfigured ? 'Active' : 'Not Configured'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Confirmation Modal */}
      <Modal
        isOpen={confirmModalOpen}
        onClose={() => setConfirmModalOpen(false)}
        title="Confirm Notification Broadcast"
      >
        <div className="space-y-4">
          <p className="text-sm text-zinc-600">
            Are you sure you want to send this notification now to{' '}
            <strong className="text-zinc-900 font-semibold">{audienceCount.total} recipients</strong> (
            {audienceCount.label})?
          </p>

          <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200 text-xs space-y-1.5">
            <div>
              <span className="text-zinc-500">Title:</span>{' '}
              <strong className="text-zinc-900">{title}</strong>
            </div>
            <div>
              <span className="text-zinc-500">Message:</span>{' '}
              <span className="text-zinc-700">{message}</span>
            </div>
          </div>

          {!fcmStatus.isConfigured && (
            <div className="p-3 rounded-lg bg-amber-50 border border-amber-200 text-xs text-amber-900 flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
              <span>
                <strong>Notice:</strong> FCM is currently not configured. This notification will be saved with status <strong>FAILED</strong> in accordance with strict production requirements.
              </span>
            </div>
          )}

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={() => setConfirmModalOpen(false)}
              className="px-4 py-2 rounded-lg border border-zinc-300 text-xs font-semibold text-zinc-700 hover:bg-zinc-50"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={() => executeCreation('SEND_NOW')}
              className="px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 shadow-xs"
            >
              Confirm & Dispatch
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
