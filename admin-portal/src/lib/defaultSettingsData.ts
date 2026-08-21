import { AppSettings, AppNotification } from '../types';

export const INITIAL_APP_SETTINGS: AppSettings = {
  id: 'global-settings-001',
  general: {
    app_name: 'WrindhaOS',
    tagline: 'The Student Operating System',
    support_email: 'support@wrindhaos.com',
    support_phone: '+91 800-974-6342',
    website_url: 'https://wrindhaos.com',
  },
  app_version: {
    minimum_supported_version: '1.0.0',
    latest_version: '1.4.2',
    force_update: false,
    maintenance_mode: false,
    maintenance_message: 'WrindhaOS is currently under maintenance. Please try again later.',
  },
  support: {
    support_email: 'support@wrindhaos.com',
    support_website: 'https://wrindhaos.com/support',
    help_center_url: 'https://docs.wrindhaos.com',
  },
  legal: {
    privacy_policy_url: 'https://wrindhaos.com/privacy',
    terms_conditions_url: 'https://wrindhaos.com/terms',
    refund_policy_url: 'https://wrindhaos.com/refund',
    account_deletion_url: 'https://wrindhaos.com/delete-account',
    grievance_contact: 'grievance-officer@wrindhaos.com',
  },
  updated_at: new Date().toISOString(),
  updated_by: 'adm-001',
};

export const INITIAL_NOTIFICATIONS: AppNotification[] = [];
