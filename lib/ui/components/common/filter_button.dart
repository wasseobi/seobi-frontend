import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

class FilterToggleButton extends StatefulWidget {
  final ValueChanged<bool>? onChanged;
  final double? height;

  const FilterToggleButton({super.key, this.onChanged, this.height});

  @override
  State<FilterToggleButton> createState() => _FilterToggleButtonState();
}

class _FilterToggleButtonState extends State<FilterToggleButton> {
  bool isUrgent = false;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: TextButton(
        onPressed: () {
          setState(() {
            isUrgent = !isUrgent;
          });
          widget.onChanged?.call(isUrgent);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isUrgent ? Icons.update : Icons.apps,
              size: 20,
              color: AppColors.gray100,
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              isUrgent ? '임박순' : '등록순',
              style: PretendardStyles.semiBold14.copyWith(
                color: AppColors.gray100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
