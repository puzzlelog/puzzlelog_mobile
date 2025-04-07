import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class DigitalAlbumListScreen extends StatefulWidget {
  const DigitalAlbumListScreen({super.key});

  @override
  State<DigitalAlbumListScreen> createState() => _DigitalAlbumListScreenState();
}

class _DigitalAlbumListScreenState extends State<DigitalAlbumListScreen> {
  List<dynamic> albums = [];

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/albums',
      queryParameters: {'userId': userId},
    );

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        albums = res.data['data'];
      });
    }
  }

  Future<void> handleDelete(String id) async {
    final dio = Dio();
    final res = await dio.delete('https://api.puzzlelog.me/albums/$id');

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        albums.removeWhere((album) => album['id'] == id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('앨범이 삭제되었습니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '나만의 디지털 앨범',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/albumNew'),
                  child: const Text('새 앨범 만들기'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                albums.isEmpty
                    ? const Center(child: Text('앨범이 없습니다.'))
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3 / 2,
                          ),
                      itemCount: albums.length,
                      itemBuilder: (context, idx) {
                        final album = albums[idx];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        album['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => handleDelete(album['id']),
                                    ),
                                  ],
                                ),
                                Text(
                                  '생성일: ${DateTime.parse(album['createdAt']).toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('상세 보기'),
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/albumDetail',
                                          arguments: {'albumId': album['id']},
                                        ),
                                  ),
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
    );
  }
}
