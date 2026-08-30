import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/config/subscription_config.dart';
import 'package:productivity_app/models/models.dart';
import 'package:productivity_app/services/feature_access_service.dart';

void main() {
  group('Subscription & Feature Access Architecture Tests', () {
    test('1. UserSubscription Model & JSON Serialization', () {
      final json = {
        'id': 'sub_123',
        'user_id': 'u_test',
        'plan': 'pro',
        'status': 'active',
        'started_at': '2026-08-30T10:00:00.000Z',
        'expires_at': '2026-09-30T10:00:00.000Z',
        'payment_provider': 'GOOGLE_PLAY',
        'transaction_id': 'GPA.1234-5678-9012',
        'created_at': '2026-08-30T10:00:00.000Z',
        'updated_at': '2026-08-30T10:00:00.000Z',
      };

      final sub = UserSubscription.fromJson(json);
      expect(sub.userId, 'u_test');
      expect(sub.plan, 'pro');
      expect(sub.isPro, isTrue);
      expect(sub.isActive, isTrue);
      expect(sub.paymentProvider, 'GOOGLE_PLAY');
      expect(sub.transactionId, 'GPA.1234-5678-9012');

      final serialized = sub.toJson();
      expect(serialized['plan'], 'pro');
      expect(serialized['status'], 'active');
      expect(serialized['payment_provider'], 'GOOGLE_PLAY');
    });

    test('2. Default Free Plan Auto-Provisioning', () {
      final freeSub = UserSubscription.defaultFree('u_new_user');
      expect(freeSub.userId, 'u_new_user');
      expect(freeSub.plan, 'free');
      expect(freeSub.status, 'active');
      expect(freeSub.isPro, isFalse);
      expect(freeSub.isFree, isTrue);
    });

    test('3. Free Plan Feature Access: Allowed, Limited, and Locked Rules', () {
      const freePlan = SubscriptionPlanType.free;

      // Reusable helper methods
      expect(FeatureAccessService.isProUser(freePlan), isFalse);
      expect(FeatureAccessService.getHabitLimit(freePlan), 2);
      expect(FeatureAccessService.getSubjectLimit(freePlan), 2);

      // FREE ALLOWED
      expect(FeatureAccessService.hasAccess(AppFeature.todo, plan: freePlan), isTrue);
      expect(FeatureAccessService.hasAccess(AppFeature.calendar, plan: freePlan), isTrue);

      // FREE LIMITED
      expect(FeatureAccessService.hasAccess(AppFeature.habits, plan: freePlan), isTrue);
      expect(FeatureAccessService.hasAccess(AppFeature.subjects, plan: freePlan), isTrue);
      expect(FeatureAccessService.canCreateHabit(currentHabitCount: 0, plan: freePlan), isTrue);
      expect(FeatureAccessService.canCreateHabit(currentHabitCount: 1, plan: freePlan), isTrue);
      expect(FeatureAccessService.canCreateHabit(currentHabitCount: 2, plan: freePlan), isFalse);
      expect(FeatureAccessService.canCreateSubject(currentSubjectCount: 0, plan: freePlan), isTrue);
      expect(FeatureAccessService.canCreateSubject(currentSubjectCount: 2, plan: freePlan), isFalse);

      // FREE LOCKED
      final lockedFeatures = [
        AppFeature.goals,
        AppFeature.priorityMatrix,
        AppFeature.eisenhowerMatrix,
        AppFeature.expenseTracker,
        AppFeature.notes,
        AppFeature.milestones,
        AppFeature.careerRoadmap,
        AppFeature.focusTimer,
        AppFeature.analytics,
      ];

      for (final locked in lockedFeatures) {
        expect(
          FeatureAccessService.hasAccess(locked, plan: freePlan),
          isFalse,
          reason: '$locked must be locked on Free',
        );
        final accessResult = FeatureAccessService.checkAccess(locked, plan: freePlan);
        expect(accessResult.isAllowed, isFalse);
        expect(accessResult.requiresUpgrade, isTrue);
      }
    });

    test('4. Pro Plan Feature Access: Unlocks All Features & Unlimited Creation', () {
      const proPlan = SubscriptionPlanType.pro;

      expect(FeatureAccessService.isProUser(proPlan), isTrue);
      expect(FeatureAccessService.getHabitLimit(proPlan), SubscriptionRegistry.unlimited);
      expect(FeatureAccessService.getSubjectLimit(proPlan), SubscriptionRegistry.unlimited);

      // All 13 features must be accessible
      for (final feature in AppFeature.values) {
        expect(FeatureAccessService.hasAccess(feature, plan: proPlan), isTrue);
      }

      // Unlimited habit and subject creations
      expect(FeatureAccessService.canCreateHabit(currentHabitCount: 50, plan: proPlan), isTrue);
      expect(FeatureAccessService.canCreateSubject(currentSubjectCount: 50, plan: proPlan), isTrue);
    });
  });
}
