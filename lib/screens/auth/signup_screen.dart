// ✅ signup_screen.dart - 중복확인 로직 오류 수정
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common_scaffold.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userPwdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  String gender = 'MALE';
  XFile? _profileImage;
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

    final data = {
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

    if (_profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', _profileImage!.path),
      );
    }

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  Future<void> _checkDuplication(String type, String value) async {
    if (value.trim().isEmpty) {
      setState(() => message = '$type를 입력해주세요.');
      return;
    }
    final uri = Uri.parse(
      'https://api.puzzlelog.me/users/check?type=$type&value=$value',
    );
    try {
      final response = await http.get(uri);
      final decoded = utf8.decode(response.bodyBytes);
      print('🔍 응답 본문: $decoded');

      final result = jsonDecode(decoded);

      setState(() => message = result['message'] ?? '응답 메시지가 없습니다.');
    } catch (e) {
      setState(() => message = '중복 확인 중 오류 발생');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 아이디 + 중복 확인
                  Row(
                    children: [
                      Expanded(child: _buildTextField(userIdController, '아이디')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            () => _checkDuplication(
                              'userId',
                              userIdController.text,
                            ),
                        style: _buttonStyle(),
                        child: const Text('중복확인'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(userPwdController, '비밀번호', obscure: true),
                  const SizedBox(height: 12),

                  // 이메일 + 중복 확인
                  Row(
                    children: [
                      Expanded(child: _buildTextField(emailController, '이메일')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            () => _checkDuplication(
                              'email',
                              emailController.text,
                            ),
                        style: _buttonStyle(),
                        child: const Text('중복확인'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _buildTextField(birthDateController, '생년월일 (YYYY-MM-DD)'),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    dropdownColor: const Color(0xFF2a1759),
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('남성')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                    ],
                    onChanged: (val) => setState(() => gender = val!),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('성별'),
                  ),

                  const SizedBox(height: 16),
                  _buildStyledButton('프로필 이미지 선택', _pickImage),
                  const SizedBox(height: 16),
                  _buildStyledButton('회원가입', handleSignup),

                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: TextStyle(
                      color:
                          message.contains('성공')
                              ? Colors.greenAccent
                              : Colors.redAccent,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent.withOpacity(0.8),
      foregroundColor: Colors.white,
      minimumSize: const Size(80, 50),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
    );
  }

  Widget _buildStyledButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _buttonStyle(),
      child: Text(text),
    );
  }
}
