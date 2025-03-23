import 'package:flutter/material.dart';
import './top_navbar.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  const CommonScaffold({
    super.key,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? const TopNavbar(),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
