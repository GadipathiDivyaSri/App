import React, { createContext, useContext, useEffect, useState } from 'react';
import { AdminUser } from '../types';
import { authService } from '../services/authService';
import { getSupabaseClient, getSupabaseCredentials } from '../lib/supabase';

interface AuthContextType {
  adminUser: AdminUser | null;
  isLoading: boolean;
  error: string | null;
  isConfigured: boolean;
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<void>;
  clearError: () => void;
  refreshAdmin: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [isConfigured, setIsConfigured] = useState<boolean>(false);

  const checkSession = async () => {
    setIsLoading(true);
    try {
      const creds = getSupabaseCredentials();
      setIsConfigured(creds.isConfigured);

      const admin = await authService.getCurrentSessionAdmin();
      setAdminUser(admin);
    } catch (err) {
      console.error('Session validation error:', err);
      setAdminUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    checkSession();

    // Listen to Supabase Auth state changes if live Supabase is present
    const supabase = getSupabaseClient();
    if (supabase) {
      const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event) => {
        if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED' || event === 'USER_UPDATED') {
          const admin = await authService.getCurrentSessionAdmin();
          setAdminUser(admin);
        } else if (event === 'SIGNED_OUT') {
          setAdminUser(null);
        }
      });

      return () => {
        subscription.unsubscribe();
      };
    }
  }, []);

  const signIn = async (email: string, password: string) => {
    setError(null);
    setIsLoading(true);
    try {
      const response = await authService.signIn(email, password);
      if (response.success && response.adminUser) {
        setAdminUser(response.adminUser);
        setIsLoading(false);
        return { success: true };
      } else {
        const errorMsg = response.error || 'Authentication failed.';
        setError(errorMsg);
        setIsLoading(false);
        return { success: false, error: errorMsg };
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : 'An unexpected error occurred during sign in.';
      setError(errorMsg);
      setIsLoading(false);
      return { success: false, error: errorMsg };
    }
  };

  const signOut = async () => {
    setIsLoading(true);
    try {
      await authService.signOut();
      setAdminUser(null);
    } catch (err) {
      console.error('Sign out error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const clearError = () => setError(null);

  const refreshAdmin = async () => {
    await checkSession();
  };

  return (
    <AuthContext.Provider
      value={{
        adminUser,
        isLoading,
        error,
        isConfigured,
        signIn,
        signOut,
        clearError,
        refreshAdmin,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
