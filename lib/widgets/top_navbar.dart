import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // ← 안 보이게 한다.
      backgroundColor: const Color(0x661e1b4b), // 반투명 보라색
      elevation: 0,
      title: GestureDetector(
        onTap: () => Navigator.pushReplacementNamed(context, '/'),
        child: Image.asset('assets/logo.png', height: 30),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/myPage'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
