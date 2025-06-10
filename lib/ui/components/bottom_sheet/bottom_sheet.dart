import 'package:flutter/material.dart';
import 'bottom_sheet_types.dart';
import '../articles/reports/report_article.dart';
import '../articles/insights/insight_article.dart';

Future<void> showCommonBottomSheet({
  required BuildContext context,
  required ReportCardType type,
  Map<String, dynamic>? content,
  String? reportType,
  String? articleId,
}) {
  Widget content_widget;
  switch (type) {
    case ReportCardType.report:
      content_widget = ReportArticle(content: content, reportType: reportType);
      break;
    case ReportCardType.insight:
      content_widget = InsightArticle(articleId: articleId);
      break;
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder:
            (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: content_widget,
              ),
            ),
      );
    },
  );
}
