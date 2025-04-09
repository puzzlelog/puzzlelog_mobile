import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class AdminEditAssetScreen extends StatefulWidget {
  const AdminEditAssetScreen({super.key});

  @override
  State<AdminEditAssetScreen> createState() => _AdminEditAssetScreenState();
}

class _AdminEditAssetScreenState extends State<AdminEditAssetScreen> {
  final dio = Dio();
  final nameController = TextEditingController();
  String? token, userId, role;

  List allAssets = [], filteredAssets = [];
  String selectedType = 'ALL';
  String selectedAssetType = 'emoji';
  int currentPage = 1;
  final int itemsPerPage = 12;

  File? selectedImage;
  String? errorMessage;

  final Map<String, String> categoryKorean = {
    'ALL': '전체',
    'BACKGROUND': '배경',
    'emotion': '감정 이모션',
    'dolls': '인형',
    'audio': '오디오',
    'camera': '카메라',
    'daily': '일상',
    'emoji': '이모지',
    'food': '음식',
    'number': '숫자',
    'language': '언어',
    'tape': '테이프',
    'vintage': '빈티지',
  };

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken');
    userId = prefs.getString('userId');
    role = prefs.getString('role');

    if (token == null || userId == null || role != 'ADMIN') {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("관리자만 접근 가능합니다.")));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      fetchAssets();
    }
  }

  Future<void> fetchAssets() async {
    try {
      final response = await dio.get(
        'https://api.puzzlelog.me/assets',
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId!},
        ),
        queryParameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      );

      final all =
          response.data['data'].where((e) => e['type'] != 'AD').toList();

      setState(() {
        allAssets = all;
        _applyFilter();
      });
    } catch (e) {
      setState(() => errorMessage = '에셋 불러오기 실패');
    }
  }

  void _applyFilter() {
    setState(() {
      filteredAssets =
          selectedType == 'ALL'
              ? allAssets
              : allAssets.where((a) => a['type'] == selectedType).toList();
      currentPage = 1;
    });
  }

  List get currentAssets {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return filteredAssets.sublist(
      start,
      end > filteredAssets.length ? filteredAssets.length : end,
    );
  }

  Future<void> handleAddAsset() async {
    if (nameController.text.isEmpty || selectedImage == null) {
      setState(() => errorMessage = '모든 필드를 입력해주세요.');
      return;
    }

    final formData = FormData.fromMap({
      'name': nameController.text,
      'type': selectedAssetType,
      'file': await MultipartFile.fromFile(selectedImage!.path),
      'tag': selectedAssetType,
    });

    try {
      final res = await dio.post(
        'https://api.puzzlelog.me/assets',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId!},
        ),
      );

      if (res.data['success']) {
        Navigator.pop(context);
        nameController.clear();
        selectedImage = null;
        selectedAssetType = 'emoji';
        await fetchAssets();
      } else {
        setState(() => errorMessage = '에셋 추가 실패: ${res.data['message']}');
      }
    } catch (e) {
      setState(() => errorMessage = '에셋 추가 실패');
    }
  }

  Future<void> handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('삭제 확인'),
            content: const Text('정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await dio.delete(
        'https://api.puzzlelog.me/assets/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId!},
        ),
      );
      await fetchAssets();
    } catch (e) {
      print('삭제 실패: $e');
    }
  }

  Future<void> toggleLockByTag() async {
    if (selectedType == 'ALL') return;

    try {
      await dio.patch(
        'https://api.puzzlelog.me/assets/lock-by-tag',
        data: {'tag': selectedType, 'locked': true},
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'userId': userId!},
        ),
      );
      await fetchAssets();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$selectedType 카테고리 잠금 완료')));
    } catch (e) {
      print('잠금 실패: $e');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  void openAddPopup() {
    errorMessage = null;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("새로운 에셋 추가"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: "에셋 이름"),
                ),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items:
                      categoryKorean.keys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text(categoryKorean[key]!),
                        );
                      }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedType = v;
                        _applyFilter();
                      });
                    }
                  },
                ),
                TextButton(onPressed: pickImage, child: const Text("이미지 선택")),
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
              ElevatedButton(
                onPressed: handleAddAsset,
                child: const Text("추가"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredAssets.length / itemsPerPage).ceil();

    return CommonScaffold(
      currentIndex: null,
      appBar: AppBar(
        title: const Text('에셋 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items:
                        [
                              'ALL',
                              'BACKGROUND',
                              'emotion',
                              'dolls',
                              'audio',
                              'camera',
                              'daily',
                              'emoji',
                              'food',
                              'number',
                              'language',
                              'tape',
                              'vintage',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedType = v;
                          _applyFilter();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: openAddPopup,
                  child: const Text("에셋 추가"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: toggleLockByTag,
                  child: const Text("잠금"),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: currentAssets.length,
              itemBuilder: (_, index) {
                final asset = currentAssets[index];
                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            asset['mediaId'] != null
                                ? Image.network(
                                  asset['mediaId'],
                                  fit: BoxFit.contain,
                                )
                                : const Icon(Icons.broken_image),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          asset['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(asset['type']),
                      Text(asset['locked'] == true ? '🔒 잠금됨' : '🔓 사용 가능'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => handleDelete(asset['id']),
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
                  child: const Text('이전'),
                ),
                const SizedBox(width: 16),
                Text('$currentPage / $totalPages'),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                  child: const Text('다음'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
