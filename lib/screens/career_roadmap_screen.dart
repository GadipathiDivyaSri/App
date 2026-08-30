import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/premium_lock_banner.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';

/// Floating / Flexible Career Roadmap Screen for WrindhaOS
/// 
/// Flexible structure:
/// Career Goal → Skills → Learning → Projects → Experience → Career Opportunities
/// Completely free of rigid milestone stages.
class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
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
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;

    final allNodes = provider.careerRoadmap;
    final totalCompleted = allNodes.where((n) => n.isCompleted).length;

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
          'Career Roadmap',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkIconBg : AppTheme.pastelCareer,
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
                  '$totalCompleted Done',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Lock Banner if Free
            if (!isPremium)
              const PremiumLockBanner(
                featureName: 'Career Roadmap',
                description: 'You are currently viewing Career Roadmap in preview mode. Upgrade to Pro for ₹49/month to customize floating path nodes and unlock infinite growth tracking.',
              ),

            const Text(
              'FLEXIBLE PATHWAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Personalized Career Map',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Floating structure that adapts as you grow. Add focus targets to each stage.',
              style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
            ),
            const SizedBox(height: 24),

            // 2. Sections Flow
            ..._sections.asMap().entries.map((entry) {
              final idx = entry.key;
              final sec = entry.value;
              final String secKey = sec['key'] as String;
              final String secTitle = sec['title'] as String;
              final String secDesc = sec['desc'] as String;
              final Color secColor = sec['color'] as Color;
              final IconData secIcon = sec['icon'] as IconData;
              final isLast = idx == _sections.length - 1;

              final items = allNodes.where((n) => n.section == secKey).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCardBorder : secColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
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
                                    color: secColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(secIcon, color: secColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      secTitle,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      secDesc,
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                !isPremium ? Icons.lock_rounded : Icons.add_circle_outline_rounded,
                                color: secColor,
                                size: 22,
                              ),
                              onPressed: () {
                                if (!isPremium) {
                                  showUpgradeProModal(
                                    context,
                                    featureTitle: 'Career Roadmap ($secTitle)',
                                    limitExplanation: 'Upgrade to Pro for ₹49/month to add unlimited custom nodes to your career roadmap.',
                                  );
                                } else {
                                  _showAddNodeDialog(context, secKey, secTitle);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Section Items List
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Tap (+) to add items to $secTitle',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                            ),
                          )
                        else
                          Column(
                            children: items.map((node) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: secColor.withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => provider.toggleCareerNode(node.id),
                                      child: Icon(
                                        node.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: node.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            node.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              decoration: node.isCompleted ? TextDecoration.lineThrough : null,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (node.description.isNotEmpty)
                                            Text(
                                              node.description,
                                              style: TextStyle(fontSize: 12, color: textSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
                                      onPressed: () => provider.deleteCareerNode(node.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Floating Connecting Indicator (Unless last)
                  if (!isLast)
                    Center(
                      child: Container(
                        width: 2,
                        height: 20,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: secColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddNodeDialog(BuildContext context, String secKey, String secTitle) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to $secTitle', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Notes / Target (Optional)', border: OutlineInputBorder()),
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
                    id: 'node_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    description: descCtrl.text.trim(),
                    section: secKey,
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
