import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/core/widgets/common/reusable_app_bar.dart';

class BidPage extends ConsumerWidget {
  const BidPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: ReusableAppBar(),
      body: const Center(child: Text("Bid")),
    );
  }
}
