import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/auth/presentation/unauthorized_page.dart';
import 'package:win33/features/profile/presentation/profile_page.dart';

class ReusableAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ReusableAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: _buildSkeleton,
      error: (_, __) => _buildGuestBar(context),
      data: (user) =>
          user == null ? _buildGuestBar(context) : _buildUserBar(context, user),
    );
  }

  // --------------------------------------------------------------------------
  // SKELETON
  // --------------------------------------------------------------------------
  AppBar _buildSkeleton() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          _skeleton(52, 52, radius: 50),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeleton(100, 16),
              const SizedBox(height: 8),
              _skeleton(80, 14),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _skeleton(30, 30),
        ),
      ],
    );
  }

  Widget _skeleton(double w, double h, {double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // GUEST BAR
  // --------------------------------------------------------------------------
  AppBar _buildGuestBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 80,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UnauthorizedPage()),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Text(
                "G",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Guest User",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Login to continue",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UnauthorizedPage()),
            );
          },
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 30,
            color: AppColors.thunderbird400,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // LOGGED-IN BAR
  // --------------------------------------------------------------------------
  AppBar _buildUserBar(BuildContext context, dynamic user) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.firstName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                user.phone,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 30,
                color: AppColors.thunderbird400,
              ),
            ),
            if (user.unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.thunderbird400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
