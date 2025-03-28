import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminEditAssetScreen extends StatefulWidget {
  const AdminEditAssetScreen({super.key});

  @override
  State<AdminEditAssetScreen> createState() => _AdminEditAssetScreenState();
}

class _AdminEditAssetScreenState extends State<AdminEditAssetScreen> {
  final dio = Dio();
  String userId = '';

  List<dynamic> assets = [];

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    if (userId != 'admin') {
      if (mounted) Navigator.pop(context);
    } else {
      fetchAssets();
    }
  }

  Future<void> fetchAssets() async {
    try {
      final response = await dio.get(
        'https://api.puzzlelog.me/api/admin/assets',
        options: Options(headers: {'userId': userId}),
      );

      setState(() {
        assets =
            response.data['data']
                .where((item) => item['type'] != 'AD')
                .toList();
      });
    } catch (e) {
      print('에셋 목록 로딩 실패: $e');
    }
  }

  Future<void> deleteAsset(String assetId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('에셋 삭제'),
            content: const Text('정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('확인'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await dio.delete(
        'https://api.puzzlelog.me/api/admin/assets/$assetId',
        options: Options(headers: {'userId': userId}),
      );
      fetchAssets();
    } catch (e) {
      print('에셋 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '에셋 관리',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child:
                            asset['imageUrl'] != null
                                ? Image.network(
                                  asset['imageUrl'],
                                  fit: BoxFit.cover,
                                )
                                : const Center(child: Text('이미지 없음')),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        asset['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(asset['type'], style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteAsset(asset['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
