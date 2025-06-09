import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/report/report_api_service.dart';
import '../../services/auth/auth_service.dart';

/// 리포트 데이터 접근을 담당하는 Repository
class ReportRepository {
  final ReportApiService _apiService = ReportApiService();
  final AuthService _authService = AuthService();
  static const String _storageKey = 'report_cards_state';

  /// 새 리포트 생성 (Daily)
  Future<Map<String, dynamic>> createDailyReport() async {
    final userId = _authService.userId;
    final authToken = await _authService.accessToken;

    if (!_authService.isLoggedIn || userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 Repository: Daily 리포트 생성 요청');

    final result = await _apiService.createDailyReport(
      userId: userId,
      authToken: authToken,
    );

    debugPrint('✅ Repository: Daily 리포트 생성 완료');
    return result;
  }

  /// 새 리포트 생성 (Weekly)
  Future<Map<String, dynamic>> createWeeklyReport() async {
    final userId = _authService.userId;
    final authToken = await _authService.accessToken;

    if (!_authService.isLoggedIn || userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 Repository: Weekly 리포트 생성 요청');

    final result = await _apiService.createWeeklyReport(
      userId: userId,
      authToken: authToken,
    );

    debugPrint('✅ Repository: Weekly 리포트 생성 완료');
    return result;
  }

  /// 기존 리포트 목록 조회
  Future<List<Map<String, dynamic>>> getAllReports() async {
    final userId = _authService.userId;
    final authToken = await _authService.accessToken;

    if (!_authService.isLoggedIn || userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    debugPrint('📡 Repository: 리포트 목록 조회 요청');

    final results = await _apiService.getAllReports(
      userId: userId,
      authToken: authToken,
    );

    debugPrint('✅ Repository: 리포트 목록 조회 완료 (${results.length}개)');
    return results;
  }

  /// 로컬 저장소에서 리포트 데이터 로드
  Future<List<Map<String, dynamic>>?> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReports = prefs.getString(_storageKey);

      if (savedReports != null) {
        debugPrint('💾 Repository: 로컬 저장소에서 데이터 로드');
        final List<dynamic> decodedReports = jsonDecode(savedReports);
        return decodedReports.cast<Map<String, dynamic>>();
      }

      debugPrint('💾 Repository: 로컬 저장소 데이터 없음');
      return null;
    } catch (e) {
      debugPrint('❌ Repository: 로컬 저장소 로드 실패 - $e');
      return null;
    }
  }

  /// 로컬 저장소에 리포트 데이터 저장
  Future<void> saveToLocalStorage(List<Map<String, dynamic>> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedReports = jsonEncode(reports);
      await prefs.setString(_storageKey, encodedReports);
      debugPrint('💾 Repository: 로컬 저장소에 데이터 저장 완료');
    } catch (e) {
      debugPrint('❌ Repository: 로컬 저장소 저장 실패 - $e');
    }
  }

  /// 사용자 인증 상태 확인
  bool get isUserLoggedIn => _authService.isLoggedIn;

  /// 사용자 ID 가져오기
  String? get userId => _authService.userId;
}
