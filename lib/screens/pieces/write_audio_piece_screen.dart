import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';

import '../../widgets/common_scaffold.dart';

class WriteAudioPieceScreen extends StatefulWidget {
  const WriteAudioPieceScreen({super.key});

  @override
  _WriteAudioPieceScreenState createState() => _WriteAudioPieceScreenState();
}

class _WriteAudioPieceScreenState extends State<WriteAudioPieceScreen> {
  final TextEditingController _tagsController = TextEditingController();
  bool _loading = false;
  bool _useGPS = false;
  bool _isGPSEnabled = false;
  String? _audioPath;
  final _audioRecorder = AudioRecorder();

  final String apiBaseUrl = "https://api.puzzlelog.me/pieces";

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
    Position position = await Geolocator.getCurrentPosition();
    return {
      "type": "Point",
      "coordinates": [position.longitude, position.latitude],
    };
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      setState(() => _audioPath = result.files.single.path);
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(const RecordConfig(), path: 'audio_piece.mp3');
      setState(() => _loading = true);
    } else {
      _showAlert("마이크 권한이 필요합니다.");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _loading = false;
      _audioPath = path;
    });
  }

  Future<void> _handleSave() async {
    if (_audioPath == null) {
      _showAlert("오디오를 녹음하거나 선택해주세요.");
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

    final tagArray =
        _tagsController.text
            .split(",")
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    final location = _useGPS ? await _getLocation() : null;

    final request = http.MultipartRequest('POST', Uri.parse(apiBaseUrl));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _audioPath!,
        contentType: MediaType('audio', 'mpeg'),
      ),
    );
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        json.encode({
          "userId": userId,
          "type": "AUDIO",
          "tags": tagArray,
          "location": location,
          "isPrivate": false,
        }),
        contentType: MediaType('application', 'json'),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final result = json.decode(responseBody);

    if (response.statusCode == 200 && result['success']) {
      _showAlert("오디오가 저장되었습니다.");
      _tagsController.clear();
      setState(() => _audioPath = null);
      Navigator.pushNamed(context, '/makePiece');
    } else {
      _showAlert(result['message'] ?? "저장 실패");
    }

    setState(() => _loading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Audio Piece",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _audioPath == null ? _startRecording : _stopRecording,
              child: Text(_audioPath == null ? "녹음 시작" : "녹음 중지"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _pickAudioFile,
              child: const Text("오디오 불러오기"),
            ),
            const SizedBox(height: 30),

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

            const SizedBox(height: 20),

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
