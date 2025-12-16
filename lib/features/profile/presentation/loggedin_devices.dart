import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/profile/data/device_repository.dart';
import 'package:win33/features/profile/data/geo_service.dart';
import 'package:win33/core/storage/app_prefs.dart';

class LoggedInDevicesPage extends ConsumerWidget {
  const LoggedInDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);

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
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Logged-in Devices",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
              fontFamily: "Coolvetica",

            fontSize: 22,
          ),
        ),
      ),

      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(child: Text("No logged-in devices found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (_, i) {
              final d = devices[i];
              return _deviceTile(context, ref, d);
            },
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // User Agent Parser (Improved & Accurate)
  // ----------------------------------------------------------
  Map<String, String> parseUserAgent(String? ua) {
    if (ua == null || ua.isEmpty) {
      return {"os": "Unknown", "model": "Unknown", "browser": "Unknown"};
    }

    final lower = ua.toLowerCase();
    String os = "Unknown";
    String model = "Unknown";
    String browser = "Unknown";

    // OS detection
    if (lower.contains("android")) {
      os = "Android";
    } else if (lower.contains("iphone")) {
      os = "iOS";
    } else if (lower.contains("ipad")) {
      os = "iPadOS";
    } else if (lower.contains("mac os") || lower.contains("macintosh")) {
      os = "MacOS";
    } else if (lower.contains("windows")) {
      os = "Windows";
    }

    // Browser detection
    if (lower.contains("chrome/")) browser = "Chrome";
    if (lower.contains("safari") && !lower.contains("chrome"))
      browser = "Safari";
    if (lower.contains("firefox")) browser = "Firefox";
    if (lower.contains("edg/")) browser = "Edge";

    // Model detection (Android)
    final androidMatch = RegExp(r'Android [0-9.]+; ([^)]+)\)').firstMatch(ua);
    if (androidMatch != null) {
      model = androidMatch.group(1)?.trim() ?? "Android Device";
    }

    // iPhone
    if (os == "iOS") model = "iPhone";
    if (os == "iPadOS") model = "iPad";

    // Fallback model
    if (model == "Unknown") {
      final match = RegExp(r'\((.*?)\)').firstMatch(ua);
      if (match != null) model = match.group(1) ?? "Device";
    }

    return {"os": os, "model": model, "browser": browser};
  }

  // ----------------------------------------------------------
  // Choose Device Icon
  // ----------------------------------------------------------
  IconData getDeviceIcon(String os) {
    os = os.toLowerCase();
    if (os.contains("android")) return Icons.android;
    if (os.contains("ios") || os.contains("iphone")) return Icons.phone_iphone;
    if (os.contains("ipad")) return Icons.tablet_mac;
    if (os.contains("mac")) return Icons.laptop_mac;
    if (os.contains("windows")) return Icons.laptop_windows;
    return Icons.devices;
  }

  // ----------------------------------------------------------
  // Device Tile
  // ----------------------------------------------------------
  Widget _deviceTile(BuildContext context, WidgetRef ref, dynamic d) {
    return FutureBuilder<String?>(
      future: AppPrefs.getDeviceId(),
      builder: (context, snapshot) {
        final currentDeviceId = snapshot.data;
        final isCurrent = d["deviceId"] == currentDeviceId;

        final ua = parseUserAgent(d["userAgent"]);
        final os = ua["os"]!;
        final model = ua["model"]!;
        final browser = ua["browser"]!;
        final ip = d["ip"] ?? "Unknown";
        final icon = getDeviceIcon(os);

        // Last Login Time
        String lastLogin = "Unknown";
        try {
          if (d["createdAt"] != null) {
            final dt = DateTime.parse(d["createdAt"]).toLocal();
            lastLogin = DateFormat("dd MMM yyyy • hh:mm a").format(dt);
          }
        } catch (_) {}

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? Colors.green : Colors.black.withOpacity(0.1),
              width: isCurrent ? 2 : 1,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- Top Row ----------------
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Icon(icon, color: AppColors.primary, size: 26),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      model,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: "Coolvetica",

                        fontSize: 16,
                      ),
                    ),
                  ),

                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "This Device",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Text("OS: $os", style: const TextStyle(color: Colors.black87)),
              Text(
                "Browser: $browser",
                style: const TextStyle(color: Colors.black87),
              ),
              Text("IP: $ip", style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 4),

              Text(
                "Last Login: $lastLogin",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              // Location
              Consumer(
                builder: (_, ref, __) {
                  final locAsync = ref.watch(deviceLocationProvider(ip));

                  return locAsync.when(
                    loading: () => const Text(
                      "Location: Loading...",
                      style: TextStyle(color: Colors.black45),
                    ),
                    error: (_, __) => const Text(
                      "Location: Unknown",
                      style: TextStyle(color: Colors.black45),
                    ),
                    data: (loc) => Text(
                      "Location: $loc",
                      style: const TextStyle(color: Colors.black45),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              if (!isCurrent)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _revoke(context, ref, d["deviceId"]),
                    child: const Text(
                      "Revoke",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // Revoke Device Session
  // ----------------------------------------------------------
  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    String deviceId,
  ) async {
    try {
      await ref.read(deviceRepoProvider).revokeDevice(deviceId);
      ref.refresh(deviceListProvider);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Device revoked")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }
}
