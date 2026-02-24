import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

class CheckInMapPanel extends StatefulWidget {
  const CheckInMapPanel({super.key});

  @override
  State<CheckInMapPanel> createState() => _CheckInMapPanelState();
}

class _CheckInMapPanelState extends State<CheckInMapPanel> {
  final MapController _mapController = MapController();
  bool _hasMovedOnce = false;
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // MAP LAYER
          BlocConsumer<CheckInBloc, CheckInState>(
            listenWhen: (p, c) =>
                p.currentLatitude != c.currentLatitude ||
                p.currentLongitude != c.currentLongitude ||
                p.isRefreshingLocation != c.isRefreshingLocation,
            listener: (context, state) {
              if (state.currentLatitude != null && state.currentLongitude != null && _isMapReady) {
                // Move map to user if it's the first fix or user requests refresh
                if (!_hasMovedOnce || state.isRefreshingLocation) {
                  _mapController.move(
                    LatLng(state.currentLatitude!, state.currentLongitude!),
                    16.0,
                  );
                  _hasMovedOnce = true;
                }
              }
            },
            builder: (context, state) {
              if (state.currentLatitude == null || state.currentLongitude == null) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 8),
                      Text('Đang lấy vị trí...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final userPos = LatLng(state.currentLatitude!, state.currentLongitude!);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userPos,
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(
                    // Disable rotation for simpler UX
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
                  ),
                  onMapReady: () {
                    _isMapReady = true;
                    if (!_hasMovedOnce) {
                       _mapController.move(userPos, 16.0);
                       _hasMovedOnce = true;
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dpt.hrm_app', // Generic package name
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userPos,
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C389).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Color(0xFF00C389),
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // If we had the target match, we could draw a circle:
                  // CircleLayer(circles: [ ... ])
                ],
              );
            },
          ),

          // OVERLAY BUTTONS
          
          // Privacy pill (left)
          Positioned(
            left: 14,
            bottom: 14,
            child: _PillButton(
              label: 'Quyền riêng tư',
              onTap: () => context.read<CheckInBloc>().add(const PrivacyPressed()),
              textColor: const Color(0xFF1976D2),
              icon: Icons.open_in_new,
              showIcon: false, 
            ),
          ),

          // Refresh location (right)
          Positioned(
            right: 14,
            bottom: 14,
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
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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