import React from 'react';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';
import { Modal } from '../common/Modal';
import { Button } from '../common/Button';

interface ChangePriceModalProps {
  isOpen: boolean;
  onClose: () => void;
  planName: string;
  previousPrice: number;
  newPrice: number;
  currency: string;
  billingPeriod: string;
  onConfirm: () => void;
  isSubmitting?: boolean;
}

export const ChangePriceModal: React.FC<ChangePriceModalProps> = ({
  isOpen,
  onClose,
  planName,
  previousPrice,
  newPrice,
  currency,
  billingPeriod,
  onConfirm,
  isSubmitting = false,
}) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Confirm Price Adjustment" maxWidth="max-w-md">
      <div className="space-y-4">
        {/* Warning Callout */}
        <div className="p-4 bg-amber-50 border border-amber-200/80 rounded-xl flex items-start gap-3 text-amber-900">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div className="text-xs space-y-1">
            <p className="font-semibold text-amber-950">Important Pricing Change Notice</p>
            <p className="text-amber-800 leading-relaxed">
              Changing the Pro price will affect future subscription purchases. Continue?
            </p>
          </div>
        </div>

        {/* Pricing Comparison Box */}
        <div className="p-4 bg-zinc-50 border border-zinc-200/80 rounded-xl space-y-3">
          <div className="text-xs font-semibold text-zinc-500 uppercase tracking-wider">
            {planName} Plan Pricing Update
          </div>

          <div className="flex items-center justify-between py-1 text-xs">
            <span className="text-zinc-500">Current Price</span>
            <span className="font-mono font-medium text-zinc-700">
              ₹{previousPrice} {currency} / {billingPeriod}
            </span>
          </div>

          <div className="flex items-center justify-between py-1 text-xs border-t border-zinc-200/60 pt-2">
            <span className="font-semibold text-zinc-900">New Price</span>
            <span className="font-mono font-bold text-zinc-900 text-sm">
              ₹{newPrice} {currency} / {billingPeriod}
            </span>
          </div>
        </div>

        <p className="text-[11px] text-zinc-500 leading-normal">
          This action will be logged in the immutable administrative audit logs with your administrator credentials and timestamp.
        </p>

        {/* Modal Actions */}
        <div className="flex items-center justify-end gap-3 pt-3 border-t border-zinc-100">
          <Button variant="outline" size="sm" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button
            variant="primary"
            size="sm"
            onClick={onConfirm}
            loading={isSubmitting}
            leftIcon={<CheckCircle2 className="w-4 h-4" />}
          >
            Confirm & Save Price
          </Button>
        </div>
      </div>
    </Modal>
  );
};
