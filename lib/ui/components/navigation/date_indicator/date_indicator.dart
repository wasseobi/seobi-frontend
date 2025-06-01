import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'date_indicator_view_model.dart';

class DateIndicator extends StatefulWidget {
  const DateIndicator({super.key});

  @override
  State<DateIndicator> createState() => _DateIndicatorState();
}

class _DateIndicatorState extends State<DateIndicator> {
  late final DateIndicatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DateIndicatorViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [          SizedBox(
            width: 78,
            child: Text(
              _viewModel.formattedDate,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.06,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 78,
            child: Text(
              _viewModel.dayOfWeek,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
