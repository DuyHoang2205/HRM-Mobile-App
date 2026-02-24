import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInBloc, CheckInState>(
      buildWhen: (p, c) => 
        p.isConfirming != c.isConfirming || 
        p.isValidLocation != c.isValidLocation || 
        p.isValidWifi != c.isValidWifi,
      builder: (_, state) {
        return SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C389),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: (state.isConfirming || !state.isValidLocation || !state.isValidWifi)
                ? null
                : () => context.read<CheckInBloc>().add(const ConfirmPressed()),
            child: state.isConfirming
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
          ),
        );
      },
    );
  }
}
