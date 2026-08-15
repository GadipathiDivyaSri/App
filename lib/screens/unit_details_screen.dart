import 'package:flutter/material.dart';
import 'focus_timer_screen.dart';

class UnitDetailsScreen extends StatefulWidget {
  final String unitTitle;
  final double progress;

  const UnitDetailsScreen({
    super.key,
    this.unitTitle = 'Unit 2: Algebra',
    this.progress = 0.60,
  });

  @override
  State<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends State<UnitDetailsScreen> {
  late List<Map<String, dynamic>> _topics;

  @override
  void initState() {
    super.initState();
    _topics = [];
  }

  double get _currentProgress {
    if (_topics.isEmpty) return 0.0;
    final completed = _topics.where((t) => t['isCompleted'] == true).length;
    return completed / _topics.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pPct = (_currentProgress * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.unitTitle),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'unit_details_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          _showAddTopicDialog(context);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          // Mastery Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MASTERY PROGRESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$pPct%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D5CE5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D5CE5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5CE5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text(
                      'Start Deep Focus Session',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FocusTimerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Topics List
          ..._topics.asMap().entries.map((entry) {
            final idx = entry.key;
            final topic = entry.value;
            return _buildTopicCard(context, idx, topic);
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, int index, Map<String, dynamic> topic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = topic['isCompleted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          GestureDetector(
            onTap: () {
              setState(() {
                _topics[index]['isCompleted'] = !isCompleted;
              });
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isCompleted ? const Color(0xFF0D5CE5) : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF0D5CE5)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? const Color(0xFF94A3B8)
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic['sub'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
            onSelected: (val) {
              if (val == 'toggle') {
                setState(() {
                  _topics[index]['isCompleted'] = !isCompleted;
                });
              } else if (val == 'edit') {
                _showEditTopicDialog(context, index);
              } else if (val == 'delete') {
                setState(() {
                  _topics.removeAt(index);
                });
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, size: 18, color: const Color(0xFF0D5CE5)),
                    const SizedBox(width: 8),
                    Text(isCompleted ? 'Mark Incomplete' : 'Mark Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D5CE5)),
                    SizedBox(width: 8),
                    Text('Edit Topic'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Delete Topic', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditTopicDialog(BuildContext context, int index) {
    final titleCtrl = TextEditingController(text: _topics[index]['title'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Topic', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Topic Title', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _topics[index]['title'] = titleCtrl.text.trim();
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

  void _showAddTopicDialog(BuildContext context) {
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Topic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Topic Title (e.g., Topic 6: Matrices)',
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
                      _topics.add({
                        'title': titleCtrl.text.trim(),
                        'sub': 'Added just now',
                        'isCompleted': false,
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Add Topic',
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
    );
  }
}
