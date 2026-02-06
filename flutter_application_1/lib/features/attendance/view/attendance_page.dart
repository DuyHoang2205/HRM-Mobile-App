import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    _tab.index = 0; 
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
          onPressed: () {
            // CRITICAL FIX: Pass the result back to HomePage
            Navigator.of(context).pop(_lastResult);
          },
        ),
        titleSpacing: 0,
        title: const _AttendanceTitle(),
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0B1B2B)),
          ),
          IconButton(
            onPressed: () async {
              final currentState = context.read<AttendanceBloc>().state;
              final bool isCheckedIn = currentState.logs.isNotEmpty && 
                                       currentState.logs.first.action == AttendanceAction.checkIn;

              final lastCheckInTime = isCheckedIn ? currentState.logs.first.timestamp : null;

              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckInPage(
                    isCheckoutMode: isCheckedIn, 
                    checkedInAt: lastCheckInTime,
                  ),
                ),
              );
              
              if (mounted && result is CheckInResult) {
                 _lastResult = result; 
                 context.read<AttendanceBloc>().add(AttendanceCheckResultArrived(
                   isCheckIn: result.action == CheckAction.checkIn,
                   timestamp: result.timestamp,
                 ));
              } else if (mounted) {
                 context.read<AttendanceBloc>().add(const AttendanceRefreshed());
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
                tabs: const [
                  Tab(text: 'Vào/Ra'),
                  Tab(text: 'Bảng công'),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: const [
              _TabLogs(),
              _TabBangCong(),
            ],
          ),
          BlocBuilder<AttendanceBloc, AttendanceState>(
            buildWhen: (p, c) => p.isLoading != c.isLoading,
            builder: (context, state) {
              if (!state.isLoading) return const SizedBox.shrink();
              return Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
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
          buildWhen: (p, c) => p.filterDate != c.filterDate,
          builder: (context, state) {
            final date = state.filterDate;
            final firstDay = DateTime(date.year, date.month, 1);
            final lastDay = DateTime(date.year, date.month + 1, 0);
            final text = '${_fmtDayMonth(firstDay)} - ${_fmtDayMonth(lastDay)}';

            return GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.filterDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  locale: const Locale('vi', 'VN'),
                );
                if (picked != null) {
                  context.read<AttendanceBloc>().add(AttendanceFilterChanged(picked));
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

  String _fmtDayMonth(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}';
  }
}

class _TabLogs extends StatelessWidget {
  const _TabLogs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.logs.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu chấm công'));
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<AttendanceBloc>().add(const AttendanceRefreshed()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            children: [
              const Text('Hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF9AA6B2))),
              const SizedBox(height: 10),
              for (final log in state.logs) ...[
                _LogItem(log: log),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LogItem extends StatelessWidget {
  final AttendanceLog log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn = log.action == AttendanceAction.checkIn;
    final iconBg = isIn ? const Color(0xFF4F8DFD) : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0B1B2B))),
                const SizedBox(height: 4),
                Text(log.subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9AA6B2))),
              ],
            ),
          ),
          Text(_fmtHHmm(log.timestamp), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0B1B2B))),
        ],
      ),
    );
  }
}

class _TabBangCong extends StatelessWidget {
  const _TabBangCong();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Bảng công'));
}

String _fmtHHmm(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}