import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../theme/app_theme.dart';

/// Serpentine S-Curve Career Roadmap Screen matching exact user UI & interactions
class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.clearPredefinedNodes();
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;

    final bgLight = const Color(0xFFFAFBFF);
    final bgDark = AppTheme.darkBg;
    final textDark = isDark ? Colors.white : const Color(0xFF1E293B);

    final nodes = provider.careerRoadmap;
    final completedCount = nodes.where((n) => n.isCompleted).length;

    return Scaffold(
        backgroundColor: isDark ? bgDark : bgLight,
        appBar: AppBar(
          backgroundColor: isDark ? bgDark : bgLight,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Career Roadmap',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_milestone_fab',
          backgroundColor: const Color(0xFF0D5CE5),
          elevation: 6,
          onPressed: () => _showAddMilestoneNodeDialog(context),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            // Top Badge Pill: "Roadmap Milestones"
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2433),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: Color(0xFF38BDF8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Roadmap Milestones',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D5CE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$completedCount/${nodes.length} Done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Serpentine Roadmap Container
            Expanded(
              child: nodes.isEmpty
                  ? Center(
                      child: Text(
                        'No milestone nodes yet.\nTap (+) to add your first roadmap node!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: SizedBox(
                            width: width,
                            height: (nodes.length * 110.0) + 60,
                            child: Stack(
                              children: [
                                // S-Curve Dashed Line Background Painter
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SerpentinePathPainter(
                                      nodeCount: nodes.length,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),

                                // Interactive Nodes along S-Curve
                                ...nodes.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final node = entry.value;

                                  // Calculate X position along S-curve
                                  final double progress = index / (nodes.length > 1 ? nodes.length - 1 : 1);
                                  // S-curve oscillation left to right
                                  final double targetX = (width / 2) + ((width * 0.28) * (index % 2 == 0 ? -1 : 1));
                                  final double targetY = 30.0 + (index * 110.0);

                                  final IconData nodeIcon = _getNodeIconForIndex(index);
                                  final bool isDone = node.isCompleted;

                                  return Positioned(
                                    left: targetX - 32,
                                    top: targetY - 32,
                                    child: GestureDetector(
                                      onTap: () {
                                        provider.toggleCareerNode(node.id);
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              node.isCompleted
                                                  ? '✓ Milestone "${node.title}" marked as Completed!'
                                                  : 'Milestone "${node.title}" marked as Planned',
                                            ),
                                            backgroundColor: node.isCompleted ? const Color(0xFF10B981) : const Color(0xFF334155),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      onLongPress: () {
                                        _showNodeOptionsModal(context, node);
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDone
                                                  ? const Color(0xFF0D5CE5)
                                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF)),
                                              border: Border.all(
                                                color: isDone
                                                    ? const Color(0xFF38BDF8)
                                                    : const Color(0xFF94A3B8).withOpacity(0.5),
                                                width: isDone ? 2.5 : 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDone
                                                      ? const Color(0xFF0D5CE5).withOpacity(0.35)
                                                      : Colors.black.withOpacity(0.05),
                                                  blurRadius: isDone ? 12 : 6,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: isDone
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 28,
                                                    )
                                                  : Icon(
                                                      nodeIcon,
                                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0D5CE5),
                                                      size: 24,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Title & Completion Tag
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 130),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDone
                                                  ? (isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5))
                                                  : (isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.9)),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  node.title,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDone
                                                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                                        : textDark,
                                                  ),
                                                ),
                                                if (isDone) ...[
                                                  const SizedBox(height: 1),
                                                  const Text(
                                                    '✓ Completed',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
  }

  IconData _getNodeIconForIndex(int index) {
    const icons = [
      Icons.star_rounded,
      Icons.rocket_launch_rounded,
      Icons.lightbulb_rounded,
      Icons.school_rounded,
      Icons.work_rounded,
    ];
    return icons[index % icons.length];
  }

  void _showNodeOptionsModal(BuildContext context, CareerRoadmapNode node) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    node.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: node.isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    node.isCompleted ? 'Completed ✓' : 'In Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: node.isCompleted ? const Color(0xFF047857) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            if (node.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                node.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle_rounded,
                color: node.isCompleted ? Colors.grey : const Color(0xFF10B981),
              ),
              title: Text(node.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed'),
              onTap: () {
                Navigator.pop(ctx);
                Provider.of<AppProvider>(context, listen: false).toggleCareerNode(node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Node', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                Provider.of<AppProvider>(context, listen: false).deleteCareerNode(node.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Add Milestone Node Dialog matching Image 3 UI
  void _showAddMilestoneNodeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedCompletionDate;
    final dateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Title
                    const Text(
                      'Roadmap',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '·',
                      style: TextStyle(fontSize: 18, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),

                    // Card Title Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Add Milestone Node',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. NODE TITLE
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'NODE TITLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Senior Architect Certification',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. DESCRIPTION
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Briefly define the scope of this milestone...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. ESTIMATED COMPLETION
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'ESTIMATED COMPLETION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedCompletionDate = picked;
                            dateCtrl.text =
                                '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'dd-mm-yyyy',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        suffixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons: Cancel & Add Node
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEEF2FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final title = titleCtrl.text.trim();
                          if (title.isNotEmpty) {
                            final provider = Provider.of<AppProvider>(context, listen: false);
                            final desc = descCtrl.text.trim();
                            final formattedDateStr = dateCtrl.text.trim();
                            final fullDesc = formattedDateStr.isNotEmpty ? '$desc (Est: $formattedDateStr)' : desc;

                            provider.addCareerNode(
                              CareerRoadmapNode(
                                id: generateUuidV4(),
                                section: 'SKILLS',
                                title: title,
                                description: fullDesc,
                                status: 'PLANNED',
                                order: provider.careerRoadmap.length,
                              ),
                            );
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          'Add Node',
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
        },
      ),
    );
  }
}

/// CustomPainter drawing a smooth, elegant serpentine S-Curve path down the roadmap
class _SerpentinePathPainter extends CustomPainter {
  final int nodeCount;
  final bool isDark;

  _SerpentinePathPainter({required this.nodeCount, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount <= 0) return;

    final paint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    final double width = size.width;

    for (int i = 0; i < nodeCount; i++) {
      final double x = (width / 2) + ((width * 0.28) * (i % 2 == 0 ? -1 : 1));
      final double y = 30.0 + (i * 110.0);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final double prevX = (width / 2) + ((width * 0.28) * ((i - 1) % 2 == 0 ? -1 : 1));
        final double prevY = 30.0 + ((i - 1) * 110.0);

        final double controlY1 = prevY + 55.0;
        final double controlY2 = y - 55.0;

        path.cubicTo(prevX, controlY1, x, controlY2, x, y);
      }
    }

    // Draw dashed path effect
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      const double dashWidth = 6.0;
      const double dashGap = 6.0;

      while (distance < metric.length) {
        final double end = distance + dashWidth;
        final extractPath = metric.extractPath(distance, end > metric.length ? metric.length : end);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SerpentinePathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount || oldDelegate.isDark != isDark;
  }
}
