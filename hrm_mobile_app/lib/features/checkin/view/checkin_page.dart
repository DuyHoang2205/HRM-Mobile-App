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
import 'package:intl/intl.dart';

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
      create: (_) =>
          CheckInBloc(isCheckoutMode: isCheckoutMode, checkedInAt: checkedInAt)
            ..add(const CheckInStarted()),
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

  Future<void> _showEarlyCheckoutDialog(BuildContext context, String msg) async {
    final noteController = TextEditingController();
    final bloc = context.read<CheckInBloc>();
    final wordReasons = bloc.state.wordReasons;
    String? selectedReasonCode = wordReasons.isNotEmpty ? wordReasons.first.code : null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cảnh Báo Ra Ca Sớm', style: TextStyle(color: Colors.red)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(msg),
                  const SizedBox(height: 16),
                  if (wordReasons.isNotEmpty) ...[
                    const Text('Lý do:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedReasonCode,
                          items: wordReasons.map((r) => DropdownMenuItem(
                                value: r.code,
                                child: Text(r.name),
                              )).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedReasonCode = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Ghi chú chi tiết:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Nhập ghi chú (tùy chọn)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Cần chọn Reason Code, nếu List rỗng thì bắt buộc nhập tay note
                    if (selectedReasonCode == null && noteController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn lý do hoặc nhập ghi chú giải trình!')),
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Vẫn Ra Ca', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirmed == true && context.mounted) {
      bloc.add(ConfirmPressed(
        force: true, 
        reasonCode: selectedReasonCode ?? 'KHAC',
        note: noteController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckInBloc, CheckInState>(
      listenWhen: (p, c) {
        if (c.successMessage != null && p.successMessage != c.successMessage) {
          return true;
        }
        if (c.errorMessage != null && p.errorMessage != c.errorMessage) {
          return true;
        }
        if (c.earlyCheckoutWarningMessage != null && p.earlyCheckoutWarningMessage != c.earlyCheckoutWarningMessage) {
          return true;
        }
        return false;
      },
      listener: (context, state) async {
        if (state.successMessage != null) {
          await _showSuccessDialog(context, state.successMessage!);
          if (!context.mounted) return;
          Navigator.of(context).pop(
            CheckInResult(
              action: state.isCheckoutMode
                  ? CheckAction.checkOut
                  : CheckAction.checkIn,
              timestamp: state.actionTimestamp!,
            ),
          );
        }
        if (state.errorMessage != null) {
          await _showSuccessDialog(context, state.errorMessage!);
        }
        if (state.earlyCheckoutWarningMessage != null) {
          await _showEarlyCheckoutDialog(context, state.earlyCheckoutWarningMessage!);
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
                  bottom:
                      MediaQuery.of(context).padding.bottom +
                      90, // leave space for sticky btn
                ),
                children: [
                  const CheckInMapPanel(),
                  const SizedBox(height: 14),
                  const WifiInfoCard(),
                  const SizedBox(height: 14),

                  BlocBuilder<CheckInBloc, CheckInState>(
                    buildWhen: (p, c) =>
                        p.warning != c.warning ||
                        p.isCheckoutMode != c.isCheckoutMode ||
                        p.shiftEndTime != c.shiftEndTime,
                    builder: (_, state) {
                      String? shiftHint;
                      if (state.shiftEndTime != null) {
                        final end = state.shiftEndTime!;
                        final hh = end.hour.toString().padLeft(2, '0');
                        final mm = end.minute.toString().padLeft(2, '0');
                        shiftHint = state.isCheckoutMode
                            ? 'Giờ kết thúc ca: $hh:$mm'
                            : 'Ca hôm nay kết thúc lúc: $hh:$mm';
                      }

                      return Text(
                        shiftHint == null
                            ? state.warning
                            : '${state.warning}\n$shiftHint',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: state.shiftEndTime == null
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFF0B1B2B),
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  BlocBuilder<CheckInBloc, CheckInState>(
                    buildWhen: (p, c) =>
                        p.options != c.options ||
                        p.selectedShiftId != c.selectedShiftId ||
                        p.shiftEndTime != c.shiftEndTime,
                    builder: (_, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.isCheckoutMode &&
                              state.shiftEndTime != null) ...[
                            Text(
                              'Giờ Ra ca quy định: ${DateFormat('HH:mm').format(state.shiftEndTime!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
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
