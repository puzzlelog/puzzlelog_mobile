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
    final userId = prefs.getString('userId') ?? 'guest';

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/api/albums',
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
    final res = await dio.delete('https://api.puzzlelog.me/api/albums/$id');

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        albums.removeWhere((album) => album['_id'] == id);
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
      currentIndex: 0,
      onTap: (_) {},
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '나만의 디지털 앨범',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child:
                albums.isEmpty
                    ? const Center(child: Text('앨범이 없습니다.'))
                    : ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (context, idx) {
                        final album = albums[idx];
                        return ListTile(
                          title: Text(album['title']),
                          subtitle: Text('생성일: ${album['createdAt']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => handleDelete(album['_id']),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/albumDetail',
                              arguments: {'albumId': album['_id']},
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
