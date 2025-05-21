import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.brightness_6),
      tooltip: '테마 변경',
      onPressed: () {
        // TODO: 테마 변경 기능 추가
      },
    );
  }
}
