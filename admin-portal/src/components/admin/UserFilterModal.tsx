import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { UserFilters } from '../../types';
import { Filter, Calendar, Activity, ShieldAlert, Sparkles, RotateCcw } from 'lucide-react';

interface UserFilterModalProps {
  isOpen: boolean;
  onClose: () => void;
  filters: UserFilters;
  onApplyFilters: (filters: UserFilters) => void;
  onResetFilters: () => void;
}

export function countActiveFilters(filters: UserFilters): number {
  let count = 0;
  if (filters.status !== 'all') count++;
  if (filters.plan !== 'all') count++;
  if (filters.registrationDate !== 'all') count++;
  if (filters.lastActive !== 'all') count++;
  return count;
}

export const UserFilterModal: React.FC<UserFilterModalProps> = ({
  isOpen,
  onClose,
  filters,
  onApplyFilters,
  onResetFilters,
}) => {
  const [draftFilters, setDraftFilters] = useState<UserFilters>(filters);

  // Sync draft when opened
  React.useEffect(() => {
    if (isOpen) {
      setDraftFilters(filters);
    }
  }, [isOpen, filters]);

  const handleApply = () => {
    onApplyFilters(draftFilters);
    onClose();
  };

  const handleReset = () => {
    onResetFilters();
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Filter Users"
      maxWidth="max-w-lg"
    >
      <div className="space-y-6 pt-1">
        {/* 1. Account Status */}
        <div>
          <label className="block text-xs font-semibold text-zinc-900 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
            <ShieldAlert className="w-3.5 h-3.5 text-zinc-500" />
            <span>Account Status</span>
          </label>
          <div className="grid grid-cols-4 gap-2">
            {[
              { id: 'all', label: 'All' },
              { id: 'active', label: 'Active' },
              { id: 'inactive', label: 'Inactive' },
              { id: 'suspended', label: 'Suspended' },
            ].map((st) => (
              <button
                key={st.id}
                type="button"
                onClick={() =>
                  setDraftFilters((prev) => ({
                    ...prev,
                    status: st.id as UserFilters['status'],
                  }))
                }
                className={`py-2 px-2.5 text-xs font-medium rounded-lg border text-center transition-colors ${
                  draftFilters.status === st.id
                    ? 'bg-zinc-900 border-zinc-900 text-white font-semibold shadow-xs'
                    : 'bg-white border-zinc-200 text-zinc-700 hover:bg-zinc-50'
                }`}
              >
                {st.label}
              </button>
            ))}
          </div>
        </div>

        {/* 2. Current Plan */}
        <div>
          <label className="block text-xs font-semibold text-zinc-900 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-zinc-500" />
            <span>Subscription Plan</span>
          </label>
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: 'all', label: 'All Plans' },
              { id: 'Free', label: 'Free' },
              { id: 'Pro', label: 'Pro' },
            ].map((p) => (
              <button
                key={p.id}
                type="button"
                onClick={() =>
                  setDraftFilters((prev) => ({
                    ...prev,
                    plan: p.id as UserFilters['plan'],
                  }))
                }
                className={`py-2 px-3 text-xs font-medium rounded-lg border text-center transition-colors ${
                  draftFilters.plan === p.id
                    ? 'bg-zinc-900 border-zinc-900 text-white font-semibold shadow-xs'
                    : 'bg-white border-zinc-200 text-zinc-700 hover:bg-zinc-50'
                }`}
              >
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {/* 3. Registration Date */}
        <div>
          <label className="block text-xs font-semibold text-zinc-900 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
            <Calendar className="w-3.5 h-3.5 text-zinc-500" />
            <span>Registration Date</span>
          </label>
          <div className="grid grid-cols-3 gap-2 mb-3">
            {[
              { id: 'all', label: 'All Time' },
              { id: 'today', label: 'Today' },
              { id: '7d', label: 'Last 7 Days' },
              { id: '30d', label: 'Last 30 Days' },
              { id: '90d', label: 'Last 90 Days' },
              { id: 'custom', label: 'Custom Range' },
            ].map((rd) => (
              <button
                key={rd.id}
                type="button"
                onClick={() =>
                  setDraftFilters((prev) => ({
                    ...prev,
                    registrationDate: rd.id as UserFilters['registrationDate'],
                  }))
                }
                className={`py-2 px-2.5 text-xs font-medium rounded-lg border text-center transition-colors ${
                  draftFilters.registrationDate === rd.id
                    ? 'bg-zinc-900 border-zinc-900 text-white font-semibold shadow-xs'
                    : 'bg-white border-zinc-200 text-zinc-700 hover:bg-zinc-50'
                }`}
              >
                {rd.label}
              </button>
            ))}
          </div>

          {draftFilters.registrationDate === 'custom' && (
            <div className="p-3 bg-zinc-50 border border-zinc-200 rounded-lg grid grid-cols-2 gap-3 animate-in fade-in">
              <div>
                <span className="block text-[11px] font-medium text-zinc-500 mb-1">Start Date</span>
                <input
                  type="date"
                  value={draftFilters.customStartDate || ''}
                  onChange={(e) =>
                    setDraftFilters((prev) => ({
                      ...prev,
                      customStartDate: e.target.value,
                    }))
                  }
                  className="w-full text-xs bg-white border border-zinc-200 rounded-md px-2.5 py-1.5 text-zinc-800 focus:outline-hidden focus:ring-1 focus:ring-zinc-900"
                />
              </div>
              <div>
                <span className="block text-[11px] font-medium text-zinc-500 mb-1">End Date</span>
                <input
                  type="date"
                  value={draftFilters.customEndDate || ''}
                  onChange={(e) =>
                    setDraftFilters((prev) => ({
                      ...prev,
                      customEndDate: e.target.value,
                    }))
                  }
                  className="w-full text-xs bg-white border border-zinc-200 rounded-md px-2.5 py-1.5 text-zinc-800 focus:outline-hidden focus:ring-1 focus:ring-zinc-900"
                />
              </div>
            </div>
          )}
        </div>

        {/* 4. Last Active */}
        <div>
          <label className="block text-xs font-semibold text-zinc-900 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
            <Activity className="w-3.5 h-3.5 text-zinc-500" />
            <span>Last Activity</span>
          </label>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
            {[
              { id: 'all', label: 'All Users' },
              { id: 'today', label: 'Today' },
              { id: '7d', label: 'Last 7 Days' },
              { id: '30d', label: 'Last 30 Days' },
              { id: 'inactive_30d', label: '30+ Days Inactive' },
            ].map((la) => (
              <button
                key={la.id}
                type="button"
                onClick={() =>
                  setDraftFilters((prev) => ({
                    ...prev,
                    lastActive: la.id as UserFilters['lastActive'],
                  }))
                }
                className={`py-2 px-2.5 text-xs font-medium rounded-lg border text-center transition-colors ${
                  draftFilters.lastActive === la.id
                    ? 'bg-zinc-900 border-zinc-900 text-white font-semibold shadow-xs'
                    : 'bg-white border-zinc-200 text-zinc-700 hover:bg-zinc-50'
                }`}
              >
                {la.label}
              </button>
            ))}
          </div>
        </div>

        {/* Footer Actions */}
        <div className="pt-4 border-t border-zinc-200 flex items-center justify-between gap-3">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={handleReset}
            leftIcon={<RotateCcw className="w-3.5 h-3.5" />}
          >
            Reset All
          </Button>

          <div className="flex items-center gap-2">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={onClose}
            >
              Cancel
            </Button>
            <Button
              type="button"
              variant="primary"
              size="sm"
              onClick={handleApply}
              leftIcon={<Filter className="w-3.5 h-3.5" />}
            >
              Apply Filters
            </Button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
