import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_scaffold.dart';

class CollaborativeSelectPiecesScreen extends StatefulWidget {
  final String date;
  final List<String> friendIds;

  const CollaborativeSelectPiecesScreen({
    super.key,
    required this.date,
    required this.friendIds,
  });

  @override
  State<CollaborativeSelectPiecesScreen> createState() =>
      _CollaborativeSelectPiecesScreenState();
}

class _CollaborativeSelectPiecesScreenState
    extends State<CollaborativeSelectPiecesScreen> {
  List<Map<String, dynamic>> allPieces = []; // 전체 불러온 조각들
  List<Map<String, dynamic>> selectedPieces = [];
  String? error;

  @override
  void initState() {
    super.initState();
    fetchPieces();
  }

  Future<void> fetchPieces() async {
    try {
      final userIds = ['user', ...widget.friendIds];
      debugPrint('🔍 fetchPieces: ${widget.date} / $userIds');

      // TODO: 실제 API 연동
      final dummy = List.generate(
        8,
        (i) => {
          'id': '$i',
          'type':
              i % 4 == 0
                  ? 'TEXT'
                  : i % 4 == 1
                  ? 'IMAGE'
                  : i % 4 == 2
                  ? 'VIDEO'
                  : 'AUDIO',
          'text': '샘플 조각 $i',
          'mediaId': null,
          'createdAt':
              DateTime.now().subtract(Duration(days: i)).toIso8601String(),
          'userId': i % 2 == 0 ? 'user' : 'friend',
          'tags': ['tag$i'],
        },
      );

      setState(() {
        allPieces = dummy;
      });
    } catch (e) {
      setState(() => error = '조각을 불러오는 데 실패했습니다.');
    }
  }

  void togglePiece(Map<String, dynamic> piece) {
    setState(() {
      final exists = selectedPieces.any((p) => p['id'] == piece['id']);
      if (exists) {
        selectedPieces.removeWhere((p) => p['id'] == piece['id']);
      } else {
        if (selectedPieces.length >= 10) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('최대 10개까지 선택 가능합니다.')));
        } else {
          selectedPieces.add(piece);
        }
      }
    });
  }

  void handleNext() {
    if (selectedPieces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 조각을 선택해주세요!')));
      return;
    }

    Navigator.pushNamed(
      context,
      '/collaborative-create-diary',
      arguments: {
        'date': widget.date,
        'friendIds': widget.friendIds,
        'selectedPieces': selectedPieces,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                '조각 선택',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '날짜: ${widget.date}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '친구 ID: ${widget.friendIds.join(', ')}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    allPieces.isEmpty
                        ? Center(
                          child: Text(
                            error ?? '${widget.date}에 나와 친구가 생성한 조각이 없습니다.',
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                        : GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(16),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children:
                              allPieces.map((piece) {
                                final isSelected = selectedPieces.any(
                                  (p) => p['id'] == piece['id'],
                                );
                                return GestureDetector(
                                  onTap: () => togglePiece(piece),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          isSelected
                                              ? Border.all(
                                                color: const Color(0xFFD6B896),
                                                width: 4,
                                              )
                                              : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          piece['type'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Center(
                                            child:
                                                piece['type'] == 'TEXT'
                                                    ? Text(
                                                      piece['text'] ?? '내용 없음',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                    : const Icon(
                                                      Icons.insert_drive_file,
                                                      color: Colors.white54,
                                                      size: 48,
                                                    ),
                                          ),
                                        ),
                                        if (piece['tags'] != null)
                                          Text(
                                            '태그: ${piece['tags'].join(', ')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        Text(
                                          DateFormat('yyyy-MM-dd').format(
                                            DateTime.parse(piece['createdAt']),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                        Text(
                                          '작성자: ${piece['userId'] == 'user' ? '나' : '친구'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6B896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
