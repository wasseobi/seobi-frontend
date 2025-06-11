import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'reports/report_card_list.dart';
import 'reports/report_card_list_view_model.dart';
import 'insights/insight_card_list.dart';
import 'insights/insight_card_list_view_model.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportCardListViewModel()),
        ChangeNotifierProvider(create: (_) => InsightCardListViewModel()),
      ],
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppDimensions.paddingMedium),

            ReportCardList(),

            SizedBox(height: AppDimensions.paddingMedium),

            InsightCardList(),
          ],
        ),
      ),
    );
  }
}
