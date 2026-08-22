import 'package:flutter/material.dart';
import 'short_term_priorities_screen.dart';
import 'career_roadmap_screen.dart';

class GoalPyramidScreen extends StatefulWidget {
  const GoalPyramidScreen({super.key});

  @override
  State<GoalPyramidScreen> createState() => _GoalPyramidScreenState();
}

class _GoalPyramidScreenState extends State<GoalPyramidScreen> {
  final List<Map<String, String>> _shortGoals = [];
  final List<Map<String, String>> _mediumGoals = [];
  final List<Map<String, String>> _longGoals = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goal_pyramid_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          _showAddGoalDialog(context);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D5CE5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Goal Hierarchy',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ALIGNED PURPOSE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),

            // Pyramid Representation
            Center(
              child: Column(
                children: [
                  // Top Level: Short
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShortTermPrioritiesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D5CE5),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D5CE5).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Short',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Middle Level: Medium
                  GestureDetector(
                    onTap: () {
                      _showGoalTierDetails(context, 'Medium Term Goals', _mediumGoals);
                    },
                    child: Container(
                      width: 230,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Medium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bottom Level: Long Term
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CareerRoadmapScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Center(
                        child: Text(
                          'Long Term',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Summary Section
            Text(
              'Active Goals Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalSummaryCard(context, 'Short Term', '${_shortGoals.length} Active Goals', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShortTermPrioritiesScreen()),
              );
            }),
            const SizedBox(height: 10),
            _buildGoalSummaryCard(context, 'Medium Term', '${_mediumGoals.length} Active Goals', () {
              _showGoalTierDetails(context, 'Medium Term Goals', _mediumGoals);
            }),
            const SizedBox(height: 10),
            _buildGoalSummaryCard(context, 'Long Term Roadmap', '${_longGoals.length} Roadmap Milestones', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CareerRoadmapScreen()),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSummaryCard(
      BuildContext context, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      tileColor: isDark ? const Color(0xFF1E1F2B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0D5CE5)),
      onTap: onTap,
    );
  }

  void _showGoalTierDetails(BuildContext context, String title, List<Map<String, String>> goals) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...goals.map((g) => ListTile(
                  title: Text(g['title']!),
                  subtitle: Text('Status: ${g['progress']}'),
                  trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF0D5CE5)),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5CE5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddGoalDialog(context);
                },
                child: const Text('Add Goal to this Tier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String selectedTerm = 'Short';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                'Add New Goal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('SELECT TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Row(
                children: ['Short', 'Medium', 'Long Term'].map((tier) {
                  final isSel = selectedTerm == tier;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tier),
                      selected: isSel,
                      selectedColor: const Color(0xFF0D5CE5),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedTerm = tier);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5CE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        if (selectedTerm == 'Short') {
                          _shortGoals.add({'title': titleCtrl.text.trim(), 'progress': '0%'});
                        } else if (selectedTerm == 'Medium') {
                          _mediumGoals.add({'title': titleCtrl.text.trim(), 'progress': '0%'});
                        } else {
                          _longGoals.add({'title': titleCtrl.text.trim(), 'progress': 'Planned'});
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Goal added to $selectedTerm term hierarchy!')),
                      );
                    }
                  },
                  child: const Text(
                    'Save Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
