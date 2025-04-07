import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final Dio dio = Dio();
  final String apiUrl = 'https://api.puzzlelog.me/admin/assets';
  List ads = [];
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  Future<void> fetchAds() async {
    try {
      final response = await dio.get(
        apiUrl,
        options: Options(headers: {"userId": "admin"}),
      );
      final data =
          response.data['data'].where((item) => item['type'] == 'AD').toList();

      if (mounted) {
        setState(() => ads = data);
        if (data.length > 1) startRotation();
      }
    } catch (e) {
      debugPrint('광고 데이터 불러오기 실패: $e');
    }
  }

  void startRotation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted && ads.isNotEmpty) {
        setState(() {
          currentIndex = (currentIndex + 1) % ads.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) return const SizedBox.shrink();

    final ad = ads[currentIndex];
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: IgnorePointer(
        child: Image.network(
          ad['imageUrl'],
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Center(child: Text('광고 이미지 로드 실패')),
        ),
      ),
    );
  }
}
