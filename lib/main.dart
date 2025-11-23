import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/start_screen.dart';
import 'screens/home_screen.dart';
import 'screens/account_screen.dart';
import 'screens/add_room_screen.dart';
import 'screens/room_detail_screen.dart';

Future<void> main() async {
  // Flutter 엔진과 위젯 트리가 바인딩되었는지 확인합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // 'ko_KR' 로케일의 날짜/시간 형식 데이터를 초기화합니다.
  await initializeDateFormatting('ko_KR');

  runApp(const TripRoomApp());
}

class TripRoomApp extends StatelessWidget {
  const TripRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripRoom',
      theme: ThemeData(primarySwatch: Colors.blue),

      initialRoute: '/start',

      // 라우트 생성 로직
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/start':
            return MaterialPageRoute(builder: (_) => const StartScreen());
          case '/home':
            // 로그인 화면에서 전달받은 arguments를 추출합니다.
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?;
            final nickname = args?['nickname'] as String?;
            final id = args?['id'] as String?;

            // userId가 없으면 에러 페이지나 로그인 페이지로 보낼 수 있습니다.
            if (userId == null || nickname == null || id == null) {
              return MaterialPageRoute(
                builder: (_) => const StartScreen(),
              ); // 예시: 시작 화면으로 리디렉션
            }
            return MaterialPageRoute(
              builder: (_) =>
                  HomeScreen(userId: userId, nickname: nickname, id: id),
            );
          case '/account':
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?; // null일 수 있음
            final id = args?['id'] as String?; // null일 수 있음

            if (userId == null || id == null) {
              return MaterialPageRoute(builder: (_) => const StartScreen());
            }
            return MaterialPageRoute(
              builder: (_) => AccountScreen(userId: userId, id: id),
            );
          case '/add_room':
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?; // null일 수 있음
            final nickname = args?['nickname'] as String?; // null일 수 있음
            final id = args?['id'] as String?; // null일 수 있음

            if (userId == null || nickname == null || id == null) {
              return MaterialPageRoute(builder: (_) => const StartScreen());
            }
            return MaterialPageRoute(
              builder: (_) =>
                  AddRoomScreen(userId: userId, nickname: nickname, id: id),
            );
          case '/room_detail':
            final args = settings.arguments as Map<String, dynamic>?;
            final roomId = args?['roomId'] as String?; // null일 수 있음
            final userId = args?['userId'] as String?; // null일 수 있음
            final nickname = args?['nickname'] as String?; // null일 수 있음
            final id = args?['id'] as String?; // null일 수 있음

            if (roomId == null ||
                userId == null ||
                nickname == null ||
                id == null) {
              return MaterialPageRoute(builder: (_) => const StartScreen());
            }
            return MaterialPageRoute(
              builder: (_) => RoomDetailScreen(
                roomId: roomId,
                userId: userId,
                nickname: nickname,
                id: id,
              ),
            );
          default:
            // 정의되지 않은 라우트로 이동 시 처리
            return MaterialPageRoute(builder: (_) => const StartScreen());
        }
      },
    );
  }
}
