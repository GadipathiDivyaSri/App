import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { WrindhaUser } from '../../types';
import { UserX, Clock } from 'lucide-react';

interface RequestDeletionModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: WrindhaUser | null;
  onConfirmRequest: (userId: string, reason: string) => Promise<void>;
}

export const RequestDeletionModal: React.FC<RequestDeletionModalProps> = ({
  isOpen,
  onClose,
  user,
  onConfirmRequest,
}) => {
  const [reason, setReason] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!user) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) {
      setError('Please specify the reason or compliance request reference.');
      return;
    }

    setIsLoading(true);
    setError(null);
    try {
      await onConfirmRequest(user.id, reason.trim());
      setReason('');
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to submit deletion request.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Request Account Deletion"
      maxWidth="max-w-md"
    >
      <form onSubmit={handleSubmit} className="space-y-4 pt-1">
        {/* Compliance Notice */}
        <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-xl flex items-start gap-3 text-xs text-amber-900">
          <Clock className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
          <div className="leading-relaxed">
            <span className="font-semibold block mb-0.5">Two-Stage Deletion Queue</span>
            This action registers a verified account deletion request in the <strong>account_deletion_requests</strong> table. In accordance with data retention policies, data is not immediately purged until reviewed.
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
            Deletion Justification / GDPR Request Reference <span className="text-rose-500">*</span>
          </label>
          <textarea
            required
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g., GDPR Article 17 Right to Erasure request from user ticket #8492..."
            className="w-full text-xs bg-white border border-zinc-200 rounded-xl p-3 text-zinc-900 placeholder:text-zinc-400 focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:border-amber-500"
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
            variant="secondary"
            size="sm"
            isLoading={isLoading}
            leftIcon={<UserX className="w-3.5 h-3.5" />}
            className="bg-amber-600 hover:bg-amber-700 text-white border-amber-600"
          >
            Submit Deletion Request
          </Button>
        </div>
      </form>
    </Modal>
  );
};
