import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';
import 'package:intl/intl.dart';

class MakeDiaryScreen extends StatefulWidget {
  final List<dynamic> selectedPieces;
  final bool isTimeCapsule;
  final String? openAt;

  const MakeDiaryScreen({
    super.key,
    required this.selectedPieces,
    this.isTimeCapsule = false,
    this.openAt,
  });

  @override
  State<MakeDiaryScreen> createState() => _MakeDiaryScreenState();
}

class _MakeDiaryScreenState extends State<MakeDiaryScreen> {
  final TextEditingController _titleController = TextEditingController();
  List<dynamic> emotionStickers = [];
  String? selectedEmotionSticker;

  @override
  void initState() {
    super.initState();
    fetchEmotionStickers();
  }

  Future<void> fetchEmotionStickers() async {
    final dio = Dio();
    final res = await dio.get('https://api.puzzlelog.me/assets');
    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        emotionStickers =
            res.data['data']
                .where(
                  (s) =>
                      (s['type']?.toLowerCase() == 'emotion' ||
                          (s['tags'] as List?)?.contains('emotion') == true),
                )
                .toList();
      });
    }
  }

  Future<void> saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';
    final token = prefs.getString('accessToken') ?? '';

    final elements =
        widget.selectedPieces
            .map(
              (p) => {
                "elementType": p['type'],
                "contentId": p['id'],
                "position": [0, 0],
                "scale": 1.0,
                "rotation": 0,
              },
            )
            .toList();

    final diaryData = {
      "userId": userId,
      "title":
          _titleController.text.trim().isEmpty
              ? "제목 없음"
              : _titleController.text.trim(),
      "backgroundContentId": "default-background-id",
      "themeColor": "#FFECCC",
      "emotionContentId": selectedEmotionSticker,
      "isShared": false,
      "openAt": widget.isTimeCapsule ? widget.openAt : null,
      "elements": elements,
      "timeZone": "Asia/Seoul",
    };

    try {
      final dio = Dio();
      final res = await dio.post(
        "https://api.puzzlelog.me/diaries",
        data: diaryData,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (res.statusCode == 200 && res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일기 저장 완료!')));
          Navigator.pop(context);
        }
      } else {
        throw Exception('저장 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('일기 저장 실패')));
      }
    }
  }

  void showEmotionSelector() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(20),
            height: 250,
            child: Column(
              children: [
                const Text(
                  '오늘 당신의 기분은?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: emotionStickers.length,
                    itemBuilder: (_, idx) {
                      final sticker = emotionStickers[idx];
                      return GestureDetector(
                        onTap: () {
                          setState(
                            () => selectedEmotionSticker = sticker['id'],
                          );
                          Navigator.pop(context);
                          saveDiary();
                        },
                        child: Image.network(sticker['mediaId'] ?? ''),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '오늘의 제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  '🧩 캔버스 에디터는 추후 추가 예정입니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소하기'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  onPressed:
                      emotionStickers.isNotEmpty ? showEmotionSelector : null,
                  child: const Text(
                    '저장하기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
