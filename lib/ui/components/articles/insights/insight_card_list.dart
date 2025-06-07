import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'insight_card.dart';
import 'insight_card_list_view_model.dart';

class InsightCardList extends StatelessWidget {
  const InsightCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InsightCardListViewModel>(
      builder: (context, viewModel, child) {
        final insights = viewModel.insights;

        if (insights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final insight = insights[index];
                return InsightCard(insight: insight);
              },
            ),
          ],
        );
      },
    );
  }
}
