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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _communityCard(
                    context,
                    title: '함께 나누는 소중한 이야기',
                    description: '다른 사용자와 일기를 공유하고 소통하는 공간입니다.\n함께 감정을 나누세요!',
                    buttonText: '커뮤니티로 이동',
                    onPressed: () => Navigator.pushNamed(context, '/postList'),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _communityCard(
                    context,
                    title: '당신의 이야기를 공유하세요',
                    description: '다른 사용자들과 함께 일기를 작성하고 소통하며\n특별한 순간을 공유하세요.',
                    buttonText: '공유하기',
                    onPressed:
                        () => Navigator.pushNamed(context, '/uploadPost'),
                  ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
              elevation: 4,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
