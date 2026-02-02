import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkin_state.dart';
import '../bloc/checkin_bloc.dart';

class WifiInfoCard extends StatelessWidget {
  const WifiInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInBloc, CheckInState>(
      buildWhen: (p, c) =>
          p.wifiName != c.wifiName || p.bssid != c.bssid || p.wifiLabelRight != c.wifiLabelRight,
      builder: (_, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi, color: Color(0xFF9AA6B2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kết nối: ${state.wifiName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1B2B),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.wifiLabelRight,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1B2B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(bssid: ${state.bssid})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9AA6B2),
                      fontWeight: FontWeight.w500,
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
