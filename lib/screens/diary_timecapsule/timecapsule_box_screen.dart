import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/common_scaffold.dart';

class TimecapsuleBoxScreen extends StatefulWidget {
  const TimecapsuleBoxScreen({super.key});

  @override
  State<TimecapsuleBoxScreen> createState() => _TimecapsuleBoxScreenState();
}

class _TimecapsuleBoxScreenState extends State<TimecapsuleBoxScreen> {
  List<dynamic> timeCapsules = [];

  @override
  void initState() {
    super.initState();
    loadTimeCapsules();
  }

  Future<void> loadTimeCapsules() async {
    final prefs = await SharedPreferences.getInstance();
    final capsulesJson = prefs.getString('timeCapsules') ?? '[]';

    setState(() {
      timeCapsules = json.decode(capsulesJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFF7F3E5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
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
            const SizedBox(height: 20),
            Expanded(
              child: timeCapsules.isEmpty
                  ? const Center(
                      child: Text(
                        '저장된 타임캡슐이 없습니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: timeCapsules.length,
                      itemBuilder: (context, index) {
                        final capsule = timeCapsules[index];
                        return Card(
                          color: const Color(0xFFEADDC5),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  capsule['openDate'] ?? '날짜 없음',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  capsule['message'] ?? '내용 없음',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
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
      ),
    );
  }
}
