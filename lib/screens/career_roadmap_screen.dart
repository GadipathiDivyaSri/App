import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating / Flexible Career Roadmap Screen for WrindhaOS
/// 
/// Flexible structure:
/// Career Goal → Skills → Learning → Projects → Experience → Career Opportunities
/// Completely free of rigid milestone stages.
class CareerRoadmapScreen extends StatelessWidget {
  const CareerRoadmapScreen({super.key});

  static const List<Map<String, dynamic>> _sections = [
    {
      'key': 'GOAL',
      'title': 'Career Goal',
      'icon': Icons.flag_rounded,
      'color': Color(0xFF6366F1),
      'desc': 'Your primary career aspiration & north star',
    },
    {
      'key': 'SKILLS',
      'title': 'Skills Mastery',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFF0D5CE5),
      'desc': 'Core technical and leadership competencies',
    },
    {
      'key': 'LEARNING',
      'title': 'Learning & Certifications',
      'icon': Icons.school_rounded,
      'color': Color(0xFF10B981),
      'desc': 'Deep-dive courses, books, and credentials',
    },
    {
      'key': 'PROJECTS',
      'title': 'Projects & Portfolio',
      'icon': Icons.terminal_rounded,
      'color': Color(0xFFF59E0B),
      'desc': 'Practical builds and verifiable proof of work',
    },
    {
      'key': 'EXPERIENCE',
      'title': 'Experience & Contributions',
      'icon': Icons.work_outline_rounded,
      'color': Color(0xFF8B5CF6),
      'desc': 'Internships, freelance, open source impact',
    },
    {
      'key': 'OPPORTUNITY',
      'title': 'Career Opportunities',
      'icon': Icons.rocket_launch_rounded,
      'color': Color(0xFFEC4899),
      'desc': 'Target roles, companies, and next big steps',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentActiveIdx = _highestCompletedIndex;

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
          'Floating Career Roadmap',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkIconBg
                  : AppTheme.pastelCareer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_totalXp XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'career_floating_fab',
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.pastelCareerIcon,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Stage Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelCareer,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
                boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkIconBg
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.alt_route_rounded,
                      color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                      size: 26,
                    ),
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
                                      ? AppTheme.darkCardBg
                                      : const Color(0xFF181924))
                                  : (isCompleted
                                      ? AppTheme.pastelCareer
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCompleted
                                    ? (isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon)
                                    : (isCurrentAvatarNode
                                        ? (isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon)
                                        : (isDark ? AppTheme.darkCardBorder : const Color(0xFFE8DCCF))),
                                width: isCurrentAvatarNode ? 2.5 : 1.5,
                              ),
                              boxShadow: isDark
                                  ? AppTheme.darkCardShadow
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
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
                                    color: isDark
                                        ? AppTheme.darkIconBg
                                        : (isCompleted ? Colors.white : AppTheme.pastelCareer),
                                  ),
                                  child: Icon(
                                    node['icon'] as IconData,
                                    color: isDark
                                        ? AppTheme.darkIconGlow
                                        : AppTheme.pastelCareerIcon,
                                    size: 20,
                                  ),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(desc, style: TextStyle(fontSize: 12, color: textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline_rounded, color: color, size: 24),
                                onPressed: () {
                                  if (!isPremium) {
                                    showUpgradeProModal(
                                      context,
                                      featureTitle: 'Career Roadmap',
                                      limitExplanation: 'Free mode includes read-only preview. Upgrade to Pro for ₹49/month to customize your career growth trajectory.',
                                    );
                                  } else {
                                    _showAddNodeDialog(context, sectionKey, title);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Section Items
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Tap (+) to add items to $title',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                              ),
                            )
                          else
                            Column(
                              children: items.map((node) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(node.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                            if (node.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(node.description, style: TextStyle(fontSize: 12, color: textSecondary)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                                        onSelected: (act) {
                                          if (act == 'delete') {
                                            provider.deleteCareerNode(node.id);
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
                    ),

                    // Floating Vertical Connector (if not last)
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.6),
                              (_sections[idx + 1]['color'] as Color).withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
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
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to $sectionTitle', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title (e.g. React & Flutter Architecture)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Details / Description (Optional)'),
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
                provider.addCareerNode(
                  CareerRoadmapNode(
                    id: 'cr_${DateTime.now().millisecondsSinceEpoch}',
                    section: sectionKey,
                    title: title,
                    description: descCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
