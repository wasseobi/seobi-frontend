import 'package:flutter/material.dart';
import 'bottom_sheet_types.dart';
import '../articles/reports/report_article.dart';
import '../articles/insights/insight_article.dart';

Future<void> showCommonBottomSheet({
  required BuildContext context,
  required ReportCardType type,
}) {
  Widget content;
  switch (type) {
    case ReportCardType.report:
      content = const ReportArticle();
      break;
    case ReportCardType.insight:
      content = const InsightArticle();
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
                child: content,
              ),
            ),
      );
    },
  );
}
