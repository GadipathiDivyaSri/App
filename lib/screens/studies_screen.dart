import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/premium_lock_banner.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';
import 'subject_details_screen.dart';
import 'focus_timer_screen.dart';
import 'goal_pyramid_screen.dart';
import 'subject_planner_screen.dart';

/// Studies Screen for WrindhaOS
/// 
/// Academic Organizer featuring:
/// - Academic Overview: Completed, Pending, Needs Attention
/// - Subjects List with progress (Max 2 subjects for Free users)
/// - Assignments, Exams & Study Tasks
/// - Live progress calculations
class StudiesScreen extends StatefulWidget {
  const StudiesScreen({super.key});

  @override
  State<StudiesScreen> createState() => _StudiesScreenState();
}

class _StudiesScreenState extends State<StudiesScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'ASSIGNMENT', 'EXAM', 'TASK'

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'EXAM':
        return Colors.redAccent;
      case 'ASSIGNMENT':
        return const Color(0xFF3B82F6);
      case 'TASK':
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildOverviewMetricCard(
    String title,
    String count,
    Color color,
    IconData icon,
    bool isDark,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isSelected, Color primaryColor) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    final subjects = provider.subjects;
    final allStudyItems = provider.studyItems;

    final completedCount = allStudyItems.where((i) => i.isCompleted).length;
    final pendingCount = allStudyItems.where((i) => !i.isCompleted).length;
    final now = DateTime.now();
    final needsAttentionCount = allStudyItems
        .where((i) => !i.isCompleted && (i.dueDate.isBefore(now) || i.dueDate.difference(now).inDays <= 2))
        .length;

    final filteredItems = allStudyItems.where((item) {
      if (_selectedFilter == 'ALL') return true;
      return item.type.toUpperCase() == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Studies',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Academic Overview Grid
            Row(
              children: [
                Expanded(
                  child: _buildOverviewMetricCard(
                    'Completed',
                    '$completedCount',
                    const Color(0xFF10B981),
                    Icons.check_circle_outline_rounded,
                    isDark,
                    cardBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOverviewMetricCard(
                    'Pending',
                    '$pendingCount',
                    const Color(0xFF3B82F6),
                    Icons.pending_actions_rounded,
                    isDark,
                    cardBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOverviewMetricCard(
                    'Attention',
                    '$needsAttentionCount',
                    const Color(0xFFF59E0B),
                    Icons.warning_amber_rounded,
                    isDark,
                    cardBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1.5 Study Accelerators (Focus Timer, Stopwatch, Goals Hierarchy)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2235) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0x332A85FF) : const Color(0xFFFFD4A8),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: isDark ? AppTheme.darkPrimary : const Color(0xFFE87552)),
                      const SizedBox(width: 6),
                      Text(
                        'STUDY & PRODUCTIVITY POWER TOOLS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: isDark ? AppTheme.darkPrimary : const Color(0xFFE87552),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Focus Timer & Stopwatch
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141724) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Focus Timer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text('Pomodoro & Stopwatch', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Goal Management
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GoalPyramidScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141724) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.flag_outlined, size: 20, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Goals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text('Short, Med, Long-Term', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Subjects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Subjects',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    Text(
                      'Tap any subject to view & add Units & Topics',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    if (!provider.canAddSubject) {
                      ProUpgradeDialog.showSubjectLimitDialog(context);
                    } else {
                      _showAddSubjectDialog(context);
                    }
                  },
                  icon: Icon(!provider.canAddSubject ? Icons.lock_rounded : Icons.add_rounded, size: 18),
                  label: Text(!provider.canAddSubject ? 'Add (Pro)' : 'Add Subject', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (subjects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('No subjects added yet. Tap (+ Add Subject) to start!', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              Column(
                children: subjects.map((sub) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectDetailsScreen(subjectName: sub.name),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(sub.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    sub.name,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                                onSelected: (val) {
                                  if (val == 'delete') {
                                    provider.deleteSubject(sub.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 16), SizedBox(width: 8), Text('Delete')]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Progress (Tap to open Units)', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                              Text('${(sub.progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sub.progress,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(sub.colorValue)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // 3. Study Items Header & Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assignments & Exams',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 24),
                  onPressed: () {
                    if (subjects.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add a subject first before adding assignments/exams.')),
                      );
                    } else {
                      _showAddStudyItemDialog(context, subjects);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Items', _selectedFilter == 'ALL', primaryColor),
                  const SizedBox(width: 8),
                  _buildFilterChip('ASSIGNMENT', 'Assignments', _selectedFilter == 'ASSIGNMENT', primaryColor),
                  const SizedBox(width: 8),
                  _buildFilterChip('EXAM', 'Exams & Tests', _selectedFilter == 'EXAM', primaryColor),
                  const SizedBox(width: 8),
                  _buildFilterChip('TASK', 'Study Tasks', _selectedFilter == 'TASK', primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Study Items List
            if (filteredItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('No study items found.', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              Column(
                children: filteredItems.map((item) {
                  final isOverdue = !item.isCompleted && item.dueDate.isBefore(now);
                  final isDueSoon = !item.isCompleted && item.dueDate.difference(now).inDays <= 2;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.redAccent.withOpacity(0.5)
                            : (isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => provider.toggleStudyItem(item.id),
                          child: Icon(
                            item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: item.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(item.type).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _getTypeColor(item.type)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.subjectName} • Due ${DateFormat('MMM d').format(item.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOverdue ? Colors.redAccent : (isDueSoon ? const Color(0xFFF59E0B) : textSecondary),
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
                          onPressed: () => provider.deleteStudyItem(item.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int colorValue = const Color(0xFF0D5CE5).value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Academic Subject', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Subject Name (e.g. Mathematics, AI)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  if (!provider.canAddSubject) {
                    Navigator.pop(ctx);
                    ProUpgradeDialog.showSubjectLimitDialog(context);
                    return;
                  }
                  provider.addSubject(
                    StudySubject(
                      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      colorValue: colorValue,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudyItemDialog(BuildContext context, List<StudySubject> subjects) {
    final titleCtrl = TextEditingController();
    String type = 'ASSIGNMENT';
    String selectedSubId = subjects.first.id;
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Study Item', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title / Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedSubId = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ASSIGNMENT', child: Text('Assignment / Project')),
                  DropdownMenuItem(value: 'EXAM', child: Text('Exam / Quiz / Test')),
                  DropdownMenuItem(value: 'TASK', child: Text('Study Task / Revision')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => type = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  final chosenSub = subjects.firstWhere((s) => s.id == selectedSubId);
                  provider.addStudyItem(
                    StudyItem(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      subjectId: chosenSub.id,
                      subjectName: chosenSub.name,
                      title: title,
                      type: type,
                      dueDate: dueDate,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
