import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/config/subscription_config.dart';
import 'package:productivity_app/services/feature_access_service.dart';

void main() {
  group('Subscription & Feature Access Architecture Tests', () {
    test('1. Free Plan Feature Access Specifications', () {
      const freePlan = SubscriptionPlanType.free;

      // Free allowed features
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.todo), isTrue);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.calendar), isTrue);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.habits), isTrue);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.subjects), isTrue);

      // Pro-exclusive locked features on Free
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.goals), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.priorityMatrix), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.eisenhowerMatrix), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.expenseTracker), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.notes), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.milestones), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.careerRoadmap), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.focusTimer), isFalse);
      expect(FeatureAccessService.hasAccess(plan: freePlan, feature: AppFeature.analytics), isFalse);
    });

    test('2. Free Plan Limit Rules (Max 2 Habits & Max 2 Subjects)', () {
      const freePlan = SubscriptionPlanType.free;

      // Habits Limit (Max 2)
      expect(FeatureAccessService.getMaxHabits(freePlan), 2);
      expect(FeatureAccessService.canCreateHabit(plan: freePlan, currentHabitCount: 0), isTrue);
      expect(FeatureAccessService.canCreateHabit(plan: freePlan, currentHabitCount: 1), isTrue);
      expect(FeatureAccessService.canCreateHabit(plan: freePlan, currentHabitCount: 2), isFalse);
      expect(FeatureAccessService.canCreateHabit(plan: freePlan, currentHabitCount: 3), isFalse);
      expect(FeatureAccessService.getRemainingHabitSlots(plan: freePlan, currentCount: 1), 1);
      expect(FeatureAccessService.getRemainingHabitSlots(plan: freePlan, currentCount: 2), 0);

      // Subjects Limit (Max 2)
      expect(FeatureAccessService.getMaxSubjects(freePlan), 2);
      expect(FeatureAccessService.canCreateSubject(plan: freePlan, currentSubjectCount: 0), isTrue);
      expect(FeatureAccessService.canCreateSubject(plan: freePlan, currentSubjectCount: 1), isTrue);
      expect(FeatureAccessService.canCreateSubject(plan: freePlan, currentSubjectCount: 2), isFalse);
      expect(FeatureAccessService.canCreateSubject(plan: freePlan, currentSubjectCount: 5), isFalse);
      expect(FeatureAccessService.getRemainingSubjectSlots(plan: freePlan, currentCount: 0), 2);
      expect(FeatureAccessService.getRemainingSubjectSlots(plan: freePlan, currentCount: 2), 0);
    });

    test('3. Pro Plan Feature Access Specifications (All Features Unlocked & Unlimited)', () {
      const proPlan = SubscriptionPlanType.pro;

      // Verify all 13 features are unlocked
      for (final feature in AppFeature.values) {
        final result = FeatureAccessService.checkAccess(plan: proPlan, feature: feature);
        expect(result.isAllowed, isTrue, reason: 'Feature ${feature.name} should be allowed on Pro');
      }

      // Verify unlimited habits & subjects
      expect(FeatureAccessService.getMaxHabits(proPlan), SubscriptionRegistry.unlimited);
      expect(FeatureAccessService.getMaxSubjects(proPlan), SubscriptionRegistry.unlimited);
      expect(FeatureAccessService.canCreateHabit(plan: proPlan, currentHabitCount: 100), isTrue);
      expect(FeatureAccessService.canCreateSubject(plan: proPlan, currentSubjectCount: 100), isTrue);
    });

    test('4. Plan Registry Parsing & Extensibility', () {
      expect(SubscriptionRegistry.parsePlanString('FREE'), SubscriptionPlanType.free);
      expect(SubscriptionRegistry.parsePlanString('free'), SubscriptionPlanType.free);
      expect(SubscriptionRegistry.parsePlanString('PRO'), SubscriptionPlanType.pro);
      expect(SubscriptionRegistry.parsePlanString('PRO_MONTHLY'), SubscriptionPlanType.pro);
      expect(SubscriptionRegistry.parsePlanString('PREMIUM'), SubscriptionPlanType.pro);
      expect(SubscriptionRegistry.parsePlanString(null), SubscriptionPlanType.free);

      final proExclusive = FeatureAccessService.getProExclusiveFeatures();
      expect(proExclusive.length, 9);
      expect(proExclusive.contains(AppFeature.goals), isTrue);
      expect(proExclusive.contains(AppFeature.analytics), isTrue);
      expect(proExclusive.contains(AppFeature.todo), isFalse);
    });
  });
}
