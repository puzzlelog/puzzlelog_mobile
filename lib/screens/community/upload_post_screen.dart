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
  int currentPage = 1; // (1부터 시작)
  final int itemsPerPage = 8;

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
    final totalPages = (diaries.length / itemsPerPage).ceil();
    final paginatedDiaries =
        diaries
            .skip((currentPage - 1) * itemsPerPage)
            .take(itemsPerPage)
            .toList();

    return CommonScaffold(
      currentIndex: 2,
      body: Container(
        color: const Color(0xFFFAF5FF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '공유할 일기 선택',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    paginatedDiaries.isEmpty
                        ? const Center(child: Text('작성된 일기가 없습니다.'))
                        : ListView.builder(
                          itemCount: paginatedDiaries.length,
                          itemBuilder: (_, index) {
                            final diary = paginatedDiaries[index];
                            final isSelected = diary == selectedDiary;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: RadioListTile(
                                activeColor: Colors.deepPurple,
                                title: Text(
                                  diary['title'] ?? '제목 없음',
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.deepPurple
                                            : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.parse(diary['createdAt'])),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                value: diary,
                                groupValue: selectedDiary,
                                onChanged:
                                    (value) =>
                                        setState(() => selectedDiary = value),
                              ),
                            );
                          },
                        ),
              ),
              const SizedBox(height: 12),
              if (totalPages > 1) _paginationControls(totalPages),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7E57C2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  '게시글 업로드',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '뒤로 가기',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.deepPurple),
          onPressed:
              currentPage > 1 ? () => setState(() => currentPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: const TextStyle(color: Colors.deepPurple),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.deepPurple),
          onPressed:
              currentPage < totalPages
                  ? () => setState(() => currentPage++)
                  : null,
        ),
      ],
    );
  }
}
