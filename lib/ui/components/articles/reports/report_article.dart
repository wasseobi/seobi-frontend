import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ReportArticle extends StatelessWidget {
  final Map<String, dynamic>? content;
  final String? reportType;

  const ReportArticle({super.key, this.content, this.reportType});

  @override
  Widget build(BuildContext context) {
    final reportText = content?['text'] ?? '리포트 내용을 불러오는 중입니다...';
    final typeTitle = _getTypeTitle();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              typeTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 리포트 텍스트 내용 (마크다운 렌더링)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📄 리포트 내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // 마크다운 렌더링
              MarkdownBody(
                data: reportText,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  h2: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  h3: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  p: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  listBullet: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(width: 1.0, color: Colors.grey[400]!),
                    ),
                  ),
                ),
                selectable: true, // 텍스트 선택 가능
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  String _getTypeTitle() {
    switch (reportType?.toLowerCase()) {
      case 'daily':
        return 'Daily Report';
      case 'weekly':
        return 'Weekly Report';
      case 'monthly':
        return 'Monthly Report';
      default:
        return 'Report';
    }
  }
}
