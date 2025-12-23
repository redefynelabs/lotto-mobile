import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/footer.dart';
import 'package:win33/core/widgets/common/reusable_app_bar.dart';
import 'package:win33/features/bid/data/bidding_repository.dart';
import 'package:win33/features/bid/data/model/create_bid_dto.dart';
import 'package:win33/features/bid/data/model/slot_model.dart';
import 'package:win33/features/bid/data/slots_repository.dart';

class BidItem {
  final String customerName;
  final String phone;
  final String details;
  final double amount;
  final String slotId;
  final String uniqueSlotId;
  final String slotType; // "LD" or "JP"

  BidItem({
    required this.customerName,
    required this.phone,
    required this.details,
    required this.amount,
    required this.slotId,
    required this.uniqueSlotId,
    required this.slotType,
  });
}

class BidPage extends StatefulWidget {
  const BidPage({super.key});

  @override
  State<BidPage> createState() => _BidPageState();
}

class _BidPageState extends State<BidPage> {
  final slotRepository = SlotRepository.instance;
  final biddingRepository = BiddingRepository.instance;

  // 0 = Lucky Draw, 1 = Jackpot
  int selectedMode = 0;

  // Date selection (default to current date)
  DateTime? selectedDate = DateTime.now();

  // Slot selection (slot id)
  String? selectedSlotId;

  // JP: 6 input boxes
  List<int?> jpNumbers = List.filled(6, null);

  int? _extractLdNumber(String details) {
    try {
      return int.tryParse(details.split('#')[2]);
    } catch (_) {
      return null;
    }
  }

  int? _extractLdCount(String details) {
    try {
      return int.tryParse(details.split('#')[3]);
    } catch (_) {
      return null;
    }
  }

  List<int>? _extractJpList(String details) {
    try {
      return details.split('#')[2].split('-').map((e) => int.parse(e)).toList();
    } catch (_) {
      return null;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int? editingIndex; // null = adding, not editing

  // Cart items

  List<BidItem> ldCart = [];
  List<BidItem> jpCart = [];

  List<BidItem> get activeCart => selectedMode == 0 ? ldCart : jpCart;

  // Inputs
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _numberController =
      TextEditingController(); // for LD number
  final TextEditingController _countController =
      TextEditingController(); // for LD count

  // Slots fetched from backend grouped by date string 'yyyy-MM-dd'
  Map<String, List<SlotModel>> groupedSlots = {};

  // Loading / error states
  bool isLoading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _numberController.dispose();
    _countController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers: parse date keys
  // ---------------------------------------------------------------------------
  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // Determine whether a slot is open (status == 'OPEN' && windowCloseAt > now UTC)
  bool _isSlotOpen(SlotModel slot) {
    try {
      final windowClose = DateTime.parse(slot.windowCloseAt).toUtc();
      final nowUtc = DateTime.now().toUtc();
      final statusOpen = (slot.status.toUpperCase() == 'OPEN');
      return statusOpen && windowClose.isAfter(nowUtc);
    } catch (e) {
      // if parse fails, fallback to status check only
      return slot.status.toUpperCase() == 'OPEN';
    }
  }

  String? _autoSelectSlotFor(DateTime date) {
    final key = _dateKey(date);
    final slots = groupedSlots[key];
    if (slots == null || slots.isEmpty) return null;

    final gameType = selectedMode == 0 ? "LD" : "JP";

    // Filter slots by current mode
    final filtered = slots
        .where((s) => s.type.toUpperCase() == gameType)
        .toList();

    // Filter open ones
    final open = filtered.where(_isSlotOpen).toList();
    if (open.isEmpty) return null;

    // Sort by slot time
    open.sort((a, b) {
      try {
        return DateTime.parse(a.slotTime).compareTo(DateTime.parse(b.slotTime));
      } catch (_) {
        return 0;
      }
    });

    return open.first.id;
  }

  // Get the earliest open slot id for a given date, if any
  String? _earliestOpenSlotIdForDate(DateTime date) {
    final key = _dateKey(date);
    final slots = groupedSlots[key];
    if (slots == null || slots.isEmpty) return null;
    final openSlots = slots.where(_isSlotOpen).toList();
    if (openSlots.isEmpty) return null;
    openSlots.sort((a, b) {
      try {
        final at = DateTime.parse(a.slotTime);
        final bt = DateTime.parse(b.slotTime);
        return at.compareTo(bt);
      } catch (e) {
        return 0;
      }
    });
    return openSlots.first.id;
  }

  // ---------------------------------------------------------------------------
  // Fetch slots from repository
  // ---------------------------------------------------------------------------
  Future<void> _fetchSlots() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final map = await slotRepository.getSlotsGroupedByDate();

      // ensure keys are normalized (yyyy-MM-dd) — assume repository already returns this, but guard
      final normalized = <String, List<SlotModel>>{};
      map.forEach((k, v) {
        final key = k; // assuming correct format; otherwise parse if needed
        normalized[key] = List<SlotModel>.from(v);
      });

      setState(() {
        groupedSlots = normalized;
      });

      // set selectedDate default (already DateTime.now()) and auto-select earliest open slot if present
      if (selectedDate != null) {
        selectedSlotId = _autoSelectSlotFor(selectedDate!);
        setState(() {
          selectedSlotId = selectedSlotId;
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching slots: $e\n$st');
      setState(() {
        errorMsg = 'Failed to load slots';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Date Picker
  // ---------------------------------------------------------------------------
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // reasonable range
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        setState(() {
          selectedDate = picked;
          selectedSlotId = _autoSelectSlotFor(picked);
        });
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      selectedDate = DateTime.now();
      selectedSlotId = _earliestOpenSlotIdForDate(selectedDate!);
    });
  }

  // ---------------------------------------------------------------------------
  // JP Number Picker Bottom Sheet
  // ---------------------------------------------------------------------------
  void _selectNumber(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Select Number",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 37,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (_, i) {
                    final number = i + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() => jpNumbers[index] = number);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          number.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Delete & Clear Functions for Cart
  // ---------------------------------------------------------------------------
  void deleteBid(int index) {
    setState(() => activeCart.removeAt(index));
  }

  void clearAllBids() {
    setState(() => activeCart.clear());
  }

  List<int>? _parseHashNumbers(String input) {
    try {
      final parts = input.split('#');
      final nums = parts.map((e) => int.parse(e.trim())).toList();
      return nums;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Add to cart
  // ---------------------------------------------------------------------------
  void _addToCart() {
    if (selectedSlotId == null) {
      _showError("Please select a slot first.");
      return;
    }

    // Find selected slot
    final key = selectedDate != null ? _dateKey(selectedDate!) : null;
    final slotsForDay = key != null ? groupedSlots[key] ?? [] : [];
    final slot = slotsForDay.firstWhere(
      (s) => s.id == selectedSlotId,
      orElse: () => SlotModel(
        id: selectedSlotId!,
        uniqueSlotId: selectedSlotId!,
        type: selectedMode == 0 ? 'LD' : 'JP',
        status: 'OPEN',
        slotTime: DateTime.now().toUtc().toIso8601String(),
        windowCloseAt: DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        settingsJson: {},
      ),
    );

    if (!_isSlotOpen(slot)) {
      _showError("Selected slot is closed.");
      return;
    }

    // -------------------------
    // COMMON VALIDATIONS
    // -------------------------
    final customer = _customerController.text.trim();
    final phone = _phoneController.text.trim();

    if (customer.isEmpty) {
      _showError("Please enter customer name.");
      return;
    }

    if (phone.isEmpty) {
      _showError("Please enter phone number.");
      return;
    }

    if (phone.length < 8 || phone.length > 15) {
      _showError("Phone number must be valid.");
      return;
    }

    // -------------------------
    // LUCKY DRAW (LD)
    // -------------------------
    if (selectedMode == 0) {
      final numberText = _numberController.text.trim();
      final countText = _countController.text.trim();

      if (numberText.isEmpty || countText.isEmpty) {
        _showError("LD: Please enter number and count.");
        return;
      }

      final numbers = _parseHashNumbers(numberText);
      final counts = _parseHashNumbers(countText);

      if (numbers == null || counts == null) {
        _showError("LD: Invalid format. Use # separated numbers.");
        return;
      }

      if (numbers.length != counts.length) {
        _showError("LD: Number and Count count must match.");
        return;
      }

      for (int i = 0; i < numbers.length; i++) {
        final number = numbers[i];
        final count = counts[i];

        if (number < 1 || number > 37) {
          _showError("LD: Number must be between 1–37.");
          return;
        }
        if (count < 1) {
          _showError("LD: Count must be at least 1.");
          return;
        }

        final details = "${slot.uniqueSlotId}#$phone#$number#$count";

        final prize = (slot.settingsJson['bidPrize'] is num)
            ? (slot.settingsJson['bidPrize'] as num).toDouble()
            : 10.0;

        final amount = prize * count;

        activeCart.add(
          BidItem(
            customerName: customer,
            phone: phone,
            details: details,
            amount: amount,
            slotId: slot.id,
            uniqueSlotId: slot.uniqueSlotId,
            slotType: 'LD',
          ),
        );
      }

      setState(() {});

      // Reset fields (IMPORTANT: name & phone cleared only after batch)
      _customerController.clear();
      _phoneController.clear();
      _numberController.clear();
      _countController.clear();
      jpNumbers = List.filled(6, null);

      return;
    }

    // -------------------------
    // JACKPOT (JP)
    // -------------------------
    if (selectedMode == 1) {
      if (jpNumbers.any((e) => e == null)) {
        _showError("JP: Please select all 6 numbers.");
        return;
      }

      // Validate duplicates
      final unique = jpNumbers.toSet();
      if (unique.length != 6) {
        _showError("JP: Duplicate numbers not allowed.");
        return;
      }

      // Validate range
      if (jpNumbers.any((e) => e! < 1 || e! > 37)) {
        _showError("JP: Each number must be 1–37.");
        return;
      }

      final details = "${slot.uniqueSlotId}#${phone}#${jpNumbers.join('-')}";

      final amount = (slot.settingsJson['bidPrize'] is num)
          ? (slot.settingsJson['bidPrize'] as num).toDouble()
          : 10.0;

      setState(() {
        activeCart.add(
          BidItem(
            customerName: customer,
            phone: phone,
            details: details,
            amount: amount,
            slotId: slot.id,
            uniqueSlotId: slot.uniqueSlotId,
            slotType: 'JP',
          ),
        );
      });

      // Reset fields
      _customerController.clear();
      _phoneController.clear();
      _numberController.clear();
      _countController.clear();
      jpNumbers = List.filled(6, null);
    }
  }

  // ---------------------------------------------------------------------------
  // Confirm - send to backend via biddingRepository
  // ---------------------------------------------------------------------------
  Future<void> _confirmBids() async {
    if (activeCart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    if (selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a slot before confirming')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      for (final item in List<BidItem>.from(activeCart)) {
        final isJp = item.slotType == "JP";

        final dto = CreateBidDto(
          customerName: item.customerName,
          customerPhone: item.phone,
          slotId: item.slotId,
          number: isJp ? null : _extractLdNumber(item.details),
          count: isJp ? null : _extractLdCount(item.details),
          jpNumbers: isJp ? _extractJpList(item.details) : null,
        );

        await biddingRepository.createBid(dto);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bids confirmed successfully')),
      );

      setState(() => activeCart.clear());
    } catch (e, st) {
      debugPrint("Confirm bids error: $e\n$st");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to confirm bids')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Call from the edit icon button
  void _startEditing(int index) {
    final item = activeCart[index];
    editingIndex = index;

    // Fill fields
    _customerController.text = item.customerName;
    _phoneController.text = item.phone;

    if (item.slotType == 'LD') {
      selectedMode = 0;
      _numberController.text = _extractLdNumber(item.details)?.toString() ?? "";
      _countController.text = _extractLdCount(item.details)?.toString() ?? "";
      jpNumbers = List.filled(6, null);
    } else {
      selectedMode = 1;
      final nums = _extractJpList(item.details) ?? [];
      jpNumbers = List.filled(6, null);
      for (int i = 0; i < nums.length && i < 6; i++) {
        jpNumbers[i] = nums[i];
      }
      _numberController.clear();
      _countController.clear();
    }

    setState(() {});
  }

  void _updateBid() {
    if (editingIndex == null) return;

    final index = editingIndex!;
    final oldItem = activeCart[index];

    final customer = _customerController.text.trim();
    final phone = _phoneController.text.trim();

    if (customer.isEmpty) return _showError("Please enter customer name.");
    if (phone.isEmpty) return _showError("Please enter phone number.");

    // ✅ ALWAYS reuse stored slot values
    final slotId = oldItem.slotId;
    final uniqueSlotId = oldItem.uniqueSlotId;

    if (selectedMode == 0) {
      // ------------------ LD ------------------
      final number = int.tryParse(_numberController.text.trim());
      final count = int.tryParse(_countController.text.trim());

      if (number == null || number < 1 || number > 37) {
        return _showError("LD number must be 1–37.");
      }
      if (count == null || count < 1) {
        return _showError("LD count must be ≥ 1.");
      }

      // ✅ CORRECT → uniqueSlotId first
      final details = "$uniqueSlotId#$phone#$number#$count";

      final unitPrice =
          oldItem.amount / (_extractLdCount(oldItem.details) ?? 1);

      final amount = unitPrice * count;

      setState(() {
        activeCart[index] = BidItem(
          customerName: customer,
          phone: phone,
          details: details,
          amount: amount,
          slotId: slotId,
          uniqueSlotId: uniqueSlotId,
          slotType: "LD",
        );
        _resetForm();
      });
    } else {
      // ------------------ JP ------------------
      if (jpNumbers.any((e) => e == null)) {
        return _showError("Select all 6 JP numbers.");
      }

      final uniqueNums = jpNumbers.toSet();
      if (uniqueNums.length != 6) {
        return _showError("JP numbers cannot repeat.");
      }

      final nums = jpNumbers.map((e) => e!).toList();

      // ✅ CORRECT → uniqueSlotId first
      final details = "$uniqueSlotId#$phone#${nums.join('-')}";

      setState(() {
        activeCart[index] = BidItem(
          customerName: customer,
          phone: phone,
          details: details,
          amount: oldItem.amount,
          slotId: slotId,
          uniqueSlotId: uniqueSlotId,
          slotType: "JP",
        );
        _resetForm();
      });
    }
  }

  void _resetForm() {
    editingIndex = null;
    _customerController.clear();
    _phoneController.clear();
    _numberController.clear();
    _countController.clear();
    jpNumbers = List.filled(6, null);
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // UI Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: const ReusableAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildHeader(),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          if (errorMsg != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 8),
          _buildSlotSelectorSection(),
          const SizedBox(height: 16),
          Expanded(child: _buildFormAndCart()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER: Toggle + Calendar Button
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildToggle(),
          const SizedBox(width: 12),
          _buildCalendarButton(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          children: [_toggleItem("Lucky Draw", 0), _toggleItem("Jackpot", 1)],
        ),
      ),
    );
  }

  Future<bool> _showClearModeSwitchDialog() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Switch Game Mode"),
        content: const Text(
          "Switching game mode will clear current bids & details. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, int index) {
    final isSelected = selectedMode == index;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (selectedMode != index) {
            final otherCart = index == 0 ? jpCart : ldCart;

            if (otherCart.isNotEmpty) {
              final confirm = await _showClearModeSwitchDialog();
              if (!confirm) return;

              setState(() {
                otherCart.clear();
              });
            }

            _resetForm();
            setState(() {
              selectedMode = index;
              selectedSlotId = _autoSelectSlotFor(selectedDate!);
            });
          }
        },

        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontFamily: "Coolvetica",
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Text(
              selectedDate == null
                  ? "Pick Date"
                  : DateFormat("MMM dd").format(selectedDate!),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              "assets/icons/calendar.svg",
              width: 20,
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
    );
  }

  // ---------------------------------------------------------------------------
  // SLOT SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildSlotSelectorSection() {
    if (selectedDate == null) {
      return const Text(
        "Select a date to view available slots",
        style: TextStyle(color: Colors.black54),
      );
    }

    final key = _dateKey(selectedDate!);

    // FILTER SLOTS BY SELECTED MODE (LD / JP)
    final filtered = (groupedSlots[key] ?? [])
        .where((s) => s.type.toUpperCase() == (selectedMode == 0 ? "LD" : "JP"))
        .toList();

    if (filtered.isEmpty) {
      return const Text(
        "No slots available for this game type",
        style: TextStyle(color: Colors.black54),
      );
    }

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final slot = filtered[index];
          final isSelected = selectedSlotId == slot.id;
          final open = _isSlotOpen(slot);

          final displayTime = () {
            try {
              final dt = DateTime.parse(
                slot.slotTime,
              ).toUtc().add(const Duration(hours: 8));
              return DateFormat('hh:mm a').format(dt);
            } catch (_) {
              return _formatTimeFallback(slot.slotTime);
            }
          }();

          return Opacity(
            opacity: open ? 1.0 : 0.5,
            child: GestureDetector(
              onTap: open
                  ? () => setState(() => selectedSlotId = slot.id)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      displayTime,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 8),
                    if (!open)
                      const Text(
                        "Closed",
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeFallback(String iso) {
    try {
      final dt = DateTime.parse(iso).toUtc().add(const Duration(hours: 8));
      return DateFormat('hh:mm a').format(dt); // Malaysia time
    } catch (e) {
      return iso;
    }
  }

  // ---------------------------------------------------------------------------
  // FORM + CART SECTION
  // ---------------------------------------------------------------------------
  Widget _buildFormAndCart() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormCard(),
          const SizedBox(height: 12),
          _buildBidCart(),
          const SizedBox(height: 12),
          const Footer(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM CARD
  // ---------------------------------------------------------------------------
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Make a Bid",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              fontFamily: "Coolvetica",
            ),
          ),
          const SizedBox(height: 16),

          _inputFieldController(
            "Customer",
            "Select customer",
            _customerController,
          ),
          const SizedBox(height: 12),
          _inputFieldController("Phone", "Phone", _phoneController),
          const SizedBox(height: 12),

          if (selectedMode == 0) ...[
            _inputFieldController("Number", "eg: 20#31#17", _numberController),
            const SizedBox(height: 12),
            _inputFieldController("Count", "eg: 10#20#40", _countController),
          ] else ...[
            const Text(
              "Select 6 Numbers",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _jpNumberBoxes(),
          ],

          const SizedBox(height: 20),
          _addToCartButton(),
        ],
      ),
    );
  }

  Widget _inputFieldController(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // JP SIX NUMBER INPUT BOXES
  // ---------------------------------------------------------------------------
  Widget _jpNumberBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final value = jpNumbers[index];

        return GestureDetector(
          onTap: () => _selectNumber(index),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value?.toString() ?? "--",
                  style: TextStyle(
                    color: value == null ? Colors.grey : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD TO CART BUTTON
  // ---------------------------------------------------------------------------
  Widget _addToCartButton() {
    final isEditing = editingIndex != null;

    return GestureDetector(
      onTap: isEditing ? _updateBid : _addToCart,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          isEditing ? "Update Bid" : "Add to bucket",
          style: const TextStyle(color: Colors.white, fontFamily: "Coolvetica"),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CART SECTION
  // ---------------------------------------------------------------------------
  Widget _buildBidCart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bid Cart",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: "Coolvetica",
            ),
          ),
          const SizedBox(height: 16),

          if (activeCart.isEmpty) _emptyCart(),
          if (activeCart.isNotEmpty) _cartList(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY CART UI
  // ---------------------------------------------------------------------------
  Widget _emptyCart() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/bag-timer.svg',
            width: 70,
            height: 70,
            colorFilter: const ColorFilter.mode(
              Color.fromARGB(255, 118, 118, 118),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your bid cart is empty",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // POPULATED CART
  // ---------------------------------------------------------------------------
  Widget _cartList() {
    final total = activeCart.fold<double>(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeCart.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) => _cartItem(activeCart[index], index),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "RM ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _clearAllButton()),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : _confirmBids,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey : AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Confirm Bid",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarForItem(BidItem item) {
    if (item.slotType == "LD") {
      final num = _extractLdNumber(item.details) ?? 0;

      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary,
        child: Text(
          num.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // JP case → show 6 balls in a row
    final nums = _extractJpList(item.details) ?? [];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final value = nums.length > i ? nums[i] : null;

        return Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            value?.toString() ?? "-",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  Widget _jpBallsRow(List<int> numbers) {
    return Row(
      children: List.generate(numbers.length, (i) {
        return Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            numbers[i].toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE CART ITEM
  // ---------------------------------------------------------------------------
  Widget _cartItem(BidItem item, int index) {
    final isJP = item.slotType == "JP";
    final jpList = isJP
        ? List<int>.from(_extractJpList(item.details) ?? [])
        : <int>[];

    if (isJP) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 TOP ROW → JP BALLS
            _jpBallsRow(jpList),

            const SizedBox(height: 10),

            // 🧑 CUSTOMER + EDIT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () => _startEditing(index),
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                ),
              ],
            ),

            // 📞 PHONE + DELETE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.phone,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                IconButton(
                  onPressed: () => deleteBid(index),
                  icon: const Icon(Icons.delete, color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 📝 DETAILS LINE
            Text(
              item.details,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            const SizedBox(height: 6),

            // 💰 AMOUNT
            Text(
              "RM ${item.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // ---------------------------------------
    // LD stays EXACTLY as your existing layout
    // ---------------------------------------
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatarForItem(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.phone,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(item.details, style: const TextStyle(fontSize: 14)),
                Text(
                  "RM ${item.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => _startEditing(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.primary),
                onPressed: () => deleteBid(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLEAR ALL
  // ---------------------------------------------------------------------------
  Widget _clearAllButton() {
    return GestureDetector(
      onTap: clearAllBids,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Text(
          "Clear all",
          style: TextStyle(color: AppColors.primary),
        ),
      ),
    );
  }
}
