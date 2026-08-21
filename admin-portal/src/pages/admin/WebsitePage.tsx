import React, { useState, useEffect } from 'react';
import {
  Globe,
  Save,
  CheckCircle2,
  ExternalLink,
  ShieldAlert,
  Smartphone,
  Mail,
  Home,
  FileCheck,
  AlertTriangle,
  ArrowUpRight,
  Info,
  Clock,
  Sparkles,
} from 'lucide-react';
import {
  WebsiteSettings,
  WebsiteGeneralSettings,
  WebsiteHomepageSettings,
  WebsiteAppLinksSettings,
  WebsiteContactSettings,
  LegalSummaryStats,
} from '../../types';
import { websiteService } from '../../services/websiteService';
import { legalService } from '../../services/legalService';
import { useAuth } from '../../contexts/AuthContext';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Badge } from '../../components/common/Badge';
import { LoadingState } from '../../components/common/LoadingState';
import { ToastAlert } from '../../components/common/ToastAlert';

interface WebsitePageProps {
  onNavigate?: (path: string) => void;
}

type TabType = 'general' | 'homepage' | 'app_links' | 'contact' | 'status';

export const WebsitePage: React.FC<WebsitePageProps> = ({ onNavigate }) => {
  const { adminUser } = useAuth();
  const [loading, setLoading] = useState(true);
  const [savingSection, setSavingSection] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('general');
  const [settings, setSettings] = useState<WebsiteSettings | null>(null);
  const [legalStats, setLegalStats] = useState<LegalSummaryStats | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  // Form states
  const [generalForm, setGeneralForm] = useState<WebsiteGeneralSettings>({
    website_name: '',
    website_url: '',
    short_description: '',
    support_email: '',
    contact_phone: '',
  });

  const [homepageForm, setHomepageForm] = useState<WebsiteHomepageSettings>({
    hero_headline: '',
    hero_description: '',
    primary_cta_text: '',
    primary_cta_url: '',
    secondary_cta_text: '',
    secondary_cta_url: '',
  });

  const [appLinksForm, setAppLinksForm] = useState<WebsiteAppLinksSettings>({
    google_play_url: '',
    android_apk_url: '',
    web_app_url: '',
  });

  const [contactForm, setContactForm] = useState<WebsiteContactSettings>({
    support_email: '',
    business_email: '',
    grievance_email: '',
    contact_page_url: '',
    physical_address: '',
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [fetchedSettings, fetchedLegalStats] = await Promise.all([
        websiteService.getSettings(),
        legalService.getSummaryStats(),
      ]);

      setSettings(fetchedSettings);
      setLegalStats(fetchedLegalStats);

      setGeneralForm(fetchedSettings.general);
      setHomepageForm(fetchedSettings.homepage);
      setAppLinksForm(fetchedSettings.app_links);
      setContactForm(fetchedSettings.contact);
    } catch (err) {
      console.error('Failed to load website settings:', err);
      showToast('Failed to load website settings.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToastMessage(message);
    setToastType(type);
  };

  const handleSaveGeneral = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminUser) return;
    try {
      setSavingSection('general');
      const updated = await websiteService.updateGeneralSettings(
        generalForm,
        adminUser.id,
        adminUser.email
      );
      setSettings(updated);
      showToast('General website settings updated successfully.');
    } catch (err) {
      console.error('Error saving general settings:', err);
      showToast('Failed to update general settings.', 'error');
    } finally {
      setSavingSection(null);
    }
  };

  const handleSaveHomepage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminUser) return;
    try {
      setSavingSection('homepage');
      const updated = await websiteService.updateHomepageSettings(
        homepageForm,
        adminUser.id,
        adminUser.email
      );
      setSettings(updated);
      showToast('Homepage hero content updated successfully.');
    } catch (err) {
      console.error('Error saving homepage settings:', err);
      showToast('Failed to update homepage settings.', 'error');
    } finally {
      setSavingSection(null);
    }
  };

  const handleSaveAppLinks = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminUser) return;
    try {
      setSavingSection('app_links');
      const updated = await websiteService.updateAppLinksSettings(
        appLinksForm,
        adminUser.id,
        adminUser.email
      );
      setSettings(updated);
      showToast('App download and platform links updated successfully.');
    } catch (err) {
      console.error('Error saving app links:', err);
      showToast('Failed to update app download links.', 'error');
    } finally {
      setSavingSection(null);
    }
  };

  const handleSaveContact = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminUser) return;
    try {
      setSavingSection('contact');
      const updated = await websiteService.updateContactSettings(
        contactForm,
        adminUser.id,
        adminUser.email
      );
      setSettings(updated);
      showToast('Contact and grievance details updated successfully.');
    } catch (err) {
      console.error('Error saving contact settings:', err);
      showToast('Failed to update contact settings.', 'error');
    } finally {
      setSavingSection(null);
    }
  };

  if (loading || !settings) {
    return <LoadingState message="Loading WrindhaOS website management..." />;
  }

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'general', label: 'General', icon: <Globe className="w-4 h-4" /> },
    { id: 'homepage', label: 'Homepage Hero', icon: <Home className="w-4 h-4" /> },
    { id: 'app_links', label: 'Download Links', icon: <Smartphone className="w-4 h-4" /> },
    { id: 'contact', label: 'Contact & Grievance', icon: <Mail className="w-4 h-4" /> },
    { id: 'status', label: 'Status & Readiness', icon: <CheckCircle2 className="w-4 h-4" /> },
  ];

  return (
    <div className="space-y-6 max-w-6xl mx-auto pb-12">
      {/* Toast Notification */}
      {toastMessage && (
        <ToastAlert
          type={toastType}
          message={toastMessage}
          onClose={() => setToastMessage(null)}
        />
      )}

      {/* Header Section */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-zinc-900">
              Website Management
            </h1>
            <Badge variant="blue" size="sm" className="font-mono text-xs">
              wrindhaos.in
            </Badge>
          </div>
          <p className="text-sm text-zinc-500 mt-1">
            Centralized public website settings, homepage hero copy, store links, and launch readiness.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <a
            href={settings.general.website_url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-3.5 py-2 text-sm font-medium text-zinc-700 bg-white border border-zinc-200 rounded-lg hover:bg-zinc-50 hover:text-zinc-900 transition-colors shadow-xs"
          >
            <Globe className="w-4 h-4 text-zinc-500" />
            <span>Preview Website</span>
            <ExternalLink className="w-3.5 h-3.5 text-zinc-400" />
          </a>

          {onNavigate && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => onNavigate('/admin/legal')}
              className="gap-2"
            >
              <FileCheck className="w-4 h-4 text-indigo-600" />
              <span>Manage Legal Docs</span>
            </Button>
          )}
        </div>
      </div>

      {/* Website Readiness Summary Bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-4 flex items-center gap-3.5 border-zinc-200">
          <div className="w-10 h-10 rounded-lg bg-indigo-50 border border-indigo-100 flex items-center justify-center text-indigo-600 shrink-0">
            <Globe className="w-5 h-5" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-xs text-zinc-500 font-medium">Public Domain</div>
            <div className="text-sm font-semibold text-zinc-900 truncate flex items-center gap-1.5 mt-0.5">
              <span>{settings.general.website_url}</span>
              <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" title="Active domain" />
            </div>
          </div>
        </Card>

        <Card className="p-4 flex items-center gap-3.5 border-zinc-200">
          <div className="w-10 h-10 rounded-lg bg-emerald-50 border border-emerald-100 flex items-center justify-center text-emerald-600 shrink-0">
            <FileCheck className="w-5 h-5" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-xs text-zinc-500 font-medium">Legal Documents Readiness</div>
            <div className="text-sm font-semibold text-zinc-900 flex items-center gap-2 mt-0.5">
              <span>{legalStats?.publishedCount || 0} of {legalStats?.totalRequired || 7} Published</span>
              {legalStats?.allPublished ? (
                <Badge variant="green" size="sm">Ready</Badge>
              ) : (
                <Badge variant="amber" size="sm">{legalStats?.missingCount} Pending</Badge>
              )}
            </div>
          </div>
        </Card>

        <Card className="p-4 flex items-center gap-3.5 border-zinc-200">
          <div className="w-10 h-10 rounded-lg bg-amber-50 border border-amber-100 flex items-center justify-center text-amber-600 shrink-0">
            <Smartphone className="w-5 h-5" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-xs text-zinc-500 font-medium">Google Play Store Status</div>
            <div className="text-sm font-semibold text-zinc-900 flex items-center gap-1.5 mt-0.5">
              {settings.app_links.google_play_url ? (
                <span className="text-emerald-600 font-medium">Live URL Configured</span>
              ) : (
                <span className="text-amber-600 font-normal text-xs">Awaiting Store Approval</span>
              )}
            </div>
          </div>
        </Card>
      </div>

      {/* Tabs Navigation */}
      <div className="border-b border-zinc-200">
        <div className="flex gap-2 overflow-x-auto pb-px">
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-all whitespace-nowrap ${
                  isActive
                    ? 'border-zinc-900 text-zinc-900 font-semibold'
                    : 'border-transparent text-zinc-500 hover:text-zinc-800 hover:border-zinc-300'
                }`}
              >
                <span className={isActive ? 'text-zinc-900' : 'text-zinc-400'}>
                  {tab.icon}
                </span>
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* TAB 1: GENERAL SETTINGS */}
      {activeTab === 'general' && (
        <form onSubmit={handleSaveGeneral}>
          <Card className="p-6 space-y-6">
            <div>
              <h3 className="text-base font-semibold text-zinc-900">
                General Website Identity
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Centralized branding information used on the public landing page and metadata.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <Input
                label="Website / Brand Name"
                value={generalForm.website_name}
                onChange={(e) =>
                  setGeneralForm({ ...generalForm, website_name: e.target.value })
                }
                placeholder="WrindhaOS"
                required
              />

              <Input
                label="Public Website URL"
                value={generalForm.website_url}
                onChange={(e) =>
                  setGeneralForm({ ...generalForm, website_url: e.target.value })
                }
                placeholder="https://wrindhaos.in"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 uppercase tracking-wider mb-1.5">
                Short Meta Description
              </label>
              <textarea
                value={generalForm.short_description}
                onChange={(e) =>
                  setGeneralForm({ ...generalForm, short_description: e.target.value })
                }
                rows={3}
                className="w-full px-3.5 py-2.5 bg-white border border-zinc-200 rounded-lg text-sm text-zinc-900 focus:outline-hidden focus:ring-2 focus:ring-zinc-900 focus:border-transparent transition-all placeholder:text-zinc-400"
                placeholder="Brief summary of WrindhaOS purpose for web search and page meta tags."
                required
              />
              <p className="text-[11px] text-zinc-500 mt-1">
                Used in HTML header metadata and social sharing previews.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 pt-2 border-t border-zinc-100">
              <Input
                label="General Support Email"
                type="email"
                value={generalForm.support_email}
                onChange={(e) =>
                  setGeneralForm({ ...generalForm, support_email: e.target.value })
                }
                placeholder="support@wrindhaos.in"
                required
              />

              <Input
                label="Support Phone Number (Optional)"
                value={generalForm.contact_phone || ''}
                onChange={(e) =>
                  setGeneralForm({ ...generalForm, contact_phone: e.target.value })
                }
                placeholder="+91 800-974-6342"
              />
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-zinc-100">
              <div className="text-xs text-zinc-400 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5" />
                <span>Last updated: {new Date(settings.updated_at).toLocaleString()}</span>
              </div>

              <Button
                type="submit"
                disabled={savingSection === 'general'}
                className="gap-2"
              >
                <Save className="w-4 h-4" />
                <span>{savingSection === 'general' ? 'Saving...' : 'Save General Settings'}</span>
              </Button>
            </div>
          </Card>
        </form>
      )}

      {/* TAB 2: HOMEPAGE HERO SETTINGS */}
      {activeTab === 'homepage' && (
        <form onSubmit={handleSaveHomepage}>
          <Card className="p-6 space-y-6">
            <div>
              <h3 className="text-base font-semibold text-zinc-900">
                Homepage Hero Content
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Manage the main headline, description, and call-to-action button on the public homepage.
              </p>
            </div>

            <div className="space-y-4">
              <Input
                label="Hero Headline"
                value={homepageForm.hero_headline}
                onChange={(e) =>
                  setHomepageForm({ ...homepageForm, hero_headline: e.target.value })
                }
                placeholder="Your Personal Operating System for Progress."
                required
              />

              <div>
                <label className="block text-xs font-semibold text-zinc-700 uppercase tracking-wider mb-1.5">
                  Hero Subtitle / Description
                </label>
                <textarea
                  value={homepageForm.hero_description}
                  onChange={(e) =>
                    setHomepageForm({ ...homepageForm, hero_description: e.target.value })
                  }
                  rows={3}
                  className="w-full px-3.5 py-2.5 bg-white border border-zinc-200 rounded-lg text-sm text-zinc-900 focus:outline-hidden focus:ring-2 focus:ring-zinc-900 focus:border-transparent transition-all placeholder:text-zinc-400"
                  placeholder="Explain WrindhaOS value proposition clearly in 1-2 sentences."
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 pt-3 border-t border-zinc-100">
                <Input
                  label="Primary CTA Button Text"
                  value={homepageForm.primary_cta_text}
                  onChange={(e) =>
                    setHomepageForm({ ...homepageForm, primary_cta_text: e.target.value })
                  }
                  placeholder="Get WrindhaOS"
                  required
                />

                <Input
                  label="Primary CTA Destination URL"
                  value={homepageForm.primary_cta_url}
                  onChange={(e) =>
                    setHomepageForm({ ...homepageForm, primary_cta_url: e.target.value })
                  }
                  placeholder="https://wrindhaos.in/download"
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 pt-3 border-t border-zinc-100">
                <Input
                  label="Secondary CTA Button Text (Optional)"
                  value={homepageForm.secondary_cta_text || ''}
                  onChange={(e) =>
                    setHomepageForm({ ...homepageForm, secondary_cta_text: e.target.value })
                  }
                  placeholder="Explore Curriculum"
                />

                <Input
                  label="Secondary CTA Destination URL"
                  value={homepageForm.secondary_cta_url || ''}
                  onChange={(e) =>
                    setHomepageForm({ ...homepageForm, secondary_cta_url: e.target.value })
                  }
                  placeholder="https://wrindhaos.in/curriculum"
                />
              </div>
            </div>

            {/* Live Hero Banner Preview */}
            <div className="mt-6 p-6 rounded-xl bg-zinc-900 text-white border border-zinc-800">
              <div className="flex items-center gap-2 text-xs font-semibold text-zinc-400 uppercase tracking-widest mb-4">
                <Sparkles className="w-3.5 h-3.5 text-indigo-400" />
                <span>Live Hero Preview (wrindhaos.in)</span>
              </div>
              <div className="max-w-2xl space-y-3">
                <h2 className="text-2xl font-bold tracking-tight text-white">
                  {homepageForm.hero_headline || 'Your Personal Operating System for Progress.'}
                </h2>
                <p className="text-sm text-zinc-300 leading-relaxed">
                  {homepageForm.hero_description ||
                    'Track habits, manage daily routines, monitor expenses, and navigate long-term career roadmaps.'}
                </p>
                <div className="flex items-center gap-3 pt-3">
                  <span className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-white text-zinc-900 text-xs font-bold shadow-xs">
                    {homepageForm.primary_cta_text || 'Get WrindhaOS'}
                    <ArrowUpRight className="w-3.5 h-3.5" />
                  </span>
                  {homepageForm.secondary_cta_text && (
                    <span className="inline-flex items-center px-4 py-2 rounded-lg bg-zinc-800 text-zinc-200 text-xs font-medium border border-zinc-700">
                      {homepageForm.secondary_cta_text}
                    </span>
                  )}
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end pt-4 border-t border-zinc-100">
              <Button
                type="submit"
                disabled={savingSection === 'homepage'}
                className="gap-2"
              >
                <Save className="w-4 h-4" />
                <span>{savingSection === 'homepage' ? 'Saving...' : 'Save Homepage Copy'}</span>
              </Button>
            </div>
          </Card>
        </form>
      )}

      {/* TAB 3: APP DOWNLOAD LINKS */}
      {activeTab === 'app_links' && (
        <form onSubmit={handleSaveAppLinks}>
          <Card className="p-6 space-y-6">
            <div>
              <h3 className="text-base font-semibold text-zinc-900">
                Application Distribution & Store Links
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Configure direct app download endpoints without modifying source code.
              </p>
            </div>

            <div className="p-4 rounded-lg bg-amber-50/70 border border-amber-200 flex items-start gap-3">
              <Info className="w-4 h-4 text-amber-700 shrink-0 mt-0.5" />
              <div className="text-xs text-amber-800 leading-relaxed">
                <span className="font-semibold">Google Play Store Listing Note:</span> When the Google Play Store listing is officially approved and published, paste the direct store URL below. Do not invent temporary mock URLs.
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <Input
                  label="Google Play Store URL"
                  value={appLinksForm.google_play_url || ''}
                  onChange={(e) =>
                    setAppLinksForm({ ...appLinksForm, google_play_url: e.target.value })
                  }
                  placeholder="https://play.google.com/store/apps/details?id=com.wrindhaos.app (leave empty if pending)"
                />
                <p className="text-[11px] text-zinc-500 mt-1">
                  {appLinksForm.google_play_url ? (
                    <span className="text-emerald-600 font-medium">Configured. Public download buttons will redirect directly to Google Play.</span>
                  ) : (
                    <span className="text-amber-600">Unset. Website will present standard registration or APK download options.</span>
                  )}
                </p>
              </div>

              <Input
                label="Direct Android APK Download URL (Optional)"
                value={appLinksForm.android_apk_url || ''}
                onChange={(e) =>
                  setAppLinksForm({ ...appLinksForm, android_apk_url: e.target.value })
                }
                placeholder="https://wrindhaos.in/downloads/wrindhaos-latest.apk"
              />

              <Input
                label="Web Application URL"
                value={appLinksForm.web_app_url || ''}
                onChange={(e) =>
                  setAppLinksForm({ ...appLinksForm, web_app_url: e.target.value })
                }
                placeholder="https://app.wrindhaos.in"
              />
            </div>

            <div className="flex items-center justify-end pt-4 border-t border-zinc-100">
              <Button
                type="submit"
                disabled={savingSection === 'app_links'}
                className="gap-2"
              >
                <Save className="w-4 h-4" />
                <span>{savingSection === 'app_links' ? 'Saving...' : 'Save Download Links'}</span>
              </Button>
            </div>
          </Card>
        </form>
      )}

      {/* TAB 4: CONTACT & GRIEVANCE */}
      {activeTab === 'contact' && (
        <form onSubmit={handleSaveContact}>
          <Card className="p-6 space-y-6">
            <div>
              <h3 className="text-base font-semibold text-zinc-900">
                Contact & Grievance Information
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Public channels displayed on the contact page and legal disclosures.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <Input
                label="Support Email"
                type="email"
                value={contactForm.support_email}
                onChange={(e) =>
                  setContactForm({ ...contactForm, support_email: e.target.value })
                }
                placeholder="support@wrindhaos.in"
                required
              />

              <Input
                label="Business / Partnership Email"
                type="email"
                value={contactForm.business_email}
                onChange={(e) =>
                  setContactForm({ ...contactForm, business_email: e.target.value })
                }
                placeholder="contact@wrindhaos.in"
                required
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 pt-3 border-t border-zinc-100">
              <Input
                label="Grievance Redressal Officer Email"
                type="email"
                value={contactForm.grievance_email}
                onChange={(e) =>
                  setContactForm({ ...contactForm, grievance_email: e.target.value })
                }
                placeholder="grievance-officer@wrindhaos.in"
                required
              />

              <Input
                label="Public Contact Page URL"
                value={contactForm.contact_page_url}
                onChange={(e) =>
                  setContactForm({ ...contactForm, contact_page_url: e.target.value })
                }
                placeholder="/contact"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 uppercase tracking-wider mb-1.5">
                Corporate Physical Address
              </label>
              <textarea
                value={contactForm.physical_address || ''}
                onChange={(e) =>
                  setContactForm({ ...contactForm, physical_address: e.target.value })
                }
                rows={2}
                className="w-full px-3.5 py-2.5 bg-white border border-zinc-200 rounded-lg text-sm text-zinc-900 focus:outline-hidden focus:ring-2 focus:ring-zinc-900 focus:border-transparent transition-all placeholder:text-zinc-400"
                placeholder="WrindhaOS Technologies India Pvt Ltd, Bengaluru, Karnataka 560100, India"
              />
            </div>

            <div className="flex items-center justify-end pt-4 border-t border-zinc-100">
              <Button
                type="submit"
                disabled={savingSection === 'contact'}
                className="gap-2"
              >
                <Save className="w-4 h-4" />
                <span>{savingSection === 'contact' ? 'Saving...' : 'Save Contact Details'}</span>
              </Button>
            </div>
          </Card>
        </form>
      )}

      {/* TAB 5: WEBSITE STATUS & READINESS */}
      {activeTab === 'status' && (
        <div className="space-y-6">
          <Card className="p-6 space-y-6">
            <div>
              <h3 className="text-base font-semibold text-zinc-900">
                Launch & Website Readiness Checklist
              </h3>
              <p className="text-xs text-zinc-500 mt-0.5">
                Pre-launch evaluation of website configuration and legal documentation.
              </p>
            </div>

            <div className="divide-y divide-zinc-100">
              <div className="py-3.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                  <div>
                    <div className="text-sm font-semibold text-zinc-900">Public Domain Configured</div>
                    <div className="text-xs text-zinc-500">{settings.general.website_url}</div>
                  </div>
                </div>
                <Badge variant="green" size="sm">Active</Badge>
              </div>

              <div className="py-3.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                  <div>
                    <div className="text-sm font-semibold text-zinc-900">Homepage Hero & CTA</div>
                    <div className="text-xs text-zinc-500">"{settings.homepage.hero_headline}"</div>
                  </div>
                </div>
                <Badge variant="green" size="sm">Configured</Badge>
              </div>

              <div className="py-3.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  {settings.app_links.google_play_url ? (
                    <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                  ) : (
                    <AlertTriangle className="w-5 h-5 text-amber-500" />
                  )}
                  <div>
                    <div className="text-sm font-semibold text-zinc-900">Google Play Store URL</div>
                    <div className="text-xs text-zinc-500">
                      {settings.app_links.google_play_url || 'Pending store listing release'}
                    </div>
                  </div>
                </div>
                {settings.app_links.google_play_url ? (
                  <Badge variant="green" size="sm">Configured</Badge>
                ) : (
                  <Badge variant="amber" size="sm">Awaiting Release</Badge>
                )}
              </div>

              <div className="py-3.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  {legalStats?.allPublished ? (
                    <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                  ) : (
                    <ShieldAlert className="w-5 h-5 text-amber-500" />
                  )}
                  <div>
                    <div className="text-sm font-semibold text-zinc-900">Required Legal Notices</div>
                    <div className="text-xs text-zinc-500">
                      {legalStats?.publishedCount} of {legalStats?.totalRequired} documents published
                    </div>
                  </div>
                </div>
                {legalStats?.allPublished ? (
                  <Badge variant="green" size="sm">All 7 Published</Badge>
                ) : (
                  <Badge variant="amber" size="sm">{legalStats?.missingCount} In Draft / Missing</Badge>
                )}
              </div>
            </div>

            {legalStats && legalStats.missingDocuments.length > 0 && (
              <div className="p-4 rounded-lg bg-amber-50 border border-amber-200">
                <div className="text-xs font-semibold text-amber-900 mb-1">
                  Pending Legal Documents before Launch:
                </div>
                <ul className="list-disc list-inside text-xs text-amber-800 space-y-1">
                  {legalStats.missingDocuments.map((doc, idx) => (
                    <li key={idx}>{doc}</li>
                  ))}
                </ul>
              </div>
            )}

            <div className="flex items-center justify-between pt-4 border-t border-zinc-100">
              <div className="text-xs text-zinc-500">
                Ensure all documents and contact points are updated prior to Play Store submission.
              </div>

              {onNavigate && (
                <Button
                  onClick={() => onNavigate('/admin/legal')}
                  className="gap-2"
                >
                  <FileCheck className="w-4 h-4" />
                  <span>Review Legal Documents</span>
                </Button>
              )}
            </div>
          </Card>
        </div>
      )}
    </div>
  );
};
