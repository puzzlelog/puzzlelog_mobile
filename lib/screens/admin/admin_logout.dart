import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLogoutFloatingButton extends StatelessWidget {
  const AdminLogoutFloatingButton({super.key});

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
    return FloatingActionButton.extended(
      onPressed: () => handleLogout(context),
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.logout),
      label: const Text('로그아웃'),
    );
  }
}
