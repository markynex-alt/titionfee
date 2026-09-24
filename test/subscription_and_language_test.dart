import 'package:flutter_test/flutter_test.dart';
import 'package:tuition_fee/models/subscription_plan.dart';
import 'package:tuition_fee/utils/app_strings.dart';

void main() {
  group('Subscription Plans & Pricing Tests', () {
    test('Default subscription plans are defined correctly', () {
      final plans = SubscriptionPlan.defaultPlans;
      expect(plans.length, 4);

      final free = SubscriptionPlan.getById('free');
      expect(free.priceMonthly, 0);
      expect(free.batchLimit, 5);
      expect(free.studentLimit, 10);
      expect(free.isFree, isTrue);

      final starter = SubscriptionPlan.getById('starter');
      expect(starter.priceMonthly, 30);
      expect(starter.batchLimit, 5);
      expect(starter.studentLimit, 10);
      expect(starter.calculatePrice(1), 30);
      expect(starter.calculatePrice(3), 90);

      final standard = SubscriptionPlan.getById('standard');
      expect(standard.priceMonthly, 50);
      expect(standard.batchLimit, 10);
      expect(standard.studentLimit, 20);
      expect(standard.calculatePrice(1), 50);
      expect(standard.calculatePrice(6), 300);

      final unlimited = SubscriptionPlan.getById('unlimited');
      expect(unlimited.priceMonthly, 200);
      expect(unlimited.batchLimit, -1);
      expect(unlimited.studentLimit, -1);
      expect(unlimited.isUnlimitedBatches, isTrue);
      expect(unlimited.isUnlimitedStudents, isTrue);
      expect(unlimited.calculatePrice(12), 2400);
    });
  });

  group('Localization (English & Bengali) Tests', () {
    test('English translations return valid values', () {
      expect(AppStrings.get('nav_home', lang: 'en'), 'Home');
      expect(AppStrings.get('nav_batch', lang: 'en'), 'Batch');
      expect(AppStrings.get('nav_students', lang: 'en'), 'Students');
      expect(AppStrings.get('nav_settings', lang: 'en'), 'Settings');
      expect(AppStrings.get('batches_title', lang: 'en'), 'Batches');
      expect(AppStrings.get('students_title', lang: 'en'), 'Students');
    });

    test('Bengali translations return expected Bangla text', () {
      expect(AppStrings.get('nav_home', lang: 'bn'), 'হোম');
      expect(AppStrings.get('nav_batch', lang: 'bn'), 'ব্যাচ');
      expect(AppStrings.get('nav_students', lang: 'bn'), 'শিক্ষার্থী');
      expect(AppStrings.get('nav_settings', lang: 'bn'), 'সেটিংস');
      expect(AppStrings.get('batches_title', lang: 'bn'), 'ব্যাচসমূহ');
      expect(AppStrings.get('students_title', lang: 'bn'), 'শিক্ষার্থীবৃন্দ');
    });
  });
}
