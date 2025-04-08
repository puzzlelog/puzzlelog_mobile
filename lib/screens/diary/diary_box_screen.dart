// Updated DiaryBoxScreen styled like PieceBoxScreen
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_scaffold.dart';

class DiaryBoxScreen extends StatefulWidget {
  const DiaryBoxScreen({super.key});

  @override
  State<DiaryBoxScreen> createState() => _DiaryBoxScreenState();
}

class _DiaryBoxScreenState extends State<DiaryBoxScreen> {
  List<dynamic> diaries = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  final int itemsPerPage = 10;
  String filterType = 'ALL';

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.puzzlelog.me/diaries',
        queryParameters: {
          'userId': userId,
          'page': currentPage - 1,
          'size': itemsPerPage,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List data = response.data['data']['diaries'];
        final int total =
            response.data['data']['pagination']['totalPages'] ?? 1;
        setState(() {
          diaries = data;
          totalPages = total;
          isLoading = false;
        });
      } else {
        throw Exception('데이터 로딩 실패');
      }
    } catch (e) {
      setState(() {
        diaries = [];
        isLoading = false;
      });
    }
  }

  List<dynamic> filteredDiaries() {
    return diaries.where((entry) {
      if (filterType == 'ALL') return true;
      final participants = entry['participants'];
      final openAt = entry['openAt'];
      if (filterType == 'COLLAB')
        return participants is List && participants.length > 1;
      if (filterType == 'TIME')
        return openAt != null && openAt.toString().isNotEmpty;
      if (filterType == 'NORMAL') {
        return (participants is! List || participants.length <= 1) &&
            (openAt == null || openAt.toString().isEmpty);
      }
      return true;
    }).toList();
  }

  String classifyDiary(Map entry) {
    final participants = entry['participants'];
    final openAt = entry['openAt'];
    if (participants is List && participants.length > 1) return '협업 일기';
    if (openAt != null && openAt.toString().isNotEmpty) return '타임캡슐';
    return '일반 일기';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredDiaries();

    return CommonScaffold(
      currentIndex: 1,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              '일기 모음집',
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
                                [
                                  {'key': 'ALL', 'label': '전체 보기'},
                                  {'key': 'NORMAL', 'label': '일반 일기'},
                                  {'key': 'TIME', 'label': '타임캡슐 일기'},
                                  {'key': 'COLLAB', 'label': '협업 일기'},
                                ].map((type) {
                                  return ChoiceChip(
                                    label: Text(type['label']!),
                                    selected: filterType == type['key'],
                                    onSelected: (_) {
                                      setState(() {
                                        filterType = type['key']!;
                                        currentPage = 1;
                                      });
                                      fetchDiaries();
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 12),
                          filtered.isEmpty
                              ? const Center(child: Text('일기가 없습니다.'))
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
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final diary = filtered[index];
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
                                                classifyDiary(diary),
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
                                                onPressed: () async {
                                                  final confirm = await showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => AlertDialog(
                                                          title: const Text(
                                                            '삭제 확인',
                                                          ),
                                                          content: const Text(
                                                            '정말로 삭제하시겠습니까?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                              child: const Text(
                                                                '취소',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                              child: const Text(
                                                                '삭제',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );

                                                  if (confirm != true) return;

                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  final token =
                                                      prefs.getString(
                                                        'accessToken',
                                                      ) ??
                                                      '';

                                                  final dio = Dio();
                                                  final res = await dio.delete(
                                                    'https://api.puzzlelog.me/diaries/${diary['diaryId']}',
                                                    options: Options(
                                                      headers: {
                                                        'Authorization':
                                                            'Bearer $token',
                                                      },
                                                    ),
                                                  );

                                                  if (res.statusCode == 200 &&
                                                      res.data['success']) {
                                                    fetchDiaries();
                                                  } else {
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          res.data['message'] ??
                                                              '삭제 실패',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                diary['title'] ?? '',
                                                maxLines: 5,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse(
                                                diary['createdAt'],
                                              ),
                                            ),
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
                                            fetchDiaries();
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
                                            fetchDiaries();
                                          });
                                        },
                                child: const Text('다음'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
}
