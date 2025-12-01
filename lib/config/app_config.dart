import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform; // Platform을 사용하기 위해 임포트

// 플랫폼에 따라 동적으로 설정되는 API의 기본 URL
String get kBaseUrl {
  if (kIsWeb) {
    return "https://triproomserver.up.railway.app";
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:5000";
  } else if (Platform.isIOS) {
    return "http://127.0.0.1:5000";
  }
  // 다른 플랫폼이나 플랫폼 확인이 실패할 경우를 위한 대체 값
  return "http://127.0.0.1:5000";
}
