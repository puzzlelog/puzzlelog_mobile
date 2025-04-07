import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int? currentIndex;

  const BottomNavbar({super.key, required this.currentIndex});

  static const List<String> _routes = [
    '/makePiece',
    '/makeDiary',
    '/community',
    '/challenge',
    '/myPage',
  ];

  @override
  Widget build(BuildContext context) {
    final validIndex =
        (currentIndex != null &&
                currentIndex! >= 0 &&
                currentIndex! < _routes.length)
            ? currentIndex!
            : -1;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: validIndex == -1 ? 0 : validIndex,
      selectedItemColor: validIndex == -1 ? Colors.white70 : Colors.white,
      unselectedItemColor: Colors.white70,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      onTap: (index) {
        final currentRoute = ModalRoute.of(context)?.settings.name;
        final targetRoute = _routes[index];
        if (currentRoute != targetRoute) {
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '조각'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: '일기'),
        BottomNavigationBarItem(icon: Icon(Icons.forum), label: '커뮤니티'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '챌린지'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
      ],
    );
  }
}
