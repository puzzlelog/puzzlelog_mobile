import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import '../../widgets/common_scaffold.dart';

class WriteTextPieceScreen extends StatefulWidget {
  const WriteTextPieceScreen({super.key});

  @override
  State<WriteTextPieceScreen> createState() => _WriteTextPieceScreenState();
}

class _WriteTextPieceScreenState extends State<WriteTextPieceScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _loading = false;
  bool _useGPS = false;
  bool _isGPSEnabled = false;
  Map<String, dynamic>? _currentLocation;

  final String apiBaseUrl = "https://api.puzzlelog.me/pieces";

  @override
  void initState() {
    super.initState();
    _checkGPSEnabled();
    _textController.addListener(() => setState(() {}));
  }

  Future<void> _checkGPSEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() => _isGPSEnabled = serviceEnabled);
  }

  Future<Map<String, dynamic>?> _getLocation() async {
    try {
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
      ).timeout(const Duration(seconds: 7));

      return {
        "type": "Point",
        "coordinates": [position.longitude, position.latitude],
      };
    } catch (e) {
      debugPrint("위치 가져오기 실패: $e");
      return null;
    }
  }

  Future<void> _handleGpsToggle(bool val) async {
    if (val) {
      // 먼저 권한 체크부터
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showAlert("위치 권한이 필요합니다. 설정에서 허용해주세요.");
        return;
      }

      // 권한 OK → 서비스 켜졌는지 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showAlert("기기의 GPS가 꺼져 있습니다. 설정에서 켜주세요.");
        return;
      }

      final location = await _getLocation();
      if (location != null) {
        setState(() {
          _useGPS = true;
          _currentLocation = location;
          _isGPSEnabled = true;
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
    final text = _textController.text.trim();

    if (text.isEmpty) {
      _showAlert("내용을 입력해주세요.");
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

    if (_useGPS && location == null) {
      _showAlert("위치 정보를 가져오지 못했습니다. GPS 상태를 확인해주세요.");
      setState(() => _loading = false);
      return;
    }

    final pieceData = {
      "userId": userId,
      "type": "TEXT",
      "text": text,
      "tags": _tags,
      "location": location,
      "isPrivate": false,
    };

    final request = http.MultipartRequest('POST', Uri.parse(apiBaseUrl));
    request.headers['Authorization'] = 'Bearer $token';

    // ✅ JSON 데이터는 fromString이 아니라 fields로 전달
    request.fields['data'] = json.encode(pieceData);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final result = json.decode(responseBody);

      if (response.statusCode == 200 && result['success']) {
        _showAlert("조각이 저장되었습니다.");
        _textController.clear();
        _tagController.clear();
        setState(() {
          _tags.clear();
          _currentLocation = null;
        });
        if (!mounted) return;
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "글 조각 작성",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "이 공간은 온전히 당신을 위한 조각입니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Stack(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_textController.text.isEmpty)
                  const Positioned(
                    top: 14,
                    left: 14,
                    child: Text(
                      "당신의 감정과 생각을 글로 표현해보세요.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      activeColor: const Color(0xFF6B4EFF),
                      value: _useGPS,
                      onChanged: _handleGpsToggle,
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
            if (!_isGPSEnabled)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "GPS가 꺼져 있습니다. 위치 정보를 사용하려면 GPS를 켜주세요.",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
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
