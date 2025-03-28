import 'package:flutter/material.dart';
import './top_navbar.dart';
import './main_navbar.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final bool showMainNavigationBar;

  const CommonScaffold({
    super.key,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.showMainNavigationBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? const TopNavbar(), // 로고 + 로그인/로그아웃만 표시
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          if (showMainNavigationBar) const MainNavbar(), // 메뉴 바로 추가
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
