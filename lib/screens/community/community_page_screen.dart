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
      onTap: (_) {},
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20), // 상단과 본문 사이 여백
              // 반응형 카드 레이아웃
              isMobile
                  ? Column(
                    children: [
                      _leftCard(context),
                      const SizedBox(height: 16),
                      _rightCard(context),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _leftCard(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _rightCard(context)),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4D3D5A), // 어두운 보라
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '함께 나누는 이야기',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '다른 사용자와 일기를 공유하고 감정을 나누세요.',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/postList'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9E85B0),
            ),
            child: const Text('커뮤니티로 이동'),
          ),
        ],
      ),
    );
  }

  Widget _rightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF9E85B0), // 밝은 보라
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '당신의 이야기를 공유하세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '일기를 나누고 소통하며 특별한 순간을 만들어요.',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/uploadPost'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4F85),
            ),
            child: const Text('공유하기'),
          ),
        ],
      ),
    );
  }
}
