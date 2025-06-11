import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fonts.dart';
import '../../../constants/dimensions/insight_card_dimensions.dart';
import 'insight_card_model.dart';
import 'insight_card_list_view_model.dart';

class InsightCard extends StatelessWidget {
  final InsightCardModel insight;

  const InsightCard({Key? key, required this.insight}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final viewModel = Provider.of<InsightCardListViewModel>(
          context,
          listen: false,
        );
        viewModel.showInsightBottomSheet(context, insight.id);
      },
      child: Container(
        color: Colors.transparent, // 터치 영역을 위해 투명 배경 설정
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: AppDimensions.paddingSmall),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (오버플로우 처리 추가)
                  Text(
                    insight.title,
                    style: PretendardStyles.semiBold16.copyWith(
                      color: AppColors.gray100,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // 최대 2줄까지 표시
                  ),

                  SizedBox(height: AppDimensions.paddingSmall),

                  // Keywords Row (오버플로우 처리 추가)
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          insight.keywords.take(3).map((kw) {
                            // 최대 3개 키워드만 표시
                            return Text(
                              '#$kw',
                              style: PretendardStyles.semiBold14.copyWith(
                                color: AppColors.gray80,
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  SizedBox(height: AppDimensions.paddingSmall),

                  // Date
                  Text(
                    insight.date,
                    style: PretendardStyles.medium10.copyWith(
                      color: AppColors.gray100,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: AppDimensions.iconSizeMedium),
          ],
        ),
      ),
    );
  }
}
