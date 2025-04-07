import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';

class InvitationListScreen extends StatefulWidget {
  const InvitationListScreen({super.key});

  @override
  State<InvitationListScreen> createState() => _InvitationListScreenState();
}

class _InvitationListScreenState extends State<InvitationListScreen> {
  List invitations = [];
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchInvitations();
  }

  Future<void> fetchInvitations() async {
    try {
      final dio = Dio();
      final token = 'test-token'; // TODO: SharedPreferences에서 불러오기

      final res = await dio.get(
        'https://api.puzzlelog.me/invitations?type=my_request',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data['data'] ?? [];
      final filtered =
          data
              .where(
                (inv) =>
                    inv['status'] != 'REJECTED' && inv['status'] != 'ACCEPTED',
              )
              .toList();

      setState(() {
        invitations = filtered;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '초대 목록을 불러오는 데 실패했습니다';
        loading = false;
      });
    }
  }

  Future<void> handleAccept(String invitationId, String diaryId) async {
    try {
      final dio = Dio();
      final token = 'test-token'; // TODO: SharedPreferences에서 불러오기

      await dio.patch(
        'https://api.puzzlelog.me/invitations/$invitationId/accept',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        invitations.removeWhere((inv) => inv['invitationId'] == invitationId);
      });

      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/collaborativeDiaryBox',
          arguments: {'diaryId': diaryId},
        );
      }
    } catch (e) {
      debugPrint('초대 수락 실패: $e');
    }
  }

  Future<void> handleReject(String invitationId) async {
    try {
      final dio = Dio();
      final token = 'test-token'; // TODO: SharedPreferences에서 불러오기

      await dio.patch(
        'https://api.puzzlelog.me/invitations/$invitationId/reject',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        invitations.removeWhere((inv) => inv['invitationId'] == invitationId);
      });
    } catch (e) {
      debugPrint('초대 거절 실패: $e');
    }
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
          child:
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(20),
                    child:
                        invitations.isEmpty
                            ? const Center(
                              child: Text(
                                '받은 초대가 없습니다.',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                            : ListView.builder(
                              itemCount: invitations.length,
                              itemBuilder: (context, index) {
                                final inv = invitations[index];
                                final dateText = DateFormat(
                                  'yyyy년 MM월 dd일',
                                ).format(DateTime.parse(inv['diaryDate']));
                                return Card(
                                  color: Colors.white.withOpacity(0.1),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '날짜: $dateText',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '보낸 사람: ${inv['senderId']}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '상태: ${inv['status']}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed:
                                                  () => handleAccept(
                                                    inv['invitationId'],
                                                    inv['diaryId'],
                                                  ),
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.3),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('수락'),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              onPressed:
                                                  () => handleReject(
                                                    inv['invitationId'],
                                                  ),
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.3),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('거절'),
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
        ),
      ),
    );
  }
}
