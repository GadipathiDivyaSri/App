import React, { useEffect, useState, useCallback } from 'react';
import {
  Users,
  UserCheck,
  Award,
  Crown,
  TrendingUp,
  ArrowUpRight,
  RefreshCw,
  Clock,
  Calendar,
  BarChart3,
} from 'lucide-react';
import { Card, CardHeader, CardContent } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { Badge } from '../../components/common/Badge';
import { Table, Column } from '../../components/common/Table';
import { EmptyState } from '../../components/common/EmptyState';
import { ErrorAlert } from '../../components/common/ErrorAlert';
import { userService } from '../../services/userService';
import { WrindhaUser, DashboardStats } from '../../types';

export const DashboardPage: React.FC<{
  onNavigateToUsers: () => void;
  onNavigateToUserProfile: (id: string) => void;
  onNavigateToAnalytics?: () => void;
}> = ({
  onNavigateToUsers,
  onNavigateToUserProfile,
  onNavigateToAnalytics,
}) => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentUsers, setRecentUsers] = useState<WrindhaUser[]>([]);
  const [growthRange, setGrowthRange] = useState<'7d' | '30d' | '90d'>('30d');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [statsData, recentData] = await Promise.all([
        userService.getDashboardStats(growthRange),
        userService.getRecentUsers(5),
      ]);
      setStats(statsData);
      setRecentUsers(recentData);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch dashboard metrics.';
      setError(msg);
    } finally {
      setIsLoading(false);
    }
  }, [growthRange]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Recent Users Table definition
  const recentUserColumns: Column<WrindhaUser>[] = [
    {
      header: 'Name',
      cell: (user) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-zinc-100 border border-zinc-200/80 flex items-center justify-center text-xs font-semibold text-zinc-700 overflow-hidden shrink-0">
            {user.avatar_url ? (
              <img
                src={user.avatar_url}
                alt={user.name}
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
            ) : (
              user.name.charAt(0).toUpperCase()
            )}
          </div>
          <div>
            <div className="font-semibold text-zinc-900 leading-snug">{user.name}</div>
            <div className="text-xs text-zinc-400 font-mono sm:hidden">{user.email}</div>
          </div>
        </div>
      ),
    },
    {
      header: 'Email',
      className: 'hidden sm:table-cell',
      cell: (user) => <span className="text-zinc-600 font-mono text-xs">{user.email}</span>,
    },
    {
      header: 'Plan',
      cell: (user) => <Badge status={user.plan}>{user.plan}</Badge>,
    },
    {
      header: 'Status',
      cell: (user) => <Badge status={user.status} />,
    },
    {
      header: 'Joined',
      cell: (user) => {
        const date = new Date(user.created_at);
        return (
          <span className="text-xs text-zinc-500 whitespace-nowrap">
            {date.toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
              year: 'numeric',
            })}
          </span>
        );
      },
    },
  ];

  // Helper for simple User Growth Chart rendering
  const renderGrowthChart = () => {
    if (!stats || !stats.userGrowth || stats.userGrowth.length === 0) {
      return (
        <EmptyState
          title="No Historical Growth Data"
          description="There are not enough registration records in the selected time range to plot growth."
          icon={<TrendingUp className="w-6 h-6" />}
        />
      );
    }

    const growthData = stats.userGrowth;
    const maxCount = Math.max(...growthData.map((d) => d.count), 1);
    const totalRegistrationsInRange = growthData.reduce((acc, curr) => acc + curr.count, 0);

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between text-xs text-zinc-500">
          <span>
            Total registrations in range:{' '}
            <strong className="text-zinc-900 font-semibold">{totalRegistrationsInRange}</strong>
          </span>
          <span>Peak: {maxCount} / day</span>
        </div>

        {/* Visual Bar / Spark Histogram */}
        <div className="h-44 w-full flex items-end gap-1 sm:gap-2 pt-6 pb-2 px-1 border-b border-zinc-100">
          {growthData.map((point, index) => {
            const heightPercent = point.count === 0 ? 4 : Math.max(12, (point.count / maxCount) * 100);
            return (
              <div
                key={index}
                className="flex-1 flex flex-col items-center group relative h-full justify-end"
              >
                {/* Tooltip */}
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-8 bg-zinc-900 text-white text-[10px] py-1 px-2 rounded pointer-events-none whitespace-nowrap z-10">
                  {point.label}: {point.count} {point.count === 1 ? 'user' : 'users'}
                </div>

                <div
                  style={{ height: `${heightPercent}%` }}
                  className={`w-full rounded-t-sm transition-all duration-300 ${
                    point.count > 0
                      ? 'bg-zinc-800 hover:bg-zinc-900 group-hover:bg-zinc-950'
                      : 'bg-zinc-100 hover:bg-zinc-200'
                  }`}
                />
              </div>
            );
          })}
        </div>

        {/* X-axis date labels */}
        <div className="flex items-center justify-between text-[11px] text-zinc-400 font-medium px-1">
          <span>{growthData[0]?.label}</span>
          {growthData.length > 2 && (
            <span>{growthData[Math.floor(growthData.length / 2)]?.label}</span>
          )}
          <span>{growthData[growthData.length - 1]?.label}</span>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-8">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-zinc-900">
            Command Center
          </h1>
          <p className="text-sm text-zinc-500 mt-1">
            Monitor your WrindhaOS platform.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {onNavigateToAnalytics && (
            <Button
              variant="outline"
              size="sm"
              onClick={onNavigateToAnalytics}
              leftIcon={<BarChart3 className="w-3.5 h-3.5" />}
            >
              Product Analytics
            </Button>
          )}
          <Button
            variant="outline"
            size="sm"
            onClick={loadData}
            isLoading={isLoading}
            leftIcon={<RefreshCw className="w-3.5 h-3.5" />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {error && <ErrorAlert title="Dashboard Data Error" message={error} onRetry={loadData} />}

      {/* 4 Core Statistic Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        {/* Total Users */}
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Total Users
            </span>
            <div className="w-8 h-8 rounded-lg bg-zinc-100 flex items-center justify-center text-zinc-700">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-bold text-zinc-900 tracking-tight">
              {isLoading ? (
                <div className="h-8 w-16 bg-zinc-200 animate-pulse rounded" />
              ) : (
                stats?.totalUsers.toLocaleString() ?? '0'
              )}
            </div>
            <p className="text-xs text-zinc-500 mt-1">Platform registered accounts</p>
          </div>
        </Card>

        {/* Active Users */}
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Active Users
            </span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center">
              <UserCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-bold text-zinc-900 tracking-tight">
              {isLoading ? (
                <div className="h-8 w-16 bg-zinc-200 animate-pulse rounded" />
              ) : (
                stats?.activeUsers.toLocaleString() ?? '0'
              )}
            </div>
            <p className="text-xs text-zinc-500 mt-1">Status verified as active</p>
          </div>
        </Card>

        {/* Free Users */}
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Free Users
            </span>
            <div className="w-8 h-8 rounded-lg bg-sky-50 text-sky-700 flex items-center justify-center">
              <Award className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-bold text-zinc-900 tracking-tight">
              {isLoading ? (
                <div className="h-8 w-16 bg-zinc-200 animate-pulse rounded" />
              ) : (
                stats?.freeUsers.toLocaleString() ?? '0'
              )}
            </div>
            <p className="text-xs text-zinc-500 mt-1">Standard student tier</p>
          </div>
        </Card>

        {/* Pro Users */}
        <Card className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Pro Users
            </span>
            <div className="w-8 h-8 rounded-lg bg-zinc-900 text-white flex items-center justify-center">
              <Crown className="w-4 h-4 text-emerald-400" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-bold text-zinc-900 tracking-tight">
              {isLoading ? (
                <div className="h-8 w-24 bg-zinc-200 animate-pulse rounded" />
              ) : (
                stats?.proUsers ?? 0
              )}
            </div>
            <p className="text-xs text-zinc-500 mt-1">₹49/month paid tier</p>
          </div>
        </Card>
      </div>


      {/* User Growth Chart Section */}
      <Card>
        <CardHeader
          title="User Registrations"
          subtitle="Timeline of new WrindhaOS user sign-ups"
          action={
            <div className="flex items-center gap-1 bg-zinc-100 p-1 rounded-lg border border-zinc-200/60">
              {(['7d', '30d', '90d'] as const).map((range) => (
                <button
                  key={range}
                  onClick={() => setGrowthRange(range)}
                  className={`px-2.5 py-1 text-xs font-medium rounded-md transition-all ${
                    growthRange === range
                      ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                      : 'text-zinc-500 hover:text-zinc-800'
                  }`}
                >
                  {range === '7d' ? '7 days' : range === '30d' ? '30 days' : '90 days'}
                </button>
              ))}
            </div>
          }
        />
        <CardContent>
          {isLoading ? (
            <div className="h-44 w-full flex items-center justify-center animate-pulse bg-zinc-50 rounded-lg">
              <span className="text-xs text-zinc-400">Loading growth metrics...</span>
            </div>
          ) : (
            renderGrowthChart()
          )}
        </CardContent>
      </Card>

      {/* Recent Users Table Section */}
      <Card>
        <CardHeader
          title="Recent Users"
          subtitle="Latest student and professional accounts created on WrindhaOS"
          action={
            <Button
              variant="outline"
              size="sm"
              onClick={onNavigateToUsers}
              rightIcon={<ArrowUpRight className="w-3.5 h-3.5" />}
            >
              View all users
            </Button>
          }
        />
        <div className="p-0">
          <Table
            columns={recentUserColumns}
            data={recentUsers}
            keyExtractor={(u) => u.id}
            isLoading={isLoading}
            onRowClick={(u) => onNavigateToUserProfile(u.id)}
            emptyState={
              <EmptyState
                title="No Users Registered Yet"
                description="When students and professionals sign up on WrindhaOS, they will appear here."
              />
            }
          />
        </div>
      </Card>
    </div>
  );
};
