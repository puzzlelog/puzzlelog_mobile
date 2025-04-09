// piece_picker_dialog.dart (리팩토링 + 미디어 처리 개선)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class PiecePickerDialog extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>) onSelected;

  const PiecePickerDialog({super.key, required this.onSelected});

  @override
  State<PiecePickerDialog> createState() => _PiecePickerDialogState();
}

class _PiecePickerDialogState extends State<PiecePickerDialog> {
  List<Map<String, dynamic>> pieces = [];
  List<String> selectedIds = [];
  bool loading = true;
  int currentPage = 1;
  int totalPages = 1;
  String filterType = "ALL";
  final int itemsPerPage = 10;
  final Map<String, VideoPlayerController> videoControllers = {};
  final Map<String, AudioPlayer> audioPlayers = {};

  final typeLabels = {
    'TEXT': '글 조각',
    'IMAGE': '사진 조각',
    'VIDEO': '영상 조각',
    'AUDIO': '음성 조각',
  };

  @override
  void initState() {
    super.initState();
    fetchPieces();
  }

  @override
  void dispose() {
    for (final controller in videoControllers.values) {
      controller.dispose();
    }
    for (final player in audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> fetchPieces() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken') ?? '';

    final typeParam = filterType != "ALL" ? "&type=$filterType" : "";
    final url = Uri.parse(
      'https://api.puzzlelog.me/pieces?userId=$userId$typeParam&isDeleted=false&page=${currentPage - 1}&size=$itemsPerPage',
    );
    print('📡 API 호출 URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = json.decode(decoded);

      if (response.statusCode == 200 && data['success']) {
        final newPieces = List<Map<String, dynamic>>.from(
          data['data']['pieces'],
        );
        setState(() {
          pieces = newPieces;
          totalPages = data['data']['pagination']['totalPages'] ?? 1;
          loading = false;
        });

        for (final piece in newPieces) {
          if (piece['type'] == 'VIDEO' &&
              !videoControllers.containsKey(piece['id'])) {
            final controller = VideoPlayerController.network(piece['mediaId'])
              ..initialize().then((_) => setState(() {}));
            videoControllers[piece['id']] = controller;
          }
          if (piece['type'] == 'AUDIO' &&
              !audioPlayers.containsKey(piece['id'])) {
            final player = AudioPlayer();
            player.setUrl(piece['mediaId']);
            audioPlayers[piece['id']] = player;
          }
        }
      } else {
        throw Exception('조각 로딩 실패');
      }
    } catch (e) {
      setState(() {
        pieces = [];
        loading = false;
      });
    }
  }

  Widget _buildPreview(Map<String, dynamic> piece) {
    final id = piece['id'];
    final type = piece['type'];
    final mediaId = piece['mediaId'];

    switch (type) {
      case 'TEXT':
        final text = piece['text'] ?? '';
        return text.isNotEmpty
            ? Text(text, maxLines: 3, overflow: TextOverflow.ellipsis)
            : const Text('내용 없음');
      case 'IMAGE':
        return (mediaId != null && mediaId != "")
            ? Image.network(mediaId, fit: BoxFit.cover)
            : const Icon(Icons.broken_image);
      case 'VIDEO':
        final controller = videoControllers[id];
        return (controller != null && controller.value.isInitialized)
            ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )
            : const Icon(Icons.play_circle, size: 36);
      case 'AUDIO':
        return const Icon(Icons.audiotrack, size: 36);
      default:
        return const Text('알 수 없음');
    }
  }

  void _toggleMedia(String id, String type) {
    if (type == 'VIDEO') {
      final controller = videoControllers[id];
      if (controller != null && controller.value.isInitialized) {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      }
    } else if (type == 'AUDIO') {
      final player = audioPlayers[id];
      if (player != null) {
        player.playing ? player.pause() : player.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 600,
        height: 550,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        '조각 선택',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children:
                          ["ALL", "TEXT", "IMAGE", "VIDEO", "AUDIO"]
                              .map(
                                (type) => ChoiceChip(
                                  label: Text(
                                    type == 'ALL'
                                        ? '전체'
                                        : typeLabels[type] ?? type,
                                  ),
                                  selected: filterType == type,
                                  onSelected: (_) {
                                    setState(() {
                                      filterType = type;
                                      currentPage = 1;
                                    });
                                    fetchPieces();
                                  },
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: pieces.length,
                        itemBuilder: (context, index) {
                          final piece = pieces[index];
                          final id = piece['id'];
                          final type = piece['type'];
                          final selected = selectedIds.contains(id);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selected
                                    ? selectedIds.remove(id)
                                    : selectedIds.add(id);
                                _toggleMedia(id, type);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      selected
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                  width: selected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                children: [
                                  Positioned.fill(child: _buildPreview(piece)),
                                  if (selected)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              currentPage > 1
                                  ? () => setState(() {
                                    currentPage--;
                                    fetchPieces();
                                  })
                                  : null,
                          child: const Text('이전'),
                        ),
                        const SizedBox(width: 10),
                        Text('$currentPage / $totalPages'),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed:
                              currentPage < totalPages
                                  ? () => setState(() {
                                    currentPage++;
                                    fetchPieces();
                                  })
                                  : null,
                          child: const Text('다음'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          final selected =
                              pieces
                                  .where((p) => selectedIds.contains(p['id']))
                                  .map(
                                    (p) => {
                                      'elementType': p['type'],
                                      'mediaId': p['mediaId'],
                                      'contentId': p['id'],
                                      'text': p['text'],
                                      'position': [100.0, 100.0],
                                      'scale': 1.0,
                                      'rotation': 0.0,
                                    },
                                  )
                                  .toList();
                          widget.onSelected(selected);
                          Navigator.pop(context);
                        },
                        child: const Text("선택 완료"),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
