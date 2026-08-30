import 'package:flutter/material.dart';
import 'pro_plans_screen.dart';

/// PricingScreen delegates directly to [ProPlansScreen] for unified plan comparison.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProPlansScreen();
  }
}
