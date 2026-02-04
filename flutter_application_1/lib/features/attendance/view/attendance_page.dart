import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../checkin/view/checkin_page.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // In your screenshot, "Bảng công" is selected.
    _tab.index = 1;
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const _AttendanceTitle(),
        actions: [
          IconButton(
            onPressed: () {
              // placeholder filter
            },
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0B1B2B)),
          ),
          IconButton(
            onPressed: () async {
              // ✅ "+" directs to Vào ca (CheckInPage in check-in mode)
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CheckInPage(
                    isCheckoutMode: false,
                    checkedInAt: null,
                  ),
                ),
              );
              if (mounted) context.read<AttendanceBloc>().add(const AttendanceRefreshed());
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chấm công',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0B1B2B),
          ),
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Text(
              '01.01 - 31.01',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AA6B2),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9AA6B2)),
          ],
        ),
      ],
    );
  }
}

class _TabLogs extends StatelessWidget {
  const _TabLogs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.error != null && state.logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF9AA6B2), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<AttendanceBloc>().add(const AttendanceRefreshed()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.logs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AttendanceBloc>().add(const AttendanceRefreshed());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: Text(
                    'Chưa có dữ liệu chấm công',
                    style: TextStyle(color: Color(0xFF9AA6B2), fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AttendanceBloc>().add(const AttendanceRefreshed());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            children: [
              const Text(
                'Hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9AA6B2),
                ),
              ),
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
    final iconBg = isIn ? const Color(0xFFE53935) : const Color(0xFF4F8DFD);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1B2B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9AA6B2),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmtHHmm(log.timestamp),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0B1B2B),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBangCong extends StatelessWidget {
  const _TabBangCong();

  @override
  Widget build(BuildContext context) {
    // static mock data for now
    final rows = const [
      _BangCongRow(label: 'Ngày công thực tế', value: '0 công', chevron: true),
      _BangCongRow(label: 'Giờ công thực tế', value: '0 giờ', chevron: true),
      _BangCongRow(label: 'Số giờ làm dư giờ', value: '0 giờ 0 phút'),
      _BangCongRow(label: 'Số giờ làm thêm', value: '0 giờ 0 phút'),
      _BangCongRow(label: 'Số phút đi làm sớm', value: '0 phút'),
      _BangCongRow(label: 'Giờ công tiêu chuẩn', value: '196 giờ'),
      _BangCongRow(label: 'Số ngày nghỉ tiêu chuẩn', value: '0 ngày'),
      _BangCongRow(label: 'Số ngày nghỉ không lương (chính thức)', value: '0 ngày'),
      _BangCongRow(label: 'Công chuẩn', value: '24.5 ngày'),
      _BangCongRow(label: 'Số ngày công nghỉ lễ', value: '0 ngày'),
      _BangCongRow(label: 'Tổng công tính lương', value: '0 ngày'),
      _BangCongRow(label: 'Số giờ về sớm', value: '0 giờ 0 phút', chevron: true),
      _BangCongRow(label: 'Số giờ đi muộn', value: '0 giờ 0 phút', chevron: true),
      _BangCongRow(label: 'Số giờ đi muộn, về sớm', value: '0 giờ 0 phút'),
      _BangCongRow(label: 'Số lần quên checkin', value: '0', chevron: true, valueColor: Color(0xFFFF8A00)),
      _BangCongRow(label: 'Số lần quên checkout', value: '0', chevron: true, valueColor: Color(0xFFFF8A00)),
      _BangCongRow(label: 'Số lần quên checkin và checkout', value: '10', chevron: true, valueColor: Color(0xFFFF3B30)),
    ];

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        for (final r in rows) _BangCongTile(row: r),
      ],
    );
  }
}

class _BangCongRow {
  final String label;
  final String value;
  final bool chevron;
  final Color? valueColor;

  const _BangCongRow({
    required this.label,
    required this.value,
    this.chevron = false,
    this.valueColor,
  });
}

class _BangCongTile extends StatelessWidget {
  final _BangCongRow row;
  const _BangCongTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            title: Text(
              row.label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D6B78),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: row.valueColor ?? const Color(0xFF0B1B2B),
                  ),
                ),
                if (row.chevron) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFB7C0C9)),
                ],
              ],
            ),
            onTap: row.chevron ? () {} : null,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
        ],
      ),
    );
  }
}

String _fmtHHmm(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
