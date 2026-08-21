import React, { useState, useEffect } from 'react';
import {
  Shield,
  ArrowLeft,
  Calendar,
  Globe,
  ExternalLink,
  ChevronRight,
  Printer,
  FileText,
  AlertCircle,
  Edit3,
} from 'lucide-react';
import { LegalDocument } from '../../types';
import { legalService, REQUIRED_LEGAL_SLUGS } from '../../services/legalService';
import { useAuth } from '../../contexts/AuthContext';
import { Badge } from '../../components/common/Badge';
import { LoadingState } from '../../components/common/LoadingState';

interface PublicLegalPageProps {
  slug?: string;
  onNavigate?: (path: string) => void;
  onBackToAdmin?: () => void;
}

export const PublicLegalPage: React.FC<PublicLegalPageProps> = ({
  slug = 'privacy-policy',
  onNavigate,
  onBackToAdmin,
}) => {
  const { adminUser } = useAuth();
  const [loading, setLoading] = useState(true);
  const [currentDoc, setCurrentDoc] = useState<LegalDocument | null>(null);
  const [allDocs, setAllDocs] = useState<LegalDocument[]>([]);

  useEffect(() => {
    loadDocument(slug);
  }, [slug]);

  const loadDocument = async (targetSlug: string) => {
    try {
      setLoading(true);
      const [docs, doc] = await Promise.all([
        legalService.getAllDocuments(),
        legalService.getDocumentBySlug(targetSlug),
      ]);
      setAllDocs(docs);
      setCurrentDoc(doc);
    } catch (err) {
      console.error('Failed to load legal document:', err);
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  if (loading) {
    return <LoadingState message="Loading legal document..." />;
  }

  return (
    <div className="min-h-screen bg-zinc-50 flex flex-col text-zinc-900 font-sans antialiased">
      {/* Top Public Header */}
      <header className="sticky top-0 z-30 bg-white/95 backdrop-blur-md border-b border-zinc-200">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-zinc-900 text-white flex items-center justify-center font-black text-sm tracking-tighter shadow-xs">
              W
            </div>
            <div>
              <div className="text-sm font-bold tracking-wider text-zinc-900">WRINDHAOS</div>
              <div className="text-[10px] font-semibold tracking-widest text-zinc-400 uppercase">
                Legal & Trust Center
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={handlePrint}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 rounded-lg transition-colors"
              title="Print document"
            >
              <Printer className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Print Document</span>
            </button>

            {onBackToAdmin && (
              <button
                onClick={onBackToAdmin}
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-semibold text-white bg-zinc-900 hover:bg-zinc-800 rounded-lg transition-colors shadow-xs"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>Return to Admin</span>
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Content Layout */}
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8 flex-1 w-full flex flex-col md:flex-row gap-8">
        {/* Sidebar Document Navigation */}
        <aside className="w-full md:w-64 shrink-0">
          <div className="sticky top-24 space-y-4">
            <div className="p-3 bg-white rounded-xl border border-zinc-200 shadow-xs">
              <div className="text-xs font-bold uppercase tracking-wider text-zinc-400 px-3 py-2">
                Legal Documents
              </div>
              <nav className="space-y-1">
                {REQUIRED_LEGAL_SLUGS.map((item) => {
                  const docMatch = allDocs.find((d) => d.slug === item.slug);
                  const isCurrent =
                    currentDoc?.slug === item.slug ||
                    slug === item.slug ||
                    currentDoc?.public_url === item.defaultUrl;

                  return (
                    <button
                      key={item.slug}
                      onClick={() => {
                        if (onNavigate) {
                          onNavigate(item.defaultUrl);
                        } else {
                          loadDocument(item.slug);
                        }
                      }}
                      className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors text-left ${
                        isCurrent
                          ? 'bg-zinc-900 text-white font-semibold shadow-xs'
                          : 'text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900'
                      }`}
                    >
                      <div className="truncate pr-2">{item.title}</div>
                      {docMatch?.status === 'DRAFT' && !isCurrent && (
                        <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0" title="Draft" />
                      )}
                      {isCurrent && <ChevronRight className="w-3.5 h-3.5 shrink-0" />}
                    </button>
                  );
                })}
              </nav>
            </div>

            {/* Support info box */}
            <div className="p-4 bg-zinc-100/70 rounded-xl border border-zinc-200/80 text-xs text-zinc-600 space-y-2">
              <div className="font-semibold text-zinc-900 flex items-center gap-1.5">
                <Shield className="w-4 h-4 text-indigo-600" />
                <span>Questions or Inquiries?</span>
              </div>
              <p className="text-[11px] leading-relaxed text-zinc-500">
                Contact our compliance & privacy desk at{' '}
                <a
                  href="mailto:support@wrindhaos.in"
                  className="text-indigo-600 hover:underline font-medium"
                >
                  support@wrindhaos.in
                </a>
              </p>
            </div>
          </div>
        </aside>

        {/* Main Document Body */}
        <main className="flex-1 bg-white rounded-2xl border border-zinc-200 p-6 sm:p-10 shadow-xs min-h-[600px]">
          {currentDoc ? (
            <article className="space-y-6 max-w-3xl">
              {/* Draft Banner if applicable */}
              {currentDoc.status === 'DRAFT' && (
                <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-between gap-3 text-xs text-amber-900">
                  <div className="flex items-center gap-2.5">
                    <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />
                    <span>
                      <strong>Notice:</strong> This document is currently in <strong>Draft Status</strong> and undergoing review.
                    </span>
                  </div>
                  {onBackToAdmin && (
                    <button
                      onClick={onBackToAdmin}
                      className="px-2.5 py-1 rounded bg-amber-200/70 text-amber-900 font-semibold hover:bg-amber-300 transition-colors"
                    >
                      Edit in Admin
                    </button>
                  )}
                </div>
              )}

              {/* Document Header Metadata */}
              <div className="border-b border-zinc-100 pb-5">
                <div className="flex flex-wrap items-center justify-between gap-2 mb-2">
                  <Badge variant="blue" size="sm">
                    WrindhaOS Legal Disclosure
                  </Badge>
                  {currentDoc.version && (
                    <span className="text-xs font-mono text-zinc-400">
                      Version {currentDoc.version}
                    </span>
                  )}
                </div>
                <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-zinc-900">
                  {currentDoc.title}
                </h1>
                <div className="flex items-center gap-4 mt-2 text-xs text-zinc-400">
                  <div className="flex items-center gap-1.5">
                    <Calendar className="w-3.5 h-3.5" />
                    <span>Last updated: {new Date(currentDoc.updated_at).toLocaleDateString()}</span>
                  </div>
                  <div className="flex items-center gap-1.5 font-mono">
                    <Globe className="w-3.5 h-3.5" />
                    <span>https://wrindhaos.in{currentDoc.public_url}</span>
                  </div>
                </div>
              </div>

              {/* Document Content Rendering */}
              <div className="prose prose-zinc max-w-none text-zinc-700 leading-relaxed text-sm whitespace-pre-wrap font-sans">
                {currentDoc.content}
              </div>

              {/* Footer Notice */}
              <div className="pt-8 border-t border-zinc-100 text-xs text-zinc-400 flex flex-col sm:flex-row items-center justify-between gap-3">
                <span>© {new Date().getFullYear()} WrindhaOS Technologies India Pvt Ltd. All rights reserved.</span>
                <span className="text-[11px]">Published under official WrindhaOS Legal Terms</span>
              </div>
            </article>
          ) : (
            <div className="py-20 text-center space-y-3">
              <FileText className="w-12 h-12 text-zinc-300 mx-auto" />
              <h3 className="text-base font-semibold text-zinc-700">Document Not Found</h3>
              <p className="text-xs text-zinc-400 max-w-sm mx-auto">
                The requested legal document could not be located or has not been published yet.
              </p>
              {onBackToAdmin && (
                <button
                  onClick={onBackToAdmin}
                  className="mt-4 px-4 py-2 text-xs font-medium text-white bg-zinc-900 rounded-lg hover:bg-zinc-800"
                >
                  Return to Admin Panel
                </button>
              )}
            </div>
          )}
        </main>
      </div>
    </div>
  );
};
