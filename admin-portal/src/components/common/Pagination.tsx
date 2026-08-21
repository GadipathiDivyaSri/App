import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  pageSizeOptions?: number[];
  itemLabel?: string;
  className?: string;
}

export const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  totalItems,
  pageSize,
  onPageChange,
  onPageSizeChange,
  pageSizeOptions = [20, 50, 100],
  itemLabel = 'users',
  className = '',
}) => {
  if (totalItems === 0) return null;

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  // Generate page numbers with ellipsis for large page ranges
  const getPageNumbers = () => {
    const pages: (number | string)[] = [];
    const delta = 1; // Number of pages around current page

    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      pages.push(1);

      const leftBound = Math.max(2, currentPage - delta);
      const rightBound = Math.min(totalPages - 1, currentPage + delta);

      if (leftBound > 2) {
        pages.push('...');
      }

      for (let i = leftBound; i <= rightBound; i++) {
        pages.push(i);
      }

      if (rightBound < totalPages - 1) {
        pages.push('...');
      }

      pages.push(totalPages);
    }
    return pages;
  };

  return (
    <div
      id="admin-pagination-container"
      className={`flex flex-col sm:flex-row items-center justify-between gap-4 py-4 px-2 select-none ${className}`}
    >
      {/* Item count text & Page size select */}
      <div className="flex flex-wrap items-center gap-3 text-xs text-zinc-500">
        <span>
          Showing <span className="font-medium text-zinc-800">{startItem}</span>–
          <span className="font-medium text-zinc-800">{endItem}</span> of{' '}
          <span className="font-medium text-zinc-800">{totalItems.toLocaleString()}</span> {itemLabel}
        </span>

        {onPageSizeChange && (
          <div className="flex items-center gap-1.5 pl-3 border-l border-zinc-200">
            <span className="text-zinc-400">Rows:</span>
            <select
              id="pagination-pagesize-select"
              value={pageSize}
              onChange={(e) => onPageSizeChange(Number(e.target.value))}
              className="bg-white border border-zinc-200 text-zinc-700 text-xs rounded-md px-2 py-1 focus:outline-hidden focus:ring-2 focus:ring-zinc-900 focus:border-zinc-900"
            >
              {pageSizeOptions.map((opt) => (
                <option key={opt} value={opt}>
                  {opt} / page
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Navigation Buttons & Page Pills */}
      <div className="flex items-center gap-1">
        {/* Previous Button */}
        <button
          id="pagination-prev-btn"
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          className="inline-flex items-center justify-center p-1.5 rounded-lg border border-zinc-200 text-zinc-600 bg-white hover:bg-zinc-50 hover:text-zinc-900 disabled:opacity-40 disabled:pointer-events-none transition-colors"
          aria-label="Previous Page"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>

        {/* Page numbers */}
        <div className="flex items-center gap-1">
          {getPageNumbers().map((p, idx) => {
            if (p === '...') {
              return (
                <span key={`ellipsis-${idx}`} className="px-2 py-1 text-xs text-zinc-400">
                  ...
                </span>
              );
            }

            const pageNum = p as number;
            const isCurrent = pageNum === currentPage;

            return (
              <button
                key={pageNum}
                type="button"
                onClick={() => onPageChange(pageNum)}
                aria-current={isCurrent ? 'page' : undefined}
                className={`min-w-[32px] h-8 px-2 text-xs font-medium rounded-lg transition-colors ${
                  isCurrent
                    ? 'bg-zinc-900 text-white font-semibold shadow-xs'
                    : 'bg-white border border-zinc-200 text-zinc-700 hover:bg-zinc-50 hover:text-zinc-900'
                }`}
              >
                {pageNum}
              </button>
            );
          })}
        </div>

        {/* Next Button */}
        <button
          id="pagination-next-btn"
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          className="inline-flex items-center justify-center p-1.5 rounded-lg border border-zinc-200 text-zinc-600 bg-white hover:bg-zinc-50 hover:text-zinc-900 disabled:opacity-40 disabled:pointer-events-none transition-colors"
          aria-label="Next Page"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
