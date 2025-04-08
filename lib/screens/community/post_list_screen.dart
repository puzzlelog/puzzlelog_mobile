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

  int currentPage = 1;
  final int itemsPerPage = 10;

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
          applyFilter();
        });
      }
    } catch (e) {
      debugPrint("게시글 로딩 실패: $e");
    }
  }

  void applyFilter() {
    setState(() {
      if (filter == 'mine') {
        filteredPosts =
            posts.where((post) => post['userId'] == userId).toList();
      } else {
        filteredPosts = List.from(posts);
      }
      currentPage = 1;
    });
  }

  void toggleFilter(String selectedFilter) {
    setState(() {
      filter = selectedFilter;
      applyFilter();
    });
  }

  void deletePost(int postId) async {
    try {
      await Dio().delete("https://api.puzzlelog.me/posts/$postId");
      setState(() => posts.removeWhere((p) => p['id'] == postId));
      applyFilter();
    } catch (e) {
      debugPrint("게시글 삭제 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredPosts.length / itemsPerPage).ceil();
    final paginatedPosts =
        filteredPosts
            .skip((currentPage - 1) * itemsPerPage)
            .take(itemsPerPage)
            .toList();

    return CommonScaffold(
      currentIndex: 2,
      body: Container(
        color: const Color(0xFFFAF5FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '커뮤니티',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        () => Navigator.pushNamed(context, '/uploadPost'),
                    child: const Text(
                      '게시글 작성',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _filterButton('전체 게시글', 'all'),
                  const SizedBox(width: 10),
                  _filterButton('내 게시글', 'mine'),
                ],
              ),
            ),
            Expanded(
              child:
                  paginatedPosts.isNotEmpty
                      ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: paginatedPosts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = paginatedPosts[index];
                          return _postCard(post);
                        },
                      )
                      : const Center(
                        child: Text(
                          '작성된 게시글이 없습니다.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
            ),
            if (totalPages > 1) _paginationControls(totalPages),
            _backButton(),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, String selectedFilter) {
    final bool isSelected = filter == selectedFilter;
    return ElevatedButton(
      onPressed: () => toggleFilter(selectedFilter),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _postCard(Map post) {
    final bool isMyPost = post['userId'] == userId;
    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(
            context,
            '/postDetail',
            arguments: {'postId': post['id']},
          ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => deletePost(post['id']),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '작성자: ${post['userId']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  '댓글 ${post['commentCount']}개',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'yyyy-MM-dd HH:mm',
              ).format(DateTime.parse(post['createdAt'])),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                currentPage > 1 ? () => setState(() => currentPage--) : null,
          ),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(color: Colors.deepPurple),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                currentPage < totalPages
                    ? () => setState(() => currentPage++)
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x146B4EFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF6B4EFF)),
            ),
          ),
          child: const Text(
            '뒤로가기',
            style: TextStyle(
              color: Color(0xFF6B4EFF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
