import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../widgets/common_scaffold.dart';
import 'widgets/diary_canvas.dart';
import 'widgets/pen_option_dialog.dart';
import 'widgets/sticker_picker_dialog.dart';
import 'widgets/background_picker_dialog.dart';
import 'widgets/emotion_picker_dialog.dart';
import 'widgets/piece_picker_dialog.dart';

class WriteTimecapsuleDiaryScreen extends StatefulWidget {
  const WriteTimecapsuleDiaryScreen({super.key});

  @override
  State<WriteTimecapsuleDiaryScreen> createState() =>
      _WriteTimecapsuleDiaryScreenState();
}

class _WriteTimecapsuleDiaryScreenState
    extends State<WriteTimecapsuleDiaryScreen> {
  final GlobalKey<DiaryCanvasState> canvasKey = GlobalKey<DiaryCanvasState>();
  final TextEditingController _titleController = TextEditingController();

  List<Map<String, dynamic>> selectedPieces = [];
  String? selectedEmotionId;
  DateTime? selectedOpenAt;

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 1,
      body: Column(
        children: [
          _buildTopBar(),
          if (selectedOpenAt != null) _buildOpenAtText(),
          Expanded(child: _buildCanvasStack()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => canvasKey.currentState?.addDateElement(),
            icon: const Icon(Icons.today),
            label: const Text("날짜 추가"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenAtText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "🕒 ${DateFormat('yyyy-MM-dd HH:mm').format(selectedOpenAt!)} 에 열리드릴 일기로 설정했습니다",
          style: const TextStyle(fontSize: 13, color: Colors.deepPurple),
        ),
      ),
    );
  }

  Widget _buildCanvasStack() {
    return Stack(
      children: [
        Positioned.fill(
          child: DiaryCanvas(key: canvasKey, elements: selectedPieces),
        ),
        Positioned(top: 24, left: 8, child: _buildToolButtons()),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 24,
          right: 12,
          child: FloatingActionButton(
            heroTag: 'piece_button',
            mini: true,
            backgroundColor: const Color(0xFFB69FCD),
            onPressed: _openPiecePicker,
            child: const Icon(Icons.grid_view),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 90,
          child: IconButton(
            icon: const Icon(Icons.lock_clock, color: Colors.deepPurple),
            tooltip: "열리는 시간 설정",
            onPressed: _pickOpenAt,
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
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButtons() {
    return Column(
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
                      canvasKey.currentState?.setPenOptions(color, width);
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
          icon: const Icon(Icons.image_outlined, color: Colors.deepPurple),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (_) => BackgroundPickerDialog(
                    onSelected: (url, id) {
                      canvasKey.currentState?.setBackground(url, id);
                    },
                  ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openPiecePicker() async {
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
                    canvasKey.currentState?.addPieces(selected);
                  });
                },
              ),
            ),
          ),
    );
  }

  Future<void> _pickOpenAt() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1); // 내일 0시

    final date = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) return;

    setState(() {
      selectedOpenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showEmotionDialogThenSave() {
    if (selectedOpenAt == null) {
      _showError("열리는 시간을 설정해주세요.");
      return;
    }

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
      "openAt": selectedOpenAt?.toUtc().toIso8601String(),
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
      debugPrint("타임캡슐 일기 저장 실패: $e");
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
