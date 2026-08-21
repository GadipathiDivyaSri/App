import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { WrindhaUser } from '../../types';
import { CheckCircle2, ShieldCheck } from 'lucide-react';

interface RestoreUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: WrindhaUser | null;
  onConfirmRestore: (userId: string) => Promise<void>;
}

export const RestoreUserModal: React.FC<RestoreUserModalProps> = ({
  isOpen,
  onClose,
  user,
  onConfirmRestore,
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!user) return null;

  const handleConfirm = async () => {
    setIsLoading(true);
    setError(null);
    try {
      await onConfirmRestore(user.id);
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to restore account.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Restore User Account"
      maxWidth="max-w-md"
    >
      <div className="space-y-4 pt-1">
        {/* Info Box */}
        <div className="p-3.5 bg-emerald-50 border border-emerald-200 rounded-xl flex items-start gap-3 text-xs text-emerald-900">
          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
          <div className="leading-relaxed">
            <span className="font-semibold block mb-0.5">Reinstate Application Access</span>
            Restoring this account will immediately remove the suspension flag and allow the student/professional to sign back in and access their productivity workspaces.
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
          {user.metadata?.suspension_reason && (
            <div className="pt-2 border-t border-zinc-200">
              <span className="text-zinc-500 block mb-0.5">Prior Suspension Reason:</span>
              <span className="text-rose-700 italic block">{user.metadata.suspension_reason}</span>
            </div>
          )}
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
            type="button"
            variant="primary"
            size="sm"
            onClick={handleConfirm}
            isLoading={isLoading}
            leftIcon={<ShieldCheck className="w-3.5 h-3.5" />}
          >
            Confirm Restore
          </Button>
        </div>
      </div>
    </Modal>
  );
};
