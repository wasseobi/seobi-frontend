import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/insight/insight_service.dart';
import '../../../../services/insight/models/insight_detail_api.dart';

class InsightArticle extends StatelessWidget {
  final String? articleId;
  final InsightService _insightService = InsightService();

  InsightArticle({super.key, this.articleId});

  @override
  Widget build(BuildContext context) {
    if (articleId == null) {
      return _buildErrorContent(context, '인사이트 ID가 없습니다');
    }

    // 예시 데이터 ID인 경우 더미 콘텐츠 표시
    if (articleId == '1' || articleId == '2' || articleId == '3') {
      return _buildDummyContent(context, articleId!);
    }

    // 실제 API 호출
    return FutureBuilder<InsightDetailApi?>(
      future: _insightService.getInsightDetail(articleId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent(context);
        }

        if (snapshot.hasError) {
          return _buildErrorContent(context, '오류: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildErrorContent(context, '인사이트를 찾을 수 없습니다');
        }

        return _buildInsightContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Insight'),
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            '인사이트를 불러오는 중...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Insight'),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDummyContent(BuildContext context, String id) {
    final dummyData = {
      '1': {
        'title': '주간 업무 분석',
        'keywords': ['생산성', '업무패턴', '시간관리'],
      },
      '2': {
        'title': '월간 성과 리포트',
        'keywords': ['목표달성', '성과지표', '개선점'],
      },
      '3': {
        'title': '업무 효율성 분석',
        'keywords': ['업무효율', '시간분배', '최적화'],
      },
    };

    final data = dummyData[id]!;

    return Column(
      children: [
        _buildHeader(context, data['title'] as String),
        const SizedBox(height: 16),

        // 키워드 표시
        Wrap(
          children:
              (data['keywords'] as List<String>)
                  .map((kw) => Chip(label: Text('#$kw')))
                  .toList(),
        ),

        const SizedBox(height: 16),
        const Text('예시 데이터입니다. 실제 백엔드 연동 후 실제 데이터가 표시됩니다.'),
      ],
    );
  }

  Widget _buildInsightContent(BuildContext context, InsightDetailApi insight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, insight.title),
        const SizedBox(height: 16),

        // 키워드 태그들
        if (insight.keywords.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                insight.keywords.map((keyword) {
                  return Chip(
                    label: Text(
                      '#$keyword',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 인사이트 내용 (마크다운 렌더링) - 완전한 오버플로우 방지
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child:
              insight.content.isNotEmpty
                  ? SingleChildScrollView(
                    child: MarkdownBody(
                      data: insight.content,
                      selectable: true,
                      softLineBreak: true,
                      fitContent: false, // 컨텐츠 크기 자동 조정
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        h1: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        h2: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        h3: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        blockquote: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: const TextStyle(color: Colors.black54),
                        a: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 14, // 링크 폰트 크기 명시적 지정
                        ),
                      ),
                    ),
                  )
                  : const Text(
                    '내용이 없습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
        ),

        const SizedBox(height: 16),

        // 메타 정보 - 접을 수 있는 링크 표시
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 생성일자
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(insight.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            // 소스 링크들 (접을 수 있는 형태)
            if (insight.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildExpandableSourceLinks(context, insight.source),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  Widget _buildExpandableSourceLinks(BuildContext context, String source) {
    // 여러 링크를 파싱
    String cleanSource = source.replaceAll(RegExp(r'[{}]'), '');
    List<String> links =
        cleanSource
            .split(',')
            .map((link) => link.trim())
            .where((link) => link.isNotEmpty)
            .toList();

    if (links.isEmpty) {
      return Text(
        source,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero, // 패딩 제거
      childrenPadding: const EdgeInsets.only(left: 20, top: 8),
      initiallyExpanded: links.length <= 2, // 링크가 2개 이하면 기본으로 펼침
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.source, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '출처 (${links.length}개)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.keyboard_arrow_down,
        size: 16,
        color: Colors.grey.shade600,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                links.map((link) {
                  String displayText = _shortenUrl(link);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () => _launchUrl(link),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 12,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 10,
                              color: Colors.blue.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  String _shortenUrl(String url) {
    // URL을 보기 좋게 줄이기
    if (url.length <= 40) return url;

    // https:// 제거
    String cleanUrl = url.replaceFirst(RegExp(r'https?://'), '');

    // www. 제거
    cleanUrl = cleanUrl.replaceFirst(RegExp(r'^www\.'), '');

    // 도메인과 경로 분리
    List<String> parts = cleanUrl.split('/');
    if (parts.length > 1) {
      String domain = parts[0];
      String path = parts.sublist(1).join('/');

      // 경로가 너무 길면 줄이기
      if (path.length > 20) {
        path = '${path.substring(0, 17)}...';
      }

      return '$domain/$path';
    }

    return cleanUrl.length > 40 ? '${cleanUrl.substring(0, 37)}...' : cleanUrl;
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      // URL이 프로토콜을 포함하지 않으면 https:// 추가
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }

      final Uri url = Uri.parse(urlString);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // 외부 브라우저에서 열기
        );
      } else {
        // URL을 열 수 없는 경우 에러 메시지 표시
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
