import React, { useEffect } from 'react';
import { X } from 'lucide-react';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  subtitle?: string;
  children: React.ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl';
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  maxWidth = 'md',
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const maxWidthClasses = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '2xl': 'max-w-2xl',
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4 text-center sm:p-0">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-zinc-900/60 backdrop-blur-xs transition-opacity animate-in fade-in duration-200"
          onClick={onClose}
        />

        {/* Modal Dialog */}
        <div
          className={`relative transform overflow-hidden rounded-xl bg-white text-left shadow-xl transition-all w-full my-8 ${maxWidthClasses[maxWidth]} border border-zinc-200 animate-in zoom-in-95 duration-150`}
        >
          <div className="flex items-start justify-between p-5 sm:p-6 border-b border-zinc-100">
            <div>
              {title && <h3 className="text-base font-semibold text-zinc-900">{title}</h3>}
              {subtitle && <p className="text-xs text-zinc-500 mt-0.5">{subtitle}</p>}
            </div>
            <button
              onClick={onClose}
              className="rounded-lg p-1.5 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600 transition-colors focus:outline-none"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="p-5 sm:p-6">{children}</div>
        </div>
      </div>
    </div>
  );
};
