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
  final TextEditingController _tagsController = TextEditingController();
  File? _video;
  bool _useGPS = false;
  bool _loading = false;

  final picker = ImagePicker();

  VideoPlayerController? _controller;

  Future<void> _initializeVideo() async {
    if (_video == null) return;

    _controller?.dispose();
    _controller = VideoPlayerController.file(_video!);

    await _controller!.initialize();
    await _controller!.setLooping(true);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controller!.play();
        setState(() {});
      }
    });
  }

  Future<void> _pickVideoFromGallery() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _video = File(pickedFile.path));
      await _initializeVideo();
    }
  }

  Future<void> _recordVideo() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _video = File(pickedFile.path));
      await _initializeVideo();
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

    final tags =
        _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final location = _useGPS ? await _getLocation() : null;

    final pieceData = {
      "userId": userId,
      "type": "VIDEO",
      "tags": tags,
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
          '비디오가 저장되었습니다.',
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
      onTap: (_) {},
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Video Piece",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  _controller == null || !_controller!.value.isInitialized
                      ? const Icon(
                        Icons.video_library,
                        size: 100,
                        color: Colors.black54,
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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
                                  color: Colors.white,
                                  size: 50,
                                ),
                            ],
                          ),
                        ),
                      ),
            ),
            ElevatedButton(
              onPressed: _pickVideoFromGallery,
              child: const Text('갤러리에서 불러오기'),
            ),
            ElevatedButton(
              onPressed: _recordVideo,
              child: const Text('비디오 촬영'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "태그 입력 (쉼표로 구분)",
              ),
            ),
            const SizedBox(height: 10),
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
                  onPressed: _loading ? null : _savePiece,
                  child: Text(_loading ? "저장 중..." : "저장하기"),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("뒤로가기"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
