import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with TickerProviderStateMixin {
  late TabController mainTabController;
  late TabController invitationTabController;

  List friends = [];
  List friendRequests = [];
  List diaryInvitations = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mainTabController = TabController(length: 2, vsync: this);
    invitationTabController = TabController(length: 2, vsync: this);
    fetchFriends();
    fetchFriendRequests();
    fetchDiaryInvitations();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> fetchFriends() async {
    final userId = await getUserId();
    final token = await getToken();
    final dio = Dio();

    final res = await dio.get(
      'https://api.puzzlelog.me/friends/$userId/friends?type=friends',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.data['success']) {
      setState(() => friends = res.data['data']['friends']);
    }
  }

  Future<void> fetchFriendRequests() async {
    final userId = await getUserId();
    final token = await getToken();
    final dio = Dio();

    final res = await dio.get(
      'https://api.puzzlelog.me/friends/$userId/friends?type=your_request',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.data['success']) {
      setState(() => friendRequests = res.data['data']['friends']);
    }
  }

  Future<void> fetchDiaryInvitations() async {
    final token = await getToken();
    final dio = Dio();

    final res = await dio.get(
      'https://api.puzzlelog.me/invitations?type=my_request',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.data['success']) {
      setState(() {
        diaryInvitations =
            (res.data['data'] as List)
                .where(
                  (inv) =>
                      inv['status'] != 'REJECTED' &&
                      inv['status'] != 'ACCEPTED',
                )
                .toList();
      });
    }
  }

  // 친구 추가
  Future<void> requestFriendByNickname(String nickname) async {
    final token = await getToken();
    final userId = await getUserId();
    final dio = Dio();

    try {
      final res = await dio.get(
        'https://api.puzzlelog.me/users/nickname/$nickname',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!res.data['success']) throw res.data['message'];

      final friendId = res.data['data']['userId'];

      final reqRes = await dio.post(
        'https://api.puzzlelog.me/friends/$userId/friends/$friendId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(reqRes.data['message'])));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // 친구 삭제 및 차단 액션
  Future<void> handleFriendAction(String action, String friendId) async {
    final userId = await getUserId();
    final token = await getToken();
    final dio = Dio();

    String url =
        'https://api.puzzlelog.me/friends/$userId/friends/$friendId${action == 'delete' ? '' : '/block'}';
    final method = action == 'delete' ? dio.delete : dio.patch;

    final res = await method(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res.data['message'])));

    fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: -1,
      body: Column(
        children: [
          TabBar(
            controller: mainTabController,
            tabs: const [
              Tab(text: '친구 목록', icon: Icon(Icons.people)),
              Tab(text: '받은 초대', icon: Icon(Icons.mail)),
            ],
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: mainTabController,
              children: [friendListView(), invitationView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget friendListView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: '닉네임 검색',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => requestFriendByNickname(searchController.text),
              child: const Text('친구 추가'),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (_, idx) {
            final friend = friends[idx];
            return ListTile(
              title: Text(friend['nickname']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed:
                        () => handleFriendAction('delete', friend['friendId']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.grey),
                    onPressed:
                        () => handleFriendAction('block', friend['friendId']),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget invitationView() => Column(
    children: [
      TabBar(
        controller: invitationTabController,
        tabs: const [Tab(text: '친구 초대'), Tab(text: '협업일기 초대')],
        indicatorColor: Colors.deepPurple,
        labelColor: Colors.deepPurple,
      ),
      Expanded(
        child: TabBarView(
          controller: invitationTabController,
          children: [friendRequestView(), diaryInvitationView()],
        ),
      ),
    ],
  );

  Widget friendRequestView() =>
      friendRequests.isEmpty
          ? const Center(child: Text('친구 초대가 없습니다.'))
          : ListView.builder(
            itemCount: friendRequests.length,
            itemBuilder: (_, idx) {
              final req = friendRequests[idx];
              return ListTile(
                title: Text('요청자: ${req['nickname']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('수락')),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '거절',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          );

  Widget diaryInvitationView() =>
      diaryInvitations.isEmpty
          ? const Center(child: Text('일기 초대가 없습니다.'))
          : ListView.builder(
            itemCount: diaryInvitations.length,
            itemBuilder: (_, idx) {
              final inv = diaryInvitations[idx];
              return ListTile(
                title: Text(inv['senderId']),
                subtitle: Text(inv['diaryDate']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('수락')),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '거절',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
}
