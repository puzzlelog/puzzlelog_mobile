import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class CommunityPageScreen extends StatelessWidget {
  const CommunityPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CommonScaffold(
      currentIndex: 2,
      body: Container(
        color: const Color(0xFFFAF5FF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _communityCard(
                  context,
                  title: '함께 나누는 소중한 이야기',
                  description: '다른 사용자와 일기를 공유하고 소통하는 공간입니다.\n함께 감정을 나누세요!',
                  buttonText: '커뮤니티로 이동',
                  onPressed: () => Navigator.pushNamed(context, '/postList'),
                ),
                const SizedBox(height: 20),
                _communityCard(
                  context,
                  title: '당신의 이야기를 공유하세요',
                  description: '다른 사용자들과 함께 일기를 작성하고 소통하며\n특별한 순간을 공유하세요.',
                  buttonText: '공유하기',
                  onPressed: () => Navigator.pushNamed(context, '/uploadPost'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _communityCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE2D5FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E57C2).withOpacity(0.8),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
