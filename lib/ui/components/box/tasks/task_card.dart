import 'package:flutter/material.dart';
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
    return Container(
      width: TaskCardDimensions.cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TaskCardDimensions.radius),
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remaining time
          Container(
            width: double.infinity,
            height: TaskCardDimensions.headerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: TaskCardDimensions.headerPaddingHorizontal,
              vertical: TaskCardDimensions.headerPaddingVertical,
            ),
            decoration: ShapeDecoration(
              color: isEnabled ? AppColors.white100 : AppColors.whiteBlur,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TaskCardDimensions.radius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEnabled
                          ? Icons.play_circle_filled
                          : Icons.pause_circle_filled,
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
                  ],
                ),
                GestureDetector(
                  onTap: _toggleExpand,
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: TaskCardDimensions.iconSize,
                    color: AppColors.gray80,
                  ),
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            // Progress bar
            TaskCardProgressBar(
              isActive: isEnabled,
              progress: widget.task.progress,
            ),

            // Content area
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(TaskCardDimensions.contentPadding),
              decoration: ShapeDecoration(
                color: AppColors.white80,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(TaskCardDimensions.radius),
                    bottomRight: Radius.circular(TaskCardDimensions.radius),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: PretendardStyles.semiBold16.copyWith(
                                color: AppColors.black100,
                              ),
                            ),
                            SizedBox(height: TaskCardDimensions.contentSpacing),
                            ...widget.task.actions.map(
                              (action) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: TaskCardDimensions.actionSpacing,
                                ),
                                child: _buildActionRow(action),
                              ),
                            ),
                            SizedBox(
                              height: TaskCardDimensions.actionBottomSpacing,
                            ),
                            Text(
                              widget.task.schedule,
                              style: PretendardStyles.medium12.copyWith(
                                color: AppColors.gray100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CustomToggleSwitch(
                        initialValue: isEnabled,
                        onChanged: _handleSwitchChange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(Map<String, String> action) {
    return Row(
      children: [
        Icon(
          Icons.play_circle_outline,
          size: TaskCardDimensions.iconSize - 4,
          color: isEnabled ? AppColors.main100 : AppColors.gray80,
        ),
        SizedBox(width: TaskCardDimensions.iconSpacing),
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
