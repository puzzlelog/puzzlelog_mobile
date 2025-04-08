import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../widgets/common_scaffold.dart';
import 'widgets/diary_canvas.dart';
import 'widgets/pen_option_dialog.dart';
import 'widgets/sticker_picker_dialog.dart';
import 'widgets/background_picker_dialog.dart';
import 'widgets/emotion_picker_dialog.dart';
import 'widgets/piece_picker_dialog.dart';

class WriteNormalDiaryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPieces;

  const WriteNormalDiaryScreen({super.key, required this.selectedPieces});

  @override
  State<WriteNormalDiaryScreen> createState() => _WriteNormalDiaryScreenState();
}

class _WriteNormalDiaryScreenState extends State<WriteNormalDiaryScreen> {
  final GlobalKey<DiaryCanvasState> canvasKey = GlobalKey<DiaryCanvasState>();
  final TextEditingController _titleController = TextEditingController();

  List<Map<String, dynamic>> selectedPieces = [];
  String? selectedEmotionId;

  @override
  void initState() {
    super.initState();
    selectedPieces = widget.selectedPieces;
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 1,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _titleController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '제목을 입력하세요',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    canvasKey.currentState?.addDateElement();
                  },
                  icon: const Icon(Icons.today),
                  label: const Text("날짜 추가"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DiaryCanvas(key: canvasKey, elements: selectedPieces),
                ),
                Positioned(
                  top: 24,
                  left: 8,
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.brush, color: Colors.deepPurple),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => PenOptionDialog(
                                  initialColor: Colors.black,
                                  initialWidth: 3.0,
                                  onConfirm: (color, width) {
                                    canvasKey.currentState?.setPenOptions(
                                      color,
                                      width,
                                    );
                                  },
                                ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.sticky_note_2_outlined,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => StickerPickerDialog(
                                  onStickerSelected: (sticker) {
                                    canvasKey.currentState?.addSticker(sticker);
                                  },
                                ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.image_outlined,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (_) => BackgroundPickerDialog(
                                  onSelected: (url, id) {
                                    canvasKey.currentState?.setBackground(
                                      url,
                                      id,
                                    );
                                  },
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 24,
                  right: 12,
                  child: FloatingActionButton(
                    heroTag: 'piece_button',
                    mini: true,
                    backgroundColor: const Color(0xFFB69FCD),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => Dialog(
                              child: SizedBox(
                                width: 600,
                                height: 500,
                                child: PiecePickerDialog(
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedPieces.addAll(selected);
                                      canvasKey.currentState?.addPieces(
                                        selected,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ),
                      );
                    },
                    child: const Icon(Icons.grid_view),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: Row(
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'save_btn',
                        onPressed: _showEmotionDialogThenSave,
                        label: const Text('저장'),
                        icon: const Icon(Icons.save),
                        backgroundColor: const Color(0xFF6B4EFF),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        heroTag: 'back_btn',
                        backgroundColor: Colors.white,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmotionDialogThenSave() {
    showDialog(
      context: context,
      builder:
          (_) => EmotionPickerDialog(
            onEmotionSelected: (emotion) {
              selectedEmotionId = emotion['_id'];
              _saveDiary();
            },
          ),
    );
  }

  Future<void> _saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    final elements = canvasKey.currentState?.getCanvasElements() ?? [];
    final backgroundId = canvasKey.currentState?.backgroundContentId;
    final title =
        _titleController.text.trim().isEmpty
            ? "제목 없음"
            : _titleController.text.trim();

    final body = {
      "userId": userId,
      "title": title,
      "emotionContentId": selectedEmotionId,
      "backgroundContentId": backgroundId,
      "themeColor": "#FFFFFF",
      "isShared": false,
      "openAt": null,
      "timeZone": "Asia/Seoul",
      "elements": elements,
    };

    try {
      final res = await http.post(
        Uri.parse("https://api.puzzlelog.me/diaries"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final result = json.decode(utf8.decode(res.bodyBytes));
      if (result['success'] == true) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/diaryBox');
        }
      } else {
        _showError(result['message'] ?? '알 수 없는 오류');
      }
    } catch (e) {
      debugPrint("❌ 일기 저장 실패: $e");
      _showError('서버 오류가 발생했습니다.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) =>
              AlertDialog(title: const Text("저장 실패"), content: Text(message)),
    );
  }
}
