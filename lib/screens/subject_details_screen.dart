import 'package:flutter/material.dart';
import 'add_unit_screen.dart';
import 'unit_details_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectName;

  const SubjectDetailsScreen({
    super.key,
    required this.subjectName,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  late List<Map<String, dynamic>> _units;

  @override
  void initState() {
    super.initState();
    _units = [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.subjectName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subject_details_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Unit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddUnitScreen(),
            ),
          ).then((newUnit) {
            if (newUnit != null && newUnit is Map<String, dynamic>) {
              setState(() {
                _units.add({
                  'title': newUnit['title'] as String,
                  'progress': 0.0,
                  'topicsCount': 3,
                  'description': newUnit['desc'] as String,
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
            'Curriculum Units',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore units inside ${widget.subjectName}. Tap any unit to view topics and mastery.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          if (_units.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5CE5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 36,
                      color: Color(0xFF0D5CE5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Units Added Yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Break down this subject into organized curriculum units & topics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5CE5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Add First Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddUnitScreen(),
                        ),
                      ).then((newUnit) {
                        if (newUnit != null && newUnit is Map<String, dynamic>) {
                          setState(() {
                            _units.add({
                              'title': newUnit['title'] as String,
                              'progress': 0.0,
                              'topicsCount': 3,
                              'description': newUnit['desc'] as String,
                            });
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
            )
          else
            ..._units.map((unit) => _buildUnitCard(context, unit)).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, Map<String, dynamic> unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = unit['progress'] as double;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnitDetailsScreen(
              unitTitle: unit['title'] as String,
              progress: progress,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    unit['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D5CE5),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditUnitDialog(context, unit);
                    } else if (val == 'complete') {
                      setState(() {
                        unit['progress'] = 1.0;
                      });
                    } else if (val == 'delete') {
                      setState(() {
                        _units.remove(unit);
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
                          Text('Edit Unit'),
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
                          Text('Delete Unit', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              unit['description'] as String,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
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
    );
  }

  void _showEditUnitDialog(BuildContext context, Map<String, dynamic> unit) {
    final titleCtrl = TextEditingController(text: unit['title'] as String);
    final descCtrl = TextEditingController(text: unit['description'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Unit Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  unit['title'] = titleCtrl.text.trim();
                  unit['description'] = descCtrl.text.trim();
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
