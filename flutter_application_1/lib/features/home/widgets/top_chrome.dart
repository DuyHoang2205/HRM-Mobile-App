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
        // Ensures the status bar icons (clock, battery) are clearly visible 
        // against the white notch area on iOS/Android.
        statusBarBrightness: Brightness.light, 
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Block 1: Status bar area
          // Keeping this white to match the clean, professional top-inset.
          SizedBox(
            height: topInset,
            child: const ColoredBox(color: Colors.white),
          ),

          // Block 2: HomeHeader
          // This contains the user profile and notification bell. 
          // Ensure that HomeHeader only navigates to functional demo pages.
          const HomeHeader(),
        ],
      ),
    );
  }
}