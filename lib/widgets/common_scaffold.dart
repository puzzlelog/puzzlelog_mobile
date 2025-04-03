import 'package:flutter/material.dart';
import './top_navbar.dart';
import './bottom_navbar.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  // ✅ 선택형으로 변경
  final int? currentIndex;
  final ValueChanged<int>? onTap;

  const CommonScaffold({
    super.key,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? const TopNavbar(),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
      body: body,
      bottomNavigationBar:
          (currentIndex != null && onTap != null)
              ? BottomNavbar(currentIndex: currentIndex!, onTap: onTap!)
              : null,
    );
  }
}
