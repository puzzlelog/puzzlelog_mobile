import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/common_scaffold.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;
  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  Map<String, dynamic>? diaryData;
  String? backgroundURL;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiaryDetails();
  }

  Future<void> fetchDiaryDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final dio = Dio();
    try {
      final response = await dio.get(
        'https://api.puzzlelog.me/diaries/${widget.diaryId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        final diary = response.data['data'];
        setState(() => diaryData = diary);
        await fetchBackgroundImage(diary['backgroundContentId']);
      }
    } catch (e) {
      debugPrint('일기 상세 불러오기 실패: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchBackgroundImage(String contentId) async {
    if (contentId == "default-background-id") return;

    try {
      final res = await Dio().get('https://api.puzzlelog.me/assets/$contentId');
      if (res.statusCode == 200 && res.data['success']) {
        setState(() => backgroundURL = res.data['data']['mediaId']);
      }
    } catch (e) {
      debugPrint('배경 이미지 로딩 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      appBar: AppBar(title: Text(diaryData?['title'] ?? '일기 상세')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : diaryData == null
              ? const Center(child: Text('일기 정보를 불러올 수 없습니다.'))
              : Stack(
                children: [
                  if (backgroundURL != null)
                    CachedNetworkImage(
                      imageUrl: backgroundURL!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ..._buildDiaryElements(diaryData!['elements'] ?? []),
                ],
              ),
    );
  }

  List<Widget> _buildDiaryElements(List<dynamic> elements) {
    return elements.map<Widget>((element) {
      final List position = element['position'] ?? [0, 0];
      final double scale = (element['scale'] ?? 1.0).toDouble();
      final double rotation = (element['rotation'] ?? 0.0).toDouble();
      final double left = position[0].toDouble();
      final double top = position[1].toDouble();

      switch (element['elementType']) {
        case 'IMAGE':
        case 'STICKER':
          return Positioned(
            left: left,
            top: top,
            child: Transform.rotate(
              angle: rotation * 3.141592 / 180,
              child: CachedNetworkImage(
                imageUrl: element['contentId'],
                width: 100 * scale,
                height: 100 * scale,
              ),
            ),
          );
        case 'TEXT':
          return Positioned(
            left: left,
            top: top,
            child: Transform.rotate(
              angle: rotation * 3.141592 / 180,
              child: Text(
                element['text'] ?? '',
                style: TextStyle(fontSize: 24 * scale, color: Colors.black),
              ),
            ),
          );
        case 'DRAWING':
          if (element['drawingData'] != null) {
            return Positioned(
              left: left,
              top: top,
              child: Transform.scale(
                scale: scale,
                child: SvgPicture.string(
                  Uri.decodeComponent(element['drawingData']),
                  width: 200,
                  height: 200,
                ),
              ),
            );
          }
          return const SizedBox();
        case 'DATE':
          return Positioned(
            left: left,
            top: top,
            child: Text(
              element['date'] ?? '',
              style: TextStyle(fontSize: 20 * scale, color: Colors.grey),
            ),
          );
        case 'VIDEO':
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(element['contentId']),
          )..initialize();
          return Positioned(
            left: left,
            top: top,
            child: SizedBox(
              width: 150 * scale,
              height: 150 * scale,
              child: VideoPlayer(controller),
            ),
          );
        case 'AUDIO':
          final player = AudioPlayer()..setUrl(element['contentId']);
          return Positioned(
            left: left,
            top: top,
            child: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => player.play(),
            ),
          );
        default:
          return const SizedBox();
      }
    }).toList();
  }
}
