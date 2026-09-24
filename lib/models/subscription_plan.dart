class SubscriptionPlan {
  final String id;
  final String nameEn;
  final String nameBn;
  final int batchLimit; // -1 means unlimited
  final int studentLimit; // -1 means unlimited
  final double priceMonthly; // in BDT Taka
  final String descriptionEn;
  final String descriptionBn;
  final List<String> featuresEn;
  final List<String> featuresBn;

  const SubscriptionPlan({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.batchLimit,
    required this.studentLimit,
    required this.priceMonthly,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.featuresEn,
    required this.featuresBn,
  });

  bool get isUnlimitedBatches => batchLimit == -1;
  bool get isUnlimitedStudents => studentLimit == -1;
  bool get isFree => priceMonthly == 0;

  double calculatePrice(int months) {
    if (isFree) return 0;
    return priceMonthly * months;
  }

  static const List<SubscriptionPlan> defaultPlans = [
    SubscriptionPlan(
      id: 'free',
      nameEn: 'Free Tier',
      nameBn: 'ফ্রি প্ল্যান',
      batchLimit: 5,
      studentLimit: 10,
      priceMonthly: 0,
      descriptionEn: 'Default starter package for new tutors',
      descriptionBn: 'নতুন গৃহশিক্ষকদের জন্য বিনামূল্যে প্রাথমিক প্যাকেজ',
      featuresEn: [
        'Up to 5 Batches',
        'Up to 10 Students',
        'Offline Hive storage',
        'Firebase cloud sync',
      ],
      featuresBn: [
        'সর্বোচ্চ ৫টি ব্যাচ',
        'সর্বোচ্চ ১০ জন শিক্ষার্থী',
        'অফলাইন মেমোরি স্টোরেজ',
        'ফায়ারবেস ক্লাউড ব্যাকআপ',
      ],
    ),
    SubscriptionPlan(
      id: 'starter',
      nameEn: 'Starter Plan',
      nameBn: 'স্টার্টার প্ল্যান',
      batchLimit: 5,
      studentLimit: 10,
      priceMonthly: 30,
      descriptionEn: 'Basic plan with premium support and cloud priority',
      descriptionBn: 'প্রিমিয়াম সাপোর্ট ও ব্যাকআপসহ বেসিক প্ল্যান',
      featuresEn: [
        '5 Batches included',
        '10 Students included',
        'High-speed cloud sync',
        'Multi-month subscription support',
      ],
      featuresBn: [
        '৫টি ব্যাচ সুবিধা',
        '১০ জন শিক্ষার্থী সুবিধা',
        'দ্রুতগতির ক্লাউড ব্যাকআপ',
        'একাধিক মাসের মেয়াদের সুবিধা',
      ],
    ),
    SubscriptionPlan(
      id: 'standard',
      nameEn: 'Standard Plan',
      nameBn: 'স্ট্যান্ডার্ড প্ল্যান',
      batchLimit: 10,
      studentLimit: 20,
      priceMonthly: 50,
      descriptionEn: 'Most popular plan for growing tuition centers',
      descriptionBn: 'জনপ্রিয় প্যাকেজ বর্ধনশীল টিউশন ও ব্যাচের জন্য',
      featuresEn: [
        'Up to 10 Batches',
        'Up to 20 Students',
        'Priority ledger calculations',
        'Instant multi-month renewal',
      ],
      featuresBn: [
        'সর্বোচ্চ ১০টি ব্যাচ',
        'সর্বোচ্চ ২০ জন শিক্ষার্থী',
        'হিসাব ও লেজার দ্রুত তৈরি',
        'একাধিক মাসের সহজ সাবস্ক্রিপশন',
      ],
    ),
    SubscriptionPlan(
      id: 'unlimited',
      nameEn: 'Unlimited Pro',
      nameBn: 'আনলিমিটেড প্রো',
      batchLimit: -1,
      studentLimit: -1,
      priceMonthly: 200,
      descriptionEn: 'Unlimited batches and students for coaching centers',
      descriptionBn: 'কোচিং সেন্টার ও পেশাদারদের জন্য সীমাহীন সুবিধা',
      featuresEn: [
        'Unlimited Batches',
        'Unlimited Students',
        'Full cloud backup & sync',
        '24/7 dedicated support',
      ],
      featuresBn: [
        'সীমাহীন (আনলিমিটেড) ব্যাচ',
        'সীমাহীন (আনলিমিটেড) শিক্ষার্থী',
        'সম্পূর্ণ ক্লাউড ব্যাকআপ ও সিঙ্ক',
        '২৪/৭ কাস্টমার সাপোর্ট',
      ],
    ),
  ];

  static SubscriptionPlan getById(String id) {
    return defaultPlans.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultPlans.first,
    );
  }
}
