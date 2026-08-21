import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  Save,
  CheckCircle2,
  AlertTriangle,
  Lock,
  Layers,
  Sparkles,
  RotateCcw,
  Check,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { ChangePriceModal } from '../../components/admin/ChangePriceModal';
import { subscriptionService } from '../../services/subscriptionService';
import { useAuth } from '../../contexts/AuthContext';
import { SubscriptionPlan, PlanFeatureConfig, PlanSlug } from '../../types';
import { DEFAULT_FEATURES } from '../../lib/defaultPlanData';

interface PlanEditorPageProps {
  slug: string;
  onNavigate: (path: string) => void;
}

export const PlanEditorPage: React.FC<PlanEditorPageProps> = ({ slug, onNavigate }) => {
  const { adminUser } = useAuth();
  const planSlug = slug as PlanSlug;
  const isFree = planSlug === 'free';
  const isPro = planSlug === 'pro';

  const [plan, setPlan] = useState<SubscriptionPlan | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Form State
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState<number>(0);
  const [trialDays, setTrialDays] = useState<string>('');
  const [isActive, setIsActive] = useState(true);
  const [features, setFeatures] = useState<PlanFeatureConfig[]>([]);

  // Price Modal State
  const [isPriceModalOpen, setIsPriceModalOpen] = useState(false);
  const [pendingPrice, setPendingPrice] = useState<number>(0);

  useEffect(() => {
    if (!isFree && !isPro) {
      onNavigate('/admin/subscriptions/plans');
      return;
    }

    const loadPlanData = async () => {
      setLoading(true);
      try {
        const data = await subscriptionService.getPlanBySlug(planSlug);
        if (data) {
          setPlan(data);
          setName(data.name);
          setDescription(data.description || '');
          setPrice(data.price);
          setTrialDays(data.trial_period_days ? String(data.trial_period_days) : '');
          setIsActive(data.is_active);

          // Merge loaded features with default 14 features to guarantee complete coverage
          const existingFeatures = data.features || [];
          const mergedFeatures: PlanFeatureConfig[] = DEFAULT_FEATURES.map((def) => {
            const found = existingFeatures.find((f) => f.feature_key === def.key);
            if (found) return found;
            return {
              feature_key: def.key,
              name: def.name,
              enabled: isPro ? true : def.defaultEnabledFree,
              limit: isPro ? def.defaultLimitPro : def.defaultLimitFree,
              description: def.description,
            };
          });
          setFeatures(mergedFeatures);
        }
      } catch (err) {
        console.error('Failed to load plan for editing:', err);
        setErrorMessage('Could not load plan details.');
      } finally {
        setLoading(false);
      }
    };

    loadPlanData();
  }, [planSlug, isFree, isPro, onNavigate]);

  const handleFeatureToggle = (key: string) => {
    setFeatures((prev) =>
      prev.map((f) => (f.feature_key === key ? { ...f, enabled: !f.enabled } : f))
    );
  };

  const handleFeatureLimitChange = (key: string, limitVal: string) => {
    setFeatures((prev) =>
      prev.map((f) => (f.feature_key === key ? { ...f, limit: limitVal } : f))
    );
  };

  const handlePriceInputChange = (val: string) => {
    const parsed = parseInt(val, 10);
    setPrice(isNaN(parsed) ? 0 : Math.max(0, parsed));
  };

  const handleSaveClick = () => {
    setSuccessMessage(null);
    setErrorMessage(null);

    // If Pro and price was changed from original, open confirmation modal first
    if (isPro && plan && price !== plan.price) {
      setPendingPrice(price);
      setIsPriceModalOpen(true);
      return;
    }

    executeSavePlan();
  };

  const executeSavePlan = async (confirmedNewPrice?: number) => {
    if (!plan) return;
    setSaving(true);
    setSuccessMessage(null);
    setErrorMessage(null);

    const finalPrice = isFree ? 0 : confirmedNewPrice !== undefined ? confirmedNewPrice : price;
    const finalTrialDays = isPro && trialDays ? parseInt(trialDays, 10) || null : null;

    try {
      const updates: Partial<SubscriptionPlan> = {
        name,
        description,
        price: finalPrice,
        trial_period_days: finalTrialDays,
        is_active: isActive,
        features,
      };

      const result = await subscriptionService.updatePlan(
        plan.id,
        updates,
        adminUser?.id,
        adminUser?.email
      );

      if (result.success && result.plan) {
        setPlan(result.plan);
        setPrice(result.plan.price);
        setIsPriceModalOpen(false);
        setSuccessMessage(`Successfully updated ${result.plan.name} configuration.`);
      } else {
        setErrorMessage(result.error || 'Failed to update plan.');
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'An error occurred while saving plan.';
      setErrorMessage(msg);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="py-20 text-center text-zinc-400">
        <p className="text-xs font-medium">Loading plan configuration...</p>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* Back Navigation */}
      <div>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onNavigate('/admin/subscriptions/plans')}
          leftIcon={<ArrowLeft className="w-4 h-4" />}
          className="mb-3 -ml-2 text-zinc-500 hover:text-zinc-900"
        >
          Back to Plans
        </Button>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2.5">
              <h1 className="text-2xl font-bold tracking-tight text-zinc-900">
                Configure {isFree ? 'Free (₹0)' : 'Pro (₹49)'} Plan
              </h1>
              {isFree ? (
                <Badge variant="neutral" className="gap-1">
                  <Lock className="w-3 h-3 text-zinc-400" />
                  Locked Base Tier
                </Badge>
              ) : (
                <Badge variant="primary" className="gap-1 bg-zinc-900 text-white">
                  <Sparkles className="w-3 h-3 text-emerald-400" />
                  Primary Paid Tier
                </Badge>
              )}
            </div>
            <p className="text-sm text-zinc-500 mt-1">
              Adjust feature matrix, access limits, and administrative specifications.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <Button
              variant="outline"
              size="sm"
              onClick={() => onNavigate('/admin/subscriptions/plans')}
              disabled={saving}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              size="sm"
              onClick={handleSaveClick}
              loading={saving}
              leftIcon={<Save className="w-3.5 h-3.5" />}
            >
              Save Changes
            </Button>
          </div>
        </div>
      </div>

      {/* Notifications */}
      {successMessage && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-3 text-emerald-900 text-xs">
          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          <span className="font-medium">{successMessage}</span>
        </div>
      )}

      {errorMessage && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-3 text-rose-900 text-xs">
          <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
          <span className="font-medium">{errorMessage}</span>
        </div>
      )}

      {/* Basic Settings Card */}
      <Card className="p-6 border border-zinc-200">
        <h3 className="text-sm font-bold text-zinc-900 uppercase tracking-wider mb-5">
          General Plan Specifications
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          {/* Plan Name */}
          <div>
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
              Plan Display Name
            </label>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Free Tier, WrindhaOS Pro"
              className="text-xs font-medium"
            />
          </div>

          {/* Plan Slug */}
          <div>
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
              System Slug (Immutable Identifier)
            </label>
            <Input
              value={planSlug}
              disabled
              className="text-xs bg-zinc-100 font-mono text-zinc-500 cursor-not-allowed"
            />
          </div>

          {/* Description */}
          <div className="sm:col-span-2">
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
              Plan Description
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 bg-white border border-zinc-300 rounded-lg text-xs text-zinc-800 focus:outline-none focus:ring-1 focus:ring-zinc-900 transition-colors"
              placeholder="Brief description of who this plan is intended for..."
            />
          </div>

          {/* Pricing Box */}
          <div>
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5 flex items-center justify-between">
              <span>Price (INR)</span>
              {isFree && (
                <span className="text-[10px] text-zinc-400 font-normal">
                  Permanently locked at ₹0
                </span>
              )}
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-xs font-bold text-zinc-400">₹</span>
              <Input
                type="number"
                min="0"
                value={isFree ? 0 : price}
                disabled={isFree}
                onChange={(e) => handlePriceInputChange(e.target.value)}
                className={`pl-7 text-xs font-mono font-bold ${
                  isFree ? 'bg-zinc-100 text-zinc-500 cursor-not-allowed' : 'text-zinc-900'
                }`}
              />
            </div>
            {isFree ? (
              <p className="text-[11px] text-zinc-400 mt-1">
                The Free plan cannot be converted to a paid tier under any circumstance.
              </p>
            ) : (
              <p className="text-[11px] text-zinc-500 mt-1">
                Changing price will prompt for confirmation and log an audit record.
              </p>
            )}
          </div>

          {/* Billing Cycle */}
          <div>
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
              Billing Interval
            </label>
            <Input
              value={isFree ? 'None (Lifetime Free)' : 'Monthly (₹49/month)'}
              disabled
              className="text-xs bg-zinc-100 font-medium text-zinc-600 cursor-not-allowed"
            />
          </div>

          {/* Trial Duration (Pro Only) */}
          {isPro && (
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Trial Duration (Days)
              </label>
              <Input
                type="number"
                min="0"
                value={trialDays}
                onChange={(e) => setTrialDays(e.target.value)}
                placeholder="e.g. 7"
                className="text-xs font-mono"
              />
              <p className="text-[11px] text-zinc-500 mt-1">
                Leave empty or 0 if trial is not active for new signups.
              </p>
            </div>
          )}

          {/* Active Status Toggle */}
          <div>
            <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
              Tier Status
            </label>
            <div className="flex items-center gap-3 h-9">
              <button
                type="button"
                onClick={() => setIsActive(!isActive)}
                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  isActive ? 'bg-zinc-900' : 'bg-zinc-300'
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    isActive ? 'translate-x-4' : 'translate-x-0'
                  }`}
                />
              </button>
              <span className="text-xs font-medium text-zinc-800">
                {isActive ? 'Active Plan' : 'Inactive Plan'}
              </span>
            </div>
          </div>
        </div>
      </Card>

      {/* Feature Matrix & Entitlements Editor */}
      <Card className="p-6 border border-zinc-200">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-6">
          <div className="flex items-center gap-2.5">
            <Layers className="w-5 h-5 text-zinc-700" />
            <div>
              <h3 className="text-sm font-bold text-zinc-900">
                WrindhaOS Core Feature Matrix & Limits
              </h3>
              <p className="text-xs text-zinc-500">
                Configure module toggles and allocation limits for the {name} tier.
              </p>
            </div>
          </div>
          <Badge variant="neutral" className="text-[11px] font-mono">
            {features.filter((f) => f.enabled).length} of {features.length} Enabled
          </Badge>
        </div>

        {/* Feature List Table */}
        <div className="overflow-x-auto border border-zinc-200 rounded-xl">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-zinc-200 bg-zinc-50/80 text-[11px] font-bold text-zinc-500 uppercase tracking-wider">
                <th className="py-3 px-4 w-12 text-center">Status</th>
                <th className="py-3 px-4">Feature Module</th>
                <th className="py-3 px-4">Description</th>
                <th className="py-3 px-4 w-60">Configured Limit / Quota</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-100 bg-white">
              {features.map((feat) => (
                <tr
                  key={feat.feature_key}
                  className={`hover:bg-zinc-50/50 transition-colors ${
                    !feat.enabled ? 'opacity-60 bg-zinc-50/30' : ''
                  }`}
                >
                  {/* Enabled Checkbox */}
                  <td className="py-3 px-4 text-center">
                    <button
                      type="button"
                      onClick={() => handleFeatureToggle(feat.feature_key)}
                      className={`w-5 h-5 rounded flex items-center justify-center border transition-all ${
                        feat.enabled
                          ? 'bg-zinc-900 border-zinc-900 text-white'
                          : 'bg-white border-zinc-300 hover:border-zinc-400'
                      }`}
                    >
                      {feat.enabled && <Check className="w-3.5 h-3.5 stroke-[2.5]" />}
                    </button>
                  </td>

                  {/* Feature Name */}
                  <td className="py-3 px-4">
                    <span className="font-semibold text-zinc-900 block">{feat.name}</span>
                    <span className="text-[10px] text-zinc-400 font-mono block">
                      {feat.feature_key}
                    </span>
                  </td>

                  {/* Feature Description */}
                  <td className="py-3 px-4 text-zinc-600 text-xs">{feat.description}</td>

                  {/* Feature Limit Field */}
                  <td className="py-3 px-4">
                    <input
                      type="text"
                      disabled={!feat.enabled}
                      value={feat.limit || ''}
                      onChange={(e) => handleFeatureLimitChange(feat.feature_key, e.target.value)}
                      placeholder={feat.enabled ? 'e.g. 5, Unlimited' : 'Disabled'}
                      className={`w-full px-2.5 py-1 text-xs border rounded-lg focus:outline-none focus:ring-1 focus:ring-zinc-900 transition-colors ${
                        !feat.enabled
                          ? 'bg-zinc-100 text-zinc-400 border-zinc-200 cursor-not-allowed'
                          : 'bg-white text-zinc-800 border-zinc-300 font-mono'
                      }`}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-between mt-6 pt-4 border-t border-zinc-100">
          <p className="text-xs text-zinc-400">
            Unspecified limits automatically default to "Not configured" in administrative views.
          </p>

          <Button
            variant="primary"
            size="sm"
            onClick={handleSaveClick}
            loading={saving}
            leftIcon={<Save className="w-3.5 h-3.5" />}
          >
            Save Configuration
          </Button>
        </div>
      </Card>

      {/* Confirmation Modal for Pro Price Change */}
      <ChangePriceModal
        isOpen={isPriceModalOpen}
        onClose={() => setIsPriceModalOpen(false)}
        planName={name || 'Pro'}
        previousPrice={plan?.price || 49}
        newPrice={pendingPrice}
        currency={plan?.currency || 'INR'}
        billingPeriod={plan?.billing_period || 'monthly'}
        onConfirm={() => executeSavePlan(pendingPrice)}
        isSubmitting={saving}
      />
    </div>
  );
};
