import React from 'react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';
import { CheckCircle2, Globe2 } from 'lucide-react';

interface PublishConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title?: string;
  itemType: string;
  itemName: string;
  isLoading?: boolean;
}

export const PublishConfirmModal: React.FC<PublishConfirmModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title = 'Publish Content to App?',
  itemType,
  itemName,
  isLoading = false,
}) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} maxWidth="max-w-md">
      <div className="space-y-4">
        <div className="flex items-start gap-3.5 p-3.5 bg-emerald-50/80 rounded-xl border border-emerald-100">
          <div className="w-9 h-9 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
            <Globe2 className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-emerald-900">Publish this content?</h4>
            <p className="text-xs text-emerald-800/80 mt-0.5 leading-relaxed">
              Once published, this {itemType} will become immediately visible and accessible to all students inside the live WrindhaOS app.
            </p>
          </div>
        </div>

        <div className="p-3 bg-zinc-50 rounded-lg border border-zinc-200">
          <div className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500 mb-1">
            Target Item
          </div>
          <div className="text-sm font-bold text-zinc-900 truncate">{itemName}</div>
          <div className="text-xs text-zinc-500 capitalize">{itemType}</div>
        </div>

        <div className="flex items-center justify-end gap-3 pt-2">
          <Button variant="outline" size="sm" onClick={onClose} disabled={isLoading}>
            Cancel
          </Button>
          <Button
            variant="primary"
            size="sm"
            onClick={onConfirm}
            isLoading={isLoading}
            className="bg-emerald-600 hover:bg-emerald-700 text-white"
          >
            <CheckCircle2 className="w-4 h-4 mr-1.5 inline" />
            Yes, Publish Content
          </Button>
        </div>
      </div>
    </Modal>
  );
};
