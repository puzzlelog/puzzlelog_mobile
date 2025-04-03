import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<String> _routes = [
    '/makePiece',
    '/diaryBox',
    '/community',
    '/challenge',
    '/myPage',
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          Navigator.pushReplacementNamed(context, _routes[index]);
        }
        onTap(index);
      },
      backgroundColor: const Color(0xFF2e1a47), // 보라 배경
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
