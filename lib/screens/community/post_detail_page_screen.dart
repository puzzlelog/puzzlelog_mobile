import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';
import '../diary/widgets/diary_canvas.dart';

class PostDetailPageScreen extends StatefulWidget {
  final String postId;
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
  bool isLoading = true;

  List<Map<String, dynamic>> diaryElements = [];
  String? diaryBackgroundUrl;

  @override
  void initState() {
    super.initState();
    fetchPostAndDiary();
    fetchComments();
  }

  Future<void> fetchPostAndDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    try {
      final res = await Dio().get(
        'https://api.puzzlelog.me/posts/${widget.postId}',
      );
      final postData = res.data['data'];
      setState(() => post = postData);

      if (postData['diaryId'] != null) {
        final diaryRes = await Dio().get(
          'https://api.puzzlelog.me/diaries/${postData['diaryId']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        final diaryData = diaryRes.data['data'];
        setState(() {
          diary = diaryData;
          diaryElements = List<Map<String, dynamic>>.from(
            diaryData['elements'] ?? [],
          );
          diaryBackgroundUrl = diaryData['background']?['mediaId'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('게시글 또는 일기 불러오기 오류: $e');
      setState(() => isLoading = false);
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
    if (isLoading || post == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CommonScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔸 제목 중앙정렬
                  Text(
                    post?["title"] ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔸 일기 정사각형 형태로 깔끔하게 구성
                  AspectRatio(
                    aspectRatio: 1, // 정사각형
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DiaryCanvas(
                        elements: diaryElements,
                        backgroundUrl: diaryBackgroundUrl,
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔸 좋아요, 날짜, 삭제 아이콘
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              post?["liked"] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.pinkAccent,
                            ),
                            onPressed: toggleLike,
                          ),
                          Text(
                            "${post?["likesCount"] ?? 0}명이 좋아합니다",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (post?['userId'] == userId)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
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
                                        onPressed:
                                            () => Navigator.pop(context, true),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.parse(
                          post?["createdAt"] ??
                              DateTime.now().toIso8601String(),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 24),

                  // 🔸 댓글 미리보기 최대 3개까지
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "댓글 ${comments.length}개",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...comments
                      .take(3)
                      .map(
                        (comment) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${comment['userId']}  ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: comment['content'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (comment['userId'] == userId)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => deleteComment(comment['id']),
                                ),
                            ],
                          ),
                        ),
                      ),
                  if (comments.length > 3)
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "댓글 모두 보기",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔸 댓글 입력창 하단 고정
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              left: 10,
              right: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "댓글을 입력하세요...",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
