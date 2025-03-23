import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';

import '../../widgets/common_scaffold.dart';

class WriteTextPieceScreen extends StatefulWidget {
  const WriteTextPieceScreen({super.key});

  @override
  _WriteTextPieceScreenState createState() => _WriteTextPieceScreenState();
}

class _WriteTextPieceScreenState extends State<WriteTextPieceScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _loading = false;
  bool _useGPS = false;
  bool _isGPSEnabled = false;

  final String apiBaseUrl = "http://api.puzzlelog.me/pieces";

  @override
  void initState() {
    super.initState();
    _checkGPSEnabled();
  }

  Future<void> _checkGPSEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() => _isGPSEnabled = serviceEnabled);
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
      "coordinates": [position.longitude, position.latitude]
    };
  }

  Future<void> _handleSave() async {
    final text = _textController.text.trim();
    final tagsText = _tagsController.text.trim();

    if (text.isEmpty) {
      _showAlert("내용을 입력해주세요.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      _showAlert("로그인이 필요합니다.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _loading = true);

    final tagArray = tagsText.split(",").map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final location = _useGPS ? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "TEXT",
      "content": text,
      "tags": tagArray,
      "location": location,
      "isPrivate": false,
    };

    final formData = FormData(pieceData);

    try {
      final response = await http.post(
        Uri.parse(apiBaseUrl),
        body: formData,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          _showAlert("조각이 저장되었습니다.");
          _textController.clear();
          _tagsController.clear();
          Navigator.pushNamed(context, '/makePiece');
        } else {
          _showAlert(result['message'] ?? "저장에 실패했습니다.");
        }
      } else {
        _showAlert("서버 오류로 인해 저장할 수 없습니다.");
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
      builder: (_) => AlertDialog(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Text Piece",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "당신의 감정과 생각을 자유롭게 남겨보세요. 이곳은 당신만의 공간입니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "당신의 조각을 남겨보세요...",
              ),
            ),
            const SizedBox(height: 10),
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
                      onChanged: _isGPSEnabled
                          ? (val) => setState(() => _useGPS = val)
                          : null,
                    ),
                    const Text("GPS 사용"),
                  ],
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSave,
                  child: Text(_loading ? "저장 중..." : "저장하기"),
                ),
              ],
            ),
            if (!_isGPSEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "GPS가 꺼져 있습니다. 위치 정보를 사용하려면 GPS를 켜주세요.",
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),
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

class FormData extends http.MultipartRequest {
  FormData(Map<String, dynamic> pieceData)
      : super('POST', Uri.parse("http://api.puzzlelog.me/pieces")) {
    final jsonData = json.encode(pieceData);
    files.add(http.MultipartFile.fromString('data', jsonData,
        contentType: MediaType('application', 'json')));
  }
}
