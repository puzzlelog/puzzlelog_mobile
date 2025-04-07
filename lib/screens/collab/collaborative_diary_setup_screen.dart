import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class CollaborativeDiarySetupScreen extends StatefulWidget {
  const CollaborativeDiarySetupScreen({super.key});

  @override
  State<CollaborativeDiarySetupScreen> createState() =>
      _CollaborativeDiarySetupScreenState();
}

class _CollaborativeDiarySetupScreenState
    extends State<CollaborativeDiarySetupScreen> {
  String? selectedDate;
  List<Map<String, dynamic>> friends = [];
  List<String> selectedFriendIds = [];
  String? error;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    // TODO: 실제 API 요청을 통해 친구 목록 불러오기
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      friends = List.generate(
        10,
        (i) => {'friendId': 'friend$i', 'nickname': '친구 $i'},
      );
    });
  }

  void toggleFriend(String id) {
    setState(() {
      if (selectedFriendIds.contains(id)) {
        selectedFriendIds.remove(id);
      } else {
        selectedFriendIds.add(id);
      }
    });
  }

  void handleNext() {
    if (selectedDate == null) {
      setState(() => error = '날짜를 선택하세요.');
      return;
    }
    if (selectedFriendIds.isEmpty) {
      setState(() => error = '최소 한 명 이상의 친구를 선택하세요.');
      return;
    }

    Navigator.pushNamed(
      context,
      '/collaborative-select-pieces',
      arguments: {'date': selectedDate, 'friendIds': selectedFriendIds},
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '협업 일기 생성 및 초대',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const Text(
                  '날짜 선택',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate =
                            picked.toIso8601String().split('T').first;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '날짜를 선택하세요',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  controller: TextEditingController(text: selectedDate),
                ),
                const SizedBox(height: 24),
                const Text(
                  '친구 선택 (복수 선택 가능)',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = selectedFriendIds.contains(
                        friend['friendId'],
                      );
                      return ListTile(
                        onTap: () => toggleFriend(friend['friendId']),
                        leading: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.pinkAccent
                                    : Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : null,
                        ),
                        title: Text(
                          friend['nickname'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('협업 요청 보내기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
