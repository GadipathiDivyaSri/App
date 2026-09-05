import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'goal_achieved_screen.dart';

class ShortTermPrioritiesScreen extends StatefulWidget {
  const ShortTermPrioritiesScreen({super.key});

  @override
  State<ShortTermPrioritiesScreen> createState() =>
      _ShortTermPrioritiesScreenState();
}

class _ShortTermPrioritiesScreenState extends State<ShortTermPrioritiesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final shortGoals = provider.shortGoals;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Short Term Priorities',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelPriorityIcon,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_short_priority_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddShortGoalDialog(context);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        children: [
          Text(
            'Short Term Priorities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Focus on the next 7 days (${shortGoals.length} Active)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (shortGoals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.flag_outlined, size: 48, color: const Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text(
                      'No short term priorities yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap + to add your priority for this week',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...shortGoals.asMap().entries.map((entry) {
              final idx = entry.key;
              final goal = entry.value;
              return _buildGoalPriorityCard(context, idx, goal, provider);
            }).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGoalPriorityCard(
      BuildContext context, int index, Goal goal, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isDark ? const Color(0xFF4C658A) : const Color(0xFF94A3B8))
                    : (isDark ? AppTheme.darkIconGlow : AppTheme.pastelPriorityIcon),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted
                                  ? (isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8))
                                  : (isDark ? Colors.white : AppTheme.lightTextPrimary),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                              onPressed: () => provider.toggleGoal(goal.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                              onPressed: () => provider.deleteGoal(goal.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShortGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Short-Term Priority',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Priority Title (e.g. Finish Sprint Task)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                hintText: 'Description / Purpose (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5CE5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    final provider = Provider.of<AppProvider>(context, listen: false);
                    final newGoal = Goal(
                      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
                      userId: provider.user.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      tier: 'short',
                    );
                    provider.addGoal(newGoal);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Priority', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
