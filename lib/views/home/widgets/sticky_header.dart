import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../providers/app_provider.dart';
import '../../../screens/subscription_plan_screen.dart';

class HomeStickyHeader extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  HomeStickyHeader({
    required this.minHeight,
    required this.maxHeight,
  });

  String _getUserDisplayName(User? user, bool isBn) {
    if (user == null) return isBn ? "গৃহশিক্ষক" : "User";
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    if (user.email != null && user.email!.contains('@')) {
      final emailName = user.email!.split('@').first;
      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase() + emailName.substring(1);
      }
    }
    return isBn ? "গৃহশিক্ষক" : "User";
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final p = context.watch<AppProvider>();
    final isBn = p.appLanguage == 'bn';

    return SizedBox.expand(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final name = _getUserDisplayName(user, isBn);
                  final firstName = name.split(' ').first;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.organizationName.isNotEmpty
                            ? p.organizationName
                            : (isBn ? 'টিউশন ফি ম্যানেজার' : 'Tuition Fee Manager'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isBn
                            ? 'স্বাগতম, $firstName 👋'
                            : 'Hello, $firstName 👋',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => SubscriptionPlanScreen.navigate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.currentPlan.isFree ? Icons.star_border : Icons.workspace_premium,
                          color: Colors.amberAccent,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.currentPlan.isFree
                              ? (isBn ? "ফ্রি টিয়ার" : "Free")
                              : (p.planDaysRemaining != null
                                  ? "${p.currentPlan.name(p.appLanguage).split(' ').first} • ${p.planDaysRemaining}d"
                                  : p.currentPlan.name(p.appLanguage)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final photoUrl = user?.photoURL;

                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                photoUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 18),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(HomeStickyHeader oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight;
  }
}