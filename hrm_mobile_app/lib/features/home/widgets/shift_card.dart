import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class ShiftCard extends StatefulWidget {
  final VoidCallback onTap;

  const ShiftCard({super.key, required this.onTap});

  @override
  State<ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<ShiftCard> {
  // Timer removed as we rely on HomeBloc state for time (or we can bring back 10s timer if we want live update of now, but user asked for Checkin Time)
  // Actually, if we want "Vào ca" to show current time, we still need a timer to refresh the UI.
  // But user said "time was supposed to follow the check in and check out time". 
  // If "Vào ca", I am NOT checked in. So what time? "Giờ hiện tại" (Current Time).
  // So I should keep the timer to refresh UI if not checked in.

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final isCheckout = state.isCheckoutMode;

          final bgColors = isCheckout
              ? const [Color(0xFFFF3B30), Color(0xFFFF5E57)] 
              : const [Color(0xFF123F74), Color(0xFF0B2D5B)]; // Blue

          final iconColor = isCheckout ? const Color(0xFFFF3B30) : const Color(0xFF0B2D5B);
          final shadowColor = isCheckout ? const Color(0xFFFF3B30) : const Color(0xFF0B2D5B);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              child: Ink(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: bgColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.shiftLabel, 
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.shiftTime, // Use state time (Check-in time or Current time)
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded, 
                        size: 38, 
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
