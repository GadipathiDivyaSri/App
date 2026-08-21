import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { WrindhaUser } from '../../types';
import { ShieldAlert, AlertTriangle } from 'lucide-react';

interface SuspendUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: WrindhaUser | null;
  onConfirmSuspend: (userId: string, reason: string) => Promise<void>;
}

export const SuspendUserModal: React.FC<SuspendUserModalProps> = ({
  isOpen,
  onClose,
  user,
  onConfirmSuspend,
}) => {
  const [reason, setReason] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!user) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) {
      setError('Please provide a specific justification for suspending this account.');
      return;
    }

    setIsLoading(true);
    setError(null);
    try {
      await onConfirmSuspend(user.id, reason.trim());
      setReason('');
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to suspend account.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Suspend User Account"
      maxWidth="max-w-md"
    >
      <form onSubmit={handleSubmit} className="space-y-4 pt-1">
        {/* Warning Callout */}
        <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-xl flex items-start gap-3 text-xs text-rose-900">
          <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
          <div className="leading-relaxed">
            <span className="font-semibold block mb-0.5">Account Access Restriction</span>
            The user will no longer be able to use the WrindhaOS application while suspended. All active sessions will be invalidated.
          </div>
        </div>

        {/* User Summary Card */}
        <div className="p-3 bg-zinc-50 border border-zinc-200 rounded-xl text-xs space-y-1.5">
          <div className="flex justify-between">
            <span className="text-zinc-500">Target User:</span>
            <span className="font-semibold text-zinc-900">{user.name}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-zinc-500">Email:</span>
            <span className="font-mono text-zinc-800">{user.email}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-zinc-500">User ID:</span>
            <span className="font-mono text-zinc-600 text-[11px]">{user.id}</span>
          </div>
        </div>

        {/* Reason Input */}
        <div>
          <label className="block text-xs font-semibold text-zinc-900 mb-1.5">
            Administrative Suspension Reason <span className="text-rose-500">*</span>
          </label>
          <textarea
            required
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g., Suspected unauthorized automated scraping, Terms of Service violation..."
            className="w-full text-xs bg-white border border-zinc-200 rounded-xl p-3 text-zinc-900 placeholder:text-zinc-400 focus:outline-hidden focus:ring-2 focus:ring-rose-500 focus:border-rose-500"
          />
        </div>

        {error && (
          <div className="p-2.5 bg-rose-50 border border-rose-200 rounded-lg text-xs text-rose-700">
            {error}
          </div>
        )}

        {/* Actions */}
        <div className="pt-3 border-t border-zinc-200 flex items-center justify-end gap-2.5">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={onClose}
            disabled={isLoading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            variant="danger"
            size="sm"
            isLoading={isLoading}
            leftIcon={<ShieldAlert className="w-3.5 h-3.5" />}
          >
            Confirm Suspension
          </Button>
        </div>
      </form>
    </Modal>
  );
};
