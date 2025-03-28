import 'package:flutter/material.dart';

class MainNavbar extends StatelessWidget implements PreferredSizeWidget {
  const MainNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(35, 67, 60, 199),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _navItem(context, '조각', '/makePiece'),
            _popupMenu(context, '일기', {
              '나의 일기': () => Navigator.pushNamed(context, '/pieceBoxMakeDiary'),
              '협업 일기': () => Navigator.pushNamed(context, '/makeTogether'),
            }),
            _navItem(context, '캘린더', '/calendar'),
            _navItem(context, '커뮤니티', '/community'),
            _popupMenu(context, '모음집', {
              '조각 모음집': () => Navigator.pushNamed(context, '/pieceBox'),
              '일기 모음집': () => Navigator.pushNamed(context, '/diaryBox'),
              '타임캡슐': () => Navigator.pushNamed(context, '/timecapsuleBox'),
            }),
            _popupMenu(context, '마이페이지', {
              '내 정보': () => Navigator.pushNamed(context, '/myPage'),
              '앨범': () => Navigator.pushNamed(context, '/digitalAlbum'),
              '챌린지': () => Navigator.pushNamed(context, '/challenge'),
              '구독 정보': () => Navigator.pushNamed(context, '/subscribe'),
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _popupMenu(BuildContext context, String label, Map<String, VoidCallback> items) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => items.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              onTap: entry.value,
              child: Text(entry.key),
            ),
          )
          .toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}