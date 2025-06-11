import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'schedule_card.dart';
import '../../common/title_card.dart';
import '../../common/filter_button.dart';
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

  Widget _buildScheduleGrid({bool isExpanded = false}) {
    final gridView = MasonryGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.paddingMedium,
      mainAxisSpacing: AppDimensions.paddingMedium,
      shrinkWrap: !isExpanded,
      physics: isExpanded ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final schedule = _viewModel.schedules[index];
        return ScheduleCard(
          schedule: schedule.copyWith(type: ScheduleType.list),
        );
      },
      itemCount: _viewModel.schedules.length,
    );

    return isExpanded ? Expanded(child: gridView) : gridView;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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

              SizedBox(height: AppDimensions.paddingMedium),

              _buildScheduleGrid(isExpanded: widget.height != null),
            ],
          );
        },
      ),
    );
  }
}
