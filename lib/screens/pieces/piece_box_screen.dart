import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  final int itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    fetchPieces();
  }

  Future<void> fetchPieces() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        error = '로그인이 필요합니다.';
        loading = false;
      });
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse(
      'https://api.puzzlelog.me/pieces?userId=$userId&isDeleted=false&page=0&size=100',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          pieces =
              data['data']['pieces']
                  .where((piece) => !piece['isDeleted'])
                  .toList();
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

    if (!confirmed) return;

    final response = await http.delete(
      Uri.parse('https://api.puzzlelog.me/pieces/$pieceId'),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      setState(() {
        pieces.removeWhere((piece) => piece['id'] == pieceId);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'] ?? '삭제 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPieces =
        filterType == "ALL"
            ? pieces
            : pieces.where((piece) => piece['type'] == filterType).toList();

    final totalPages = (filteredPieces.length / itemsPerPage).ceil();
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    final paginatedPieces = filteredPieces.sublist(
      start,
      end > filteredPieces.length ? filteredPieces.length : end,
    );

    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text("오류: $error"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      children:
                          ["ALL", "TEXT", "IMAGE", "VIDEO", "AUDIO"]
                              .map(
                                (type) => ChoiceChip(
                                  label: Text(type == "ALL" ? "전체 보기" : type),
                                  selected: filterType == type,
                                  onSelected: (_) {
                                    setState(() {
                                      filterType = type;
                                      currentPage = 1;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                    paginatedPieces.isEmpty
                        ? const Text('조각이 없습니다.')
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                          itemCount: paginatedPieces.length,
                          itemBuilder: (context, index) {
                            final piece = paginatedPieces[index];
                            return Card(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      piece['type'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(child: pieceWidget(piece)),
                                  ),
                                  if (piece['tags'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        '태그: ${piece['tags'].join(", ")}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      DateTime.parse(
                                        piece['createdAt'],
                                      ).toLocal().toString().split(' ')[0],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[300],
                                    ),
                                    onPressed: () => handleDelete(piece['id']),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    const SizedBox(height: 20),
                    if (totalPages > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                currentPage == 1
                                    ? null
                                    : () {
                                      setState(() => currentPage--);
                                    },
                            child: const Text('이전'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("$currentPage / $totalPages"),
                          ),
                          ElevatedButton(
                            onPressed:
                                currentPage == totalPages
                                    ? null
                                    : () {
                                      setState(() => currentPage++);
                                    },
                            child: const Text('다음'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }

  Widget pieceWidget(dynamic piece) {
    switch (piece['type']) {
      case 'TEXT':
        return Text(
          piece['content'],
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      case 'IMAGE':
        return Image.network(piece['mediaId'], fit: BoxFit.cover);
      case 'VIDEO':
        return const Icon(Icons.videocam, size: 50); // 실제 비디오 재생 필요시 추가
      case 'AUDIO':
        return const Icon(Icons.audiotrack, size: 50); // 실제 오디오 재생 필요시 추가
      default:
        return const SizedBox();
    }
  }
}
