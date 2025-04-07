# 🧩 PuzzleLog Mobile App (Flutter)

**PuzzleLog**는 텍스트, 이미지, 오디오, 비디오 조각을 통해
하나하나 감정과 추억을 기록할 수 있는 퍼즐형 다이어리 플랫폼입니다.
이 Flutter 앱은 해당 플랫폼의 모바일 클라이언트입니다.

---

## 🚀 기능 요약

- 🔐 JWT 기반 로그인 / 회원가입 (API 연동)
- 🧩 조각 만들기 (텍스트 / 이미지 / 영상 / 음성)
- 📦 조각 보관함 (필터, 삭제)
- 📅 감정 캘린더 / 챌린지 진행
- 🧠 협업 / 타임캡슐 작성 예정
- 🌈 Orbit UI 기반 퍼즐 회전 애니메이션

---

## 📱 기술 스택

| 구분 | 기술 |
|------|------|
| 프론트엔드 | Flutter (3.x), Dart, Provider |
| 상태관리 | SharedPreferences (JWT 저장) |
| HTTP 통신 | `http` 패키지 사용 |
| 이미지/비디오 | ImagePicker, Cloudinary (서버 연동) |
| UI 구성 | AnimatedBuilder, CustomPainter, ClipPath |

---

## 🧪 개발 중인 브랜치

- `master`: 안정화된 코드

---

## 📦 실행 방법

```bash
# 1. 패키지 설치
flutter pub get

# 2. 로컬 실행 (에뮬레이터 또는 실기기)
flutter run

# 3. 웹 실행 (테스트용)
flutter run -d chrome
```
---

## 📁 구조 예시

```
lib/
├── screens/
│   ├── auth/               # 로그인 / 회원가입
│   ├── pieces/             # 조각 쓰기, 보관함
│   ├── diary_timecapsule/  # 일기, 타임캡슐
│   ├── calendar_challenge/ # 캘린더, 챌린지
│   └── user/               # 마이페이지 등
├── widgets/                # 공통 위젯
└── main.dart
```

---

## 🧩 개발 기여 중이신 분

- 👤 @ChickenPizzaHamburger (Flutter, Orbit UI, 퍼즐 시스템)
- 👥 Team
 @1ddami
 @K0HA2O
 @shinzhaoxian

---