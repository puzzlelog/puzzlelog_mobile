import 'package:flutter/material.dart';

class WriteNormalDiaryScreen extends StatelessWidget {
  const WriteNormalDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일반 일기 작성')),
      body: const Center(child: Text('WriteNormalDiaryScreen')),
    );
  }
}
