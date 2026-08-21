import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from './Button';

export interface Column<T> {
  header: string;
  accessorKey?: keyof T;
  cell?: (row: T) => React.ReactNode;
  className?: string;
  headerClassName?: string;
}

export interface TableProps<T = any> {
  columns?: Column<T>[];
  data?: T[];
  keyExtractor?: (item: T) => string;
  isLoading?: boolean;
  emptyState?: React.ReactNode;
  onRowClick?: (item: T) => void;
  // Pagination
  pagination?: {
    currentPage: number;
    totalPages: number;
    totalItems: number;
    pageSize: number;
    onPageChange: (newPage: number) => void;
  };
  children?: React.ReactNode;
  className?: string;
}

export function Table<T = any>({
  columns,
  data,
  keyExtractor,
  isLoading = false,
  emptyState,
  onRowClick,
  pagination,
  children,
  className = '',
}: TableProps<T>) {
  if (children) {
    return (
      <div className={`w-full overflow-x-auto border border-zinc-200/80 rounded-xl bg-white shadow-xs ${className}`}>
        <table className="w-full text-left border-collapse text-sm">
          {children}
        </table>
      </div>
    );
  }

  const safeColumns = columns || [];
  const safeData = data || [];

  return (
    <div className="w-full flex flex-col">
      <div className="overflow-x-auto border border-zinc-200/80 rounded-xl bg-white shadow-xs">
        <table className="w-full text-left border-collapse text-sm">
          <thead>
            <tr className="border-b border-zinc-200/80 bg-zinc-50/80 text-zinc-500 font-medium text-xs uppercase tracking-wider">
              {safeColumns.map((col, idx) => (
                <th
                  key={idx}
                  className={`py-3.5 px-4 font-semibold text-zinc-600 ${col.headerClassName || ''}`}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-zinc-100">
            {isLoading ? (
              // Loading skeletons
              Array.from({ length: pagination?.pageSize || 5 }).map((_, rIdx) => (
                <tr key={`skel-${rIdx}`} className="animate-pulse">
                  {safeColumns.map((_, cIdx) => (
                    <td key={`skel-c-${cIdx}`} className="py-4 px-4">
                      <div className="h-4 bg-zinc-200 rounded-md w-3/4"></div>
                    </td>
                  ))}
                </tr>
              ))
            ) : safeData.length === 0 ? (
              <tr>
                <td colSpan={safeColumns.length} className="py-12 px-4 text-center">
                  {emptyState || <div className="text-zinc-500 text-sm">No records found.</div>}
                </td>
              </tr>
            ) : (
              safeData.map((row) => (
                <tr
                  key={keyExtractor ? keyExtractor(row) : (row as any).id || String(Math.random())}
                  onClick={() => onRowClick && onRowClick(row)}
                  className={`transition-colors duration-100 ${
                    onRowClick ? 'cursor-pointer hover:bg-zinc-50/80' : 'hover:bg-zinc-50/40'
                  }`}
                >
                  {safeColumns.map((col, cIdx) => (
                    <td key={cIdx} className={`py-3.5 px-4 text-zinc-800 ${col.className || ''}`}>
                      {col.cell ? col.cell(row) : (row[col.accessorKey as keyof T] as React.ReactNode)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {pagination && pagination.totalPages > 1 && (
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 px-2 py-4 mt-2">
          <p className="text-xs text-zinc-500">
            Showing <span className="font-semibold text-zinc-700">{(pagination.currentPage - 1) * pagination.pageSize + 1}</span> to{' '}
            <span className="font-semibold text-zinc-700">
              {Math.min(pagination.currentPage * pagination.pageSize, pagination.totalItems)}
            </span>{' '}
            of <span className="font-semibold text-zinc-700">{pagination.totalItems}</span> users
          </p>

          <div className="flex items-center gap-1.5">
            <Button
              variant="outline"
              size="sm"
              disabled={pagination.currentPage <= 1}
              onClick={() => pagination.onPageChange(pagination.currentPage - 1)}
              leftIcon={<ChevronLeft className="w-4 h-4" />}
            >
              Previous
            </Button>
            <span className="text-xs text-zinc-600 px-2 font-medium">
              Page {pagination.currentPage} of {pagination.totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={pagination.currentPage >= pagination.totalPages}
              onClick={() => pagination.onPageChange(pagination.currentPage + 1)}
              rightIcon={<ChevronRight className="w-4 h-4" />}
            >
              Next
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

// Compositional Table primitives for custom flexible views
export const TableHeader: React.FC<React.HTMLAttributes<HTMLTableSectionElement>> = ({
  className = '',
  children,
  ...props
}) => (
  <thead className={`border-b border-zinc-200/80 bg-zinc-50/80 text-zinc-500 font-medium text-xs uppercase tracking-wider ${className}`} {...props}>
    {children}
  </thead>
);

export const TableBody: React.FC<React.HTMLAttributes<HTMLTableSectionElement>> = ({
  className = '',
  children,
  ...props
}) => (
  <tbody className={`divide-y divide-zinc-100 ${className}`} {...props}>
    {children}
  </tbody>
);

export const TableRow: React.FC<React.HTMLAttributes<HTMLTableRowElement>> = ({
  className = '',
  children,
  ...props
}) => (
  <tr className={`transition-colors duration-100 hover:bg-zinc-50/40 ${className}`} {...props}>
    {children}
  </tr>
);

export const TableHead: React.FC<React.ThHTMLAttributes<HTMLTableCellElement>> = ({
  className = '',
  children,
  ...props
}) => (
  <th className={`py-3 px-4 font-semibold text-zinc-600 text-left text-xs uppercase tracking-wider ${className}`} {...props}>
    {children}
  </th>
);

export const TableCell: React.FC<React.TdHTMLAttributes<HTMLTableCellElement>> = ({
  className = '',
  children,
  ...props
}) => (
  <td className={`py-3.5 px-4 text-xs text-zinc-800 align-middle ${className}`} {...props}>
    {children}
  </td>
);

