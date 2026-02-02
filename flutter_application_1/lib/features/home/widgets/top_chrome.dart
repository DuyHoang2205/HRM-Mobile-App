import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_header.dart';

class TopChrome extends StatelessWidget {
  const TopChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light, // iOS: dark icons on white
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Block 1: notch/status bar area (white)
          SizedBox(
            height: topInset,
            child: const ColoredBox(color: Colors.white),
          ),

          // Block 2: blue header content
          const HomeHeader(),
        ],
      ),
    );
  }
}
