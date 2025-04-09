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
  List<dynamic> allAlbums = [];
  List<dynamic> pagedAlbums = [];
  int currentPage = 1;
  int totalPages = 1;
  final int itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) return;

    final dio = Dio();
    final res = await dio.get(
      'https://api.puzzlelog.me/albums',
      queryParameters: {'userId': userId},
    );

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        allAlbums = res.data['data'];
        totalPages = (allAlbums.length / itemsPerPage).ceil();
        updatePage();
      });
    }
  }

  void updatePage() {
    final start = (currentPage - 1) * itemsPerPage;
    final end =
        (start + itemsPerPage > allAlbums.length)
            ? allAlbums.length
            : start + itemsPerPage;
    pagedAlbums = allAlbums.sublist(start, end);
  }

  Future<void> handleDelete(String id) async {
    final dio = Dio();
    final res = await dio.delete('https://api.puzzlelog.me/albums/$id');

    if (res.statusCode == 200 && res.data['success']) {
      setState(() {
        allAlbums.removeWhere((album) => album['id'] == id);
        totalPages = (allAlbums.length / itemsPerPage).ceil();
        if (currentPage > totalPages) currentPage = totalPages;
        updatePage();
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
      currentIndex: -1,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                pagedAlbums.isEmpty
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
                      itemCount: pagedAlbums.length,
                      itemBuilder: (context, idx) {
                        final album = pagedAlbums[idx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/albumDetail',
                              arguments: {'albumId': album['id']},
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          album['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
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
                                    '생성일: ${DateTime.parse(album['createdAt']).toLocal().toString().split(" ")[0]}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed:
                        currentPage > 1
                            ? () {
                              setState(() {
                                currentPage--;
                                updatePage();
                              });
                            }
                            : null,
                    child: const Text('이전'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$currentPage / $totalPages'),
                  ),
                  ElevatedButton(
                    onPressed:
                        currentPage < totalPages
                            ? () {
                              setState(() {
                                currentPage++;
                                updatePage();
                              });
                            }
                            : null,
                    child: const Text('다음'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x146B4EFF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFF6B4EFF)),
                ),
              ),
              child: const Text(
                "뒤로가기",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
