import 'package:flutter/material.dart';
import '../navigation/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Seobi App'),
      ),
      body: const Center(
        child: Text('Hello World!'),
      ),
    );
  }
}
