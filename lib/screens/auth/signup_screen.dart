import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
  String? gender;
  DateTime? birthDate = DateTime(2001, 1, 1);
  bool skipBirthDate = false;

  String _message = '';
  bool _isLoading = false;

  Future<bool> _checkDuplicate(String type, String value) async {
    if (value.isEmpty) return false;

    final uri = Uri.parse(
      'https://api.puzzlelog.me/users/check?type=$type&value=$value',
    );

    try {
      final response = await http.get(uri);
      final decoded = utf8.decode(response.bodyBytes);
      final result = jsonDecode(decoded);

      setState(() {
        _message = result['message'] ?? '';
      });

      return result['success'] == true;
    } catch (e) {
      setState(() {
        _message = '중복 확인 실패: $e';
      });
      return false;
    }
  }

  Future<void> handleSignup() async {
    setState(() {
      _message = '';
      _isLoading = true;
    });

    final userId = userIdController.text.trim();
    final userPwd = userPwdController.text.trim();
    final email = emailController.text.trim();

    if (userId.isEmpty || userPwd.isEmpty || email.isEmpty) {
      setState(() {
        _message = '아이디, 비밀번호, 이메일은 필수 입력값입니다.';
        _isLoading = false;
      });
      return;
    }

    final idOk = await _checkDuplicate('userId', userId);
    if (!idOk) {
      setState(() => _isLoading = false);
      return;
    }

    final emailOk = await _checkDuplicate('email', email);
    if (!emailOk) {
      setState(() => _isLoading = false);
      return;
    }

    final uri = Uri.parse('https://api.puzzlelog.me/users');
    final request = http.MultipartRequest('POST', uri);

    final data = {
      'userId': userId,
      'userPwd': userPwd,
      'email': email,
      if (!skipBirthDate && birthDate != null)
        'birthDate':
            '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
      if (gender != null) 'gender': gender,
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
      final decoded = utf8.decode(responseData.bodyBytes);
      final result = jsonDecode(decoded);

      if (response.statusCode == 200 && result['success']) {
        setState(() => _message = '회원가입 성공!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() => _message = result['message'] ?? '회원가입 실패');
      }
    } catch (error) {
      setState(() => _message = '회원가입 실패: 서버 오류 ($error)');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: null,
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  _buildTextField(userIdController, '아이디'),
                  const SizedBox(height: 12),
                  _buildTextField(userPwdController, '비밀번호', obscure: true),
                  const SizedBox(height: 12),
                  _buildTextField(emailController, '이메일'),
                  const SizedBox(height: 12),
                  _buildBirthDatePicker(),
                  const SizedBox(height: 12),
                  _buildGenderDropdown(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('회원가입'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('로그인 화면으로 이동'),
                  ),
                  const SizedBox(height: 20),
                  if (_message.isNotEmpty)
                    Text(
                      _message,
                      style: TextStyle(
                        color:
                            _message.contains('성공')
                                ? Colors.greenAccent
                                : Colors.redAccent,
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: gender,
      hint: const Text('선택 안 함', style: TextStyle(color: Colors.white70)),
      items: const [
        DropdownMenuItem(value: null, child: Text('선택 안 함')),
        DropdownMenuItem(value: 'MALE', child: Text('남성')),
        DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
      ],
      onChanged: (val) => setState(() => gender = val),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('성별'),
      dropdownColor: Colors.deepPurple,
    );
  }

  Widget _buildBirthDatePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap:
                skipBirthDate
                    ? null
                    : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birthDate ?? DateTime(2001, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => birthDate = picked);
                      }
                    },
            child: AbsorbPointer(
              child: TextField(
                controller: TextEditingController(
                  text:
                      skipBirthDate
                          ? ''
                          : (birthDate != null
                              ? '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}'
                              : ''),
                ),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('생년월일'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Checkbox(
              value: skipBirthDate,
              onChanged:
                  (val) => setState(() {
                    skipBirthDate = val ?? false;
                    if (skipBirthDate) birthDate = null;
                  }),
              checkColor: Colors.black,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.white70;
              }),
            ),
            const Text(
              '선택 안 함',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
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
}
