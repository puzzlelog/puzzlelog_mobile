import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/common_scaffold.dart';

class WriteVideoPieceScreen extends StatefulWidget {
  const WriteVideoPieceScreen({super.key});

  @override
  State<WriteVideoPieceScreen> createState() => _WriteVideoPieceScreenState();
}

class _WriteVideoPieceScreenState extends State<WriteVideoPieceScreen> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  File? _video;
  bool _useGPS = false;
  bool _loading = false;
  bool _isMuted = true;
  Map<String, dynamic>? _currentLocation;

  final picker = ImagePicker();
  VideoPlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_video == null) return;

    _controller?.dispose();
    _controller = VideoPlayerController.file(_video!);

    await _controller!.initialize();
    await _controller!.setLooping(true);
    await _controller!.setVolume(0.0);
    setState(() {});
  }

  Future<bool> _checkVideoSize(File videoFile) async {
    final fileSize = await videoFile.length();
    final uri = Uri.parse("https://api.puzzlelog.me/pieces");

    final response = await http.head(
      uri,
      headers: {
        'Content-Length': fileSize.toString(),
        'Content-Type': 'video/mp4',
      },
    );

    if (response.statusCode == 200) return true;
    if (response.statusCode == 413) {
      _showDialog("100MB 이하의 영상만 업로드할 수 있습니다.");
    } else {
      _showDialog("파일 크기 확인 중 문제가 발생했습니다.");
    }
    return false;
  }

  Future<void> _pickVideoFromGallery() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final isOk = await _checkVideoSize(file);
      if (!isOk) return;

      setState(() => _video = file);
      await _initializeVideo();
    }
  }

  Future<void> _recordVideo() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final isOk = await _checkVideoSize(file);
      if (!isOk) return;

      setState(() => _video = file);
      await _initializeVideo();
    }
  }

  Future<void> _handleGpsToggle(bool val) async {
    if (val) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showDialog("기기의 GPS가 꺼져 있습니다. 설정에서 켜주세요.");
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          _showDialog("위치 권한이 거부되어 GPS를 사용할 수 없습니다.");
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
        _showDialog("위치 정보를 가져오지 못했습니다.");
      }
    } else {
      setState(() {
        _useGPS = false;
        _currentLocation = null;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
    }
    Position position = await Geolocator.getCurrentPosition();
    return {
      "type": "Point",
      "coordinates": [position.longitude, position.latitude],
    };
  }

  void _handleTagInput(String raw) {
    final clean = raw.replaceAll(',', '').trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() => _tags.add(clean));
    }
    _tagController.clear();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _savePiece() async {
    if (_video == null) {
      _showDialog('비디오를 첨부해주세요.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('accessToken') ?? '';
    if (userId == null) {
      _showDialog('로그인이 필요합니다.');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _loading = true);

    final location = _useGPS ? _currentLocation ?? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "VIDEO",
      "tags": _tags,
      "location": location,
      "isPrivate": false,
    };

    final uri = Uri.parse("https://api.puzzlelog.me/pieces");
    final request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', _video!.path));
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(pieceData),
        contentType: MediaType('application', 'json'),
      ),
    );

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final result = jsonDecode(resBody);

      if (response.statusCode == 200 && result['success']) {
        _showDialog(
          '영상이 저장되었습니다.',
          onClose: () {
            Navigator.pushNamed(context, '/makePiece');
          },
        );
      } else {
        _showDialog(result['message'] ?? '저장에 실패했습니다.');
      }
    } catch (e) {
      _showDialog('서버 오류가 발생했습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showDialog(String msg, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onClose != null) onClose();
                },
                child: const Text('확인'),
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
              "영상 조각 작성",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  _controller == null || !_controller!.value.isInitialized
                      ? const Center(
                        child: Icon(
                          Icons.video_library,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controller!),
                              if (!_controller!.value.isPlaying)
                                const Icon(
                                  Icons.play_arrow,
                                  size: 50,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),
            ),
            if (_controller != null && _controller!.value.isInitialized)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: const Color(0xFF6B4EFF),
                    ),
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _recordVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('비디오 촬영'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickVideoFromGallery,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('갤러리에서 불러오기'),
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
                  onPressed: _loading ? null : _savePiece,
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
