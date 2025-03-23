import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class CommunityPageScreen extends StatelessWidget {
  const CommunityPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/home'),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 120,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6B4F35)),
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF6B4F35),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF6F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '함께 나누는 소중한 이야기',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B0805),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '다른 사용자와 일기를 공유하고 소통하는 공간입니다. 함께 감정을 나누세요!',
                            style: TextStyle(fontSize: 16, color: Color(0xFF0B0805)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/postList'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDEB784),
                            ),
                            child: const Text('커뮤니티로 이동'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEB784),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '당신의 이야기를 공유하세요',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '다른 사용자들과 함께 일기를 작성하고 소통하며 특별한 순간을 공유하세요.',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/uploadPost'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B4F35),
                            ),
                            child: const Text('공유하기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}