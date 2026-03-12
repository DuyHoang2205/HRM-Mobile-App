import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../models/daily_summary.dart';

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
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: const [
                  _MonthlyTimesheetTab(),
                  _WeeklyTimesheetTab(),
                  Center(child: Text('Đang phát triển: Thống kê')),
                  Center(child: Text('Đang phát triển: Danh sách')),
                ],
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'legendBtn',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () => _showLegendDialog(context),
                  tooltip: 'Ký hiệu chấm công',
                  child: const Icon(Icons.info_outline, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ký hiệu chấm công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              '1',
              'Đủ công (quẹt đủ và đủ giờ)',
              const Color(0xFF2CAD61),
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              '0',
              'Lỗi công (thiếu In/Out) / Không phát sinh công',
              const Color(0xFFECAE41), 
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              'x/P',
              'Nửa ngày công + nửa ngày phép',
              const Color(0xFFECAE41), 
            ),
            const SizedBox(height: 12),
            _buildLegendItem('P', 'Nghỉ phép', const Color(0xFFD63F3A)),
            const SizedBox(height: 12),
            _buildLegendItem('C', 'Công tác', const Color(0xFF4F8DFD)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String symbol, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            symbol,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _MonthlyTimesheetTab extends StatefulWidget {
  const _MonthlyTimesheetTab();

  @override
  State<_MonthlyTimesheetTab> createState() => _MonthlyTimesheetTabState();
}

class _MonthlyTimesheetTabState extends State<_MonthlyTimesheetTab> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    // Request initial data
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMonth());
  }

  void _fetchMonth() {
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    context.read<AttendanceBloc>().add(
      AttendanceTimesheetDateChanged(start: _currentMonth, end: end),
    );
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _fetchMonth();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _fetchMonth();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final cellDataList = _buildCalendar(
          _currentMonth,
          state.dailySummaries,
        );

        return Column(
          children: [
            // Month Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF0B1B2B)),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    'Tháng ${_currentMonth.month.toString().padLeft(2, '0')}/${_currentMonth.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C389)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF0B1B2B)),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
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
    Map<String, DailySummary> dailySummaries,
  ) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    int offset = firstDayOfMonth.weekday - 1;
    int totalCells = ((lastDayOfMonth.day + offset) / 7).ceil() * 7;

    final startDate = firstDayOfMonth.subtract(Duration(days: offset));
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    // todayDate used for isToday cell highlight only

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

      _DayStatus status = _DayStatus.none;
      String displaySymbol = '';
      DailySummary? summary;

      if (isCurrentMonth) {
        if (dailySummaries.containsKey(key)) {
          summary = dailySummaries[key]!;
          displaySymbol = summary.daySymbol;

          if (summary.daySymbol == '0') {
            status = _DayStatus.none; // Empty day
          } else if (summary.daySymbol == '1' || summary.daySymbol == '1.0') {
            status = _DayStatus.normal;
          } else if (summary.daySymbol.contains('x')) {
            status = _DayStatus.missing;
            displaySymbol = (summary.daySymbol == 'x') ? '0' : summary.daySymbol;
          } else {
            status = _DayStatus.leave;
          }
        } else {
          // Ngày trong tháng nhưng không có data từ API → để trống, không tự gán 'x'
          // (tránh false positive khi API chưa load xong hoặc ngày chưa có log)
          status = _DayStatus.none;
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
          displaySymbol: displaySymbol,
          summary: summary,
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

class _WeeklyTimesheetTab extends StatefulWidget {
  const _WeeklyTimesheetTab();

  @override
  State<_WeeklyTimesheetTab> createState() => _WeeklyTimesheetTabState();
}

class _WeeklyTimesheetTabState extends State<_WeeklyTimesheetTab> {
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final offset = now.weekday - 1;
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: offset));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWeek());
  }

  void _fetchWeek() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    context.read<AttendanceBloc>().add(
      AttendanceTimesheetDateChanged(start: _currentWeekStart, end: end),
    );
  }

  void _prevWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _fetchWeek();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _fetchWeek();
  }

  String _weekLabel() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    String f(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${f(_currentWeekStart)} - ${f(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final cellDataList = _buildWeekly(
          _currentWeekStart,
          state.dailySummaries,
        );

        return Column(
          children: [
            // Week Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF0B1B2B)),
                    onPressed: _prevWeek,
                  ),
                  Text(
                    _weekLabel(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00C389)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF0B1B2B)),
                    onPressed: _nextWeek,
                  ),
                ],
              ),
            ),
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
    DateTime startOfWeek,
    Map<String, DailySummary> dailySummaries,
  ) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
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

      _DayStatus status = _DayStatus.none;
      String displaySymbol = '';
      DailySummary? summary;

      if (isCurrentMonth) {
        if (dailySummaries.containsKey(key)) {
          summary = dailySummaries[key]!;
          displaySymbol = summary.daySymbol;

          if (summary.daySymbol == '0') {
            status = _DayStatus.none; // Empty day
          } else if (summary.daySymbol == '1' || summary.daySymbol == '1.0') {
            status = _DayStatus.normal;
          } else if (summary.daySymbol.contains('x')) {
            status = _DayStatus.missing;
            displaySymbol = '0'; // Hiển thị đè 0 thay vì x
          } else {
            status = _DayStatus.leave;
          }
        } else if (current.compareTo(todayDate) <= 0) {
          if (!isSunday && !isSaturday) {
            status = _DayStatus.missing;
            displaySymbol = '0'; // Hiển thị đè 0 thay vì x
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
          displaySymbol: displaySymbol,
          summary: summary,
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
  final String? displaySymbol;
  final DailySummary? summary;
  final bool isToday;
  final bool isHoliday;
  final bool isPublicHoliday;
  final bool isCurrentMonth;

  _TimesheetCellData({
    required this.dateStr,
    this.status = _DayStatus.none,
    this.displaySymbol,
    this.summary,
    this.isToday = false,
    this.isHoliday = false,
    this.isPublicHoliday = false,
    this.isCurrentMonth = true,
  });
}

class _TimesheetCell extends StatelessWidget {
  final _TimesheetCellData data;

  const _TimesheetCell({required this.data});

  void _showDetail(BuildContext context) {
    final summary = data.summary;
    if (summary == null) return;
    
    final bool isMissing = summary.daySymbol.trim() == '0' || summary.daySymbol.trim().toLowerCase() == 'x';

    String v(String? x) => (x == null || x.isEmpty) ? '--' : x;
    final worked = summary.rawWorkedHours == null
        ? '--'
        : summary.rawWorkedHours!.toStringAsFixed(2);
    final breakMinutes = summary.breakMinutesDeducted?.toString() ?? '--';
    final notes = _buildUseCaseNotes(summary);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ngày ${summary.date}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ký hiệu: ${summary.daySymbol}'),
            Text(_buildShiftLabel(summary)),
            Text('Vào đầu tiên: ${v(summary.firstIn)}'),
            Text('Ra cuối cùng: ${v(summary.lastOut)}'),
            Text('Giờ làm thực tế: $worked'),
            Text('Giờ yêu cầu: ${summary.requiredHours.toStringAsFixed(2)}'),
            Text('Trừ nghỉ giữa ca (phút): $breakMinutes'),
            Text('Đi trễ (phút): ${summary.lateMinutes}'),
            Text('Về sớm (phút): ${summary.earlyLeaveMinutes}'),
            if (summary.otEligibleMinutes > 0)
              Text('OT đủ điều kiện (phút): ${summary.otEligibleMinutes}'),
            if (summary.otApprovedMinutes > 0)
              Text('OT đã duyệt (phút): ${summary.otApprovedMinutes}'),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Giải thích:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ...notes.map(
                (item) => Text('• $item', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
        actions: [
          if (isMissing)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showChangeForm(context, summary);
              },
              child: const Text('Tạo giải trình', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showChangeForm(BuildContext context, DailySummary summary) {
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return BlocConsumer<AttendanceBloc, AttendanceState>(
              listener: (context, state) {
                if (state.changeSuccessMessage != null && state.changeSuccessMessage!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.changeSuccessMessage!), backgroundColor: Colors.green),
                  );
                  Navigator.of(context).pop(); // Close dialog
                  // Refresh timesheet
                  context.read<AttendanceBloc>().add(const AttendanceRefreshed());
                } else if (!state.isSubmittingChange && state.error != null && state.error!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                return AlertDialog(
                  title: Text('Giải trình công: ${summary.date}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Giờ bổ sung'),
                        trailing: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: selectedTime);
                          if (time != null) setStateSB(() => selectedTime = time);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Lý do (VD: Quên quẹt thẻ)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: state.isSubmittingChange ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: state.isSubmittingChange ? null : () {
                        context.read<AttendanceBloc>().add(AttendanceChangeSubmitted(
                          date: summary.date,
                          time: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00',
                          reason: reasonController.text,
                        ));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C389)),
                      child: state.isSubmittingChange 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Gửi duyệt', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _buildShiftLabel(DailySummary s) {
    final title = (s.shiftTitle ?? '').trim();
    final code = (s.shiftCode ?? '').trim();
    final from = _formatClock(s.shiftFromTime);
    final to = _formatClock(s.shiftToTime);
    final hasRange = from.isNotEmpty && to.isNotEmpty;

    final name = title.isNotEmpty
        ? title
        : (code.isNotEmpty ? code : 'Chưa có thông tin');
    if (!hasRange) return name;
    return '$name ($from - $to)';
  }

  String _formatClock(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final text = raw.trim();
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match != null) {
      final h = match.group(1)!.padLeft(2, '0');
      final m = match.group(2)!.padLeft(2, '0');
      return '$h:$m';
    }
    return '';
  }

  List<String> _buildUseCaseNotes(DailySummary s) {
    final notes = <String>[];
    final symbol = s.daySymbol.trim().toUpperCase();
    final missingType = (s.missingType ?? '').trim().toUpperCase();
    final finalize = (s.finalizeStatus ?? '').trim();

    if (s.lateMinutes > 0 || s.earlyLeaveMinutes > 0) {
      notes.add(
        'Có phát sinh đi trễ/về sớm, hệ thống sẽ áp dụng quy tắc trừ công theo cấu hình HR.',
      );
    }
    if (s.breakMinutesDeducted != null && s.breakMinutesDeducted! > 0) {
      notes.add('Đã tự động trừ thời gian nghỉ giữa ca.');
    }
    if (symbol == 'X') {
      notes.add(
        'Thiếu log Check-in/Check-out. Cần đơn giải trình để tính lại công.',
      );
    }
    if (missingType == 'IN') {
      notes.add('Thiếu log Check-in.');
    } else if (missingType == 'OUT') {
      notes.add('Thiếu log Check-out.');
    }
    if (symbol == 'X/P') {
      notes.add('Kết hợp nửa ngày công thực tế và nửa ngày nghỉ phép.');
    }
    if (symbol == 'P' || symbol == '1L') {
      final leaveType = (s.leaveType ?? '').trim();
      if (leaveType.isNotEmpty) {
        notes.add('Ngày nghỉ phép đã được duyệt ($leaveType).');
      } else {
        notes.add('Ngày nghỉ phép đã được duyệt.');
      }
    }
    if (symbol == 'C') {
      notes.add('Ngày công tác đã được duyệt.');
    }
    if (s.isCrossDay == true) {
      notes.add('Ca qua ngày đã được gom thành một ngày công.');
    }
    if (s.otEligibleMinutes > 0 && s.otApprovedMinutes <= 0) {
      notes.add(
        'Có thời gian ngoài giờ nhưng chưa có đơn OT duyệt nên chưa tính OT.',
      );
    }
    if (s.otApprovedMinutes > 0) {
      notes.add('Đã có OT được duyệt và được cộng theo chính sách.');
    }
    if (finalize.isNotEmpty) {
      notes.add('Trạng thái chốt công: $finalize.');
    }

    return notes;
  }

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

    String statusText = data.displaySymbol ?? '';
    Color statusColor = Colors.transparent;

    switch (data.status) {
      case _DayStatus.normal:
        if (statusText.isEmpty) statusText = '1';
        statusColor = const Color(0xFF2CAD61); // Green
        break;
      case _DayStatus.missing:
        if (statusText.isEmpty || statusText == 'x') {
          statusText = '0';
        } else if (statusText == 'x/P') {
          // keep 'x/P' as is
        }
        statusColor = const Color(0xFFECAE41); // Yellow/Orange
        break;
      case _DayStatus.leave:
        if (statusText.isEmpty) statusText = 'P';
        statusColor = statusText == 'C'
            ? const Color(0xFF4F8DFD) // Cong tac
            : const Color(0xFFD63F3A); // Leave
        break;
      case _DayStatus.emptyZero:
        if (statusText.isEmpty) statusText = '0';
        statusColor = Colors.black;
        break;
      case _DayStatus.none:
        break;
    }

    Widget cell = InkWell(
      onTap: data.summary == null ? null : () => _showDetail(context),
      child: Container(
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
      ),
    );

    if (!data.isCurrentMonth) {
      return Opacity(opacity: 0.35, child: cell);
    }

    return cell;
  }
}
