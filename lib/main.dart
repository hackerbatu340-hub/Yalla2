import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const YallaApp());

class YallaApp extends StatelessWidget {
  const YallaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sesli Oda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF12101A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12101A),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
