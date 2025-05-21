import 'package:flutter/material.dart';
import 'features/speech/speech_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SpeechScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
