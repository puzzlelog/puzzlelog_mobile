import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common_scaffold.dart';

class AdminEditAdsScreen extends StatefulWidget {
  const AdminEditAdsScreen({super.key});

  @override
  State<AdminEditAdsScreen> createState() => _AdminEditAdsScreenState();
}

class _AdminEditAdsScreenState extends State<AdminEditAdsScreen> {
  final Dio dio = Dio();
  final String apiUrl = "https://api.puzzlelog.me/admin/assets";
  List ads = [];
  final TextEditingController adNameController = TextEditingController();
  File? adImage;

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
      setState(() {
        ads =
            response.data['data']
                .where((item) => item['type'] == 'AD')
                .toList();
      });
    } catch (e) {
      print('Error fetching ads: $e');
    }
  }

  Future<void> handleImagePicker() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => adImage = File(pickedFile.path));
    }
  }

  Future<void> handleAddAd() async {
    if (adNameController.text.isEmpty || adImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 필드를 입력해주세요.")));
      return;
    }

    final formData = FormData.fromMap({
      "name": adNameController.text,
      "type": "AD",
      "file": await MultipartFile.fromFile(adImage!.path),
    });

    try {
      final response = await dio.post(
        apiUrl,
        data: formData,
        options: Options(headers: {"userId": "admin"}),
      );
      if (response.data['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("광고 추가 완료")));
        fetchAds();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("광고 추가 중 오류가 발생했습니다.")));
    }
  }

  Future<void> handleDeleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
        options: Options(headers: {"userId": "admin"}),
      );
      if (response.data['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("광고 삭제 완료")));
        fetchAds();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("광고 삭제 중 오류 발생")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '광고 관리',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("새로운 광고 추가"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: adNameController,
                                    decoration: const InputDecoration(
                                      hintText: "광고 이름",
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: handleImagePicker,
                                    child: const Text("이미지 선택"),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("취소"),
                                ),
                                ElevatedButton(
                                  onPressed: handleAddAd,
                                  child: const Text("추가"),
                                ),
                              ],
                            ),
                      ),
                  child: const Text('광고 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: ads.length,
                itemBuilder:
                    (context, index) => Card(
                      child: Column(
                        children: [
                          Image.network(
                            ads[index]['imageUrl'],
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Text(ads[index]['name']),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => handleDeleteAd(ads[index]['id']),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
