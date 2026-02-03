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
import '../../../core/demo/demo_attendance_store.dart';
import '../../attendance/models/attendance_log.dart';
import '../widgets/folder_section.dart';
import '../models/folder_item.dart';

import '../../attendance/view/attendance_page.dart';


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
      return Container(
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
                          final homeState = context.read<HomeBloc>().state;
                          
                          // 1. Navigate to the confirmation page first
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CheckInPage(
                                isCheckoutMode: homeState.isCheckoutMode,
                                checkedInAt: homeState.checkedInAt,
                              ),
                            ),
                          );

                          // 2. Only if the user confirmed (result is CheckInResult), then trigger the Bloc
                          if (result is CheckInResult) {
                            context.read<HomeBloc>().add(const CheckInTapped());
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      FolderSection(
                        onTap: (action) async {
                          switch (action) {
                          case FolderAction.attendance:
                                  // Points to the history list of "Vào ca / Ra ca" entries
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AttendancePage()),
                                  );
                          break;

                            // case FolderAction.timesheet: // This is 'Bảng công'
                            //   // Direct to the history/list page
                            //   Navigator.of(context).push(
                            //     MaterialPageRoute(builder: (_) => const AttendancePage()),
                            //   );
                            //   break;

                            default:
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chức năng đang phát triển')),
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
            // This shows the spinner when the Bloc is talking to the NestJS backend
            if (state.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      );
    },
  );
}}