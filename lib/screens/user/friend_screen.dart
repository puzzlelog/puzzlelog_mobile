import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../widgets/common_scaffold.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  List friends = [];
  List requests = [];
  List blocked = [];
  String searchNickname = '';
  Map? searchResult;
  String activeTab = 'friends';

  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchFriends('friends');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> fetchFriends(String type) async {
    final userId = await getUserId();
    if (userId == null) return;

    final response = await http.get(
      Uri.parse(
        'https://api.puzzlelog.me/friends/$userId/friends?type=$type&size=20',
      ),
    );

    final result = jsonDecode(response.body);

    if (result['success']) {
      setState(() {
        switch (type) {
          case 'friends':
            friends = result['data']['friends'];
            break;
          case 'your_request':
            requests = result['data']['friends'];
            break;
          case 'blocked':
            blocked = result['data']['friends'];
            break;
        }
      });
    }
  }

  Future<void> handleFriendAction(String action, String friendId) async {
    final userId = await getUserId();
    final token = await getAccessToken();

    final headers = {'Authorization': 'Bearer $token', 'userId': userId!};

    String url = '';
    String method = '';

    switch (action) {
      case 'request':
        url = 'https://api.puzzlelog.me/friends/$userId/friends/$friendId';
        method = 'POST';
        break;
      case 'accept':
        url =
            'https://api.puzzlelog.me/friends/$userId/requests/$friendId/accept';
        method = 'PATCH';
        break;
      case 'delete':
        url = 'https://api.puzzlelog.me/friends/$userId/friends/$friendId';
        method = 'DELETE';
        break;
      case 'block':
        url =
            'https://api.puzzlelog.me/friends/$userId/friends/$friendId/block';
        method = 'PATCH';
        break;
      case 'unblock':
        url =
            'https://api.puzzlelog.me/friends/$userId/friends/$friendId/unblock';
        method = 'PATCH';
        break;
    }

    final response = http.Request(method, Uri.parse(url));
    response.headers.addAll(headers);

    final result = await response.send();
    final resBody = await result.stream.bytesToString();
    final json = jsonDecode(resBody);

    if (json['success']) {
      fetchFriends(activeTab);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(json['message'] ?? '요청 처리됨')));
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: -1,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '친구 관리',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => searchNickname = val,
                    decoration: InputDecoration(
                      hintText: '닉네임 검색',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(onPressed: () {}, child: const Text('검색')),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder:
                    (context, idx) => ListTile(
                      title: Text(friends[idx]['nickname']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed:
                                () => handleFriendAction(
                                  'delete',
                                  friends[idx]['friendId'],
                                ),
                          ),
                          IconButton(
                            icon: Icon(Icons.block),
                            onPressed:
                                () => handleFriendAction(
                                  'block',
                                  friends[idx]['friendId'],
                                ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
