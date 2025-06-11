import 'package:flutter/material.dart';
import '../../common/schedule_card.dart';
import '../../common/title_card.dart';
import '../../common/filter_button.dart';
import '../../../constants/dimensions/schedule_card_dimensions.dart';
import 'schedule_card_list_view_model.dart';
import 'schedule_types.dart';

class ScheduleCardList extends StatefulWidget {
  final double? width;
  final double? height;
  final ScheduleCardListViewModel? viewModel;

  const ScheduleCardList({super.key, this.width, this.height, this.viewModel});

  @override
  State<ScheduleCardList> createState() => _ScheduleCardListState();
}

class _ScheduleCardListState extends State<ScheduleCardList> {
  late final ScheduleCardListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? ScheduleCardListViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ScheduleCardDimensions.listPaddingHorizontal,
              vertical: ScheduleCardDimensions.listPaddingVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TitleCard(
                      section: 'Schedule',
                      sectionKr: '나의 일정',
                      count: _viewModel.schedules.length,
                    ),
                    FilterToggleButton(
                      onChanged: (isUrgent) {
                        _viewModel.sortSchedules(isUrgent);
                      },
                    ),
                  ],
                ),
                SizedBox(height: ScheduleCardDimensions.listSpacing),
                if (widget.height != null)
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ScheduleCardDimensions.crossAxisCount,
                        crossAxisSpacing: ScheduleCardDimensions.gridSpacing,
                        mainAxisSpacing: ScheduleCardDimensions.gridSpacing,
                        childAspectRatio: ScheduleCardDimensions.aspectRatio,
                      ),
                      itemCount: _viewModel.schedules.length,
                      itemBuilder: (context, index) {
                        return ScheduleCard(
                          schedule: _viewModel.schedules[index].copyWith(
                            type: ScheduleType.list,
                          ),
                        );
                      },
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ScheduleCardDimensions.crossAxisCount,
                      crossAxisSpacing: ScheduleCardDimensions.gridSpacing,
                      mainAxisSpacing: ScheduleCardDimensions.gridSpacing,
                      childAspectRatio: ScheduleCardDimensions.aspectRatio,
                    ),
                    itemCount: _viewModel.schedules.length,
                    itemBuilder: (context, index) {
                      return ScheduleCard(
                        schedule: _viewModel.schedules[index].copyWith(
                          type: ScheduleType.list,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
