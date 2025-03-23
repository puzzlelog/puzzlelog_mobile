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
    {'id': 1, 'name': '달리기 챌린지', 'active': true},
    {'id': 2, 'name': '독서 챌린지', 'active': false},
    {'id': 3, 'name': '명상 챌린지', 'active': true},
  ];

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

  void addChallenge(String name, String description) {
    setState(() {
      challenges.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'description': description,
        'active': false,
      });
    });
  }

  void showAddChallengeDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새로운 챌린지 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: '챌린지 제목'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: '챌린지 내용'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              addChallenge(nameController.text, descriptionController.text);
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '챌린지 관리',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: showAddChallengeDialog,
              child: const Text('챌린지 추가'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text(challenge['name']),
                      subtitle: Text(
                        challenge['active'] ? '활성화됨' : '비활성화됨',
                        style: TextStyle(
                          color:
                              challenge['active'] ? Colors.green : Colors.red,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              challenge['active']
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                              color: challenge['active']
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () => toggleChallenge(challenge['id']),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => deleteChallenge(challenge['id']),
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
    );
  }
}