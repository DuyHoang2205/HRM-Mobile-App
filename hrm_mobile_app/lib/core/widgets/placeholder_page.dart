import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0B1B2B),
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title (coming soon)',
          style: const TextStyle(
            color: Color(0xFF9AA6B2),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
