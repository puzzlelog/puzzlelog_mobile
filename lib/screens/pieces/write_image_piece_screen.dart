import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

import '../../widgets/common_scaffold.dart';

class WriteImagePieceScreen extends StatefulWidget {
  const WriteImagePieceScreen({super.key});

  @override
  _WriteImagePieceScreenState createState() => _WriteImagePieceScreenState();
}

class _WriteImagePieceScreenState extends State<WriteImagePieceScreen> {
  final TextEditingController _tagsController = TextEditingController();
  File? _selectedImage;
  bool _useGPS = false;
  bool _loading = false;

  final String apiBaseUrl = "https://api.puzzlelog.me/pieces";

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<Map<String, dynamic>?> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      "type": "Point",
      "coordinates": [position.longitude, position.latitude],
    };
  }

  Future<void> _handleSave() async {
    final tagsText = _tagsController.text.trim();

    if (_selectedImage == null) {
      _showAlert("이미지를 선택해주세요.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken') ?? '';

    if (userId == null) {
      _showAlert("로그인이 필요합니다.");
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _loading = true);

    final tags =
        tagsText
            .split(",")
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    final location = _useGPS ? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "IMAGE",
      "tags": tags,
      "location": location,
      "isPrivate": false,
    };

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiBaseUrl));
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromString(
          'data',
          json.encode(pieceData),
          contentType: MediaType('application', 'json'),
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();

      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);

      if (response.statusCode == 200 && result['success']) {
        _showAlert("이미지 조각이 저장되었습니다.");
        Navigator.pushNamed(context, '/makePiece');
      } else {
        _showAlert(result['message'] ?? "저장에 실패했습니다.");
      }
    } catch (e) {
      _showAlert("서버 오류로 인해 저장할 수 없습니다.");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("확인"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Image Piece",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 100),
                ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("사진 촬영"),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("갤러리에서 선택"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "태그 입력 (쉼표로 구분)",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _useGPS,
                      onChanged: (val) => setState(() => _useGPS = val),
                    ),
                    const Text("GPS 사용"),
                  ],
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSave,
                  child: Text(_loading ? "저장 중" : "저장하기"),
                ),
              ],
            ),
            TextButton(
              child: const Text("뒤로가기", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
