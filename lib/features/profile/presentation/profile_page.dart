import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/app/providers/auth_provider.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/auth/presentation/login_page.dart';

import 'package:win33/features/profile/data/user_repository.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/features/wallet/presentation/wallet_home_page.dart';

import 'widgets/profile_edit_form.dart';
import 'package:win33/core/widgets/common/skeleton.dart';
import 'package:win33/core/widgets/common/fade_wrapper.dart';

/// Repo provider
final userRepositoryProvider = Provider((ref) => UserRepository());

/// Device list provider
final devicesProvider = FutureProvider.autoDispose<List<DeviceModel>>((
  ref,
) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.getDevices();
});

/// Local deviceId provider (from AppPrefs)
final localDeviceIdProvider = FutureProvider<String?>((ref) async {
  return await AppPrefs.getDeviceId();
});

Widget _walletInfoItem({
  required String title,
  required String value,
  required Color color,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.black45),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: color,
        ),
      ),
    ],
  );
}


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final localDeviceIdAsync = ref.watch(localDeviceIdProvider);

    return FadeWrapper(
      child: userAsync.when(
        loading: () => _buildSkeletonLoader(),

        error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),

        data: (user) {
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text("No user data found")),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),

            body: FadeWrapper(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),

                  child: Column(
                    children: [
                      // Avatar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.fastOutSlowIn,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        child: Text("${user.firstName} ${user.lastName}"),
                      ),

                      Text(
                        user.phone,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),
                      const ProfileEditForm(),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _infoTile(
                              svgPath: "assets/icons/mobile_check.svg",
                              title: "My Phone",
                              value: user.phone,
                              subtitle: "Verified",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoTile(
                              svgPath: "assets/icons/mail.svg",
                              title: "My Email",
                              value: user.email ?? "Not Provided",
                              subtitle: user.email != null
                                  ? "Updated"
                                  : "Missing",
                            ),
                          ),
                        ],
                      ),

                      // ------------------------------
                      // WALLET SUMMARY (Live Data)
                      // ------------------------------
                      const SizedBox(height: 24),

                      Consumer(
                        builder: (context, ref, _) {
                          final walletAsync = ref.watch(walletBalanceProvider);

                          return walletAsync.when(
                            loading: () => Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),

                            error: (e, _) => Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Text("Wallet error: $e"),
                            ),

                            data: (wallet) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WalletHomePage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: const [
                                          Text(
                                            "Wallet Summary",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Values
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _walletInfoItem(
                                            title: "Available",
                                            value:
                                                "₹${wallet.availableBalance.toStringAsFixed(2)}",
                                            color: Colors.green,
                                          ),
                                          _walletInfoItem(
                                            title: "Balance",
                                            value:
                                                "₹${wallet.totalBalance.toStringAsFixed(2)}",
                                            color: Colors.blue,
                                          ),
                                          _walletInfoItem(
                                            title: "Commission",
                                            value:
                                                "₹${wallet.commissionPending.toStringAsFixed(2)}",
                                            color: Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // ------------------------------
                      // WALLET TILE (Navigation)
                      // ------------------------------
                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Wallet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletHomePage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Wallet & Transactions",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Check balance, deposit & history",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      // Devices section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Logged in devices",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // DEVICE LIST BOX
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: devicesAsync.when(
                          loading: () => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, _) => SizedBox(
                            height: 120,
                            child: Center(
                              child: Text("Failed to load devices: $err"),
                            ),
                          ),

                          data: (devices) {
                            if (devices.isEmpty) {
                              return const SizedBox(
                                height: 80,
                                child: Center(
                                  child: Text("No active devices found"),
                                ),
                              );
                            }

                            final localDeviceId = localDeviceIdAsync.value;

                            return Column(
                              children: devices.map((d) {
                                final isThisDevice =
                                    d.deviceId == localDeviceId;

                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isThisDevice
                                              ? Colors.green.withOpacity(0.15)
                                              : AppColors.thunderbird400
                                                    .withOpacity(0.06),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isThisDevice
                                              ? Icons.smartphone
                                              : Icons.devices,
                                          color: Colors.black54,
                                        ),
                                      ),

                                      title: Text(
                                        d.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _deviceSubtitle(d),
                                        style: const TextStyle(fontSize: 13),
                                      ),

                                      trailing: isThisDevice
                                          ? Chip(
                                              label: const Text("This device"),
                                              backgroundColor: Colors.green
                                                  .withOpacity(0.12),
                                            )
                                          : TextButton(
                                              onPressed: () =>
                                                  _confirmRevokeDevice(
                                                    context,
                                                    ref,
                                                    d,
                                                  ),
                                              child: const Text(
                                                "Revoke",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const Divider(),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),
                      _logoutButton(context, ref),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------
  // SKELETON LOADER
  // ------------------------------------------------------
  Widget _buildSkeletonLoader() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            SizedBox(height: 60),
            Skeleton(height: 80, width: 80, radius: 40),
            SizedBox(height: 20),
            Skeleton(height: 20, width: 140),
            SizedBox(height: 10),
            Skeleton(height: 16, width: 100),
            SizedBox(height: 30),
            Skeleton(height: 180),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // INFO TILE
  // ------------------------------------------------------
  Widget _infoTile({
    required String svgPath,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.thunderbird400.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(svgPath, width: 20, height: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // LOGOUT BUTTON
  // ------------------------------------------------------
  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showLogoutDialog(context, ref),
        child: const Text(
          "Logout",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // LOGOUT DIALOG
  // ------------------------------------------------------
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Logout",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),

      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: 0.9 + (anim.value * 0.1),
          child: Opacity(
            opacity: anim.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Logout?"),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                    ref.invalidate(userProvider);

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------
  // DEVICE UTILITY
  // ------------------------------------------------------
  String _deviceSubtitle(DeviceModel d) {
    final parts = <String>[];
    if (d.ip != null && d.ip!.isNotEmpty) parts.add(d.ip!);
    if (d.lastSeen != null)
      parts.add("Last seen ${_readableDate(d.lastSeen!)}");
    return parts.isEmpty ? 'Not available' : parts.join(' • ');
  }

  String _readableDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 1) return "${diff.inDays}d ago";
    if (diff.inHours >= 1) return "${diff.inHours}h ago";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m ago";
    return "just now";
  }

  // ------------------------------------------------------
  // REVOKE DEVICE
  // ------------------------------------------------------
  void _confirmRevokeDevice(
    BuildContext context,
    WidgetRef ref,
    DeviceModel d,
  ) async {
    final localDeviceId = await AppPrefs.getDeviceId();
    final isThisDevice = d.deviceId == localDeviceId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Revoke device?"),
        content: Text(
          isThisDevice
              ? "You are revoking THIS device. You will be logged out immediately."
              : "Revoke access for '${d.name}'?",
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(userRepositoryProvider);

              try {
                await repo.revokeDevice(d.deviceId);

                // 🔥 If THIS DEVICE is revoked → logout immediately
                if (isThisDevice) {
                  await ref.read(authProvider.notifier).logout();
                  ref.invalidate(userProvider);

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                  return;
                }

                // Otherwise just refresh
                ref.invalidate(devicesProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Device revoked")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to revoke: $e")),
                  );
                }
              }
            },
            child: const Text("Revoke"),
          ),
        ],
      ),
    );
  }
}
