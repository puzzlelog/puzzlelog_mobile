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
      backgroundColor: const Color.fromARGB(35, 67, 60, 199),
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

  @override
  Size get preferredSize => const Size.fromHeight(60);
}