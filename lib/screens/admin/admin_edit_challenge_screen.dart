import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class AdminEditChallengeScreen extends StatefulWidget {
  const AdminEditChallengeScreen({super.key});

  @override
  State<AdminEditChallengeScreen> createState() =>
      _AdminEditChallengeScreenState();
}

class _AdminEditChallengeScreenState extends State<AdminEditChallengeScreen> {
  List<Map<String, dynamic>> challenges = [
    {'id': 1, 'name': '달리기 챌린지', 'description': '매일 1km 달리기', 'active': true},
    {'id': 2, 'name': '독서 챌린지', 'description': '하루 30분 독서', 'active': false},
    {'id': 3, 'name': '명상 챌린지', 'description': '10분 명상하기', 'active': true},
  ];

  bool isPopupOpen = false;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  void toggleChallenge(int id) {
    setState(() {
      final challenge = challenges.firstWhere((c) => c['id'] == id);
      challenge['active'] = !challenge['active'];
    });
  }

  void deleteChallenge(int id) {
    setState(() {
      challenges.removeWhere((c) => c['id'] == id);
    });
  }

  void addChallenge() {
    if (nameController.text.trim().isEmpty) return;
    setState(() {
      challenges.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': nameController.text,
        'description': descriptionController.text,
        'active': false,
      });
      nameController.clear();
      descriptionController.clear();
      isPopupOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 2,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '챌린지 관리',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '챌린지를 추가하고 삭제하며 활성화 또는 비활성화할 수 있습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => isPopupOpen = true),
                  child: const Text('챌린지 추가'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      return Card(
                        elevation: 4,
                        color: Colors.white.withOpacity(0.8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                challenge['description'] ?? '',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                challenge['active'] ? '활성화됨' : '비활성화됨',
                                style: TextStyle(
                                  color:
                                      challenge['active']
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () =>
                                              toggleChallenge(challenge['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: Text(
                                        challenge['active'] ? '비활성화' : '활성화',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        () => deleteChallenge(challenge['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isPopupOpen)
            Center(
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '새로운 챌린지 추가',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: '챌린지 제목'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(hintText: '챌린지 내용'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => isPopupOpen = false),
                          child: const Text('취소'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: addChallenge,
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
