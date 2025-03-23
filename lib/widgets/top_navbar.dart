import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavbar({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.1),
      elevation: 1,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Image.asset('assets/logo.png', height: 35),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
              ),
              FutureBuilder<bool>(
                future: _isLoggedIn(),
                builder: (context, snapshot) {
                  bool loggedIn = snapshot.data ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: loggedIn
                        ? OutlinedButton(
                            onPressed: () async {
                              final confirmLogout = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("로그아웃"),
                                  content: const Text("정말 로그아웃 하시겠습니까?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("취소"),
                                      onPressed: () => Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: const Text("확인"),
                                      onPressed: () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmLogout == true) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('userId');
                                await prefs.remove('token');
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text('로그아웃'),
                          )
                        : ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('로그인'),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => items.entries
          .map((entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.key),
                onTap: entry.value,
              ))
          .toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
