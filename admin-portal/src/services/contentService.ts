import { getSupabaseClient, getSupabaseCredentials } from '../lib/supabase';
import {
  getDemoCareerCategories,
  saveDemoCareerCategories,
  getDemoCareerPaths,
  saveDemoCareerPaths,
  getDemoCareerMilestones,
  saveDemoCareerMilestones,
} from '../lib/supabase';
import {
  CareerCategory,
  CareerPath,
  CareerMilestone,
  ContentStatus,
  ContentFilterParams,
  AdminUser,
} from '../types';
import { auditService } from './auditService';

export const contentService = {
  // ==========================================
  // CAREER CATEGORIES
  // ==========================================

  async getCareerCategories(params?: ContentFilterParams): Promise<CareerCategory[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        let query = supabase.from('career_categories').select('*, career_paths(count)');

        if (params?.status && params.status !== 'ALL') {
          query = query.eq('status', params.status);
        }
        if (params?.search) {
          query = query.or(`name.ilike.%${params.search}%,description.ilike.%${params.search}%`);
        }

        const { data, error } = await query.order('order', { ascending: true });
        if (error) throw error;
        if (data) {
          return data.map((c: any) => ({
            ...c,
            paths_count: c.career_paths?.[0]?.count || 0,
          }));
        }
      } catch (err) {
        console.error('Error fetching career categories from Supabase:', err);
      }
    }

    let categories = getDemoCareerCategories();
    if (params?.status && params.status !== 'ALL') {
      categories = categories.filter((c) => c.status === params.status);
    }
    if (params?.search) {
      const q = params.search.toLowerCase();
      categories = categories.filter(
        (c) => c.name.toLowerCase().includes(q) || (c.description && c.description.toLowerCase().includes(q))
      );
    }
    return categories.sort((a, b) => (a.order || 0) - (b.order || 0));
  },

  async createCareerCategory(
    data: Omit<CareerCategory, 'id' | 'created_at' | 'updated_at' | 'paths_count'>,
    admin?: AdminUser | null
  ): Promise<CareerCategory> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const newId = `cat-${Date.now()}`;

    const newCategory: CareerCategory = {
      id: newId,
      ...data,
      order: data.order ?? 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_categories')
          .insert({
            name: data.name,
            description: data.description,
            icon: data.icon,
            order: data.order ?? 1,
            status: data.status,
          })
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_CREATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_CATEGORY', id: dbData.id, name: dbData.name },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to create career category in Supabase:', err);
      }
    }

    const categories = getDemoCareerCategories();
    categories.push(newCategory);
    saveDemoCareerCategories(categories);

    await auditService.logAction(
      'CONTENT_CREATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_CATEGORY', id: newCategory.id, name: newCategory.name },
      admin?.email
    );

    return newCategory;
  },

  async updateCareerCategory(
    id: string,
    data: Partial<CareerCategory>,
    admin?: AdminUser | null
  ): Promise<CareerCategory> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_categories')
          .update({
            ...data,
            updated_at: new Date().toISOString(),
          })
          .eq('id', id)
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_UPDATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_CATEGORY', id, changes: data },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to update career category in Supabase:', err);
      }
    }

    const categories = getDemoCareerCategories();
    const idx = categories.findIndex((c) => c.id === id);
    if (idx === -1) throw new Error('Category not found');

    const updated = {
      ...categories[idx],
      ...data,
      updated_at: new Date().toISOString(),
    };
    categories[idx] = updated;
    saveDemoCareerCategories(categories);

    await auditService.logAction(
      'CONTENT_UPDATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_CATEGORY', id, changes: data },
      admin?.email
    );

    return updated;
  },

  async updateCareerCategoryStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerCategory> {
    return this.updateCareerCategory(id, { status }, admin);
  },

  async setCareerCategoryStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerCategory> {
    return this.updateCareerCategory(id, { status }, admin);
  },

  async canDeleteCareerCategory(id: string): Promise<{ canDelete: boolean; reason?: string }> {
    const paths = await this.getCareerPaths({ categoryId: id });
    if (paths.length > 0) {
      return {
        canDelete: false,
        reason: `This category contains ${paths.length} career path(s). Delete or reassign paths first.`,
      };
    }
    return { canDelete: true };
  },

  async deleteCareerCategory(id: string, admin?: AdminUser | null): Promise<void> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('career_categories').delete().eq('id', id);
        if (error) throw error;
      } catch (err) {
        console.error('Failed to delete career category in Supabase:', err);
      }
    }

    const categories = getDemoCareerCategories().filter((c) => c.id !== id);
    saveDemoCareerCategories(categories);

    await auditService.logAction(
      'CONTENT_DELETED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_CATEGORY', id },
      admin?.email
    );
  },

  async reorderCareerCategories(orderedIds: string[]): Promise<void> {
    const categories = getDemoCareerCategories();
    orderedIds.forEach((id, index) => {
      const c = categories.find((item) => item.id === id);
      if (c) c.order = index + 1;
    });
    saveDemoCareerCategories(categories);
  },

  // ==========================================
  // CAREER PATHS
  // ==========================================

  async getCareerPaths(params?: ContentFilterParams & { categoryId?: string }): Promise<CareerPath[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        let query = supabase.from('career_paths').select('*, career_categories(*), career_milestones(count)');

        if (params?.categoryId && params.categoryId !== 'ALL') {
          query = query.eq('category_id', params.categoryId);
        }
        if (params?.status && params.status !== 'ALL') {
          query = query.eq('status', params.status);
        }
        if (params?.search) {
          query = query.or(`name.ilike.%${params.search}%,description.ilike.%${params.search}%`);
        }

        const { data, error } = await query.order('order', { ascending: true });
        if (error) throw error;
        if (data) {
          return data.map((p: any) => ({
            ...p,
            category: p.career_categories,
            milestones_count: p.career_milestones?.[0]?.count || 0,
          }));
        }
      } catch (err) {
        console.error('Error fetching career paths from Supabase:', err);
      }
    }

    let paths = getDemoCareerPaths();
    const categories = getDemoCareerCategories();

    if (params?.categoryId && params.categoryId !== 'ALL') {
      paths = paths.filter((p) => p.category_id === params.categoryId);
    }
    if (params?.status && params.status !== 'ALL') {
      paths = paths.filter((p) => p.status === params.status);
    }
    if (params?.search) {
      const q = params.search.toLowerCase();
      paths = paths.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          (p.description && p.description.toLowerCase().includes(q))
      );
    }

    return paths
      .map((p) => ({
        ...p,
        category: categories.find((c) => c.id === p.category_id),
      }))
      .sort((a, b) => (a.order || 0) - (b.order || 0));
  },

  async createCareerPath(
    data: Omit<CareerPath, 'id' | 'created_at' | 'updated_at' | 'milestones_count' | 'category'>,
    admin?: AdminUser | null
  ): Promise<CareerPath> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const newId = `path-${Date.now()}`;

    const newPath: CareerPath = {
      id: newId,
      ...data,
      order: data.order ?? 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_paths')
          .insert({
            category_id: data.category_id,
            name: data.name,
            description: data.description,
            skills: data.skills,
            order: data.order ?? 1,
            status: data.status,
          })
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_CREATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_PATH', id: dbData.id, name: dbData.name },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to create career path in Supabase:', err);
      }
    }

    const paths = getDemoCareerPaths();
    paths.push(newPath);
    saveDemoCareerPaths(paths);

    await auditService.logAction(
      'CONTENT_CREATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_PATH', id: newPath.id, name: newPath.name },
      admin?.email
    );

    return newPath;
  },

  async updateCareerPath(
    id: string,
    data: Partial<CareerPath>,
    admin?: AdminUser | null
  ): Promise<CareerPath> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_paths')
          .update({
            ...data,
            updated_at: new Date().toISOString(),
          })
          .eq('id', id)
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_UPDATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_PATH', id, changes: data },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to update career path in Supabase:', err);
      }
    }

    const paths = getDemoCareerPaths();
    const idx = paths.findIndex((p) => p.id === id);
    if (idx === -1) throw new Error('Career path not found');

    const updated = {
      ...paths[idx],
      ...data,
      updated_at: new Date().toISOString(),
    };
    paths[idx] = updated;
    saveDemoCareerPaths(paths);

    await auditService.logAction(
      'CONTENT_UPDATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_PATH', id, changes: data },
      admin?.email
    );

    return updated;
  },

  async updateCareerPathStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerPath> {
    return this.updateCareerPath(id, { status }, admin);
  },

  async setCareerPathStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerPath> {
    return this.updateCareerPath(id, { status }, admin);
  },

  async canDeleteCareerPath(id: string): Promise<{ canDelete: boolean; reason?: string }> {
    const milestones = await this.getCareerMilestones({ pathId: id });
    if (milestones.length > 0) {
      return {
        canDelete: false,
        reason: `This career path contains ${milestones.length} milestone(s). Delete milestones first.`,
      };
    }
    return { canDelete: true };
  },

  async deleteCareerPath(id: string, admin?: AdminUser | null): Promise<void> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('career_paths').delete().eq('id', id);
        if (error) throw error;
      } catch (err) {
        console.error('Failed to delete career path in Supabase:', err);
      }
    }

    const paths = getDemoCareerPaths().filter((p) => p.id !== id);
    saveDemoCareerPaths(paths);

    await auditService.logAction(
      'CONTENT_DELETED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_PATH', id },
      admin?.email
    );
  },

  async reorderCareerPaths(orderedIds: string[]): Promise<void> {
    const paths = getDemoCareerPaths();
    orderedIds.forEach((id, index) => {
      const p = paths.find((item) => item.id === id);
      if (p) p.order = index + 1;
    });
    saveDemoCareerPaths(paths);
  },

  // ==========================================
  // CAREER MILESTONES
  // ==========================================

  async getCareerMilestones(params?: ContentFilterParams & { pathId?: string }): Promise<CareerMilestone[]> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        let query = supabase.from('career_milestones').select('*, career_paths(*)');

        if (params?.pathId && params.pathId !== 'ALL') {
          query = query.eq('career_path_id', params.pathId);
        }
        if (params?.status && params.status !== 'ALL') {
          query = query.eq('status', params.status);
        }
        if (params?.search) {
          query = query.or(`title.ilike.%${params.search}%,description.ilike.%${params.search}%`);
        }

        const { data, error } = await query.order('order', { ascending: true });
        if (error) throw error;
        if (data) {
          return data.map((m: any) => ({
            ...m,
            career_path: m.career_paths,
          }));
        }
      } catch (err) {
        console.error('Error fetching career milestones from Supabase:', err);
      }
    }

    let milestones = getDemoCareerMilestones();
    const paths = getDemoCareerPaths();

    if (params?.pathId && params.pathId !== 'ALL') {
      milestones = milestones.filter((m) => m.career_path_id === params.pathId);
    }
    if (params?.status && params.status !== 'ALL') {
      milestones = milestones.filter((m) => m.status === params.status);
    }
    if (params?.search) {
      const q = params.search.toLowerCase();
      milestones = milestones.filter(
        (m) => m.title.toLowerCase().includes(q) || (m.description && m.description.toLowerCase().includes(q))
      );
    }

    return milestones
      .map((m) => ({
        ...m,
        career_path: paths.find((p) => p.id === m.career_path_id),
      }))
      .sort((a, b) => (a.order || 0) - (b.order || 0));
  },

  async createCareerMilestone(
    data: Omit<CareerMilestone, 'id' | 'created_at' | 'updated_at' | 'career_path'>,
    admin?: AdminUser | null
  ): Promise<CareerMilestone> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();
    const newId = `ms-${Date.now()}`;

    const newMilestone: CareerMilestone = {
      id: newId,
      ...data,
      order: data.order ?? 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_milestones')
          .insert({
            career_path_id: data.career_path_id,
            title: data.title,
            description: data.description,
            order: data.order ?? 1,
            status: data.status,
          })
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_CREATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_MILESTONE', id: dbData.id, title: dbData.title },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to create career milestone in Supabase:', err);
      }
    }

    const milestones = getDemoCareerMilestones();
    milestones.push(newMilestone);
    saveDemoCareerMilestones(milestones);

    await auditService.logAction(
      'CONTENT_CREATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_MILESTONE', id: newMilestone.id, title: newMilestone.title },
      admin?.email
    );

    return newMilestone;
  },

  async updateCareerMilestone(
    id: string,
    data: Partial<CareerMilestone>,
    admin?: AdminUser | null
  ): Promise<CareerMilestone> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { data: dbData, error } = await supabase
          .from('career_milestones')
          .update({
            ...data,
            updated_at: new Date().toISOString(),
          })
          .eq('id', id)
          .select()
          .single();

        if (error) throw error;
        if (dbData) {
          await auditService.logAction(
            'CONTENT_UPDATED',
            undefined,
            admin?.id,
            { contentType: 'CAREER_MILESTONE', id, changes: data },
            admin?.email
          );
          return dbData;
        }
      } catch (err) {
        console.error('Failed to update career milestone in Supabase:', err);
      }
    }

    const milestones = getDemoCareerMilestones();
    const idx = milestones.findIndex((m) => m.id === id);
    if (idx === -1) throw new Error('Career milestone not found');

    const updated = {
      ...milestones[idx],
      ...data,
      updated_at: new Date().toISOString(),
    };
    milestones[idx] = updated;
    saveDemoCareerMilestones(milestones);

    await auditService.logAction(
      'CONTENT_UPDATED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_MILESTONE', id, changes: data },
      admin?.email
    );

    return updated;
  },

  async updateCareerMilestoneStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerMilestone> {
    return this.updateCareerMilestone(id, { status }, admin);
  },

  async setCareerMilestoneStatus(
    id: string,
    status: ContentStatus,
    admin?: AdminUser | null
  ): Promise<CareerMilestone> {
    return this.updateCareerMilestone(id, { status }, admin);
  },

  async deleteCareerMilestone(id: string, admin?: AdminUser | null): Promise<void> {
    const { isConfigured } = getSupabaseCredentials();
    const supabase = getSupabaseClient();

    if (isConfigured && supabase) {
      try {
        const { error } = await supabase.from('career_milestones').delete().eq('id', id);
        if (error) throw error;
      } catch (err) {
        console.error('Failed to delete career milestone in Supabase:', err);
      }
    }

    const milestones = getDemoCareerMilestones().filter((m) => m.id !== id);
    saveDemoCareerMilestones(milestones);

    await auditService.logAction(
      'CONTENT_DELETED',
      undefined,
      admin?.id,
      { contentType: 'CAREER_MILESTONE', id },
      admin?.email
    );
  },

  async reorderCareerMilestones(orderedIds: string[]): Promise<void> {
    const milestones = getDemoCareerMilestones();
    orderedIds.forEach((id, index) => {
      const m = milestones.find((item) => item.id === id);
      if (m) m.order = index + 1;
    });
    saveDemoCareerMilestones(milestones);
  },

  // ==========================================
  // AGGREGATE SUMMARY
  // ==========================================

  async getContentSummary(): Promise<{
    careerCategoriesCount: number;
    careerPathsCount: number;
    careerMilestonesCount: number;
    publishedCareerCount: number;
    draftCareerCount: number;
  }> {
    const [categories, paths, milestones] = await Promise.all([
      this.getCareerCategories(),
      this.getCareerPaths(),
      this.getCareerMilestones(),
    ]);

    const careerItems = [...categories, ...paths, ...milestones];

    return {
      careerCategoriesCount: categories.length,
      careerPathsCount: paths.length,
      careerMilestonesCount: milestones.length,
      publishedCareerCount: careerItems.filter((i) => i.status === 'PUBLISHED').length,
      draftCareerCount: careerItems.filter((i) => i.status === 'DRAFT').length,
    };
  },
};
