import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MelhorRotaApp());
}

class MelhorRotaApp extends StatelessWidget {
  const MelhorRotaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melhor Rota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
