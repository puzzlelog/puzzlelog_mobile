import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_scaffold.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List posts = [];
  List filteredPosts = [];
  String filter = 'all';
  String userId = "user";

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final dio = Dio();
    try {
      final response = await dio.get("https://api.puzzlelog.me/posts");
      if (response.statusCode == 200) {
        final List<dynamic> fetchedPosts = response.data['data'];
        for (var post in fetchedPosts) {
          final commentCountRes = await dio.get(
            "https://api.puzzlelog.me/posts/${post['id']}/comments/count",
          );
          post['commentCount'] = commentCountRes.data['data'];
        }
        fetchedPosts.sort(
          (a, b) => DateTime.parse(
            b['createdAt'],
          ).compareTo(DateTime.parse(a['createdAt'])),
        );
        setState(() {
          posts = fetchedPosts;
          filteredPosts = fetchedPosts;
        });
      }
    } catch (e) {
      debugPrint("게시글 로딩 실패: $e");
    }
  }

  void toggleFilter(String selectedFilter) {
    setState(() {
      filter = selectedFilter;
      if (filter == 'mine') {
        filteredPosts =
            posts.where((post) => post['userId'] == userId).toList();
      } else {
        filteredPosts = posts;
      }
    });
  }

  void deletePost(int postId) async {
    try {
      await Dio().delete("https://api.puzzlelog.me/posts/$postId");
      setState(() => posts.removeWhere((p) => p['id'] == postId));
      toggleFilter(filter);
    } catch (e) {
      debugPrint("게시글 삭제 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '커뮤니티',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/uploadPost'),
                  child: const Text('게시글 작성'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => toggleFilter('all'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        filter == 'all' ? Colors.brown : Colors.grey,
                  ),
                  child: const Text(
                    '전체 게시글',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => toggleFilter('mine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        filter == 'mine' ? Colors.brown : Colors.grey,
                  ),
                  child: const Text(
                    '내 게시글',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  filteredPosts.isNotEmpty
                      ? ListView.separated(
                        itemCount: filteredPosts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return Card(
                            color: Colors.white,
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                post['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('작성자: ${post['userId']}'),
                                  Text('댓글 수: ${post['commentCount']}'),
                                  Text(
                                    '작성일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(post['createdAt']))}',
                                  ),
                                ],
                              ),
                              trailing:
                                  post['userId'] == userId
                                      ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => deletePost(post['id']),
                                      )
                                      : null,
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/postDetail',
                                    arguments: {'postId': post['id']},
                                  ),
                            ),
                          );
                        },
                      )
                      : const Center(child: Text('작성된 게시글이 없습니다.')),
            ),
          ],
        ),
      ),
    );
  }
}
