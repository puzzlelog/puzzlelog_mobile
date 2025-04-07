import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_scaffold.dart';

class PostDetailPageScreen extends StatefulWidget {
  final int postId;
  const PostDetailPageScreen({super.key, required this.postId});

  @override
  State<PostDetailPageScreen> createState() => _PostDetailPageScreenState();
}

class _PostDetailPageScreenState extends State<PostDetailPageScreen> {
  Map<String, dynamic>? post;
  Map<String, dynamic>? diary;
  List comments = [];
  final commentController = TextEditingController();
  String userId = "user";

  @override
  void initState() {
    super.initState();
    fetchPost();
    fetchComments();
  }

  Future<void> fetchPost() async {
    try {
      final res = await Dio().get(
        'https://api.puzzlelog.me/posts/${widget.postId}',
      );
      final postData = res.data['data'];
      setState(() => post = postData);

      if (postData['diaryId'] != null) {
        final diaryRes = await Dio().get(
          'https://api.puzzlelog.me/diaries/${postData['diaryId']}',
        );
        setState(() => diary = diaryRes.data['data']);
      }
    } catch (e) {
      debugPrint('게시글 불러오기 오류: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      final res = await Dio().get(
        'https://api.puzzlelog.me/posts/${widget.postId}/comments',
      );
      setState(() => comments = res.data['data'] ?? []);
    } catch (e) {
      debugPrint('댓글 불러오기 오류: $e');
    }
  }

  void toggleLike() async {
    try {
      final res = await Dio().patch(
        'https://api.puzzlelog.me/posts/${widget.postId}/like?userId=$userId',
      );
      setState(() {
        post?['liked'] = res.data['data']['liked'];
        post?['likesCount'] = res.data['data']['likesCount'];
      });
    } catch (e) {
      debugPrint('좋아요 처리 오류: $e');
    }
  }

  void submitComment() async {
    if (commentController.text.trim().isEmpty) return;
    try {
      final res = await Dio().post(
        'https://api.puzzlelog.me/posts/${widget.postId}/comments',
        data: {"userId": userId, "content": commentController.text.trim()},
      );
      setState(() => comments.insert(0, res.data['data']));
      commentController.clear();
    } catch (e) {
      debugPrint('댓글 작성 오류: $e');
    }
  }

  void deleteComment(int commentId) async {
    try {
      await Dio().delete(
        'https://api.puzzlelog.me/posts/${widget.postId}/comments/$commentId',
      );
      setState(() => comments.removeWhere((c) => c['id'] == commentId));
    } catch (e) {
      debugPrint('댓글 삭제 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post?["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (post?['userId'] == userId)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("삭제 확인"),
                              content: const Text("정말 삭제하시겠습니까?"),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text("취소"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("삭제"),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await Dio().delete(
                          'https://api.puzzlelog.me/posts/${widget.postId}',
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 300,
              color: Colors.white30,
              child: Center(child: Text("🧩 FabricCanvasViewer 대체")),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    post?["liked"] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.pink,
                  ),
                  onPressed: toggleLike,
                ),
                Text("좋아요 ${post?["likesCount"] ?? 0}"),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(
                      post?["createdAt"] ?? DateTime.now().toIso8601String(),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              "댓글",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var comment in comments)
              ListTile(
                title: Text(comment['userId'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment['content'] ?? ''),
                    Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(DateTime.parse(comment['createdAt'])),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing:
                    comment['userId'] == userId
                        ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => deleteComment(comment['id']),
                        )
                        : null,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "댓글 입력",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: submitComment,
              child: const Text("댓글 작성"),
            ),
          ],
        ),
      ),
    );
  }
}
