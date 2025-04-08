import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmotionPickerDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onEmotionSelected;

  const EmotionPickerDialog({super.key, required this.onEmotionSelected});

  @override
  State<EmotionPickerDialog> createState() => _EmotionPickerDialogState();
}

class _EmotionPickerDialogState extends State<EmotionPickerDialog> {
  List<Map<String, dynamic>> emotions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEmotions();
  }

  Future<void> fetchEmotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final res = await http.get(
        Uri.parse("https://api.puzzlelog.me/assets"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final decoded = json.decode(utf8.decode(res.bodyBytes));
      final data = List<Map<String, dynamic>>.from(decoded['data']);

      final filtered =
          data
              .where(
                (e) =>
                    e['type']?.toString().toLowerCase() == 'emotion' &&
                    (e['deleted'] == null || e['deleted'] == false),
              )
              .toList();

      setState(() {
        emotions = filtered;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ 감정 불러오기 실패: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFDF5EF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "오늘 당신의 기분은?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 480,
              height: 320,
              child:
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : emotions.isEmpty
                      ? const Center(child: Text('❌ 감정 이모션이 없습니다.'))
                      : GridView.builder(
                        itemCount: emotions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (_, index) {
                          final emotion = emotions[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onEmotionSelected(emotion);
                              Navigator.pop(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                emotion['mediaId'],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
