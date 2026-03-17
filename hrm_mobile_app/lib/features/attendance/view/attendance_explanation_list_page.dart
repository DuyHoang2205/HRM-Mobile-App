import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../models/daily_summary.dart';
import 'attendance_explanation_page.dart';

class AttendanceExplanationListPage extends StatefulWidget {
  const AttendanceExplanationListPage({super.key});

  @override
  State<AttendanceExplanationListPage> createState() =>
      _AttendanceExplanationListPageState();
}

class _AttendanceExplanationListPageState
    extends State<AttendanceExplanationListPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<AttendanceBloc>().add(
      AttendanceTimesheetDateChanged(start: _startDate, end: _endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Danh sách giải trình',
          style: TextStyle(
            color: Color(0xFF0B1B2B),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0B1B2B)),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final items = _buildNeedExplainItems(state.dailySummaries);

          if (state.isLoading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF00C389),
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Hiện không có ngày nào cần giải trình.',
                      style: TextStyle(color: Color(0xFF6B778C), fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final summary = items[index];
                return _NeedExplainCard(
                  summary: summary,
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AttendanceBloc>(),
                          child: AttendanceExplanationPage(
                            initialDate: _tryParseDate(summary.date),
                            initialShift: summary.shiftTitle,
                            initialShiftId: summary.shiftID,
                          ),
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      _loadData();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<DailySummary> _buildNeedExplainItems(Map<String, DailySummary> map) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final items = map.values.where((s) {
      final date = _tryParseDate(s.date);
      if (date == null) return false;
      if (date.isAfter(todayDate)) return false;
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        return false;
      }

      final symbol = s.daySymbol.trim().toLowerCase();
      if (!_hasAssignedShift(s)) return false;

      // Hiện các ngày cần giải trình:
      // - x: thiếu check-in/check-out
      // - 0: vắng mặt 
      // - lateMinutes > 0: đi trễ
      // - earlyLeaveMinutes > 0: về sớm
      return symbol == '0' || 
             symbol == 'x' || 
             s.lateMinutes > 0 || 
             s.earlyLeaveMinutes > 0;
    }).toList();

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  DateTime? _tryParseDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  bool _hasAssignedShift(DailySummary summary) {
    final title = (summary.shiftTitle ?? '').trim();
    final code = (summary.shiftCode ?? '').trim();
    final from = (summary.shiftFromTime ?? '').trim();
    final to = (summary.shiftToTime ?? '').trim();
    return title.isNotEmpty ||
        code.isNotEmpty ||
        (from.isNotEmpty && to.isNotEmpty);
  }
}

class _NeedExplainCard extends StatelessWidget {
  final DailySummary summary;
  final VoidCallback onTap;

  const _NeedExplainCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (summary.shiftTitle ?? '').trim();
    final code = (summary.shiftCode ?? '').trim();
    final from = (summary.shiftFromTime ?? '').trim();
    final to = (summary.shiftToTime ?? '').trim();
    final shift = title.isNotEmpty
        ? title
        : (code.isNotEmpty
              ? code
              : '${from.isEmpty ? '--:--' : from} - ${to.isEmpty ? '--:--' : to}');
    final symbol = summary.daySymbol.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ngày ${summary.date}',
                      style: const TextStyle(
                        color: Color(0xFF0B1B2B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECCB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      symbol.isEmpty ? '0' : symbol,
                      style: const TextStyle(
                        color: Color(0xFFE09A2A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                shift,
                style: const TextStyle(
                  color: Color(0xFF6B778C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              _buildReasonBadges(summary),
              const SizedBox(height: 8),
              Text(
                'Vào: ${summary.firstIn ?? '--'}  •  Ra: ${summary.lastOut ?? '--'}',
                style: const TextStyle(color: Color(0xFF6B778C)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C389),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tạo giải trình'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonBadges(DailySummary summary) {
    final reasons = <String>[];
    final symbol = summary.daySymbol.trim().toUpperCase();
    if (symbol == '0') reasons.add('Vắng mặt');
    if (symbol == 'X') reasons.add('Thiếu log');
    if (summary.lateMinutes > 0) reasons.add('Đi trễ ${summary.lateMinutes}p');
    if (summary.earlyLeaveMinutes > 0) {
      reasons.add('Về sớm ${summary.earlyLeaveMinutes}p');
    }

    if (reasons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: reasons.map((r) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            r,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
