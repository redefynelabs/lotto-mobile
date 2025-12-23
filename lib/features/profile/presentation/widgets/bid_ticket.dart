import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/bid/data/model/bid_model.dart';

class BidTicketWidget extends StatelessWidget {
  final BidModel bid;
  final GlobalKey repaintKey;
  final bool showActions;

  const BidTicketWidget({
    super.key,
    required this.bid,
    required this.repaintKey,
    this.showActions = false,
  });

  // ---------------------------------------------------------------------------
  // SLOT TIME (backend-first, safe fallback)
  // ---------------------------------------------------------------------------
  String _getSlotTimeText() {
    final slot = bid.slot;
    if (slot == null) return '—';

    if (slot.slotTimeFormatted != null && slot.slotTimeFormatted!.isNotEmpty) {
      return slot.slotTimeFormatted!;
    }

    try {
      final utc = DateTime.parse(slot.slotTime);
      final myt = utc.add(const Duration(hours: 8));
      return DateFormat("dd MMM yyyy • hh:mm a").format(myt);
    } catch (_) {
      return '—';
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE CAPTURE
  // ---------------------------------------------------------------------------
  Future<Uint8List> _captureTicket() async {
    await Future.delayed(const Duration(milliseconds: 80));

    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ---------------------------------------------------------------------------
  // SHARE
  // ---------------------------------------------------------------------------
  Future<void> _shareTicket() async {
    final bytes = await _captureTicket();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ticket_${bid.uniqueBidId ?? DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          '''
🎟️ Official Ticket

Customer: ${bid.customerName}
Ticket ID: ${bid.uniqueBidId}
Slot Time: ${_getSlotTimeText()}
Amount: RM ${bid.amount ?? '0.00'}

Good luck 🍀
''',
    );
  }

  // ---------------------------------------------------------------------------
  // PRINT
  // ---------------------------------------------------------------------------
  Future<void> _printTicket() async {
    final bytes = await _captureTicket();

    await Printing.layoutPdf(
      onLayout: (_) async {
        final pdf = pw.Document();
        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Center(child: pw.Image(image)),
          ),
        );
        return pdf.save();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isJP = bid.jpNumbers != null && bid.jpNumbers!.isNotEmpty;
    final amount =
        double.tryParse(bid.amount ?? '0')?.toStringAsFixed(2) ?? '0.00';

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22), // 🔑 FIXED
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= TICKET (CAPTURED) =================
              RepaintBoundary(
                key: repaintKey,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/icons/logo-icon.png', height: 34),
                          const Text(
                            "OFFICIAL TICKET",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 20),

                      _row("Customer", bid.customerName),
                      _row("Phone", bid.customerPhone ?? "-"),
                      _row("Ticket ID", bid.uniqueBidId ?? "-"),
                      _row("Slot Time", _getSlotTimeText()),

                      const SizedBox(height: 14),

                      if (!isJP) ...[
                        _bigBall(bid.number ?? 0),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            "Count × ${bid.count ?? 0}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ] else ...[
                        Center(child: _jpBalls(bid.jpNumbers!)),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 20),

                      _row("Total Amount", "RM $amount", bold: true),
                    ],
                  ),
                ),
              ),

              // ================= ACTIONS (NOT CAPTURED) =================
              if (showActions)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _shareTicket,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text("Share Ticket"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _printTicket,
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text("Print"),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------
  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigBall(int n) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        alignment: Alignment.center,
        child: Text(
          n.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _jpBalls(List<int> nums) {
    return Wrap(
      spacing: 6,
      alignment: WrapAlignment.center,
      children: nums
          .map(
            (n) => Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              alignment: Alignment.center,
              child: Text(
                n.toString().padLeft(2, '0'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}
