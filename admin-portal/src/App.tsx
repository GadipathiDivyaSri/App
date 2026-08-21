import React, { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { LoginPage } from './pages/admin/LoginPage';
import { DashboardPage } from './pages/admin/DashboardPage';
import { UsersPage } from './pages/admin/UsersPage';
import { UserProfilePage } from './pages/admin/UserProfilePage';
import { SubscriptionsPage } from './pages/admin/SubscriptionsPage';
import { PlansPage } from './pages/admin/PlansPage';
import { PlanEditorPage } from './pages/admin/PlanEditorPage';
import { SubscriptionDetailPage } from './pages/admin/SubscriptionDetailPage';
import { CareerContentPage } from './pages/admin/CareerContentPage';
import { NotificationsPage } from './pages/admin/NotificationsPage';
import { CreateNotificationPage } from './pages/admin/CreateNotificationPage';
import { AppSettingsPage } from './pages/admin/AppSettingsPage';
import { WebsitePage } from './pages/admin/WebsitePage';
import { LegalPage } from './pages/admin/LegalPage';
import { AnalyticsPage } from './pages/admin/AnalyticsPage';
import { PublicLegalPage } from './pages/public/PublicLegalPage';
import { AdminLayout } from './layouts/AdminLayout';
import { LoadingState } from './components/common/LoadingState';

const PUBLIC_LEGAL_SLUGS: Record<string, string> = {
  '/privacy-policy': 'privacy-policy',
  '/terms': 'terms',
  '/terms-and-conditions': 'terms',
  '/refund-policy': 'refund-policy',
  '/account-deletion': 'account-deletion',
  '/contact': 'contact',
  '/cookies': 'cookies',
  '/copyright': 'copyright',
};

function AppContent() {
  const { adminUser, isLoading } = useAuth();
  const [currentPath, setCurrentPath] = useState<string>(() => {
    const p = window.location.pathname;
    return (p === '/' || p === '/admin' || p === '/admin/') ? '/admin/dashboard' : p;
  });
  const [userProfileTab, setUserProfileTab] = useState<'overview' | 'activity' | 'account' | 'audit'>('overview');

  // Sync with browser navigation
  useEffect(() => {
    const handlePopState = () => {
      const p = window.location.pathname;
      setCurrentPath((p === '/' || p === '/admin' || p === '/admin/') ? '/admin/dashboard' : p);
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const navigate = (path: string, tab?: 'overview' | 'activity' | 'account' | 'audit') => {
    window.history.pushState({}, '', path);
    setCurrentPath(path);
    if (tab) {
      setUserProfileTab(tab);
    }
    window.scrollTo(0, 0);
  };

  // Check if current path is a public legal page
  const matchedPublicSlug = PUBLIC_LEGAL_SLUGS[currentPath.toLowerCase()];
  if (matchedPublicSlug) {
    return (
      <PublicLegalPage
        slug={matchedPublicSlug}
        onNavigate={(path) => navigate(path)}
        onBackToAdmin={adminUser ? () => navigate('/admin/legal') : () => navigate('/admin/login')}
      />
    );
  }

  // 1. App loading state while checking Supabase auth session & admin privileges
  if (isLoading) {
    return (
      <div className="min-h-screen bg-zinc-50 flex flex-col items-center justify-center text-zinc-900">
        <div className="w-10 h-10 rounded-xl bg-zinc-900 text-white flex items-center justify-center font-black text-lg mb-3 shadow-md">
          W
        </div>
        <div className="text-xs font-bold tracking-widest text-zinc-500 uppercase mb-2">
          WRINDHAOS ADMIN
        </div>
        <LoadingState message="Verifying administrative privileges..." className="text-zinc-500" />
      </div>
    );
  }

  // 2. Unauthenticated: Show Admin Login
  if (!adminUser) {
    return <LoginPage onSuccess={() => navigate('/admin/dashboard')} />;
  }

  // 3. Authenticated Admin: Route to Requested View inside AdminLayout
  const renderCurrentPage = () => {
    if (currentPath === '/admin/dashboard' || currentPath === '/') {
      return (
        <DashboardPage
          onNavigateToUsers={() => navigate('/admin/users')}
          onNavigateToUserProfile={(id) => navigate(`/admin/users/${id}`, 'overview')}
          onNavigateToAnalytics={() => navigate('/admin/analytics')}
        />
      );
    }

    if (currentPath === '/admin/users') {
      return (
        <UsersPage
          onNavigateToUser={(id, tab) => navigate(`/admin/users/${id}`, tab || 'overview')}
        />
      );
    }

    if (currentPath.startsWith('/admin/users/')) {
      const userId = currentPath.replace('/admin/users/', '').split('?')[0];
      return (
        <UserProfilePage
          userId={userId}
          initialTab={userProfileTab}
          onBack={() => navigate('/admin/users')}
          onNavigate={(path) => navigate(path)}
        />
      );
    }

    // Subscriptions Plans Editor: /admin/subscriptions/plans/:slug
    if (currentPath.startsWith('/admin/subscriptions/plans/')) {
      const planSlug = currentPath.replace('/admin/subscriptions/plans/', '').split('?')[0];
      return <PlanEditorPage slug={planSlug} onNavigate={(path) => navigate(path)} />;
    }

    // Subscriptions Plans List: /admin/subscriptions/plans
    if (currentPath === '/admin/subscriptions/plans') {
      return <PlansPage onNavigate={(path) => navigate(path)} />;
    }

    // Subscription Detail: /admin/subscriptions/:id
    if (currentPath.startsWith('/admin/subscriptions/')) {
      const subId = currentPath.replace('/admin/subscriptions/', '').split('?')[0];
      return <SubscriptionDetailPage id={subId} onNavigate={(path) => navigate(path)} />;
    }

    // Subscriptions Dashboard: /admin/subscriptions
    if (currentPath === '/admin/subscriptions') {
      return <SubscriptionsPage onNavigate={(path) => navigate(path)} />;
    }

    // Phase 7: Product Analytics (/admin/analytics)
    if (currentPath.startsWith('/admin/analytics')) {
      return <AnalyticsPage onNavigate={(path) => navigate(path)} />;
    }

    // App Content: Career (/admin/content/career)
    if (currentPath.startsWith('/admin/content/career')) {
      return <CareerContentPage onNavigate={(path) => navigate(path)} />;
    }

    // Notifications: Create (/admin/notifications/create)
    if (currentPath === '/admin/notifications/create') {
      return (
        <CreateNotificationPage
          onBack={() => navigate('/admin/notifications')}
          onSuccess={() => navigate('/admin/notifications')}
        />
      );
    }

    // Notifications Dashboard & List (/admin/notifications)
    if (currentPath.startsWith('/admin/notifications')) {
      return (
        <NotificationsPage
          onCreateNotification={() => navigate('/admin/notifications/create')}
        />
      );
    }

    // Website Settings (/admin/website)
    if (currentPath.startsWith('/admin/website')) {
      return <WebsitePage onNavigate={(path) => navigate(path)} />;
    }

    // Legal Documents Management (/admin/legal)
    if (currentPath.startsWith('/admin/legal')) {
      return (
        <LegalPage
          onNavigate={(path) => navigate(path)}
          onPreviewPublicDocument={(slug) => navigate(`/${slug}`)}
        />
      );
    }

    // App Settings (/admin/settings)
    if (currentPath.startsWith('/admin/settings')) {
      return <AppSettingsPage />;
    }

    // Default fallback to dashboard
    return (
      <DashboardPage
        onNavigateToUsers={() => navigate('/admin/users')}
        onNavigateToUserProfile={(id) => navigate(`/admin/users/${id}`, 'overview')}
        onNavigateToAnalytics={() => navigate('/admin/analytics')}
      />
    );
  };



  return (
    <AdminLayout activePath={currentPath} onNavigate={(path) => navigate(path)}>
      {renderCurrentPage()}
    </AdminLayout>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

