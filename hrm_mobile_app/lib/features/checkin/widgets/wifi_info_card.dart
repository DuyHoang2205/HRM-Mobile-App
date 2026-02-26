import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkin_state.dart';
import '../bloc/checkin_bloc.dart';

class WifiInfoCard extends StatelessWidget {
  const WifiInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInBloc, CheckInState>(
      buildWhen: (p, c) => p.isValidLocation != c.isValidLocation || p.locationName != c.locationName,
      builder: (_, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
            child: Row(
            children: [
              Icon(
                Icons.wifi,
                color: const Color(0xFF00C389),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết nối: Có kết nối WIFI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B1B2B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.isValidLocation ? (state.locationName) : 'Ngoài vùng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: state.isValidLocation ? const Color(0xFF0B1B2B) : const Color(0xFFFF3B30),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
