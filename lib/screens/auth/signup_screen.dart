import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userPwdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  String gender = 'MALE';

  String message = '';

  Future<void> handleSignup() async {
    if (userIdController.text.isEmpty ||
        userPwdController.text.isEmpty ||
        emailController.text.isEmpty) {
      setState(() => message = '아이디, 비밀번호, 이메일은 필수 입력값입니다.');
      return;
    }

    final uri = Uri.parse('https://api.puzzlelog.me/users');

    final request = http.MultipartRequest('POST', uri);

    Map<String, dynamic> data = {
      'userId': userIdController.text,
      'userPwd': userPwdController.text,
      'email': emailController.text,
      'birthDate': birthDateController.text,
      'gender': gender,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(data),
        contentType: MediaType('application', 'json'),
      ),
    );

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final result = jsonDecode(responseData.body);

      if (response.statusCode == 200 && result['success']) {
        setState(() => message = '회원가입 성공!');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() => message = result['message'] ?? '회원가입 실패');
      }
    } catch (error) {
      setState(() => message = '회원가입 실패: 서버 오류');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userPwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: birthDateController,
              decoration: const InputDecoration(
                labelText: '생년월일(YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: gender,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('남성')),
                DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
              ],
              onChanged: (val) => setState(() => gender = val!),
              decoration: const InputDecoration(
                labelText: '성별',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleSignup,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
