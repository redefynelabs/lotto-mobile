import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/reusable_app_bar.dart';
import 'package:win33/features/results/data/models/result_model.dart';
import 'package:win33/features/results/data/result_repository.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final ResultsRepository repo = ResultsRepository();

  String selectedType = 'LD';
  bool loading = true;
  DateTime? selectedDate;

  List<ResultModel> results = [];
  List<ResultModel> todayLDList = []; // sorted oldest -> newest
  List<ResultModel> todayJPList = []; // sorted oldest -> newest
  int displayedCount = 10;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => loading = true);
    await Future.wait([_loadLatest(), _loadTodaySlots()]);
    setState(() => loading = false);
  }

  Future<void> _loadLatest() async {
    try {
      final res = await repo.fetchResults(selectedType, limit: 200);
      res.sort((a, b) => b.slotTime.compareTo(a.slotTime)); // newest first
      setState(() => results = res);
    } catch (_) {
      setState(() => results = []);
    }
  }

  Future<void> _loadTodaySlots() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final ld = await repo.fetchResultsByDate(today, 'LD');
      final jp = await repo.fetchResultsByDate(today, 'JP');

      ld.sort((a, b) => a.slotTime.compareTo(b.slotTime)); // oldest -> newest
      jp.sort((a, b) => a.slotTime.compareTo(b.slotTime));

      setState(() {
        todayLDList = ld;
        todayJPList = jp;
      });
    } catch (_) {
      setState(() {
        todayLDList = [];
        todayJPList = [];
      });
    }
  }

  Future<void> _loadForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      selectedDate = date;
      displayedCount = 10;
      loading = true;
    });

    try {
      final res = await repo.fetchResultsByDate(dateStr, selectedType);
      res.sort((a, b) => b.slotTime.compareTo(a.slotTime));
      setState(() => results = res);
    } catch (_) {
      setState(() => results = []);
    }

    setState(() => loading = false);
  }

  void _clearDateFilter() async {
    setState(() {
      selectedDate = null;
      displayedCount = 10;
      loading = true;
    });

    await _loadLatest();
    await _loadTodaySlots();

    setState(() => loading = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) await _loadForDate(picked);
  }

  String _displayDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return raw;
    }
  }

  // --------------------------- TODAY CARD — LUCKY DRAW ---------------------------
  Widget _todayCardLD(BuildContext ctx) {
    if (todayLDList.isEmpty) return const SizedBox.shrink();

    final latest = todayLDList.last; // newest
    final earlier = todayLDList.length > 1
        ? todayLDList.take(todayLDList.length - 1).toList().reversed.toList()
        : [];

    return Container(
      width: double.infinity, // ⭐ FULL WIDTH
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.thunderbird50),

        // ⭐ BACKGROUND IMAGE MOVED HERE (correct place)
        image: const DecorationImage(
          image: AssetImage("assets/images/results_box_bg.png"),
          fit: BoxFit.cover,
          opacity: 1, // keep your subtle effect
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 12;
          final int cols = 3;
          final double itemWidth =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(height: 6),

              const Text(
                "Today's Lucky Draw",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),

              // BIG FEATURED LD NUMBER
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                child: Text(
                  latest.winningNumber?.toString() ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                latest.timeStr,
                style: const TextStyle(
                  color: AppColors.thunderbird900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              Text(_displayDate(latest.dateStr)),
              const SizedBox(height: 4),

              Text(
                "Slot ID: ${latest.uniqueSlotId}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (earlier.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Earlier Today",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // ⭐ FULL-WIDTH EARLIER TODAY GRID
                Wrap(
                  spacing: spacing,
                  runSpacing: 12,
                  children: earlier.map((r) {
                    return SizedBox(
                      width: itemWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.thunderbird50),
                        ),
                        child: Column(
                          children: [
                            Text(
                              r.uniqueSlotId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.thunderbird900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CircleAvatar(
                              radius: 20, // adjust size as needed
                              backgroundColor: AppColors.primary,
                              child: Text(
                                r.winningNumber?.toString() ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Text(
                              r.timeStr,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // --------------------------- TODAY CARD — JACKPOT (ONLY 1 SLOT) ---------------------------
  Widget _todayCardJP(BuildContext ctx) {
    if (todayJPList.isEmpty) return const SizedBox.shrink();

    final latest = todayJPList.last;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          // ⭐ BORDER VISIBLE
          border: Border.all(color: AppColors.thunderbird50),

          // ⭐ BACKGROUND IMAGE MOVED HERE (correct place)
          image: const DecorationImage(
            image: AssetImage("assets/images/results_box_bg.png"),
            fit: BoxFit.cover,
            opacity: 1, // keep your subtle effect
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),

            const Text(
              "Today's Jackpot",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: (latest.winningCombo ?? []).map((n) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    n.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Text(
              latest.timeStr,
              style: const TextStyle(
                color: AppColors.thunderbird900,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              _displayDate(latest.dateStr),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),

            Text(
              "Slot ID: ${latest.uniqueSlotId}",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------- LIST ITEM (Below today card) ---------------------------
  Widget _listItem(ResultModel r) {
    final combo = r.winningCombo ?? [];
    final isJP = r.type == 'JP';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            r.timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          isJP
              ? Wrap(
                  spacing: 10,
                  children: combo
                      .map(
                        (n) => CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Text(
                            n.toString(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    r.winningNumber?.toString() ?? "?",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            '${_displayDate(r.dateStr)} • Slot ${r.uniqueSlotId}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --------------------------- HEADER ---------------------------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary, width: 2),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  _toggle('Lucky Draw', 'LD'),
                  _toggle('Jackpot', 'JP'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Text(
                    selectedDate == null
                        ? "Today"
                        : DateFormat("MMM dd").format(selectedDate!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    "assets/icons/calendar.svg",
                    width: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (selectedDate != null)
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, String type) {
    final active = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (active) return;

          setState(() {
            selectedType = type;
            loading = true;
          });

          if (selectedDate != null) {
            await _loadForDate(selectedDate!);
          } else {
            await _loadLatest();
            await _loadTodaySlots();
          }

          setState(() => loading = false);
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------- RESULTS LIST ---------------------------
  Widget _resultsList() {
    List<ResultModel> listSource = results;

    // remove today's results from list when today card is shown
    if (selectedDate == null &&
        selectedType == 'LD' &&
        todayLDList.isNotEmpty) {
      listSource = listSource
          .where((r) => !todayLDList.any((t) => t.slotId == r.slotId))
          .toList();
    }

    if (selectedDate == null &&
        selectedType == 'JP' &&
        todayJPList.isNotEmpty) {
      listSource = listSource
          .where((r) => !todayJPList.any((t) => t.slotId == r.slotId))
          .toList();
    }

    final showList = listSource.take(displayedCount).toList();
    final hasMore = listSource.length > displayedCount;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount:
          showList.length +
          ((selectedDate == null &&
                  ((selectedType == 'LD' && todayLDList.isNotEmpty) ||
                      (selectedType == 'JP' && todayJPList.isNotEmpty)))
              ? 1
              : 0) +
          (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Insert today's card
        if (index == 0 && selectedDate == null) {
          if (selectedType == 'LD' && todayLDList.isNotEmpty) {
            return Column(
              children: [
                _todayCardLD(context),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Earlier Results',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          if (selectedType == 'JP' && todayJPList.isNotEmpty) {
            return Column(
              children: [
                _todayCardJP(context),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Earlier Results',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }
        }

        // adjust index due to the today card tile
        int offset = 0;
        if (selectedDate == null &&
            ((selectedType == 'LD' && todayLDList.isNotEmpty) ||
                (selectedType == 'JP' && todayJPList.isNotEmpty))) {
          offset = 1;
        }

        final actualIndex = index - offset;

        // Load more button
        if (actualIndex >= showList.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextButton.icon(
              onPressed: () => setState(() => displayedCount += 10),
              icon: const Icon(Icons.expand_more, color: AppColors.primary),
              label: const Text(
                "Show More",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );
        }

        return _listItem(showList[actualIndex]);
      },
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.thunderbird200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  // --------------------------- BUILD ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 14),
            Expanded(
              child: loading
                  ? _loadingList()
                  : results.isEmpty
                  ? const Center(child: Text('No results found'))
                  : _resultsList(),
            ),
          ],
        ),
      ),
    );
  }
}
