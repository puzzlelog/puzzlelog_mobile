import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';

class NewAlbumPageScreen extends StatefulWidget {
  const NewAlbumPageScreen({super.key});

  @override
  State<NewAlbumPageScreen> createState() => _NewAlbumPageScreenState();
}

class _NewAlbumPageScreenState extends State<NewAlbumPageScreen> {
  final TextEditingController _titleController = TextEditingController();
  List<dynamic> diaries = [];
  List<String> selectedDiaries = [];

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
      'https://api.puzzlelog.me/api/getDiary',
      queryParameters: {'userId': userId},
    );

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        diaries = res.data['data'];
      });
    }
  }

  void _handleCreateAlbum() async {
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

    final newAlbum = {
      'userId': userId,
      'title': _titleController.text.trim(),
      'diaryId': selectedDiaries,
      'purchased': false,
    };

    final dio = Dio();
    final res = await dio.post(
      'https://api.puzzlelog.me/api/albums',
      data: newAlbum,
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

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
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
              child: ListView(
                children:
                    diaries
                        .map(
                          (diary) => CheckboxListTile(
                            title: Text(diary['title']),
                            value: selectedDiaries.contains(diary['id']),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedDiaries.add(diary['id']);
                                } else {
                                  selectedDiaries.remove(diary['id']);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
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
