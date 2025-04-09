import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundPickerDialog extends StatefulWidget {
  final void Function(String mediaUrl, String backgroundId) onSelected;

  const BackgroundPickerDialog({super.key, required this.onSelected});

  @override
  State<BackgroundPickerDialog> createState() => _BackgroundPickerDialogState();
}

class _BackgroundPickerDialogState extends State<BackgroundPickerDialog> {
  List<Map<String, dynamic>> backgrounds = [];
  bool loading = true;

  int currentPage = 0;
  final int pageSize = 12;

  @override
  void initState() {
    super.initState();
    fetchBackgrounds();
  }

  Future<void> fetchBackgrounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final res = await http.get(
        Uri.parse("https://api.puzzlelog.me/assets/type/BACKGROUND"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        json.decode(utf8.decode(res.bodyBytes))['data'],
      );

      setState(() {
        backgrounds = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ 배경 불러오기 실패: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (backgrounds.length / pageSize).ceil();
    final visible =
        backgrounds.skip(currentPage * pageSize).take(pageSize).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFF3b0764),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 640,
        height: 560,
        child: Column(
          children: [
            // 배경 제거
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton.icon(
                  onPressed: () {
                    widget.onSelected('', '');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: const Text(
                    '배경 제거',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // 썸네일 그리드
            Expanded(
              child:
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final bg = visible[index];
                          final isLocked = bg['locked'] == true;
                          final mediaUrl = bg['mediaId'];
                          final id = bg['_id'] ?? bg['id'];

                          return GestureDetector(
                            onTap: () {
                              if (!isLocked) {
                                widget.onSelected(mediaUrl, id);
                                Navigator.pop(context);
                              }
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    mediaUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    color:
                                        isLocked
                                            ? Colors.black.withOpacity(0.4)
                                            : null,
                                    colorBlendMode:
                                        isLocked ? BlendMode.darken : null,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                if (isLocked)
                                  const Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        '🔒 잠긴 배경',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          backgroundColor: Colors.black45,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),

            // 페이지네이션
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed:
                      currentPage > 0
                          ? () => setState(() => currentPage--)
                          : null,
                  child: const Text('이전'),
                ),
                const SizedBox(width: 20),
                Text('${currentPage + 1} / $totalPages'),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed:
                      currentPage < totalPages - 1
                          ? () => setState(() => currentPage++)
                          : null,
                  child: const Text('다음'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
