import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'career_roadmap_screen.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final careerTasks =
        provider.tasks.where((t) => t.category == 'Career Roadmap').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

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
          'Career Pathways & Goals',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'career_screen_fab',
        backgroundColor: primaryColor,
        elevation: 6,
        icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
        label: const Text(
          'Floating Roadmap',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CareerRoadmapScreen(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Rank & XP Header Banner (Refer to Image 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelCareer,
                borderRadius: BorderRadius.circular(22),
                border: isDark
                    ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkIconBg
                          : AppTheme.pastelCareerIcon,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.work_outline_rounded,
                      color: isDark ? AppTheme.darkIconGlow : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Career Pathways',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pathways & Goals 🎯',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Floating Interactive Roadmap Hero Card
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132F5C) : const Color(0xFFFFECE5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interactive Node Map',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Drag, zoom & connect skill nodes live',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active Milestones List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Milestone Pathways',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  '${careerTasks.length} Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (careerTasks.isEmpty) ...[
              _buildPathwayProgressCard(
                title: 'Make-up graduate',
                subtitle: 'Pathways & Goal Goals',
                progress: 0.60,
                icon: Icons.school_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPathwayProgressCard(
                title: 'Complete intention',
                subtitle: 'Draft your goals',
                progress: 0.40,
                icon: Icons.edit_note_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPathwayProgressCard(
                title: 'Develop commissions',
                subtitle: 'Contribution',
                progress: 0.25,
                icon: Icons.lightbulb_outline_rounded,
                isDark: isDark,
              ),
            ] else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: careerTasks.length,
                itemBuilder: (context, index) {
                  final task = careerTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: isDark
                          ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkIconBg : AppTheme.pastelCareer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            task.isCompleted ? Icons.check_rounded : Icons.flag_rounded,
                            color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPathwayProgressCard({
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
    required bool isDark,
  }) {
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkIconBg : AppTheme.pastelCareer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelCareerIcon,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF4C658A) : const Color(0xFF8D827A),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFECE5),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.darkPrimary : AppTheme.pastelCareer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
