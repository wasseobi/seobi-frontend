import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'database_interface.dart';
import 'desktop_database.dart';
import 'mobile_database.dart';

/// 플랫폼에 맞는 데이터베이스 구현체를 생성하는 팩토리 클래스입니다.
class DatabaseFactory {
  /// 현재 플랫폼에 적합한 데이터베이스 구현체를 반환합니다.
  static DatabaseInterface create() {
    // 웹 환경에서는 지원하지 않음
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported for local database operations');
    }
    
    // 모바일 환경(Android, iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      return MobileDatabase();
    }
    
    // 데스크톱 환경(Windows, macOS, Linux)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return DesktopDatabase();
    }
    
    throw UnsupportedError('Current platform is not supported for local database operations');
  }
}
