import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';
import 'leave_registration_page.dart';

class LeaveListPage extends StatelessWidget {
  const LeaveListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveBloc()..add(const LeaveStarted()),
      child: const _LeaveListView(),
    );
  }
}

class _LeaveListView extends StatelessWidget {
  const _LeaveListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Nghỉ phép',
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
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0B1B2B), size: 30),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaveRegistrationPage(),
                ),
              );
              if (result == true) {
                if (context.mounted) {
                  context.read<LeaveBloc>().add(const LeaveRefreshed());
                }
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<LeaveBloc, LeaveState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có yêu cầu nghỉ phép',
                    style: TextStyle(color: Color(0xFF9AA6B2)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<LeaveBloc>().add(const LeaveRefreshed()),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<LeaveBloc>().add(const LeaveRefreshed());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = state.requests[index];

                final statusLabel = switch (req.status) {
                  0 => 'CHỜ DUYỆT',
                  1 => 'CHỜ DUYỆT',
                  2 => 'ĐÃ DUYỆT',
                  3 => 'ĐÃ DUYỆT',
                  4 => 'TỪ CHỐI',
                  _ => 'KHÔNG RÕ',
                };
                final statusColor = switch (req.status) {
                  0 => Colors.orange,
                  1 => Colors.orange,
                  2 => Colors.green,
                  3 => Colors.green,
                  4 => Colors.red,
                  _ => Colors.grey,
                };

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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tự động map ID sang Tên Loại Phép tại máy khách
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final permName = state.permissionTypes
                                    .where((p) => p.id == req.permissionType)
                                    .map((p) => p.permissionType)
                                    .firstOrNull;
                                return Text(
                                  permName ??
                                      'Loại phép #${req.permissionType}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày: ${_fmtDate(req.fromDate)} - ${_fmtDate(req.toDate)}',
                      ),
                      Text('Số ngày: ${_fmtQty(req.qty)}'),
                      if (req.description.isNotEmpty)
                        Text(
                          'Diễn giải: ${req.description}',
                          style: const TextStyle(color: Colors.grey),
                        ),
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

  /// Hiển thị số ngày: nếu là số nguyên thì bỏ .0 (ví dụ: 2.0 → "2", 2.5 → "2.5")
  String _fmtQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toString();
  }
}
