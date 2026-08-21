import React from 'react';
import { Inbox } from 'lucide-react';
import { Button } from './Button';

export interface EmptyStateProps {
  title?: string;
  description?: string;
  icon?: React.ReactNode;
  actionText?: string;
  onAction?: () => void;
  className?: string;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title = 'No records found',
  description = 'There is no data to display right now.',
  icon,
  actionText,
  onAction,
  className = '',
}) => {
  return (
    <div className={`flex flex-col items-center justify-center p-8 sm:p-12 text-center ${className}`}>
      <div className="w-12 h-12 rounded-full bg-zinc-100 flex items-center justify-center text-zinc-400 mb-3.5 border border-zinc-200/60">
        {icon || <Inbox className="w-6 h-6" />}
      </div>
      <h4 className="text-sm font-semibold text-zinc-900 tracking-tight">{title}</h4>
      <p className="text-xs text-zinc-500 max-w-sm mt-1 mb-4 leading-relaxed">{description}</p>
      {actionText && onAction && (
        <Button variant="outline" size="sm" onClick={onAction}>
          {actionText}
        </Button>
      )}
    </div>
  );
};
