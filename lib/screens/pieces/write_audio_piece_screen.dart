import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

import '../../widgets/common_scaffold.dart';

class WriteAudioPieceScreen extends StatefulWidget {
  const WriteAudioPieceScreen({super.key});

  @override
  _WriteAudioPieceScreenState createState() => _WriteAudioPieceScreenState();
}

class _WriteAudioPieceScreenState extends State<WriteAudioPieceScreen> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  String? _audioPath;
  bool _useGPS = false;
  bool _loading = false;
  double _volume = 1.0;

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final String apiBaseUrl = "https://api.puzzlelog.me/pieces";

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _handleTagInput(String raw) {
    final clean = raw.replaceAll(',', '').trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() => _tags.add(clean));
    }
    _tagController.clear();
  }

  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isCompleted = state.processingState == ProcessingState.completed;
      });
    });
    _audioPlayer.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });
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

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: 'audio_piece.aac',
      );
      setState(() => _loading = true);
    } else {
      _showAlert("마이크 권한이 필요합니다.");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _audioPath = path;
      _loading = false;
    });
    if (_audioPath != null) {
      await _audioPlayer.setFilePath(_audioPath!);
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _audioPath = result.files.single.path!;
      await _audioPlayer.setFilePath(_audioPath!);
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    if (_isCompleted) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play();
    }
  }

  Future<void> _handleSave() async {
    if (_audioPath == null) {
      _showAlert("오디오를 녹음하거나 선택해주세요.");
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

    final location = _useGPS ? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "AUDIO",
      "tags": _tags,
      "location": location,
      "isPrivate": false,
    };

    final request = http.MultipartRequest('POST', Uri.parse(apiBaseUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _audioPath!,
        contentType: MediaType('audio', 'aac'),
      ),
    );
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        json.encode(pieceData),
        contentType: MediaType('application', 'json'),
      ),
    );

    final response = await request.send();
    final result = json.decode(await response.stream.bytesToString());

    if (response.statusCode == 200 && result['success']) {
      _showAlert("오디오가 저장되었습니다.");
      setState(() {
        _tags.clear();
        _audioPath = null;
      });
      Navigator.pushNamed(context, '/makePiece');
    } else {
      _showAlert(result['message'] ?? "저장 실패");
    }

    setState(() => _loading = false);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
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
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "음성 조각 작성",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ✅ 🎧 미리듣기 UI를 위로 이동
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _audioPath == null
                        ? Icons.play_disabled
                        : (_isCompleted
                            ? Icons.replay
                            : (_isPlaying ? Icons.pause : Icons.play_arrow)),
                    size: 40,
                    color: Color(0xFF6B4EFF),
                  ),
                  onPressed: _audioPath == null ? null : _togglePlayback,
                ),
                const SizedBox(height: 4),
                Text(
                  _audioPath == null
                      ? "00:00 / 00:00"
                      : "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                  style: const TextStyle(fontSize: 12),
                ),
                Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  onChanged: (val) {
                    setState(() => _volume = val);
                    _audioPlayer.setVolume(val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ 🎤 녹음/불러오기 버튼
            ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : (_audioPath == null ? _startRecording : _stopRecording),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
              ),
              child: Text(_audioPath == null ? "녹음 시작" : "녹음 중지"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _pickAudioFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
              ),
              child: const Text("오디오 불러오기"),
            ),

            const SizedBox(height: 20),

            // ✅ 🏷 태그
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

            // ✅ 📍 GPS + 저장 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _useGPS,
                      onChanged: (val) => setState(() => _useGPS = val),
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

            // ✅ 🔙 뒤로가기 버튼
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
