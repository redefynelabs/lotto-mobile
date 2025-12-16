import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/app/providers/auth_provider.dart';
import 'package:win33/app/providers/wallet_provider.dart';

import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/auth/presentation/login_page.dart';
import 'package:win33/features/profile/data/user_repository.dart';
import 'package:win33/features/profile/presentation/loggedin_devices.dart';
import 'package:win33/features/profile/presentation/my_bid_history.dart';
import 'package:win33/features/profile/presentation/widgets/profile_edit_form.dart';

import 'package:win33/features/wallet/presentation/wallet_home_page.dart';
import 'package:win33/core/widgets/common/skeleton.dart';
import 'package:win33/core/widgets/common/fade_wrapper.dart';

import 'package:win33/features/bid/data/bidding_repository.dart';
import 'package:win33/features/bid/data/model/bid_model.dart';

/// Repo provider
final userRepositoryProvider = Provider((ref) => UserRepository());

/// Fetch last 5 bids
final lastFiveBidsProvider = FutureProvider<List<BidModel>>((ref) async {
  final repo = BiddingRepository.instance;
  final all = await repo.getMyBids();
  if (all.length <= 5) return all;
  return all.take(5).toList();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final auth = ref.watch(authProvider);

    if (!auth.isLoggedIn) {
      // User is not authenticated → block page
      return const LoginPage();
    }

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
                iconSize: 20,
                icon: SvgPicture.asset(
                  'assets/icons/arrow-left.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontFamily: "Coolvetica",

                  fontSize: 22,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------------------------------
                      // AVATAR + USER DETAILS
                      // -------------------------------
                      Center(child: _avatarLetter(user.firstName)),

                      const SizedBox(height: 20),

                      // -------------------------------
                      // Edit Profile Form
                      // -------------------------------
                      const ProfileEditForm(),

                      const SizedBox(height: 25),

                      // -------------------------------
                      // LAST 5 BIDS SECTION
                      // -------------------------------
                      const Text(
                        "Recent Bids",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: "Coolvetica",

                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Consumer(
                        builder: (context, ref, _) {
                          final bidsAsync = ref.watch(lastFiveBidsProvider);

                          return bidsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Text("Failed to load bids: $e"),

                            data: (bids) {
                              if (bids.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "No recent bids",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  ...bids.map((b) => _bidItem(b)).toList(),
                                  const SizedBox(height: 10),

                                  // View All Button → MyBidHistoryPage
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MyBidHistoryPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "View All →",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // -------------------------------
                      // WALLET SUMMARY
                      // -------------------------------
                      _walletSection(ref, context),

                      const SizedBox(height: 24),

                      // -------------------------------
                      // LOGGED-IN DEVICES BUTTON
                      // -------------------------------
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: SvgPicture.asset(
                            'assets/icons/monitor-mobbile.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: const Text(
                            "Logged-in Devices",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontFamily: "Coolvetica",

                              color: Colors.black87,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoggedInDevicesPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -------------------------------
                      // Logout Button
                      // -------------------------------
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

  Widget _avatarLetter(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Stack(
      alignment: Alignment.center,
      children: [
        // MAIN PLACEHOLDER AVATAR IMAGE
        const CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/images/avatar.jpg'),
          backgroundColor: Colors.transparent,
        ),

        // BOTTOM-RIGHT LETTER BADGE
        Positioned(
          bottom: 3,
          right: 3,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Coolvetica",
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------
  // BID ITEM UI
  // ------------------------------
  Widget _bidItem(BidModel b) {
    final isJp = b.jpNumbers != null && b.jpNumbers!.isNotEmpty;
    final jpList = b.jpNumbers ?? [];
    final number = b.number ?? 0;
    final count = b.count ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- HEADER (Name + Amount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Coolvetica",
                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                "RM ${double.parse(b.amount.toString()).toStringAsFixed(2)}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------------- NUMBERS UI
          isJp
              ? Wrap(
                  spacing: 8,
                  children: jpList.map((n) {
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA500),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        n.toString().padLeft(2, "0"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

          const SizedBox(height: 12),

          // ---------------- SLOT
          Text(
            "Slot: ${b.uniqueBidId}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),

          const SizedBox(height: 4),

          // ---------------- DATE
          Text(
            DateFormat("MMM dd, HH:mm").format(b.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // WALLET SECTION
  // ------------------------------
  Widget _walletSection(WidgetRef ref, BuildContext context) {
    final walletAsync = ref.watch(walletBalanceProvider);

    return walletAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("Wallet error: $e"),
      data: (wallet) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletHomePage()),
            );
          },

          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Wallet Summary",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: "Coolvetica",
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _walletItem(
                      title: "Available",
                      value: "₹${wallet.availableBalance.toStringAsFixed(2)}",
                      color: Colors.green,
                    ),
                    _walletItem(
                      title: "Balance",
                      value: "₹${wallet.totalBalance.toStringAsFixed(2)}",
                      color: Colors.blue,
                    ),
                    _walletItem(
                      title: "Commission",
                      value: "₹${wallet.commissionPending.toStringAsFixed(2)}",
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
  }

  Widget _walletItem({
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

  // ------------------------------
  // LOGOUT BUTTON
  // ------------------------------
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to logout?"),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
    );
  }

  // ------------------------------
  // SKELETON LOADER
  // ------------------------------
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
}
