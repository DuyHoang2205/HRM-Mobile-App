import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key});

  String _dowViShort(int weekday) {
    // DateTime.weekday: Mon=1..Sun=7
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFF0B1B2B),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: const [
              Text('Lịch làm việc', style: titleStyle,),
            ],
          ),
          const SizedBox(height: 14),

          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (p, c) =>
                p.today.year != c.today.year ||
                p.today.month != c.today.month ||
                p.today.day != c.today.day ||
                p.attendanceLogs != c.attendanceLogs,
            builder: (context, state) {
              final today = DateTime(
                state.today.year,
                state.today.month,
                state.today.day,
              );

              final start = today.subtract(const Duration(days: 3));

              // Create a set of dates that have attendance for quick lookup
              final datesWithAttendance = <String>{};
              for (final log in state.attendanceLogs) {
                final dateKey = '${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}';
                datesWithAttendance.add(dateKey);
              }

              print('DEBUG Schedule: ${state.attendanceLogs.length} logs, ${datesWithAttendance.length} unique dates');
              print('DEBUG Schedule: Dates with attendance: $datesWithAttendance');

              return LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  const chipH = 74.0;

                  // compute chip width so all 7 fit perfectly
                  final totalGap = gap * 6;
                  final chipW = (constraints.maxWidth - totalGap) / 7;

                  return SizedBox(
                    height: chipH,
                    child: Row(
                      children: List.generate(7, (i) {
                        final date = start.add(Duration(days: i));
                        final dow = _dowViShort(date.weekday);
                        final day = date.day.toString();

                        final isToday = i == 3;
                        
                        // Check if this date has attendance
                        final dateKey = '${date.year}-${date.month}-${date.day}';
                        final hasAttendance = datesWithAttendance.contains(dateKey);
                        
                        print('DEBUG Chip $i: $dateKey, hasAttendance: $hasAttendance');

                        return Padding(
                          padding: EdgeInsets.only(right: i == 6 ? 0 : gap),
                          child: _StaticDateChip(
                            width: chipW,
                            height: chipH,
                            dow: dow,
                            day: day,
                            highlight: isToday,
                            hasAttendance: hasAttendance,
                          ),
                        );
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StaticDateChip extends StatelessWidget {
  final double width;
  final double height;
  final String dow;
  final String day;
  final bool highlight;
  final bool hasAttendance;

  const _StaticDateChip({
    required this.width,
    required this.height,
    required this.dow,
    required this.day,
    required this.highlight,
    this.hasAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? const Color(0xFF5B84A8) : Colors.white;
    final dowColor = highlight
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF9AA6B2);
    final dayColor = highlight ? Colors.white : const Color(0xFF0B1B2B);
    final dotColor = highlight ? Colors.white : const Color(0xFFD7DFE8);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: highlight
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dow,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dowColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: dayColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          // Only show dot if there's attendance data for this day
          if (hasAttendance)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
