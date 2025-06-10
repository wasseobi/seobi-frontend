import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'report_card.dart';
import 'report_card_list_view_model.dart';
import '../../../../services/models/report_card_types.dart';

class ReportCardList extends StatelessWidget {
  const ReportCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportCardListViewModel>(
      builder: (context, viewModel, child) {
        final reports = viewModel.reports;
        if (reports.isEmpty) return const SizedBox.shrink();

        // Get screen width for relative sizing
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth * 0.04; // 4% of screen width
        final containerWidth = screenWidth - (horizontalPadding * 2);
        final cardSpacing = containerWidth * 0.027; // 2.7% of container width

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: containerWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Report Card
                ReportCard(
                  report: reports.firstWhere(
                    (report) => report.type == ReportCardType.daily,
                    orElse: () => reports.first,
                  ),
                ),
                SizedBox(height: cardSpacing),
                // Weekly and Monthly Report Cards Container
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Report Card
                      Expanded(
                        flex: 6,
                        child: ReportCard(
                          report: reports.firstWhere(
                            (report) => report.type == ReportCardType.weekly,
                            orElse: () => reports.first,
                          ),
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      // Monthly Report Card
                      Expanded(
                        flex: 4,
                        child: ReportCard(
                          report: reports.firstWhere(
                            (report) => report.type == ReportCardType.monthly,
                            orElse: () => reports.first,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
