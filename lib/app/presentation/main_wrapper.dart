import 'package:flutter/material.dart';
import 'package:win33/core/widgets/common/bottom_app_bar.dart';
import 'package:win33/features/auth/presentation/unauthorized_page.dart';
import 'package:win33/features/home/presentation/home_page.dart';
import 'package:win33/features/bid/presentation/bid_page.dart';
import 'package:win33/features/results/presentation/resuts_page.dart';

class MainWrapper extends StatefulWidget {
  final bool isLoggedIn;

  const MainWrapper({super.key, required this.isLoggedIn});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _index = 0;

  

  final pages = const [HomePage(), BidPage(), ResultsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (_) {
          // if guest clicks BID tab → send to login
          if (!widget.isLoggedIn && _index == 1) {
            return const UnauthorizedPage();
          }

          return pages[_index];
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
