import React, { useState, useEffect, useCallback } from 'react';
import {
  Users,
  UserPlus,
  Activity,
  Crown,
  TrendingUp,
  TrendingDown,
  Calendar,
  RefreshCw,
  Clock,
  Zap,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  BarChart2,
  PieChart,
  ShieldCheck,
  Target,
  Flame,
  CheckSquare,
  BookOpen,
  Timer,
  Info,
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { Card, CardHeader, CardContent } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { Badge } from '../../components/common/Badge';
import { LoadingState } from '../../components/common/LoadingState';
import { ErrorAlert } from '../../components/common/ErrorAlert';
import { useAuth } from '../../contexts/AuthContext';
import { analyticsService } from '../../services/analyticsService';
import { AnalyticsSummary, AnalyticsDateRange } from '../../types';

interface AnalyticsPageProps {
  onNavigate?: (path: string) => void;
}

export const AnalyticsPage: React.FC<AnalyticsPageProps> = ({ onNavigate }) => {
  const { adminUser } = useAuth();
  const [range, setRange] = useState<AnalyticsDateRange>('30d');
  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAnalytics = useCallback(async (selectedRange: AnalyticsDateRange) => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await analyticsService.getAnalyticsSummary(selectedRange);
      setSummary(data);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to load product analytics.';
      setError(msg);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAnalytics(range);
  }, [range, fetchAnalytics]);

  // Log ANALYTICS_VIEWED audit once per mount
  useEffect(() => {
    if (adminUser?.email) {
      analyticsService.logAnalyticsView(adminUser.email);
    }
  }, [adminUser?.email]);

  const handleRangeChange = (newRange: AnalyticsDateRange) => {
    setRange(newRange);
  };

  // Compute peak registration count in the dataset
  const peakDay = summary?.growthChart
    ? summary.growthChart.reduce((max, pt) => (pt.newUsers > max.newUsers ? pt : max), {
        date: '',
        label: '',
        newUsers: 0,
        cumulativeUsers: 0,
      })
    : null;

  const dailyAvg = summary && summary.growthChart.length > 0
    ? (summary.newUsers / summary.growthChart.length).toFixed(1)
    : '0';

  return (
    <div className="space-y-6 pb-12">
      {/* 1. Page Header & Date Range Filter */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 tracking-tight flex items-center gap-2">
            Analytics
          </h1>
          <p className="text-sm text-zinc-500 mt-0.5">
            Understand how WrindhaOS is growing and being used.
          </p>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-auto">
          {/* Date Range Selector */}
          <div className="inline-flex items-center bg-zinc-100 p-1 rounded-lg border border-zinc-200/80">
            <button
              id="analytics-range-7d"
              onClick={() => handleRangeChange('7d')}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-all ${
                range === '7d'
                  ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              7 Days
            </button>
            <button
              id="analytics-range-30d"
              onClick={() => handleRangeChange('30d')}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-all ${
                range === '30d'
                  ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              30 Days
            </button>
            <button
              id="analytics-range-90d"
              onClick={() => handleRangeChange('90d')}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-all ${
                range === '90d'
                  ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                  : 'text-zinc-600 hover:text-zinc-900'
              }`}
            >
              90 Days
            </button>
          </div>

          <Button
            id="analytics-refresh-btn"
            variant="secondary"
            size="sm"
            onClick={() => fetchAnalytics(range)}
            isLoading={isLoading}
            className="flex items-center gap-1.5"
            title="Refresh database metrics"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
            <span className="hidden sm:inline">Refresh</span>
          </Button>
        </div>
      </div>

      {error && (
        <ErrorAlert
          title="Error Loading Analytics"
          message={error}
          onRetry={() => fetchAnalytics(range)}
        />
      )}

      {isLoading && !summary ? (
        <div className="py-16">
          <LoadingState message="Aggregating product analytics from database..." />
        </div>
      ) : summary ? (
        <>
          {/* ====================================================
              2. CORE METRICS KPI CARDS
              ==================================================== */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* Card 1: Total Users */}
            <Card className="hover:border-zinc-300 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                    Total Users
                  </span>
                  <div className="w-8 h-8 rounded-lg bg-zinc-100 flex items-center justify-center text-zinc-700">
                    <Users className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  <div className="text-2xl font-bold text-zinc-900 font-mono tracking-tight">
                    {summary.totalUsers.toLocaleString()}
                  </div>
                  <div className="text-xs text-zinc-500 mt-1 flex items-center gap-1">
                    All-time registered accounts
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Card 2: New Users (with period comparison) */}
            <Card className="hover:border-zinc-300 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                    New Users
                  </span>
                  <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
                    <UserPlus className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  <div className="text-2xl font-bold text-zinc-900 font-mono tracking-tight">
                    +{summary.newUsers.toLocaleString()}
                  </div>
                  <div className="text-xs mt-1 flex items-center gap-1">
                    {summary.growthPct !== null ? (
                      <span
                        className={`font-semibold inline-flex items-center gap-0.5 ${
                          summary.growthIsPositive ? 'text-emerald-600' : 'text-rose-600'
                        }`}
                      >
                        {summary.growthIsPositive ? (
                          <TrendingUp className="w-3 h-3" />
                        ) : (
                          <TrendingDown className="w-3 h-3" />
                        )}
                        {summary.growthIsPositive ? '+' : ''}
                        {summary.growthPct}%
                      </span>
                    ) : null}
                    <span className="text-zinc-500">vs prev {range}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Card 3: Active Users (DAU & WAU) */}
            <Card className="hover:border-zinc-300 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                    Active Users
                  </span>
                  <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">
                    <Activity className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  {summary.hasActiveUserData && summary.dau !== null ? (
                    <>
                      <div className="text-2xl font-bold text-zinc-900 font-mono tracking-tight">
                        {summary.dau.toLocaleString()}
                        <span className="text-xs font-normal text-zinc-500 ml-1.5 font-sans">DAU</span>
                      </div>
                      <div className="text-xs text-zinc-500 mt-1">
                        <span className="font-semibold text-zinc-700 font-mono">{summary.wau ?? 0}</span> WAU (past 7 days)
                      </div>
                    </>
                  ) : (
                    <div className="space-y-1">
                      <div className="text-sm font-semibold text-zinc-700">Source Missing</div>
                      <div className="text-[11px] text-amber-700 leading-tight">
                        Active-user analytics require an activity tracking source.
                      </div>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Card 4: Pro Users */}
            <Card className="hover:border-zinc-300 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                    Pro Users
                  </span>
                  <div className="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center text-amber-600">
                    <Crown className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  <div className="text-2xl font-bold text-zinc-900 font-mono tracking-tight">
                    {summary.proUsersCount.toLocaleString()}
                  </div>
                  <div className="text-xs text-zinc-500 mt-1">
                    <span className="font-semibold text-zinc-700">{summary.proUsersPct}%</span> of total users
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Card 5: Pro Conversion Rate */}
            <Card className="hover:border-zinc-300 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                    Pro Conversion
                  </span>
                  <div className="w-8 h-8 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
                    <Zap className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  {summary.conversionRate !== null ? (
                    <>
                      <div className="text-2xl font-bold text-zinc-900 font-mono tracking-tight">
                        {summary.conversionRate}%
                      </div>
                      <div className="text-xs text-zinc-500 mt-1">
                        Pro Users ÷ Total Users
                      </div>
                    </>
                  ) : (
                    <div className="space-y-1">
                      <div className="text-sm font-semibold text-zinc-700">Unavailable</div>
                      <div className="text-[11px] text-zinc-500">
                        Conversion data unavailable.
                      </div>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* ====================================================
              4. USER GROWTH (LINE / AREA CHART)
              ==================================================== */}
          <Card>
            <CardHeader
              title="User Growth"
              subtitle={`New account registrations over the past ${
                range === '7d' ? '7 days' : range === '30d' ? '30 days' : '90 days'
              }`}
              action={
                <div className="flex items-center gap-3 text-xs text-zinc-500">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-zinc-900 inline-block" />
                    <span>Daily Registrations</span>
                  </div>
                </div>
              }
            />
            <CardContent className="p-6">
              {summary.growthChart.length === 0 ? (
                <div className="py-12 text-center text-zinc-500 text-sm">
                  No user registration data available in this date range.
                </div>
              ) : (
                <div className="space-y-6">
                  {/* Chart Summary Chips */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 bg-zinc-50 p-3.5 rounded-lg border border-zinc-200/70 text-xs">
                    <div>
                      <span className="text-zinc-500">New Users in Period:</span>
                      <div className="font-mono font-bold text-zinc-900 text-sm mt-0.5">
                        {summary.newUsers}
                      </div>
                    </div>
                    <div>
                      <span className="text-zinc-500">Daily Average:</span>
                      <div className="font-mono font-bold text-zinc-900 text-sm mt-0.5">
                        {dailyAvg} / day
                      </div>
                    </div>
                    <div>
                      <span className="text-zinc-500">Peak Single Day:</span>
                      <div className="font-mono font-bold text-zinc-900 text-sm mt-0.5">
                        {peakDay && peakDay.newUsers > 0
                          ? `${peakDay.newUsers} (${peakDay.label})`
                          : '0'}
                      </div>
                    </div>
                    <div>
                      <span className="text-zinc-500">Total Accounts:</span>
                      <div className="font-mono font-bold text-zinc-900 text-sm mt-0.5">
                        {summary.totalUsers}
                      </div>
                    </div>
                  </div>

                  {/* Recharts Area / Line Chart */}
                  <div className="h-64 sm:h-72 w-full pt-2">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart
                        data={summary.growthChart}
                        margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
                      >
                        <defs>
                          <linearGradient id="growthGradient" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#18181b" stopOpacity={0.15} />
                            <stop offset="95%" stopColor="#18181b" stopOpacity={0.0} />
                          </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f4f4f5" />
                        <XAxis
                          dataKey="label"
                          tick={{ fontSize: 11, fill: '#71717a' }}
                          tickLine={false}
                          axisLine={{ stroke: '#e4e4e7' }}
                          minTickGap={20}
                        />
                        <YAxis
                          allowDecimals={false}
                          tick={{ fontSize: 11, fill: '#71717a' }}
                          tickLine={false}
                          axisLine={false}
                        />
                        <Tooltip
                          content={({ active, payload, label }) => {
                            if (active && payload && payload.length) {
                              const data = payload[0].payload;
                              return (
                                <div className="bg-zinc-900 text-white text-xs rounded-lg p-2.5 shadow-lg border border-zinc-800">
                                  <div className="font-semibold text-zinc-200">{label} ({data.date})</div>
                                  <div className="mt-1 flex items-center justify-between gap-4">
                                    <span className="text-zinc-400">New Users:</span>
                                    <span className="font-bold text-emerald-400 font-mono">
                                      +{data.newUsers}
                                    </span>
                                  </div>
                                  <div className="flex items-center justify-between gap-4 text-zinc-400 text-[11px] mt-0.5">
                                    <span>Cumulative Total:</span>
                                    <span className="font-mono text-zinc-300">{data.cumulativeUsers}</span>
                                  </div>
                                </div>
                              );
                            }
                            return null;
                          }}
                        />
                        <Area
                          type="monotone"
                          dataKey="newUsers"
                          stroke="#18181b"
                          strokeWidth={2}
                          fillOpacity={1}
                          fill="url(#growthGradient)"
                          activeDot={{ r: 4, stroke: '#18181b', strokeWidth: 2, fill: '#ffffff' }}
                        />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* ====================================================
              TWO COLUMNS: PLAN DISTRIBUTION & RETENTION / ACTIVE USERS
              ==================================================== */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 7. PLAN DISTRIBUTION & CONVERSION */}
            <Card>
              <CardHeader
                title="Plan Distribution"
                subtitle="Breakdown of free vs pro subscription tier usage"
              />
              <CardContent className="p-6 space-y-5">
                {/* Visual Proportion Bar */}
                <div>
                  <div className="flex items-center justify-between text-xs text-zinc-500 mb-2">
                    <span>Distribution</span>
                    <span>{summary.totalUsers} Total Accounts</span>
                  </div>
                  <div className="h-4 w-full bg-zinc-100 rounded-full overflow-hidden flex">
                    <div
                      style={{ width: `${summary.freeUsersPct}%` }}
                      className="bg-zinc-300 transition-all"
                      title={`Free: ${summary.freeUsersCount} (${summary.freeUsersPct}%)`}
                    />
                    <div
                      style={{ width: `${summary.proUsersPct}%` }}
                      className="bg-amber-500 transition-all"
                      title={`Pro: ${summary.proUsersCount} (${summary.proUsersPct}%)`}
                    />
                  </div>
                  <div className="flex items-center justify-between text-xs mt-2 text-zinc-600">
                    <div className="flex items-center gap-1.5">
                      <span className="w-2.5 h-2.5 rounded-full bg-zinc-300 inline-block" />
                      <span>Free ({summary.freeUsersPct}%)</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <span className="w-2.5 h-2.5 rounded-full bg-amber-500 inline-block" />
                      <span>Pro ({summary.proUsersPct}%)</span>
                    </div>
                  </div>
                </div>

                {/* Plan Details Grid */}
                <div className="grid grid-cols-2 gap-3 pt-2">
                  <div className="p-3.5 bg-zinc-50 rounded-lg border border-zinc-200/70">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-zinc-600">Free Tier</span>
                      <Badge status="Free">Free</Badge>
                    </div>
                    <div className="text-xl font-bold font-mono text-zinc-900 mt-2">
                      {summary.freeUsersCount}
                    </div>
                    <div className="text-xs text-zinc-500 mt-0.5">
                      {summary.freeUsersPct}% of total users
                    </div>
                  </div>

                  <div className="p-3.5 bg-amber-50/50 rounded-lg border border-amber-200/60">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-amber-900">Pro Tier</span>
                      <Badge status="Pro">Pro</Badge>
                    </div>
                    <div className="text-xl font-bold font-mono text-amber-950 mt-2">
                      {summary.proUsersCount}
                    </div>
                    <div className="text-xs text-amber-700/80 mt-0.5">
                      {summary.proUsersPct}% of total users
                    </div>
                  </div>
                </div>

                {/* Conversion Calculation Note */}
                <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200/70 text-xs text-zinc-600 flex items-start gap-2.5">
                  <Info className="w-4 h-4 text-zinc-400 shrink-0 mt-0.5" />
                  <div>
                    <span className="font-semibold text-zinc-800">Pro Conversion Rate: </span>
                    {summary.conversionRate !== null ? (
                      <span>
                        <strong className="font-mono text-zinc-900">{summary.conversionRate}%</strong> calculated as{' '}
                        <code className="text-[11px] bg-zinc-200/60 px-1 py-0.5 rounded">
                          {summary.proUsersCount} Pro / {summary.totalEligibleUsers} Total × 100
                        </code>.
                      </span>
                    ) : (
                      <span className="text-zinc-500">Conversion data unavailable.</span>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* 6. BASIC RETENTION & ACTIVE USER HEALTH */}
            <Card>
              <CardHeader
                title="Active Users & Retention"
                subtitle="User engagement and returning activity rates"
              />
              <CardContent className="p-6 space-y-5">
                {/* 7-Day Returning User Rate */}
                <div className="p-4 bg-zinc-50 rounded-lg border border-zinc-200/70">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-semibold text-zinc-500 uppercase tracking-wider">
                        7-Day Returning User Rate
                      </div>
                      <div className="text-xs text-zinc-500 mt-0.5">
                        Users registered &gt;7 days ago active in the last 7 days
                      </div>
                    </div>
                    <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">
                      <Target className="w-4 h-4" />
                    </div>
                  </div>

                  <div className="mt-3">
                    {summary.hasRetentionData && summary.retention7dRate !== null ? (
                      <div className="flex items-baseline gap-2">
                        <div className="text-3xl font-bold font-mono text-zinc-900">
                          {summary.retention7dRate}%
                        </div>
                        <span className="text-xs font-semibold text-emerald-600">
                          active cohort return rate
                        </span>
                      </div>
                    ) : (
                      <div className="space-y-1">
                        <div className="text-sm font-semibold text-zinc-700">
                          Retention data is not available yet.
                        </div>
                        <div className="text-xs text-zinc-500">
                          Requires continuous session heartbeat telemetry from the mobile app.
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Active Tracking Health Source Breakdown */}
                <div className="space-y-2 text-xs">
                  <div className="font-semibold text-zinc-700 mb-1.5">Activity Tracking Status</div>
                  
                  <div className="flex items-center justify-between p-2.5 rounded-lg border border-zinc-100 bg-white">
                    <div className="flex items-center gap-2">
                      {summary.hasActiveUserData ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      ) : (
                        <AlertCircle className="w-4 h-4 text-amber-500" />
                      )}
                      <div>
                        <div className="font-semibold text-zinc-800">User Activity Heartbeat</div>
                        <div className="text-[11px] text-zinc-500">
                          {summary.hasActiveUserData
                            ? 'Telemetry captured via last_active_at & app_events'
                            : 'Active-user analytics require an activity tracking source'}
                        </div>
                      </div>
                    </div>
                    <Badge status={summary.hasActiveUserData ? 'active' : 'inactive'}>
                      {summary.hasActiveUserData ? 'Connected' : 'Pending'}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between p-2.5 rounded-lg border border-zinc-100 bg-white">
                    <div className="flex items-center gap-2">
                      {summary.hasFeatureTracking ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      ) : (
                        <AlertCircle className="w-4 h-4 text-amber-500" />
                      )}
                      <div>
                        <div className="font-semibold text-zinc-800">Event Logging Engine (app_events)</div>
                        <div className="text-[11px] text-zinc-500">
                          {summary.hasFeatureTracking
                            ? 'Event schema active and accepting client telemetry'
                            : 'Feature usage tracking is not configured'}
                        </div>
                      </div>
                    </div>
                    <Badge status={summary.hasFeatureTracking ? 'active' : 'inactive'}>
                      {summary.hasFeatureTracking ? 'Operational' : 'Empty'}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* ====================================================
              9. BASIC PRODUCT USAGE (MODULE ACTIVITY COUNTS)
              ==================================================== */}
          <Card>
            <CardHeader
              title="Product Usage"
              subtitle="Verified interaction counts from WrindhaOS feature modules"
            />
            <CardContent className="p-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {summary.productUsage.map((metric) => (
                  <div
                    key={metric.metricKey}
                    className="p-4 rounded-xl border border-zinc-200/80 bg-zinc-50/50 hover:bg-zinc-50 transition-colors"
                  >
                    <div className="flex items-center justify-between text-xs text-zinc-500 mb-1">
                      <span>{metric.category}</span>
                      {metric.isTracked ? (
                        <span className="w-2 h-2 rounded-full bg-emerald-500" title="Tracked in database" />
                      ) : (
                        <span className="w-2 h-2 rounded-full bg-amber-400" title="Missing event tracking" />
                      )}
                    </div>

                    <div className="font-semibold text-zinc-900 text-sm leading-snug">
                      {metric.label}
                    </div>

                    <div className="mt-3">
                      {metric.isTracked && metric.count !== null ? (
                        <div className="text-2xl font-bold font-mono text-zinc-900">
                          {metric.count.toLocaleString()}
                        </div>
                      ) : (
                        <div className="text-xs text-amber-700 font-medium bg-amber-50 border border-amber-200/60 rounded px-2 py-1">
                          Not tracked yet
                        </div>
                      )}
                    </div>

                    <div className="text-[11px] text-zinc-400 mt-2 truncate" title={metric.sourceTableOrEvent}>
                      Source: {metric.sourceTableOrEvent}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* ====================================================
              10. MOST USED FEATURES & 11. RECENT GROWTH COMPARISON
              ==================================================== */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 10. MOST USED FEATURES */}
            <Card>
              <CardHeader
                title="Most Used Features"
                subtitle="Relative frequency of feature engagement events"
              />
              <CardContent className="p-6">
                {!summary.hasFeatureTracking || summary.mostUsedFeatures.length === 0 ? (
                  <div className="py-8 text-center text-zinc-500 text-sm">
                    Feature usage analytics require event tracking.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {summary.mostUsedFeatures.map((feat, idx) => (
                      <div key={feat.featureName} className="space-y-1.5">
                        <div className="flex items-center justify-between text-xs">
                          <div className="flex items-center gap-2">
                            <span className="w-5 h-5 rounded-full bg-zinc-100 text-zinc-700 flex items-center justify-center font-mono font-bold text-[11px]">
                              {idx + 1}
                            </span>
                            <span className="font-semibold text-zinc-900">{feat.featureName}</span>
                          </div>
                          <div className="font-mono text-zinc-600">
                            <strong className="text-zinc-900">{feat.count}</strong> events ({feat.pct}%)
                          </div>
                        </div>
                        <div className="h-2 w-full bg-zinc-100 rounded-full overflow-hidden">
                          <div
                            style={{ width: `${feat.pct}%` }}
                            className="h-full bg-zinc-900 rounded-full"
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* 11. RECENT GROWTH COMPARISON & 12. REVENUE PLACEHOLDER */}
            <div className="space-y-6">
              {/* Recent Growth Period Card */}
              <Card>
                <CardHeader
                  title="Period Growth Comparison"
                  subtitle={`Comparing current ${range} vs previous equivalent ${range}`}
                />
                <CardContent className="p-6">
                  <div className="grid grid-cols-3 gap-3 text-center">
                    <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200/70">
                      <div className="text-xs text-zinc-500">Current Period</div>
                      <div className="text-xl font-bold font-mono text-zinc-900 mt-1">
                        {summary.newUsers}
                      </div>
                      <div className="text-[11px] text-zinc-400 mt-0.5">new accounts</div>
                    </div>

                    <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200/70">
                      <div className="text-xs text-zinc-500">Previous Period</div>
                      <div className="text-xl font-bold font-mono text-zinc-900 mt-1">
                        {summary.newUsersPreviousPeriod}
                      </div>
                      <div className="text-[11px] text-zinc-400 mt-0.5">new accounts</div>
                    </div>

                    <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200/70">
                      <div className="text-xs text-zinc-500">Growth Rate</div>
                      <div
                        className={`text-xl font-bold font-mono mt-1 ${
                          summary.growthIsPositive ? 'text-emerald-600' : 'text-rose-600'
                        }`}
                      >
                        {summary.growthPct !== null ? (
                          <>
                            {summary.growthIsPositive ? '+' : ''}
                            {summary.growthPct}%
                          </>
                        ) : (
                          '0%'
                        )}
                      </div>
                      <div className="text-[11px] text-zinc-400 mt-0.5">delta</div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 12. BASIC REVENUE PLACEHOLDER */}
              <Card>
                <CardHeader
                  title="Revenue Analytics"
                  subtitle="Monetization and transaction metrics"
                />
                <CardContent className="p-6">
                  <div className="p-4 rounded-xl border border-dashed border-zinc-300 bg-zinc-50/70 flex items-start gap-3 text-xs text-zinc-600">
                    <Info className="w-5 h-5 text-zinc-400 shrink-0 mt-0.5" />
                    <div>
                      <div className="font-semibold text-zinc-800 text-sm mb-1">
                        Payment Analytics Unavailable
                      </div>
                      <p className="leading-relaxed">
                        Payment analytics will become available after payment integration (Razorpay / Google Play Billing). No fabricated transactions or revenue numbers are displayed.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* ====================================================
              15. PRIVACY & TELEMETRY STANDARDS NOTE
              ==================================================== */}
          <div className="p-4 bg-zinc-100/70 border border-zinc-200/80 rounded-xl text-xs text-zinc-500 flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-zinc-400 shrink-0" />
              <span>
                <strong>Privacy by Design:</strong> Analytics queries aggregate only non-sensitive event names and timestamps. Passwords, OTP codes, authentication tokens, and private user credentials are strictly excluded.
              </span>
            </div>
            <div className="text-zinc-400 font-mono text-[11px] shrink-0 hidden sm:block">
              Schema v1.4.2
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
};
