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
  Map<String, String> emotions = {}; // 날짜별 이미지 경로 저장

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

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weeks = <List<int?>>[];

    int weekDayOffset = firstDayOfMonth.weekday % 7;

    for (var i = 0; i < weekDayOffset; i++) {
      weeks.add([null]);
    }

    List<int?> days = [];
    for (var day = 1; day <= daysInMonth; day++) {
      days.add(day);
    }

    weeks.clear();
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }

    return CommonScaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: handlePrevMonth, icon: const Icon(Icons.arrow_back_ios)),
              Text(DateFormat('yyyy년 MM월').format(selectedDate),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: handleNextMonth, icon: const Icon(Icons.arrow_forward_ios)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((e) => Expanded(child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))))
                .toList(),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final key = '${selectedDate.year}-${selectedDate.month}-$day';

                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day != null ? '$day' : ''),
                        if (day != null && emotions[key] != null)
                          Image.network(emotions[key]!, width: 24, height: 24)
                        else if (day != null)
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              // 이미지 추가 로직
                            },
                          )
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