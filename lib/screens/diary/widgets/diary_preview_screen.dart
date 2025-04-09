import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'diary_canvas.dart';

class DiaryPreviewScreen extends StatefulWidget {
  final String diaryId;

  const DiaryPreviewScreen({super.key, required this.diaryId});

  @override
  State<DiaryPreviewScreen> createState() => _DiaryPreviewScreenState();
}

class _DiaryPreviewScreenState extends State<DiaryPreviewScreen> {
  List<Map<String, dynamic>> elements = [];
  String? backgroundUrl;
  String title = "";
  String diaryType = "";
  DateTime? createdAt;
  String? openAt;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiaryDetail();
  }

  Future<void> fetchDiaryDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) return;

    try {
      final res = await Dio().get(
        'https://api.puzzlelog.me/diaries/${widget.diaryId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data['success']) {
        final data = res.data['data'];

        // 일기 종류 분류
        final participants = data['participants'];
        final openAtRaw = data['openAt'];
        if (participants is List && participants.length > 1) {
          diaryType = "협업 일기";
        } else if (openAtRaw != null && openAtRaw.toString().isNotEmpty) {
          diaryType = "타임캡슐 일기";
        } else {
          diaryType = "일반 일기";
        }

        setState(() {
          title = data['title'] ?? '';
          createdAt = DateTime.tryParse(data['createdAt'] ?? '');
          openAt = data['openAt'];
          elements = List<Map<String, dynamic>>.from(data['elements'] ?? []);
          backgroundUrl = data['background']?['mediaId'];
          isLoading = false;
        });
      } else {
        throw Exception("일기 불러오기 실패");
      }
    } catch (e) {
      debugPrint('일기 불러오기 오류: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final created =
        createdAt != null
            ? DateFormat("yyyy-MM-dd HH:mm").format(createdAt!)
            : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("일기 미리보기"),
        backgroundColor: Colors.deepPurple,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 🔹 일기 메타 정보 표시
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$title",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "($diaryType / $created)",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Canvas
                  Expanded(
                    child: Stack(
                      children: [
                        DiaryCanvas(
                          elements: elements,
                          backgroundUrl: backgroundUrl,
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
