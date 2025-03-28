import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class PieceBoxMakeDiaryScreen extends StatefulWidget {
  const PieceBoxMakeDiaryScreen({super.key});

  @override
  State<PieceBoxMakeDiaryScreen> createState() =>
      _PieceBoxMakeDiaryScreenState();
}

class _PieceBoxMakeDiaryScreenState extends State<PieceBoxMakeDiaryScreen> {
  List<dynamic> pieces = [];
  List<dynamic> selectedPieces = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPieces();
  }

  Future<void> fetchPieces() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionCookie = prefs.getString('sessionCookie') ?? '';

      final dio = Dio();
      final response = await dio.get(
        'https://api.puzzlelog.me/pieces',
        options: Options(headers: {'Cookie': sessionCookie}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          pieces =
              response.data['data'] is List
                  ? response.data['data']
                  : response.data['data']['pieces'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('조각 불러오기 실패: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void selectPiece(dynamic piece) {
    setState(() {
      if (selectedPieces.any((p) => p['id'] == piece['id'])) {
        selectedPieces.removeWhere((p) => p['id'] == piece['id']);
      } else {
        if (selectedPieces.length >= 10) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('최대 10개까지 선택 가능합니다.')));
          return;
        }
        selectedPieces.add(piece);
      }
    });
  }

  bool isPieceSelected(dynamic piece) {
    return selectedPieces.any((p) => p['id'] == piece['id']);
  }

  void navigateToDiary() {
    if (selectedPieces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개의 조각을 선택해주세요!')));
      return;
    }

    Navigator.pushNamed(
      context,
      '/makeDiary',
      arguments: {'selectedPieces': selectedPieces},
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              '조각 모음집',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : pieces.isEmpty
                      ? const Center(child: Text('오늘 생성된 조각이 없습니다.'))
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: pieces.length,
                        itemBuilder: (_, idx) {
                          final piece = pieces[idx];
                          final selected = isPieceSelected(piece);
                          return GestureDetector(
                            onTap: () => selectPiece(piece),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    selected
                                        ? Border.all(
                                          color: Colors.brown,
                                          width: 3,
                                        )
                                        : null,
                                boxShadow: const [
                                  BoxShadow(blurRadius: 4, color: Colors.grey),
                                ],
                              ),
                              child: buildPieceContent(piece),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              onPressed: navigateToDiary,
              child: const Text('다음', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPieceContent(dynamic piece) {
    switch (piece['type']) {
      case 'IMAGE':
        return Image.network(piece['mediaId'], fit: BoxFit.cover);
      case 'AUDIO':
        return const Icon(Icons.audiotrack, size: 50, color: Colors.brown);
      case 'VIDEO':
        return const Icon(Icons.videocam, size: 50, color: Colors.brown);
      case 'TEXT':
        return SingleChildScrollView(
          child: Text(
            piece['content'] ?? '',
            style: const TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        );
      default:
        return const Icon(
          Icons.insert_drive_file,
          size: 50,
          color: Colors.grey,
        );
    }
  }
}
