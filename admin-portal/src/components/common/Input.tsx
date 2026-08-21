import React, { useState } from 'react';
import { Eye, EyeOff, Search } from 'lucide-react';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  isSearch?: boolean;
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, leftIcon, rightIcon, isSearch, type = 'text', className = '', id, ...props }, ref) => {
    const [showPassword, setShowPassword] = useState(false);
    const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);
    const isPasswordType = type === 'password';

    const actualType = isPasswordType ? (showPassword ? 'text' : 'password') : type;

    return (
      <div className="w-full">
        {label && (
          <label htmlFor={inputId} className="block text-xs font-semibold uppercase tracking-wider text-zinc-600 mb-1.5">
            {label}
          </label>
        )}
        <div className="relative flex items-center">
          {isSearch && (
            <div className="absolute left-3 text-zinc-400 pointer-events-none flex items-center">
              <Search className="w-4 h-4" />
            </div>
          )}
          {!isSearch && leftIcon && (
            <div className="absolute left-3 text-zinc-400 pointer-events-none flex items-center">
              {leftIcon}
            </div>
          )}

          <input
            ref={ref}
            id={inputId}
            type={actualType}
            className={`w-full rounded-lg border bg-white text-zinc-900 placeholder:text-zinc-400 text-sm transition-colors
              focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:border-zinc-900 disabled:bg-zinc-50 disabled:text-zinc-500
              ${isSearch || leftIcon ? 'pl-9.5' : 'pl-3.5'}
              ${isPasswordType || rightIcon ? 'pr-10' : 'pr-3.5'}
              py-2.5
              ${error ? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500' : 'border-zinc-300'}
              ${className}
            `}
            {...props}
          />

          {isPasswordType && (
            <button
              type="button"
              tabIndex={-1}
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 text-zinc-400 hover:text-zinc-600 focus:outline-none p-1"
            >
              {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          )}

          {!isPasswordType && rightIcon && (
            <div className="absolute right-3 text-zinc-400 flex items-center">
              {rightIcon}
            </div>
          )}
        </div>

        {error && <p className="mt-1.5 text-xs text-rose-600">{error}</p>}
        {!error && helperText && <p className="mt-1.5 text-xs text-zinc-500">{helperText}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';
