import 'package:flutter/material.dart';

// 홈
import 'screens/home_screen.dart';

// 인증 관련
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';

// 사용자 관련
import 'screens/user/my_page_screen.dart';
import 'screens/user/friend_screen.dart';

// 조각(piece) 관련
import 'screens/pieces/make_piece_screen.dart';
import 'screens/pieces/write_text_piece_screen.dart';
import 'screens/pieces/write_image_piece_screen.dart';
import 'screens/pieces/write_video_piece_screen.dart';
import 'screens/pieces/write_audio_piece_screen.dart';
import 'screens/pieces/piece_box_screen.dart';

// 다이어리 및 타임캡슐 관련
import 'screens/diary_timecapsule/diary_box_screen.dart';
import 'screens/diary_timecapsule/make_diary_screen.dart';
import 'screens/diary_timecapsule/piece_box_make_diary_screen.dart';
import 'screens/diary_timecapsule/timecapsule_box_screen.dart';

// 캘린더 및 챌린지
import 'screens/calendar_challenge/calendar_screen.dart';
import 'screens/calendar_challenge/challenge_screen.dart';

// 커뮤니티 관련
import 'screens/community/community_page_screen.dart';
import 'screens/community/upload_post_screen.dart';
import 'screens/community/post_list_screen.dart';
import 'screens/community/post_detail_page_screen.dart';

// 디지털 앨범 관련
import 'screens/album/digital_album_list_screen.dart';
import 'screens/album/new_album_page_screen.dart';
import 'screens/album/album_detail_screen.dart';

// 관리자(admin) 관련
import 'screens/admin/admin_page_screen.dart';
import 'screens/admin/admin_edit_challenge_screen.dart';
import 'screens/admin/admin_edit_asset_screen.dart';
import 'screens/admin/admin_edit_ads_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuzzleLog',
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        // 홈
        '/home': (context) => const HomeScreen(),

        // 인증 (회원가입/로그인)
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),

        // 사용자 (마이페이지/친구)
        '/myPage': (context) => const MyPageScreen(),
        '/friend': (context) => const FriendScreen(),

        // 조각 관리 (pieces)
        '/makePiece': (context) => const MakePieceScreen(),
        '/writeTextPiece': (context) => const WriteTextPieceScreen(),
        '/writeImagePiece': (context) => const WriteImagePieceScreen(),
        '/writeVideoPiece': (context) => const WriteVideoPieceScreen(),
        '/writeAudioPiece': (context) => const WriteAudioPieceScreen(),
        '/pieceBox': (context) => const PieceBoxScreen(),

        // 다이어리 & 타임캡슐
        '/diaryBox': (context) => const DiaryBoxScreen(),
        '/makeDiary': (context) => MakeDiaryScreen(selectedPieces: []),
        '/pieceBoxMakeDiary': (context) => const PieceBoxMakeDiaryScreen(),
        '/timecapsuleBox': (context) => const TimecapsuleBoxScreen(),

        // 캘린더 & 챌린지
        '/calendar': (context) => const CalendarScreen(),
        '/challenge': (context) => const ChallengeScreen(),

        // 커뮤니티
        '/community': (context) => const CommunityPageScreen(),
        '/uploadPost': (context) => const UploadPostScreen(),
        '/postList': (context) => const PostListScreen(),
        '/postDetailPage': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
            final postId = args['postId'];
            return PostDetailPageScreen(postId: postId);
          },

        // 디지털 앨범
        '/digitalAlbum': (context) => const DigitalAlbumListScreen(),
        '/albumNew': (context) => const NewAlbumPageScreen(),
        '/albumDetail': (context) {
            final albumId = ModalRoute.of(context)?.settings.arguments as String;
            return AlbumDetailScreen(albumId: albumId);
          },

        // 관리자(admin)
        '/adminPage': (context) => const AdminPageScreen(),
        '/adminEditChallenge': (context) => const AdminEditChallengeScreen(),
        '/adminEditAsset': (context) => const AdminEditAssetScreen(),
        '/adminEditAds': (context) => const AdminEditAdsScreen(),
      },
    );
  }
}