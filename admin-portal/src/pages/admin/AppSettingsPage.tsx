import React, { useState, useEffect } from 'react';
import {
  Settings,
  Shield,
  Smartphone,
  HelpCircle,
  FileText,
  AlertTriangle,
  CheckCircle2,
  Save,
  RotateCcw,
  History,
  Lock,
  ExternalLink,
  Info,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { settingsService } from '../../services/settingsService';
import { auditService } from '../../services/auditService';
import {
  AppSettings,
  GeneralSettings,
  AppVersionSettings,
  SupportSettings,
  LegalSettings,
  AdminAuditLog,
} from '../../types';
import { Badge } from '../../components/common/Badge';

export const AppSettingsPage: React.FC = () => {
  const { adminUser } = useAuth();

  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'general' | 'version' | 'support' | 'legal' | 'audit'>('general');

  // Form State
  const [generalForm, setGeneralForm] = useState<GeneralSettings>({
    app_name: 'WrindhaOS',
    tagline: '',
    support_email: '',
    support_phone: '',
    website_url: '',
  });

  const [versionForm, setVersionForm] = useState<AppVersionSettings>({
    minimum_supported_version: '1.0.0',
    latest_version: '1.4.2',
    force_update: false,
    maintenance_mode: false,
    maintenance_message: '',
  });

  const [supportForm, setSupportForm] = useState<SupportSettings>({
    support_email: '',
    support_website: '',
    help_center_url: '',
  });

  const [legalForm, setLegalForm] = useState<LegalSettings>({
    privacy_policy_url: '',
    terms_conditions_url: '',
    refund_policy_url: '',
    account_deletion_url: '',
    grievance_contact: '',
  });

  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [recentLogs, setRecentLogs] = useState<AdminAuditLog[]>([]);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setLoading(true);
    try {
      const data = await settingsService.getSettings();
      setSettings(data);
      setGeneralForm(data.general);
      setVersionForm(data.app_version);
      setSupportForm(data.support);
      setLegalForm(data.legal);

      const logs = await auditService.getRecentLogs(15);
      setRecentLogs(logs);
    } catch (err) {
      console.error('Error loading settings:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveGeneral = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const updated = await settingsService.updateGeneralSettings(
        generalForm,
        adminUser?.id || 'adm-001',
        adminUser?.email || 'admin@wrindhaos.com'
      );
      setSettings(updated);
      setFeedback({ type: 'success', message: 'General application settings saved successfully.' });
      loadAudit();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to save general settings.' });
    } finally {
      setSaving(false);
    }
  };

  const handleSaveVersion = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const updated = await settingsService.updateAppVersionSettings(
        versionForm,
        adminUser?.id || 'adm-001',
        adminUser?.email || 'admin@wrindhaos.com'
      );
      setSettings(updated);
      setFeedback({
        type: 'success',
        message: 'App version, force update, and maintenance mode settings updated successfully.',
      });
      loadAudit();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to update app version settings.' });
    } finally {
      setSaving(false);
    }
  };

  const handleSaveSupport = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const updated = await settingsService.updateSupportSettings(
        supportForm,
        adminUser?.id || 'adm-001',
        adminUser?.email || 'admin@wrindhaos.com'
      );
      setSettings(updated);
      setFeedback({ type: 'success', message: 'Support and help information updated successfully.' });
      loadAudit();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to save support settings.' });
    } finally {
      setSaving(false);
    }
  };

  const handleSaveLegal = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setFeedback(null);
    try {
      const updated = await settingsService.updateLegalSettings(
        legalForm,
        adminUser?.id || 'adm-001',
        adminUser?.email || 'admin@wrindhaos.com'
      );
      setSettings(updated);
      setFeedback({ type: 'success', message: 'Legal, compliance, and grievance URLs updated successfully.' });
      loadAudit();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to save legal settings.' });
    } finally {
      setSaving(false);
    }
  };

  const loadAudit = async () => {
    const logs = await auditService.getRecentLogs(15);
    setRecentLogs(logs);
  };

  if (loading) {
    return (
      <div className="p-8 text-center text-zinc-400">
        <div className="w-6 h-6 border-2 border-zinc-900 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
        Loading application settings...
      </div>
    );
  }

  return (
    <div className="p-4 sm:p-8 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold text-zinc-900 tracking-tight">
            App Settings
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 mt-0.5">
            Manage global runtime configurations, version requirements, maintenance mode, and legal compliance.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {versionForm.maintenance_mode && (
            <Badge variant="amber" size="sm" className="font-bold py-1 px-2.5">
              <AlertTriangle className="w-3.5 h-3.5 mr-1 inline" />
              Maintenance Mode Active
            </Badge>
          )}
          {versionForm.force_update && (
            <Badge variant="purple" size="sm" className="font-bold py-1 px-2.5">
              Force Update ON
            </Badge>
          )}
        </div>
      </div>

      {feedback && (
        <div
          className={`p-4 rounded-xl border text-xs sm:text-sm flex items-start gap-3 shadow-xs ${
            feedback.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
              : 'bg-rose-50 border-rose-200 text-rose-900'
          }`}
        >
          {feedback.type === 'success' ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          ) : (
            <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />
          )}
          <p className="font-medium leading-relaxed">{feedback.message}</p>
        </div>
      )}

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-zinc-200 overflow-x-auto pb-px">
        {[
          { key: 'general', label: 'General', icon: <Settings className="w-4 h-4" /> },
          { key: 'version', label: 'App Version & Control', icon: <Smartphone className="w-4 h-4" /> },
          { key: 'support', label: 'Support & Help', icon: <HelpCircle className="w-4 h-4" /> },
          { key: 'legal', label: 'Legal & Compliance', icon: <FileText className="w-4 h-4" /> },
          { key: 'audit', label: 'Audit History', icon: <History className="w-4 h-4" /> },
        ].map((tab) => {
          const isSelected = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              onClick={() => {
                setActiveTab(tab.key as any);
                setFeedback(null);
              }}
              className={`flex items-center gap-2 px-4 py-2.5 text-xs font-semibold border-b-2 transition-all whitespace-nowrap ${
                isSelected
                  ? 'border-zinc-900 text-zinc-900 font-bold'
                  : 'border-transparent text-zinc-500 hover:text-zinc-800 hover:border-zinc-300'
              }`}
            >
              <span>{tab.icon}</span>
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Tab 1: General Settings */}
      {activeTab === 'general' && (
        <form onSubmit={handleSaveGeneral} className="bg-white rounded-xl border border-zinc-200/80 p-6 shadow-xs space-y-5">
          <div className="border-b border-zinc-100 pb-3">
            <h2 className="text-sm font-bold text-zinc-900">General Application Information</h2>
            <p className="text-xs text-zinc-500 mt-0.5">Core brand identity and primary support contact details.</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Application Name
              </label>
              <input
                type="text"
                value={generalForm.app_name}
                onChange={(e) => setGeneralForm({ ...generalForm, app_name: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Tagline / Slogan
              </label>
              <input
                type="text"
                value={generalForm.tagline || ''}
                onChange={(e) => setGeneralForm({ ...generalForm, tagline: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Primary Support Email
              </label>
              <input
                type="email"
                value={generalForm.support_email}
                onChange={(e) => setGeneralForm({ ...generalForm, support_email: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Support Helpline Phone
              </label>
              <input
                type="text"
                value={generalForm.support_phone || ''}
                onChange={(e) => setGeneralForm({ ...generalForm, support_phone: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div className="sm:col-span-2">
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Official Website URL
              </label>
              <input
                type="url"
                value={generalForm.website_url || ''}
                onChange={(e) => setGeneralForm({ ...generalForm, website_url: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-zinc-100 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs disabled:opacity-50"
            >
              <Save className="w-3.5 h-3.5" />
              {saving ? 'Saving...' : 'Save General Settings'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 2: App Version & Maintenance Control */}
      {activeTab === 'version' && (
        <form onSubmit={handleSaveVersion} className="bg-white rounded-xl border border-zinc-200/80 p-6 shadow-xs space-y-6">
          <div className="border-b border-zinc-100 pb-3">
            <h2 className="text-sm font-bold text-zinc-900">App Versioning & Mobile Client Control</h2>
            <p className="text-xs text-zinc-500 mt-0.5">
              Control update policies and maintenance banners for Flutter/mobile clients without locking out administrators.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Minimum Supported Version (e.g. 1.0.0)
              </label>
              <input
                type="text"
                value={versionForm.minimum_supported_version}
                onChange={(e) =>
                  setVersionForm({ ...versionForm, minimum_supported_version: e.target.value })
                }
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
              <p className="text-[11px] text-zinc-400 mt-1">
                Clients running an older version will be prompted or forced to update.
              </p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Latest Released Version (e.g. 1.4.2)
              </label>
              <input
                type="text"
                value={versionForm.latest_version}
                onChange={(e) => setVersionForm({ ...versionForm, latest_version: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
              <p className="text-[11px] text-zinc-400 mt-1">
                Latest stable build available in production stores.
              </p>
            </div>
          </div>

          {/* Force Update Toggle */}
          <div className="p-4 rounded-xl bg-zinc-50 border border-zinc-200/80 flex items-start justify-between gap-4">
            <div className="space-y-0.5">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-zinc-900">Force Update</span>
                {versionForm.force_update ? (
                  <Badge variant="purple" size="sm">Active</Badge>
                ) : (
                  <Badge variant="gray" size="sm">Disabled</Badge>
                )}
              </div>
              <p className="text-[11px] text-zinc-500 leading-relaxed">
                When enabled, students running versions older than{' '}
                <strong className="text-zinc-800">{versionForm.minimum_supported_version}</strong> are blocked by a non-dismissible &ldquo;Please update WrindhaOS to continue&rdquo; screen.
              </p>
            </div>

            <label className="relative inline-flex items-center cursor-pointer shrink-0 mt-1">
              <input
                type="checkbox"
                checked={versionForm.force_update}
                onChange={(e) => setVersionForm({ ...versionForm, force_update: e.target.checked })}
                className="sr-only peer"
              />
              <div className="w-9 h-5 bg-zinc-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-600"></div>
            </label>
          </div>

          {/* Maintenance Mode Toggle */}
          <div className={`p-4 rounded-xl border transition-colors flex flex-col gap-3 ${
            versionForm.maintenance_mode ? 'bg-amber-50/70 border-amber-300' : 'bg-zinc-50 border-zinc-200/80'
          }`}>
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-0.5">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-zinc-900">Maintenance Mode</span>
                  {versionForm.maintenance_mode ? (
                    <Badge variant="amber" size="sm" className="font-bold">ENABLED</Badge>
                  ) : (
                    <Badge variant="gray" size="sm">DISABLED</Badge>
                  )}
                </div>
                <p className="text-[11px] text-zinc-500 leading-relaxed">
                  Temporarily restricts mobile user access during migrations or maintenance windows.
                  <strong className="text-zinc-900 block mt-0.5">
                    Important: Authorized administrators retain full access to this admin panel at all times.
                  </strong>
                </p>
              </div>

              <label className="relative inline-flex items-center cursor-pointer shrink-0 mt-1">
                <input
                  type="checkbox"
                  checked={versionForm.maintenance_mode}
                  onChange={(e) =>
                    setVersionForm({ ...versionForm, maintenance_mode: e.target.checked })
                  }
                  className="sr-only peer"
                />
                <div className="w-9 h-5 bg-zinc-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-amber-600"></div>
              </label>
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1">
                Maintenance Notice Message
              </label>
              <input
                type="text"
                value={versionForm.maintenance_message}
                onChange={(e) =>
                  setVersionForm({ ...versionForm, maintenance_message: e.target.value })
                }
                placeholder="WrindhaOS is currently under maintenance. Please try again later."
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900 bg-white"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-zinc-100 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs disabled:opacity-50"
            >
              <Save className="w-3.5 h-3.5" />
              {saving ? 'Saving...' : 'Update App Version & Controls'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 3: Support & Help Settings */}
      {activeTab === 'support' && (
        <form onSubmit={handleSaveSupport} className="bg-white rounded-xl border border-zinc-200/80 p-6 shadow-xs space-y-5">
          <div className="border-b border-zinc-100 pb-3">
            <h2 className="text-sm font-bold text-zinc-900">Support & Documentation Links</h2>
            <p className="text-xs text-zinc-500 mt-0.5">Channels configured for student customer assistance and user guides.</p>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Support Email Address
              </label>
              <input
                type="email"
                value={supportForm.support_email}
                onChange={(e) => setSupportForm({ ...supportForm, support_email: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Support Help Desk Website URL
              </label>
              <input
                type="url"
                value={supportForm.support_website || ''}
                onChange={(e) => setSupportForm({ ...supportForm, support_website: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Help Center / Documentation URL
              </label>
              <input
                type="url"
                value={supportForm.help_center_url || ''}
                onChange={(e) => setSupportForm({ ...supportForm, help_center_url: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-zinc-100 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs disabled:opacity-50"
            >
              <Save className="w-3.5 h-3.5" />
              {saving ? 'Saving...' : 'Save Support Links'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 4: Legal & Compliance */}
      {activeTab === 'legal' && (
        <form onSubmit={handleSaveLegal} className="bg-white rounded-xl border border-zinc-200/80 p-6 shadow-xs space-y-5">
          <div className="border-b border-zinc-100 pb-3">
            <h2 className="text-sm font-bold text-zinc-900">Legal Compliance & Grievance URLs</h2>
            <p className="text-xs text-zinc-500 mt-0.5">Mandatory public URLs surfaced within mobile app store listings and client settings.</p>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Privacy Policy URL
              </label>
              <input
                type="url"
                value={legalForm.privacy_policy_url}
                onChange={(e) => setLegalForm({ ...legalForm, privacy_policy_url: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Terms and Conditions URL
              </label>
              <input
                type="url"
                value={legalForm.terms_conditions_url}
                onChange={(e) => setLegalForm({ ...legalForm, terms_conditions_url: e.target.value })}
                required
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Refund & Cancellation Policy URL
              </label>
              <input
                type="url"
                value={legalForm.refund_policy_url || ''}
                onChange={(e) => setLegalForm({ ...legalForm, refund_policy_url: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Account Deletion Request URL (Play Store / App Store Mandate)
              </label>
              <input
                type="url"
                value={legalForm.account_deletion_url || ''}
                onChange={(e) => setLegalForm({ ...legalForm, account_deletion_url: e.target.value })}
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 mb-1.5">
                Grievance Officer Contact Email / Details
              </label>
              <input
                type="text"
                value={legalForm.grievance_contact || ''}
                onChange={(e) => setLegalForm({ ...legalForm, grievance_contact: e.target.value })}
                placeholder="e.g. grievance-officer@wrindhaos.com"
                className="w-full px-3.5 py-2 rounded-lg border border-zinc-300 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-zinc-100 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-zinc-900 text-white text-xs font-semibold hover:bg-zinc-800 transition-colors shadow-xs disabled:opacity-50"
            >
              <Save className="w-3.5 h-3.5" />
              {saving ? 'Saving...' : 'Save Legal URLs'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 5: Audit History */}
      {activeTab === 'audit' && (
        <div className="bg-white rounded-xl border border-zinc-200/80 p-6 shadow-xs space-y-4">
          <div className="border-b border-zinc-100 pb-3">
            <h2 className="text-sm font-bold text-zinc-900">System Configuration Audit Trail</h2>
            <p className="text-xs text-zinc-500 mt-0.5">Immutable record of sensitive settings and maintenance status adjustments.</p>
          </div>

          <div className="divide-y divide-zinc-100">
            {recentLogs.length === 0 ? (
              <div className="py-8 text-center text-xs text-zinc-400">
                No recent system configuration audit records found.
              </div>
            ) : (
              recentLogs.map((log) => (
                <div key={log.id} className="py-3 flex items-start justify-between gap-4 text-xs">
                  <div className="space-y-0.5">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-semibold text-zinc-900 bg-zinc-100 px-1.5 py-0.5 rounded text-[11px]">
                        {log.action}
                      </span>
                      <span className="text-zinc-500 text-[11px]">
                        by {log.admin_email || 'admin@wrindhaos.com'}
                      </span>
                    </div>
                    {log.metadata && (
                      <div className="text-[11px] text-zinc-500 font-mono">
                        {JSON.stringify(log.metadata)}
                      </div>
                    )}
                  </div>
                  <div className="text-zinc-400 text-[11px] whitespace-nowrap">
                    {new Date(log.timestamp).toLocaleString()}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};
