import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';
import 'package:intl/intl.dart';

class PieceBoxMakeDiaryScreen extends StatefulWidget {
  final bool isTimeCapsule;
  const PieceBoxMakeDiaryScreen({super.key, this.isTimeCapsule = false});

  @override
  State<PieceBoxMakeDiaryScreen> createState() =>
      _PieceBoxMakeDiaryScreenState();
}

class _PieceBoxMakeDiaryScreenState extends State<PieceBoxMakeDiaryScreen> {
  List<dynamic> pieces = [];
  List<dynamic> selectedPieces = [];
  bool isLoading = false;
  String? openAt;
  String? filterDate;

  @override
  void initState() {
    super.initState();
    fetchPieces();
  }

  Future<void> fetchPieces() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('accessToken') ?? '';

      final dio = Dio();
      final response = await dio.get(
        'https://api.puzzlelog.me/pieces',
        queryParameters: {'userId': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        setState(() {
          pieces = data is List ? data : data['pieces'] ?? [];
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

  bool isPieceSelected(dynamic piece) =>
      selectedPieces.any((p) => p['id'] == piece['id']);

  void navigateToDiary() {
    if (selectedPieces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개의 조각을 선택해주세요!')));
      return;
    }
    if (widget.isTimeCapsule && (openAt == null || openAt!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오픈 날짜를 선택해주세요!')));
      return;
    }
    Navigator.pushNamed(
      context,
      '/makeDiary',
      arguments: {
        'selectedPieces': selectedPieces,
        'isTimeCapsule': widget.isTimeCapsule,
        'openAt': openAt,
      },
    );
  }

  List get filteredPieces {
    if (filterDate == null || filterDate!.isEmpty) return pieces;
    return pieces.where((piece) {
      final created =
          DateTime.tryParse(
            piece['createdAt'] ?? '',
          )?.toIso8601String().split('T').first;
      return created == filterDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '조각 모음집',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '날짜 필터',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(
                          () =>
                              filterDate = DateFormat(
                                'yyyy-MM-dd',
                              ).format(picked),
                        );
                      }
                    },
                    controller: TextEditingController(text: filterDate),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(() => filterDate = null),
                  child: const Text('필터 초기화'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPieces.isEmpty
                      ? const Center(child: Text('조각이 없습니다.'))
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: filteredPieces.length,
                        itemBuilder: (_, idx) {
                          final piece = filteredPieces[idx];
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
            if (widget.isTimeCapsule) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '오픈할 날짜/시간 선택',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(
                      () => openAt = DateFormat('yyyy-MM-dd').format(picked),
                    );
                  }
                },
                controller: TextEditingController(text: openAt ?? ''),
              ),
            ],
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
            piece['text'] ?? '',
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
