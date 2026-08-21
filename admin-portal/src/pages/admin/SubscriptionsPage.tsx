import React, { useEffect, useState, useCallback } from 'react';
import {
  CreditCard,
  Users,
  CheckCircle2,
  Clock,
  XCircle,
  AlertCircle,
  Search,
  Filter,
  RefreshCw,
  Eye,
  Sliders,
  Sparkles,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { EmptyState } from '../../components/common/EmptyState';
import { SubscriptionFilterModal } from '../../components/admin/SubscriptionFilterModal';
import { subscriptionService } from '../../services/subscriptionService';
import {
  UserSubscription,
  SubscriptionKPIs,
  SubscriptionFilters,
  SubscriptionSortField,
  SortOrder,
} from '../../types';

interface SubscriptionsPageProps {
  onNavigate: (path: string) => void;
}

export const SubscriptionsPage: React.FC<SubscriptionsPageProps> = ({ onNavigate }) => {
  const [kpis, setKpis] = useState<SubscriptionKPIs | null>(null);
  const [subscriptions, setSubscriptions] = useState<UserSubscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [kpisLoading, setKpisLoading] = useState(true);
  const [totalRecords, setTotalRecords] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(15);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [sortField, setSortField] = useState<SubscriptionSortField>('started_at');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [isFilterModalOpen, setIsFilterModalOpen] = useState(false);

  const [filters, setFilters] = useState<SubscriptionFilters>({
    plan: 'all',
    status: 'all',
    dateRange: 'all',
  });

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1);
    }, 300);
    return () => clearTimeout(timer);
  }, [search]);

  // Fetch KPIs
  const loadKPIs = useCallback(async () => {
    setKpisLoading(true);
    try {
      const data = await subscriptionService.getSubscriptionKPIs();
      setKpis(data);
    } catch (err) {
      console.error('Failed to load subscription KPIs:', err);
    } finally {
      setKpisLoading(false);
    }
  }, []);

  // Fetch paginated subscriptions
  const loadSubscriptions = useCallback(async () => {
    setLoading(true);
    try {
      const result = await subscriptionService.getSubscriptions({
        page,
        pageSize,
        search: debouncedSearch,
        filters,
        sortField,
        sortOrder,
      });
      setSubscriptions(result.data);
      setTotalRecords(result.total);
      setTotalPages(result.totalPages);
    } catch (err) {
      console.error('Failed to load subscriptions:', err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, debouncedSearch, filters, sortField, sortOrder]);

  useEffect(() => {
    loadKPIs();
  }, [loadKPIs]);

  useEffect(() => {
    loadSubscriptions();
  }, [loadSubscriptions]);

  const handleRefresh = () => {
    loadKPIs();
    loadSubscriptions();
  };

  const handleApplyFilters = (newFilters: SubscriptionFilters) => {
    setFilters(newFilters);
    setPage(1);
  };

  const handleResetFilters = () => {
    setFilters({
      plan: 'all',
      status: 'all',
      dateRange: 'all',
    });
    setSearch('');
    setPage(1);
  };

  const activeFilterCount =
    (filters.plan !== 'all' ? 1 : 0) +
    (filters.status !== 'all' ? 1 : 0) +
    (filters.dateRange !== 'all' ? 1 : 0);

  const formatDate = (dateStr?: string | null) => {
    if (!dateStr) return '—';
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    } catch {
      return dateStr;
    }
  };

  const renderStatusBadge = (status: UserSubscription['status']) => {
    switch (status) {
      case 'ACTIVE':
        return (
          <Badge variant="success" className="gap-1 font-medium">
            <CheckCircle2 className="w-3 h-3" />
            <span>Active</span>
          </Badge>
        );
      case 'TRIALING':
        return (
          <Badge variant="purple" className="gap-1 font-medium bg-purple-50 text-purple-700 border-purple-200">
            <Sparkles className="w-3 h-3" />
            <span>Trialing</span>
          </Badge>
        );
      case 'CANCELLED':
        return (
          <Badge variant="warning" className="gap-1 font-medium">
            <Clock className="w-3 h-3" />
            <span>Cancelled</span>
          </Badge>
        );
      case 'EXPIRED':
        return (
          <Badge variant="danger" className="gap-1 font-medium">
            <XCircle className="w-3 h-3" />
            <span>Expired</span>
          </Badge>
        );
      case 'PAST_DUE':
        return (
          <Badge variant="danger" className="gap-1 font-medium">
            <AlertCircle className="w-3 h-3" />
            <span>Past Due</span>
          </Badge>
        );
      default:
        return <Badge variant="neutral">{status}</Badge>;
    }
  };

  // Safe percentage calculations for distribution
  const totalSubUsers = kpis?.totalUsers || 1;
  const freePercent = kpis ? Math.round(((kpis.freeUsers || 0) / totalSubUsers) * 100) : 0;
  const proPercent = kpis ? Math.round(((kpis.proUsers || 0) / totalSubUsers) * 100) : 0;
  const trialPercent = kpis ? Math.round(((kpis.trialUsers || 0) / totalSubUsers) * 100) : 0;

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold tracking-tight text-zinc-900">Subscriptions</h1>
            <Badge variant="primary" className="text-[10px] tracking-wide">
              ₹0 / ₹49 MODEL
            </Badge>
          </div>
          <p className="text-sm text-zinc-500 mt-1">
            Monitor WrindhaOS plans and subscription status.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            leftIcon={<RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />}
          >
            Refresh
          </Button>

          <Button
            variant="primary"
            size="sm"
            onClick={() => onNavigate('/admin/subscriptions/plans')}
            leftIcon={<Sliders className="w-3.5 h-3.5" />}
          >
            Manage Plans
          </Button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3 sm:gap-4">
        {/* Total Users */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Total Users
            </span>
            <Users className="w-4 h-4 text-zinc-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-zinc-900">
            {kpisLoading ? '—' : kpis?.totalUsers ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">All registered users</p>
        </Card>

        {/* Free Users */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Free Users
            </span>
            <span className="text-xs font-mono font-bold text-zinc-600">₹0</span>
          </div>
          <div className="mt-2 text-2xl font-bold text-zinc-800">
            {kpisLoading ? '—' : kpis?.freeUsers ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Default base tier</p>
        </Card>

        {/* Pro Users */}
        <Card className="p-4 bg-zinc-900 text-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider">
              Pro Users
            </span>
            <span className="text-xs font-mono font-bold text-emerald-400">₹49/mo</span>
          </div>
          <div className="mt-2 text-2xl font-bold text-white">
            {kpisLoading ? '—' : kpis?.proUsers ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Total Pro accounts</p>
        </Card>

        {/* Trial Users */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Trial Users
            </span>
            <Sparkles className="w-4 h-4 text-purple-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-purple-700">
            {kpisLoading ? '—' : kpis?.trialUsers ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Active evaluation</p>
        </Card>

        {/* Active Pro */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Active Pro
            </span>
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-emerald-700">
            {kpisLoading ? '—' : kpis?.activePro ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Ongoing subscription</p>
        </Card>

        {/* Cancelled */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Cancelled
            </span>
            <Clock className="w-4 h-4 text-amber-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-amber-700">
            {kpisLoading ? '—' : kpis?.cancelled ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Pending period end</p>
        </Card>

        {/* Expired */}
        <Card className="p-4 bg-white">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold text-zinc-500 uppercase tracking-wider">
              Expired
            </span>
            <XCircle className="w-4 h-4 text-rose-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-rose-700">
            {kpisLoading ? '—' : kpis?.expired ?? 0}
          </div>
          <p className="text-[10px] text-zinc-400 mt-0.5">Reverted to Free</p>
        </Card>
      </div>

      {/* Subscription Distribution Visual Breakdown */}
      <Card className="p-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4">
          <div>
            <h3 className="text-sm font-bold text-zinc-900 tracking-tight">
              Subscription Tier Distribution
            </h3>
            <p className="text-xs text-zinc-500 mt-0.5">
              Live user breakdown across Free (₹0), Pro (₹49/mo), and Active Trials.
            </p>
          </div>

          <div className="flex items-center gap-4 text-xs">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-400" />
              <span className="text-zinc-600 font-medium">Free: {kpis?.freeUsers ?? 0}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-900" />
              <span className="text-zinc-900 font-bold">Pro: {kpis?.proUsers ?? 0}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-purple-500" />
              <span className="text-purple-700 font-medium">Trial: {kpis?.trialUsers ?? 0}</span>
            </div>
          </div>
        </div>

        {/* Visual Progress Bar */}
        <div className="w-full h-3.5 bg-zinc-100 rounded-full overflow-hidden flex shadow-inner">
          <div
            style={{ width: `${freePercent}%` }}
            className="bg-zinc-400 h-full transition-all duration-500"
            title={`Free Users: ${kpis?.freeUsers ?? 0} (${freePercent}%)`}
          />
          <div
            style={{ width: `${proPercent}%` }}
            className="bg-zinc-900 h-full transition-all duration-500"
            title={`Pro Users: ${kpis?.proUsers ?? 0} (${proPercent}%)`}
          />
          <div
            style={{ width: `${trialPercent}%` }}
            className="bg-purple-500 h-full transition-all duration-500"
            title={`Trial Users: ${kpis?.trialUsers ?? 0} (${trialPercent}%)`}
          />
        </div>

        <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t border-zinc-100 text-xs">
          <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
            <span className="text-zinc-500 block text-[11px]">Free Tier Users</span>
            <span className="text-base font-bold text-zinc-800 font-mono mt-0.5 block">
              {kpis?.freeUsers ?? 0}
            </span>
            <span className="text-[10px] text-zinc-400">{freePercent}% of user base</span>
          </div>

          <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
            <span className="text-zinc-500 block text-[11px]">Pro Plan Subscribers</span>
            <span className="text-base font-bold text-zinc-900 font-mono mt-0.5 block">
              {kpis?.proUsers ?? 0}
            </span>
            <span className="text-[10px] text-zinc-400">
              {proPercent}% conversion (₹49/mo)
            </span>
          </div>

          <div className="p-3 bg-zinc-50 rounded-xl border border-zinc-200/60">
            <span className="text-zinc-500 block text-[11px]">Active Trial Accounts</span>
            <span className="text-base font-bold text-purple-700 font-mono mt-0.5 block">
              {kpis?.trialUsers ?? 0}
            </span>
            <span className="text-[10px] text-zinc-400">{trialPercent}% in evaluation</span>
          </div>
        </div>
      </Card>

      {/* Subscription Table Card */}
      <Card className="overflow-hidden border border-zinc-200">
        {/* Table Search & Controls Bar */}
        <div className="p-4 sm:p-5 border-b border-zinc-200 bg-white flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-md">
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search user name, email, user ID, subscription ID..."
              leftIcon={<Search className="w-4 h-4 text-zinc-400" />}
              className="text-xs"
            />
          </div>

          <div className="flex items-center gap-2">
            {/* Quick Plan Filter Chips */}
            <div className="hidden md:flex items-center bg-zinc-100 p-0.5 rounded-lg text-xs">
              <button
                onClick={() => handleApplyFilters({ ...filters, plan: 'all' })}
                className={`px-2.5 py-1 rounded-md font-medium transition-colors ${
                  filters.plan === 'all'
                    ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                    : 'text-zinc-500 hover:text-zinc-800'
                }`}
              >
                All
              </button>
              <button
                onClick={() => handleApplyFilters({ ...filters, plan: 'free' })}
                className={`px-2.5 py-1 rounded-md font-medium transition-colors ${
                  filters.plan === 'free'
                    ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                    : 'text-zinc-500 hover:text-zinc-800'
                }`}
              >
                Free
              </button>
              <button
                onClick={() => handleApplyFilters({ ...filters, plan: 'pro' })}
                className={`px-2.5 py-1 rounded-md font-medium transition-colors ${
                  filters.plan === 'pro'
                    ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                    : 'text-zinc-500 hover:text-zinc-800'
                }`}
              >
                Pro
              </button>
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsFilterModalOpen(true)}
              leftIcon={<Filter className="w-3.5 h-3.5 text-zinc-500" />}
            >
              <span>Filters</span>
              {activeFilterCount > 0 && (
                <span className="ml-1 px-1.5 py-0.2 bg-zinc-900 text-white rounded-full text-[10px] font-bold">
                  {activeFilterCount}
                </span>
              )}
            </Button>

            {(activeFilterCount > 0 || search) && (
              <Button variant="ghost" size="sm" onClick={handleResetFilters}>
                Clear
              </Button>
            )}
          </div>
        </div>

        {/* Subscription Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-zinc-200 bg-zinc-50/80 text-[11px] font-bold text-zinc-500 uppercase tracking-wider">
                <th className="py-3 px-4 sm:px-6">User</th>
                <th className="py-3 px-4">Plan</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Started</th>
                <th className="py-3 px-4">Current Period</th>
                <th className="py-3 px-4">Trial</th>
                <th className="py-3 px-4 sm:px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-100 bg-white">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-zinc-400">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <RefreshCw className="w-5 h-5 animate-spin text-zinc-400" />
                      <span className="text-xs font-medium">Loading subscription data...</span>
                    </div>
                  </td>
                </tr>
              ) : subscriptions.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-16 text-center">
                    <EmptyState
                      icon={<CreditCard className="w-6 h-6 text-zinc-400" />}
                      title={
                        search || activeFilterCount > 0
                          ? 'No matching subscriptions'
                          : 'No subscription records found'
                      }
                      description={
                        search || activeFilterCount > 0
                          ? 'Try adjusting your search criteria or clear active filters.'
                          : 'Newly registered users default to Free tier automatically.'
                      }
                      action={
                        search || activeFilterCount > 0 ? (
                          <Button variant="outline" size="sm" onClick={handleResetFilters}>
                            Clear Filters
                          </Button>
                        ) : undefined
                      }
                    />
                  </td>
                </tr>
              ) : (
                subscriptions.map((sub) => {
                  const isPro = sub.plan?.slug === 'pro';
                  const currentPeriodDisplay =
                    sub.current_period_start && sub.current_period_end
                      ? `${formatDate(sub.current_period_start)} – ${formatDate(sub.current_period_end)}`
                      : isPro && sub.started_at
                      ? `${formatDate(sub.started_at)} – Ongoing`
                      : '—';

                  const trialDisplay =
                    sub.status === 'TRIALING' && sub.trial_ends_at
                      ? `Active Trial (Ends ${formatDate(sub.trial_ends_at)})`
                      : sub.trial_started_at
                      ? `Trial used (${formatDate(sub.trial_started_at)})`
                      : '—';

                  return (
                    <tr
                      key={sub.id}
                      className="hover:bg-zinc-50/70 transition-colors group cursor-pointer"
                      onClick={() => onNavigate(`/admin/subscriptions/${sub.id}`)}
                    >
                      {/* User Avatar + Identity */}
                      <td className="py-3 px-4 sm:px-6">
                        <div className="flex items-center gap-3">
                          {sub.user?.avatar_url ? (
                            <img
                              src={sub.user.avatar_url}
                              alt={sub.user.name || 'User'}
                              className="w-8 h-8 rounded-full object-cover border border-zinc-200 shrink-0"
                            />
                          ) : (
                            <div className="w-8 h-8 rounded-full bg-zinc-900 text-white font-bold text-xs flex items-center justify-center shrink-0">
                              {(sub.user?.name || 'U').charAt(0).toUpperCase()}
                            </div>
                          )}
                          <div className="min-w-0">
                            <span className="font-semibold text-zinc-900 hover:underline block truncate">
                              {sub.user?.name || 'Unknown User'}
                            </span>
                            <span className="text-[11px] text-zinc-500 font-mono block truncate">
                              {sub.user?.email || sub.user_id}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Plan */}
                      <td className="py-3 px-4">
                        {isPro ? (
                          <Badge variant="primary" className="gap-1 font-semibold">
                            Pro (₹49)
                          </Badge>
                        ) : (
                          <Badge variant="neutral" className="gap-1 font-medium">
                            Free (₹0)
                          </Badge>
                        )}
                      </td>

                      {/* Status */}
                      <td className="py-3 px-4">{renderStatusBadge(sub.status)}</td>

                      {/* Started Date */}
                      <td className="py-3 px-4 text-zinc-700 whitespace-nowrap">
                        {formatDate(sub.started_at || sub.created_at)}
                      </td>

                      {/* Current Period */}
                      <td className="py-3 px-4 text-zinc-600 font-mono text-[11px] whitespace-nowrap">
                        {currentPeriodDisplay}
                      </td>

                      {/* Trial Status */}
                      <td className="py-3 px-4 text-zinc-600 text-xs whitespace-nowrap">
                        {sub.status === 'TRIALING' ? (
                          <span className="text-purple-700 font-semibold">{trialDisplay}</span>
                        ) : (
                          <span className="text-zinc-400">{trialDisplay}</span>
                        )}
                      </td>

                      {/* Action */}
                      <td className="py-3 px-4 sm:px-6 text-right" onClick={(e) => e.stopPropagation()}>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onNavigate(`/admin/subscriptions/${sub.id}`)}
                          leftIcon={<Eye className="w-3.5 h-3.5" />}
                          className="text-xs"
                        >
                          View
                        </Button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {subscriptions.length > 0 && (
          <div className="p-4 border-t border-zinc-200 bg-white flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-zinc-500">
            <div>
              Showing <span className="font-semibold text-zinc-900">{subscriptions.length}</span> of{' '}
              <span className="font-semibold text-zinc-900">{totalRecords}</span> subscriptions
            </div>

            <div className="flex items-center gap-1.5">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
              >
                Previous
              </Button>
              <span className="px-3 py-1 text-xs font-semibold text-zinc-700">
                Page {page} of {totalPages}
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Subscription Filter Modal */}
      <SubscriptionFilterModal
        isOpen={isFilterModalOpen}
        onClose={() => setIsFilterModalOpen(false)}
        filters={filters}
        onApply={handleApplyFilters}
        onReset={handleResetFilters}
      />
    </div>
  );
};
