import React from 'react';
import { Loader2 } from 'lucide-react';

export const LoadingState: React.FC<{ message?: string; className?: string }> = ({
  message = 'Loading data from database...',
  className = '',
}) => {
  return (
    <div className={`flex flex-col items-center justify-center p-12 text-center ${className}`}>
      <Loader2 className="w-8 h-8 text-zinc-900 animate-spin mb-3" />
      <p className="text-sm font-medium text-zinc-600">{message}</p>
    </div>
  );
};

export const SkeletonRow: React.FC<{ count?: number }> = ({ count = 4 }) => {
  return (
    <div className="space-y-3 animate-pulse">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="h-10 bg-zinc-100 rounded-lg w-full" />
      ))}
    </div>
  );
};
