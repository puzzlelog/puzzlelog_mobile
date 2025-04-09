import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common_scaffold.dart';
import 'package:http_parser/http_parser.dart';

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

  String? originalNickname;
  String? originalBirthDate;
  String? originalGender;
  bool? originalIsAlarm;

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

          // 원본 값 백업
          originalNickname = nicknameController.text;
          originalBirthDate = birthDateController.text;
          originalGender = gender;
          originalIsAlarm = isAlarm;
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
      if (birthDateController.text.isNotEmpty)
        "birthDate": birthDateController.text,
      if (gender != null) "gender": gender,
      "isAlarm": isAlarm,
    };

    final Map<String, dynamic> formFields = {};

    // ✅ JSON을 MultipartFile로 포장해서 보냄
    formFields['data'] = MultipartFile.fromString(
      jsonEncode(data),
      contentType: MediaType('application', 'json'),
    );

    if (profileImage != null) {
      formFields['file'] = await MultipartFile.fromFile(profileImage!.path);
    }

    final formData = FormData.fromMap(formFields);

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
        ).showSnackBar(const SnackBar(content: Text('정보가 성공적으로 수정되었습니다.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? '오류')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정보 수정 실패')));
    }
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => profileImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 4,
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('사용자 정보를 불러오지 못했습니다.'))
              : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.center,
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                profileImage != null
                                    ? FileImage(File(profileImage!.path))
                                    : NetworkImage(
                                          user!['profileImg'] ??
                                              'https://via.placeholder.com/150?text=👤',
                                        )
                                        as ImageProvider,
                          ),
                          const SizedBox(height: 16),
                          editMode
                              ? Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: pickProfileImage,
                                    child: const Text('프로필 이미지 변경'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: nicknameController,
                                    decoration: const InputDecoration(
                                      labelText: '닉네임',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: birthDateController,
                                    decoration: const InputDecoration(
                                      labelText: '생년월일',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButton<String>(
                                    value: gender,
                                    hint: const Text('성별 선택'),
                                    onChanged:
                                        (val) => setState(() => gender = val),
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
                                    title: const Text('알람 설정'),
                                    value: isAlarm,
                                    onChanged:
                                        (val) => setState(() => isAlarm = val),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: handleUpdate,
                                        child: const Text('수정 완료'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            // ✅ 되돌리기 (Restore original values)
                                            nicknameController.text =
                                                originalNickname ?? '';
                                            birthDateController.text =
                                                originalBirthDate ?? '';
                                            gender = originalGender;
                                            isAlarm = originalIsAlarm ?? false;

                                            editMode = false;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                        ),
                                        child: const Text(
                                          '취소',
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              : Column(
                                children: [
                                  Text(
                                    '${user!['nickname']} 님',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('아이디: ${user!['userId']}'),
                                  // Text('이메일: ${user!['email']}'),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed:
                                        () => setState(() => editMode = true),
                                    child: const Text('정보 수정'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.photo_album),
                                    label: const Text('디지털 앨범 보기'),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/digitalAlbum',
                                      );
                                    },
                                  ),
                                ],
                              ),
                          const SizedBox(height: 16),
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
                  ),
                ),
              ),
    );
  }
}
