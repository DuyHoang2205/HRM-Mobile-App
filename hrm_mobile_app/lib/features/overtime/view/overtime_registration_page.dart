import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import '../models/employee_item.dart';
import '../models/overtime_request.dart';

class OvertimeRegistrationPage extends StatefulWidget {
  const OvertimeRegistrationPage({super.key});

  @override
  State<OvertimeRegistrationPage> createState() =>
      _OvertimeRegistrationPageState();
}

class _OvertimeRegistrationPageState extends State<OvertimeRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  DateTime? _fromDate;
  int? _selectedShiftId;
  int? _selectedEmployeeId; // HR: nhân viên được giao ca
  double _qty = 0;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state.submitSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitSuccess!),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: BlocBuilder<OvertimeBloc, OvertimeState>(
            buildWhen: (p, c) => p.isHR != c.isHR,
            builder: (_, state) => Text(
              state.isHR ? 'Tạo phiếu tăng ca' : 'Đăng ký làm thêm',
              style: const TextStyle(
                color: Color(0xFF0B1B2B),
                fontWeight: FontWeight.bold,
              ),
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
        ),
        body: BlocBuilder<OvertimeBloc, OvertimeState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── [HR only] Chọn nhân viên ─────────────────────────
                    if (state.isHR) ..._buildEmployeeDropdown(state),

                    // ── Ca làm việc ──────────────────────────────────────
                    _buildLabel('Ca làm việc', required: true),
                    const SizedBox(height: 8),
                    if (state.isLoading && state.shifts.isEmpty)
                      const LinearProgressIndicator()
                    else
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFE55A00),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF0B1B2B),
                          ),
                        ),
                        child: DropdownButtonFormField<int>(
                          menuMaxHeight: 300,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          decoration: _inputDecoration(),
                          initialValue: _selectedShiftId,
                          isExpanded: true,
                          hint: const Text('Chọn ca làm việc'),
                          items: state.shifts
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(
                                    s.displayLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedShiftId = v;
                              // Tự động điền số giờ dựa trên ca được chọn
                              if (v != null) {
                                final shift = state.shifts
                                    .where((s) => s.id == v)
                                    .firstOrNull;
                                if (shift != null && shift.workTime > 0) {
                                  _qty = shift.workTime;
                                  _qtyCtrl.text = _fmtQty(_qty);
                                }
                              }
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Vui lòng chọn ca làm việc' : null,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Ngày Tăng ca ─────────────────────
                    _buildLabel('Ngày', required: true),
                    const SizedBox(height: 8),
                    _DatePickerField(
                      value: _fromDate,
                      hint: 'Chọn ngày tăng ca',
                      onPick: _pickStartDate,
                    ),

                    const SizedBox(height: 16),

                    // ── Số giờ tăng ca ────────────────────────────────────
                    _buildLabel('Số giờ', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _qtyCtrl,
                      readOnly: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Tự động theo ca đã chọn',
                        suffixText: 'giờ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập số giờ';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Số giờ không hợp lệ';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Lý do / Diễn giải ─────────────────────────────────
                    _buildLabel('Lý do', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        hint: 'Nhập lý do làm ngoài giờ...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập lý do'
                          : null,
                    ),

                    const SizedBox(height: 32),

                    // ── Nút Gửi ───────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B2A5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                state.isHR ? 'Tạo phiếu' : 'Gửi yêu cầu',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF0B1B2B),
          ),
        ),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  /// Employee dropdown — chỉ render khi HR
  List<Widget> _buildEmployeeDropdown(OvertimeState state) {
    return [
      _buildLabel('Nhân viên', required: true),
      const SizedBox(height: 8),
      if (state.employees.isEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Đang tải danh sách nhân viên...',
            style: TextStyle(color: Colors.grey),
          ),
        )
      else
        FormField<int>(
          initialValue: _selectedEmployeeId,
          validator: (v) => v == null ? 'Vui lòng chọn nhân viên' : null,
          builder: (field) {
            final selected = state.employees
                .where((e) => e.id == _selectedEmployeeId)
                .firstOrNull;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showEmployeeSearchSheet(state.employees, field),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: field.hasError
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selected?.displayName ?? 'Chạm để tìm nhân viên...',
                            style: TextStyle(
                              color: selected == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.search, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      const SizedBox(height: 16),
    ];
  }

  void _showEmployeeSearchSheet(
    List<EmployeeItem> employees,
    FormFieldState<int> field,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeSearchSheet(
        employees: employees,
        initialId: _selectedEmployeeId,
        onSelected: (id) {
          setState(() => _selectedEmployeeId = id);
          field.didChange(id);
        },
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE55A00),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0B1B2B),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE55A00),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    setState(() {
      _fromDate = DateTime(date.year, date.month, date.day);
    });
  }

  String _fmtQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toString();
  }

  Future<void> _submit() async {
    final bloc = context.read<OvertimeBloc>();
    final isHR = bloc.state.isHR;

    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ca làm việc và Ngày tăng ca'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final siteId = await AuthHelper.getSiteId();
    final staffCode = await AuthHelper.getStaffCode() ?? '';

    // HR giao cho nhân viên được chọn; nhân viên tự gửi cho mình
    final requestBy = isHR
        ? (_selectedEmployeeId ?? 0)
        : (await AuthHelper.getEmployeeId() ?? 0);

    if (isHR && requestBy == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn nhân viên'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final request = OvertimeRequest(
      // HR tạo → status=2 (Xác nhận ngay, không cần duyệt)
      // NV tự xin → status=0 (Chờ HR duyệt) — tương lai
      status: isHR ? 2 : 0,

      // Đặt FromDate và ToDate thành trọn vẹn 00:00 của ngày được chọn để đồng bộ với Database Zensuite
      fromDate: DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
      toDate: DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
      requestBy: requestBy,
      note: _noteCtrl.text.trim(),
      shiftID: _selectedShiftId!,
      qty: _qty,
      createBy: staffCode,
      updateBy: staffCode,
      siteID: siteId,
    );

    if (mounted) {
      context.read<OvertimeBloc>().add(OvertimeRequestSubmitted(request));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback? onPick;

  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final text = value != null
        ? '${two(value!.day)}/${two(value!.month)}/${value!.year}'
        : hint;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value != null
                      ? const Color(0xFF0B1B2B)
                      : Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.access_time, size: 18, color: Color(0xFF9AA6B2)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Searchable Bottom Sheet for Employees
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeeSearchSheet extends StatefulWidget {
  final List<EmployeeItem> employees;
  final int? initialId;
  final void Function(int) onSelected;

  const _EmployeeSearchSheet({
    required this.employees,
    this.initialId,
    required this.onSelected,
  });

  @override
  State<_EmployeeSearchSheet> createState() => _EmployeeSearchSheetState();
}

class _EmployeeSearchSheetState extends State<_EmployeeSearchSheet> {
  final _searchCtrl = TextEditingController();
  late List<EmployeeItem> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = widget.employees);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.employees.where((e) {
        return e.displayName.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(top: mq.padding.top + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle & Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chọn nhân viên',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1B2B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc mã nhân viên...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filter,
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy nhân viên nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = _filtered[i];
                      final isSelected = e.id == widget.initialId;
                      return ListTile(
                        title: Text(e.displayName),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFFE55A00),
                              )
                            : null,
                        tileColor: isSelected ? Colors.orange.shade50 : null,
                        onTap: () {
                          widget.onSelected(e.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
