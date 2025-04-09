import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';
import 'admin_logout.dart';

class AdminPageScreen extends StatelessWidget {
  const AdminPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: null,
      body: Stack(
        children: [
          Column(
            children: [
              // 기존 상단 환영 메시지 & 카드들
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '환영합니다, 관리자님',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '스티커, 광고, 챌린지를 관리할 수 있습니다.',
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ✅ 오른쪽 하단 로그아웃 버튼 고정
          const Positioned(
            right: 20,
            bottom: 20,
            child: AdminLogoutFloatingButton(),
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
    return SizedBox(
      width:
          spanTwo
              ? MediaQuery.of(context).size.width - 56
              : (MediaQuery.of(context).size.width - 72) / 2,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, route),
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
