import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common_scaffold.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool editMode = false;
  TextEditingController nicknameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  String? gender;
  bool isAlarm = false;
  XFile? profileImage;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await Dio().get(
        'https://api.puzzlelog.me/users',
        queryParameters: {'userId': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success']) {
        setState(() {
          user = response.data['data']['users'][0];
          nicknameController.text = user!['nickname'] ?? '';
          birthDateController.text = user!['birthDate'] ?? '';
          gender = user!['gender'];
          isAlarm = user!['isAlarm'];
        });
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/login');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('accessToken');
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> handleUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final data = {
      "nickname": nicknameController.text,
      "birthDate": birthDateController.text,
      "gender": gender,
      "isAlarm": isAlarm,
    };

    FormData formData = FormData.fromMap({
      'data': jsonEncode(data),
      if (profileImage != null)
        'file': await MultipartFile.fromFile(profileImage!.path),
    });

    try {
      final response = await Dio().patch(
        'https://api.puzzlelog.me/users/me',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success']) {
        fetchUserInfo();
        setState(() => editMode = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('정보가 성공적으로 수정되었습니다.')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정보 수정 실패')));
    }
  }

  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => profileImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 2,
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('사용자 정보를 불러오지 못했습니다.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          profileImage != null
                              ? FileImage(File(profileImage!.path))
                                  as ImageProvider
                              : NetworkImage(
                                user!['profileImg'] ??
                                    'https://via.placeholder.com/150?text=👤',
                              ),
                    ),
                    const SizedBox(height: 16),
                    editMode
                        ? Column(
                          children: [
                            ElevatedButton(
                              onPressed: pickProfileImage,
                              child: const Text('프로필 이미지 변경'),
                            ),
                            TextField(
                              controller: nicknameController,
                              decoration: InputDecoration(labelText: '닉네임'),
                            ),
                            TextField(
                              controller: birthDateController,
                              decoration: InputDecoration(labelText: '생년월일'),
                            ),
                            DropdownButton<String>(
                              value: gender,
                              hint: Text('성별 선택'),
                              onChanged: (val) => setState(() => gender = val),
                              items:
                                  ['MALE', 'FEMALE']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                            ),
                            SwitchListTile(
                              title: Text('알람 설정'),
                              value: isAlarm,
                              onChanged: (val) => setState(() => isAlarm = val),
                            ),
                            ElevatedButton(
                              onPressed: handleUpdate,
                              child: const Text('수정 완료'),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            Text(
                              '${user!['nickname']} 님',
                              style: const TextStyle(fontSize: 20),
                            ),
                            Text('아이디: ${user!['userId']}'),
                            Text('이메일: ${user!['email']}'),
                            ElevatedButton(
                              onPressed: () => setState(() => editMode = true),
                              child: const Text('정보 수정'),
                            ),
                          ],
                        ),
                    TextButton(
                      onPressed: handleLogout,
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
