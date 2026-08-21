import {
  AppSettings,
  GeneralSettings,
  AppVersionSettings,
  SupportSettings,
  LegalSettings,
} from '../types';
import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoAppSettings,
  saveDemoAppSettings,
} from '../lib/supabase';
import { auditService } from './auditService';
import { INITIAL_APP_SETTINGS } from '../lib/defaultSettingsData';

export const settingsService = {
  /**
   * Retrieves the current app settings.
   */
  async getSettings(): Promise<AppSettings> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('app_settings')
          .select('*')
          .eq('id', 'global_settings')
          .maybeSingle();

        if (error) {
          console.error('Error fetching app settings from Supabase:', error);
        } else if (data) {
          return {
            id: data.id,
            general: data.general || INITIAL_APP_SETTINGS.general,
            app_version: data.app_version || INITIAL_APP_SETTINGS.app_version,
            support: data.support || INITIAL_APP_SETTINGS.support,
            legal: data.legal || INITIAL_APP_SETTINGS.legal,
            updated_at: data.updated_at || new Date().toISOString(),
            updated_by: data.updated_by,
          };
        }
      } catch (err) {
        console.error('Failed to read app settings from Supabase, falling back:', err);
      }
    }

    return getDemoAppSettings();
  },

  /**
   * Updates general settings.
   */
  async updateGeneralSettings(
    general: GeneralSettings,
    adminId: string,
    adminEmail: string
  ): Promise<AppSettings> {
    const current = await this.getSettings();
    const updated: AppSettings = {
      ...current,
      general,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'GENERAL_SETTINGS_CHANGED',
      undefined,
      adminId,
      { general },
      adminEmail
    );

    return updated;
  },

  /**
   * Updates app version, force update, and maintenance mode settings.
   */
  async updateAppVersionSettings(
    appVersion: AppVersionSettings,
    adminId: string,
    adminEmail: string
  ): Promise<AppSettings> {
    const current = await this.getSettings();
    const prevVersion = current.app_version;

    const updated: AppSettings = {
      ...current,
      app_version: appVersion,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    // Audit Log for Maintenance Mode change
    if (prevVersion.maintenance_mode !== appVersion.maintenance_mode) {
      await auditService.logAction(
        appVersion.maintenance_mode ? 'MAINTENANCE_ENABLED' : 'MAINTENANCE_DISABLED',
        undefined,
        adminId,
        {
          maintenance_message: appVersion.maintenance_message,
          applied_at: new Date().toISOString(),
        },
        adminEmail
      );
    }

    // Audit Log for Force Update change
    if (prevVersion.force_update !== appVersion.force_update) {
      await auditService.logAction(
        'FORCE_UPDATE_CHANGED',
        undefined,
        adminId,
        {
          force_update: appVersion.force_update,
          minimum_supported_version: appVersion.minimum_supported_version,
        },
        adminEmail
      );
    }

    // Audit Log for App Version change
    if (
      prevVersion.latest_version !== appVersion.latest_version ||
      prevVersion.minimum_supported_version !== appVersion.minimum_supported_version
    ) {
      await auditService.logAction(
        'APP_VERSION_CHANGED',
        undefined,
        adminId,
        {
          from_latest: prevVersion.latest_version,
          to_latest: appVersion.latest_version,
          from_min: prevVersion.minimum_supported_version,
          to_min: appVersion.minimum_supported_version,
        },
        adminEmail
      );
    }

    return updated;
  },

  /**
   * Updates support contact and documentation links.
   */
  async updateSupportSettings(
    support: SupportSettings,
    adminId: string,
    adminEmail: string
  ): Promise<AppSettings> {
    const current = await this.getSettings();
    const updated: AppSettings = {
      ...current,
      support,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'SUPPORT_SETTINGS_CHANGED',
      undefined,
      adminId,
      { support },
      adminEmail
    );

    return updated;
  },

  /**
   * Updates legal and compliance URLs.
   */
  async updateLegalSettings(
    legal: LegalSettings,
    adminId: string,
    adminEmail: string
  ): Promise<AppSettings> {
    const current = await this.getSettings();
    const updated: AppSettings = {
      ...current,
      legal,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'LEGAL_SETTINGS_CHANGED',
      undefined,
      adminId,
      { legal },
      adminEmail
    );

    return updated;
  },

  /**
   * Internal persistence helper.
   */
  async persistSettings(settings: AppSettings): Promise<void> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('app_settings').upsert({
          id: 'global_settings',
          general: settings.general,
          app_version: settings.app_version,
          support: settings.support,
          legal: settings.legal,
          updated_at: settings.updated_at,
          updated_by: settings.updated_by || null,
        });
        if (error) throw error;
      } catch (err) {
        console.error('Failed to upsert app_settings to Supabase:', err);
      }
    }

    saveDemoAppSettings(settings);
  },
};
