import { LegalDocument, LegalSummaryStats, LegalDocumentSlug } from '../types';
import {
  getSupabaseClient,
  getSupabaseCredentials,
  getDemoLegalDocuments,
  saveDemoLegalDocuments,
} from '../lib/supabase';
import { auditService } from './auditService';
import { INITIAL_LEGAL_DOCUMENTS } from '../lib/defaultWebsiteAndLegalData';

export const REQUIRED_LEGAL_SLUGS: { slug: LegalDocumentSlug; title: string; defaultUrl: string }[] = [
  { slug: 'privacy-policy', title: 'Privacy Policy', defaultUrl: '/privacy-policy' },
  { slug: 'terms', title: 'Terms & Conditions', defaultUrl: '/terms' },
  { slug: 'refund-policy', title: 'Refund & Cancellation Policy', defaultUrl: '/refund-policy' },
  { slug: 'account-deletion', title: 'Account Deletion', defaultUrl: '/account-deletion' },
  { slug: 'contact', title: 'Contact / Grievance', defaultUrl: '/contact' },
  { slug: 'cookies', title: 'Cookie / Analytics Disclosure', defaultUrl: '/cookies' },
  { slug: 'copyright', title: 'Copyright / Intellectual Property Notice', defaultUrl: '/copyright' },
];

export const legalService = {
  /**
   * Returns all legal documents.
   */
  async getAllDocuments(): Promise<LegalDocument[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data, error } = await supabase
          .from('legal_documents')
          .select('*')
          .order('created_at', { ascending: true });

        if (error) {
          console.error('Error fetching legal documents from Supabase:', error);
        } else if (data && data.length > 0) {
          return data;
        }
      } catch (err) {
        console.error('Failed to read legal documents from Supabase, falling back:', err);
      }
    }

    return getDemoLegalDocuments();
  },

  /**
   * Retrieves a single document by slug (used for public routing and detail preview).
   */
  async getDocumentBySlug(slug: string): Promise<LegalDocument | null> {
    const docs = await this.getAllDocuments();
    return docs.find((d) => d.slug.toLowerCase() === slug.toLowerCase() || d.public_url === slug || d.public_url === `/${slug}`) || null;
  },

  /**
   * Retrieves a single document by ID.
   */
  async getDocumentById(id: string): Promise<LegalDocument | null> {
    const docs = await this.getAllDocuments();
    return docs.find((d) => d.id === id) || null;
  },

  /**
   * Computes dashboard-style legal summary metrics.
   */
  async getSummaryStats(): Promise<LegalSummaryStats> {
    const docs = await this.getAllDocuments();
    const totalRequired = REQUIRED_LEGAL_SLUGS.length; // 7

    const publishedDocs = docs.filter((d) => d.status === 'PUBLISHED');
    const publishedCount = publishedDocs.length;
    const draftCount = docs.filter((d) => d.status === 'DRAFT').length;

    // Check which of the 7 required are not published
    const missingDocuments: string[] = [];

    REQUIRED_LEGAL_SLUGS.forEach((req) => {
      const match = docs.find((d) => d.slug === req.slug);
      if (!match) {
        missingDocuments.push(`${req.title} (Missing)`);
      } else if (match.status !== 'PUBLISHED') {
        missingDocuments.push(`${req.title} (In Draft)`);
      }
    });

    const missingCount = missingDocuments.length;
    const allPublished = missingCount === 0 && publishedCount >= totalRequired;

    return {
      totalRequired,
      publishedCount,
      draftCount,
      missingCount,
      allPublished,
      missingDocuments,
    };
  },

  /**
   * Updates an existing legal document.
   */
  async updateDocument(
    id: string,
    updates: Partial<LegalDocument>,
    adminId: string,
    adminEmail: string
  ): Promise<LegalDocument> {
    const docs = await this.getAllDocuments();
    const index = docs.findIndex((d) => d.id === id);

    if (index === -1) {
      throw new Error(`Legal document with ID ${id} not found.`);
    }

    const previousDoc = docs[index];
    const updatedDoc: LegalDocument = {
      ...previousDoc,
      ...updates,
      updated_at: new Date().toISOString(),
      updated_by: adminId,
      updated_by_email: adminEmail,
    };

    const newDocs = [...docs];
    newDocs[index] = updatedDoc;

    await this.persistDocuments(newDocs);

    // Audit Log for status change or update
    if (updates.status && updates.status !== previousDoc.status) {
      const action = updates.status === 'PUBLISHED' ? 'LEGAL_DOCUMENT_PUBLISHED' : 'LEGAL_DOCUMENT_UNPUBLISHED';
      await auditService.logAction(
        action,
        undefined,
        adminId,
        {
          document_id: id,
          title: updatedDoc.title,
          slug: updatedDoc.slug,
          public_url: updatedDoc.public_url,
          status: updatedDoc.status,
        },
        adminEmail
      );
    } else {
      await auditService.logAction(
        'LEGAL_DOCUMENT_UPDATED',
        undefined,
        adminId,
        {
          document_id: id,
          title: updatedDoc.title,
          slug: updatedDoc.slug,
          public_url: updatedDoc.public_url,
        },
        adminEmail
      );
    }

    return updatedDoc;
  },

  /**
   * Quick action to publish a legal document.
   */
  async publishDocument(id: string, adminId: string, adminEmail: string): Promise<LegalDocument> {
    return this.updateDocument(id, { status: 'PUBLISHED' }, adminId, adminEmail);
  },

  /**
   * Quick action to set a document to draft.
   */
  async unpublishDocument(id: string, adminId: string, adminEmail: string): Promise<LegalDocument> {
    return this.updateDocument(id, { status: 'DRAFT' }, adminId, adminEmail);
  },

  /**
   * Creates a new legal document.
   */
  async createDocument(
    doc: Partial<LegalDocument>,
    adminId: string,
    adminEmail: string
  ): Promise<LegalDocument> {
    const docs = await this.getAllDocuments();
    const newDoc: LegalDocument = {
      id: `legal-${Date.now()}`,
      slug: doc.slug || `doc-${Date.now()}`,
      title: doc.title || 'Untitled Document',
      description: doc.description || '',
      content: doc.content || '# ' + (doc.title || 'Document Content') + '\n\nEnter legal text here...',
      status: doc.status || 'DRAFT',
      public_url: doc.public_url || `/${doc.slug || 'doc'}`,
      version: doc.version || '1.0.0',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      updated_by: adminId,
      updated_by_email: adminEmail,
    };

    const newDocs = [...docs, newDoc];
    await this.persistDocuments(newDocs);

    await auditService.logAction(
      'LEGAL_DOCUMENT_CREATED',
      undefined,
      adminId,
      {
        document_id: newDoc.id,
        title: newDoc.title,
        slug: newDoc.slug,
        status: newDoc.status,
      },
      adminEmail
    );

    return newDoc;
  },

  /**
   * Resets or seeds defaults if list is emptied.
   */
  async resetToDefaults(adminId: string, adminEmail: string): Promise<LegalDocument[]> {
    await this.persistDocuments(INITIAL_LEGAL_DOCUMENTS);
    await auditService.logAction(
      'LEGAL_DOCUMENT_UPDATED',
      undefined,
      adminId,
      { action: 'RESET_TO_INITIAL_LEGAL_DEFAULTS' },
      adminEmail
    );
    return INITIAL_LEGAL_DOCUMENTS;
  },

  /**
   * Persists legal documents list.
   */
  async persistDocuments(docs: LegalDocument[]): Promise<void> {
    saveDemoLegalDocuments(docs);

    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        // Upsert all documents
        const { error } = await supabase.from('legal_documents').upsert(
          docs.map((d) => ({
            id: d.id,
            slug: d.slug,
            title: d.title,
            description: d.description,
            content: d.content,
            status: d.status,
            public_url: d.public_url,
            version: d.version,
            created_at: d.created_at,
            updated_at: d.updated_at,
            updated_by: d.updated_by,
          }))
        );

        if (error) {
          console.error('Failed to persist legal documents to Supabase:', error);
        }
      } catch (err) {
        console.error('Error writing legal docs to Supabase:', err);
      }
    }
  },
};
