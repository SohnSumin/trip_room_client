import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/start_screen.dart';
import 'views/home_screen.dart';
import 'views/account_screen.dart';
import 'views/add_room_screen.dart';
import 'views/room_detail_screen.dart';

Future<void> main() async {
  // Flutter 엔진과 위젯 트리가 바인딩되었는지 확인
  WidgetsFlutterBinding.ensureInitialized();
  // 한국 시간 형식 데이터를 초기화
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

      // 라우트 생성
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/start':
            return MaterialPageRoute(builder: (_) => const StartScreen());
          case '/home':
            // 로그인 화면에서 전달받은 arguments를 추출
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?;
            final nickname = args?['nickname'] as String?;
            final id = args?['id'] as String?;

            // userId가 없으면 시작 화면으로 이동
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
            final userId = args?['userId'] as String?;
            final id = args?['id'] as String?;

            if (userId == null || id == null) {
              return MaterialPageRoute(builder: (_) => const StartScreen());
            }
            return MaterialPageRoute(
              builder: (_) => AccountScreen(userId: userId, id: id),
            );
          case '/add_room':
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?;
            final nickname = args?['nickname'] as String?;
            final id = args?['id'] as String?;

            if (userId == null || nickname == null || id == null) {
              return MaterialPageRoute(builder: (_) => const StartScreen());
            }
            return MaterialPageRoute(
              builder: (_) =>
                  AddRoomScreen(userId: userId, nickname: nickname, id: id),
            );
          case '/room_detail':
            final args = settings.arguments as Map<String, dynamic>?;
            final roomId = args?['roomId'] as String?;
            final userId = args?['userId'] as String?;
            final nickname = args?['nickname'] as String?;
            final id = args?['id'] as String?;

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
            // 정의되지 않은 라우트로 이동 시 시작 화면으로 이동
            return MaterialPageRoute(builder: (_) => const StartScreen());
        }
      },
    );
  }
}
