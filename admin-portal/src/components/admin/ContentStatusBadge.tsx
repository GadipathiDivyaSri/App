import React from 'react';
import { ContentStatus } from '../../types';

interface ContentStatusBadgeProps {
  status: ContentStatus;
  size?: 'sm' | 'md';
}

export const ContentStatusBadge: React.FC<ContentStatusBadgeProps> = ({ status, size = 'md' }) => {
  const sizeClasses =
    size === 'sm'
      ? 'text-[10px] px-2 py-0.5 font-semibold'
      : 'text-xs px-2.5 py-1 font-semibold';

  if (status === 'PUBLISHED') {
    return (
      <span
        className={`inline-flex items-center gap-1.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200/80 ${sizeClasses}`}
      >
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
        PUBLISHED
      </span>
    );
  }

  if (status === 'ARCHIVED') {
    return (
      <span
        className={`inline-flex items-center gap-1.5 rounded-full bg-zinc-100 text-zinc-600 border border-zinc-200 ${sizeClasses}`}
      >
        <span className="w-1.5 h-1.5 rounded-full bg-zinc-400" />
        ARCHIVED
      </span>
    );
  }

  // DRAFT
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200/80 ${sizeClasses}`}
    >
      <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
      DRAFT
    </span>
  );
};
