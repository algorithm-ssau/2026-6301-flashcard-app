import 'package:flutter/material.dart';

void main() {
  runApp(const FlashGeniusApp());
}

class FlashGeniusApp extends StatelessWidget {
  const FlashGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    );
  }
}
