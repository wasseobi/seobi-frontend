import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../repositories/backend/http_helper.dart';
import 'models/insight_article_api.dart';
import 'models/insight_detail_api.dart';

/// Insight API와의 HTTP 통신을 담당하는 서비스 클래스
class InsightApiService {
  late final HttpHelper _httpHelper;

  /// 환경변수를 기반으로 백엔드 URL 결정
  static String get baseUrl {
    final useRemoteBackend =
        dotenv.get('USE_REMOTE_BACKEND', fallback: 'false') == 'true';

    if (useRemoteBackend) {
      // 원격 백엔드 사용
      return dotenv.get(
        'REMOTE_BACKEND_URL',
        fallback:
            'https://seobi-backend-edfygbdvh8cfbvev.koreacentral-01.azurewebsites.net/',
      );
    } else {
      // 로컬 백엔드 사용 - 플랫폼에 따라 URL 선택
      if (kIsWeb || !Platform.isAndroid) {
        return dotenv.get(
          'LOCAL_BACKEND_URL_DEFAULT',
          fallback: 'http://127.0.0.1:5000',
        );
      } else {
        return dotenv.get(
          'LOCAL_BACKEND_URL_ANDROID',
          fallback: 'http://10.0.2.2:5000',
        );
      }
    }
  }

  InsightApiService({HttpHelper? httpHelper}) {
    _httpHelper = httpHelper ?? HttpHelper(baseUrl);
  }

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _httpHelper.setAuthToken(token);
  }

  /// 특정 사용자의 모든 인사이트 아티클 목록을 조회합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: 인사이트 아티클 목록
  /// Throws: Exception when API call fails
  Future<List<InsightArticleApi>> getUserInsights(String userId) async {
    try {
      return await _httpHelper.getList<InsightArticleApi>(
        '/insights/$userId',
        (json) => InsightArticleApi.fromJson(json),
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      throw Exception('인사이트 목록 조회 실패: $e');
    }
  }

  /// 특정 인사이트 아티클의 상세 정보를 조회합니다
  ///
  /// [articleId] 인사이트 아티클 UUID
  /// Returns: 인사이트 상세 정보
  /// Throws: Exception when API call fails or article not found
  Future<InsightDetailApi> getInsightDetail(String articleId) async {
    try {
      return await _httpHelper.get<InsightDetailApi>(
        '/insights/list/$articleId',
        (json) => InsightDetailApi.fromJson(json),
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      throw Exception('인사이트 상세 조회 실패: $e');
    }
  }

  /// 사용자의 데이터를 기반으로 새로운 인사이트 아티클을 생성합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: 생성된 인사이트 상세 정보
  /// Throws: Exception when API call fails or generation fails
  Future<InsightDetailApi> generateInsight(String userId) async {
    try {
      return await _httpHelper.post<InsightDetailApi>(
        '/insights/$userId',
        {}, // POST body는 빈 객체 (API 문서에 따르면 body 없음)
        (json) => InsightDetailApi.fromJson(json),
        expectedStatus: 201, // 생성 성공 시 201 또는 200
        timeout: const Duration(seconds: 30), // 생성은 시간이 오래 걸릴 수 있음
      );
    } catch (e) {
      throw Exception('인사이트 생성 실패: $e');
    }
  }
}
