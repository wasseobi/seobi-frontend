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

        // 인사이트 내용 (마크다운 렌더링)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: insight.content,
              selectable: true,
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
                h1: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                h2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                blockSpacing: 16.0,
                listIndent: 24.0,
                listBullet: TextStyle(color: Colors.black87),
              ),
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

  Widget _buildExpandableSourceLinks(BuildContext context, String sources) {
    final sourceList = sources.split('\n').where((s) => s.isNotEmpty).toList();

    return ExpansionTile(
      title: Text(
        '출처 ${sourceList.length}개',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
      children:
          sourceList
              .map(
                (source) => ListTile(
                  dense: true,
                  title: Text(
                    source,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () async {
                    if (await canLaunch(source)) {
                      await launch(source);
                    }
                  },
                ),
              )
              .toList(),
    );
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
