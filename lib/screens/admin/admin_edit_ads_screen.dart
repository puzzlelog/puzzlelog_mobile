import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class AdminEditAdsScreen extends StatefulWidget {
  const AdminEditAdsScreen({super.key});

  @override
  State<AdminEditAdsScreen> createState() => _AdminEditAdsScreenState();
}

class _AdminEditAdsScreenState extends State<AdminEditAdsScreen> {
  final Dio dio = Dio();
  final String apiUrl = "https://api.puzzlelog.me/assets";
  List ads = [];
  File? adImage;
  final TextEditingController adNameController = TextEditingController();
  String? token;
  String? userId;
  String? role;
  String? errorMessage;
  bool isLoading = true;

  int currentPage = 1;
  final int itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _checkAdminAndFetchAds();
  }

  Future<void> _checkAdminAndFetchAds() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken');
    userId = prefs.getString('userId');
    role = prefs.getString('role');

    if (token == null || userId == null || role != 'ADMIN') {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('관리자만 접근 가능합니다.')));
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    await fetchAds();
  }

  Future<void> fetchAds() async {
    setState(() => isLoading = true);
    try {
      final response = await dio.get(
        apiUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId},
        ),
      );

      final List loaded =
          response.data['data'].where((item) => item['type'] == 'AD').toList();

      setState(() {
        ads = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '광고 목록을 불러오는 중 오류 발생';
        isLoading = false;
      });
    }
  }

  List get paginatedAds {
    final start = (currentPage - 1) * itemsPerPage;
    final end =
        (start + itemsPerPage) > ads.length ? ads.length : start + itemsPerPage;
    return ads.sublist(start, end);
  }

  Future<void> handleImagePicker() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => adImage = File(picked.path));
    }
  }

  Future<void> handleAddAd() async {
    if (adNameController.text.isEmpty || adImage == null) {
      setState(() => errorMessage = "모든 필드를 입력해주세요.");
      return;
    }

    final formData = FormData.fromMap({
      'name': adNameController.text,
      'type': 'AD',
      'file': await MultipartFile.fromFile(adImage!.path),
      'tag': '광고',
    });

    try {
      final response = await dio.post(
        apiUrl,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId},
        ),
      );

      if (response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('광고 추가 완료')));
        }
        adNameController.clear();
        adImage = null;
        Navigator.pop(context);
        await fetchAds();
      }
    } catch (e) {
      setState(() => errorMessage = '광고 추가 중 오류 발생');
    }
  }

  Future<void> handleDeleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("정말 삭제하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("삭제"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await dio.delete(
        "$apiUrl/$adId",
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId},
        ),
      );

      if (response.data['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("광고 삭제 완료")));
        await fetchAds();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("광고 삭제 중 오류 발생")));
    }
  }

  void openAddPopup() {
    setState(() => errorMessage = null);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("새로운 광고 추가"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adNameController,
                  decoration: const InputDecoration(hintText: "광고 이름"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: handleImagePicker,
                  child: const Text("이미지 선택"),
                ),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              ElevatedButton(onPressed: handleAddAd, child: const Text("추가")),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (ads.length / itemsPerPage).ceil();

    return CommonScaffold(
      currentIndex: null,
      appBar: AppBar(
        title: const Text("광고 관리"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openAddPopup,
            tooltip: "광고 추가",
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: paginatedAds.length,
                      itemBuilder: (_, index) {
                        final ad = paginatedAds[index];
                        return Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.network(
                                  ad['mediaId'] ?? ad['imageUrl'] ?? '',
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ad['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => handleDeleteAd(ad['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              currentPage > 1
                                  ? () => setState(() => currentPage--)
                                  : null,
                          child: const Text("이전"),
                        ),
                        const SizedBox(width: 16),
                        Text('$currentPage / $totalPages'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed:
                              currentPage < totalPages
                                  ? () => setState(() => currentPage++)
                                  : null,
                          child: const Text("다음"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
