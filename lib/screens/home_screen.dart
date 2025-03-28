import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../widgets/common_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  bool _showNicknamePopup = false;
  bool _isNicknameAvailable = false;
  bool _isCheckingNickname = false;
  String _nicknameMessage = '';
  XFile? _profileImage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNickname());
  }

  Future<void> _checkNickname() async {
    String? userId = 'exampleUserId';
    String? token = 'exampleToken';

    if (userId == null || token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final response = await http.get(
      Uri.parse('https://api.puzzlelog.me/users?userId=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] && (data['data']['users'][0]['nickname'] == null)) {
        setState(() => _showNicknamePopup = true);
      }
    }
  }

  Future<void> _checkNicknameAvailability() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() {
        _nicknameMessage = '닉네임을 입력해주세요.';
        _isNicknameAvailable = false;
      });
      return;
    }

    setState(() => _isCheckingNickname = true);

    final response = await http.get(
      Uri.parse(
        'https://api.puzzlelog.me/users/check?type=nickname&value=$nickname',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _nicknameMessage =
            data['success']
                ? '사용 가능한 닉네임입니다.'
                : (data['message'] ?? '닉네임 중복 확인 실패');
        _isNicknameAvailable = data['success'];
        _isCheckingNickname = false;
      });
    } else {
      setState(() {
        _nicknameMessage = '이미 존재하는 닉네임입니다.';
        _isNicknameAvailable = false;
        _isCheckingNickname = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _profileImage = pickedImage);
    }
  }

  Future<void> _submitProfile() async {
    String? userId = 'exampleUserId';
    String? token = 'exampleToken';

    final uri = Uri.parse('https://api.puzzlelog.me/users/$userId');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $token';

    Map<String, dynamic> data = {
      'userId': userId,
      'email': '$userId@example.com',
      'nickname': _nicknameController.text,
      'birthDate': '2000-01-01',
      'gender': 'MALE',
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

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final result = jsonDecode(responseData.body);

    if (result['success']) {
      setState(() => _showNicknamePopup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC5E4E9), Color(0xFF87DCD7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🌱 PuzzleLog',
                  style: TextStyle(fontSize: 30, color: Colors.green),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () {}, child: const Text('시작하기')),
              ],
            ),
          ),
          if (_showNicknamePopup)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(labelText: '닉네임 입력'),
                      ),
                      ElevatedButton(
                        onPressed: _checkNicknameAvailability,
                        child: const Text('중복 확인'),
                      ),
                      Text(
                        _nicknameMessage,
                        style: TextStyle(
                          color:
                              _isNicknameAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('프로필 이미지 선택'),
                      ),
                      ElevatedButton(
                        onPressed: _isNicknameAvailable ? _submitProfile : null,
                        child: const Text('설정 완료'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
