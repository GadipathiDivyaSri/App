import React from 'react';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  className?: string;
}

export const Card: React.FC<CardProps> = ({ children, className = '', ...props }) => {
  return (
    <div
      className={`bg-white border border-zinc-200/80 rounded-xl shadow-xs overflow-hidden ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

export const CardHeader: React.FC<{
  title?: string;
  subtitle?: string;
  action?: React.ReactNode;
  children?: React.ReactNode;
  className?: string;
}> = ({ title, subtitle, action, children, className = '' }) => {
  if (children) {
    return <div className={`p-5 sm:p-6 border-b border-zinc-100 ${className}`}>{children}</div>;
  }

  return (
    <div className={`p-5 sm:p-6 border-b border-zinc-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 ${className}`}>
      <div>
        {title && <h3 className="text-base font-semibold text-zinc-900 tracking-tight">{title}</h3>}
        {subtitle && <p className="text-sm text-zinc-500 mt-0.5">{subtitle}</p>}
      </div>
      {action && <div className="flex items-center gap-2 shrink-0">{action}</div>}
    </div>
  );
};

export const CardContent: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = '' }) => {
  return <div className={`p-5 sm:p-6 ${className}`}>{children}</div>;
};

export const CardFooter: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className = '' }) => {
  return <div className={`px-5 sm:px-6 py-4 bg-zinc-50/70 border-t border-zinc-100 flex items-center justify-between ${className}`}>{children}</div>;
};
