import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

class FilterToggleButton extends StatefulWidget {
  final ValueChanged<bool>? onChanged;

  const FilterToggleButton({super.key, this.onChanged});

  @override
  State<FilterToggleButton> createState() => _FilterToggleButtonState();
}

class _FilterToggleButtonState extends State<FilterToggleButton> {
  bool isUrgent = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isUrgent = !isUrgent;
        });
        widget.onChanged?.call(isUrgent);
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppColors.white100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 6),
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
