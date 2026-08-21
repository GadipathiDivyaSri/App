import React, { useState, useEffect, useMemo } from 'react';
import {
  CareerCategory,
  CareerPath,
  CareerMilestone,
  ContentStatus,
} from '../../types';
import { contentService } from '../../services/contentService';
import { useAuth } from '../../contexts/AuthContext';
import { ContentStatusBadge } from '../../components/admin/ContentStatusBadge';
import { PublishConfirmModal } from '../../components/admin/PublishConfirmModal';
import { DeleteProtectionModal } from '../../components/admin/DeleteProtectionModal';
import { ContentPreviewModal } from '../../components/admin/ContentPreviewModal';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Modal } from '../../components/common/Modal';
import { Card } from '../../components/common/Card';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '../../components/common/Table';
import { EmptyState } from '../../components/common/EmptyState';
import { LoadingState } from '../../components/common/LoadingState';
import {
  Compass,
  Briefcase,
  Plus,
  Search,
  ArrowUp,
  ArrowDown,
  Eye,
  Edit2,
  Trash2,
  CheckCircle2,
  Archive,
  ChevronRight,
  ChevronLeft,
  AlertCircle,
  Settings2,
  Globe2,
  Flag,
  Sparkles,
  X,
} from 'lucide-react';

interface CareerContentPageProps {
  onNavigate?: (path: string) => void;
}

export const CareerContentPage: React.FC<CareerContentPageProps> = () => {
  const { adminUser } = useAuth();

  // State
  const [categories, setCategories] = useState<CareerCategory[]>([]);
  const [paths, setPaths] = useState<CareerPath[]>([]);
  const [milestones, setMilestones] = useState<CareerMilestone[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<ContentStatus | 'ALL'>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Active Career Path Detail View (Deep Hierarchy: Path -> Milestones)
  const [activePath, setActivePath] = useState<CareerPath | null>(null);

  // Modals state
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<CareerCategory | null>(null);
  const [categoryForm, setCategoryForm] = useState({
    name: '',
    description: '',
    icon: 'Briefcase',
    status: 'DRAFT' as ContentStatus,
  });

  const [isPathModalOpen, setIsPathModalOpen] = useState(false);
  const [editingPath, setEditingPath] = useState<CareerPath | null>(null);
  const [pathForm, setPathForm] = useState({
    category_id: '',
    name: '',
    description: '',
    skillsInput: '',
    status: 'DRAFT' as ContentStatus,
  });

  const [isMilestoneModalOpen, setIsMilestoneModalOpen] = useState(false);
  const [editingMilestone, setEditingMilestone] = useState<CareerMilestone | null>(null);
  const [milestoneForm, setMilestoneForm] = useState({
    title: '',
    description: '',
    status: 'DRAFT' as ContentStatus,
  });

  // Manage Categories Drawer / Modal
  const [isCategoriesManagerOpen, setIsCategoriesManagerOpen] = useState(false);

  // Publish confirmation modal
  const [publishTarget, setPublishTarget] = useState<{
    type: 'category' | 'path' | 'milestone';
    id: string;
    name: string;
  } | null>(null);

  // Delete protection modal
  const [deleteBlockedInfo, setDeleteBlockedInfo] = useState<{
    itemType: string;
    itemName: string;
    reason: string;
  } | null>(null);

  // App Roadmap Preview modal
  const [previewPath, setPreviewPath] = useState<CareerPath | null>(null);

  // Feedback Toast
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const [fetchedCats, fetchedPaths, fetchedMilestones] = await Promise.all([
        contentService.getCareerCategories(),
        contentService.getCareerPaths(),
        contentService.getCareerMilestones(),
      ]);

      setCategories(fetchedCats);
      setPaths(fetchedPaths);
      setMilestones(fetchedMilestones);

      if (activePath) {
        const refreshedPath = fetchedPaths.find((p) => p.id === activePath.id);
        setActivePath(refreshedPath || null);
      }
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to load career content.' });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Filtered Career Paths
  const filteredPaths = useMemo(() => {
    return paths.filter((p) => {
      if (selectedCategoryId !== 'ALL' && p.category_id !== selectedCategoryId) return false;
      if (selectedStatus !== 'ALL' && p.status !== selectedStatus) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesName = p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q);
        const matchesSkill = p.skills?.some((s) => s.toLowerCase().includes(q));
        const pathMilestones = milestones.filter((m) => m.career_path_id === p.id);
        const matchesMilestone = pathMilestones.some((m) => m.title.toLowerCase().includes(q));
        return matchesName || matchesSkill || matchesMilestone;
      }
      return true;
    });
  }, [paths, selectedCategoryId, selectedStatus, searchQuery, milestones]);

  // Quick stats
  const stats = useMemo(() => {
    const totalCategories = categories.length;
    const totalPaths = paths.length;
    const totalMilestones = milestones.length;
    const publishedPaths = paths.filter((p) => p.status === 'PUBLISHED').length;
    const draftPaths = paths.filter((p) => p.status === 'DRAFT').length;

    return { totalCategories, totalPaths, totalMilestones, publishedPaths, draftPaths };
  }, [categories, paths, milestones]);

  // ==========================================
  // CAREER PATH ACTIONS
  // ==========================================

  const handleOpenCreatePath = () => {
    setEditingPath(null);
    setPathForm({
      category_id: categories[0]?.id || '',
      name: '',
      description: '',
      skillsInput: '',
      status: 'DRAFT',
    });
    setIsPathModalOpen(true);
  };

  const handleOpenEditPath = (path: CareerPath) => {
    setEditingPath(path);
    setPathForm({
      category_id: path.category_id,
      name: path.name,
      description: path.description || '',
      skillsInput: (path.skills || []).join(', '),
      status: path.status,
    });
    setIsPathModalOpen(true);
  };

  const handleSavePath = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pathForm.name.trim()) return;

    const parsedSkills = pathForm.skillsInput
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    try {
      if (editingPath) {
        await contentService.updateCareerPath(
          editingPath.id,
          {
            category_id: pathForm.category_id,
            name: pathForm.name.trim(),
            description: pathForm.description.trim(),
            skills: parsedSkills,
            status: pathForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Career Path "${pathForm.name}" updated.` });
      } else {
        await contentService.createCareerPath(
          {
            category_id: pathForm.category_id,
            name: pathForm.name.trim(),
            description: pathForm.description.trim(),
            skills: parsedSkills,
            order: paths.length + 1,
            status: pathForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Career Path "${pathForm.name}" created.` });
      }

      setIsPathModalOpen(false);
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to save career path.' });
    }
  };

  const handleDeletePath = async (path: CareerPath) => {
    const check = await contentService.canDeleteCareerPath(path.id);
    if (!check.canDelete) {
      setDeleteBlockedInfo({
        itemType: 'Career Path',
        itemName: path.name,
        reason: check.reason || 'Contains active career milestones.',
      });
      return;
    }

    if (!window.confirm(`Delete career path "${path.name}"?`)) return;

    try {
      await contentService.deleteCareerPath(path.id, adminUser);
      setFeedback({ type: 'success', message: `Career path "${path.name}" deleted.` });
      if (activePath?.id === path.id) setActivePath(null);
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to delete career path.' });
    }
  };

  const handleStatusChange = async (type: 'category' | 'path' | 'milestone', id: string, status: ContentStatus) => {
    try {
      if (type === 'path') await contentService.setCareerPathStatus(id, status, adminUser);
      if (type === 'category') await contentService.setCareerCategoryStatus(id, status, adminUser);
      if (type === 'milestone') await contentService.setCareerMilestoneStatus(id, status, adminUser);

      setFeedback({ type: 'success', message: `Status updated to ${status}.` });
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to update status.' });
    }
  };

  const handleMovePath = async (path: CareerPath, direction: 'up' | 'down') => {
    const currentList = [...filteredPaths];
    const index = currentList.findIndex((p) => p.id === path.id);
    if (index === -1) return;
    if (direction === 'up' && index === 0) return;
    if (direction === 'down' && index === currentList.length - 1) return;

    const swapIndex = direction === 'up' ? index - 1 : index + 1;
    const temp = currentList[index];
    currentList[index] = currentList[swapIndex];
    currentList[swapIndex] = temp;

    await contentService.reorderCareerPaths(currentList.map((p) => p.id));
    await loadData();
  };

  // ==========================================
  // MILESTONE ACTIONS
  // ==========================================

  const handleOpenCreateMilestone = () => {
    setEditingMilestone(null);
    setMilestoneForm({ title: '', description: '', status: 'DRAFT' });
    setIsMilestoneModalOpen(true);
  };

  const handleOpenEditMilestone = (ms: CareerMilestone) => {
    setEditingMilestone(ms);
    setMilestoneForm({ title: ms.title, description: ms.description || '', status: ms.status });
    setIsMilestoneModalOpen(true);
  };

  const handleSaveMilestone = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activePath || !milestoneForm.title.trim()) return;

    try {
      if (editingMilestone) {
        await contentService.updateCareerMilestone(
          editingMilestone.id,
          {
            title: milestoneForm.title.trim(),
            description: milestoneForm.description.trim(),
            status: milestoneForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Milestone "${milestoneForm.title}" updated.` });
      } else {
        await contentService.createCareerMilestone(
          {
            career_path_id: activePath.id,
            title: milestoneForm.title.trim(),
            description: milestoneForm.description.trim(),
            order: milestones.filter((m) => m.career_path_id === activePath.id).length + 1,
            status: milestoneForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Milestone "${milestoneForm.title}" created.` });
      }

      setIsMilestoneModalOpen(false);
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to save milestone.' });
    }
  };

  const handleDeleteMilestone = async (ms: CareerMilestone) => {
    if (!window.confirm(`Delete milestone "${ms.title}"?`)) return;

    try {
      await contentService.deleteCareerMilestone(ms.id, adminUser);
      setFeedback({ type: 'success', message: `Milestone "${ms.title}" deleted.` });
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to delete milestone.' });
    }
  };

  const handleMoveMilestone = async (msList: CareerMilestone[], ms: CareerMilestone, direction: 'up' | 'down') => {
    const index = msList.findIndex((m) => m.id === ms.id);
    if (index === -1) return;
    if (direction === 'up' && index === 0) return;
    if (direction === 'down' && index === msList.length - 1) return;

    const current = [...msList];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;
    const temp = current[index];
    current[index] = current[swapIndex];
    current[swapIndex] = temp;

    await contentService.reorderCareerMilestones(current.map((m) => m.id));
    await loadData();
  };

  // ==========================================
  // CATEGORIES MANAGEMENT
  // ==========================================

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoryForm.name.trim()) return;

    try {
      if (editingCategory) {
        await contentService.updateCareerCategory(
          editingCategory.id,
          {
            name: categoryForm.name.trim(),
            description: categoryForm.description.trim(),
            status: categoryForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Career Category "${categoryForm.name}" updated.` });
      } else {
        await contentService.createCareerCategory(
          {
            name: categoryForm.name.trim(),
            description: categoryForm.description.trim(),
            order: categories.length + 1,
            status: categoryForm.status,
          },
          adminUser
        );
        setFeedback({ type: 'success', message: `Career Category "${categoryForm.name}" created.` });
      }

      setIsCategoryModalOpen(false);
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to save career category.' });
    }
  };

  const handleDeleteCategory = async (cat: CareerCategory) => {
    const check = await contentService.canDeleteCareerCategory(cat.id);
    if (!check.canDelete) {
      setDeleteBlockedInfo({
        itemType: 'Career Category',
        itemName: cat.name,
        reason: check.reason || 'Contains active career paths.',
      });
      return;
    }

    if (!window.confirm(`Delete career category "${cat.name}"?`)) return;

    try {
      await contentService.deleteCareerCategory(cat.id, adminUser);
      setFeedback({ type: 'success', message: `Category "${cat.name}" deleted.` });
      await loadData();
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Failed to delete category.' });
    }
  };

  // Preview Data Helper
  const previewData = useMemo(() => {
    if (!previewPath) return null;
    const pathMilestones = milestones.filter((m) => m.career_path_id === previewPath.id);
    return {
      path: previewPath,
      milestones: pathMilestones,
    };
  }, [previewPath, milestones]);

  return (
    <div className="space-y-6">
      {/* Toast Feedback */}
      {feedback && (
        <div
          className={`p-4 rounded-xl flex items-center justify-between shadow-xs ${
            feedback.type === 'success'
              ? 'bg-emerald-50 border border-emerald-200 text-emerald-900'
              : 'bg-rose-50 border border-rose-200 text-rose-900'
          }`}
        >
          <div className="flex items-center gap-2.5 text-xs font-semibold">
            {feedback.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
            )}
            <span>{feedback.message}</span>
          </div>
          <button
            type="button"
            onClick={() => setFeedback(null)}
            className="text-xs font-bold text-zinc-500 hover:text-zinc-800"
          >
            ✕
          </button>
        </div>
      )}

      {/* ==========================================
          HEADER & BREADCRUMBS
      ========================================== */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs text-zinc-500 font-medium mb-1">
            <span className="text-zinc-900 font-bold">App Content</span>
            <ChevronRight className="w-3.5 h-3.5 text-zinc-400" />
            <span
              className={activePath ? 'text-zinc-600 cursor-pointer hover:underline' : 'text-zinc-900 font-bold'}
              onClick={() => setActivePath(null)}
            >
              Career Content
            </span>
            {activePath && (
              <>
                <ChevronRight className="w-3.5 h-3.5 text-zinc-400" />
                <span className="text-zinc-900 font-bold">{activePath.name}</span>
              </>
            )}
          </div>
          <h1 className="text-2xl font-black tracking-tight text-zinc-900">
            {activePath ? activePath.name : 'Career Categories & Roadmaps'}
          </h1>
          <p className="text-xs text-zinc-500 mt-1 max-w-2xl">
            {activePath
              ? `Manage milestone steps, skill requirements, and roadmap stages for ${activePath.name}.`
              : 'Organize career categories, professional paths, and step-by-step milestones for student career guidance.'}
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          {activePath ? (
            <>
              <Button variant="outline" size="sm" onClick={() => setActivePath(null)}>
                <ChevronLeft className="w-4 h-4 mr-1" />
                Back to Paths
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPreviewPath(activePath)}
              >
                <Eye className="w-4 h-4 mr-1.5 text-zinc-500" />
                Preview in App
              </Button>
              <Button variant="primary" size="sm" onClick={handleOpenCreateMilestone}>
                <Flag className="w-4 h-4 mr-1.5" />
                Add Milestone
              </Button>
            </>
          ) : (
            <>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsCategoriesManagerOpen(true)}
              >
                <Settings2 className="w-4 h-4 mr-1.5 text-zinc-500" />
                Manage Categories
              </Button>
              <Button variant="primary" size="sm" onClick={handleOpenCreatePath}>
                <Plus className="w-4 h-4 mr-1.5" />
                Add Career Path
              </Button>
            </>
          )}
        </div>
      </div>

      {/* ==========================================
          QUICK STATS PILLS
      ========================================== */}
      {!activePath && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <Card className="p-3.5">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
              Career Categories
            </div>
            <div className="text-xl font-bold text-zinc-900 mt-1">{stats.totalCategories}</div>
          </Card>
          <Card className="p-3.5">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
              Career Paths
            </div>
            <div className="text-xl font-bold text-zinc-900 mt-1">{stats.totalPaths}</div>
          </Card>
          <Card className="p-3.5">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
              Total Milestones
            </div>
            <div className="text-xl font-bold text-zinc-900 mt-1">{stats.totalMilestones}</div>
          </Card>
          <Card className="p-3.5">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
              Published Status
            </div>
            <div className="flex items-center gap-2 mt-1 text-xs font-bold">
              <span className="text-emerald-700">{stats.publishedPaths} Live</span>
              <span className="text-zinc-300">•</span>
              <span className="text-amber-600">{stats.draftPaths} Draft</span>
            </div>
          </Card>
        </div>
      )}

      {/* ==========================================
          MAIN VIEW: PATHS LIST OR MILESTONES MANAGER
      ========================================== */}
      {isLoading ? (
        <Card className="p-12 text-center">
          <LoadingState message="Loading career paths and roadmaps..." />
        </Card>
      ) : activePath ? (
        /* ==========================================
           CAREER PATH DETAIL VIEW (MILESTONES MANAGER)
        ========================================== */
        <div className="space-y-6">
          {/* Path Metadata Card */}
          <Card className="p-5 border-zinc-200">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-start gap-3.5">
                <div className="w-12 h-12 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-700 flex items-center justify-center font-bold">
                  <Compass className="w-6 h-6" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold uppercase tracking-wider px-2 py-0.5 rounded bg-zinc-100 text-zinc-700">
                      {activePath.category?.name || 'General Category'}
                    </span>
                    <ContentStatusBadge status={activePath.status} />
                  </div>
                  <h2 className="text-lg font-bold text-zinc-900 mt-1">{activePath.name}</h2>
                  {activePath.description && (
                    <p className="text-xs text-zinc-600 mt-1">{activePath.description}</p>
                  )}

                  {/* Skills tags */}
                  {activePath.skills && activePath.skills.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 mt-2.5">
                      {activePath.skills.map((skill, idx) => (
                        <span
                          key={idx}
                          className="text-[11px] font-medium bg-emerald-50 text-emerald-800 border border-emerald-200/80 px-2 py-0.5 rounded-md"
                        >
                          {skill}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleOpenEditPath(activePath)}
                >
                  <Edit2 className="w-3.5 h-3.5 mr-1" />
                  Edit Path
                </Button>
                {activePath.status !== 'PUBLISHED' ? (
                  <Button
                    variant="primary"
                    size="sm"
                    className="bg-emerald-600 hover:bg-emerald-700"
                    onClick={() =>
                      setPublishTarget({
                        type: 'path',
                        id: activePath.id,
                        name: activePath.name,
                      })
                    }
                  >
                    <CheckCircle2 className="w-3.5 h-3.5 mr-1" />
                    Publish
                  </Button>
                ) : (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusChange('path', activePath.id, 'DRAFT')}
                  >
                    Unpublish
                  </Button>
                )}
              </div>
            </div>
          </Card>

          {/* Milestones List */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold uppercase tracking-wider text-zinc-700">
                Sequential Milestones & Stages ({milestones.filter((m) => m.career_path_id === activePath.id).length} Steps)
              </h3>
              <Button variant="outline" size="sm" onClick={handleOpenCreateMilestone}>
                <Plus className="w-3.5 h-3.5 mr-1" />
                Add Milestone
              </Button>
            </div>

            {milestones.filter((m) => m.career_path_id === activePath.id).length === 0 ? (
              <EmptyState
                icon={Flag}
                title="No Milestones Added"
                description="Create step-by-step career milestones (e.g. Master Core Algorithms, System Design Fundamentals, Build Capstone Project)."
                action={
                  <Button variant="primary" size="sm" onClick={handleOpenCreateMilestone}>
                    <Plus className="w-4 h-4 mr-1" />
                    Add First Milestone
                  </Button>
                }
              />
            ) : (
              <div className="relative pl-6 space-y-3 before:absolute before:left-2.5 before:top-3 before:bottom-3 before:w-0.5 before:bg-emerald-200">
                {milestones
                  .filter((m) => m.career_path_id === activePath.id)
                  .map((ms, idx, msArr) => (
                    <Card
                      key={ms.id}
                      className="relative p-4 border-zinc-200 hover:border-zinc-300 transition-colors"
                    >
                      {/* Timeline Dot */}
                      <div className="absolute -left-6 top-5 w-4 h-4 rounded-full bg-emerald-600 border-2 border-white shadow-xs" />

                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <div className="flex items-start gap-3">
                          <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-800 font-bold text-xs flex items-center justify-center shrink-0">
                            {idx + 1}
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <h4 className="text-sm font-bold text-zinc-900">{ms.title}</h4>
                              <ContentStatusBadge status={ms.status} size="sm" />
                            </div>
                            {ms.description && (
                              <p className="text-xs text-zinc-600 mt-1 leading-relaxed">
                                {ms.description}
                              </p>
                            )}
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5 self-end sm:self-auto shrink-0">
                          {/* Reorder Buttons */}
                          <button
                            type="button"
                            onClick={() => handleMoveMilestone(msArr, ms, 'up')}
                            disabled={idx === 0}
                            className="p-1 rounded hover:bg-zinc-100 disabled:opacity-30 text-zinc-500"
                            title="Move Up"
                          >
                            <ArrowUp className="w-3.5 h-3.5" />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleMoveMilestone(msArr, ms, 'down')}
                            disabled={idx === msArr.length - 1}
                            className="p-1 rounded hover:bg-zinc-100 disabled:opacity-30 text-zinc-500"
                            title="Move Down"
                          >
                            <ArrowDown className="w-3.5 h-3.5" />
                          </button>

                          <div className="h-4 w-px bg-zinc-200 mx-1" />

                          <button
                            type="button"
                            onClick={() => handleOpenEditMilestone(ms)}
                            className="p-1.5 rounded hover:bg-zinc-100 text-zinc-600"
                            title="Edit Milestone"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>

                          {ms.status !== 'PUBLISHED' ? (
                            <button
                              type="button"
                              onClick={() => handleStatusChange('milestone', ms.id, 'PUBLISHED')}
                              className="p-1.5 rounded hover:bg-emerald-50 text-emerald-600"
                              title="Publish Milestone"
                            >
                              <Globe2 className="w-3.5 h-3.5" />
                            </button>
                          ) : (
                            <button
                              type="button"
                              onClick={() => handleStatusChange('milestone', ms.id, 'DRAFT')}
                              className="p-1.5 rounded hover:bg-zinc-100 text-zinc-500"
                              title="Unpublish Milestone"
                            >
                              <Archive className="w-3.5 h-3.5" />
                            </button>
                          )}

                          <button
                            type="button"
                            onClick={() => handleDeleteMilestone(ms)}
                            className="p-1.5 rounded hover:bg-rose-50 text-rose-600"
                            title="Delete Milestone"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    </Card>
                  ))}
              </div>
            )}
          </div>
        </div>
      ) : (
        /* ==========================================
           ALL CAREER PATHS TABLE & FILTERS
        ========================================== */
        <div className="space-y-4">
          {/* Filters Bar */}
          <Card className="p-4">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Search */}
              <div className="relative">
                <Search className="w-4 h-4 text-zinc-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <Input
                  type="text"
                  placeholder="Search career paths, skills, milestones..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 text-xs"
                />
              </div>

              {/* Category Filter */}
              <div>
                <select
                  value={selectedCategoryId}
                  onChange={(e) => setSelectedCategoryId(e.target.value)}
                  className="w-full h-9 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-800 font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
                >
                  <option value="ALL">All Categories ({categories.length})</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Status Filter */}
              <div>
                <select
                  value={selectedStatus}
                  onChange={(e) => setSelectedStatus(e.target.value as ContentStatus | 'ALL')}
                  className="w-full h-9 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-800 font-medium focus:outline-none focus:ring-2 focus:ring-zinc-900"
                >
                  <option value="ALL">All Statuses</option>
                  <option value="PUBLISHED">Published Only</option>
                  <option value="DRAFT">Draft Only</option>
                  <option value="ARCHIVED">Archived Only</option>
                </select>
              </div>
            </div>
          </Card>

          {/* Paths Table */}
          <Card className="overflow-hidden">
            {filteredPaths.length === 0 ? (
              <EmptyState
                icon={Compass}
                title="No Career Paths Found"
                description={
                  searchQuery || selectedCategoryId !== 'ALL' || selectedStatus !== 'ALL'
                    ? 'No career paths matched your filter criteria.'
                    : 'Start by creating your first career roadmap and milestone progression.'
                }
                action={
                  <Button variant="primary" size="sm" onClick={handleOpenCreatePath}>
                    <Plus className="w-4 h-4 mr-1" />
                    Create Career Path
                  </Button>
                }
              />
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12 text-center">#</TableHead>
                    <TableHead>Career Path</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Required Skills</TableHead>
                    <TableHead>Milestones</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPaths.map((path, idx) => {
                    const pathMilestones = milestones.filter((m) => m.career_path_id === path.id);

                    return (
                      <TableRow key={path.id}>
                        {/* Order & Move Buttons */}
                        <TableCell className="text-center">
                          <div className="flex flex-col items-center gap-0.5">
                            <button
                              type="button"
                              onClick={() => handleMovePath(path, 'up')}
                              disabled={idx === 0}
                              className="p-0.5 hover:bg-zinc-100 rounded text-zinc-400 hover:text-zinc-700 disabled:opacity-20"
                            >
                              <ArrowUp className="w-3 h-3" />
                            </button>
                            <span className="text-[11px] font-mono font-bold text-zinc-600">
                              {path.order}
                            </span>
                            <button
                              type="button"
                              onClick={() => handleMovePath(path, 'down')}
                              disabled={idx === filteredPaths.length - 1}
                              className="p-0.5 hover:bg-zinc-100 rounded text-zinc-400 hover:text-zinc-700 disabled:opacity-20"
                            >
                              <ArrowDown className="w-3 h-3" />
                            </button>
                          </div>
                        </TableCell>

                        {/* Path Name & Description */}
                        <TableCell>
                          <div
                            onClick={() => setActivePath(path)}
                            className="cursor-pointer group"
                          >
                            <div className="text-xs font-bold text-zinc-900 group-hover:text-emerald-600 transition-colors">
                              {path.name}
                            </div>
                            {path.description && (
                              <p className="text-[11px] text-zinc-500 line-clamp-1 mt-0.5">
                                {path.description}
                              </p>
                            )}
                          </div>
                        </TableCell>

                        {/* Category */}
                        <TableCell>
                          <span className="text-xs font-semibold text-zinc-800">
                            {path.category?.name || 'General'}
                          </span>
                        </TableCell>

                        {/* Skills */}
                        <TableCell>
                          <div className="flex flex-wrap gap-1 max-w-xs">
                            {path.skills && path.skills.length > 0 ? (
                              path.skills.slice(0, 3).map((skill, sIdx) => (
                                <span
                                  key={sIdx}
                                  className="text-[10px] bg-emerald-50 text-emerald-800 border border-emerald-200 px-1.5 py-0.2 rounded font-medium"
                                >
                                  {skill}
                                </span>
                              ))
                            ) : (
                              <span className="text-[11px] text-zinc-400 italic">None set</span>
                            )}
                            {path.skills && path.skills.length > 3 && (
                              <span className="text-[10px] text-zinc-500">
                                +{path.skills.length - 3} more
                              </span>
                            )}
                          </div>
                        </TableCell>

                        {/* Milestones count */}
                        <TableCell>
                          <div
                            onClick={() => setActivePath(path)}
                            className="inline-flex items-center gap-1.5 cursor-pointer text-xs font-semibold text-zinc-700 hover:text-emerald-600"
                          >
                            <span className="px-2 py-0.5 rounded bg-zinc-100 text-zinc-800 font-bold">
                              {pathMilestones.length} Steps
                            </span>
                          </div>
                        </TableCell>

                        {/* Status */}
                        <TableCell>
                          <ContentStatusBadge status={path.status} />
                        </TableCell>

                        {/* Actions */}
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <Button
                              variant="outline"
                              size="sm"
                              className="h-8 text-xs"
                              onClick={() => setActivePath(path)}
                            >
                              Manage Roadmap
                              <ChevronRight className="w-3.5 h-3.5 ml-1" />
                            </Button>

                            <button
                              type="button"
                              onClick={() => setPreviewPath(path)}
                              className="p-2 rounded-lg hover:bg-zinc-100 text-zinc-600"
                              title="Preview Roadmap"
                            >
                              <Eye className="w-4 h-4" />
                            </button>

                            <button
                              type="button"
                              onClick={() => handleOpenEditPath(path)}
                              className="p-2 rounded-lg hover:bg-zinc-100 text-zinc-600"
                              title="Edit Path"
                            >
                              <Edit2 className="w-4 h-4" />
                            </button>

                            {path.status !== 'PUBLISHED' ? (
                              <button
                                type="button"
                                onClick={() =>
                                  setPublishTarget({
                                    type: 'path',
                                    id: path.id,
                                    name: path.name,
                                  })
                                }
                                className="p-2 rounded-lg hover:bg-emerald-50 text-emerald-600"
                                title="Publish"
                              >
                                <Globe2 className="w-4 h-4" />
                              </button>
                            ) : (
                              <button
                                type="button"
                                onClick={() => handleStatusChange('path', path.id, 'DRAFT')}
                                className="p-2 rounded-lg hover:bg-zinc-100 text-zinc-500"
                                title="Unpublish"
                              >
                                <Archive className="w-4 h-4" />
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={() => handleDeletePath(path)}
                              className="p-2 rounded-lg hover:bg-rose-50 text-rose-600"
                              title="Delete Path"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </Card>
        </div>
      )}

      {/* ==========================================
          MODALS
      ========================================== */}

      {/* 1. Create/Edit Career Path Modal */}
      <Modal
        isOpen={isPathModalOpen}
        onClose={() => setIsPathModalOpen(false)}
        title={editingPath ? 'Edit Career Path' : 'Add New Career Path'}
        maxWidth="max-w-lg"
      >
        <form onSubmit={handleSavePath} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Career Category <span className="text-rose-500">*</span>
            </label>
            <select
              value={pathForm.category_id}
              onChange={(e) => setPathForm({ ...pathForm, category_id: e.target.value })}
              required
              className="w-full h-10 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900"
            >
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Career Path Name <span className="text-rose-500">*</span>
            </label>
            <Input
              type="text"
              required
              placeholder="e.g. Full Stack Engineer, IAS Officer, Product Manager"
              value={pathForm.name}
              onChange={(e) => setPathForm({ ...pathForm, name: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Description (Optional)
            </label>
            <textarea
              rows={2}
              placeholder="Overview of this career direction and growth trajectory..."
              value={pathForm.description}
              onChange={(e) => setPathForm({ ...pathForm, description: e.target.value })}
              className="w-full rounded-lg border border-zinc-200 p-2.5 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Required Skills (Comma separated)
            </label>
            <Input
              type="text"
              placeholder="e.g. TypeScript, React, SQL, Cloud Architecture"
              value={pathForm.skillsInput}
              onChange={(e) => setPathForm({ ...pathForm, skillsInput: e.target.value })}
            />
            <span className="text-[11px] text-zinc-400">Separate multiple skills with commas</span>
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Publish Status
            </label>
            <select
              value={pathForm.status}
              onChange={(e) => setPathForm({ ...pathForm, status: e.target.value as ContentStatus })}
              className="w-full h-10 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900"
            >
              <option value="DRAFT">DRAFT (Admin Only)</option>
              <option value="PUBLISHED">PUBLISHED (Live for Students)</option>
              <option value="ARCHIVED">ARCHIVED</option>
            </select>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setIsPathModalOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="primary" size="sm">
              {editingPath ? 'Save Changes' : 'Create Career Path'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* 2. Create/Edit Milestone Modal */}
      <Modal
        isOpen={isMilestoneModalOpen}
        onClose={() => setIsMilestoneModalOpen(false)}
        title={editingMilestone ? 'Edit Career Milestone' : 'Add Career Milestone'}
        maxWidth="max-w-md"
      >
        <form onSubmit={handleSaveMilestone} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Milestone Title <span className="text-rose-500">*</span>
            </label>
            <Input
              type="text"
              required
              placeholder="e.g. Master React & State Management, Clear Prelims GS-1"
              value={milestoneForm.title}
              onChange={(e) => setMilestoneForm({ ...milestoneForm, title: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Description (Optional)
            </label>
            <textarea
              rows={3}
              placeholder="Actionable steps, checkpoints, or study resources required to achieve this milestone..."
              value={milestoneForm.description}
              onChange={(e) => setMilestoneForm({ ...milestoneForm, description: e.target.value })}
              className="w-full rounded-lg border border-zinc-200 p-2.5 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Publish Status
            </label>
            <select
              value={milestoneForm.status}
              onChange={(e) => setMilestoneForm({ ...milestoneForm, status: e.target.value as ContentStatus })}
              className="w-full h-10 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900"
            >
              <option value="DRAFT">DRAFT</option>
              <option value="PUBLISHED">PUBLISHED</option>
              <option value="ARCHIVED">ARCHIVED</option>
            </select>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setIsMilestoneModalOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="primary" size="sm">
              {editingMilestone ? 'Save Milestone' : 'Add Milestone'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* 3. Manage Categories Modal */}
      <Modal
        isOpen={isCategoriesManagerOpen}
        onClose={() => setIsCategoriesManagerOpen(false)}
        title="Manage Career Categories"
        maxWidth="max-w-xl"
      >
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <p className="text-xs text-zinc-500">
              Broad industry disciplines grouping individual career paths.
            </p>
            <Button
              variant="outline"
              size="sm"
              className="h-7 text-xs"
              onClick={() => {
                setEditingCategory(null);
                setCategoryForm({ name: '', description: '', icon: 'Briefcase', status: 'DRAFT' });
                setIsCategoryModalOpen(true);
              }}
            >
              <Plus className="w-3 h-3 mr-1" />
              Add Category
            </Button>
          </div>

          <div className="space-y-2 max-h-60 overflow-y-auto border border-zinc-200 rounded-lg p-2 bg-zinc-50">
            {categories.map((cat) => (
              <div
                key={cat.id}
                className="flex items-center justify-between p-2.5 rounded-lg bg-white border border-zinc-200 text-xs"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-zinc-900">{cat.name}</span>
                    <ContentStatusBadge status={cat.status} size="sm" />
                  </div>
                  {cat.description && (
                    <p className="text-[11px] text-zinc-500 line-clamp-1 mt-0.5">
                      {cat.description}
                    </p>
                  )}
                </div>

                <div className="flex items-center gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={() => {
                      setEditingCategory(cat);
                      setCategoryForm({
                        name: cat.name,
                        description: cat.description || '',
                        icon: cat.icon || 'Briefcase',
                        status: cat.status,
                      });
                      setIsCategoryModalOpen(true);
                    }}
                    className="p-1 text-zinc-500 hover:text-zinc-800"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeleteCategory(cat)}
                    className="p-1 text-rose-500 hover:text-rose-700"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="flex justify-end pt-2">
            <Button variant="primary" size="sm" onClick={() => setIsCategoriesManagerOpen(false)}>
              Done
            </Button>
          </div>
        </div>
      </Modal>

      {/* 4. Create/Edit Category Modal */}
      <Modal
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
        title={editingCategory ? 'Edit Career Category' : 'Add Career Category'}
        maxWidth="max-w-md"
      >
        <form onSubmit={handleSaveCategory} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Category Name <span className="text-rose-500">*</span>
            </label>
            <Input
              type="text"
              required
              placeholder="e.g. Software Engineering, Civil Services, Product & Design"
              value={categoryForm.name}
              onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">
              Description (Optional)
            </label>
            <textarea
              rows={2}
              placeholder="Brief description of the career domain..."
              value={categoryForm.description}
              onChange={(e) => setCategoryForm({ ...categoryForm, description: e.target.value })}
              className="w-full rounded-lg border border-zinc-200 p-2.5 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-zinc-700 uppercase mb-1">Status</label>
            <select
              value={categoryForm.status}
              onChange={(e) => setCategoryForm({ ...categoryForm, status: e.target.value as ContentStatus })}
              className="w-full h-10 rounded-lg border border-zinc-200 bg-white px-3 text-xs text-zinc-900 focus:ring-2 focus:ring-zinc-900"
            >
              <option value="DRAFT">DRAFT</option>
              <option value="PUBLISHED">PUBLISHED</option>
              <option value="ARCHIVED">ARCHIVED</option>
            </select>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setIsCategoryModalOpen(false)}
            >
              Cancel
            </Button>
            <Button type="submit" variant="primary" size="sm">
              {editingCategory ? 'Save Category' : 'Create Category'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* 5. Publish Confirmation Modal */}
      {publishTarget && (
        <PublishConfirmModal
          isOpen={Boolean(publishTarget)}
          onClose={() => setPublishTarget(null)}
          onConfirm={async () => {
            await handleStatusChange(publishTarget.type, publishTarget.id, 'PUBLISHED');
            setPublishTarget(null);
          }}
          itemType={publishTarget.type}
          itemName={publishTarget.name}
        />
      )}

      {/* 6. Delete Protection Modal */}
      {deleteBlockedInfo && (
        <DeleteProtectionModal
          isOpen={Boolean(deleteBlockedInfo)}
          onClose={() => setDeleteBlockedInfo(null)}
          itemType={deleteBlockedInfo.itemType}
          itemName={deleteBlockedInfo.itemName}
          reason={deleteBlockedInfo.reason}
        />
      )}

      {/* 7. Student App Roadmap Preview Modal */}
      <ContentPreviewModal
        isOpen={Boolean(previewPath)}
        onClose={() => setPreviewPath(null)}
        type="career"
        careerData={previewData}
      />
    </div>
  );
};
