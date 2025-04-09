import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';
import '../diary/widgets/diary_canvas.dart'; // DiaryCanvas 경로에 맞게 조정

class NewAlbumPageScreen extends StatefulWidget {
  const NewAlbumPageScreen({super.key});

  @override
  State<NewAlbumPageScreen> createState() => _NewAlbumPageScreenState();
}

class _NewAlbumPageScreenState extends State<NewAlbumPageScreen> {
  final TextEditingController _titleController = TextEditingController();
  List<dynamic> diaries = [];
  List<String> selectedDiaries = [];

  int currentPage = 0;
  final int itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _fetchDiaries();
  }

  Future<void> _fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/diaries',
      queryParameters: {'userId': userId, 'includeElements': true},
    );

    if (res.statusCode == 200 && res.data['success']) {
      final diariesData = res.data['data']['diaries'] as List<dynamic>;
      final filteredDiaries =
          diariesData
              .where((d) => d['openAt'] == null || d['openAt'] == '')
              .toList();
      setState(() => diaries = filteredDiaries);
    }
  }

  void _handleCheckboxChange(String diaryId) {
    setState(() {
      if (selectedDiaries.contains(diaryId)) {
        selectedDiaries.remove(diaryId);
      } else if (selectedDiaries.length < 5) {
        selectedDiaries.add(diaryId);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('최대 5개의 일기만 선택할 수 있습니다.')));
      }
    });
  }

  Future<void> _handleCreateAlbum() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범 제목을 입력하세요.')));
      return;
    }
    if (selectedDiaries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('적어도 하나의 일기를 선택해야 합니다.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final dio = Dio();
    final res = await dio.post(
      'https://api.puzzlelog.me/albums',
      data: {
        'userId': userId,
        'title': _titleController.text.trim(),
        'diaryId': selectedDiaries,
        'purchased': false,
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    if (res.statusCode == 200 && res.data['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범이 성공적으로 생성되었습니다.')));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범 생성 중 오류가 발생했습니다.')));
    }
  }

  void changePage(int offset) {
    setState(() => currentPage += offset);
  }

  @override
  Widget build(BuildContext context) {
    final paginatedDiaries =
        diaries.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return CommonScaffold(
      currentIndex: -1,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '새 디지털 앨범 만들기',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '앨범 제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: paginatedDiaries.length,
                itemBuilder: (_, index) {
                  final diary = paginatedDiaries[index];
                  final diaryId = diary['diaryId'];
                  final elements = List<Map<String, dynamic>>.from(
                    diary['elements'] ?? [],
                  );
                  final bgUrl = diary['background']?['mediaId'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text(diary['title'] ?? '제목 없음'),
                          value: selectedDiaries.contains(diaryId),
                          onChanged: (_) => _handleCheckboxChange(diaryId),
                        ),
                        AspectRatio(
                          aspectRatio: 1,
                          child: DiaryCanvas(
                            elements: elements,
                            backgroundUrl: bgUrl,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage == 0 ? null : () => changePage(-1),
                  child: const Text('이전'),
                ),
                ElevatedButton(
                  onPressed:
                      (currentPage + 1) * itemsPerPage >= diaries.length
                          ? null
                          : () => changePage(1),
                  child: const Text('다음'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _handleCreateAlbum,
                  child: const Text('앨범 만들기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
