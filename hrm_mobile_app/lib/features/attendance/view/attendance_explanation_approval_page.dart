import 'package:flutter/material.dart';

import '../../../core/auth/auth_helper.dart';
import '../data/attendance_change_repository.dart';

class AttendanceExplanationApprovalPage extends StatefulWidget {
  const AttendanceExplanationApprovalPage({super.key});

  @override
  State<AttendanceExplanationApprovalPage> createState() =>
      _AttendanceExplanationApprovalPageState();
}

class _AttendanceExplanationApprovalPageState
    extends State<AttendanceExplanationApprovalPage> {
  final AttendanceChangeRepository _repository = AttendanceChangeRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = const <Map<String, dynamic>>[];
  String _selectedDepartment = 'Tất cả phòng ban';

  late DateTime _periodDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodDate = DateTime(now.year, now.month, 1);
    _loadRows();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final period = _periodDate.month;
      final year = _periodDate.year;
      final fromDate = '$year-${period.toString().padLeft(2, '0')}-01';
      final toDate =
          '$year-${period.toString().padLeft(2, '0')}-${DateTime(year, period + 1, 0).day.toString().padLeft(2, '0')}';

      final siteID = await AuthHelper.getSiteId();

      final rows = await _repository.getTimekeepingOffsets(
        period: period,
        siteID: siteID,
        fromDate: fromDate,
        toDate: toDate,
      );

      final depSet = rows.map(_departmentOf).toSet();
      final safeDepartment =
          _selectedDepartment == 'Tất cả phòng ban' ||
              depSet.contains(_selectedDepartment)
          ? _selectedDepartment
          : 'Tất cả phòng ban';

      setState(() {
        _rows = rows;
        _selectedDepartment = safeDepartment;
      });
    } catch (e) {
      setState(() {
        _error = 'Không tải được danh sách phiếu bù công: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodDate,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Chọn tháng/kỳ',
    );
    if (picked == null) return;
    setState(() {
      _periodDate = DateTime(picked.year, picked.month, 1);
    });
    await _loadRows();
  }

  int _intVal(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final raw = row[key];
      if (raw is num) return raw.toInt();
      final value = int.tryParse(raw?.toString() ?? '');
      if (value != null) return value;
    }
    return 0;
  }

  String _strVal(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '--',
  }) {
    for (final key in keys) {
      final raw = row[key]?.toString().trim();
      if (raw != null && raw.isNotEmpty) return raw;
    }
    return fallback;
  }

  bool _isPending(Map<String, dynamic> row) {
    final status = _intVal(row, const <String>['status', 'Status']);
    return status == 0 || status == 1;
  }

  String _periodLabel() {
    final month = _periodDate.month.toString().padLeft(2, '0');
    return 'Kỳ $month/${_periodDate.year}';
  }

  String _departmentOf(Map<String, dynamic> row) {
    return _strVal(row, const <String>[
      'organizationName',
      'OrganizationName',
      'departmentName',
      'DepartmentName',
    ], fallback: 'Chưa rõ phòng ban');
  }

  List<String> _departmentOptions() {
    final values = _rows.map(_departmentOf).toSet().toList()..sort();
    return <String>['Tất cả phòng ban', ...values];
  }

  bool _matchesSearch(Map<String, dynamic> row, String keyword) {
    if (keyword.isEmpty) return true;
    final employeeName = _strVal(row, const <String>[
      'fullName',
      'FullName',
      'employeeName',
      'EmployeeName',
    ]).toLowerCase();
    final employeeCode = _strVal(row, const <String>[
      'code',
      'Code',
      'staffCode',
      'StaffCode',
    ], fallback: '').toLowerCase();
    return employeeName.contains(keyword) || employeeCode.contains(keyword);
  }

  List<Map<String, dynamic>> _filteredRows() {
    final keyword = _searchController.text.trim().toLowerCase();
    return _rows.where((row) {
      final dep = _departmentOf(row);
      final passDep =
          _selectedDepartment == 'Tất cả phòng ban' ||
          dep == _selectedDepartment;
      return passDep && _matchesSearch(row, keyword);
    }).toList();
  }

  Future<void> _accept(Map<String, dynamic> row) async {
    final employeeID = _intVal(row, const <String>['employeeID', 'EmployeeID']);
    final shiftID = _intVal(row, const <String>['shiftID', 'ShiftID']);
    final dateRaw = _strVal(row, const <String>['dateApply', 'DateApply']);

    if (employeeID <= 0 || shiftID <= 0 || dateRaw == '--') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thiếu dữ liệu employeeID/shift/date để duyệt bù công.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _repository.acceptTimekeepingOffset(
        employeeID: employeeID,
        date: dateRaw,
        shiftID: shiftID,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Đã duyệt bù công.' : 'Duyệt thất bại.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      await _loadRows();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi duyệt bù công: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Duyệt phiếu bù công',
          style: TextStyle(
            color: Color(0xFF0B1B2B),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0B1B2B)),
        actions: [
          IconButton(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Đổi kỳ',
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadRows, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      );
    }

    final title = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            _periodLabel(),
            style: const TextStyle(
              color: Color(0xFF0B1B2B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '(period = tháng, năm lấy theo ngày lọc)',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );

    final departments = _departmentOptions();
    final rows = _filteredRows();

    final filterBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã nhân viên',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDepartment,
            isExpanded: true,
            items: departments
                .map(
                  (dep) => DropdownMenuItem<String>(
                    value: dep,
                    child: Text(dep, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedDepartment = value);
            },
            decoration: InputDecoration(
              labelText: 'Phòng ban',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );

    if (_rows.isEmpty) {
      return ListView(
        children: [
          title,
          filterBar,
          const SizedBox(height: 120),
          const Icon(
            Icons.assignment_turned_in,
            size: 56,
            color: Color(0xFF00C389),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Không có phiếu bù công trong kỳ này.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    if (rows.isEmpty) {
      return ListView(
        children: [
          title,
          filterBar,
          const SizedBox(height: 120),
          const Icon(Icons.filter_alt_off, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Không có dữ liệu phù hợp bộ lọc.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: rows.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) return title;
        if (index == 1) return filterBar;

        final row = rows[index - 2];
        final pending = _isPending(row);
        final employeeName = _strVal(row, const <String>[
          'fullName',
          'FullName',
          'employeeName',
          'EmployeeName',
        ]);
        final employeeCode = _strVal(row, const <String>[
          'code',
          'Code',
          'staffCode',
          'StaffCode',
        ], fallback: '');
        final date = _strVal(row, const <String>['dateApply', 'DateApply']);
        final reason = _strVal(row, const <String>[
          'reason',
          'Reason',
        ], fallback: '');
        final note = _strVal(row, const <String>['note', 'Note'], fallback: '');
        final fromTime = _strVal(row, const <String>[
          'fromTime',
          'FromTime',
        ], fallback: '--:--');
        final toTime = _strVal(row, const <String>[
          'toTime',
          'ToTime',
        ], fallback: '--:--');
        final shiftID = _intVal(row, const <String>['shiftID', 'ShiftID']);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employeeCode.isEmpty
                    ? employeeName
                    : '$employeeName ($employeeCode)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1B2B),
                ),
              ),
              const SizedBox(height: 6),
              Text('Ngày: $date | Ca: $shiftID'),
              Text('Giờ điều chỉnh: $fromTime -> $toTime'),
              if (reason.isNotEmpty) Text('Lý do: $reason'),
              if (note.isNotEmpty) Text('Ghi chú: $note'),
              const SizedBox(height: 10),
              if (pending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _accept(row),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C389),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Duyệt bù công'),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _intVal(row, const <String>['status', 'Status']) == 3
                        ? 'Đã duyệt'
                        : 'Đã xử lý',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
