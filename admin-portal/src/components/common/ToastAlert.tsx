import React, { useEffect } from 'react';
import { CheckCircle2, AlertCircle, X, Info } from 'lucide-react';

export interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'info';
  title: string;
  message?: string;
}

interface ToastAlertProps {
  toast: ToastMessage | null;
  onDismiss: () => void;
}

export const ToastAlert: React.FC<ToastAlertProps> = ({ toast, onDismiss }) => {
  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => {
        onDismiss();
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [toast, onDismiss]);

  if (!toast) return null;

  const typeStyles = {
    success: 'bg-emerald-50 border-emerald-200 text-emerald-900',
    error: 'bg-rose-50 border-rose-200 text-rose-900',
    info: 'bg-blue-50 border-blue-200 text-blue-900',
  };

  const icons = {
    success: <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />,
    error: <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />,
    info: <Info className="w-4 h-4 text-blue-600 shrink-0" />,
  };

  return (
    <div className="fixed bottom-6 right-6 z-50 max-w-sm w-full animate-in slide-in-from-bottom-5 fade-in duration-200">
      <div
        className={`p-3.5 rounded-xl border shadow-lg flex items-start justify-between gap-3 ${
          typeStyles[toast.type]
        }`}
      >
        <div className="flex items-start gap-2.5">
          {icons[toast.type]}
          <div>
            <h4 className="text-xs font-semibold">{toast.title}</h4>
            {toast.message && <p className="text-[11px] mt-0.5 opacity-90">{toast.message}</p>}
          </div>
        </div>
        <button
          type="button"
          onClick={onDismiss}
          className="text-zinc-400 hover:text-zinc-700 p-0.5 rounded-md transition-colors"
          aria-label="Close notification"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
};
