import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class CollaborativeDiaryCreateScreen extends StatefulWidget {
  final List<dynamic> selectedPieces;
  final String? date;
  final List<String> friendIds;

  const CollaborativeDiaryCreateScreen({
    super.key,
    required this.selectedPieces,
    this.date,
    required this.friendIds,
  });

  @override
  State<CollaborativeDiaryCreateScreen> createState() =>
      _CollaborativeDiaryCreateScreenState();
}

class _CollaborativeDiaryCreateScreenState
    extends State<CollaborativeDiaryCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  String? error;
  bool showEmotionSelector = false;

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '협업 일기 만들기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '오늘의 제목을 입력하세요',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🛠️ FabricCanvasEditor 대체 위젯 영역'),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => setState(() => showEmotionSelector = true),
                      child: const Text('요청하기'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소하기'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                if (showEmotionSelector) ...[
                  const SizedBox(height: 32),
                  const Text(
                    '오늘 당신의 기분은?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: List.generate(
                      8,
                      (i) => InkWell(
                        onTap:
                            () => handleSubmit(emotionStickerId: 'emotion-$i'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('😀'),
                          ), // TODO: 스티커 이미지 대체
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        () => setState(() => showEmotionSelector = false),
                    child: const Text(
                      '닫기',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleSubmit({String? emotionStickerId}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => error = '제목을 입력해주세요.');
      return;
    }

    if (widget.friendIds.isEmpty) {
      setState(() => error = '협업할 친구 정보가 없습니다.');
      return;
    }

    // TODO: 캔버스 요소 + 오디오/비디오 포함해서 elements 생성
    // TODO: diary POST 후 /invitations 전송
    debugPrint('🟢 diary 생성 및 초대 요청 처리 시작');
  }
}
