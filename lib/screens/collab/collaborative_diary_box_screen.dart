import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';

class CollaborativeDiaryBoxScreen extends StatefulWidget {
  const CollaborativeDiaryBoxScreen({super.key});

  @override
  State<CollaborativeDiaryBoxScreen> createState() =>
      _CollaborativeDiaryBoxScreenState();
}

class _CollaborativeDiaryBoxScreenState
    extends State<CollaborativeDiaryBoxScreen> {
  List diaries = [];
  int currentPage = 0;
  int pageSize = 9;
  bool loading = true;
  String? error;
  Map<String, dynamic>? selectedDiary;

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    try {
      setState(() => loading = true);

      final dio = Dio();
      final token = 'test-token';
      final userId = 'user';

      final res = await dio.get(
        'https://api.puzzlelog.me/diaries?includeElements=true',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final all = res.data['data']['diaries'] ?? res.data['diaries'] ?? [];
      final filtered =
          all.where((d) {
            final participants = d['participants'];
            return participants != null &&
                participants.length > 1 &&
                participants.contains(userId);
          }).toList();

      setState(() {
        diaries = filtered;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '협업 일기 데이터를 불러오는 데 실패했습니다.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginated =
        diaries.skip(currentPage * pageSize).take(pageSize).toList();
    final totalPages = (diaries.length / pageSize).ceil();

    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          paginated.isEmpty
                              ? const Center(
                                child: Text(
                                  '참여한 협업 일기가 없습니다.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                              : Expanded(
                                child: ListView.builder(
                                  itemCount: paginated.length,
                                  itemBuilder: (context, index) {
                                    final diary = paginated[index];
                                    return Card(
                                      color: Colors.white.withOpacity(0.3),
                                      elevation: 4,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        onTap:
                                            () => setState(
                                              () => selectedDiary = diary,
                                            ),
                                        title: Text(
                                          diary['title'] ?? '제목 없음',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat('yyyy-MM-dd').format(
                                            DateTime.parse(diary['createdAt']),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          if (totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      currentPage > 0
                                          ? () => setState(() => currentPage--)
                                          : null,
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                  ),
                                ),
                                ...List.generate(totalPages, (index) {
                                  final isActive = index == currentPage;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          () => setState(
                                            () => currentPage = index,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isActive
                                                ? const Color(0xFF6B4F35)
                                                : Colors.white.withOpacity(0.3),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('${index + 1}'),
                                    ),
                                  );
                                }),
                                IconButton(
                                  onPressed:
                                      currentPage < totalPages - 1
                                          ? () => setState(() => currentPage++)
                                          : null,
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 800,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            selectedDiary != null
                                ? const Center(
                                  child: Text(
                                    'FabricCanvasViewer 대체 위젯 들어올 자리',
                                  ),
                                )
                                : const Center(
                                  child: Text(
                                    '협업일기를 선택해주세요.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
