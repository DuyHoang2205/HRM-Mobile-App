import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../models/checkin_result.dart';
import '../widgets/checkin_topbar.dart';
import '../widgets/checkin_map_panel.dart';
import '../widgets/wifi_info_card.dart';
import '../widgets/shift_option_tile.dart';
import '../widgets/confirm_button.dart';

class CheckInPage extends StatelessWidget {
  final bool isCheckoutMode;
  final DateTime? checkedInAt;

  const CheckInPage({
    super.key,
    required this.isCheckoutMode,
    required this.checkedInAt,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckInBloc(
        isCheckoutMode: isCheckoutMode,
        checkedInAt: checkedInAt,
      )..add(const CheckInStarted()),
      child: const _CheckInView(),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView();

  Future<void> _showSuccessDialog(BuildContext context, String msg) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckInBloc, CheckInState>(
      listenWhen: (p, c) {
        if (c.successMessage != null && p.successMessage != c.successMessage) return true;
        if (c.errorMessage != null && p.errorMessage != c.errorMessage) return true;
        return false;
      },
      listener: (context, state) async {
        if (state.successMessage != null) {
          await _showSuccessDialog(context, state.successMessage!);
          Navigator.of(context).pop(
            CheckInResult(
              action: state.isCheckoutMode ? CheckAction.checkOut : CheckAction.checkIn,
              timestamp: state.actionTimestamp!,
            ),
          );
        }
        if (state.errorMessage != null) {
          await _showSuccessDialog(context, state.errorMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: BlocBuilder<CheckInBloc, CheckInState>(
                  builder: (_, state) {
                    return CheckInTopBar(
                      title: state.isCheckoutMode ? 'Ra ca' : 'Vào ca',
                      onClose: () => Navigator.of(context).pop(),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 90, // leave space for sticky btn
                ),
                children: [
                  const CheckInMapPanel(),
                  const SizedBox(height: 14),
                  const WifiInfoCard(),
                  const SizedBox(height: 14),

                  BlocBuilder<CheckInBloc, CheckInState>(
                    buildWhen: (p, c) =>
                        p.warning != c.warning || p.isCheckoutMode != c.isCheckoutMode,
                    builder: (_, state) {
                      return Text(
                        state.warning,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF3B30),
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  BlocBuilder<CheckInBloc, CheckInState>(
                    buildWhen: (p, c) => p.options != c.options || p.selectedShiftId != c.selectedShiftId,
                    builder: (_, state) {
                      return Column(
                        children: [
                          for (final opt in state.options) ...[
                            ShiftOptionTile(option: opt),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // sticky confirm
            Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: const ConfirmButton(),
            ),
          ],
        ),
      ),
    );
  }
}
