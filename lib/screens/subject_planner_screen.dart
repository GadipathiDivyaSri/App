import 'package:flutter/material.dart';
import 'add_subject_screen.dart';
import 'subject_details_screen.dart';

class SubjectPlannerScreen extends StatefulWidget {
  const SubjectPlannerScreen({super.key});

  @override
  State<SubjectPlannerScreen> createState() => _SubjectPlannerScreenState();
}

class _SubjectPlannerScreenState extends State<SubjectPlannerScreen> {
  List<Map<String, dynamic>> _subjects = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subject Planner'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subject_planner_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Subject',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddSubjectScreen(),
            ),
          ).then((newSubject) {
            if (newSubject != null && newSubject is String) {
              setState(() {
                _subjects.add({
                  'name': newSubject,
                  'unitsCount': 0,
                  'progress': 0.0,
                  'icon': Icons.school_outlined,
                });
              });
            }
          });
        },
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          Text(
            'Your Subjects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a subject to view units and topics, or add a new subject curriculum.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          if (_subjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'No subjects added yet.\nTap Add Subject (+) to create your first subject.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
              ),
            )
          else
            ..._subjects.map((sub) => _buildSubjectCard(context, sub)).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectDetailsScreen(
              subjectName: sub['name'] as String,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0D5CE5).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(sub['icon'] as IconData,
                  color: const Color(0xFF0D5CE5), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub['name'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sub['unitsCount']} Units • ${(sub['progress'] * 100).toInt()}% Mastered',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: sub['progress'] as double,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEEF2FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0D5CE5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditSubjectDialog(context, sub);
                } else if (val == 'complete') {
                  setState(() {
                    sub['progress'] = 1.0;
                  });
                } else if (val == 'delete') {
                  setState(() {
                    _subjects.remove(sub);
                  });
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D5CE5)),
                      SizedBox(width: 8),
                      Text('Edit Subject'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Mark 100% Complete'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Delete Subject', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Map<String, dynamic> sub) {
    final nameCtrl = TextEditingController(text: sub['name'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  sub['name'] = nameCtrl.text.trim();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
