import React, { useState, useEffect, useCallback } from 'react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { LoadingState } from '../../components/common/LoadingState';
import { EmptyState } from '../../components/common/EmptyState';
import { ErrorAlert } from '../../components/common/ErrorAlert';
import { SuspendUserModal } from '../../components/admin/SuspendUserModal';
import { RestoreUserModal } from '../../components/admin/RestoreUserModal';
import { RequestDeletionModal } from '../../components/admin/RequestDeletionModal';
import { ToastAlert, ToastMessage } from '../../components/common/ToastAlert';
import { userService } from '../../services/userService';
import { auditService } from '../../services/auditService';
import { subscriptionService } from '../../services/subscriptionService';
import { useAuth } from '../../contexts/AuthContext';
import {
  WrindhaUser,
  UserActivityLog,
  AccountDeletionRequest,
  AdminAuditLog,
  UserSubscription,
} from '../../types';
import {
  formatRelativeTime,
  formatDateLocale,
  formatDateTimeLocale,
} from '../../utils/dateUtils';
import {
  ArrowLeft,
  Mail,
  Phone,
  Calendar,
  Clock,
  ShieldCheck,
  ShieldAlert,
  Smartphone,
  CheckCircle2,
  XCircle,
  UserX,
  History,
  Activity,
  Layers,
  FileText,
  KeyRound,
  Laptop,
  CreditCard,
  Sparkles,
  ExternalLink,
} from 'lucide-react';

interface UserProfilePageProps {
  userId: string;
  initialTab?: 'overview' | 'activity' | 'account' | 'audit';
  onBack: () => void;
  onNavigate?: (path: string) => void;
}


export const UserProfilePage: React.FC<UserProfilePageProps> = ({
  userId,
  initialTab = 'overview',
  onBack,
  onNavigate,
}) => {
  const { admin } = useAuth();
  const [activeTab, setActiveTab] = useState<'overview' | 'activity' | 'account' | 'audit'>(initialTab);

  const [user, setUser] = useState<WrindhaUser | null>(null);
  const [subscription, setSubscription] = useState<UserSubscription | null>(null);
  const [activities, setActivities] = useState<UserActivityLog[]>([]);
  const [deletionRequests, setDeletionRequests] = useState<AccountDeletionRequest[]>([]);
  const [auditLogs, setAuditLogs] = useState<AdminAuditLog[]>([]);

  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modals state
  const [isSuspendModalOpen, setIsSuspendModalOpen] = useState(false);
  const [isRestoreModalOpen, setIsRestoreModalOpen] = useState(false);
  const [isDeletionModalOpen, setIsDeletionModalOpen] = useState(false);

  // Toast Notification
  const [toast, setToast] = useState<ToastMessage | null>(null);

  const loadUserData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const userData = await userService.getUserById(userId, admin?.user_id, admin?.email);
      if (!userData) {
        throw new Error(`User account with ID "${userId}" was not found.`);
      }
      setUser(userData);

      // Load parallel sub-data including subscriptions
      const [actData, delData, audData, subData] = await Promise.all([
        userService.getUserActivities(userId),
        userService.getDeletionRequestsForUser(userId),
        auditService.getAuditLogsForUser(userId),
        subscriptionService.getSubscriptionByUserId(userId),
      ]);

      setActivities(actData);
      setDeletionRequests(delData);
      setAuditLogs(audData);
      setSubscription(subData);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error loading user profile.');
    } finally {
      setIsLoading(false);
    }
  }, [userId, admin]);


  useEffect(() => {
    loadUserData();
  }, [loadUserData]);

  // Suspend
  const handleConfirmSuspend = async (targetId: string, reason: string) => {
    const res = await userService.suspendUser(
      targetId,
      reason,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) throw new Error(res.error || 'Failed to suspend.');
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'User Suspended',
      message: 'Account access has been revoked.',
    });
    loadUserData();
  };

  // Restore
  const handleConfirmRestore = async (targetId: string) => {
    const res = await userService.restoreUser(
      targetId,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) throw new Error(res.error || 'Failed to restore.');
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'User Restored',
      message: 'Account privileges have been reinstated.',
    });
    loadUserData();
  };

  // Deletion Request
  const handleConfirmDeletion = async (targetId: string, reason: string) => {
    const res = await userService.requestAccountDeletion(
      targetId,
      reason,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) throw new Error(res.error || 'Failed to request deletion.');
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'Deletion Request Registered',
      message: 'Added to account deletion review queue.',
    });
    loadUserData();
  };

  if (isLoading) {
    return (
      <div className="py-20">
        <LoadingState message="Loading verified user profile..." />
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="space-y-4">
        <Button
          variant="outline"
          size="sm"
          onClick={onBack}
          leftIcon={<ArrowLeft className="w-4 h-4" />}
        >
          Back to Users
        </Button>
        <Card className="p-8">
          <ErrorAlert
            title="User Profile Unavailable"
            message={error || 'The requested user could not be found.'}
            onRetry={loadUserData}
          />
        </Card>
      </div>
    );
  }

  const isSuspended = user.status === 'suspended';

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      <ToastAlert toast={toast} onDismiss={() => setToast(null)} />

      {/* Navigation Breadcrumb */}
      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-1.5 text-xs font-medium text-zinc-500 hover:text-zinc-900 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          <span>Back to Users</span>
        </button>

        <span className="text-[11px] font-mono text-zinc-400">
          ID: {user.id}
        </span>
      </div>

      {/* Header Profile Card */}
      <Card className="p-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-start sm:items-center gap-4">
            {user.avatar_url ? (
              <img
                src={user.avatar_url}
                alt={user.name}
                className="w-16 h-16 rounded-2xl object-cover border border-zinc-200 shadow-xs shrink-0"
              />
            ) : (
              <div className="w-16 h-16 rounded-2xl bg-zinc-900 text-white font-bold text-2xl flex items-center justify-center shadow-xs shrink-0">
                {user.name.charAt(0).toUpperCase()}
              </div>
            )}

            <div>
              <div className="flex flex-wrap items-center gap-2.5">
                <h1 className="text-xl font-bold text-zinc-900 tracking-tight">
                  {user.name}
                </h1>
                {isSuspended ? (
                  <Badge variant="danger" className="gap-1">
                    <ShieldAlert className="w-3 h-3" />
                    <span>Suspended</span>
                  </Badge>
                ) : user.status === 'inactive' ? (
                  <Badge variant="neutral">Inactive</Badge>
                ) : (
                  <Badge variant="success" className="gap-1">
                    <ShieldCheck className="w-3 h-3" />
                    <span>Active</span>
                  </Badge>
                )}

                {user.plan === 'Pro' ? (
                  <Badge variant="primary">Pro Plan</Badge>
                ) : user.plan === 'Free' ? (
                  <Badge variant="neutral">Free Plan</Badge>
                ) : (
                  <Badge variant="neutral">Plan: Not configured</Badge>
                )}
              </div>

              <div className="flex flex-wrap items-center gap-y-1 gap-x-4 text-xs text-zinc-500 mt-2">
                <span className="flex items-center gap-1.5">
                  <Mail className="w-3.5 h-3.5 text-zinc-400" />
                  <span className="font-mono text-zinc-700">{user.email}</span>
                </span>
                {user.phone && (
                  <span className="flex items-center gap-1.5">
                    <Phone className="w-3.5 h-3.5 text-zinc-400" />
                    <span>{user.phone}</span>
                  </span>
                )}
                <span className="flex items-center gap-1.5">
                  <Calendar className="w-3.5 h-3.5 text-zinc-400" />
                  <span>Joined {formatDateLocale(user.created_at)}</span>
                </span>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap items-center gap-2 pt-2 md:pt-0 border-t md:border-t-0 border-zinc-100">
            {isSuspended ? (
              <Button
                variant="primary"
                size="sm"
                onClick={() => setIsRestoreModalOpen(true)}
                leftIcon={<ShieldCheck className="w-3.5 h-3.5" />}
              >
                Restore Account
              </Button>
            ) : (
              <Button
                variant="danger"
                size="sm"
                onClick={() => setIsSuspendModalOpen(true)}
                leftIcon={<ShieldAlert className="w-3.5 h-3.5" />}
              >
                Suspend Account
              </Button>
            )}

            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsDeletionModalOpen(true)}
              leftIcon={<UserX className="w-3.5 h-3.5" />}
              className="text-amber-700 hover:text-amber-800 hover:bg-amber-50"
            >
              Request Deletion
            </Button>
          </div>
        </div>

        {/* Suspension Banner Notice */}
        {isSuspended && (
          <div className="mt-5 p-3.5 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-900 flex items-start gap-2.5">
            <ShieldAlert className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
            <div>
              <span className="font-semibold block">Account Suspended by Administration</span>
              <p className="mt-0.5 text-rose-800">
                {user.metadata?.suspension_reason || 'Access has been suspended by an administrator.'}
              </p>
              {user.metadata?.suspended_at && (
                <span className="text-[11px] text-rose-600 block mt-1">
                  Suspension Timestamp: {formatDateTimeLocale(user.metadata.suspended_at as string)}
                </span>
              )}
            </div>
          </div>
        )}
      </Card>

      {/* Tabs Navigation */}
      <div className="flex items-center gap-1 border-b border-zinc-200 text-xs font-medium">
        {[
          { id: 'overview', label: 'Overview', icon: <Layers className="w-3.5 h-3.5" /> },
          { id: 'account', label: 'Account Information', icon: <FileText className="w-3.5 h-3.5" /> },
          { id: 'activity', label: 'Activity', count: activities.length, icon: <Activity className="w-3.5 h-3.5" /> },
          { id: 'audit', label: 'Audit & Requests', count: deletionRequests.length + auditLogs.length, icon: <History className="w-3.5 h-3.5" /> },
        ].map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as typeof activeTab)}
              className={`pb-3 px-3.5 flex items-center gap-2 border-b-2 font-medium transition-colors ${
                isActive
                  ? 'border-zinc-900 text-zinc-900 font-semibold'
                  : 'border-transparent text-zinc-500 hover:text-zinc-900 hover:border-zinc-300'
              }`}
            >
              {tab.icon}
              <span>{tab.label}</span>
              {tab.count !== undefined && tab.count > 0 && (
                <span className="px-1.5 py-0.2 text-[10px] font-bold rounded-full bg-zinc-100 text-zinc-700">
                  {tab.count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Tab 1: Overview */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Identity & Educational Metadata */}
          <Card className="p-5 space-y-4">
            <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider flex items-center gap-2">
              <Layers className="w-3.5 h-3.5 text-zinc-500" />
              <span>Identity & Profile Details</span>
            </h3>

            <div className="divide-y divide-zinc-100 text-xs">
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">User ID</span>
                <span className="font-mono text-zinc-800 text-[11px]">{user.id}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Full Name</span>
                <span className="font-semibold text-zinc-900">{user.name}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Email Address</span>
                <span className="font-mono text-zinc-800">{user.email}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Phone Number</span>
                <span className="text-zinc-800">{user.phone || 'Not provided'}</span>
              </div>
              {user.metadata?.school && (
                <div className="py-2.5 flex justify-between">
                  <span className="text-zinc-500">University / Institution</span>
                  <span className="font-medium text-zinc-800">{user.metadata.school as string}</span>
                </div>
              )}
              {user.metadata?.major && (
                <div className="py-2.5 flex justify-between">
                  <span className="text-zinc-500">Field of Study</span>
                  <span className="text-zinc-800">{user.metadata.major as string}</span>
                </div>
              )}
              {user.metadata?.graduation_year && (
                <div className="py-2.5 flex justify-between">
                  <span className="text-zinc-500">Class Of</span>
                  <span className="text-zinc-800">{user.metadata.graduation_year as string}</span>
                </div>
              )}
              {user.metadata?.timezone && (
                <div className="py-2.5 flex justify-between">
                  <span className="text-zinc-500">Primary Timezone</span>
                  <span className="text-zinc-800">{user.metadata.timezone as string}</span>
                </div>
              )}
            </div>

            {user.metadata?.bio && (
              <div className="pt-2 border-t border-zinc-100">
                <span className="text-[11px] font-medium text-zinc-500 block mb-1">User Bio</span>
                <p className="text-xs text-zinc-700 bg-zinc-50 p-3 rounded-lg border border-zinc-200/80 leading-relaxed">
                  {user.metadata.bio as string}
                </p>
              </div>
            )}
          </Card>

          {/* Session & Device Environment */}
          <Card className="p-5 space-y-4">
            <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider flex items-center gap-2">
              <Laptop className="w-3.5 h-3.5 text-zinc-500" />
              <span>Environment & Session</span>
            </h3>

            <div className="divide-y divide-zinc-100 text-xs">
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Login Method</span>
                <span className="font-medium text-zinc-800">{user.login_method || 'Email & Password'}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">App Version</span>
                <span className="font-mono text-zinc-800">{user.app_version || '1.4.2'}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Client Device</span>
                <span className="text-zinc-800">{user.device_info || 'Chrome / Web Client'}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Last Active</span>
                <span className="font-medium text-zinc-900">{formatRelativeTime(user.last_active_at)}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Last Login Recorded</span>
                <span className="text-zinc-800">{formatDateTimeLocale(user.last_login_at || user.last_active_at)}</span>
              </div>
              <div className="py-2.5 flex justify-between">
                <span className="text-zinc-500">Registration Date</span>
                <span className="text-zinc-800">{formatDateTimeLocale(user.created_at)}</span>
              </div>
            </div>

            {/* Least Privilege Security Notice */}
            <div className="mt-4 p-3 bg-zinc-50 border border-zinc-200/80 rounded-xl flex items-start gap-2.5 text-[11px] text-zinc-500">
              <KeyRound className="w-3.5 h-3.5 text-zinc-400 shrink-0 mt-0.5" />
              <span>
                Under administrative least-privilege policies, secret auth tokens, hashed credentials, and OTP states are protected from administrative presentation.
              </span>
            </div>
          </Card>

          {/* Subscription & Plan Status Card */}
          <Card className="p-5 space-y-4 md:col-span-2 border border-zinc-200">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider flex items-center gap-2">
                <CreditCard className="w-3.5 h-3.5 text-zinc-500" />
                <span>Subscription & Plan Status</span>
              </h3>
              {subscription && onNavigate && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => onNavigate(`/admin/subscriptions/${subscription.id}`)}
                  rightIcon={<ExternalLink className="w-3.5 h-3.5" />}
                  className="text-xs"
                >
                  View Subscription
                </Button>
              )}
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs pt-1">
              <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
                <span className="text-zinc-500 block text-[11px]">Assigned Plan</span>
                <div className="flex items-center gap-1.5 mt-1">
                  {subscription?.plan?.slug === 'pro' ? (
                    <Badge variant="primary" className="font-bold">PRO (₹49/mo)</Badge>
                  ) : (
                    <Badge variant="neutral" className="font-medium">FREE (₹0)</Badge>
                  )}
                </div>
              </div>

              <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
                <span className="text-zinc-500 block text-[11px]">Subscription State</span>
                <span className="font-semibold text-zinc-900 mt-1 block">
                  {subscription?.status || 'ACTIVE'}
                </span>
              </div>

              <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
                <span className="text-zinc-500 block text-[11px]">Started Date</span>
                <span className="text-zinc-800 font-medium mt-1 block">
                  {subscription?.started_at ? formatDateLocale(subscription.started_at) : formatDateLocale(user.created_at)}
                </span>
              </div>

              <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
                <span className="text-zinc-500 block text-[11px]">Trial / Renewal</span>
                <span className="text-zinc-800 font-mono text-[11px] mt-1 block truncate">
                  {subscription?.status === 'TRIALING' && subscription.trial_ends_at
                    ? `Trial ends ${formatDateLocale(subscription.trial_ends_at)}`
                    : subscription?.current_period_end
                    ? `Renews ${formatDateLocale(subscription.current_period_end)}`
                    : 'Lifetime Base Tier'}
                </span>
              </div>
            </div>
          </Card>
        </div>
      )}


      {/* Tab 2: Account Information */}
      {activeTab === 'account' && (
        <Card className="p-6">
          <div className="max-w-2xl space-y-6">
            <div>
              <h3 className="text-sm font-bold text-zinc-900">Account & Verification Status</h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Core account timestamps and identity verification state.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="p-4 bg-zinc-50 border border-zinc-200 rounded-xl">
                <span className="text-[11px] font-medium text-zinc-500 block mb-1">Email Verification</span>
                <div className="flex items-center gap-2">
                  {user.email_verified ? (
                    <>
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      <span className="text-xs font-semibold text-emerald-900">Verified</span>
                    </>
                  ) : (
                    <>
                      <XCircle className="w-4 h-4 text-zinc-400" />
                      <span className="text-xs font-semibold text-zinc-600">Pending Verification</span>
                    </>
                  )}
                </div>
              </div>

              <div className="p-4 bg-zinc-50 border border-zinc-200 rounded-xl">
                <span className="text-[11px] font-medium text-zinc-500 block mb-1">Phone Verification</span>
                <div className="flex items-center gap-2">
                  {user.phone_verified ? (
                    <>
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      <span className="text-xs font-semibold text-emerald-900">Verified</span>
                    </>
                  ) : (
                    <>
                      <XCircle className="w-4 h-4 text-zinc-400" />
                      <span className="text-xs font-semibold text-zinc-600">Unverified / Not provided</span>
                    </>
                  )}
                </div>
              </div>
            </div>

            <div className="divide-y divide-zinc-100 text-xs">
              <div className="py-3 flex justify-between">
                <span className="text-zinc-500">Created At (Timestamp)</span>
                <span className="font-mono text-zinc-800">{user.created_at}</span>
              </div>
              <div className="py-3 flex justify-between">
                <span className="text-zinc-500">Updated At (Timestamp)</span>
                <span className="font-mono text-zinc-800">{user.updated_at || user.created_at}</span>
              </div>
              <div className="py-3 flex justify-between">
                <span className="text-zinc-500">Last Login</span>
                <span className="font-mono text-zinc-800">{user.last_login_at || 'Never'}</span>
              </div>
              <div className="py-3 flex justify-between">
                <span className="text-zinc-500">Last Active</span>
                <span className="font-mono text-zinc-800">{user.last_active_at || 'Never'}</span>
              </div>
              <div className="py-3 flex justify-between">
                <span className="text-zinc-500">Account Status State</span>
                <span className="font-semibold uppercase text-zinc-900">{user.status}</span>
              </div>
            </div>
          </div>
        </Card>
      )}

      {/* Tab 3: Activity */}
      {activeTab === 'activity' && (
        <Card className="p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-sm font-bold text-zinc-900">Verified Activity Events</h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Real productivity actions and session occurrences logged by the WrindhaOS application.
              </p>
            </div>
          </div>

          {activities.length === 0 ? (
            <div className="py-12">
              <EmptyState
                icon={<Activity className="w-6 h-6 text-zinc-400" />}
                title="No activity data is available yet"
                description="This user has no recorded activity events in the database."
              />
            </div>
          ) : (
            <div className="relative pl-6 border-l-2 border-zinc-200 space-y-6">
              {activities.map((act) => (
                <div key={act.id} className="relative group">
                  {/* Dot */}
                  <div className="absolute -left-[31px] top-1.5 w-3 h-3 rounded-full bg-zinc-900 border-2 border-white" />

                  <div className="p-3.5 bg-zinc-50 border border-zinc-200/90 rounded-xl space-y-1 hover:border-zinc-300 transition-colors">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-bold text-zinc-900">{act.action}</span>
                      <span className="text-[10px] text-zinc-400 whitespace-nowrap">
                        {formatDateTimeLocale(act.created_at)}
                      </span>
                    </div>

                    <p className="text-xs text-zinc-600 leading-relaxed">{act.details}</p>

                    {act.ip_address && (
                      <div className="pt-1 text-[10px] font-mono text-zinc-400">
                        IP: {act.ip_address}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {/* Tab 4: Audit & Requests */}
      {activeTab === 'audit' && (
        <div className="space-y-6">
          {/* Deletion Requests Table */}
          <Card className="p-6">
            <h3 className="text-sm font-bold text-zinc-900 mb-1">Account Deletion Requests</h3>
            <p className="text-xs text-zinc-500 mb-4">
              Pending and processed compliance erasure requests for this user account.
            </p>

            {deletionRequests.length === 0 ? (
              <div className="py-8 text-center text-xs text-zinc-400 italic">
                No account deletion requests are currently pending for this user.
              </div>
            ) : (
              <div className="divide-y divide-zinc-200 text-xs">
                {deletionRequests.map((req) => (
                  <div key={req.id} className="py-3 flex items-start justify-between gap-4">
                    <div>
                      <div className="flex items-center gap-2">
                        <Badge variant="warning">{req.status}</Badge>
                        <span className="font-semibold text-zinc-900">Request #{req.id}</span>
                      </div>
                      <p className="text-zinc-600 mt-1 text-xs">{req.reason}</p>
                      <span className="text-[10px] text-zinc-400 block mt-1">
                        Requested on {formatDateTimeLocale(req.created_at)}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>

          {/* Admin Audit Trail */}
          <Card className="p-6">
            <h3 className="text-sm font-bold text-zinc-900 mb-1">Administrative Audit Trail</h3>
            <p className="text-xs text-zinc-500 mb-4">
              Immutable log of administrative access, status changes, and actions performed on this account.
            </p>

            {auditLogs.length === 0 ? (
              <div className="py-8 text-center text-xs text-zinc-400 italic">
                No administrative audit actions recorded yet.
              </div>
            ) : (
              <div className="divide-y divide-zinc-100 text-xs">
                {auditLogs.map((log) => (
                  <div key={log.id} className="py-3 flex items-start justify-between gap-4">
                    <div>
                      <div className="flex items-center gap-2">
                        <Badge
                          variant={
                            log.action === 'USER_SUSPENDED'
                              ? 'danger'
                              : log.action === 'USER_RESTORED'
                              ? 'success'
                              : log.action === 'DELETION_REQUESTED'
                              ? 'warning'
                              : 'neutral'
                          }
                        >
                          {log.action}
                        </Badge>
                        <span className="text-zinc-600 text-xs">
                          by <span className="font-semibold text-zinc-900">{log.admin_email || log.admin_id}</span>
                        </span>
                      </div>
                      {log.metadata && Object.keys(log.metadata).length > 0 && (
                        <div className="text-[11px] text-zinc-500 mt-1 font-mono bg-zinc-50 p-2 rounded-md">
                          {JSON.stringify(log.metadata)}
                        </div>
                      )}
                    </div>
                    <span className="text-[10px] text-zinc-400 whitespace-nowrap">
                      {formatDateTimeLocale(log.timestamp)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      )}

      {/* Suspend User Modal */}
      <SuspendUserModal
        isOpen={isSuspendModalOpen}
        onClose={() => setIsSuspendModalOpen(false)}
        user={user}
        onConfirmSuspend={handleConfirmSuspend}
      />

      {/* Restore User Modal */}
      <RestoreUserModal
        isOpen={isRestoreModalOpen}
        onClose={() => setIsRestoreModalOpen(false)}
        user={user}
        onConfirmRestore={handleConfirmRestore}
      />

      {/* Request Deletion Modal */}
      <RequestDeletionModal
        isOpen={isDeletionModalOpen}
        onClose={() => setIsDeletionModalOpen(false)}
        user={user}
        onConfirmRequest={handleConfirmDeletion}
      />
    </div>
  );
};
