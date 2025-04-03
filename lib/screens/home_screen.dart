import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> pieces = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
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
                .map<Map<String, dynamic>>((piece) {
                  final castedPiece = Map<String, dynamic>.from(piece);
                  return {
                    ...castedPiece,
                    'angleOffset': Random().nextDouble() * 2 * pi,
                  };
                })
                .toList();

        setState(() => pieces = loaded);
      }
    } catch (e) {
      print('🚨 조각 불러오기 실패: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              final progress = _animationController.value;
              return Stack(
                children:
                    pieces.map((piece) {
                      final angle =
                          progress * 2 * pi + (piece['angleOffset'] ?? 0);
                      const radius = 140.0;
                      final offsetX = cos(angle) * radius;
                      final offsetY = sin(angle) * radius;

                      return Positioned(
                        left:
                            MediaQuery.of(context).size.width / 2 +
                            offsetX -
                            40,
                        top:
                            MediaQuery.of(context).size.height / 2 +
                            offsetY -
                            60,
                        child: PuzzlePieceWidget(piece: piece),
                      );
                    }).toList(),
              );
            },
          ),
          Center(
            child: Container(
              width: 180,
              height: 180,
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
          ),
        ],
      ),
    );
  }
}

class PuzzlePieceWidget extends StatelessWidget {
  final Map<String, dynamic> piece;
  const PuzzlePieceWidget({required this.piece, super.key});

  @override
  Widget build(BuildContext context) {
    final type = piece['type'];
    final content = piece['content'] ?? '';
    final mediaId = piece['mediaId'];

    return ClipPath(
      clipper: PuzzleClipper(),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          image:
              (type == 'IMAGE' &&
                      mediaId != null &&
                      mediaId is String &&
                      mediaId.isNotEmpty)
                  ? DecorationImage(
                    image: NetworkImage(mediaId),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        alignment: Alignment.center,
        child: switch (type) {
          'TEXT' => Text(content, style: const TextStyle(color: Colors.white)),
          'VIDEO' => const Icon(Icons.videocam, color: Colors.white),
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
