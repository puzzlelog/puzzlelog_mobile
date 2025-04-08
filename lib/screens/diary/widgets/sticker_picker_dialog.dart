import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StickerPickerDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onStickerSelected;

  const StickerPickerDialog({super.key, required this.onStickerSelected});

  @override
  State<StickerPickerDialog> createState() => _StickerPickerDialogState();
}

class _StickerPickerDialogState extends State<StickerPickerDialog> {
  List<Map<String, dynamic>> allStickers = [];
  String selectedCategory = 'ALL';
  bool loading = true;

  int currentPage = 0;
  final int pageSize = 12;

  final Map<String, String> categoryKorean = {
    'dolls': '인형',
    'audio': '오디오',
    'camera': '카메라',
    'daily': '일상',
    'emoji': '이모지',
    'food': '음식',
    'language': '언어',
    'tape': '테이프',
    'vintage': '빈티지',
  };

  @override
  void initState() {
    super.initState();
    fetchStickers();
  }

  Future<void> fetchStickers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse("https://api.puzzlelog.me/assets/type/STICKER"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<Map<String, dynamic>> raw = List<Map<String, dynamic>>.from(
        decoded['data'],
      );

      setState(() {
        allStickers = raw;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ 스티커 로딩 실패: $e");
      setState(() {
        allStickers = [];
        loading = false;
      });
    }
  }

  List<String> getAllCategories() {
    final tags = allStickers.expand((e) => (e['tags'] ?? [])).cast<String>();
    return ['ALL', ...tags.toSet()];
  }

  List<Map<String, dynamic>> getFilteredStickers() {
    if (selectedCategory == 'ALL') return allStickers;
    return allStickers
        .where((s) => (s['tags'] ?? []).contains(selectedCategory))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredStickers();
    final totalPages = (filtered.length / pageSize).ceil();
    final visible =
        filtered.skip(currentPage * pageSize).take(pageSize).toList();

    return Dialog(
      backgroundColor: const Color(0xFFFDF5EF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 640,
        height: 600,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      '스티커 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    // 카테고리 필터
                    Wrap(
                      spacing: 6,
                      children:
                          getAllCategories().map((cat) {
                            return ChoiceChip(
                              label: Text(
                                cat == 'ALL'
                                    ? '전체'
                                    : categoryKorean[cat] ?? cat,
                              ),
                              selected: selectedCategory == cat,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategory = cat;
                                  currentPage = 0;
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // 스티커 목록
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final sticker = visible[index];
                          final isLocked = sticker['locked'] == true;

                          return GestureDetector(
                            onTap: () {
                              if (!isLocked) {
                                widget.onStickerSelected(sticker);
                                Navigator.pop(context);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.deepPurple.shade100,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      sticker['mediaId'],
                                      fit: BoxFit.contain,
                                      color:
                                          isLocked
                                              ? Colors.black.withOpacity(0.4)
                                              : null,
                                      colorBlendMode:
                                          isLocked ? BlendMode.darken : null,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                if (isLocked)
                                  const Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        "🔒 결제 필요",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          backgroundColor: Colors.black45,
                                          fontSize: 12,
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
