import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/common_scaffold.dart';

class MakeDiaryScreen extends StatelessWidget {
  const MakeDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final cardWidth = isWide ? 280.0 : double.infinity;
    const cardColor = Color(0xFFB388FF);

    return CommonScaffold(
      currentIndex: 1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 버튼
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/diaryBox'),
                  icon: const Icon(
                    Icons.grid_view,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "일기 모음 보기",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),

            // 세로 3단 카드
            _buildDiaryCard(
              context,
              '일반 일기 작성',
              '일상의 생각과 감정을 자유롭게 기록하세요.',
              'assets/normal_diary.jpg',
              '/writeNormalDiary',
              cardWidth,
              backgroundColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildDiaryCard(
              context,
              '타임캡슐 일기 작성',
              '설정한 시간이 지나야 열리는 비밀스런 일기예요.',
              'assets/timecapsule_diary.jpg',
              '/writeTimecapsuleDiary',
              cardWidth,
              backgroundColor: cardColor,
            ),
            const SizedBox(height: 12),
            _buildDiaryCard(
              context,
              '협업 일기 작성',
              '친구들과 함께 만드는 공동 일기를 시작해보세요.',
              'assets/collab_diary.jpg',
              '/writeCollaborativeDiary',
              cardWidth,
              backgroundColor: cardColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard(
    BuildContext context,
    String title,
    String description,
    String imagePath,
    String route,
    double width, {
    required Color backgroundColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.4),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
