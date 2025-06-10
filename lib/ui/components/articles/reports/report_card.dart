import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fonts.dart';
import '../../../constants/dimensions/report_card_dimensions.dart';
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
    // Get screen width for relative sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth * ReportCardDimensions.horizontalPaddingPercent;
    final containerWidth = screenWidth - (horizontalPadding * 2);

    // Calculate relative sizes
    final dailyCardHeight =
        containerWidth * ReportCardDimensions.dailyCardHeightPercent;
    final smallCardHeight =
        containerWidth * ReportCardDimensions.smallCardHeightPercent;
    final imageWidth = containerWidth * ReportCardDimensions.imageWidthPercent;
    final progressRingSize =
        containerWidth * ReportCardDimensions.progressRingSizePercent;
    final spacing = containerWidth * ReportCardDimensions.spacingPercent;

    Widget buildCardContent() {
      if (report.type == ReportCardType.daily) {
        return Container(
          width: double.infinity,
          height: dailyCardHeight,
          padding: EdgeInsets.fromLTRB(
            containerWidth * ReportCardDimensions.dailyCardPaddingLeftPercent,
            containerWidth * ReportCardDimensions.dailyCardPaddingTopPercent,
            containerWidth * ReportCardDimensions.dailyCardPaddingRightPercent,
            containerWidth * ReportCardDimensions.dailyCardPaddingBottomPercent,
          ),
          decoration: BoxDecoration(
            color: AppColors.white100,
            borderRadius: BorderRadius.circular(
              containerWidth * ReportCardDimensions.dailyCardRadiusPercent,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image (Right side)
              if (report.imageUrl != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: imageWidth,
                    height: dailyCardHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(report.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportCardProgressRing(
                    progress: report.progress,
                    size: progressRingSize,
                    isLoading: _isCardLoading(), // 개별 카드 로딩 상태 사용
                  ),
                  SizedBox(height: spacing),
                  Text(
                    report.title,
                    style: PretendardStyles.semiBold16.copyWith(
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: spacing * 0.2),
                  Text(
                    report.subtitle,
                    style: PretendardStyles.regular12.copyWith(
                      color: AppColors.gray100,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      } else {
        // Weekly and Monthly cards
        return Container(
          width: double.infinity,
          height: smallCardHeight,
          padding: EdgeInsets.all(
            containerWidth * ReportCardDimensions.smallCardPaddingPercent,
          ),
          decoration: BoxDecoration(
            color: AppColors.white100,
            borderRadius: BorderRadius.circular(
              containerWidth * ReportCardDimensions.smallCardRadiusPercent,
            ),
          ),
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
                largeDotSize:
                    containerWidth * ReportCardDimensions.largeDotSizePercent,
                smallDotSize:
                    containerWidth * ReportCardDimensions.smallDotSizePercent,
                spacing:
                    containerWidth * ReportCardDimensions.dotsSpacingPercent,
                isLoading: _isCardLoading(), // 개별 카드 로딩 상태 사용
              ),
              SizedBox(
                height:
                    containerWidth * ReportCardDimensions.titleSpacingPercent,
              ),
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
                  SizedBox(height: spacing * 0.2),
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
