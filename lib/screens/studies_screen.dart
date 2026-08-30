import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = Provider.of<AppProvider>(context).user.isPremium;

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
            // 1. Top Academic Overview Grid (Completed, Pending, Needs Attention)
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
            const SizedBox(height: 24),

            // 2. Subjects Section (Limit 2 for Free users)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (!provider.canAddSubject) {
                      showUpgradeProModal(
                        context,
                        featureTitle: 'Subjects',
                        limitExplanation: 'Free plan allows up to 2 subjects. Upgrade to Pro for ₹49/month to manage unlimited subjects and syllabi!',
                      );
                    } else {
                      _showAddSubjectDialog(context);
                    }
                  },
                  icon: Icon(!provider.canAddSubject ? Icons.lock_rounded : Icons.add_rounded, size: 18),
                  label: Text(!provider.canAddSubject ? 'Add (Pro)' : 'Add Subject', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (subjects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('No subjects added yet. Tap (+ Add Subject) to start!', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              Column(
                children: subjects.map((sub) {
                  return Container(
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
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: Color(sub.colorHex), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sub.name,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                            ),
                            if (sub.code.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(sub.colorHex).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.code,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(sub.colorHex)),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                              onSelected: (act) {
                                if (act == 'delete') {
                                  provider.deleteSubject(sub.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), SizedBox(width: 6), Text('Delete')]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                            Text('${(sub.progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(sub.colorHex))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: sub.progress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(sub.colorHex)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // 3. Study Items / Assignments / Exams Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Academic Work',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 24),
                  onPressed: () {
                    if (subjects.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one subject first.')),
                      );
                    } else {
                      _showAddStudyItemDialog(context, subjects);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Items', _selectedFilter == 'ALL', primaryColor),
                  _buildFilterChip('ASSIGNMENT', 'Assignments', _selectedFilter == 'ASSIGNMENT', primaryColor),
                  _buildFilterChip('EXAM', 'Exams & Tests', _selectedFilter == 'EXAM', primaryColor),
                  _buildFilterChip('TASK', 'Study Tasks', _selectedFilter == 'TASK', primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (filteredItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isCompleted
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : (isOverdue ? Colors.redAccent.withOpacity(0.4) : (isDark ? AppTheme.darkCardBorder : AppTheme.borderLight)),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(item.type).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
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
                                      fontSize: 11.5,
                                      color: isOverdue ? Colors.redAccent : (isDueSoon ? const Color(0xFFF59E0B) : textSecondary),
                                      fontWeight: isDueSoon || isOverdue ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                          onSelected: (act) {
                            if (act == 'delete') {
                              provider.deleteStudyItem(item.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), SizedBox(width: 6), Text('Delete')]),
                            ),
                          ],
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

  Widget _buildStudyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: AppTheme.darkCardBorder, width: 1)
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? AppTheme.darkIconBg
                    : AppTheme.pastelStudies,
              ),
              child: Icon(
                icon,
                color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelStudiesIcon,
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF4C658A) : const Color(0xFF8D827A),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
