import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onTap; // ✅ 외부 콜백 (선택)

  const TopNavbar({super.key, this.onTap});

  // JWT 존재 여부 확인
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        final loggedIn = snapshot.data ?? false;

        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0x661e1b4b), // 반투명 보라색
          elevation: 0,
          title: GestureDetector(
            onTap: () => _handleTap(context, '/'),
            child: Image.asset('assets/logo.png', height: 30),
          ),
          actions: [
            if (loggedIn)
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () => _handleTap(context, '/notifications'),
              ),
            if (loggedIn)
              IconButton(
                icon: const Icon(Icons.group, color: Colors.white),
                onPressed: () => _handleTap(context, '/friend'),
              ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => _handleTap(context, '/settings'),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  // 탭 동작 처리 (외부 콜백이 있으면 우선 사용)
  void _handleTap(BuildContext context, String route) {
    if (onTap != null) {
      onTap!(route);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
