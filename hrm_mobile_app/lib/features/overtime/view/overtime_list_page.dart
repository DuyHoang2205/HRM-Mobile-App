import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import '../helpers/overtime_status_helper.dart';
import '../models/employee_item.dart';
import '../models/overtime_request.dart';
import '../models/shift_item.dart';
import 'overtime_registration_page.dart';

class OvertimeListPage extends StatelessWidget {
  const OvertimeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OvertimeBloc()..add(const OvertimeStarted()),
      child: const _OvertimeListView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab definitions
// ─────────────────────────────────────────────────────────────────────────────

const _hrTabs = [
  'Tất cả',
  'Đã tạo',
  'Trong ca',
  'Nghỉ phép',
  'Hoàn thành',
  'Vắng mặt',
];

const _employeeTabs = [
  'Tất cả',
  'Sắp tới',
  'Trong ca',
  'Nghỉ phép',
  'Hoàn thành',
  'Vắng mặt',
];

List<OvertimeDisplayStatus?> _tabFilters(bool isHR) => [
  null, // Tất cả
  OvertimeDisplayStatus.upcoming,
  OvertimeDisplayStatus.inProgress,
  OvertimeDisplayStatus.onLeave,
  OvertimeDisplayStatus.completed,
  OvertimeDisplayStatus.absent,
];

// ─────────────────────────────────────────────────────────────────────────────

class _OvertimeListView extends StatelessWidget {
  const _OvertimeListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OvertimeBloc, OvertimeState>(
      buildWhen: (p, c) => p.isHR != c.isHR || p.isLoading != c.isLoading,
      builder: (context, state) {
        final tabs = state.isHR ? _hrTabs : _employeeTabs;
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: AppBar(
              title: const Text(
                'Làm ngoài giờ',
                style: TextStyle(
                  color: Color(0xFF0B1B2B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0B1B2B),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (state.isHR)
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF0B1B2B),
                      size: 30,
                    ),
                    tooltip: 'Tạo phiếu tăng ca',
                    onPressed: () async {
                      final bloc = context.read<OvertimeBloc>();
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: bloc,
                            child: const OvertimeRegistrationPage(),
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        bloc.add(const OvertimeRefreshed());
                      }
                    },
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: const Color(0xFF00C389),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF00C389),
                      unselectedLabelColor: const Color(0xFF9AA6B2),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      tabs: tabs.map((t) => Tab(text: t)).toList(),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x11000000),
                    ),
                  ],
                ),
              ),
            ),
            body: BlocBuilder<OvertimeBloc, OvertimeState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(state.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<OvertimeBloc>().add(
                            const OvertimeRefreshed(),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final tabFilters = _tabFilters(state.isHR);
                return TabBarView(
                  children: List.generate(tabs.length, (i) {
                    return _buildList(context, state, tabFilters[i]);
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    OvertimeState state,
    OvertimeDisplayStatus? filterStatus,
  ) {
    // Tính display status cho từng record
    final filtered = state.requests.where((req) {
      if (filterStatus == null) return true;
      final status = computeOvertimeStatus(
        overtime: req,
        attendance: state.attendance,
        leaves: state.leaves,
      );
      return status == filterStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timelapse, size: 56, color: Color(0xFFD0D8E4)),
            const SizedBox(height: 12),
            const Text(
              'Không có dữ liệu',
              style: TextStyle(color: Color(0xFF9AA6B2)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () =>
                  context.read<OvertimeBloc>().add(const OvertimeRefreshed()),
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<OvertimeBloc>().add(const OvertimeRefreshed());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final req = filtered[index];
          final displayStatus = computeOvertimeStatus(
            overtime: req,
            attendance: state.attendance,
            leaves: state.leaves,
          );
          return _OvertimeCard(
            request: req,
            shifts: state.shifts,
            employees: state.employees,
            isHR: state.isHR,
            displayStatus: displayStatus,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────

class _OvertimeCard extends StatelessWidget {
  final OvertimeRequest request;
  final List<ShiftItem> shifts;
  final List<EmployeeItem> employees;
  final bool isHR;
  final OvertimeDisplayStatus displayStatus;

  const _OvertimeCard({
    required this.request,
    required this.shifts,
    required this.employees,
    required this.isHR,
    required this.displayStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = displayStatus.color;
    final statusLabel = displayStatus.shortLabel;

    final shiftName = shifts
        .where((s) => s.id == request.shiftID)
        .map((s) => s.title)
        .firstOrNull;

    final employeeName = isHR
        ? employees
                  .where((e) => e.id == request.requestBy)
                  .map((e) => e.fullName)
                  .firstOrNull ??
              'NV #${request.requestBy}'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shiftName ?? 'Ca #${request.shiftID}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0B1B2B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(displayStatus.icon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (employeeName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: Color(0xFF9AA6B2),
                ),
                const SizedBox(width: 4),
                Text(
                  employeeName,
                  style: const TextStyle(
                    color: Color(0xFF5D6B78),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 15, color: Color(0xFF9AA6B2)),
              const SizedBox(width: 4),
              Text(
                '${_fmt(request.fromDate)} → ${_fmt(request.toDate)}',
                style: const TextStyle(color: Color(0xFF5D6B78), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 15,
                color: Color(0xFF9AA6B2),
              ),
              const SizedBox(width: 4),
              Text(
                '${request.qty % 1 == 0 ? request.qty.toInt() : request.qty} giờ',
                style: const TextStyle(color: Color(0xFF5D6B78), fontSize: 13),
              ),
            ],
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 15, color: Color(0xFF9AA6B2)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.note,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}';
  }
}
