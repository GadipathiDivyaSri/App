import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  User,
  CreditCard,
  Calendar,
  CheckCircle2,
  Clock,
  XCircle,
  AlertCircle,
  ExternalLink,
  Shield,
  Sparkles,
  Layers,
  Check,
  RefreshCw,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { EmptyState } from '../../components/common/EmptyState';
import { subscriptionService } from '../../services/subscriptionService';
import { useAuth } from '../../contexts/AuthContext';
import { UserSubscription, TimelineEvent } from '../../types';

interface SubscriptionDetailPageProps {
  id: string;
  onNavigate: (path: string) => void;
}

export const SubscriptionDetailPage: React.FC<SubscriptionDetailPageProps> = ({
  id,
  onNavigate,
}) => {
  const { adminUser } = useAuth();
  const [subscription, setSubscription] = useState<UserSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadSubscription = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await subscriptionService.getSubscriptionById(
        id,
        adminUser?.id,
        adminUser?.email
      );
      if (data) {
        setSubscription(data);
      } else {
        setError('Subscription record not found.');
      }
    } catch (err) {
      console.error('Failed to load subscription:', err);
      setError('Could not fetch subscription details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSubscription();
  }, [id]);

  const formatDate = (dateStr?: string | null) => {
    if (!dateStr) return '—';
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString('en-GB', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return dateStr;
    }
  };

  const renderStatusBadge = (status?: UserSubscription['status']) => {
    switch (status) {
      case 'ACTIVE':
        return (
          <Badge variant="success" className="gap-1 font-semibold">
            <CheckCircle2 className="w-3.5 h-3.5" />
            <span>Active Subscription</span>
          </Badge>
        );
      case 'TRIALING':
        return (
          <Badge variant="purple" className="gap-1 font-semibold bg-purple-50 text-purple-700 border-purple-200">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Trial In Progress</span>
          </Badge>
        );
      case 'CANCELLED':
        return (
          <Badge variant="warning" className="gap-1 font-semibold">
            <Clock className="w-3.5 h-3.5" />
            <span>Cancelled (Pending Period End)</span>
          </Badge>
        );
      case 'EXPIRED':
        return (
          <Badge variant="danger" className="gap-1 font-semibold">
            <XCircle className="w-3.5 h-3.5" />
            <span>Expired (Reverted to Free)</span>
          </Badge>
        );
      case 'PAST_DUE':
        return (
          <Badge variant="danger" className="gap-1 font-semibold">
            <AlertCircle className="w-3.5 h-3.5" />
            <span>Past Due</span>
          </Badge>
        );
      default:
        return <Badge variant="neutral">{status || 'Unknown'}</Badge>;
    }
  };

  // Generate verified timeline events that actually occurred
  const getTimelineEvents = (sub: UserSubscription): TimelineEvent[] => {
    const events: TimelineEvent[] = [];

    // 1. Account Created
    if (sub.user?.created_at) {
      events.push({
        id: 'ev-1',
        title: 'WrindhaOS Account Registered',
        description: `User account created via ${sub.user.login_method || 'Email/OAuth'}.`,
        timestamp: sub.user.created_at,
        type: 'created',
      });
    }

    // 2. Free Plan Initialized
    if (sub.started_at) {
      events.push({
        id: 'ev-2',
        title: 'Initial Subscription Assigned',
        description: `Subscribed to ${sub.plan?.name || 'Free Tier'}.`,
        timestamp: sub.started_at,
        type: 'plan_change',
      });
    }

    // 3. Trial Started (if any)
    if (sub.trial_started_at) {
      events.push({
        id: 'ev-3',
        title: 'Pro Trial Commenced',
        description: `Trial started. Valid until ${formatDate(sub.trial_ends_at)}.`,
        timestamp: sub.trial_started_at,
        type: 'trial_start',
      });
    }

    // 4. Pro Activation (if Pro and start date recorded)
    if (sub.plan?.slug === 'pro' && sub.current_period_start) {
      events.push({
        id: 'ev-4',
        title: 'Pro Subscription Period Activated',
        description: `Current billing cycle active at ₹${sub.plan.price}/month.`,
        timestamp: sub.current_period_start,
        type: 'payment',
      });
    }

    // 5. Cancellation (if cancelled)
    if (sub.cancelled_at) {
      events.push({
        id: 'ev-5',
        title: 'Subscription Cancelled by User',
        description: 'Auto-renewal disabled. Access continues until period end.',
        timestamp: sub.cancelled_at,
        type: 'cancellation',
      });
    }

    // 6. Expired / Ended (if ended)
    if (sub.ended_at || sub.status === 'EXPIRED') {
      events.push({
        id: 'ev-6',
        title: 'Subscription Expired',
        description: 'Pro period completed. Account automatically reverted to Free tier.',
        timestamp: sub.ended_at || sub.updated_at || new Date().toISOString(),
        type: 'expiration',
      });
    }

    // Sort descending by timestamp
    return events.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  };

  if (loading) {
    return (
      <div className="py-24 text-center text-zinc-400">
        <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-zinc-400" />
        <p className="text-xs font-medium">Loading subscription details...</p>
      </div>
    );
  }

  if (error || !subscription) {
    return (
      <div className="space-y-6">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onNavigate('/admin/subscriptions')}
          leftIcon={<ArrowLeft className="w-4 h-4" />}
          className="text-zinc-500"
        >
          Back to Subscriptions
        </Button>
        <EmptyState
          icon={<CreditCard className="w-8 h-8 text-zinc-400" />}
          title="Subscription Not Found"
          description={error || 'The requested subscription ID could not be located in the database.'}
          action={
            <Button variant="primary" size="sm" onClick={() => onNavigate('/admin/subscriptions')}>
              Return to Subscriptions
            </Button>
          }
        />
      </div>
    );
  }

  const timelineEvents = getTimelineEvents(subscription);
  const isPro = subscription.plan?.slug === 'pro';

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* Back Navigation */}
      <div>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onNavigate('/admin/subscriptions')}
          leftIcon={<ArrowLeft className="w-4 h-4" />}
          className="mb-3 -ml-2 text-zinc-500 hover:text-zinc-900"
        >
          Back to Subscriptions
        </Button>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {subscription.user?.avatar_url ? (
              <img
                src={subscription.user.avatar_url}
                alt={subscription.user.name || 'User'}
                className="w-12 h-12 rounded-full object-cover border border-zinc-200"
              />
            ) : (
              <div className="w-12 h-12 rounded-full bg-zinc-900 text-white font-bold text-base flex items-center justify-center">
                {(subscription.user?.name || 'U').charAt(0).toUpperCase()}
              </div>
            )}
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold tracking-tight text-zinc-900">
                  {subscription.user?.name || 'WrindhaOS User'}
                </h1>
                {isPro ? (
                  <Badge variant="primary" className="font-bold">
                    PRO (₹49)
                  </Badge>
                ) : (
                  <Badge variant="neutral" className="font-medium">
                    FREE (₹0)
                  </Badge>
                )}
                {renderStatusBadge(subscription.status)}
              </div>
              <p className="text-xs text-zinc-500 font-mono mt-0.5">
                ID: {subscription.id} • User: {subscription.user?.email || subscription.user_id}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => onNavigate(`/admin/users/${subscription.user_id}`)}
              leftIcon={<User className="w-3.5 h-3.5" />}
            >
              View User Profile
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={loadSubscription}
              leftIcon={<RefreshCw className="w-3.5 h-3.5" />}
            >
              Refresh
            </Button>
          </div>
        </div>
      </div>

      {/* Overview Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Account & Plan Summary */}
        <Card className="p-6 border border-zinc-200 md:col-span-2">
          <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider mb-4 flex items-center gap-2">
            <CreditCard className="w-4 h-4 text-zinc-500" />
            Subscription Overview
          </h3>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 text-xs">
            <div>
              <span className="text-zinc-500 block text-[11px]">Current Plan</span>
              <span className="font-semibold text-zinc-900 mt-0.5 block">
                {subscription.plan?.name || (isPro ? 'WrindhaOS Pro' : 'Free Tier')}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Billing Rate</span>
              <span className="font-mono font-bold text-zinc-900 mt-0.5 block">
                ₹{subscription.plan?.price ?? (isPro ? 49 : 0)} INR /{' '}
                {subscription.plan?.billing_period || (isPro ? 'month' : 'lifetime')}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Subscription Status</span>
              <div className="mt-1">{renderStatusBadge(subscription.status)}</div>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Subscription Started</span>
              <span className="text-zinc-800 font-medium mt-0.5 block">
                {formatDate(subscription.started_at || subscription.created_at)}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Current Period Start</span>
              <span className="text-zinc-800 font-mono mt-0.5 block">
                {formatDate(subscription.current_period_start)}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Current Period End / Renewal</span>
              <span className="text-zinc-800 font-mono mt-0.5 block">
                {formatDate(subscription.current_period_end)}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Trial Start</span>
              <span className="text-zinc-800 font-mono mt-0.5 block">
                {formatDate(subscription.trial_started_at)}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Trial End Date</span>
              <span className="text-zinc-800 font-mono mt-0.5 block">
                {formatDate(subscription.trial_ends_at)}
              </span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Cancellation Date</span>
              <span className="text-zinc-800 font-mono mt-0.5 block">
                {formatDate(subscription.cancelled_at)}
              </span>
            </div>
          </div>
        </Card>

        {/* User Identity Snapshot */}
        <Card className="p-6 border border-zinc-200 bg-zinc-50/50">
          <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider mb-4 flex items-center gap-2">
            <User className="w-4 h-4 text-zinc-500" />
            Associated Account
          </h3>

          <div className="space-y-3 text-xs">
            <div>
              <span className="text-zinc-500 block text-[11px]">User Name</span>
              <span className="font-semibold text-zinc-900">{subscription.user?.name || '—'}</span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Email Address</span>
              <span className="font-mono text-zinc-800">{subscription.user?.email || '—'}</span>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Account Status</span>
              <Badge
                variant={subscription.user?.status === 'active' ? 'success' : 'warning'}
                className="mt-0.5 text-[11px]"
              >
                {subscription.user?.status || 'active'}
              </Badge>
            </div>

            <div>
              <span className="text-zinc-500 block text-[11px]">Registered Date</span>
              <span className="text-zinc-700">{formatDate(subscription.user?.created_at)}</span>
            </div>

            <div className="pt-2">
              <Button
                variant="outline"
                size="sm"
                className="w-full text-xs"
                onClick={() => onNavigate(`/admin/users/${subscription.user_id}`)}
                rightIcon={<ExternalLink className="w-3.5 h-3.5" />}
              >
                Open Full User Record
              </Button>
            </div>
          </div>
        </Card>
      </div>

      {/* Subscription Timeline & Audit History */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Timeline Column */}
        <Card className="p-6 border border-zinc-200 lg:col-span-2">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2">
              <Calendar className="w-4 h-4 text-zinc-500" />
              <h3 className="text-sm font-bold text-zinc-900">Subscription Lifecycle Timeline</h3>
            </div>
            <span className="text-xs text-zinc-400">
              {timelineEvents.length} recorded lifecycle event{timelineEvents.length !== 1 ? 's' : ''}
            </span>
          </div>

          <div className="relative pl-6 space-y-6 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-zinc-200">
            {timelineEvents.map((event) => (
              <div key={event.id} className="relative group">
                {/* Node marker */}
                <div className="absolute -left-6 mt-1 w-5 h-5 rounded-full border-2 border-white bg-zinc-900 text-white flex items-center justify-center shadow-xs">
                  <span className="w-1.5 h-1.5 rounded-full bg-white" />
                </div>

                <div className="bg-zinc-50 border border-zinc-200/80 rounded-xl p-3.5 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-zinc-900">{event.title}</span>
                    <span className="text-[11px] text-zinc-400 font-mono">
                      {formatDate(event.timestamp)}
                    </span>
                  </div>
                  <p className="text-xs text-zinc-600 leading-relaxed">{event.description}</p>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Plan Entitlements Summary */}
        <Card className="p-6 border border-zinc-200">
          <div className="flex items-center gap-2 mb-4">
            <Layers className="w-4 h-4 text-zinc-500" />
            <h3 className="text-xs font-bold text-zinc-900 uppercase tracking-wider">
              {subscription.plan?.name || 'Plan'} Entitlements
            </h3>
          </div>

          <div className="space-y-3 text-xs">
            <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60 space-y-2">
              <span className="text-[11px] font-bold text-zinc-500 uppercase tracking-wider block">
                Active Module Permissions
              </span>

              {subscription.plan?.features ? (
                <div className="space-y-1.5 max-h-64 overflow-y-auto pr-1">
                  {subscription.plan.features.map((f) => (
                    <div
                      key={f.feature_key}
                      className="flex items-center justify-between text-[11px] py-1 border-b border-zinc-100 last:border-0"
                    >
                      <div className="flex items-center gap-1.5">
                        <Check className="w-3 h-3 text-emerald-600 shrink-0" />
                        <span className="text-zinc-800 font-medium">{f.name}</span>
                      </div>
                      <span className="font-mono text-zinc-500">{f.limit || 'Not configured'}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-zinc-500 text-xs">Standard plan defaults applied.</p>
              )}
            </div>

            <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60 text-xs text-zinc-600 flex items-start gap-2">
              <Shield className="w-4 h-4 text-zinc-500 shrink-0 mt-0.5" />
              <p className="text-[11px] leading-relaxed">
                Supabase RLS protects all plan tables. Normal users cannot modify status or prices directly.
              </p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};
