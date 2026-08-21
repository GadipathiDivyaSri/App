import {
  WebsiteSettings,
  WebsiteGeneralSettings,
  WebsiteHomepageSettings,
  WebsiteAppLinksSettings,
  WebsiteContactSettings,
} from '../types';
import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoWebsiteSettings,
  saveDemoWebsiteSettings,
} from '../lib/supabase';
import { auditService } from './auditService';
import { INITIAL_WEBSITE_SETTINGS } from '../lib/defaultWebsiteAndLegalData';

export const websiteService = {
  /**
   * Retrieves current website settings.
   */
  async getSettings(): Promise<WebsiteSettings> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('website_settings')
          .select('*')
          .eq('id', 'global_website_settings')
          .maybeSingle();

        if (error) {
          console.error('Error fetching website settings from Supabase:', error);
        } else if (data) {
          return {
            id: data.id,
            general: data.general || INITIAL_WEBSITE_SETTINGS.general,
            homepage: data.homepage || INITIAL_WEBSITE_SETTINGS.homepage,
            app_links: data.app_links || INITIAL_WEBSITE_SETTINGS.app_links,
            contact: data.contact || INITIAL_WEBSITE_SETTINGS.contact,
            updated_at: data.updated_at || new Date().toISOString(),
            updated_by: data.updated_by,
          };
        }
      } catch (err) {
        console.error('Failed to read website settings from Supabase, falling back:', err);
      }
    }

    return getDemoWebsiteSettings();
  },

  /**
   * Updates General website settings.
   */
  async updateGeneralSettings(
    general: WebsiteGeneralSettings,
    adminId: string,
    adminEmail: string
  ): Promise<WebsiteSettings> {
    const current = await this.getSettings();
    const updated: WebsiteSettings = {
      ...current,
      general,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'WEBSITE_SETTINGS_UPDATED',
      undefined,
      adminId,
      { section: 'general', changes: general },
      adminEmail
    );

    return updated;
  },

  /**
   * Updates Homepage hero and CTA settings.
   */
  async updateHomepageSettings(
    homepage: WebsiteHomepageSettings,
    adminId: string,
    adminEmail: string
  ): Promise<WebsiteSettings> {
    const current = await this.getSettings();
    const updated: WebsiteSettings = {
      ...current,
      homepage,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'HOMEPAGE_UPDATED',
      undefined,
      adminId,
      { headline: homepage.hero_headline, primary_cta: homepage.primary_cta_text },
      adminEmail
    );

    return updated;
  },

  /**
   * Updates Mobile App download links.
   */
  async updateAppLinksSettings(
    app_links: WebsiteAppLinksSettings,
    adminId: string,
    adminEmail: string
  ): Promise<WebsiteSettings> {
    const current = await this.getSettings();
    const updated: WebsiteSettings = {
      ...current,
      app_links,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'WEBSITE_SETTINGS_UPDATED',
      undefined,
      adminId,
      { section: 'app_links', google_play_configured: !!app_links.google_play_url },
      adminEmail
    );

    return updated;
  },

  /**
   * Updates Contact and Grievance details.
   */
  async updateContactSettings(
    contact: WebsiteContactSettings,
    adminId: string,
    adminEmail: string
  ): Promise<WebsiteSettings> {
    const current = await this.getSettings();
    const updated: WebsiteSettings = {
      ...current,
      contact,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
    };

    await this.persistSettings(updated);

    await auditService.logAction(
      'WEBSITE_SETTINGS_UPDATED',
      undefined,
      adminId,
      { section: 'contact', support_email: contact.support_email },
      adminEmail
    );

    return updated;
  },

  /**
   * Persists settings to Supabase or demo storage.
   */
  async persistSettings(settings: WebsiteSettings): Promise<void> {
    // Always update local cache
    saveDemoWebsiteSettings(settings);

    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('website_settings').upsert({
          id: settings.id || 'global_website_settings',
          general: settings.general,
          homepage: settings.homepage,
          app_links: settings.app_links,
          contact: settings.contact,
          updated_at: settings.updated_at,
          updated_by: settings.updated_by,
        });

        if (error) {
          console.error('Failed to persist website settings to Supabase:', error);
        }
      } catch (err) {
        console.error('Error saving website settings to Supabase:', err);
      }
    }
  },
};
