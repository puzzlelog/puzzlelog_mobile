import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';

class AdminPageScreen extends StatelessWidget {
  const AdminPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환영합니다, 관리자님',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800]),
            ),
            const SizedBox(height: 10),
            const Text(
              '여기에서 스티커 추가, 광고 수정 및 챌린지 활성화를 관리할 수 있습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 3 / 2,
              children: [
                _adminCard(
                  context,
                  title: '스티커 관리',
                  buttonText: '스티커 추가',
                  route: '/adminEditSticker',
                ),
                _adminCard(
                  context,
                  title: '광고 관리',
                  buttonText: '광고 수정',
                  route: '/adminEditAds',
                ),
                GridTile(
                  child: _adminCard(
                    context,
                    title: '챌린지 관리',
                    buttonText: '챌린지 활성화',
                    route: '/adminEditChallenge',
                    crossAxisSpan: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(BuildContext context,
      {required String title,
      required String buttonText,
      required String route,
      int crossAxisSpan = 1}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, route),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}