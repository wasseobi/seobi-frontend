import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fonts.dart';
import '../../../constants/dimensions/task_card_dimensions.dart';
import '../../common/switch.dart';
import 'task_card_model.dart';
import 'task_card_progressbar.dart';

class TaskCard extends StatefulWidget {
  final TaskCardModel task;
  final ValueChanged<bool>? onChanged;

  const TaskCard({super.key, required this.task, this.onChanged});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late bool isEnabled;
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isEnabled = widget.task.isEnabled;
    isExpanded =
        widget.task.isEnabled; // Initialize expanded state based on task status
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isEnabled != widget.task.isEnabled) {
      isEnabled = widget.task.isEnabled;
      // Update expanded state when task status changes
      if (!isEnabled) {
        isExpanded = false;
      }
    }
  }

  void _handleSwitchChange(bool value) {
    setState(() {
      isEnabled = value;
      if (value) {
        isExpanded = true; // Auto-expand when activated
      }
    });
    widget.onChanged?.call(value);
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Padding(
          padding:
              isExpanded
                  ? const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingSmall,
                  )
                  : const EdgeInsets.only(top: AppDimensions.paddingSmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              SizedBox(height: AppDimensions.paddingSmall),

              TaskCardProgressBar(
                isActive: isEnabled,
                progress: widget.task.progress,
              ),

              if (isExpanded) ...[
                SizedBox(height: AppDimensions.paddingSmall),
                _buildContentArea(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
      ),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.play_circle_filled : Icons.pause_circle_filled,
            size: TaskCardDimensions.iconSize,
            color: isEnabled ? AppColors.main100 : AppColors.gray80,
          ),
          SizedBox(width: TaskCardDimensions.iconSpacing),
          Text(
            isEnabled ? widget.task.remainingTime : '정지된 업무',
            style: PretendardStyles.semiBold12.copyWith(
              color: AppColors.gray100,
            ),
          ),
          Spacer(),
          Icon(
            isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            size: TaskCardDimensions.iconSize,
            color: AppColors.gray80,
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.title,
                style: PretendardStyles.semiBold16.copyWith(
                  color: AppColors.black100,
                ),
              ),

              SizedBox(height: AppDimensions.paddingSmall),

              ...widget.task.actions.map(
                (action) => Column(
                  children: [
                    _buildActionDetail(action),
                    SizedBox(height: AppDimensions.paddingSmall),
                  ],
                ),
              ),

              SizedBox(height: AppDimensions.paddingSmall),

              Text(
                widget.task.schedule,
                style: PretendardStyles.medium12.copyWith(
                  color: AppColors.gray100,
                ),
              ),
            ],
          ),

          Spacer(),

          Switch(value: isEnabled, onChanged: _handleSwitchChange),
        ],
      ),
    );
  }

  Widget _buildActionDetail(Map<String, String> action) {
    return Row(
      children: [
        Icon(
          Icons.play_circle_outline,
          size: TaskCardDimensions.iconSize - 4,
          color: isEnabled ? AppColors.main100 : AppColors.gray80,
        ),

        SizedBox(width: AppDimensions.paddingSmall),

        Text(
          action['service']!,
          style: PretendardStyles.semiBold12.copyWith(color: AppColors.gray100),
        ),
        Text(
          action['action']!,
          style: PretendardStyles.regular12.copyWith(color: AppColors.gray100),
        ),
      ],
    );
  }
}
