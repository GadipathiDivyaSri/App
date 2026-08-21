import React, { useState, useEffect } from 'react';
import {
  FileCheck,
  Plus,
  Search,
  ExternalLink,
  Edit3,
  Globe,
  Clock,
  ShieldCheck,
  AlertTriangle,
  Copy,
  Check,
  RotateCcw,
  BookOpen,
  Info,
  CheckCircle2,
  FileText,
} from 'lucide-react';
import { LegalDocument, LegalSummaryStats, LegalDocumentStatus } from '../../types';
import { legalService, REQUIRED_LEGAL_SLUGS } from '../../services/legalService';
import { useAuth } from '../../contexts/AuthContext';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import { Badge } from '../../components/common/Badge';
import { Modal } from '../../components/common/Modal';
import { Input } from '../../components/common/Input';
import { LoadingState } from '../../components/common/LoadingState';
import { ToastAlert } from '../../components/common/ToastAlert';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '../../components/common/Table';

interface LegalPageProps {
  onNavigate?: (path: string) => void;
  onPreviewPublicDocument?: (slug: string) => void;
}

export const LegalPage: React.FC<LegalPageProps> = ({ onNavigate, onPreviewPublicDocument }) => {
  const { adminUser } = useAuth();
  const [loading, setLoading] = useState(true);
  const [documents, setDocuments] = useState<LegalDocument[]>([]);
  const [stats, setStats] = useState<LegalSummaryStats | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | LegalDocumentStatus>('ALL');
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  const [copiedUrl, setCopiedUrl] = useState<string | null>(null);

  // Editor Modal State
  const [editorOpen, setEditorOpen] = useState(false);
  const [editingDoc, setEditingDoc] = useState<LegalDocument | null>(null);
  const [editorForm, setEditorForm] = useState({
    title: '',
    slug: '',
    description: '',
    version: '1.0.0',
    public_url: '',
    status: 'DRAFT' as LegalDocumentStatus,
    content: '',
  });
  const [previewMode, setPreviewMode] = useState<'edit' | 'preview'>('edit');
  const [savingDoc, setSavingDoc] = useState(false);

  // Publish Confirm Modal State
  const [publishModalOpen, setPublishModalOpen] = useState(false);
  const [docToPublish, setDocToPublish] = useState<LegalDocument | null>(null);

  // Quick View / Reader Modal State
  const [readerDoc, setReaderDoc] = useState<LegalDocument | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [docs, summary] = await Promise.all([
        legalService.getAllDocuments(),
        legalService.getSummaryStats(),
      ]);
      setDocuments(docs);
      setStats(summary);
    } catch (err) {
      console.error('Failed to load legal documents:', err);
      showToast('Failed to load legal documents.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToastMessage(message);
    setToastType(type);
  };

  const handleCopyUrl = (url: string) => {
    const fullUrl = url.startsWith('http') ? url : `https://wrindhaos.in${url}`;
    navigator.clipboard.writeText(fullUrl);
    setCopiedUrl(url);
    setTimeout(() => setCopiedUrl(null), 2000);
    showToast(`Copied URL: ${fullUrl}`);
  };

  const handleOpenCreate = () => {
    setEditingDoc(null);
    setEditorForm({
      title: '',
      slug: '',
      description: '',
      version: '1.0.0',
      public_url: '',
      status: 'DRAFT',
      content: '# Document Title\n\nWrite legal policy content here...',
    });
    setPreviewMode('edit');
    setEditorOpen(true);
  };

  const handleOpenEdit = (doc: LegalDocument) => {
    setEditingDoc(doc);
    setEditorForm({
      title: doc.title,
      slug: doc.slug,
      description: doc.description || '',
      version: doc.version || '1.0.0',
      public_url: doc.public_url,
      status: doc.status,
      content: doc.content,
    });
    setPreviewMode('edit');
    setEditorOpen(true);
  };

  const handleSaveDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminUser) return;

    // If changing to PUBLISHED from DRAFT, ask for confirmation
    if (editorForm.status === 'PUBLISHED' && (!editingDoc || editingDoc.status !== 'PUBLISHED')) {
      // Prompt confirmation before finalizing
      setPublishModalOpen(true);
      return;
    }

    await executeSave();
  };

  const executeSave = async () => {
    if (!adminUser) return;
    try {
      setSavingDoc(true);
      if (editingDoc) {
        await legalService.updateDocument(
          editingDoc.id,
          {
            title: editorForm.title,
            slug: editorForm.slug,
            description: editorForm.description,
            version: editorForm.version,
            public_url: editorForm.public_url.startsWith('/') ? editorForm.public_url : `/${editorForm.public_url}`,
            status: editorForm.status,
            content: editorForm.content,
          },
          adminUser.id,
          adminUser.email
        );
        showToast(`Document "${editorForm.title}" updated successfully.`);
      } else {
        await legalService.createDocument(
          {
            title: editorForm.title,
            slug: editorForm.slug,
            description: editorForm.description,
            version: editorForm.version,
            public_url: editorForm.public_url.startsWith('/') ? editorForm.public_url : `/${editorForm.public_url}`,
            status: editorForm.status,
            content: editorForm.content,
          },
          adminUser.id,
          adminUser.email
        );
        showToast(`New document "${editorForm.title}" created.`);
      }

      setEditorOpen(false);
      setPublishModalOpen(false);
      await loadData();
    } catch (err) {
      console.error('Failed to save document:', err);
      showToast('Failed to save legal document.', 'error');
    } finally {
      setSavingDoc(false);
    }
  };

  const handleQuickTogglePublish = (doc: LegalDocument) => {
    if (doc.status === 'DRAFT') {
      setDocToPublish(doc);
      setPublishModalOpen(true);
    } else {
      handleConfirmUnpublish(doc);
    }
  };

  const handleConfirmPublish = async () => {
    if (!adminUser) return;
    try {
      if (docToPublish) {
        await legalService.publishDocument(docToPublish.id, adminUser.id, adminUser.email);
        showToast(`"${docToPublish.title}" is now published.`);
        setDocToPublish(null);
        setPublishModalOpen(false);
        await loadData();
      } else if (editorOpen) {
        await executeSave();
      }
    } catch (err) {
      console.error('Failed to publish document:', err);
      showToast('Failed to publish document.', 'error');
    }
  };

  const handleConfirmUnpublish = async (doc: LegalDocument) => {
    if (!adminUser) return;
    try {
      await legalService.unpublishDocument(doc.id, adminUser.id, adminUser.email);
      showToast(`"${doc.title}" reverted to draft.`);
      await loadData();
    } catch (err) {
      console.error('Failed to unpublish document:', err);
      showToast('Failed to unpublish document.', 'error');
    }
  };

  const handleResetDefaults = async () => {
    if (!adminUser) return;
    if (!window.confirm('Reset all legal documents to default WrindhaOS launch templates?')) {
      return;
    }
    try {
      await legalService.resetToDefaults(adminUser.id, adminUser.email);
      showToast('Reset all 7 legal documents to default templates.');
      await loadData();
    } catch (err) {
      console.error('Failed to reset legal templates:', err);
      showToast('Failed to reset legal templates.', 'error');
    }
  };

  if (loading) {
    return <LoadingState message="Loading WrindhaOS legal document repository..." />;
  }

  const filteredDocs = documents.filter((doc) => {
    const matchesSearch =
      doc.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.slug.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.public_url.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      statusFilter === 'ALL' || doc.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6 max-w-6xl mx-auto pb-12">
      {/* Toast Alert */}
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
              Legal & Policy Management
            </h1>
            <Badge variant="purple" size="sm">
              Compliance Repository
            </Badge>
          </div>
          <p className="text-sm text-zinc-500 mt-1">
            Manage required public legal notices, terms of service, and user privacy disclosures.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={handleResetDefaults}
            className="gap-2 text-zinc-600 hover:text-zinc-900"
            title="Reload standard default templates"
          >
            <RotateCcw className="w-4 h-4 text-zinc-500" />
            <span>Reset Templates</span>
          </Button>

          <Button
            size="sm"
            onClick={handleOpenCreate}
            className="gap-2"
          >
            <Plus className="w-4 h-4" />
            <span>New Document</span>
          </Button>
        </div>
      </div>

      {/* Legal Status Dashboard Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-4 border-zinc-200">
          <div className="flex items-center justify-between">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Required Documents
            </div>
            <BookOpen className="w-4 h-4 text-zinc-400" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-black text-zinc-900">{stats?.totalRequired || 7}</span>
            <span className="text-xs text-zinc-500">Mandatory for Launch</span>
          </div>
        </Card>

        <Card className="p-4 border-zinc-200">
          <div className="flex items-center justify-between">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Published & Active
            </div>
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-black text-emerald-600">
              {stats?.publishedCount || 0}
            </span>
            <span className="text-xs text-zinc-500">
              of {stats?.totalRequired || 7} Live
            </span>
          </div>
        </Card>

        <Card className="p-4 border-zinc-200">
          <div className="flex items-center justify-between">
            <div className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
              Draft / Pending
            </div>
            <AlertTriangle className="w-4 h-4 text-amber-500" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-black text-amber-600">
              {stats?.draftCount || 0}
            </span>
            <span className="text-xs text-zinc-500">
              {stats?.allPublished ? 'All Published' : 'Action Required'}
            </span>
          </div>
        </Card>
      </div>

      {/* Important Legal Compliance Disclaimer Notice */}
      <div className="p-4 rounded-xl bg-indigo-50/60 border border-indigo-100 flex items-start gap-3.5">
        <Info className="w-5 h-5 text-indigo-700 shrink-0 mt-0.5" />
        <div className="text-xs text-indigo-900 leading-relaxed">
          <span className="font-bold">Operational Guidance:</span> Having published legal documents is a mandatory operational prerequisite for app store submission and public domain readiness. However, publishing a template does not automatically constitute binding legal compliance across all global jurisdictions. Always review final terms with qualified legal counsel.
        </div>
      </div>

      {/* Search & Filter Controls */}
      <Card className="p-4">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-400" />
            <input
              type="text"
              placeholder="Search document name or slug..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9.5 pr-3.5 py-2 bg-zinc-50 border border-zinc-200 rounded-lg text-sm text-zinc-900 focus:outline-hidden focus:ring-2 focus:ring-zinc-900 focus:border-transparent transition-all placeholder:text-zinc-400"
            />
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <div className="flex items-center bg-zinc-100 p-1 rounded-lg text-xs font-medium text-zinc-600">
              <button
                onClick={() => setStatusFilter('ALL')}
                className={`px-3 py-1 rounded-md transition-all ${
                  statusFilter === 'ALL'
                    ? 'bg-white text-zinc-900 shadow-xs font-semibold'
                    : 'hover:text-zinc-900'
                }`}
              >
                All ({documents.length})
              </button>
              <button
                onClick={() => setStatusFilter('PUBLISHED')}
                className={`px-3 py-1 rounded-md transition-all ${
                  statusFilter === 'PUBLISHED'
                    ? 'bg-white text-emerald-700 shadow-xs font-semibold'
                    : 'hover:text-zinc-900'
                }`}
              >
                Published ({documents.filter((d) => d.status === 'PUBLISHED').length})
              </button>
              <button
                onClick={() => setStatusFilter('DRAFT')}
                className={`px-3 py-1 rounded-md transition-all ${
                  statusFilter === 'DRAFT'
                    ? 'bg-white text-amber-700 shadow-xs font-semibold'
                    : 'hover:text-zinc-900'
                }`}
              >
                Draft ({documents.filter((d) => d.status === 'DRAFT').length})
              </button>
            </div>
          </div>
        </div>
      </Card>

      {/* Documents Table */}
      <Card className="overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Document Name</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Public Route</TableHead>
              <TableHead>Last Updated</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredDocs.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="py-12 text-center text-zinc-500">
                  <div className="flex flex-col items-center justify-center">
                    <FileText className="w-8 h-8 text-zinc-300 mb-2" />
                    <p className="text-sm font-medium text-zinc-600">No legal documents found</p>
                    <p className="text-xs text-zinc-400 mt-0.5">Try adjusting your search criteria</p>
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              filteredDocs.map((doc) => {
                const isRequired = REQUIRED_LEGAL_SLUGS.some((r) => r.slug === doc.slug);

                return (
                  <TableRow key={doc.id} className="hover:bg-zinc-50/70 transition-colors">
                    <TableCell>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-zinc-900">{doc.title}</span>
                          {isRequired && (
                            <span className="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 bg-indigo-50 text-indigo-700 rounded border border-indigo-200/60">
                              Required
                            </span>
                          )}
                          {doc.version && (
                            <span className="text-[11px] text-zinc-400 font-mono">
                              v{doc.version}
                            </span>
                          )}
                        </div>
                        {doc.description && (
                          <div className="text-xs text-zinc-500 mt-0.5 max-w-md truncate">
                            {doc.description}
                          </div>
                        )}
                      </div>
                    </TableCell>

                    <TableCell>
                      {doc.status === 'PUBLISHED' ? (
                        <Badge variant="green" size="sm" className="gap-1 font-medium">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block" />
                          Published
                        </Badge>
                      ) : (
                        <Badge variant="amber" size="sm" className="gap-1 font-medium">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 inline-block" />
                          Draft
                        </Badge>
                      )}
                    </TableCell>

                    <TableCell>
                      <div className="flex items-center gap-1.5">
                        <code className="text-xs font-mono bg-zinc-100 px-2 py-0.5 rounded text-zinc-700">
                          {doc.public_url}
                        </code>
                        <button
                          onClick={() => handleCopyUrl(doc.public_url)}
                          title="Copy public URL"
                          className="p-1 text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 rounded transition-colors"
                        >
                          {copiedUrl === doc.public_url ? (
                            <Check className="w-3.5 h-3.5 text-emerald-600" />
                          ) : (
                            <Copy className="w-3.5 h-3.5" />
                          )}
                        </button>
                      </div>
                    </TableCell>

                    <TableCell>
                      <div className="text-xs text-zinc-600">
                        {new Date(doc.updated_at).toLocaleDateString(undefined, {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </div>
                      <div className="text-[11px] text-zinc-400">
                        {new Date(doc.updated_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </TableCell>

                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        {/* Preview / Read Button */}
                        <button
                          onClick={() => setReaderDoc(doc)}
                          className="px-2.5 py-1 text-xs font-medium text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 rounded-md transition-colors"
                          title="Read rendered document"
                        >
                          View
                        </button>

                        {/* Open Public Page Preview */}
                        <button
                          onClick={() => {
                            if (onPreviewPublicDocument) {
                              onPreviewPublicDocument(doc.slug);
                            } else if (onNavigate) {
                              onNavigate(doc.public_url);
                            }
                          }}
                          className="p-1.5 text-zinc-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-md transition-colors"
                          title="Preview public route"
                        >
                          <ExternalLink className="w-3.5 h-3.5" />
                        </button>

                        {/* Edit Button */}
                        <button
                          onClick={() => handleOpenEdit(doc)}
                          className="p-1.5 text-zinc-500 hover:text-zinc-900 hover:bg-zinc-100 rounded-md transition-colors"
                          title="Edit document content"
                        >
                          <Edit3 className="w-3.5 h-3.5" />
                        </button>

                        {/* Fast Publish / Unpublish Toggle */}
                        <button
                          onClick={() => handleQuickTogglePublish(doc)}
                          className={`px-2 py-1 text-xs font-medium rounded-md transition-colors ${
                            doc.status === 'PUBLISHED'
                              ? 'text-zinc-500 hover:text-amber-700 hover:bg-amber-50'
                              : 'text-emerald-700 bg-emerald-50 hover:bg-emerald-100'
                          }`}
                          title={doc.status === 'PUBLISHED' ? 'Revert to draft' : 'Publish document'}
                        >
                          {doc.status === 'PUBLISHED' ? 'Unpublish' : 'Publish'}
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </Card>

      {/* DOCUMENT EDITOR MODAL */}
      <Modal
        isOpen={editorOpen}
        onClose={() => setEditorOpen(false)}
        title={editingDoc ? `Edit: ${editingDoc.title}` : 'Create Legal Document'}
        size="2xl"
      >
        <form onSubmit={handleSaveDocument} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Document Title"
              value={editorForm.title}
              onChange={(e) => {
                const title = e.target.value;
                setEditorForm({
                  ...editorForm,
                  title,
                  slug: editingDoc ? editorForm.slug : title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, ''),
                  public_url: editingDoc ? editorForm.public_url : `/${title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')}`,
                });
              }}
              placeholder="e.g. Terms & Conditions"
              required
            />

            <Input
              label="URL Slug (System Identifier)"
              value={editorForm.slug}
              onChange={(e) =>
                setEditorForm({ ...editorForm, slug: e.target.value })
              }
              placeholder="e.g. terms"
              required
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input
              label="Public URL Route"
              value={editorForm.public_url}
              onChange={(e) =>
                setEditorForm({ ...editorForm, public_url: e.target.value })
              }
              placeholder="e.g. /terms"
              required
            />

            <Input
              label="Document Version"
              value={editorForm.version}
              onChange={(e) =>
                setEditorForm({ ...editorForm, version: e.target.value })
              }
              placeholder="1.0.0"
            />

            <div>
              <label className="block text-xs font-semibold text-zinc-700 uppercase tracking-wider mb-1.5">
                Publication Status
              </label>
              <select
                value={editorForm.status}
                onChange={(e) =>
                  setEditorForm({ ...editorForm, status: e.target.value as LegalDocumentStatus })
                }
                className="w-full px-3 py-2 bg-white border border-zinc-200 rounded-lg text-sm text-zinc-900 focus:outline-hidden focus:ring-2 focus:ring-zinc-900"
              >
                <option value="DRAFT">Draft (Internal Only)</option>
                <option value="PUBLISHED">Published (Public)</option>
              </select>
            </div>
          </div>

          <div>
            <Input
              label="Short Description (Summary)"
              value={editorForm.description}
              onChange={(e) =>
                setEditorForm({ ...editorForm, description: e.target.value })
              }
              placeholder="Summary for internal records & meta description"
            />
          </div>

          {/* Content Editor & Live Preview Tabs */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="block text-xs font-semibold text-zinc-700 uppercase tracking-wider">
                Legal Document Content (Markdown Supported)
              </label>
              <div className="flex items-center bg-zinc-100 p-0.5 rounded text-xs">
                <button
                  type="button"
                  onClick={() => setPreviewMode('edit')}
                  className={`px-2.5 py-1 rounded transition-colors ${
                    previewMode === 'edit'
                      ? 'bg-white text-zinc-900 font-semibold shadow-xs'
                      : 'text-zinc-600'
                  }`}
                >
                  Raw Markdown
                </button>
                <button
                  type="button"
                  onClick={() => setPreviewMode('preview')}
                  className={`px-2.5 py-1 rounded transition-colors ${
                    previewMode === 'preview'
                      ? 'bg-white text-zinc-900 font-semibold shadow-xs'
                      : 'text-zinc-600'
                  }`}
                >
                  Formatted Preview
                </button>
              </div>
            </div>

            {previewMode === 'edit' ? (
              <textarea
                value={editorForm.content}
                onChange={(e) =>
                  setEditorForm({ ...editorForm, content: e.target.value })
                }
                rows={14}
                className="w-full px-3.5 py-3 font-mono text-xs text-zinc-900 bg-zinc-50 border border-zinc-200 rounded-lg focus:outline-hidden focus:ring-2 focus:ring-zinc-900 leading-relaxed"
                placeholder="# Document Title..."
                required
              />
            ) : (
              <div className="max-h-96 overflow-y-auto p-5 bg-white border border-zinc-200 rounded-lg prose prose-sm max-w-none text-zinc-800">
                <div className="whitespace-pre-wrap font-sans text-xs leading-relaxed">
                  {editorForm.content}
                </div>
              </div>
            )}
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-zinc-100">
            <div className="text-xs text-zinc-500">
              Status: <span className="font-semibold">{editorForm.status}</span>
            </div>

            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setEditorOpen(false)}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={savingDoc} className="gap-2">
                {savingDoc ? 'Saving...' : 'Save Legal Document'}
              </Button>
            </div>
          </div>
        </form>
      </Modal>

      {/* CONFIRM PUBLISH MODAL */}
      <Modal
        isOpen={publishModalOpen}
        onClose={() => {
          setPublishModalOpen(false);
          setDocToPublish(null);
        }}
        title="Publish this legal document?"
        size="md"
      >
        <div className="space-y-4">
          <div className="p-4 rounded-lg bg-emerald-50 border border-emerald-200 flex items-start gap-3">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
            <div className="text-xs text-emerald-900 leading-relaxed">
              Publishing will update the live public legal notice at{' '}
              <span className="font-bold">
                {docToPublish ? docToPublish.public_url : editorForm.public_url}
              </span>
              . All students and users will immediately access this version.
            </div>
          </div>

          <p className="text-xs text-zinc-600">
            Document:{' '}
            <span className="font-bold text-zinc-900">
              {docToPublish ? docToPublish.title : editorForm.title}
            </span>
          </p>

          <div className="flex items-center justify-end gap-2 pt-3 border-t border-zinc-100">
            <Button
              variant="outline"
              onClick={() => {
                setPublishModalOpen(false);
                setDocToPublish(null);
              }}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={handleConfirmPublish}
              className="gap-2 bg-emerald-600 hover:bg-emerald-700"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Confirm & Publish</span>
            </Button>
          </div>
        </div>
      </Modal>

      {/* QUICK DOCUMENT READER / VIEWER MODAL */}
      <Modal
        isOpen={!!readerDoc}
        onClose={() => setReaderDoc(null)}
        title={readerDoc ? readerDoc.title : 'Legal Document View'}
        size="2xl"
      >
        {readerDoc && (
          <div className="space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-zinc-100">
              <div className="flex items-center gap-2">
                <Badge
                  variant={readerDoc.status === 'PUBLISHED' ? 'green' : 'amber'}
                  size="sm"
                >
                  {readerDoc.status}
                </Badge>
                <span className="text-xs font-mono text-zinc-500">
                  Route: {readerDoc.public_url}
                </span>
              </div>
              <div className="text-xs text-zinc-400">
                Last updated: {new Date(readerDoc.updated_at).toLocaleDateString()}
              </div>
            </div>

            <div className="max-h-[60vh] overflow-y-auto p-4 bg-zinc-50 rounded-lg text-xs leading-relaxed text-zinc-800 whitespace-pre-wrap font-sans">
              {readerDoc.content}
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-zinc-100">
              <button
                onClick={() => {
                  const doc = readerDoc;
                  setReaderDoc(null);
                  handleOpenEdit(doc);
                }}
                className="inline-flex items-center gap-1.5 text-xs font-medium text-indigo-600 hover:text-indigo-800"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Edit Document</span>
              </button>

              <Button
                variant="outline"
                size="sm"
                onClick={() => setReaderDoc(null)}
              >
                Close
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
