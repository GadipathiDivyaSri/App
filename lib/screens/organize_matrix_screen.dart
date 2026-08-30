import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/premium_lock_banner.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';

/// Eisenhower Matrix Screen for WrindhaOS
/// 
/// 4 Quadrants:
/// 1. Urgent & Important (Do First)
/// 2. Not Urgent & Important (Schedule)
/// 3. Urgent & Not Important (Delegate)
/// 4. Not Urgent & Not Important (Eliminate)
class OrganizeMatrixScreen extends StatefulWidget {
  const OrganizeMatrixScreen({super.key});

  @override
  State<OrganizeMatrixScreen> createState() => _OrganizeMatrixScreenState();
}

class _OrganizeMatrixScreenState extends State<OrganizeMatrixScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final q1Tasks = provider.tasks.where((t) => t.priority == 1).toList();
    final q2Tasks = provider.tasks.where((t) => t.priority == 2).toList();
    final q3Tasks = provider.tasks.where((t) => t.priority == 3).toList();
    final q4Tasks = provider.tasks.where((t) => t.priority == 4).toList();

    return ProFeatureGuard(
      feature: AppFeature.eisenhowerMatrix,
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Eisenhower Matrix',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reusable Premium Lock Banner for Free users
            if (!isPremium)
              const PremiumLockBanner(
                featureName: 'Eisenhower Matrix',
                description: 'You are currently viewing Eisenhower Matrix in preview mode. Upgrade to Pro for ₹49/month to manage all four priority quadrants with live scheduling.',
              ),

            const Text(
              'PRODUCTIVITY MATRIX',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organize by Urgency & Importance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Focus on what matters most with the 4-quadrant decision model.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // 2x2 Quadrant Grid
            Column(
              children: [
                // Row 1: Q1 (Do First) & Q2 (Schedule)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Do First',
                        subtitle: 'Urgent & Important',
                        bgColor: AppTheme.matrixDoFirst,
                        iconColor: const Color(0xFF10B981),
                        icon: Icons.priority_high_rounded,
                        tasks: q1Tasks,
                        priority: 1,
                        isPremium: isPremium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Schedule',
                        subtitle: 'Important (Not Urgent)',
                        bgColor: AppTheme.matrixSchedule,
                        iconColor: const Color(0xFF3B82F6),
                        icon: Icons.calendar_today_rounded,
                        tasks: q2Tasks,
                        priority: 2,
                        isPremium: isPremium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Q3 (Delegate) & Q4 (Eliminate)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Delegate',
                        subtitle: 'Urgent (Not Important)',
                        bgColor: AppTheme.matrixDelegate,
                        iconColor: const Color(0xFFF59E0B),
                        icon: Icons.people_outline_rounded,
                        tasks: q3Tasks,
                        priority: 3,
                        isPremium: isPremium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Eliminate',
                        subtitle: 'Neither',
                        bgColor: AppTheme.matrixEliminate,
                        iconColor: const Color(0xFFEF4444),
                        icon: Icons.delete_outline_rounded,
                        tasks: q4Tasks,
                        priority: 4,
                        isPremium: isPremium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuadrantCell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required List<Task> tasks,
    required int priority,
    required bool isPremium,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : bgColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
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
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: () {
                  if (!isPremium) {
                    showUpgradeProModal(
                      context,
                      featureTitle: 'Eisenhower Matrix',
                      limitExplanation: 'Free mode includes read-only preview. Upgrade to Pro for ₹49/month to add and manage matrix tasks.',
                    );
                  } else {
                    _showAddTaskDialog(context, priority);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No tasks here',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            Column(
              children: tasks.map((task) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242321) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => provider.toggleTaskCompletion(task.id),
                        child: Icon(
                          task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: task.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
                        onSelected: (action) {
                          if (action == 'delete') {
                            provider.deleteTask(task.id);
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
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, int priority) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Quadrant $priority Task', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter task title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = titleCtrl.text.trim();
              if (text.isNotEmpty) {
                final provider = Provider.of<AppProvider>(context, listen: false);
                provider.addTask(text, 'Eisenhower Matrix', 'Today', priority: priority);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}
