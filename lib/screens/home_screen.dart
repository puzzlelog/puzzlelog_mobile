import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/common_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> pieces = [];
  String? playingPieceId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    fetchPieces();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> fetchPieces() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) return;

    final url = Uri.parse(
      'https://api.puzzlelog.me/pieces?userId=$userId&isDeleted=false&page=0&size=100',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final loaded =
            data['data']['pieces']
                .where((piece) => !(piece['isDeleted'] ?? false))
                .map<Map<String, dynamic>>(
                  (piece) => Map<String, dynamic>.from(piece),
                )
                .toList();

        setState(() => pieces = loaded);
      }
    } catch (e) {
      print('🚨 조각 불러오기 실패: $e');
    }
  }

  void togglePlayback(String pieceId) {
    setState(() {
      playingPieceId = (playingPieceId == pieceId) ? null : pieceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.35),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'PuzzleLog',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children:
                    pieces.map((piece) {
                      return GestureDetector(
                        onTap: () => togglePlayback(piece['id']),
                        child: PuzzlePieceWidget(
                          piece: piece,
                          isPlaying: playingPieceId == piece['id'],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PuzzlePieceWidget extends StatefulWidget {
  final Map<String, dynamic> piece;
  final bool isPlaying;
  const PuzzlePieceWidget({
    required this.piece,
    required this.isPlaying,
    super.key,
  });

  @override
  State<PuzzlePieceWidget> createState() => _PuzzlePieceWidgetState();
}

class _PuzzlePieceWidgetState extends State<PuzzlePieceWidget> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying && widget.piece['type'] == 'VIDEO') {
      _videoController =
          VideoPlayerController.network(widget.piece['mediaId'])
            ..initialize().then((_) => setState(() {}))
            ..play();
    } else if (widget.isPlaying && widget.piece['type'] == 'AUDIO') {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setUrl(widget.piece['mediaId']);
      _audioPlayer!.play();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.piece['type'];
    final content = widget.piece['content'] ?? '';
    final mediaId = widget.piece['mediaId'];

    return ClipPath(
      clipper: PuzzleClipper(),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          image:
              (type == 'IMAGE' && mediaId != null && mediaId.isNotEmpty)
                  ? DecorationImage(
                    image: NetworkImage(mediaId),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        alignment: Alignment.center,
        child: switch (type) {
          'TEXT' => Text(content, style: const TextStyle(color: Colors.white)),
          'VIDEO' =>
            _videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
                : const Icon(Icons.videocam, color: Colors.white),
          'AUDIO' => const Icon(Icons.audiotrack, color: Colors.white),
          _ => null,
        },
      ),
    );
  }
}

class PuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.85, 0);
    path.quadraticBezierTo(size.width, 0, size.width, size.height * 0.15);
    path.lineTo(size.width, size.height * 0.85);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width * 0.85,
      size.height,
    );
    path.lineTo(size.width * 0.15, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height * 0.85);
    path.lineTo(0, size.height * 0.15);
    path.quadraticBezierTo(0, 0, size.width * 0.15, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
