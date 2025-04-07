import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class TimecapsuleBoxScreen extends StatefulWidget {
  const TimecapsuleBoxScreen({super.key});

  @override
  State<TimecapsuleBoxScreen> createState() => _TimecapsuleBoxScreenState();
}

class _TimecapsuleBoxScreenState extends State<TimecapsuleBoxScreen> {
  List<dynamic> timeCapsules = [];
  Map<String, dynamic>? selectedDiary;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTimeCapsules();
  }

  Future<void> fetchTimeCapsules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('accessToken') ?? '';

      final dio = Dio();
      final res = await dio.get(
        'https://api.puzzlelog.me/diaries',
        queryParameters: {'userId': userId, 'includeElements': true},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (res.statusCode == 200 && res.data['success']) {
        final allDiaries = res.data['data']['diaries'] ?? [];
        final onlyTimeCapsules =
            allDiaries.where((d) {
              final openAt = d['openAt'];
              final participants = d['participants'] ?? [];
              return openAt != null &&
                  (participants is List && participants.length <= 1);
            }).toList();

        setState(() {
          timeCapsules = onlyTimeCapsules;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('타임캡슐 불러오기 실패: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        '타임캡슐 모음집',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4F35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          timeCapsules.isEmpty
                              ? const Center(
                                child: Text(
                                  '저장된 타임캡슐이 없습니다.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: ListView.separated(
                                      itemCount: timeCapsules.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final diary = timeCapsules[index];
                                        final openDate = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(
                                          DateTime.parse(diary['openAt']),
                                        );
                                        return ListTile(
                                          tileColor: Colors.brown.shade100
                                              .withOpacity(0.3),
                                          title: Text(
                                            diary['title'] ?? '제목 없음',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '열리는 날짜: $openDate',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                          ),
                                          onTap:
                                              () => setState(
                                                () => selectedDiary = diary,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 6,
                                    child:
                                        selectedDiary == null
                                            ? const Center(
                                              child: Text(
                                                '타임캡슐을 선택해주세요.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            )
                                            : buildPreview(selectedDiary!),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget buildPreview(Map<String, dynamic> diary) {
    final openAt = DateTime.tryParse(diary['openAt'] ?? '');
    final now = DateTime.now();
    final isLocked = openAt != null && openAt.isAfter(now);

    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child:
          isLocked
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    '${DateFormat('yyyy-MM-dd').format(openAt)} 에 열립니다.',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              )
              : const Center(
                child: Text(
                  '📖 타임캡슐 열람 가능 (캔버스 영역)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
    );
  }
}
