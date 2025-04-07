import 'package:flutter/material.dart';

class WriteCollaborativeDiaryScreen extends StatelessWidget {
  const WriteCollaborativeDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('협업 일기 작성')),
      body: const Center(child: Text('WriteCollaborativeDiaryScreen')),
    );
  }
}
