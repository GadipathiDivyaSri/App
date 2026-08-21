import React from 'react';
import { Loader2 } from 'lucide-react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  leftIcon,
  rightIcon,
  className = '',
  disabled,
  ...props
}) => {
  const baseStyles = 'inline-flex items-center justify-center font-medium transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed select-none rounded-lg';

  const sizeStyles = {
    sm: 'px-3 py-1.5 text-xs gap-1.5',
    md: 'px-4 py-2 text-sm gap-2',
    lg: 'px-5 py-2.5 text-base gap-2.5',
  };

  const variantStyles = {
    primary: 'bg-zinc-900 text-white hover:bg-zinc-800 active:bg-zinc-950 focus:ring-zinc-900 shadow-xs dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-white',
    secondary: 'bg-zinc-100 text-zinc-800 hover:bg-zinc-200 active:bg-zinc-300 focus:ring-zinc-400 dark:bg-zinc-800 dark:text-zinc-200 dark:hover:bg-zinc-700',
    outline: 'border border-zinc-300 bg-white text-zinc-700 hover:bg-zinc-50 active:bg-zinc-100 focus:ring-zinc-500 shadow-xs dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200 dark:hover:bg-zinc-800',
    ghost: 'text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 active:bg-zinc-200 focus:ring-zinc-400 dark:text-zinc-400 dark:hover:text-zinc-100 dark:hover:bg-zinc-800',
    danger: 'bg-rose-600 text-white hover:bg-rose-700 active:bg-rose-800 focus:ring-rose-500 shadow-xs',
  };

  return (
    <button
      disabled={disabled || isLoading}
      className={`${baseStyles} ${sizeStyles[size]} ${variantStyles[variant]} ${className}`}
      {...props}
    >
      {isLoading ? (
        <Loader2 className="w-4 h-4 animate-spin shrink-0" />
      ) : (
        leftIcon && <span className="shrink-0">{leftIcon}</span>
      )}
      <span>{children}</span>
      {!isLoading && rightIcon && <span className="shrink-0">{rightIcon}</span>}
    </button>
  );
};
