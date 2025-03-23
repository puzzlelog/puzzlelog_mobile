import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '도전! 챌린지',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '챌린지를 성공하여 얻은 보상으로 puzzelog의 잠겨진 기능들을 열어보세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: 3,
              itemBuilder: (_, idx) => Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('이미지', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '진행 중인 미션 리스트',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '각 미션의 진행 상황을 퍼센트로 보여줍니다.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Text(
                        '🔵 김철수 • 11 Jan 2022 • 5분 소요',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '현재 진행 중인 미션과 달성 현황을 확인하세요!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700]),
            ),
            const SizedBox(height: 10),
            const Text(
              '각 미션의 진행 상황을 쉽게 확인할 수 있습니다. 목표 달성을 위한 여정을 함께하세요.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                _buildProgressItem('미션을 완료하고 보상을 받으세요!', 0.75),
                const SizedBox(height: 20),
                _buildProgressItem('지금 바로 도전해 보세요!', 0.30),
                const SizedBox(height: 20),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('이미지', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String text, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(progress * 100).round()}% $text',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: Colors.brown[700],
          minHeight: 10,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}