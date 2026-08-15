import 'package:flutter/material.dart';

class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  List<Map<String, dynamic>> _nodes = [];

  int get _highestCompletedIndex {
    int lastIdx = 0;
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i]['isCompleted'] == true) {
        lastIdx = i;
      }
    }
    return lastIdx;
  }

  int get _totalXp {
    int xp = 0;
    for (var node in _nodes) {
      if (node['isCompleted'] == true) {
        xp += (node['xp'] as int);
      }
    }
    return xp;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentActiveIdx = _highestCompletedIndex;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Floating Career Roadmap'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D5CE5).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF0D5CE5), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_totalXp XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D5CE5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'career_floating_fab',
        backgroundColor: const Color(0xFF0D5CE5),
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Milestone',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _showAddMilestoneDialog(context);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Floating Stage Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
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
                      color: const Color(0xFF0D5CE5).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.alt_route_rounded,
                        color: Color(0xFF60A5FA), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'START: ENTRY LEVEL',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nodes.isNotEmpty
                              ? _nodes[currentActiveIdx]['title'] as String
                              : 'No Milestones Set',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lvl ${currentActiveIdx + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap any node to view deliverables & slide your character avatar along the floating path.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),

            // S-Curve Floating Nodes & Avatar
            ..._nodes.asMap().entries.map((entry) {
              final idx = entry.key;
              final node = entry.value;
              final isCompleted = node['isCompleted'] == true;
              final isCurrentAvatarNode = (idx == currentActiveIdx);

              // Alternate horizontal offset
              final double alignOffset = (idx % 2 == 0) ? -0.4 : 0.4;

              return Column(
                children: [
                  Align(
                    alignment: Alignment(alignOffset, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Left Avatar Character
                        if (isCurrentAvatarNode && alignOffset < 0) ...[
                          _buildFloatingPersonAvatar(context, idx + 1),
                          const SizedBox(width: 8),
                        ],

                        // Floating Glassmorphism Node Card
                        GestureDetector(
                          onTap: () {
                            _showNodeDetailsModal(context, idx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isCompleted
                                      ? const Color(0xFF1E1F2B)
                                      : const Color(0xFF181924))
                                  : (isCompleted
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFF0D5CE5)
                                    : (isCurrentAvatarNode
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFCBD5E1)),
                                width: isCurrentAvatarNode ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isCompleted
                                      ? const Color(0xFF0D5CE5).withOpacity(0.12)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? const Color(0xFF0D5CE5)
                                        : const Color(0xFFEEF2FF),
                                  ),
                                  child: Icon(
                                    node['icon'] as IconData,
                                    color: isCompleted
                                        ? Colors.white
                                        : const Color(0xFF0D5CE5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Lvl ${node['level']}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D5CE5),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (isCompleted)
                                          const Icon(Icons.check_circle_rounded,
                                              size: 12, color: Color(0xFF10B981)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      node['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      '+${node['xp']} XP • ${node['date']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Avatar Character
                        if (isCurrentAvatarNode && alignOffset >= 0) ...[
                          const SizedBox(width: 8),
                          _buildFloatingPersonAvatar(context, idx + 1),
                        ],
                      ],
                    ),
                  ),

                  if (idx < _nodes.length - 1)
                    CustomPaint(
                      size: const Size(160, 60),
                      painter: ElectricCurvePainter(
                        isLeftToRight: (idx % 2 == 0),
                        isCompleted: isCompleted,
                      ),
                    ),
                ],
              );
            }).toList(),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingPersonAvatar(BuildContext context, int level) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            'YOU L$level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  void _showNodeDetailsModal(BuildContext context, int index) {
    final node = _nodes[index];
    final isCompleted = node['isCompleted'] == true;
    final List deliverables = node['deliverables'] as List;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5CE5).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(node['icon'] as IconData,
                            color: const Color(0xFF0D5CE5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${node['level']} Milestone',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D5CE5),
                            ),
                          ),
                          Text(
                            node['title'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _nodes.removeAt(index);
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                node['subtitle'] as String,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              const Text(
                'KEY DELIVERABLES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              ...deliverables.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF0D5CE5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item as String,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),

              // Complete Toggle Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0D5CE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _nodes[index]['isCompleted'] = !isCompleted;
                    });
                    Navigator.pop(ctx);
                  },
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    isCompleted
                        ? 'Completed (+${node['xp']} XP)'
                        : 'Mark as Completed (+${node['xp']} XP)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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

  void _showAddMilestoneDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final xpCtrl = TextEditingController(text: '500');

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
              'Add New Career Milestone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Milestone Title (e.g., Senior Architect)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subCtrl,
              decoration: const InputDecoration(
                hintText: 'Subtitle / Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: xpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'XP Reward (e.g., 500)',
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
                      _nodes.add({
                        'level': _nodes.length + 1,
                        'title': titleCtrl.text.trim(),
                        'subtitle': subCtrl.text.trim(),
                        'icon': Icons.stars_rounded,
                        'xp': int.tryParse(xpCtrl.text.trim()) ?? 500,
                        'date': 'Planned',
                        'isCompleted': false,
                        'deliverables': [
                          'Define core requirements',
                          'Execute deliverables',
                        ],
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Add Milestone',
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

class ElectricCurvePainter extends CustomPainter {
  final bool isLeftToRight;
  final bool isCompleted;

  ElectricCurvePainter({
    required this.isLeftToRight,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? const Color(0xFF0D5CE5) : const Color(0xFF93C5FD)
      ..strokeWidth = isCompleted ? 3.5 : 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double startX = isLeftToRight ? size.width * 0.25 : size.width * 0.75;
    final double endX = isLeftToRight ? size.width * 0.75 : size.width * 0.25;

    path.moveTo(startX, 0);
    path.cubicTo(
        startX, size.height * 0.5, endX, size.height * 0.5, endX, size.height);

    // Draw dashed path
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
