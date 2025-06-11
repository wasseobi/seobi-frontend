import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../../constants/dimensions/task_card_dimensions.dart';
import '../../common/title_card.dart';
import 'task_card.dart';
import 'task_card_list_view_model.dart';

class TaskCardList extends StatefulWidget {
  final double? width;
  final double? height;
  final TaskCardListViewModel? viewModel;

  const TaskCardList({super.key, this.width, this.height, this.viewModel});

  @override
  State<TaskCardList> createState() => _TaskCardListState();
}

class _TaskCardListState extends State<TaskCardList> {
  late final TaskCardListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? TaskCardListViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleCard(
              section: 'Autotask™',
              sectionKr: '자동업무',
              count: _viewModel.tasks.length,
            ),
            SizedBox(height: AppDimensions.paddingMedium),
            if (widget.height != null)
              Expanded(
                child: _buildTaskList(isExpanded: true),
              )
            else
              _buildTaskList(),
          ],
        );
      },
    );
  }

  Widget _buildTaskList({bool isExpanded = false}) {
    return ListView.builder(
      shrinkWrap: !isExpanded,
      physics: isExpanded ? null : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _viewModel.tasks.length,
      itemBuilder: (context, index) {
        final task = _viewModel.tasks[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _viewModel.tasks.length - 1
                ? 0
                : TaskCardDimensions.listSpacing,
          ),
          child: TaskCard(
            task: task,
            onChanged: (value) {
              _viewModel.toggleTaskStatus(task.id, value);
            },
          ),
        );
      },
    );
  }
}
