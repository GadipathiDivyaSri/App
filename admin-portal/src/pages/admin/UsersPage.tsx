import React, { useState, useEffect, useCallback, useTransition } from 'react';
import { Card } from '../../components/common/Card';
import { Badge } from '../../components/common/Badge';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { LoadingState } from '../../components/common/LoadingState';
import { EmptyState } from '../../components/common/EmptyState';
import { ErrorAlert } from '../../components/common/ErrorAlert';
import { Pagination } from '../../components/common/Pagination';
import { UserActionMenu } from '../../components/admin/UserActionMenu';
import { UserFilterModal, countActiveFilters } from '../../components/admin/UserFilterModal';
import { SuspendUserModal } from '../../components/admin/SuspendUserModal';
import { RestoreUserModal } from '../../components/admin/RestoreUserModal';
import { RequestDeletionModal } from '../../components/admin/RequestDeletionModal';
import { ToastAlert, ToastMessage } from '../../components/common/ToastAlert';
import { userService } from '../../services/userService';
import { useAuth } from '../../contexts/AuthContext';
import { WrindhaUser, UserFilters, SortField, SortOrder } from '../../types';
import { formatRelativeTime, formatDateLocale } from '../../utils/dateUtils';
import {
  Search,
  Filter,
  RefreshCw,
  Users,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Mail,
  ShieldCheck,
  ShieldAlert,
  Loader2,
  X,
} from 'lucide-react';

interface UsersPageProps {
  onNavigateToUser: (userId: string, tab?: 'overview' | 'activity') => void;
}

const DEFAULT_FILTERS: UserFilters = {
  status: 'all',
  plan: 'all',
  registrationDate: 'all',
  lastActive: 'all',
};

export const UsersPage: React.FC<UsersPageProps> = ({ onNavigateToUser }) => {
  const { admin } = useAuth();
  const [users, setUsers] = useState<WrindhaUser[]>([]);
  const [totalUsers, setTotalUsers] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);

  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [, startTransition] = useTransition();

  const [filters, setFilters] = useState<UserFilters>(DEFAULT_FILTERS);
  const [sortField, setSortField] = useState<SortField>('created_at');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');

  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modals state
  const [isFilterModalOpen, setIsFilterModalOpen] = useState(false);
  const [selectedUserForAction, setSelectedUserForAction] = useState<WrindhaUser | null>(null);
  const [isSuspendModalOpen, setIsSuspendModalOpen] = useState(false);
  const [isRestoreModalOpen, setIsRestoreModalOpen] = useState(false);
  const [isDeletionModalOpen, setIsDeletionModalOpen] = useState(false);

  // Notification toast
  const [toast, setToast] = useState<ToastMessage | null>(null);

  // Debounce search query
  useEffect(() => {
    setIsSearching(true);
    const handler = setTimeout(() => {
      startTransition(() => {
        setDebouncedSearch(searchQuery);
        setCurrentPage(1); // reset to page 1 on new search
        setIsSearching(false);
      });
    }, 300);

    return () => clearTimeout(handler);
  }, [searchQuery]);

  // Fetch users with full query parameters
  const loadUsers = useCallback(
    async (showSilentRefresh: boolean = false) => {
      if (showSilentRefresh) {
        setIsRefreshing(true);
      } else {
        setIsLoading(true);
      }
      setError(null);

      try {
        const res = await userService.getUsers({
          page: currentPage,
          pageSize,
          search: debouncedSearch,
          filters,
          sortField,
          sortOrder,
        });

        setUsers(res.data);
        setTotalUsers(res.total);
        setTotalPages(res.totalPages);
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to query user database.';
        setError(msg);
      } finally {
        setIsLoading(false);
        setIsRefreshing(false);
      }
    },
    [currentPage, pageSize, debouncedSearch, filters, sortField, sortOrder]
  );

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  // Handle column sort toggle
  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
    setCurrentPage(1);
  };

  // Render Sort Header Icon
  const renderSortIcon = (field: SortField) => {
    if (sortField !== field) {
      return <ArrowUpDown className="w-3.5 h-3.5 text-zinc-400 opacity-0 group-hover:opacity-100 transition-opacity" />;
    }
    return sortOrder === 'asc' ? (
      <ArrowUp className="w-3.5 h-3.5 text-zinc-900" />
    ) : (
      <ArrowDown className="w-3.5 h-3.5 text-zinc-900" />
    );
  };

  // Suspension Handler
  const handleConfirmSuspend = async (userId: string, reason: string) => {
    const res = await userService.suspendUser(
      userId,
      reason,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) {
      throw new Error(res.error || 'Failed to suspend user.');
    }
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'Account Suspended',
      message: 'The user account has been suspended and privileges revoked.',
    });
    loadUsers(true);
  };

  // Restore Handler
  const handleConfirmRestore = async (userId: string) => {
    const res = await userService.restoreUser(
      userId,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) {
      throw new Error(res.error || 'Failed to restore user.');
    }
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'Account Restored',
      message: 'The user account has been successfully reinstated to active status.',
    });
    loadUsers(true);
  };

  // Deletion Request Handler
  const handleConfirmDeletionRequest = async (userId: string, reason: string) => {
    const res = await userService.requestAccountDeletion(
      userId,
      reason,
      admin?.user_id || 'admin',
      admin?.email
    );
    if (!res.success) {
      throw new Error(res.error || 'Failed to create deletion request.');
    }
    setToast({
      id: `toast-${Date.now()}`,
      type: 'success',
      title: 'Deletion Request Registered',
      message: 'Account deletion request queued for compliance review in account_deletion_requests.',
    });
  };

  const activeFilterCount = countActiveFilters(filters);

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      <ToastAlert toast={toast} onDismiss={() => setToast(null)} />

      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-zinc-900">Users</h1>
          <p className="text-sm text-zinc-500 mt-1">
            Manage and monitor WrindhaOS accounts.
          </p>
        </div>

        {/* Global Action Tools */}
        <div className="flex items-center gap-2">
          <Button
            id="users-refresh-btn"
            variant="outline"
            size="sm"
            onClick={() => loadUsers(true)}
            isLoading={isRefreshing}
            leftIcon={<RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {/* Search & Filter Control Bar */}
      <Card className="p-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          {/* Debounced Search Box */}
          <div className="relative flex-1 max-w-lg">
            <Input
              id="users-search-input"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name, email, phone, or user ID..."
              leftIcon={<Search className="w-4 h-4 text-zinc-400" />}
              rightIcon={
                isSearching ? (
                  <Loader2 className="w-4 h-4 text-zinc-400 animate-spin" />
                ) : searchQuery ? (
                  <button
                    type="button"
                    onClick={() => setSearchQuery('')}
                    className="text-zinc-400 hover:text-zinc-700"
                    aria-label="Clear search"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                ) : undefined
              }
            />
          </div>

          {/* Filter & View Controls */}
          <div className="flex items-center gap-2 self-start md:self-auto">
            <button
              id="users-filter-btn"
              type="button"
              onClick={() => setIsFilterModalOpen(true)}
              className={`inline-flex items-center gap-2 px-3 py-2 text-xs font-medium rounded-xl border transition-colors ${
                activeFilterCount > 0
                  ? 'bg-zinc-900 border-zinc-900 text-white shadow-xs'
                  : 'bg-white border-zinc-200 text-zinc-700 hover:bg-zinc-50 hover:text-zinc-900'
              }`}
            >
              <Filter className="w-3.5 h-3.5" />
              <span>Filters</span>
              {activeFilterCount > 0 && (
                <span className="inline-flex items-center justify-center px-1.5 py-0.5 text-[10px] font-bold rounded-full bg-white text-zinc-900">
                  {activeFilterCount}
                </span>
              )}
            </button>

            {activeFilterCount > 0 && (
              <button
                type="button"
                onClick={() => {
                  setFilters(DEFAULT_FILTERS);
                  setCurrentPage(1);
                }}
                className="text-xs text-zinc-500 hover:text-zinc-900 underline px-1.5"
              >
                Clear filters
              </button>
            )}
          </div>
        </div>

        {/* Searching... Status Indicator */}
        {isSearching && (
          <div className="mt-2 text-xs text-zinc-400 flex items-center gap-1.5">
            <Loader2 className="w-3 h-3 animate-spin" />
            <span>Searching database...</span>
          </div>
        )}
      </Card>

      {/* Main Data Table */}
      <Card className="overflow-hidden">
        {error ? (
          <div className="p-6">
            <ErrorAlert
              title="Error loading users"
              message={error}
              onRetry={() => loadUsers(false)}
            />
          </div>
        ) : isLoading ? (
          <div className="p-12">
            <LoadingState message="Querying user directory..." />
          </div>
        ) : users.length === 0 ? (
          <div className="p-12">
            <EmptyState
              icon={<Users className="w-6 h-6" />}
              title="No users found"
              description={
                debouncedSearch || activeFilterCount > 0
                  ? 'No users match your current search criteria or active filters.'
                  : 'No users have registered on the platform yet.'
              }
              action={
                debouncedSearch || activeFilterCount > 0 ? (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      setSearchQuery('');
                      setFilters(DEFAULT_FILTERS);
                    }}
                  >
                    Reset Search & Filters
                  </Button>
                ) : undefined
              }
            />
          </div>
        ) : (
          <div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs divide-y divide-zinc-200">
                <thead className="bg-zinc-50 text-zinc-600 font-semibold uppercase tracking-wider text-[11px]">
                  <tr>
                    {/* User Column */}
                    <th
                      scope="col"
                      onClick={() => handleSort('name')}
                      className="py-3.5 px-4 cursor-pointer hover:bg-zinc-100/70 transition-colors group select-none"
                    >
                      <div className="flex items-center gap-1.5">
                        <span>User</span>
                        {renderSortIcon('name')}
                      </div>
                    </th>

                    {/* Email Column */}
                    <th scope="col" className="py-3.5 px-4 select-none">
                      Email
                    </th>

                    {/* Plan Column */}
                    <th scope="col" className="py-3.5 px-4 select-none">
                      Plan
                    </th>

                    {/* Account Status Column */}
                    <th
                      scope="col"
                      onClick={() => handleSort('status')}
                      className="py-3.5 px-4 cursor-pointer hover:bg-zinc-100/70 transition-colors group select-none"
                    >
                      <div className="flex items-center gap-1.5">
                        <span>Account Status</span>
                        {renderSortIcon('status')}
                      </div>
                    </th>

                    {/* Joined Column */}
                    <th
                      scope="col"
                      onClick={() => handleSort('created_at')}
                      className="py-3.5 px-4 cursor-pointer hover:bg-zinc-100/70 transition-colors group select-none"
                    >
                      <div className="flex items-center gap-1.5">
                        <span>Joined</span>
                        {renderSortIcon('created_at')}
                      </div>
                    </th>

                    {/* Last Active Column */}
                    <th
                      scope="col"
                      onClick={() => handleSort('last_active_at')}
                      className="py-3.5 px-4 cursor-pointer hover:bg-zinc-100/70 transition-colors group select-none"
                    >
                      <div className="flex items-center gap-1.5">
                        <span>Last Active</span>
                        {renderSortIcon('last_active_at')}
                      </div>
                    </th>

                    {/* Actions Column */}
                    <th scope="col" className="py-3.5 px-4 text-right select-none">
                      Actions
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-zinc-100 bg-white">
                  {users.map((user) => {
                    const isSuspended = user.status === 'suspended';
                    const isInactive = user.status === 'inactive';

                    return (
                      <tr
                        key={user.id}
                        id={`user-row-${user.id}`}
                        className="hover:bg-zinc-50/80 transition-colors group"
                      >
                        {/* User Column (Avatar, Name, ID) */}
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-3">
                            {user.avatar_url ? (
                              <img
                                src={user.avatar_url}
                                alt={user.name}
                                className="w-8 h-8 rounded-full object-cover border border-zinc-200 shrink-0"
                              />
                            ) : (
                              <div className="w-8 h-8 rounded-full bg-zinc-100 border border-zinc-200 text-zinc-700 font-bold text-xs flex items-center justify-center shrink-0">
                                {user.name.charAt(0).toUpperCase()}
                              </div>
                            )}
                            <div>
                              <button
                                type="button"
                                onClick={() => onNavigateToUser(user.id, 'overview')}
                                className="font-semibold text-zinc-900 hover:underline text-left block"
                              >
                                {user.name}
                              </button>
                              <span className="text-[10px] font-mono text-zinc-400 block">
                                {user.id}
                              </span>
                            </div>
                          </div>
                        </td>

                        {/* Email Column */}
                        <td className="py-3 px-4">
                          <div className="text-zinc-800 font-mono text-[11px] flex items-center gap-1.5">
                            <Mail className="w-3 h-3 text-zinc-400 shrink-0" />
                            <span>{user.email}</span>
                          </div>
                          {user.phone && (
                            <div className="text-zinc-400 text-[10px] mt-0.5">
                              {user.phone}
                            </div>
                          )}
                        </td>

                        {/* Plan Column */}
                        <td className="py-3 px-4">
                          {user.plan === 'Pro' ? (
                            <Badge variant="primary">Pro</Badge>
                          ) : user.plan === 'Free' ? (
                            <Badge variant="neutral">Free</Badge>
                          ) : (
                            <span className="text-zinc-400 italic text-[11px]">Not configured</span>
                          )}
                        </td>

                        {/* Status Column */}
                        <td className="py-3 px-4">
                          {isSuspended ? (
                            <Badge variant="danger" className="gap-1">
                              <ShieldAlert className="w-3 h-3" />
                              <span>Suspended</span>
                            </Badge>
                          ) : isInactive ? (
                            <Badge variant="neutral">Inactive</Badge>
                          ) : (
                            <Badge variant="success" className="gap-1">
                              <ShieldCheck className="w-3 h-3" />
                              <span>Active</span>
                            </Badge>
                          )}
                        </td>

                        {/* Joined Column */}
                        <td className="py-3 px-4 text-zinc-600 whitespace-nowrap">
                          {formatDateLocale(user.created_at)}
                        </td>

                        {/* Last Active Column */}
                        <td className="py-3 px-4 text-zinc-600 whitespace-nowrap font-medium">
                          {formatRelativeTime(user.last_active_at)}
                        </td>

                        {/* Actions Menu */}
                        <td className="py-3 px-4 text-right whitespace-nowrap">
                          <UserActionMenu
                            user={user}
                            onViewProfile={(id) => onNavigateToUser(id, 'overview')}
                            onViewActivity={(id) => onNavigateToUser(id, 'activity')}
                            onOpenSuspendModal={(u) => {
                              setSelectedUserForAction(u);
                              setIsSuspendModalOpen(true);
                            }}
                            onOpenRestoreModal={(u) => {
                              setSelectedUserForAction(u);
                              setIsRestoreModalOpen(true);
                            }}
                            onOpenDeletionModal={(u) => {
                              setSelectedUserForAction(u);
                              setIsDeletionModalOpen(true);
                            }}
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Pagination Controls */}
            <div className="border-t border-zinc-200 px-4">
              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                totalItems={totalUsers}
                pageSize={pageSize}
                onPageChange={(page) => setCurrentPage(page)}
                onPageSizeChange={(newSize) => {
                  setPageSize(newSize);
                  setCurrentPage(1);
                }}
                pageSizeOptions={[20, 50, 100]}
              />
            </div>
          </div>
        )}
      </Card>

      {/* Filter Modal */}
      <UserFilterModal
        isOpen={isFilterModalOpen}
        onClose={() => setIsFilterModalOpen(false)}
        filters={filters}
        onApplyFilters={(newFilters) => {
          setFilters(newFilters);
          setCurrentPage(1);
        }}
        onResetFilters={() => {
          setFilters(DEFAULT_FILTERS);
          setCurrentPage(1);
        }}
      />

      {/* Suspend User Modal */}
      <SuspendUserModal
        isOpen={isSuspendModalOpen}
        onClose={() => setIsSuspendModalOpen(false)}
        user={selectedUserForAction}
        onConfirmSuspend={handleConfirmSuspend}
      />

      {/* Restore User Modal */}
      <RestoreUserModal
        isOpen={isRestoreModalOpen}
        onClose={() => setIsRestoreModalOpen(false)}
        user={selectedUserForAction}
        onConfirmRestore={handleConfirmRestore}
      />

      {/* Request Deletion Modal */}
      <RequestDeletionModal
        isOpen={isDeletionModalOpen}
        onClose={() => setIsDeletionModalOpen(false)}
        user={selectedUserForAction}
        onConfirmRequest={handleConfirmDeletionRequest}
      />
    </div>
  );
};
