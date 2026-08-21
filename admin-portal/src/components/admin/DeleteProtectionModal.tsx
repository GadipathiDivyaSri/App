import React from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { AlertTriangle, ShieldAlert } from 'lucide-react';

interface DeleteProtectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  itemType: string;
  itemName: string;
  reason: string;
}

export const DeleteProtectionModal: React.FC<DeleteProtectionModalProps> = ({
  isOpen,
  onClose,
  title = 'Delete Protection Warning',
  itemType,
  itemName,
  reason,
}) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} maxWidth="max-w-md">
      <div className="space-y-4">
        <div className="flex items-start gap-3.5 p-3.5 bg-rose-50 rounded-xl border border-rose-200">
          <div className="w-9 h-9 rounded-lg bg-rose-100 text-rose-700 flex items-center justify-center shrink-0">
            <ShieldAlert className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-rose-900">Deletion Blocked</h4>
            <p className="text-xs text-rose-800/80 mt-0.5 leading-relaxed">
              This {itemType} cannot be deleted because it contains active child content.
            </p>
          </div>
        </div>

        <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200 text-xs text-zinc-700 space-y-2">
          <div>
            <span className="font-semibold text-zinc-900">Item:</span> {itemName} ({itemType})
          </div>
          <div className="flex items-start gap-2 text-zinc-600 bg-white p-2.5 rounded border border-zinc-200/80">
            <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
            <span>{reason}</span>
          </div>
        </div>

        <div className="text-[11px] text-zinc-500">
          To safely remove this {itemType}, first delete or reassign all attached child units, topics, or paths.
        </div>

        <div className="flex justify-end pt-2">
          <Button variant="primary" size="sm" onClick={onClose}>
            Understand & Return
          </Button>
        </div>
      </div>
    </Modal>
  );
};
