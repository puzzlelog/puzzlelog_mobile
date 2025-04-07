import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class UploadPostScreen extends StatefulWidget {
  const UploadPostScreen({super.key});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  List diaries = [];
  Map<String, dynamic>? selectedDiary;
  int currentPage = 0;
  final int pageSize = 8;

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';
    final token = prefs.getString('accessToken') ?? '';

    try {
      final res = await Dio().get(
        'https://api.puzzlelog.me/diaries',
        queryParameters: {'userId': userId, 'includeElements': true},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (res.statusCode == 200) {
        final List data = res.data['data']['diaries'] ?? [];
        final filtered =
            data
                .where((d) => d['openAt'] == null || d['openAt'] == '')
                .toList();
        for (var diary in filtered) {
          diary['elements'] ??= [];
        }
        setState(() => diaries = filtered);
      }
    } catch (e) {
      debugPrint('일기 불러오기 실패: $e');
    }
  }

  void handleUpload() async {
    if (selectedDiary == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유할 일기를 선택해주세요.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';

    try {
      final res = await Dio().post(
        'https://api.puzzlelog.me/posts',
        data: {
          'userId': userId,
          'diaryId': selectedDiary!['diaryId'],
          'title': selectedDiary!['title'] ?? '제목 없음',
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 성공적으로 업로드되었습니다.')));
        Navigator.pushReplacementNamed(context, '/postList');
      } else {
        throw Exception('업로드 실패');
      }
    } catch (e) {
      debugPrint('업로드 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글 업로드에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (diaries.length / pageSize).ceil();
    final paginated =
        diaries.skip(currentPage * pageSize).take(pageSize).toList();

    return CommonScaffold(
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공유할 일기 선택',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  paginated.isEmpty
                      ? const Center(child: Text('작성된 일기가 없습니다.'))
                      : ListView.builder(
                        itemCount: paginated.length,
                        itemBuilder: (_, index) {
                          final diary = paginated[index];
                          return RadioListTile(
                            title: Text(diary['title'] ?? '제목 없음'),
                            subtitle: Text(
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.parse(diary['createdAt'])),
                            ),
                            value: diary,
                            groupValue: selectedDiary,
                            onChanged:
                                (value) =>
                                    setState(() => selectedDiary = value),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        currentPage > 0
                            ? () => setState(() => currentPage--)
                            : null,
                  ),
                  for (int i = 0; i < totalPages; i++)
                    TextButton(
                      onPressed: () => setState(() => currentPage = i),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight:
                              currentPage == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        currentPage < totalPages - 1
                            ? () => setState(() => currentPage++)
                            : null,
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: handleUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text(
                '게시글 업로드',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('뒤로 가기', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
