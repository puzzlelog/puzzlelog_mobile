import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/common_scaffold.dart';

class PieceBoxScreen extends StatefulWidget {
  const PieceBoxScreen({super.key});

  @override
  State<PieceBoxScreen> createState() => _PieceBoxScreenState();
}

class _PieceBoxScreenState extends State<PieceBoxScreen> {
  List pieces = [];
  bool loading = true;
  String? error;
  String filterType = "ALL";
  int currentPage = 1;
  int totalPages = 1;
  final int itemsPerPage = 10;

  final Map<String, String> typeLabels = {
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

  Future<void> fetchPieces() async {
    setState(() {
      loading = true;
      error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken') ?? '';

    if (userId == null) {
      setState(() {
        error = '로그인이 필요합니다.';
        loading = false;
      });
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final typeParam = filterType != "ALL" ? "&type=$filterType" : "";
    final url = Uri.parse(
      'https://api.puzzlelog.me/pieces?userId=$userId$typeParam&isDeleted=false&page=${currentPage - 1}&size=$itemsPerPage',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final decoded = utf8.decode(response.bodyBytes);
      final data = json.decode(decoded);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          pieces = List.from(data['data']['pieces'] ?? []);
          totalPages = (data['data']['pagination']['totalPages'] ?? 1);
          loading = false;
        });
      } else {
        throw Exception(data['message'] ?? '데이터 불러오기 실패');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> handleDelete(String pieceId) async {
    final confirmed = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('삭제 확인'),
            content: const Text('정말로 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final response = await http.delete(
      Uri.parse('https://api.puzzlelog.me/pieces/$pieceId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final decoded = utf8.decode(response.bodyBytes);
    final data = json.decode(decoded);
    if (response.statusCode == 200 && data['success']) {
      fetchPieces();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'] ?? '삭제 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text("오류: $error"))
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              '조각 모음집',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            children:
                                ["ALL", "TEXT", "IMAGE", "VIDEO", "AUDIO"]
                                    .map(
                                      (type) => ChoiceChip(
                                        label: Text(
                                          type == "ALL"
                                              ? "전체 보기"
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
                          const SizedBox(height: 12),
                          pieces.isEmpty
                              ? const Text('조각이 없습니다.')
                              : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6,
                                      childAspectRatio: 0.9,
                                    ),
                                itemCount: pieces.length,
                                itemBuilder: (context, index) {
                                  final piece = pieces[index];
                                  final type = piece['type'] ?? '';
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                typeLabels[type] ?? type,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed:
                                                    () => handleDelete(
                                                      piece['id'],
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: Align(
                                              alignment:
                                                  type == 'TEXT'
                                                      ? Alignment.topLeft
                                                      : Alignment.center,
                                              child: pieceWidget(piece),
                                            ),
                                          ),
                                          if (piece['tags'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                '태그: ${piece['tags'].join(", ")}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          Text(
                                            (piece['createdAt'] ?? '')
                                                .toString()
                                                .split('T')
                                                .first,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    currentPage == 1
                                        ? null
                                        : () {
                                          setState(() {
                                            currentPage--;
                                            fetchPieces();
                                          });
                                        },
                                child: const Text('이전'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text("$currentPage / $totalPages"),
                              ),
                              ElevatedButton(
                                onPressed:
                                    currentPage == totalPages
                                        ? null
                                        : () {
                                          setState(() {
                                            currentPage++;
                                            fetchPieces();
                                          });
                                        },
                                child: const Text('다음'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4), // 페이지네이션과 뒤로가기 간격 좁히기
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0x146B4EFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Color(0xFF6B4EFF),
                                ),
                              ),
                            ),
                            child: const Text(
                              "뒤로가기",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B4EFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }

  Widget pieceWidget(dynamic piece) {
    final type = piece['type'];
    final mediaId = piece['mediaId'];

    switch (type) {
      case 'TEXT':
        return Text(
          piece['text'] ?? '',
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          maxLines: 5,
          style: const TextStyle(fontSize: 12),
        );
      case 'IMAGE':
        if (mediaId == null || mediaId.toString().isEmpty) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        }
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            mediaId,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              mediaId,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
            ),
          ),
        );
      case 'VIDEO':
        return VideoThumbnailWidget(videoUrl: mediaId);
      case 'AUDIO':
        return AudioPlayerButton(url: mediaId);
      default:
        return const SizedBox();
    }
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (_) => Dialog(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.6,
                  child: VideoPlayerPopup(videoUrl: widget.videoUrl),
                ),
              ),
        );
      },
      child:
          _controller.value.isInitialized
              ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    const Icon(
                      Icons.play_circle_fill,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ],
                ),
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

class VideoPlayerPopup extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPopup({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPopup> createState() => _VideoPlayerPopupState();
}

class _VideoPlayerPopupState extends State<VideoPlayerPopup> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.network(widget.videoUrl)
          ..initialize().then((_) => setState(() {}))
          ..addListener(() {
            if (_controller.value.position == _controller.value.duration) {
              setState(() {});
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
            : const CircularProgressIndicator(),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              if (_controller.value.position == _controller.value.duration) {
                _controller.seekTo(Duration.zero);
                _controller.play();
              } else {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }
              setState(() {});
            },
            child: Icon(
              _controller.value.position == _controller.value.duration
                  ? Icons.replay
                  : (_controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
            ),
          ),
        ),
      ],
    );
  }
}

class AudioPlayerButton extends StatefulWidget {
  final String? url;
  const AudioPlayerButton({super.key, required this.url});

  @override
  State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
}

class _AudioPlayerButtonState extends State<AudioPlayerButton> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  bool isCompleted = false;
  double volume = 1.0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.url == null) return;

    if (isCompleted) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (isPlaying) {
      await _player.pause();
    } else {
      await _player.setUrl(widget.url!);
      await _player.setVolume(volume);
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final completed = state.processingState == ProcessingState.completed;
      if (mounted) {
        setState(() {
          isPlaying = playing;
          isCompleted = completed;
        });
      }
    });

    return SizedBox(
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isCompleted
                  ? Icons.replay
                  : (isPlaying ? Icons.pause : Icons.play_arrow),
              size: 32,
              color: Colors.deepPurple,
            ),
            onPressed: _togglePlay,
          ),
          SizedBox(
            height: 20,
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: (val) {
                setState(() => volume = val);
                _player.setVolume(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
