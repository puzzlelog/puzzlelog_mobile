import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  Future<void> handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/adminPage'),
            child: Image.asset(
              'assets/logo.png', // Flutter에서는 assets 폴더에 logo.png가 있어야 함
              height: 40,
            ),
          ),
          ElevatedButton(
            onPressed: () => handleLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
