import React, { useState } from 'react';
import {
  LayoutDashboard,
  Users,
  CreditCard,
  BarChart3,
  LogOut,
  Menu,
  X,
  ShieldCheck,
  ChevronRight,
  Compass,
  Bell,
  Settings,
  Globe,
  FileCheck,
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { Badge } from '../components/common/Badge';

interface AdminLayoutProps {
  children: React.ReactNode;
  activePath: string;
  onNavigate: (path: string) => void;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({
  children,
  activePath,
  onNavigate,
}) => {
  const { adminUser, signOut } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const coreNavItems = [
    {
      name: 'Dashboard',
      path: '/admin/dashboard',
      icon: <LayoutDashboard className="w-4 h-4" />,
    },
    {
      name: 'Users',
      path: '/admin/users',
      icon: <Users className="w-4 h-4" />,
    },
    {
      name: 'Subscriptions',
      path: '/admin/subscriptions',
      icon: <CreditCard className="w-4 h-4" />,
    },
    {
      name: 'Analytics',
      path: '/admin/analytics',
      icon: <BarChart3 className="w-4 h-4" />,
    },
  ];

  const contentNavItems = [
    {
      name: 'Career Roadmaps',
      path: '/admin/content/career',
      icon: <Compass className="w-4 h-4" />,
    },
  ];

  const systemNavItems = [
    {
      name: 'Notifications',
      path: '/admin/notifications',
      icon: <Bell className="w-4 h-4" />,
    },
    {
      name: 'Website',
      path: '/admin/website',
      icon: <Globe className="w-4 h-4" />,
    },
    {
      name: 'Legal Docs',
      path: '/admin/legal',
      icon: <FileCheck className="w-4 h-4" />,
    },
    {
      name: 'Settings',
      path: '/admin/settings',
      icon: <Settings className="w-4 h-4" />,
    },
  ];


  const handleNavClick = (path: string) => {
    onNavigate(path);
    setMobileMenuOpen(false);
  };


  const renderSidebarContent = () => (
    <div className="flex flex-col h-full bg-zinc-900 text-zinc-300 border-r border-zinc-800">
      {/* Brand Header */}
      <div className="p-6 border-b border-zinc-800/80">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-white text-zinc-900 flex items-center justify-center font-black text-sm tracking-tighter shadow-xs">
            W
          </div>
          <div>
            <div className="text-sm font-bold tracking-wider text-white">WRINDHAOS</div>
            <div className="text-[10px] font-semibold tracking-widest text-zinc-400 uppercase flex items-center gap-1 mt-0.5">
              <span>ADMIN</span>
              <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500" />
            </div>
          </div>
        </div>
      </div>

      {/* Navigation List */}
      <div className="flex-1 px-3 py-6 space-y-1.5 overflow-y-auto">
        <div className="px-3 pb-2 text-[10px] font-bold uppercase tracking-wider text-zinc-500">
          Core Operations
        </div>
        {coreNavItems.map((item) => {
          const isActive =
            activePath === item.path ||
            (item.path === '/admin/users' && activePath.startsWith('/admin/users')) ||
            (item.path === '/admin/subscriptions' && activePath.startsWith('/admin/subscriptions'));

          return (
            <button
              key={item.path}
              onClick={() => handleNavClick(item.path)}
              className={`w-full flex items-center justify-between px-3.5 py-2 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-zinc-800 text-white shadow-xs border border-zinc-700/60 font-semibold'
                  : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className={isActive ? 'text-white' : 'text-zinc-400'}>{item.icon}</span>
                <span>{item.name}</span>
              </div>
              {isActive && <ChevronRight className="w-3.5 h-3.5 text-zinc-400" />}
            </button>
          );
        })}

        {/* Section: APP CONTENT */}
        <div className="pt-5 px-3 pb-2 text-[10px] font-bold uppercase tracking-wider text-zinc-500">
          App Content
        </div>
        {contentNavItems.map((item) => {
          const isActive =
            activePath === item.path ||
            (item.path === '/admin/content/career' && activePath.startsWith('/admin/content/career'));

          return (
            <button
              key={item.path}
              onClick={() => handleNavClick(item.path)}
              className={`w-full flex items-center justify-between px-3.5 py-2 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-zinc-800 text-white shadow-xs border border-zinc-700/60 font-semibold'
                  : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className={isActive ? 'text-white' : 'text-zinc-400'}>{item.icon}</span>
                <span>{item.name}</span>
              </div>
              {isActive && <ChevronRight className="w-3.5 h-3.5 text-zinc-400" />}
            </button>
          );
        })}

        {/* Section: SYSTEM & OPERATIONS */}
        <div className="pt-5 px-3 pb-2 text-[10px] font-bold uppercase tracking-wider text-zinc-500">
          Operations & Settings
        </div>
        {systemNavItems.map((item) => {
          const isActive =
            activePath === item.path ||
            (item.path === '/admin/notifications' && activePath.startsWith('/admin/notifications')) ||
            (item.path === '/admin/website' && activePath.startsWith('/admin/website')) ||
            (item.path === '/admin/legal' && activePath.startsWith('/admin/legal')) ||
            (item.path === '/admin/settings' && activePath.startsWith('/admin/settings'));

          return (
            <button
              key={item.path}
              onClick={() => handleNavClick(item.path)}
              className={`w-full flex items-center justify-between px-3.5 py-2 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-zinc-800 text-white shadow-xs border border-zinc-700/60 font-semibold'
                  : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className={isActive ? 'text-white' : 'text-zinc-400'}>{item.icon}</span>
                <span>{item.name}</span>
              </div>
              {isActive && <ChevronRight className="w-3.5 h-3.5 text-zinc-400" />}
            </button>
          );
        })}
      </div>

      {/* Admin Profile & Logout at Bottom */}
      <div className="p-4 border-t border-zinc-800 bg-zinc-950/40">
        <div className="flex items-center gap-3 mb-3 px-1">
          <div className="w-8 h-8 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center text-xs font-bold text-white uppercase shrink-0">
            {adminUser?.name ? adminUser.name.charAt(0) : 'A'}
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <p className="text-xs font-semibold text-white truncate">{adminUser?.name || 'Administrator'}</p>
            </div>
            <p className="text-[11px] text-zinc-400 truncate">{adminUser?.email}</p>
          </div>
        </div>

        <div className="flex items-center justify-between gap-2 pt-1">
          <Badge variant="purple" size="sm" className="text-[10px] py-0.5 px-2 bg-indigo-950/70 border-indigo-800/60 text-indigo-300">
            <ShieldCheck className="w-3 h-3 mr-1 inline" />
            SUPER_ADMIN
          </Badge>

          <button
            onClick={() => signOut()}
            title="Sign out of Admin Portal"
            className="inline-flex items-center gap-1.5 text-xs text-zinc-400 hover:text-rose-400 hover:bg-zinc-800/60 px-2 py-1 rounded-md transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Logout</span>
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-zinc-50 flex flex-col md:flex-row text-zinc-900 font-sans antialiased">
      {/* Desktop Sidebar */}
      <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 z-30">
        {renderSidebarContent()}
      </aside>

      {/* Mobile Top Navigation Bar */}
      <div className="md:hidden flex items-center justify-between px-4 py-3 bg-zinc-900 text-white border-b border-zinc-800 sticky top-0 z-40">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded bg-white text-zinc-900 flex items-center justify-center font-bold text-xs">
            W
          </div>
          <div>
            <div className="text-xs font-bold tracking-wider leading-none">WRINDHAOS</div>
            <div className="text-[9px] font-semibold tracking-widest text-zinc-400 uppercase mt-0.5">
              ADMIN
            </div>
          </div>
        </div>

        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="p-1.5 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800 focus:outline-none"
        >
          {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {/* Mobile Drawer Overlay */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed inset-0 z-50 flex">
          <div
            className="fixed inset-0 bg-zinc-900/70 backdrop-blur-xs transition-opacity"
            onClick={() => setMobileMenuOpen(false)}
          />
          <div className="relative flex-1 flex flex-col max-w-xs w-full bg-zinc-900 z-50">
            {renderSidebarContent()}
          </div>
        </div>
      )}

      {/* Main Content Area */}
      <main className="flex-1 md:pl-64 flex flex-col min-h-screen">
        {/* Top Header Bar */}
        <header className="h-14 border-b border-zinc-200/80 bg-white/80 backdrop-blur-xs px-4 sm:px-8 flex items-center justify-between sticky top-0 z-20">
          <div className="flex items-center gap-2 text-xs font-medium text-zinc-500">
            <span className="text-zinc-400">WrindhaOS</span>
            <span>/</span>
            <span className="text-zinc-900 font-semibold capitalize">
              {activePath.includes('/admin/users/')
                ? 'User Profile'
                : activePath.replace('/admin/', '') || 'Dashboard'}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-full bg-zinc-900 text-white flex items-center justify-center text-xs font-bold shadow-xs">
                {adminUser?.name ? adminUser.name.charAt(0) : 'A'}
              </div>
              <div className="hidden sm:block text-left">
                <p className="text-xs font-semibold text-zinc-900 leading-none">
                  {adminUser?.name || 'Administrator'}
                </p>
                <p className="text-[10px] text-zinc-500 truncate max-w-[150px] mt-0.5">
                  {adminUser?.email}
                </p>
              </div>
            </div>
          </div>
        </header>

        {/* Dynamic Page Container */}
        <div className="flex-1 p-4 sm:p-8 max-w-7xl w-full mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
};
