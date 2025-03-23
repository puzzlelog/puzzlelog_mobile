import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final Dio dio = Dio();
  String userId = '';
  List<dynamic> friends = [];
  String searchNickname = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
    if (userId.isNotEmpty) {
      fetchFriends();
    }
  }

  Future<void> fetchFriends() async {
    final response = await dio.get('http://api.puzzlelog.me/friends/$userId/friends?type=friends&size=20');
    if (response.data['success']) {
      setState(() => friends = response.data['data']['friends']);
    }
  }

  Future<void> searchUser() async {
    final response = await dio.get('http://api.puzzlelog.me/users?nickname=$searchNickname');
    if (response.data['success'] && response.data['data']['users'].isNotEmpty) {
      final foundUser = response.data['data']['users'][0];
      sendFriendRequest(foundUser['userId']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
    }
  }

  Future<void> sendFriendRequest(String friendId) async {
    final response = await dio.post('http://api.puzzlelog.me/friends/$userId/friends/$friendId');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'])));
    fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => searchNickname = value,
                    decoration: InputDecoration(
                      hintText: '닉네임 입력',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: searchUser,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (_, index) {
                final friend = friends[index];
                return ListTile(
                  title: Text(friend['nickname']),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () async {
                      await dio.delete('http://api.puzzlelog.me/friends/$userId/deactivate/${friend['friendId']}');
                      fetchFriends();
                    },
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