import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/top_chrome.dart';
import '../widgets/schedule_section.dart';
import '../widgets/shift_card.dart';
import '../../checkin/view/checkin_page.dart';
import '../../checkin/models/checkin_result.dart';
import '../widgets/folder_section.dart';
import '../models/folder_item.dart';
import '../../attendance/view/attendance_page.dart';
import '../../overtime/view/overtime_list_page.dart';
import '../../leave/view/leave_list_page.dart';

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
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          body: Container(
            color: const Color(0xFFF6F7FB),
            child: Stack(
              children: [
                Column(
                  children: [
                    const TopChrome(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: 14,
                          bottom: MediaQuery.of(context).padding.bottom + 120,
                        ),
                        children: [
                          const ScheduleSection(),
                          const SizedBox(height: 16),
                          ShiftCard(
                            onTap: () async {
                              // Navigates to the working Check-In flow
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CheckInPage(
                                    isCheckoutMode: state.isCheckoutMode,
                                    checkedInAt: state.checkedInAt,
                                  ),
                                ),
                              );

                              if (context.mounted && result is CheckInResult) {
                                context.read<HomeBloc>().add(CheckResultArrived(
                                  timestamp: result.timestamp,
                                  isCheckIn: result.action == CheckAction.checkIn,
                                ));
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          FolderSection(
                            onTap: (action) async {
                              switch (action) {
                                case FolderAction.attendance:
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AttendancePage()),
                                  );

                                  if (context.mounted) {
                                    if (result is CheckInResult) {
                                      context.read<HomeBloc>().add(CheckResultArrived(
                                        timestamp: result.timestamp,
                                        isCheckIn: result.action == CheckAction.checkIn,
                                      ));
                                    } else {
                                      context.read<HomeBloc>().add(const AttendanceLogsRequested());
                                    }
                                  }
                                  break;
                                case FolderAction.overtime:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const OvertimeListPage()),
                                  );
                                  break;
                                case FolderAction.leave:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const LeaveListPage()),
                                  );
                                  break;
                                default:
                                  break;
                              }
                            },
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }
}