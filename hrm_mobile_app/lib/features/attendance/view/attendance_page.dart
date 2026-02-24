import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../checkin/view/checkin_page.dart';
import '../../checkin/models/checkin_result.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../models/attendance_log.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceBloc()..add(const AttendanceStarted()),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatefulWidget {
  const _AttendanceView();

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  CheckInResult? _lastResult; 

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1B2B)),
          onPressed: () => Navigator.of(context).pop(_lastResult),
        ),
        titleSpacing: 0,
        title: const _AttendanceTitle(),
        actions: [
          IconButton(
            onPressed: () async {
              final currentState = context.read<AttendanceBloc>().state;
              final bool isCheckedIn = currentState.isCheckedIn;

              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckInPage(
                    isCheckoutMode: isCheckedIn, 
                    checkedInAt: isCheckedIn ? currentState.logs.first.timestamp : null,
                  ),
                ),
              );
              
              if (mounted && result is CheckInResult) {
                 _lastResult = result; 
                 context.read<AttendanceBloc>().add(AttendanceCheckResultArrived(
                   isCheckIn: result.action == CheckAction.checkIn,
                   timestamp: result.timestamp,
                 ));
              }
            },
            icon: const Icon(Icons.add, color: Color(0xFF0B1B2B)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Column(
            children: [
              TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFF00C389),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00C389),
                unselectedLabelColor: const Color(0xFF9AA6B2),
                labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                tabs: const [Tab(text: 'Vào/Ra'), Tab(text: 'Bảng công')],
              ),
              const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_TabLogs(), _TabBangCong()],
      ),
    );
  }
}

class _AttendanceTitle extends StatelessWidget {
  const _AttendanceTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chấm công',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0B1B2B)),
        ),
        const SizedBox(height: 2),
        BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            final start = state.filterDate;
            final end = state.endDate ?? DateTime.now();
            final text = '${_fmt(start)} - ${_fmt(end)}';

            return GestureDetector(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  initialDateRange: DateTimeRange(start: start, end: end),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  locale: const Locale('vi', 'VN'),
                );
                if (picked != null) {
                  context.read<AttendanceBloc>().add(AttendanceFilterChanged(
                    start: picked.start,
                    end: picked.end,
                  ));
                }
              },
              child: Row(
                children: [
                  Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9AA6B2))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9AA6B2)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

class _TabLogs extends StatefulWidget {
  const _TabLogs();

  @override
  State<_TabLogs> createState() => _TabLogsState();
}

class _TabLogsState extends State<_TabLogs> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.logs.isEmpty) return const Center(child: Text('Chưa có dữ liệu'));

        final Map<String, List<AttendanceLog>> grouped = {};
        for (var log in state.logs) {
          final key = DateFormat('yyyy-MM-dd').format(log.timestamp);
          if (!grouped.containsKey(key)) grouped[key] = [];
          grouped[key]!.add(log);
        }

        final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final logs = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateHeader(dateKey), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF9AA6B2))),
                const SizedBox(height: 10),
                ...logs.map((log) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _LogItem(log: log))),
              ],
            );
          },
        );
      },
    );
  }

  String _dateHeader(String key) {
    final d = DateTime.parse(key);
    // Use Vietnamese locale for date formatting
    // Example: Thứ Tư, 11 Tháng 02
    return DateFormat('EEEE, dd MMMM', 'vi_VN').format(d);
  }
}

class _LogItem extends StatelessWidget {
  final AttendanceLog log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn = log.action == AttendanceAction.checkIn;
    final subtitle = isIn ? 'Vào ca trên điện thoại' : 'Ra ca trên điện thoại';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              // Blue for CheckIn, Red for CheckOut
              color: isIn ? const Color(0xFF4F8DFD) : const Color(0xFFE53935), 
              borderRadius: BorderRadius.circular(14)
            ),
            child: const Icon(Icons.phone_iphone_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF9AA6B2))),
          ])),
          Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TabBangCong extends StatelessWidget {
  const _TabBangCong();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.logs.isEmpty) return const Center(child: Text('Chưa có dữ liệu cho Bảng công'));

        // Grouping logs by date for Bảng công
        final Map<String, List<AttendanceLog>> dailyLogs = {};
        for (var log in state.logs) {
          final key = DateFormat('yyyy-MM-dd').format(log.timestamp);
          dailyLogs.putIfAbsent(key, () => []).add(log);
        }

        final sortedDates = dailyLogs.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateStr = sortedDates[index];
            final logs = dailyLogs[dateStr]!;
            
            final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
            final totalLogs = logs.length;
            
            return _BangCongTile(
              label: formattedDate,
              value: '$totalLogs lần',
              // Visual cue: Red text if there is an odd number of logs (likely missed a checkout)
              valueColor: totalLogs % 2 != 0 ? const Color(0xFFFF3B30) : const Color(0xFF00C389),
            );
          },
        );
      },
    );
  }
}

class _BangCongTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BangCongTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            title: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF5D6B78)),
            ),
            trailing: Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: valueColor ?? const Color(0xFF0B1B2B)),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
        ],
      ),
    );
  }
}