import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_scaffold.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();

  Map<String, String> emotions = {};

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
    List<DateTime> calendarDays = [];

    // 월의 첫 번째 날짜 (예: 2025년 4월 1일)
    final firstDayOfMonth = DateTime(month.year, month.month, 1);

    // 첫 번째 날짜가 속한 주의 첫 날짜(일요일) 구하기
    final startDay = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );

    // 6주(6*7=42일)를 표시하여 달력의 모든 날짜를 채움
    for (int i = 0; i < 42; i++) {
      calendarDays.add(startDay.add(Duration(days: i)));
    }

    return calendarDays;
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> days = generateCalendarDays(selectedDate);

    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Column(
        children: [
          // 월 선택 헤더
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

          // 요일 헤더
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
                        (weekday) => Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              weekday,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    weekday == '일' ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // 날짜 그리드
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.57, // 이 값을 조정하여 세로 공간을 꽉 채웁니다.
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final key = DateFormat('yyyy-MM-dd').format(day);
                final bool isCurrentMonth = day.month == selectedDate.month;

                return Container(
                  decoration: BoxDecoration(
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
                                  : IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      // 이모션 추가 로직을 여기에 추가
                                    },
                                  ),
                        ),
                      ),
                    ],
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
