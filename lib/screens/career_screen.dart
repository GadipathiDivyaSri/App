import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'career_roadmap_screen.dart';
import 'goal_pyramid_screen.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgCream = Color(0xFFFFF9F0);
    const textDark = Color(0xFF2D2622);
    const textMuted = Color(0xFF8D827A);
    const primaryCoral = Color(0xFFE87552);
    const cardPeach = Color(0xFFFFD4C2);
    const cardNodeBg = Color(0xFFFFF2EC);

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Career Pathways & Goals',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'career_screen_fab',
        backgroundColor: primaryCoral,
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
            // Top Career Pathways Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardPeach,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryCoral,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Career Pathways',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pathways & Goals 🎯',
                          style: TextStyle(
                            color: textMuted,
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

            // 1. Career Roadmap Card
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
                  color: cardPeach,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryCoral.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: primaryCoral,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Career Roadmap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Floating Skill & Pathway Node Graph',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: primaryCoral,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Goals (PRO Feature - Short-Term, Medium-Term & Long-Term Targets)
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final isPro = provider.user.isPremium;
                return GestureDetector(
                  onTap: () {
                    if (!isPro) {
                      ProUpgradeDialog.showFeatureLockedDialog(context, AppFeature.goals);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GoalPyramidScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardNodeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPro ? const Color(0xFF0D5CE5) : const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isPro ? const Color(0xFF0D5CE5) : const Color(0xFFF59E0B)).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPro ? Icons.military_tech_rounded : Icons.lock_rounded,
                            color: isPro ? const Color(0xFF0D5CE5) : const Color(0xFFF59E0B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Goals 🎯',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  if (!isPro) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Short-Term, Medium-Term & Long-Term Targets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isPro ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
                          size: 16,
                          color: isPro ? const Color(0xFF0D5CE5) : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
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
}
