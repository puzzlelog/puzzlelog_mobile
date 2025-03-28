import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String userId = "1";

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

        // 댓글 개수 가져오기
        for (var post in fetchedPosts) {
          final commentCountRes = await dio.get(
            "https://api.puzzlelog.me/posts/${post['id']}/comments/count",
          );
          post['commentCount'] = commentCountRes.data['data'];
        }

        setState(() {
          posts = fetchedPosts;
          filteredPosts = fetchedPosts;
        });
      }
    } catch (e) {
      print("게시글 로딩 실패: $e");
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

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '커뮤니티',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/uploadPost'),
                  child: Text('게시글 작성'),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => toggleFilter('all'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: filter == 'all' ? Colors.brown : Colors.grey,
                ),
                child: Text('전체 게시글', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => toggleFilter('mine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      filter == 'mine' ? Colors.brown : Colors.grey,
                ),
                child: Text('내 게시글', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          Expanded(
            child:
                filteredPosts.isNotEmpty
                    ? ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return ListTile(
                          title: Text(post['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post['content']),
                              Text('댓글 수: ${post['commentCount']}'),
                              Text(
                                '작성일: ${DateTime.parse(post['createdAt']).toLocal()}',
                              ),
                            ],
                          ),
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/postDetail',
                                arguments: post['id'],
                              ),
                        );
                      },
                    )
                    : Center(child: Text('작성된 게시글이 없습니다.')),
          ),
        ],
      ),
    );
  }
}
