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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 새 인사이트 생성 버튼 - 항상 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: viewModel.generateNewInsight,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('새 인사이트 생성'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 인사이트 목록 - 있을 때만 표시
            if (insights.isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: insights.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final insight = insights[index];
                  return InsightCard(insight: insight);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
