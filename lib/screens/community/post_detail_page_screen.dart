import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class PostDetailPageScreen extends StatefulWidget {
  final int postId;
  const PostDetailPageScreen({super.key, required this.postId});

  @override
  State<PostDetailPageScreen> createState() => _PostDetailPageScreenState();
}

class _PostDetailPageScreenState extends State<PostDetailPageScreen> {
  Map<String, dynamic>? post;
  List comments = [];
  final commentController = TextEditingController();
  String userId = "1";

  @override
  void initState() {
    super.initState();
    fetchPost();
    fetchComments();
  }

  Future<void> fetchPost() async {
    final res = await Dio().get('api.puzzlelog.me/posts/${widget.postId}');
    setState(() => post = res.data);
  }

  Future<void> fetchComments() async {
    final res = await Dio().get(
      'api.puzzlelog.me/posts/${widget.postId}/comments',
    );
    setState(() => comments = res.data);
  }

  void toggleLike() async {
    final res = await Dio().patch(
      'api.puzzlelog.me/posts/${widget.postId}/like?userId=$userId',
    );
    setState(() {
      post?["liked"] = res.data["liked"];
      post?["likesCount"] = res.data["likesCount"];
    });
  }

  void submitComment() async {
    if (commentController.text.trim().isEmpty) return;

    final commentData = {
      "userId": userId,
      "content": commentController.text.trim(),
    };

    final res = await Dio().post(
      'api.puzzlelog.me/posts/${widget.postId}/comments',
      data: commentData,
    );
    setState(() => comments.add(res.data));
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) return const Center(child: CircularProgressIndicator());

    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              post?["title"] ?? "",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(post?["content"] ?? ""),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    post?["liked"] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: toggleLike,
                ),
                Text("좋아요 ${post?["likesCount"] ?? 0}"),
                Text("작성일: ${post?["createdAt"]}"),
              ],
            ),
            const Divider(),
            const Text(
              "댓글",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...comments.map(
              (comment) => ListTile(
                title: Text(comment["content"]),
                subtitle: Text(comment["userId"]),
                trailing: Text(comment["createdAt"]),
              ),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: "댓글 입력"),
            ),
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
