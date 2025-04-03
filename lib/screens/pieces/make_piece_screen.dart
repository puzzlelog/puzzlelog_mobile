import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class MakePieceScreen extends StatelessWidget {
  const MakePieceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '당신의 이야기를 한 조각씩 채워보세요.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F35),
                ),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  _buildPieceCard(
                    context,
                    '나만의 글 조각 작성',
                    '당신의 생각과 감정을 표현할 수 있는 공간입니다. 글 조각을 통해 감정을 기록해 보세요.',
                    'assets/text_piece.png',
                    '/writeTextPiece',
                  ),
                  _buildPieceCard(
                    context,
                    '순간의 사진 조각 작성',
                    '소중한 순간을 사진으로 남겨보세요. 당신만의 특별한 기억을 기록할 수 있습니다.',
                    'assets/image_piece.png',
                    '/writeImagePiece',
                  ),
                  _buildPieceCard(
                    context,
                    '공유 동영상 조각 작성',
                    '순간을 동영상으로 담아보세요. 추억을 생생하게 기록할 수 있습니다.',
                    'assets/video_piece.png',
                    '/writeVideoPiece',
                  ),
                  _buildPieceCard(
                    context,
                    '기억할 음성 조각 작성',
                    '소중한 목소리를 남겨보세요. 오디오를 통해 추억을 더욱 특별하게 보관할 수 있습니다.',
                    'assets/audio_piece.png',
                    '/writeAudioPiece',
                  ),
                ],
              ),
            ],
          ),
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
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: const Color(0xFFEADDC5),
        margin: const EdgeInsets.only(bottom: 20), // 카드 간격 추가
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4F35),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
