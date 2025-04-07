import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';
import '../../widgets/admin/admin_header.dart';

class AdminPageScreen extends StatelessWidget {
  const AdminPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Column(
        children: [
          const AdminHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '환영합니다, 관리자님',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4F35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '여기에서 스티커 추가, 광고 수정 및 챌린지 활성화를 관리할 수 있습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                    children: [
                      _adminCard(
                        context,
                        title: '스티커 관리',
                        buttonText: '스티커 추가',
                        route: '/adminEditAsset',
                      ),
                      _adminCard(
                        context,
                        title: '광고 관리',
                        buttonText: '광고 수정',
                        route: '/adminEditAds',
                      ),
                      _adminCard(
                        context,
                        title: '챌린지 관리',
                        buttonText: '챌린지 활성화',
                        route: '/adminEditChallenge',
                        spanTwo: true,
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

  Widget _adminCard(
    BuildContext context, {
    required String title,
    required String buttonText,
    required String route,
    bool spanTwo = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, route),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.3),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
