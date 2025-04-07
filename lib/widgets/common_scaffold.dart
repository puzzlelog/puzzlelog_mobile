import 'package:flutter/material.dart';
import 'top_navbar.dart';
import 'bottom_navbar.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  final int? currentIndex; // null이면 강조 없음
  final ValueChanged<String>? onTopNavTap;

  const CommonScaffold({
    super.key,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.currentIndex,
    this.onTopNavTap,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';

    // 탭 자체를 안 보일 경로
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
      bottomNavigationBar: BottomNavbar(currentIndex: currentIndex),
    );
  }
}
