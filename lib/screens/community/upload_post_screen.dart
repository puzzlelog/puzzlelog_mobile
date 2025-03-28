import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/api/getDiary',
      queryParameters: {'userId': userId},
    );

    if (res.statusCode == 200 && res.data is List) {
      setState(() {
        diaries = res.data;
      });
    }
  }

  void handleUpload() async {
    if (selectedDiary == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일기를 선택해주세요.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';

    final dio = Dio();
    final res = await dio.post(
      'https://api.puzzlelog.me/api/posts',
      data: {
        'userId': userId,
        'content': selectedDiary!['content'],
        'title': selectedDiary!['title'],
      },
    );

    if (res.statusCode == 200 && res.data['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 성공적으로 업로드되었습니다.')));
      Navigator.pushReplacementNamed(context, '/postList');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글 업로드에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '모든 일기 목록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  diaries.isEmpty
                      ? const Center(child: Text('작성된 일기가 없습니다.'))
                      : ListView.builder(
                        itemCount: diaries.length,
                        itemBuilder: (_, index) {
                          final diary = diaries[index];
                          return RadioListTile(
                            title: Text(diary['title'] ?? '제목 없음'),
                            value: diary,
                            groupValue: selectedDiary,
                            onChanged: (value) {
                              setState(() => selectedDiary = value);
                            },
                          );
                        },
                      ),
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
