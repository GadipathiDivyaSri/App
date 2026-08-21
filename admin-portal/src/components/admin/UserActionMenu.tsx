import React, { useState, useRef, useEffect } from 'react';
import { MoreHorizontal, Eye, Activity, ShieldAlert, ShieldCheck, UserX } from 'lucide-react';
import { WrindhaUser } from '../../types';

interface UserActionMenuProps {
  user: WrindhaUser;
  onViewProfile: (userId: string) => void;
  onViewActivity: (userId: string) => void;
  onOpenSuspendModal: (user: WrindhaUser) => void;
  onOpenRestoreModal: (user: WrindhaUser) => void;
  onOpenDeletionModal: (user: WrindhaUser) => void;
}

export const UserActionMenu: React.FC<UserActionMenuProps> = ({
  user,
  onViewProfile,
  onViewActivity,
  onOpenSuspendModal,
  onOpenRestoreModal,
  onOpenDeletionModal,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const isSuspended = user.status === 'suspended';

  return (
    <div className="relative inline-block text-left" ref={menuRef}>
      <button
        id={`user-action-btn-${user.id}`}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="p-1.5 rounded-lg border border-zinc-200 text-zinc-600 bg-white hover:bg-zinc-50 hover:text-zinc-900 transition-colors focus:outline-hidden focus:ring-2 focus:ring-zinc-900"
        aria-expanded={isOpen}
        aria-label="User actions"
      >
        <MoreHorizontal className="w-4 h-4" />
      </button>

      {isOpen && (
        <div className="origin-top-right absolute right-0 mt-1.5 w-48 rounded-xl shadow-lg bg-white border border-zinc-200 ring-1 ring-black/5 divide-y divide-zinc-100 z-30 focus:outline-hidden animate-in fade-in-50 zoom-in-95">
          {/* Navigation group */}
          <div className="py-1">
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onViewProfile(user.id);
              }}
              className="w-full text-left px-3.5 py-2 text-xs text-zinc-700 hover:bg-zinc-50 hover:text-zinc-900 flex items-center gap-2 transition-colors font-medium"
            >
              <Eye className="w-3.5 h-3.5 text-zinc-500" />
              <span>View Profile</span>
            </button>
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onViewActivity(user.id);
              }}
              className="w-full text-left px-3.5 py-2 text-xs text-zinc-700 hover:bg-zinc-50 hover:text-zinc-900 flex items-center gap-2 transition-colors font-medium"
            >
              <Activity className="w-3.5 h-3.5 text-zinc-500" />
              <span>View Activity</span>
            </button>
          </div>

          {/* Admin Management Group */}
          <div className="py-1">
            {isSuspended ? (
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  onOpenRestoreModal(user);
                }}
                className="w-full text-left px-3.5 py-2 text-xs text-emerald-700 hover:bg-emerald-50 flex items-center gap-2 transition-colors font-medium"
              >
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                <span>Restore Account</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  onOpenSuspendModal(user);
                }}
                className="w-full text-left px-3.5 py-2 text-xs text-rose-700 hover:bg-rose-50 flex items-center gap-2 transition-colors font-medium"
              >
                <ShieldAlert className="w-3.5 h-3.5 text-rose-600" />
                <span>Suspend Account</span>
              </button>
            )}

            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onOpenDeletionModal(user);
              }}
              className="w-full text-left px-3.5 py-2 text-xs text-amber-700 hover:bg-amber-50 flex items-center gap-2 transition-colors font-medium"
            >
              <UserX className="w-3.5 h-3.5 text-amber-600" />
              <span>Request Deletion</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
