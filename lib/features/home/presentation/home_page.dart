import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/footer.dart';
import 'package:win33/core/widgets/common/reusable_app_bar.dart';

import 'package:win33/features/bid/data/slots_repository.dart';
import 'package:win33/features/bid/data/model/slot_model.dart';
import 'package:win33/features/home/presentation/widgets/jackpot_instruction_section.dart';
import 'package:win33/features/home/presentation/widgets/luckydraw_instruction_section.dart';
import 'package:win33/features/results/data/models/result_model.dart';
import 'package:win33/features/results/data/result_repository.dart';

/// --------------------------------------------------------------
/// MERGED SLOT MODEL
/// --------------------------------------------------------------
class MergedSlot {
  final SlotModel slot;
  final ResultModel? result;

  bool get hasResult => result != null && result!.winningNumber != null;
  bool get isLD => slot.type == "LD";
  bool get isJP => slot.type == "JP";

  int? get winningNumber => result?.winningNumber;
  List<int>? get winningCombo => result?.winningCombo;

  MergedSlot({required this.slot, this.result});
}

/// --------------------------------------------------------------
/// HOME PAGE
/// --------------------------------------------------------------
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final slotRepo = SlotRepository.instance;
  final resultsRepo = ResultsRepository();

  static const String _videoBaseUrl = "https://server.lotto.redefyne.in/videos";

  List<MergedSlot> mergedLD = [];
  List<MergedSlot> mergedJP = [];

  int selectedMode = 0;
  String? selectedSlotId;

  VideoPlayerController? currentCtrl;
  bool isMuted = false;
  bool ldNumberRevealed = false;

  bool loading = true;

  // JP state
  int jpIndex = 0;
  List<int> revealedJP = [];
  Timer? jpRestartTimer;

  // LD loop timer
  Timer? ldLoopTimer;

  @override
  void dispose() async {
    await _safeDisposeController();
    jpRestartTimer?.cancel();
    ldLoopTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _formatSlotDate(dynamic slotTime) {
    try {
      if (slotTime is DateTime) {
        return DateFormat('dd MMM yyyy').format(slotTime);
      }
      if (slotTime is String) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(slotTime));
      }
    } catch (_) {}
    return "--";
  }

  String _formatSlotTime(dynamic time) {
    try {
      final DateTime dt = time is DateTime ? time : DateTime.parse(time);

      // Convert to UTC first, then add Malaysia offset (+8)
      final DateTime myt = dt.isUtc
          ? dt.add(const Duration(hours: 8))
          : dt.toUtc().add(const Duration(hours: 8));

      return DateFormat('hh:mm a').format(myt);
    } catch (_) {
      return "--";
    }
  }

  Future<void> _safeDisposeController() async {
    if (currentCtrl != null) {
      final oldCtrl = currentCtrl!;
      currentCtrl = null; // <-- VERY IMPORTANT
      if (mounted)
        setState(() {}); // rebuild UI so no widget tries to use old ctrl
      await oldCtrl.dispose(); // safe dispose
    }
  }

  /// --------------------------------------------------------------
  /// FETCH + MERGE DATA
  /// --------------------------------------------------------------
  Future<void> _loadAll() async {
    loading = true;
    setState(() {});

    try {
      final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
      final slotsResponse = await slotRepo.getSlotsByDate(today);

      mergedLD = _merge(
        slotsResponse["LD"] ?? [],
        await resultsRepo.fetchResultsByDate(today, "LD"),
      );
      mergedJP = _merge(
        slotsResponse["JP"] ?? [],
        await resultsRepo.fetchResultsByDate(today, "JP"),
      );

      final list = selectedMode == 0 ? mergedLD : mergedJP;

      if (selectedSlotId == null && list.isNotEmpty) {
        selectedSlotId = list.first.slot.id;
      }

      if (selectedMode == 0) {
        _startLD();
      } else {
        _startJP();
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    }

    loading = false;
    setState(() {});
  }

  List<MergedSlot> _merge(List<SlotModel> slots, List<ResultModel> results) {
    slots.sort((a, b) => a.slotTime.compareTo(b.slotTime));
    return slots.map((slot) {
      final result = results.firstWhere(
        (r) => r.slotId == slot.id,
        orElse: () => ResultModel.empty(),
      );
      return MergedSlot(slot: slot, result: result);
    }).toList();
  }

  /// --------------------------------------------------------------
  /// VIDEO LOAD HELPER
  /// --------------------------------------------------------------
  Future<VideoPlayerController> _loadVideo(String url) async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await ctrl.initialize();
    ctrl.setVolume(isMuted ? 0 : 1);
    ctrl.setLooping(false);
    await ctrl.play();

    return ctrl;
  }

  /// --------------------------------------------------------------
  /// LUCKY DRAW HANDLER (A — loop forever & keep number visible)
  /// --------------------------------------------------------------
  void _startLD() async {
    ldLoopTimer?.cancel();
    await _safeDisposeController();

    ldNumberRevealed = false;
    setState(() {}); // remove video from UI before loading new one

    final slot = mergedLD.firstWhere(
      (m) => m.slot.id == selectedSlotId,
      orElse: () => mergedLD.first,
    );

    if (!slot.hasResult) {
      currentCtrl = await _loadVideo("$_videoBaseUrl/balls-spin.mp4");
      currentCtrl!.setLooping(true);
      setState(() {});
      return;
    }

    final win = slot.winningNumber!;
    final url = "$_videoBaseUrl/$win.mp4";

    currentCtrl = await _loadVideo(url);
    setState(() {});

    final duration = currentCtrl!.value.duration;
    final revealTime = duration - const Duration(seconds: 10);

    if (revealTime > Duration.zero) {
      Timer(revealTime, () {
        if (mounted) setState(() => ldNumberRevealed = true);
      });
    }

    late VoidCallback ldListener;
    ldListener = () {
      if (!mounted) return;
      if (currentCtrl!.value.position >= duration) {
        currentCtrl!.removeListener(ldListener);
        ldLoopTimer = Timer(const Duration(seconds: 2), _startLD);
      }
    };

    currentCtrl!.addListener(ldListener);
  }

  /// --------------------------------------------------------------
  /// JACKPOT SEQUENCE HANDLER
  /// --------------------------------------------------------------
  void _startJP() async {
    jpRestartTimer?.cancel();
    await _safeDisposeController();

    revealedJP.clear();
    jpIndex = 0;

    final slot = mergedJP.firstWhere(
      (m) => m.slot.id == selectedSlotId,
      orElse: () => mergedJP.first,
    );

    if (slot.winningCombo == null) {
      setState(() {});
      return;
    }

    final nums = slot.winningCombo!;

    Future<void> playNext() async {
      if (jpIndex >= nums.length) {
        // pause 5 sec → restart
        jpRestartTimer = Timer(const Duration(seconds: 2), () {
          jpIndex = 0;
          revealedJP.clear();
          playNext();
        });
        return;
      }

      await _safeDisposeController();
      final n = nums[jpIndex];
      currentCtrl = await _loadVideo("$_videoBaseUrl/$n.mp4");
      setState(() {});

      final duration = currentCtrl!.value.duration;
      final revealTime = duration - const Duration(seconds: 10);

      Timer(revealTime, () {
        revealedJP.add(n);
        if (mounted) setState(() {});
      });

      currentCtrl!.addListener(() {
        if (!mounted) return;
        if (currentCtrl!.value.position >= duration) {
          jpIndex++;
          playNext();
        }
      });
    }

    playNext();
  }

  /// --------------------------------------------------------------
  /// SHIMMER PLACEHOLDER
  /// --------------------------------------------------------------
  Widget _shimmerBox({double height = 180}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------
  /// GRAY CIRCLE PLACEHOLDER
  /// --------------------------------------------------------------
  Widget _grayCircle({double radius = 22}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade100,
      child: Text(
        "?",
        style: TextStyle(
          color: AppColors.primary,
          fontSize: radius, // scales nicely
          fontWeight: FontWeight.bold,
          fontFamily: "Coolvetica",
        ),
      ),
    );
  }

  /// --------------------------------------------------------------
  /// VIDEO BORDER WRAPPER + MUTE BUTTON
  /// --------------------------------------------------------------
  Widget _videoFrame(VideoPlayerController ctrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
            child: VideoPlayer(ctrl),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
          ),
        ),

        /// MUTE BUTTON
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isMuted = !isMuted;
                currentCtrl?.setVolume(isMuted ? 0 : 1);
              });
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black54,
              child: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// --------------------------------------------------------------
  /// RESULT BOX
  /// --------------------------------------------------------------
  Widget _resultCard(MergedSlot slot) {
    final bool hasLDResult = slot.isLD && slot.hasResult;
    final bool hasJPResult = slot.isJP && slot.winningCombo != null;

    return Container(
      width: double.infinity, // 🔥 always full width
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: AssetImage("assets/images/results_box_bg.png"),
          fit: BoxFit.cover,
          opacity: 1, // keep your subtle effect
        ),
        border: Border.all(color: AppColors.primary, width: 1),
        boxShadow: [
          BoxShadow(spreadRadius: 1, blurRadius: 8, color: Colors.black12),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slot.isLD ? "Lucky Draw" : "Jackpot",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: "Coolvetica",
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// SLOT INFO
          Text(
            "Slot: ${slot.slot.uniqueSlotId}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: "Coolvetica",
            ),
          ),
          Text(
            "Time: ${_formatSlotTime(slot.slot.slotTime)}",
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            "Date: ${_formatSlotDate(slot.slot.slotTime)}",
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 18),

          //---------------------------------------------------------------
          // 🔥 CASE 1: LD — NO RESULT
          //---------------------------------------------------------------
          if (slot.isLD && !hasLDResult)
            Column(
              children: [
                currentCtrl != null && currentCtrl!.value.isInitialized
                    ? _videoFrame(currentCtrl!)
                    : _shimmerBox(),
                const SizedBox(height: 12),
                const Text(
                  "Awaiting Lucky Draw Result...",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),

          //---------------------------------------------------------------
          // 🔥 CASE 2: LD — HAS RESULT (Video + number reveal)
          //---------------------------------------------------------------
          if (hasLDResult)
            Column(
              children: [
                currentCtrl != null && currentCtrl!.value.isInitialized
                    ? _videoFrame(currentCtrl!)
                    : _shimmerBox(),

                const SizedBox(height: 18),

                if (!ldNumberRevealed)
                  _grayCircle(radius: 26)
                else
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      slot.winningNumber.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
              ],
            ),

          //---------------------------------------------------------------
          // 🔥 CASE 3: JP — NO RESULT
          //---------------------------------------------------------------
          if (slot.isJP && !hasJPResult)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Awaiting Jackpot Result...",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),

          //---------------------------------------------------------------
          // 🔥 CASE 4: JP — HAS RESULT (sequence + reveal)
          //---------------------------------------------------------------
          if (slot.isJP && hasJPResult)
            Column(
              children: [
                currentCtrl != null && currentCtrl!.value.isInitialized
                    ? _videoFrame(currentCtrl!)
                    : _shimmerBox(),

                const SizedBox(height: 18),

                Wrap(
                  spacing: 10,
                  children: List.generate(6, (i) {
                    if (i < revealedJP.length) {
                      return CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          "${revealedJP[i]}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return _grayCircle(radius: 22);
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------
  /// UI BUILDERS
  /// --------------------------------------------------------------
  Widget _display() {
    final list = selectedMode == 0 ? mergedLD : mergedJP;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No slots available",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    final slot = list.firstWhere(
      (m) => m.slot.id == selectedSlotId,
      orElse: () => list.first,
    );

    return _resultCard(slot);
  }

  Widget _toggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: [_toggleItem("Lucky Draw", 0), _toggleItem("Jackpot", 1)],
      ),
    );
  }

  Widget _toggleItem(String text, int index) {
    final isSel = index == selectedMode;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await _safeDisposeController(); // FIX 4
          setState(() => selectedMode = index);

          final list = index == 0 ? mergedLD : mergedJP;
          if (list.isNotEmpty) selectedSlotId = list.first.slot.id;

          if (index == 0) {
            _startLD();
          } else {
            _startJP();
          }
        },

        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSel ? Colors.white : AppColors.primary,
              fontFamily: "Coolvetica",
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _refreshToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _toggle()),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadAll,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _slotSelector() {
    final list = selectedMode == 0 ? mergedLD : mergedJP;
    return SizedBox(
      height: 45,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final m = list[i];
          final isSel = m.slot.id == selectedSlotId;

          return GestureDetector(
            onTap: () async {
              await _safeDisposeController(); // FIX 3
              setState(() => selectedSlotId = m.slot.id);

              if (m.isLD) {
                _startLD();
              } else {
                _startJP();
              }
            },

            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: isSel ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: isSel ? AppColors.primary : Colors.grey.shade400,
                ),
              ),
              child: Text(
                _formatSlotTime(m.slot.slotTime),
                style: TextStyle(
                  color: isSel ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// --------------------------------------------------------------
  /// PAGE BUILD
  /// --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: const ReusableAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  _refreshToggle(),
                  const SizedBox(height: 14),
                  _slotSelector(),
                  const SizedBox(height: 16),

                  /// RESULT BLOCK (not expanded inside scroll view)
                  _display(),

                  const SizedBox(height: 24),

                  Text(
                    'Instructions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: "Coolvetica",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// 🔥 CONDITIONAL INSTRUCTIONS
                  if (selectedMode == 0) ...[
                    const LuckyDrawInstructionSection(),
                  ] else ...[
                    const JackpotInstructionSection(),
                  ],

                  const SizedBox(height: 40),

                  const Footer(opacity: 0.35),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
