import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../attendance/view/attendance_page.dart'; // Reuse logic/styles if possible? No, independent.
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
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

class _OvertimeListView extends StatelessWidget {
  const _OvertimeListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Làm ngoài giờ',
          style: TextStyle(color: Color(0xFF0B1B2B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1B2B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0B1B2B), size: 30),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OvertimeRegistrationPage()),
              );
              if (result == true) {
                 if (context.mounted) context.read<OvertimeBloc>().add(const OvertimeRefreshed());
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<OvertimeBloc, OvertimeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có yêu cầu làm ngoài giờ', style: TextStyle(color: Color(0xFF9AA6B2))),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.read<OvertimeBloc>().add(const OvertimeRefreshed()), // Retry
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
              itemCount: state.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = state.requests[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.reason,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.status == 'PENDING' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status,
                              style: TextStyle(
                                color: req.status == 'PENDING' ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Ngày: ${_fmtDate(req.date)}'),
                      Text('Thời gian: ${req.startTime} - ${req.endTime}'),
                      if (req.isNextDay)
                        const Text('Làm thêm sang ngày hôm sau', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}
