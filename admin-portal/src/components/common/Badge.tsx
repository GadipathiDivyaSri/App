import React from 'react';
import { UserStatus } from '../../types';

export interface BadgeProps {
  children?: React.ReactNode;
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'purple' | 'neutral';
  size?: 'sm' | 'md';
  status?: UserStatus | string;
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant,
  size = 'md',
  status,
  className = '',
}) => {
  let resolvedVariant = variant || 'default';

  if (status) {
    switch (status.toLowerCase()) {
      case 'active':
        resolvedVariant = 'success';
        break;
      case 'pending':
        resolvedVariant = 'warning';
        break;
      case 'suspended':
        resolvedVariant = 'danger';
        break;
      case 'inactive':
        resolvedVariant = 'neutral';
        break;
      case 'pro':
      case 'super_admin':
        resolvedVariant = 'purple';
        break;
      case 'free':
        resolvedVariant = 'info';
        break;
      default:
        resolvedVariant = 'neutral';
    }
  }

  const sizeStyles = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-xs',
  };

  const variantStyles = {
    default: 'bg-zinc-100 text-zinc-700 border border-zinc-200/80',
    primary: 'bg-zinc-900 text-white border border-zinc-900',
    neutral: 'bg-zinc-100 text-zinc-600 border border-zinc-200/60',
    success: 'bg-emerald-50 text-emerald-700 border border-emerald-200/80',
    warning: 'bg-amber-50 text-amber-700 border border-amber-200/80',
    danger: 'bg-rose-50 text-rose-700 border border-rose-200/80',
    info: 'bg-sky-50 text-sky-700 border border-sky-200/80',
    purple: 'bg-indigo-50 text-indigo-700 border border-indigo-200/80',
  };

  const displayText = children || (status ? status.charAt(0).toUpperCase() + status.slice(1) : '');

  return (
    <span
      className={`inline-flex items-center font-medium rounded-md tracking-wide whitespace-nowrap capitalize ${sizeStyles[size]} ${variantStyles[resolvedVariant]} ${className}`}
    >
      {displayText}
    </span>
  );
};
