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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(58),
            child: Column(
              children: [
                TabBar(
                  indicatorColor: Color(0xFF00C389),
                  indicatorWeight: 3,
                  labelColor: Color(0xFF00C389),
                  unselectedLabelColor: Color(0xFF9AA6B2),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Chờ duyệt'),
                    Tab(text: 'Lịch sử'),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: Color(0x11000000)),
              ],
            ),
          ),
        ),
        body: BlocBuilder<LeaveBloc, LeaveState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildList(context, state, 0), // Tất cả
                _buildList(context, state, 1), // Chờ duyệt
                _buildList(context, state, 2), // Lịch sử
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, LeaveState state, int tabIndex) {
    // tabIndex: 0 = Tất cả, 1 = Chờ duyệt, 2 = Lịch sử (Đã duyệt/Từ chối)
    final filteredRequests = state.requests.where((req) {
      if (tabIndex == 1) {
        return req.status == 0 || req.status == 1; // 0, 1 thường là chờ duyệt
      }
      if (tabIndex == 2) {
        return req.status == 2 ||
            req.status == 3 ||
            req.status == 4; // 2, 3 là đã duyệt, 4 là từ chối
      }
      return true; // tab 0 => show All
    }).toList();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tabIndex == 0 ? 'Chưa có yêu cầu nghỉ phép' : 'Không có dữ liệu',
              style: const TextStyle(color: Color(0xFF9AA6B2)),
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
        itemCount: filteredRequests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final req = filteredRequests[index];

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
                            permName ?? 'Loại phép #${req.permissionType}',
                            style: const TextStyle(
                              color: Colors.black,
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
                  Text('Diễn giải: ${req.description}'),
              ],
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
