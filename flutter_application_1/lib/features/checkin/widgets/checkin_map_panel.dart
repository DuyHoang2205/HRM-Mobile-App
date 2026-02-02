import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

class CheckInMapPanel extends StatelessWidget {
  const CheckInMapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // light grid feel
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),

          // Pin / avatar in center
          Center(
            child: BlocBuilder<CheckInBloc, CheckInState>(
              buildWhen: (p, c) => p.initials != c.initials,
              builder: (_, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C389),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.initials,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C389),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Privacy pill (left)
          Positioned(
            left: 14,
            bottom: 18,
            child: _PillButton(
              label: 'Quyền riêng tư',
              onTap: () => context.read<CheckInBloc>().add(const PrivacyPressed()),
              textColor: const Color(0xFF1976D2),
              icon: Icons.open_in_new,
              showIcon: false, // screenshot shows text only
            ),
          ),

          // Refresh location (right)
          Positioned(
            right: 14,
            bottom: 18,
            child: BlocBuilder<CheckInBloc, CheckInState>(
              buildWhen: (p, c) => p.isRefreshingLocation != c.isRefreshingLocation,
              builder: (_, state) {
                return _PillButton(
                  label: state.isRefreshingLocation ? 'Đang làm mới...' : 'Làm mới vị trí',
                  onTap: () => context.read<CheckInBloc>().add(const RefreshLocationPressed()),
                  textColor: const Color(0xFF00C389),
                  icon: Icons.refresh,
                  showIcon: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final IconData icon;
  final bool showIcon;

  const _PillButton({
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.icon,
    required this.showIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;

    const step = 34.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
