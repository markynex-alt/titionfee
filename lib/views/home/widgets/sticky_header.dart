import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import '../../../utils/app_colors.dart';

class HomeStickyHeader extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  HomeStickyHeader({
    required this.minHeight,
    required this.maxHeight,
  });

  static const String _cachedNameKey = 'cached_user_display_name';

  Future<String> _getUserDisplayName(User? user) async {
    // Open or retrieve your app's settings/cache box
    final box = await Hive.openBox('app_settings');

    // 1. Try Firebase User display name
    final dName = user?.displayName;
    if (dName != null && dName.trim().isNotEmpty) {
      await box.put(_cachedNameKey, dName.trim());
      return dName.trim();
    }

    // 2. Try fetching updated user info (if online)
    if (user != null) {
      try {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        final updatedDName = updatedUser?.displayName;
        if (updatedDName != null && updatedDName.trim().isNotEmpty) {
          await box.put(_cachedNameKey, updatedDName.trim());
          return updatedDName.trim();
        }
      } catch (_) {
        // Ignored for offline support
      }

      // 3. Try Google Sign-In silently (if online)
      try {
        final googleAccount = await GoogleSignIn().signInSilently();
        final gName = googleAccount?.displayName;
        if (gName != null && gName.trim().isNotEmpty) {
          await box.put(_cachedNameKey, gName.trim());
          return gName.trim();
        }
      } catch (_) {
        // Ignored for offline support
      }

      // 4. Fallback to Email username
      final email = user.email;
      if (email != null && email.contains('@')) {
        final emailName = email.split('@').first;
        if (emailName.isNotEmpty) {
          final formattedName = emailName[0].toUpperCase() + emailName.substring(1);
          await box.put(_cachedNameKey, formattedName);
          return formattedName;
        }
      }
    }

    // 5. Offline Fallback: Retrieve cached name from Hive
    final cachedName = box.get(_cachedNameKey) as String?;
    if (cachedName != null && cachedName.trim().isNotEmpty) {
      return cachedName.trim();
    }

    // 6. Final default fallback
    return 'User';
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;

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
                  return FutureBuilder<String>(
                    future: _getUserDisplayName(user),
                    builder: (context, nameSnapshot) {
                      final name = nameSnapshot.data ?? 'User';
                      final firstName = name.split(' ').first;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hello, $firstName 👋\nHave a great day ahead!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /*Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),*/
                const SizedBox(width: 12),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final photoUrl = user?.photoURL;

                    return CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white24,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 34,
                          height: 34,
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