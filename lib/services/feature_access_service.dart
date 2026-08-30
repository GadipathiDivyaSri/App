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
  static bool hasAccess(
    AppFeature feature, {
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    return config.accessibleFeatures.contains(feature);
  }

  /// Reusable method to get max habit limit for a plan (returns 2 on Free, -1 for unlimited on Pro)
  static int getHabitLimit([SubscriptionPlanType plan = SubscriptionPlanType.free]) {
    return SubscriptionRegistry.getConfig(plan).maxHabits;
  }

  /// Reusable method to get max subject limit for a plan (returns 2 on Free, -1 for unlimited on Pro)
  static int getSubjectLimit([SubscriptionPlanType plan = SubscriptionPlanType.free]) {
    return SubscriptionRegistry.getConfig(plan).maxSubjects;
  }

  /// Reusable method to check if a plan is Pro
  static bool isProUser([SubscriptionPlanType plan = SubscriptionPlanType.free]) {
    return plan == SubscriptionPlanType.pro;
  }

  /// Detailed permission evaluation returning structured error & upgrade prompt if denied
  static FeatureAccessResult checkAccess(
    AppFeature feature, {
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final allowed = hasAccess(feature, plan: plan);
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
    required int currentHabitCount,
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    if (config.isHabitsUnlimited) return true;
    return currentHabitCount < config.maxHabits;
  }

  /// Evaluates whether a new study subject can be added given current subject count and plan
  static bool canCreateSubject({
    required int currentSubjectCount,
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final config = SubscriptionRegistry.getConfig(plan);
    if (config.isSubjectsUnlimited) return true;
    return currentSubjectCount < config.maxSubjects;
  }

  /// Calculate remaining slots for habits (-1 for unlimited)
  static int getRemainingHabitSlots({
    required int currentCount,
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final max = getHabitLimit(plan);
    if (max == SubscriptionRegistry.unlimited) return SubscriptionRegistry.unlimited;
    final remaining = max - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Calculate remaining slots for subjects (-1 for unlimited)
  static int getRemainingSubjectSlots({
    required int currentCount,
    SubscriptionPlanType plan = SubscriptionPlanType.free,
  }) {
    final max = getSubjectLimit(plan);
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
