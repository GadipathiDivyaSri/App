import '../config/subscription_config.dart';

/// Detailed result structure for feature access evaluations
class FeatureAccessResult {
  final bool isAllowed;
  final AppFeature feature;
  final SubscriptionPlanType plan;
  final String? message;
  final bool requiresUpgrade;

  const FeatureAccessResult({
    required this.isAllowed,
    required this.feature,
    required this.plan,
    this.message,
    this.requiresUpgrade = false,
  });

  factory FeatureAccessResult.granted(AppFeature feature, SubscriptionPlanType plan) {
    return FeatureAccessResult(
      isAllowed: true,
      feature: feature,
      plan: plan,
    );
  }

  factory FeatureAccessResult.denied(AppFeature feature, SubscriptionPlanType plan, {String? reason}) {
    return FeatureAccessResult(
      isAllowed: false,
      feature: feature,
      plan: plan,
      message: reason ?? '${feature.displayName} requires a WrindhaOS Pro subscription.',
      requiresUpgrade: true,
    );
  }
}

/// Centralized Feature Access Service for WrindhaOS
/// Evaluates and enforces permission rules, plan limits, and feature gates.
class FeatureAccessService {
  /// Check if a user on a given subscription plan has access to a specific application feature
  static bool hasAccess({
    required SubscriptionPlanType plan,
    required AppFeature feature,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    return config.accessibleFeatures.contains(feature);
  }

  /// Detailed permission evaluation returning structured error & upgrade prompt if denied
  static FeatureAccessResult checkAccess({
    required SubscriptionPlanType plan,
    required AppFeature feature,
  }) {
    final allowed = hasAccess(plan: plan, feature: feature);
    if (allowed) {
      return FeatureAccessResult.granted(feature, plan);
    }
    return FeatureAccessResult.denied(
      feature,
      plan,
      reason: '${feature.displayName} is an advanced tool available exclusively on WrindhaOS Pro.',
    );
  }

  /// Evaluates whether a new habit can be added given current habit count and plan
  static bool canCreateHabit({
    required SubscriptionPlanType plan,
    required int currentHabitCount,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    if (config.isHabitsUnlimited) return true;
    return currentHabitCount < config.maxHabits;
  }

  /// Evaluates whether a new study subject can be added given current subject count and plan
  static bool canCreateSubject({
    required SubscriptionPlanType plan,
    required int currentSubjectCount,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    if (config.isSubjectsUnlimited) return true;
    return currentSubjectCount < config.maxSubjects;
  }

  /// Get maximum allowed habits for a plan (-1 for unlimited)
  static int getMaxHabits(SubscriptionPlanType plan) {
    return SubscriptionRegistry.getConfig(plan).maxHabits;
  }

  /// Get maximum allowed subjects for a plan (-1 for unlimited)
  static int getMaxSubjects(SubscriptionPlanType plan) {
    return SubscriptionRegistry.getConfig(plan).maxSubjects;
  }

  /// Calculate remaining slots for habits (-1 for unlimited)
  static int getRemainingHabitSlots({
    required SubscriptionPlanType plan,
    required int currentCount,
  }) {
    final max = getMaxHabits(plan);
    if (max == SubscriptionRegistry.unlimited) return SubscriptionRegistry.unlimited;
    final remaining = max - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Calculate remaining slots for subjects (-1 for unlimited)
  static int getRemainingSubjectSlots({
    required SubscriptionPlanType plan,
    required int currentCount,
  }) {
    final max = getMaxSubjects(plan);
    if (max == SubscriptionRegistry.unlimited) return SubscriptionRegistry.unlimited;
    final remaining = max - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Get list of features that are locked on Free and require Pro
  static List<AppFeature> getProExclusiveFeatures() {
    final freeConfig = SubscriptionRegistry.freePlan;
    final proConfig = SubscriptionRegistry.proPlan;
    return proConfig.accessibleFeatures
        .where((f) => !freeConfig.accessibleFeatures.contains(f))
        .toList();
  }

  /// Get all accessible features for a specific plan
  static List<AppFeature> getAllFeaturesForPlan(SubscriptionPlanType plan) {
    return SubscriptionRegistry.getConfig(plan).accessibleFeatures.toList();
  }
}
