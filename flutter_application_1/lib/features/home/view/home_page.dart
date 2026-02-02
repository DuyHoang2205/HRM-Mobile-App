import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../widgets/top_chrome.dart';
import '../widgets/schedule_section.dart';
import '../widgets/shift_card.dart';
import '../../checkin/view/checkin_page.dart';
import '../../checkin/models/checkin_result.dart';
import '../../../core/demo/demo_attendance_store.dart';
import '../../attendance/models/attendance_log.dart';
import '../widgets/folder_section.dart';
import '../models/folder_item.dart';

import '../../attendance/view/attendance_page.dart';
// import '../../../core/widgets/placeholder_page.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    return Container(
      color: const Color(0xFFF6F7FB),
      child: Column(
        children: [
          const TopChrome(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 120),
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

                    if (result is CheckInResult) {
                      context.read<HomeBloc>().add(
                        CheckResultArrived(
                          timestamp: result.timestamp,
                          isCheckIn: result.action == CheckAction.checkIn,
                        ),
                      );

                      final action = result.action == CheckAction.checkIn
                          ? AttendanceAction.checkIn
                          : AttendanceAction.checkOut;

                      DemoAttendanceStore.add(
                        AttendanceLog(
                          timestamp: result.timestamp,
                          action: action,
                          userName: context.read<HomeBloc>().state.name,
                          subtitle: 'Vào/Ra ca trên điện thoại',
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
                          MaterialPageRoute(builder: (_) => const AttendancePage()),
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
      ),
    );
  }
}
