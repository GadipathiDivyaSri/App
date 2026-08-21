import React, { useState } from 'react';
import { Filter, RotateCcw } from 'lucide-react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { SubscriptionFilters, SubscriptionStatus } from '../../types';

interface SubscriptionFilterModalProps {
  isOpen: boolean;
  onClose: () => void;
  filters: SubscriptionFilters;
  onApply: (filters: SubscriptionFilters) => void;
  onReset: () => void;
}

export const SubscriptionFilterModal: React.FC<SubscriptionFilterModalProps> = ({
  isOpen,
  onClose,
  filters,
  onApply,
  onReset,
}) => {
  const [localFilters, setLocalFilters] = useState<SubscriptionFilters>(filters);

  const handleStatusToggle = (status: 'all' | SubscriptionStatus) => {
    setLocalFilters((prev) => ({ ...prev, status }));
  };

  const handlePlanToggle = (plan: 'all' | 'free' | 'pro') => {
    setLocalFilters((prev) => ({ ...prev, plan }));
  };

  const handleDateRangeToggle = (dateRange: SubscriptionFilters['dateRange']) => {
    setLocalFilters((prev) => ({ ...prev, dateRange }));
  };

  const handleApply = () => {
    onApply(localFilters);
    onClose();
  };

  const handleResetLocal = () => {
    const defaultFilters: SubscriptionFilters = {
      plan: 'all',
      status: 'all',
      dateRange: 'all',
    };
    setLocalFilters(defaultFilters);
    onReset();
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Filter Subscriptions" maxWidth="max-w-lg">
      <div className="space-y-6">
        {/* Plan Filter */}
        <div>
          <label className="text-xs font-bold text-zinc-900 uppercase tracking-wider block mb-2">
            Subscription Plan
          </label>
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: 'all', label: 'All Plans' },
              { id: 'free', label: 'Free (₹0)' },
              { id: 'pro', label: 'Pro (₹49/mo)' },
            ].map((p) => {
              const selected = localFilters.plan === p.id;
              return (
                <button
                  key={p.id}
                  type="button"
                  onClick={() => handlePlanToggle(p.id as typeof localFilters.plan)}
                  className={`py-2 px-3 text-xs font-medium rounded-lg border text-center transition-all ${
                    selected
                      ? 'bg-zinc-900 text-white border-zinc-900 font-semibold shadow-xs'
                      : 'bg-white text-zinc-700 border-zinc-200 hover:bg-zinc-50'
                  }`}
                >
                  {p.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Status Filter */}
        <div>
          <label className="text-xs font-bold text-zinc-900 uppercase tracking-wider block mb-2">
            Subscription Status
          </label>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
            {[
              { id: 'all', label: 'All Statuses' },
              { id: 'ACTIVE', label: 'Active' },
              { id: 'TRIALING', label: 'Trialing' },
              { id: 'CANCELLED', label: 'Cancelled' },
              { id: 'EXPIRED', label: 'Expired' },
              { id: 'PAST_DUE', label: 'Past Due' },
            ].map((s) => {
              const selected = localFilters.status === s.id;
              return (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => handleStatusToggle(s.id as typeof localFilters.status)}
                  className={`py-2 px-3 text-xs font-medium rounded-lg border text-center transition-all ${
                    selected
                      ? 'bg-zinc-900 text-white border-zinc-900 font-semibold shadow-xs'
                      : 'bg-white text-zinc-700 border-zinc-200 hover:bg-zinc-50'
                  }`}
                >
                  {s.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Date Filter */}
        <div>
          <label className="text-xs font-bold text-zinc-900 uppercase tracking-wider block mb-2">
            Subscription Start Date
          </label>
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: 'all', label: 'All Time' },
              { id: 'today', label: 'Today' },
              { id: '7d', label: 'Last 7 days' },
              { id: '30d', label: 'Last 30 days' },
              { id: '90d', label: 'Last 90 days' },
              { id: 'custom', label: 'Custom Range' },
            ].map((d) => {
              const selected = localFilters.dateRange === d.id;
              return (
                <button
                  key={d.id}
                  type="button"
                  onClick={() => handleDateRangeToggle(d.id as typeof localFilters.dateRange)}
                  className={`py-2 px-3 text-xs font-medium rounded-lg border text-center transition-all ${
                    selected
                      ? 'bg-zinc-900 text-white border-zinc-900 font-semibold shadow-xs'
                      : 'bg-white text-zinc-700 border-zinc-200 hover:bg-zinc-50'
                  }`}
                >
                  {d.label}
                </button>
              );
            })}
          </div>

          {/* Custom Date Pickers */}
          {localFilters.dateRange === 'custom' && (
            <div className="mt-3 p-3.5 bg-zinc-50 border border-zinc-200 rounded-xl grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">Start Date</label>
                <input
                  type="date"
                  value={localFilters.customStartDate || ''}
                  onChange={(e) =>
                    setLocalFilters((prev) => ({ ...prev, customStartDate: e.target.value }))
                  }
                  className="w-full px-3 py-1.5 bg-white border border-zinc-300 rounded-lg text-xs text-zinc-800 focus:outline-none focus:ring-1 focus:ring-zinc-900"
                />
              </div>
              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">End Date</label>
                <input
                  type="date"
                  value={localFilters.customEndDate || ''}
                  onChange={(e) =>
                    setLocalFilters((prev) => ({ ...prev, customEndDate: e.target.value }))
                  }
                  className="w-full px-3 py-1.5 bg-white border border-zinc-300 rounded-lg text-xs text-zinc-800 focus:outline-none focus:ring-1 focus:ring-zinc-900"
                />
              </div>
            </div>
          )}
        </div>

        {/* Modal Controls */}
        <div className="flex items-center justify-between pt-4 border-t border-zinc-100">
          <Button
            variant="ghost"
            size="sm"
            onClick={handleResetLocal}
            leftIcon={<RotateCcw className="w-3.5 h-3.5" />}
          >
            Reset Filters
          </Button>

          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={onClose}>
              Cancel
            </Button>
            <Button variant="primary" size="sm" onClick={handleApply} leftIcon={<Filter className="w-3.5 h-3.5" />}>
              Apply Filters
            </Button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
