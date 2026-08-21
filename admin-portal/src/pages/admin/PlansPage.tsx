import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  CheckCircle2,
  Sliders,
  Sparkles,
  Shield,
  Layers,
  Info,
  RefreshCw,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { subscriptionService } from '../../services/subscriptionService';
import { SubscriptionPlan } from '../../types';

interface PlansPageProps {
  onNavigate: (path: string) => void;
}

export const PlansPage: React.FC<PlansPageProps> = ({ onNavigate }) => {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);

  const loadPlans = async () => {
    setLoading(true);
    try {
      const data = await subscriptionService.getPlans();
      setPlans(data);
    } catch (err) {
      console.error('Failed to load plans:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPlans();
  }, []);

  const freePlan = plans.find((p) => p.slug === 'free');
  const proPlan = plans.find((p) => p.slug === 'pro');

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* Back Navigation & Header */}
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
          <div>
            <div className="flex items-center gap-2.5">
              <h1 className="text-2xl font-bold tracking-tight text-zinc-900">Subscription Plans</h1>
              <Badge variant="primary" className="text-[10px] tracking-wide">
                2-TIER MODEL
              </Badge>
            </div>
            <p className="text-sm text-zinc-500 mt-1">
              Configure WrindhaOS plan specifications, limits, and feature entitlements.
            </p>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={loadPlans}
            leftIcon={<RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {/* Architectural Policy Banner */}
      <div className="p-4 bg-zinc-900 text-white rounded-2xl flex items-start gap-3.5 shadow-sm">
        <Shield className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
        <div className="text-xs space-y-1">
          <p className="font-bold text-white tracking-wide">
            WrindhaOS Business Model Architecture Policy
          </p>
          <p className="text-zinc-300 leading-relaxed">
            The WrindhaOS operating system strictly operates on two subscription tiers:{' '}
            <strong className="text-white">FREE (₹0)</strong> and{' '}
            <strong className="text-emerald-400">PRO (₹49/month)</strong>. Elite, Premium, or auxiliary
            tiers are strictly prohibited in the product specification.
          </p>
        </div>
      </div>

      {/* Plans Comparison Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* FREE PLAN CARD */}
        <Card className="p-6 border border-zinc-200 bg-white flex flex-col justify-between relative overflow-hidden">
          <div className="space-y-5">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-zinc-400 uppercase tracking-wider">
                  Base Plan
                </span>
                <h2 className="text-xl font-bold text-zinc-900 mt-0.5">
                  {freePlan?.name || 'Free Tier'}
                </h2>
              </div>
              <Badge variant="neutral" className="gap-1 text-xs">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                Active Default
              </Badge>
            </div>

            <p className="text-xs text-zinc-600 leading-relaxed">
              {freePlan?.description ||
                'Essential student productivity toolkit with foundational limits on subjects, habits, tasks, and journals.'}
            </p>

            {/* Price block */}
            <div className="p-4 bg-zinc-50 rounded-xl border border-zinc-200/80 flex items-baseline justify-between">
              <div>
                <span className="text-3xl font-black text-zinc-900 font-mono">₹0</span>
                <span className="text-xs text-zinc-500 ml-1.5">forever / student</span>
              </div>
              <span className="text-[11px] font-medium text-zinc-500 bg-zinc-200/60 px-2 py-0.5 rounded">
                Price Locked
              </span>
            </div>

            {/* Feature Summary */}
            <div className="space-y-3 pt-2">
              <span className="text-xs font-bold text-zinc-900 uppercase tracking-wider block">
                Entitlement Limits Summary
              </span>
              <ul className="space-y-2 text-xs text-zinc-600">
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                  <span>Subjects limit: <strong>3 subjects</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                  <span>Active Habits: <strong>5 habits max</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                  <span>Goals limit: <strong>3 concurrent goals</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                  <span>Standard Study Planner & To-Do Lists</span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
                  <span>Focus Centre (Standard ambient presets)</span>
                </li>
              </ul>
            </div>
          </div>

          <div className="mt-8 pt-5 border-t border-zinc-100 flex items-center justify-between">
            <span className="text-[11px] text-zinc-400">Slug: <code className="font-mono text-zinc-600">free</code></span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => onNavigate('/admin/subscriptions/plans/free')}
              leftIcon={<Sliders className="w-3.5 h-3.5" />}
            >
              Configure Free Plan
            </Button>
          </div>
        </Card>

        {/* PRO PLAN CARD */}
        <Card className="p-6 border-2 border-zinc-900 bg-white flex flex-col justify-between relative overflow-hidden shadow-sm">
          <div className="space-y-5">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-emerald-600 uppercase tracking-wider flex items-center gap-1">
                  <Sparkles className="w-3.5 h-3.5" />
                  Paid Plan
                </span>
                <h2 className="text-xl font-bold text-zinc-900 mt-0.5">
                  {proPlan?.name || 'WrindhaOS Pro'}
                </h2>
              </div>
              <Badge variant="primary" className="gap-1 text-xs bg-zinc-900 text-white">
                Active Tier
              </Badge>
            </div>

            <p className="text-xs text-zinc-600 leading-relaxed">
              {proPlan?.description ||
                'Unlocks unlimited subjects, advanced analytics, priority matrices, custom soundscapes, and full export capabilities.'}
            </p>

            {/* Price block */}
            <div className="p-4 bg-zinc-900 text-white rounded-xl flex items-baseline justify-between">
              <div>
                <span className="text-3xl font-black text-white font-mono">
                  ₹{proPlan?.price ?? 49}
                </span>
                <span className="text-xs text-zinc-300 ml-1.5">/ month</span>
              </div>
              <span className="text-[11px] font-medium text-emerald-300 bg-emerald-950/80 border border-emerald-800 px-2 py-0.5 rounded">
                Trial: {proPlan?.trial_period_days ? `${proPlan.trial_period_days} Days` : 'Configurable'}
              </span>
            </div>

            {/* Feature Summary */}
            <div className="space-y-3 pt-2">
              <span className="text-xs font-bold text-zinc-900 uppercase tracking-wider block">
                Pro Entitlements Summary
              </span>
              <ul className="space-y-2 text-xs text-zinc-700">
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Subjects: <strong>Unlimited subjects & semesters</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Habits & Streaks: <strong>Unlimited habits & analytics</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Goals & Milestones: <strong>Unlimited hierarchical tracking</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Priority & Eisenhower Matrix: <strong>Enabled</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Focus Centre: <strong>Custom binaural & ambient synth</strong></span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Kanban, Journal & Finance Modules: <strong>Full Access</strong></span>
                </li>
              </ul>
            </div>
          </div>

          <div className="mt-8 pt-5 border-t border-zinc-100 flex items-center justify-between">
            <span className="text-[11px] text-zinc-400">Slug: <code className="font-mono text-zinc-600">pro</code></span>
            <Button
              variant="primary"
              size="sm"
              onClick={() => onNavigate('/admin/subscriptions/plans/pro')}
              leftIcon={<Sliders className="w-3.5 h-3.5" />}
            >
              Configure Pro Plan
            </Button>
          </div>
        </Card>
      </div>

      {/* Feature Configuration Matrix Overview */}
      <Card className="p-6 border border-zinc-200">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2.5">
            <Layers className="w-5 h-5 text-zinc-700" />
            <div>
              <h3 className="text-sm font-bold text-zinc-900">
                Operating System Feature Matrix Reference
              </h3>
              <p className="text-xs text-zinc-500">
                14 core productivity modules governed across Free and Pro tiers.
              </p>
            </div>
          </div>
        </div>

        <div className="p-4 bg-zinc-50 border border-zinc-200/70 rounded-xl flex items-start gap-3 text-xs text-zinc-600">
          <Info className="w-4 h-4 text-zinc-500 shrink-0 mt-0.5" />
          <p>
            Any limit configured as blank or undefined will safely display as{' '}
            <strong className="text-zinc-800">"Not configured"</strong> in administrative audit and user
            account summaries to maintain interface clarity.
          </p>
        </div>
      </Card>
    </div>
  );
};
