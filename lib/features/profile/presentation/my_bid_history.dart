import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/bid/data/bidding_repository.dart';
import 'package:win33/features/bid/data/model/bid_model.dart';

class MyBidHistoryPage extends StatefulWidget {
  const MyBidHistoryPage({super.key});

  @override
  State<MyBidHistoryPage> createState() => _MyBidHistoryPageState();
}

enum HistoryViewMode { tiles /* reserved for future list/cards */ }

class _MyBidHistoryPageState extends State<MyBidHistoryPage> {
  final repo = BiddingRepository.instance;

  List<BidModel> _allBids = [];
  bool _loading = false;
  String? _error;

  // Filters
  String _gameTypeFilter = 'LD'; // 'LD' or 'JP' — only these two as requested
  DateTime? _dateFilter; // null => show all dates

  // pagination
  int _visible = 20;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _error = null;
        _loading = true;
        _visible = _pageSize;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await repo.getMyBids();
      // ensure createdAt is DateTime in BidModel; otherwise parse if needed
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _allBids = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // load more locally
  void _loadMore() {
    setState(() {
      _visible = (_visible + _pageSize).clamp(0, _allBids.length);
    });
  }

  bool get _hasMore => _visible < _filteredBids.length;

  List<BidModel> get _filteredBids {
    var list = _allBids.where((b) {
      // filter by game type
      final isJp = (b.jpNumbers?.isNotEmpty ?? false);
      final type = isJp ? 'JP' : 'LD';
      if (type != _gameTypeFilter) return false;

      // filter by date if provided
      if (_dateFilter != null) {
        final d = DateTime(
          b.createdAt.year,
          b.createdAt.month,
          b.createdAt.day,
        );
        final f = DateTime(
          _dateFilter!.year,
          _dateFilter!.month,
          _dateFilter!.day,
        );
        return d == f;
      }
      return true;
    }).toList();

    // already sorted by createdAt desc
    return list;
  }

  // ---------- UI helpers ----------
  Widget _jpBall(int n) {
    final txt = n.toString().padLeft(2, '0');
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        txt,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _ldBall(int n) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        n.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _slotStatusBadge(String? status) {
    final s = (status ?? '').toUpperCase();
    Color bg = Colors.grey.shade300;
    Color fg = Colors.black87;

    if (s == 'OPEN') {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green.shade700;
    } else if (s == 'CLOSED') {
      bg = Colors.orange.withOpacity(0.12);
      fg = Colors.orange.shade800;
    } else if (s == 'COMPLETED') {
      bg = Colors.blue.withOpacity(0.12);
      fg = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.isEmpty ? 'N/A' : s,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  DateTime toMalaysia(DateTime utc) {
    return utc.add(const Duration(hours: 8));
  }

  Widget _tileLDItem(BidModel b) {
    final number = b.number ?? 0;
    final count = b.count ?? 1;

    final resultRaw = b.slot?.drawResult?['winner'];
    final resultNumber = (resultRaw is String) ? resultRaw : "-";
    final isWinner = number.toString() == resultNumber;
    final local = b.createdAt.toLocal();

    return Card(
      color: const Color(0xFFFFF3F3),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: const Color.fromARGB(255, 255, 235, 235),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TOP ROW ----------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT — LD big ball (always visible)
                _ldBall(number),

                const SizedBox(width: 12),

                // MIDDLE — user info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.customerPhone ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.uniqueBidId ?? "",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // RIGHT — status + result
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _slotStatusBadge(b.slot?.status),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? Colors.green.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isWinner ? "WINNER" : "Result: $resultNumber",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isWinner ? Colors.green.shade700 : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- BOTTOM ROW ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // PRICE
                    Text(
                      "RM ${double.parse(b.amount.toString()).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // DATE + TIME (Malaysia local)
                    Text(
                      DateFormat("MMM dd • HH:mm").format(local),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // SLOT TIME (also convert to local)
                    if (b.slot?.slotTime != null)
                      Text(
                        "Slot: ${DateFormat("HH:mm").format(toMalaysia(DateTime.parse(b.slot!.slotTime!)))}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileJPItem(BidModel b) {
    final jp = b.jpNumbers ?? [];

    // Convert UTC → Malaysia time manually (UTC+8)
    DateTime? slotTime;
    if (b.slot?.slotTime != null) {
      final utc = DateTime.parse(b.slot!.slotTime!);
      slotTime = utc.add(const Duration(hours: 8));
    }

    // Handle result / winner
    final resultRaw = b.slot?.drawResult?['winner'];
    final resultList = (resultRaw is String && resultRaw.contains('-'))
        ? resultRaw.split('-')
        : [];

    final isWinner = jp.join('-') == resultList.join('-');

    return Card(
      color: const Color(0xFFFFF3F3),
      elevation: 0,

      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: const Color.fromARGB(255, 255, 235, 235),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TOP ROW (Balls + Status) ----------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // JP Balls
                Expanded(
                  flex: 6,
                  child: Wrap(
                    spacing: 8,
                    children: jp.map((n) => _jpBall(n)).toList(),
                  ),
                ),

                // Status and Result
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _slotStatusBadge(b.slot?.status),
                        const SizedBox(height: 6),

                        if (resultList.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isWinner
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isWinner
                                  ? "WINNER"
                                  : "Result: ${resultList.join(', ')}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWinner
                                    ? Colors.green.shade700
                                    : Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- USER DETAILS ----------------
            Text(
              b.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              b.customerPhone ?? "",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),

            // Slot time — Malaysia Time
            if (slotTime != null) ...[
              const SizedBox(height: 4),
              Text(
                "Slot: ${DateFormat('h:mm a').format(slotTime!)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 6),

            Text(b.uniqueBidId ?? "", style: const TextStyle(fontSize: 13)),

            const SizedBox(height: 12),

            // ---------------- BOTTOM ROW ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "RM ${double.parse(b.amount.toString()).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("MMM dd").format(b.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileItem(BidModel b) {
    final isJp = (b.jpNumbers?.isNotEmpty ?? false);
    return isJp ? _tileJPItem(b) : _tileLDItem(b);
  }

  // Date picker
  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
    }
  }

  void _clearDateFilter() {
    setState(() => _dateFilter = null);
  }

  // ---------------- Export CSV & PDF ----------------

  Future<File> _writeTempFile(String fileName, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _buildCsvString(List<BidModel> list) {
    // Header
    final rows = <List<String>>[
      [
        'Date',
        'GameType',
        'Customer',
        'Phone',
        'Numbers',
        'Count',
        'Amount',
        'SlotId',
        'Status',
      ],
    ];

    for (final b in list) {
      final isJp = (b.jpNumbers?.isNotEmpty ?? false);
      final numbers = isJp
          ? (b.jpNumbers!.join('-'))
          : (b.number?.toString() ?? '');
      final count = b.count?.toString() ?? '';
      final type = isJp ? 'JP' : 'LD';
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm:ss').format(b.createdAt),
        type,
        b.customerName,
        b.customerPhone ?? '',
        numbers,
        count,
        b.amount?.toString() ?? '',
        b.slotId ?? '',
        b.slot?.status ?? '',
      ]);
    }

    final buffer = StringBuffer();
    for (final r in rows) {
      // CSV-safe escaping double quotes
      final line = r
          .map((c) {
            final safe = c.replaceAll('"', '""');
            return '"$safe"';
          })
          .join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    try {
      final list =
          _filteredBids; // export filtered visible list (all filtered, not only visible)
      final csv = _buildCsvString(list);
      final bytes = csv.codeUnits;
      final file = await _writeTempFile(
        'my_bids_${DateTime.now().millisecondsSinceEpoch}.csv',
        bytes,
      );
      await Share.shareXFiles([XFile(file.path)], text: 'My Bids CSV export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();
      final list = _filteredBids;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('My Bids', style: pw.TextStyle(fontSize: 20)),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Filters: ${_gameTypeFilter} ${_dateFilter != null ? DateFormat('yyyy-MM-dd').format(_dateFilter!) : ''}',
              ),
              pw.SizedBox(height: 12),
              ...list.map((b) {
                final isJp = (b.jpNumbers?.isNotEmpty ?? false);
                final nums = (b.jpNumbers ?? [])
                    .map((n) => n.toString().padLeft(2, '0'))
                    .join(', ');
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              b.customerName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            'RM ${double.tryParse(b.amount?.toString() ?? '0')?.toStringAsFixed(2) ?? "0.00"}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.red600,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(b.customerPhone ?? ''),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        isJp ? 'JP Numbers: $nums' : 'LD: ${b.number ?? "-"}',
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Placed: ${DateFormat('yyyy-MM-dd HH:mm').format(b.createdAt)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final file = await _writeTempFile(
        'my_bids_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes,
      );
      await Share.shareXFiles([XFile(file.path)], text: 'My Bids PDF export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }

  // Popup menu handler
  void _onExportSelected(String value) {
    if (value == 'csv') {
      _exportCsv();
    } else if (value == 'pdf') {
      _exportPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleList = _filteredBids.take(_visible).toList();

    return Scaffold(
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
          "My Bid History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",

            fontSize: 22,
          ),
        ),
        actions: [
          // Export icon with menu
          PopupMenuButton<String>(
            onSelected: _onExportSelected,
            elevation: 0,
            icon: SvgPicture.asset(
              'assets/icons/export.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),

            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/refresh.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => _loadBids(refresh: true),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _loadBids(refresh: true),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 40),
                  Center(child: Text('Failed to load: $_error')),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _loadBids(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // FILTER ROW (Option A)
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // LD button
                        _filterPill('Lucky Draw', _gameTypeFilter == 'LD', () {
                          setState(() {
                            _gameTypeFilter = 'LD';
                            _visible = _pageSize;
                          });
                        }),

                        const SizedBox(width: 8),

                        // JP button
                        _filterPill('Jackpot', _gameTypeFilter == 'JP', () {
                          setState(() {
                            _gameTypeFilter = 'JP';
                            _visible = _pageSize;
                          });
                        }),

                        const Spacer(),

                        // Date display + picker
                        GestureDetector(
                          onTap: _pickDateFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dateFilter == null
                                      ? 'Date'
                                      : DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(_dateFilter!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_dateFilter != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: GestureDetector(
                                      onTap: _clearDateFilter,
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: visibleList.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'No bids found',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            itemCount: visibleList.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == visibleList.length && _hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: _loadMore,
                                      child: const Text('Load more'),
                                    ),
                                  ),
                                );
                              }
                              final b = visibleList[i];
                              return _tileItem(b);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _filterPill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontFamily: "Coolvetica",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
