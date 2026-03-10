import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/attendance_day_policy.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';
import '../models/attendance_log.dart';

class TimesheetPage extends StatefulWidget {
  const TimesheetPage({super.key});

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // We have 4 tabs: Công tháng, Công tuần, Thống kê, Danh sách
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFFEF5350),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFEF5350),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Công tháng'),
              Tab(text: 'Công tuần'),
              Tab(text: 'Thống kê'),
              Tab(text: 'Danh sách'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _MonthlyTimesheetTab(),
              _WeeklyTimesheetTab(),
              Center(child: Text('Đang phát triểnThống kê')),
              Center(child: Text('Đang phát triển: Danh sách')),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyTimesheetTab extends StatelessWidget {
  const _MonthlyTimesheetTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading && state.logs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final cellDataList = _buildCalendar(
          state.filterDate,
          state.logs,
          state.dayPolicies,
        );

        return Column(
          children: [
            // Days of week header
            Container(
              color: const Color(
                0xFFF5F6FA,
              ), // Light grey background for header
              child: Row(
                children: const [
                  _DayHeader('T2'),
                  _DayHeader('T3'),
                  _DayHeader('T4'),
                  _DayHeader('T5'),
                  _DayHeader('T6'),
                  _DayHeader('T7'),
                  _DayHeader('CN'),
                ],
              ),
            ),
            // Calendar grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                childAspectRatio:
                    0.65, // Adjust height of cells relative to width
                physics: const BouncingScrollPhysics(),
                children: cellDataList
                    .map((data) => _TimesheetCell(data: data))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TimesheetCellData> _buildCalendar(
    DateTime monthDate,
    List<AttendanceLog> logs,
    Map<String, AttendancePolicyConfig> dayPolicies,
  ) {
    // 1. Group logs by yyyy-MM-dd
    final Map<String, List<AttendanceLog>> grouped = {};
    for (var log in logs) {
      final key =
          "${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    int offset = firstDayOfMonth.weekday - 1;
    int totalCells = ((lastDayOfMonth.day + offset) / 7).ceil() * 7;

    final startDate = firstDayOfMonth.subtract(Duration(days: offset));
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayDate = DateTime(now.year, now.month, now.day);

    List<_TimesheetCellData> result = [];
    for (int i = 0; i < totalCells; i++) {
      final current = startDate.add(Duration(days: i));
      final key =
          "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";

      bool isCurrentMonth = current.month == monthDate.month;
      bool isSunday = current.weekday == 7;
      bool isSaturday = current.weekday == 6;
      bool isPublicHoliday =
          (current.month == 1 && current.day == 1) ||
          (current.month == 4 && current.day == 30) ||
          (current.month == 5 && current.day == 1) ||
          (current.month == 9 && current.day == 2);

      final dayLogs = grouped[key] ?? [];
      _DayStatus status = _DayStatus.none;
      final eval = AttendanceDayPolicy.evaluate(
        date: current,
        logs: dayLogs,
        config: dayPolicies[key],
      );

      if (isCurrentMonth && current.compareTo(todayDate) <= 0) {
        if (eval.hasCompletePair && eval.meetsMinimum) {
          status = _DayStatus.normal;
        } else if (dayLogs.isNotEmpty) {
          status = _DayStatus.missing;
        } else {
          if (isSunday || isSaturday) {
            status = _DayStatus.none;
          } else {
            status = _DayStatus.missing;
          }
        }
      }

      String dateStr = current.day.toString().padLeft(2, '0');
      if (current.day == 1) {
        dateStr = "$dateStr/${current.month.toString().padLeft(2, '0')}";
      }

      result.add(
        _TimesheetCellData(
          dateStr: dateStr,
          status: status,
          isToday: key == todayStr,
          isHoliday: isSunday || isSaturday,
          isPublicHoliday: isPublicHoliday,
          isCurrentMonth: isCurrentMonth,
        ),
      );
    }
    return result;
  }
}

class _WeeklyTimesheetTab extends StatelessWidget {
  const _WeeklyTimesheetTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading && state.logs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final cellDataList = _buildWeekly(
          state.filterDate,
          state.logs,
          state.dayPolicies,
        );

        return Column(
          children: [
            // Days of week header
            Container(
              color: const Color(0xFFF5F6FA), // Light grey background
              child: const Row(
                children: [
                  _DayHeader('T2'),
                  _DayHeader('T3'),
                  _DayHeader('T4'),
                  _DayHeader('T5'),
                  _DayHeader('T6'),
                  _DayHeader('T7'),
                  _DayHeader('CN'),
                ],
              ),
            ),
            // Weekly row
            SizedBox(
              height: 120, // Approximate height for one week row
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cellDataList
                    .map((data) => Expanded(child: _TimesheetCell(data: data)))
                    .toList(),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Chi tiết công tuần',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TimesheetCellData> _buildWeekly(
    DateTime monthDate,
    List<AttendanceLog> logs,
    Map<String, AttendancePolicyConfig> dayPolicies,
  ) {
    final Map<String, List<AttendanceLog>> grouped = {};
    for (var log in logs) {
      final key =
          "${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final offset = todayDate.weekday - 1;
    final startOfWeek = todayDate.subtract(Duration(days: offset));
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    List<_TimesheetCellData> result = [];
    for (int i = 0; i < 7; i++) {
      final current = startOfWeek.add(Duration(days: i));
      final key =
          "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";

      bool isCurrentMonth = current.month == todayDate.month;
      bool isSunday = current.weekday == 7;
      bool isSaturday = current.weekday == 6;
      bool isPublicHoliday =
          (current.month == 1 && current.day == 1) ||
          (current.month == 4 && current.day == 30) ||
          (current.month == 5 && current.day == 1) ||
          (current.month == 9 && current.day == 2);

      final dayLogs = grouped[key] ?? [];
      _DayStatus status = _DayStatus.none;
      final eval = AttendanceDayPolicy.evaluate(
        date: current,
        logs: dayLogs,
        config: dayPolicies[key],
      );

      if (isCurrentMonth && current.compareTo(todayDate) <= 0) {
        if (eval.hasCompletePair && eval.meetsMinimum) {
          status = _DayStatus.normal;
        } else if (dayLogs.isNotEmpty) {
          status = _DayStatus.missing;
        } else {
          if (isSunday || isSaturday) {
            status = _DayStatus.none;
          } else {
            status = _DayStatus.missing;
          }
        }
      }

      String dateStr = current.day.toString().padLeft(2, '0');
      if (current.day == 1) {
        dateStr = "$dateStr/${current.month.toString().padLeft(2, '0')}";
      }

      result.add(
        _TimesheetCellData(
          dateStr: dateStr,
          status: status,
          isToday: key == todayStr,
          isHoliday: isSunday || isSaturday,
          isPublicHoliday: isPublicHoliday,
          isCurrentMonth: isCurrentMonth,
        ),
      );
    }
    return result;
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

enum _DayStatus { none, normal, missing, leave, emptyZero }

class _TimesheetCellData {
  final String dateStr;
  final _DayStatus status;
  final bool isToday;
  final bool isHoliday;
  final bool isPublicHoliday;
  final bool isCurrentMonth;

  _TimesheetCellData({
    required this.dateStr,
    this.status = _DayStatus.none,
    this.isToday = false,
    this.isHoliday = false,
    this.isPublicHoliday = false,
    this.isCurrentMonth = true,
  });
}

class _TimesheetCell extends StatelessWidget {
  final _TimesheetCellData data;

  const _TimesheetCell({required this.data});

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFFCEF0D9); // default light green
    if (!data.isCurrentMonth) {
      bgColor = const Color(0xFFF9FAFC); // lighter grey for other month
    } else if (data.isToday) {
      bgColor = const Color(0xFFA1C1FE); // light blue
    } else if (data.isHoliday) {
      bgColor = Colors.white;
    }

    String statusText = '';
    Color statusColor = Colors.transparent;

    switch (data.status) {
      case _DayStatus.normal:
        statusText = 'N';
        statusColor = const Color(0xFF2CAD61); // Green
        break;
      case _DayStatus.missing:
        statusText = 'x';
        statusColor = const Color(0xFFECAE41); // Yellow/Orange
        break;
      case _DayStatus.leave:
        statusText = '1L';
        statusColor = const Color(0xFFD63F3A); // Red
        break;
      case _DayStatus.emptyZero:
        statusText = '0';
        statusColor = Colors.black;
        break;
      case _DayStatus.none:
        break;
    }

    Widget cell = Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
          right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.dateStr,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (data.isPublicHoliday) ...[
                const SizedBox(width: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935), // Red dot indicator
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          if (statusText.isNotEmpty)
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
        ],
      ),
    );

    if (!data.isCurrentMonth) {
      return Opacity(opacity: 0.35, child: cell);
    }

    return cell;
  }
}
