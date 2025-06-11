import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fonts.dart';
import 'progress_indicator/report_card_progressring.dart';
import 'progress_indicator/report_card_progressdots.dart';
import '../../../../services/models/report_card_model.dart';
import '../../../../services/models/report_card_types.dart';
import 'report_card_list_view_model.dart';

class ReportCard extends StatelessWidget {
  final ReportCardModel report;

  const ReportCard({super.key, required this.report});

  /// 개별 카드의 로딩 상태 판별 로직
  bool _isCardLoading() {
    if (report.type == ReportCardType.daily) {
      // Daily: progress가 0이면서 subtitle이 '생성 실패'가 아니면 로딩 중
      return report.progress == 0.0 && report.subtitle != '생성 실패';
    } else if (report.type == ReportCardType.weekly) {
      // Weekly: activeDots가 0이면서 subtitle이 '생성 실패'가 아니면 로딩 중
      return report.activeDots == 0 && report.subtitle != '생성 실패';
    } else {
      // Monthly: 아직 구현 안됨
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildCardContent() {
      if (report.type == ReportCardType.daily) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: ProgressRing + 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReportCardProgressRing(
                        progress: report.progress,
                        size: AppDimensions.reportIndicatorLarge,
                        isLoading: _isCardLoading(),
                      ),

                      SizedBox(height: AppDimensions.paddingMedium),

                      Text(
                        report.title,
                        style: PretendardStyles.semiBold16.copyWith(
                          color: AppColors.black100,
                        ),
                      ),

                      SizedBox(height: AppDimensions.paddingSmall),

                      Text(
                        report.subtitle,
                        style: PretendardStyles.regular12.copyWith(
                          color: AppColors.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
                // 오른쪽: 배경 이미지 (있을 때만)
                if (report.imageUrl != null)
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(report.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        // Weekly and Monthly cards
        return Card(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportCardProgressDots(
                  type:
                      report.type == ReportCardType.weekly
                          ? ProgressDotsType.weekly
                          : ProgressDotsType.monthly,
                  activeDots: report.activeDots,
                  largeDotSize: AppDimensions.reportIndicatorMedium,
                  smallDotSize: AppDimensions.reportIndicatorSmall,
                  spacing: AppDimensions.paddingExtraSmall,
                  isLoading: _isCardLoading(), // 개별 카드 로딩 상태 사용
                ),

                SizedBox(height: AppDimensions.paddingMedium),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: PretendardStyles.semiBold16.copyWith(
                        color: AppColors.black100,
                      ),
                    ),

                    SizedBox(height: AppDimensions.paddingSmall),

                    Text(
                      report.subtitle,
                      style: PretendardStyles.regular12.copyWith(
                        color: AppColors.gray100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        final viewModel = Provider.of<ReportCardListViewModel>(
          context,
          listen: false,
        );
        viewModel.showReportBottomSheet(context, report.id);
      },
      child: buildCardContent(),
    );
  }
}
