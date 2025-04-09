import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

// 홈
import 'screens/home_screen.dart';

// 인증
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

// 사용자
import 'screens/user/my_page_screen.dart';
import 'screens/user/friend_screen.dart';
import 'screens/user/invitation_list_screen.dart';

// 조각 (Piece)
import 'screens/pieces/make_piece_screen.dart';
import 'screens/pieces/piece_box_screen.dart';
import 'screens/pieces/write_text_piece_screen.dart';
import 'screens/pieces/write_image_piece_screen.dart';
import 'screens/pieces/write_video_piece_screen.dart';
import 'screens/pieces/write_audio_piece_screen.dart';

// 일기 (Diary)
import 'screens/diary/make_diary_screen.dart';
import 'screens/diary/diary_box_screen.dart';
import 'screens/diary/write_normal_diary_screen.dart';
import 'screens/diary/write_timecapsule_diary_screen.dart';
import 'screens/diary/write_collaborative_diary_screen.dart';

// 커뮤니티
import 'screens/community/community_page_screen.dart';
import 'screens/community/upload_post_screen.dart';
import 'screens/community/post_list_screen.dart';
import 'screens/community/post_detail_page_screen.dart';

// 캘린더 & 챌린지
import 'screens/calendar_challenge/calendar_screen.dart';
import 'screens/calendar_challenge/challenge_screen.dart';

// 디지털 앨범
import 'screens/album/digital_album_list_screen.dart';
import 'screens/album/new_album_page_screen.dart';
import 'screens/album/album_detail_screen.dart';

// 관리자
import 'screens/admin/admin_page_screen.dart';
import 'screens/admin/admin_edit_challenge_screen.dart';
import 'screens/admin/admin_edit_asset_screen.dart';
import 'screens/admin/admin_edit_ads_screen.dart';

// 공통 위젯
import 'widgets/ad_banner.dart';
import 'screens/user/settings_screen.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class AuthGuardObserver extends NavigatorObserver {
  final List<String> publicRoutes = ['/', '/login', '/signup'];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;

    if (name == null || publicRoutes.contains(name)) return;

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      // 토큰이 없고, 이미 /login이나 /signup이 아니라면 /login으로 보냄
      if ((token == null || token.isEmpty) &&
          navigator?.widget.initialRoute != '/login') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // pushReplacementNamed가 중복 호출되지 않도록 현재 경로 체크
          if (navigator?.canPop() == false || route.settings.name != '/login') {
            navigator?.pushReplacementNamed('/login');
          }
        });
      }
    });

    super.didPush(route, previousRoute);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuzzleLog',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      navigatorObservers: [AuthGuardObserver()],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final path = ModalRoute.of(context)?.settings.name;
        final excludedPaths = [
          '/',
          '/login',
          '/signup',
          '/adminPage',
          '/adminEditChallenge',
          '/adminEditAsset',
          '/adminEditAds',
        ];

        return Stack(
          children: [
            child,
            if (path != null && !excludedPaths.contains(path))
              const Positioned(bottom: 0, left: 0, right: 0, child: AdBanner()),
          ],
        );
      },
      routes: {
        // 공개 경로
        '/': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),

        // 사용자
        '/myPage': (context) => const MyPageScreen(),
        '/friend': (context) => const FriendScreen(),
        '/invitations': (context) => const InvitationListScreen(),

        // 조각 (Piece)
        '/makePiece': (context) => const MakePieceScreen(),
        '/pieceBox': (context) => const PieceBoxScreen(),
        '/writeTextPiece': (context) => const WriteTextPieceScreen(),
        '/writeImagePiece': (context) => const WriteImagePieceScreen(),
        '/writeVideoPiece': (context) => const WriteVideoPieceScreen(),
        '/writeAudioPiece': (context) => const WriteAudioPieceScreen(),

        // 일기 (Diary)
        '/makeDiary': (context) => const MakeDiaryScreen(),
        '/diaryBox': (context) => const DiaryBoxScreen(),
        '/writeNormalDiary': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final selectedPieces =
              args?['selectedPieces'] as List<Map<String, dynamic>>? ?? [];

          return WriteNormalDiaryScreen(selectedPieces: selectedPieces);
        },
        '/writeTimecapsuleDiary':
            (context) => const WriteTimecapsuleDiaryScreen(),
        '/writeCollaborativeDiary':
            (context) => const WriteCollaborativeDiaryScreen(),

        // 캘린더 & 챌린지
        '/calendar': (context) => const CalendarScreen(),
        '/challenge': (context) => const ChallengeScreen(),

        // 커뮤니티
        '/community': (context) => const CommunityPageScreen(),
        '/uploadPost': (context) => const UploadPostScreen(),
        '/postList': (context) => const PostListScreen(),
        '/postDetail': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>;
          return PostDetailPageScreen(postId: args['postId']);
        },

        // 디지털 앨범
        '/digitalAlbum': (context) => const DigitalAlbumListScreen(),
        '/albumNew': (context) => const NewAlbumPageScreen(),
        '/albumDetail': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>;
          final albumId = args['albumId'] as String;
          return AlbumDetailScreen(albumId: albumId);
        },

        // 관리자
        '/adminPage': (context) => const AdminPageScreen(),
        '/adminEditChallenge': (context) => const AdminEditChallengeScreen(),
        '/adminEditAsset': (context) => const AdminEditAssetScreen(),
        '/adminEditAds': (context) => const AdminEditAdsScreen(),

        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
