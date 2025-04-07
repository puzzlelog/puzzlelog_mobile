import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Map<String, dynamic>? album;
  List<dynamic> diaries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
  }

  Future<void> fetchAlbumDetails() async {
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://api.puzzlelog.me/albums/${widget.albumId}',
      );
      if (res.statusCode == 200) {
        final data = res.data['data'];
        setState(() {
          album = data;
        });

        if (data['diaryId'] != null && data['diaryId'].isNotEmpty) {
          final futures = data['diaryId'].map<Future>((id) async {
            final response = await dio.get(
              'https://api.puzzlelog.me/diaries/$id?includeElements=true',
            );
            return response.data['data'];
          });
          final result = await Future.wait(futures);
          setState(() {
            diaries = result;
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> deleteAlbum() async {
    try {
      final dio = Dio();
      final res = await dio.delete(
        'https://api.puzzlelog.me/albums/${widget.albumId}',
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('앨범이 삭제되었습니다.')));
          Navigator.pop(context);
        }
      } else {
        throw Exception('삭제 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범 삭제에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 2,
      appBar: AppBar(title: const Text('앨범 상세')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : album == null
              ? const Center(child: Text('앨범을 찾을 수 없습니다.'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      album!['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'yyyy년 MM월 dd일 HH:mm',
                      ).format(DateTime.parse(album!['createdAt'])),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child:
                          diaries.isNotEmpty
                              ? ListView.builder(
                                itemCount: diaries.length,
                                itemBuilder: (_, index) {
                                  final diary = diaries[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      title: Text('일기 ID: ${diary['diaryId']}'),
                                      subtitle: Text(diary['title'] ?? ''),
                                      onTap: () {
                                        // 향후 상세보기 가능
                                      },
                                    ),
                                  );
                                },
                              )
                              : const Center(
                                child: Text('이 앨범에 저장된 일기가 없습니다.'),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('뒤로 가기'),
                        ),
                        ElevatedButton(
                          onPressed: deleteAlbum,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            '앨범 삭제',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
