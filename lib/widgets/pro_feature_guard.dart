import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import 'pro_upgrade_dialog.dart';

/// Route & Widget Level Guard for Pro-Exclusive Features.
/// 
/// Provides Read Access to Free users so they can explore the UI, preview features,
/// and view sample workflows, while guarding write/create actions with the ProUpgradeDialog.
class ProFeatureGuard extends StatelessWidget {
  final AppFeature feature;
  final Widget child;

  const ProFeatureGuard({
    super.key,
    required this.feature,
    required this.child,
  });

  /// Navigates to a feature screen.
  static void navigate(
    BuildContext context, {
    required AppFeature feature,
    required Widget Function() builder,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProFeatureGuard(
          feature: feature,
          child: builder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Allows full read access for Free users to preview and explore features.
    // Write/Create operations on child screens are guarded by ProUpgradeDialog.
    return child;
  }
}
