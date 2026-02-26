import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import '../data/overtime_repository.dart';
import 'overtime_registration_page.dart';

class OvertimeListPage extends StatelessWidget {
  const OvertimeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OvertimeBloc(repository: OvertimeRepository())
            ..add(const LoadOvertimeList()),
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
          style: TextStyle(
            color: Color(0xFF0B1B2B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
            icon: const Icon(Icons.add, color: Color(0xFF0B2A5B), size: 28),
            onPressed: () async {
              final bloc = context
                  .read<
                    OvertimeBloc
                  >(); // pass Bloc down if you want, but easier to just refresh on pop
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OvertimeRegistrationPage(),
                ),
              );
              if (result == true) {
                bloc.add(const LoadOvertimeList());
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<OvertimeBloc, OvertimeState>(
        builder: (context, state) {
          if (state.status == OvertimeStatus.loading ||
              state.status == OvertimeStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B2A5B)),
            );
          }
          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có yêu cầu làm ngoài giờ',
                    style: TextStyle(color: Color(0xFF9AA6B2)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.read<OvertimeBloc>().add(
                      const LoadOvertimeList(),
                    ), // Retry
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2A5B),
                    ),
                    child: const Text(
                      'Tải lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<OvertimeBloc>().add(const LoadOvertimeList());
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
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fmtDate(req.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF0B1B2B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: req.status == 'Chờ duyệt'
                                  ? const Color(0xFFFEF3C7)
                                  : (req.status == 'Đã duyệt' ||
                                        req.status == 'APPROVED')
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              req.status,
                              style: TextStyle(
                                color: req.status == 'Chờ duyệt'
                                    ? const Color(0xFFD97706)
                                    : (req.status == 'Đã duyệt' ||
                                          req.status == 'APPROVED')
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Thời gian: ',
                        '${req.startTime} - ${req.endTime}',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow('Lý do: ', req.reason),
                      const SizedBox(height: 6),
                      _buildInfoRow('Diễn giải: ', req.description),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        'Nghỉ giữa giờ: ',
                        '${req.breakMinutes} phút',
                      ),
                      if (req.reeproDispatch != null &&
                          req.reeproDispatch!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Điều động ReePro: ',
                          req.reeproDispatch!,
                        ),
                      ],
                      if (req.reeproProject != null &&
                          req.reeproProject!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Công trình ReePro: ',
                          req.reeproProject!,
                        ),
                      ],
                      const SizedBox(height: 6),
                      _buildInfoRow('Người duyệt: ', req.approverName),
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

  Widget _buildInfoRow(String title, String value) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}
