import 'package:flutter/material.dart';
import 'top_navbar.dart';
import 'bottom_navbar.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final int? currentIndex; // null이면 하단 탭 숨김, -1이면 보이지만 강조 없음
  final ValueChanged<String>? onTopNavTap;
  final Widget? floatingActionButton;

  const CommonScaffold({
    super.key,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.currentIndex,
    this.onTopNavTap,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';

    const excludedRoutes = [
      '/login',
      '/signup',
      '/adminPage',
      '/adminEditChallenge',
      '/adminEditAsset',
      '/adminEditAds',
    ];

    final showBottomNav = !excludedRoutes.contains(route);

    return Scaffold(
      appBar: appBar ?? TopNavbar(onTap: onTopNavTap),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
      body: body,
      bottomNavigationBar:
          showBottomNav && currentIndex != null
              ? BottomNavbar(currentIndex: currentIndex!)
              : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
