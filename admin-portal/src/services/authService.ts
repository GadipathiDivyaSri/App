import { getSupabaseClient, getSupabaseCredentials, DEMO_ADMIN } from '../lib/supabase';
import { AdminUser } from '../types';

export interface AuthResponse {
  success: boolean;
  adminUser?: AdminUser;
  error?: string;
}

export const authService = {
  /**
   * Signs in user with Supabase Auth and checks admin_users table for authorization.
   */
  async signIn(email: string, password: string): Promise<AuthResponse> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    // 1. Live Supabase Connection
    if (isConfigured && supabase) {
      try {
        const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
          email: email.trim(),
          password: password,
        });

        if (authError || !authData.user) {
          return {
            success: false,
            error: authError?.message || 'Invalid email or password credentials.',
          };
        }

        const userId = authData.user.id;

        // 2. Check admin_users table to verify this user is an active Administrator
        const { data: adminRecord, error: adminQueryError } = await supabase
          .from('admin_users')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .single();

        if (adminQueryError || !adminRecord) {
          // If not in admin_users, attempt lookup by authenticated email as well
          const { data: adminByEmail } = await supabase
            .from('admin_users')
            .select('*')
            .eq('email', authData.user.email)
            .eq('is_active', true)
            .single();

          if (!adminByEmail) {
            // User is authenticated in Supabase, but NOT an admin.
            // Sign out immediately and deny access.
            await supabase.auth.signOut();
            return {
              success: false,
              error: 'Access Denied: Your account does not have administrator privileges for the WrindhaOS Admin Portal.',
            };
          }

          const adminUser: AdminUser = {
            id: adminByEmail.id,
            user_id: adminByEmail.user_id || userId,
            name: adminByEmail.name || 'Wrindha Administrator',
            email: adminByEmail.email,
            role: adminByEmail.role || 'SUPER_ADMIN',
            is_active: adminByEmail.is_active,
            created_at: adminByEmail.created_at,
            updated_at: adminByEmail.updated_at || adminByEmail.created_at,
          };

          return { success: true, adminUser };
        }

        const adminUser: AdminUser = {
          id: adminRecord.id,
          user_id: adminRecord.user_id,
          name: adminRecord.name || 'Wrindha Administrator',
          email: adminRecord.email,
          role: adminRecord.role || 'SUPER_ADMIN',
          is_active: adminRecord.is_active,
          created_at: adminRecord.created_at,
          updated_at: adminRecord.updated_at || adminRecord.created_at,
        };

        return { success: true, adminUser };
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Authentication failed';
        return {
          success: false,
          error: message,
        };
      }
    }

    // 2. Standby / Local Fallback Authentication
    if (email.trim().toLowerCase() === DEMO_ADMIN.email.toLowerCase()) {
      if (password === 'admin123' || password.length >= 6) {
        localStorage.setItem('wrindha_demo_admin_auth', JSON.stringify(DEMO_ADMIN));
        return {
          success: true,
          adminUser: DEMO_ADMIN,
        };
      } else {
        return {
          success: false,
          error: 'Invalid password. Please enter the correct administrator password.',
        };
      }
    } else if (email.includes('user@') || email.includes('student@')) {
      // Simulate standard non-admin user trying to log in
      return {
        success: false,
        error: 'Access Denied: The account "' + email + '" is a standard application user and does not have administrator privileges.',
      };
    } else {
      return {
        success: false,
        error: 'Admin account not found. Please verify your email and password.',
      };
    }
  },

  /**
   * Checks current session and verifies admin role.
   */
  async getCurrentSessionAdmin(): Promise<AdminUser | null> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data } = await supabase.auth.getSession();
        if (!data.session?.user) return null;

        const userId = data.session.user.id;
        const { data: adminRecord } = await supabase
          .from('admin_users')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .single();

        if (!adminRecord) {
          // Check by email fallback
          const { data: adminByEmail } = await supabase
            .from('admin_users')
            .select('*')
            .eq('email', data.session.user.email)
            .eq('is_active', true)
            .single();

          if (!adminByEmail) return null;

          return {
            id: adminByEmail.id,
            user_id: adminByEmail.user_id || userId,
            name: adminByEmail.name || 'Wrindha Administrator',
            email: adminByEmail.email,
            role: adminByEmail.role || 'SUPER_ADMIN',
            is_active: adminByEmail.is_active,
            created_at: adminByEmail.created_at,
            updated_at: adminByEmail.updated_at || adminByEmail.created_at,
          };
        }

        return {
          id: adminRecord.id,
          user_id: adminRecord.user_id,
          name: adminRecord.name || 'Wrindha Administrator',
          email: adminRecord.email,
          role: adminRecord.role || 'SUPER_ADMIN',
          is_active: adminRecord.is_active,
          created_at: adminRecord.created_at,
          updated_at: adminRecord.updated_at || adminRecord.created_at,
        };
      } catch (err) {
        console.error('Error fetching admin session:', err);
        return null;
      }
    }

    // Demo fallback session
    const stored = localStorage.getItem('wrindha_demo_admin_auth');
    if (stored) {
      try {
        return JSON.parse(stored) as AdminUser;
      } catch {
        return null;
      }
    }

    return null;
  },

  /**
   * Signs out the current admin session.
   */
  async signOut(): Promise<void> {
    const supabase = getSupabaseClient();
    if (supabase) {
      try {
        await supabase.auth.signOut();
      } catch (err) {
        console.error('Sign out error:', err);
      }
    }
    localStorage.removeItem('wrindha_demo_admin_auth');
  },

  /**
   * Sends password reset email.
   */
  async resetPassword(email: string): Promise<{ success: boolean; message: string }> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
          redirectTo: `${window.location.origin}/admin/login`,
        });
        if (error) {
          return { success: false, message: error.message };
        }
        return { success: true, message: 'Password recovery email has been dispatched via Supabase.' };
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Failed to send recovery email.';
        return { success: false, message };
      }
    }

    // Demo simulation
    await new Promise((resolve) => setTimeout(resolve, 600));
    return {
      success: true,
      message: `Password reset instructions have been sent to ${email}. (In live mode, this connects via Supabase Auth email service).`,
    };
  },
};
