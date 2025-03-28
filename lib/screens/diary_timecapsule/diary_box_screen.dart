import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';
import 'diary_detail_screen.dart';

class DiaryBoxScreen extends StatefulWidget {
  const DiaryBoxScreen({super.key});

  @override
  State<DiaryBoxScreen> createState() => _DiaryBoxScreenState();
}

class _DiaryBoxScreenState extends State<DiaryBoxScreen> {
  List<dynamic> diaryEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.puzzlelog.me/diaries',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          diaryEntries = response.data['data']['diaries'] as List<dynamic>;
          isLoading = false;
        });
      } else {
        throw Exception('데이터 로딩 실패');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          diaryEntries = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : diaryEntries.isNotEmpty
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        '일기 모음집',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4F35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: diaryEntries.length,
                        itemBuilder: (context, index) {
                          final entry = diaryEntries[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => DiaryDetailScreen(
                                        diaryId: entry['diaryId'],
                                      ),
                                ),
                              );
                            },
                            child: Card(
                              color: const Color(0xFFEADDC5),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      entry['title'] ?? '제목 없음',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '작성일: ${DateTime.parse(entry['createdAt']).toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
                : const Center(
                  child: Text(
                    '저장된 일기가 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
      ),
    );
  }
}
