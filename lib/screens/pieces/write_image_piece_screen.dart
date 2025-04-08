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
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  File? _selectedImage;
  bool _useGPS = false;
  bool _loading = false;
  Map<String, dynamic>? _currentLocation;

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

  Future<void> _handleGpsToggle(bool val) async {
    if (val) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showAlert("기기의 GPS가 꺼져 있습니다. 설정에서 켜주세요.");
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          _showAlert("위치 권한이 거부되어 GPS를 사용할 수 없습니다.");
          return;
        }
      }

      final location = await _getLocation();
      if (location != null) {
        setState(() {
          _useGPS = true;
          _currentLocation = location;
        });
      } else {
        _showAlert("위치 정보를 가져오지 못했습니다.");
      }
    } else {
      setState(() {
        _useGPS = false;
        _currentLocation = null;
      });
    }
  }

  void _handleTagInput(String raw) {
    final clean = raw.replaceAll(',', '').trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() => _tags.add(clean));
    }
    _tagController.clear();
  }

  Future<void> _handleSave() async {
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

    final location = _useGPS ? _currentLocation ?? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "IMAGE",
      "tags": _tags,
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
        _showAlert("사진 조각이 저장되었습니다.");
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "사진 조각 작성",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _selectedImage != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                : Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("사진 촬영"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("갤러리에서 선택"),
            ),
            const SizedBox(height: 20),
            const Text("태그", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._tags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFFEDE7F6),
                        labelStyle: const TextStyle(color: Colors.black87),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: _tags.isEmpty ? "태그 입력" : null,
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleTagInput,
                      onChanged: (val) {
                        if (val.endsWith(',')) _handleTagInput(val);
                      },
                    ),
                  ),
                ],
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
                      onChanged: _handleGpsToggle,
                      activeColor: const Color(0xFF6B4EFF),
                    ),
                    const Text("GPS 사용"),
                  ],
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_loading ? "저장 중..." : "저장하기"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x146B4EFF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF6B4EFF)),
                ),
              ),
              child: const Text(
                "뒤로가기",
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
