import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../ui/constants/app_colors.dart';
import '../../../../ui/constants/app_dimensions.dart';
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
            // 헤더 영역 (제목 + 생성 버튼)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '인사이트',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: viewModel.generateNewInsight,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('새 인사이트 생성'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.main100,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingMedium),

            // 로딩 상태 표시
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator()),

            // 에러 메시지 표시
            if (viewModel.error != null)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Text(
                  viewModel.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),

            // 인사이트 목록
            if (insights.isNotEmpty)
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

            // 데이터가 없을 때 표시
            if (!viewModel.isLoading && insights.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Text(
                    '아직 생성된 인사이트가 없습니다.\n새 인사이트를 생성해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray60, fontSize: 14),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
