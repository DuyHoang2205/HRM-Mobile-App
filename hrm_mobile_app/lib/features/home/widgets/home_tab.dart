import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../widgets/top_chrome.dart';
import '../widgets/schedule_section.dart';
import '../widgets/shift_card.dart';
import '../../checkin/view/checkin_page.dart';
import '../../checkin/models/checkin_result.dart';

import '../widgets/folder_section.dart';
import '../../attendance/view/attendance_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopChrome(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 14, bottom: 20),
            children: [
              const ScheduleSection(),
              const SizedBox(height: 16),

              ShiftCard(
                onTap: () async {
                  final homeState = context.read<HomeBloc>().state;

                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckInPage(
                        isCheckoutMode: homeState.isCheckoutMode,
                        checkedInAt: homeState.checkedInAt,
                      ),
                    ),
                  );

                  if (!context.mounted) return;
                  if (result is CheckInResult) {
                    context.read<HomeBloc>().add(
                      CheckResultArrived(
                        timestamp: result.timestamp,
                        isCheckIn: result.action == CheckAction.checkIn,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 18),

              FolderSection(
                onTap: (action) {
                  switch (action) {
                    case FolderAction.attendance:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AttendancePage(),
                        ),
                      );
                      break;
                    default:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                  }
                },
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ],
    );
  }
}
