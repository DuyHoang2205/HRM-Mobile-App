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
import '../../attendance/models/attendance_log.dart';
import '../widgets/folder_section.dart';
import '../models/folder_item.dart';
import '../../attendance/view/attendance_page.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DioClient _dioClient = DioClient();

  Future<void> _fetchAttendanceLogs(BuildContext context) async {
    try {
      final employeeId = await AuthHelper.getEmployeeId();
      if (employeeId == null) {
        print('DEBUG: No employeeId, skipping attendance fetch');
        return;
      }

      final siteID = await AuthHelper.getSiteId();
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30)); // Last 30 days
      // Add 1 day to include today's records if backend uses <= date (midnight)
      final toDate = now.add(const Duration(days: 1));

      print('DEBUG: Fetching attendance from ${_formatDate(fromDate)} to ${_formatDate(toDate)}');
      
      final requestData = {
        'employeeId': employeeId,
        'fromDate': _formatDate(fromDate),
        'toDate': _formatDate(toDate),
      };
      
      print('DEBUG: API endpoint: attendance/byEmployee/$siteID');
      print('DEBUG: Request data: $requestData');

      final response = await _dioClient.dio.post(
        'attendance/byEmployee/$siteID',
        data: requestData,
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data type: ${response.data.runtimeType}');
      print('DEBUG: Response data: ${response.data}');

      final List<dynamic> raw = response.data is List ? response.data as List : const [];
      final logs = raw.map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      print('DEBUG: Fetched ${logs.length} attendance logs');
      for (final log in logs.take(5)) {
        print('DEBUG: Log date: ${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}');
      }

      if (context.mounted) {
        context.read<HomeBloc>().add(AttendanceLogsLoaded(logs));
        print('DEBUG: Sent ${logs.length} logs to HomeBloc');
      }
    } catch (e) {
      print('DEBUG: Error fetching attendance: $e');
      // Silently fail - dots just won't show
    }
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(const HomeStarted()),
      child: Builder(
        builder: (context) {
          // Fetch attendance logs after BlocProvider is ready
          Future.microtask(() => _fetchAttendanceLogs(context));
          return _HomeView(
            onRefresh: () => _fetchAttendanceLogs(context),
          );
        },
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback? onRefresh;
  const _HomeView({this.onRefresh});

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

                          if (result is CheckInResult) {
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
                          print('DEBUG: Folder tapped: $action');
                          switch (action) {
                          case FolderAction.attendance:
                                  print('DEBUG: Navigating to AttendancePage...');
                                  // Points to the history list of "Vào ca / Ra ca" entries
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AttendancePage()),
                                  ).then((_) {
                                    // Refresh logic when returning from Attendance Page
                                    print('DEBUG: Returned from AttendancePage, refreshing logs...');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Updating Home...'), duration: Duration(milliseconds: 500)),
                                    );
                                    onRefresh?.call();
                                  });
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