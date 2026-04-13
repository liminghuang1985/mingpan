import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/home_page.dart';

void main() {
  runApp(const ProviderScope(child: MingPanApp()));
}

class MingPanApp extends StatelessWidget {
  const MingPanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '命盘',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
