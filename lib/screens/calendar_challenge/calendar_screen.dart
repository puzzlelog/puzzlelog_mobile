import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';
import '../diary/widgets/diary_preview_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, String> emotions = {};

  @override
  void initState() {
    super.initState();
    fetchEmotions();
  }

  Future<void> fetchEmotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final token = prefs.getString('accessToken');

      if (userId == null || token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final dio = Dio();

      final res = await dio.get(
        'https://api.puzzlelog.me/diaries?userId=$userId&includeElements=true',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final List diaries =
          res.data['data']['diaries'] ?? res.data['diaries'] ?? [];

      final Map<String, dynamic> newestByDate = {};
      for (var diary in diaries) {
        final createdAt = diary['createdAt'];
        if (createdAt == null) continue;
        final dateKey = createdAt.split('T')[0];
        if (!newestByDate.containsKey(dateKey) ||
            DateTime.parse(
              createdAt,
            ).isAfter(DateTime.parse(newestByDate[dateKey]['createdAt']))) {
          newestByDate[dateKey] = diary;
        }
      }

      final Map<String, String> emotionMap = {};
      for (var entry in newestByDate.entries) {
        final date = entry.key;
        final diary = entry.value;

        final mediaUrl = diary['emotion']?['mediaId'];
        if (mediaUrl != null) {
          emotionMap[date] = mediaUrl;
        } else if (diary['emotionContentId'] != null) {
          try {
            final assetRes = await dio.get(
              'https://api.puzzlelog.me/assets/${diary['emotionContentId']}',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            final media = assetRes.data['data']?['mediaId'];
            if (media != null) {
              emotionMap[date] = media;
            }
          } catch (_) {}
        }
      }

      setState(() => emotions = emotionMap);
    } catch (e) {
      debugPrint('감정 이모지 불러오기 실패: $e');
    }
  }

  Future<List<dynamic>> fetchDiariesForSelectedDate(String selectedDate) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return [];
    }

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/diaries?userId=$userId&date=$selectedDate',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return res.data['data']['diaries'] ?? [];
  }

  void handlePrevMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void handleNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  List<DateTime> generateCalendarDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final startDay = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );
    return List.generate(42, (i) => startDay.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> days = generateCalendarDays(selectedDate);

    return CommonScaffold(
      currentIndex: 3,
      body: Column(
        children: [
          // 🔥 월 선택 및 표시 부분 (기존 유지)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: handlePrevMonth,
                ),
                Text(
                  DateFormat('yyyy년 M월').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: handleNextMonth,
                ),
              ],
            ),
          ),

          // 🔥 요일 표시 부분 (추가해야 하는 부분!)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade400),
                bottom: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            child: Row(
              children:
                  ['일', '월', '화', '수', '목', '금', '토']
                      .map(
                        (day) => Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: day == '일' ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // 🔥 달력 본문 (기존 유지)
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.57,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final key = DateFormat('yyyy-MM-dd').format(day);
                final isCurrentMonth = day.month == selectedDate.month;
                final today = DateTime.now();
                final isToday =
                    day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                return GestureDetector(
                  onTap: () async {
                    final selectedDateStr = DateFormat(
                      'yyyy-MM-dd',
                    ).format(day);
                    final diariesOnSelectedDate =
                        await fetchDiariesForSelectedDate(selectedDateStr);

                    if (diariesOnSelectedDate.isEmpty) return;

                    if (diariesOnSelectedDate.length == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder:
                              (_) => DiaryPreviewScreen(
                                diaryId: diariesOnSelectedDate.first['diaryId'],
                              ),
                        ),
                      );
                    } else {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (_) => ListView(
                              shrinkWrap: true,
                              children:
                                  diariesOnSelectedDate
                                      .map(
                                        (diary) => ListTile(
                                          title: Text(
                                            diary['title'] ?? '제목 없음',
                                          ),
                                          subtitle: Text(
                                            DateFormat('HH:mm').format(
                                              DateTime.parse(
                                                diary['createdAt'],
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                fullscreenDialog: true,
                                                builder:
                                                    (_) => DiaryPreviewScreen(
                                                      diaryId: diary['diaryId'],
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                      );
                    }
                  },

                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isToday
                              ? Colors.grey.shade300.withOpacity(0.4)
                              : null,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentMonth ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Center(
                            child:
                                emotions[key] != null
                                    ? Image.network(
                                      emotions[key]!,
                                      width: 24,
                                      height: 24,
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
