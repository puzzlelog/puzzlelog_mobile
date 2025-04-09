import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/common_scaffold.dart';

class MakePieceScreen extends StatelessWidget {
  const MakePieceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final cardWidth =
        isWide ? 280.0 : (MediaQuery.of(context).size.width - 56) / 2;
    const cardColor = Color(0xFFB388FF); // 동일한 보라색 배경

    return CommonScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // 하단 광고 배너 여백
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/pieceBox'),
                  icon: const Icon(
                    Icons.grid_view,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    '조각 모음 보기',
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
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildPieceCard(
                  context,
                  '글 조각 작성',
                  '당신의 생각과 감정을 표현할 수 있는 공간입니다.',
                  'assets/text_piece.png',
                  '/writeTextPiece',
                  cardWidth,
                  backgroundColor: cardColor,
                ),
                _buildPieceCard(
                  context,
                  '사진 조각 작성',
                  '소중한 순간을 사진으로 남겨보세요.',
                  'assets/image_piece.png',
                  '/writeImagePiece',
                  cardWidth,
                  backgroundColor: cardColor,
                ),
                _buildPieceCard(
                  context,
                  '영상 조각 작성',
                  '직접 찍은 추억을 기록해보세요.',
                  'assets/video_piece.png',
                  '/writeVideoPiece',
                  cardWidth,
                  backgroundColor: cardColor,
                ),
                _buildPieceCard(
                  context,
                  '음성 조각 작성',
                  '당신의 목소리를 남겨보세요.',
                  'assets/audio_piece.png',
                  '/writeAudioPiece',
                  cardWidth,
                  backgroundColor: cardColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceCard(
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
          height: 200,
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
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
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
