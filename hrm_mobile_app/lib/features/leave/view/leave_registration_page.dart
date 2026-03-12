import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/leave_request.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';
import '../../../core/auth/auth_helper.dart';

class LeaveRegistrationPage extends StatelessWidget {
  final String pageTitle;
  final String? forcePermissionSymbol;

  const LeaveRegistrationPage({
    super.key,
    this.pageTitle = 'Đăng ký nghỉ',
    this.forcePermissionSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isBusinessTripMode =
        forcePermissionSymbol?.trim().toUpperCase() == 'C';
    return BlocProvider(
      create: (_) =>
          LeaveBloc(businessTripMode: isBusinessTripMode)
            ..add(const LeaveStarted()),
      child: _LeaveRegistrationView(
        pageTitle: pageTitle,
        forcePermissionSymbol: forcePermissionSymbol,
      ),
    );
  }
}

class _LeaveRegistrationView extends StatefulWidget {
  final String pageTitle;
  final String? forcePermissionSymbol;

  const _LeaveRegistrationView({
    required this.pageTitle,
    required this.forcePermissionSymbol,
  });

  @override
  State<_LeaveRegistrationView> createState() => _LeaveRegistrationViewState();
}

class _LeaveRegistrationViewState extends State<_LeaveRegistrationView> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;
  String _halfDayOption = 'ALL'; // 'ALL', 'MORNING', 'AFTERNOON'

  // permissionType là số nguyên (ID), được load từ state.permissionTypes (API)
  int? _selectedPermissionTypeId;
  bool _didAutoBindPermission = false;

  final TextEditingController _descCtrl = TextEditingController();
  final List<String> _attachedFiles = [];

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveBloc, LeaveState>(
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
          title: Text(
            widget.pageTitle,
            style: const TextStyle(
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Ngày bắt đầu', required: true),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmtDate(_startDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildLabel('Ngày kết thúc', required: true),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmtDate(_endDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_isSameDay(_startDate, _endDate)) ...[
                  _buildLabel('Thời gian nghỉ'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_halfDayOption),
                    dropdownColor: Colors.white,
                    initialValue: _halfDayOption,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Cả ngày (1.0 ngày)'),
                      ),
                      DropdownMenuItem(
                        value: 'MORNING',
                        child: Text('Buổi sáng (0.5 ngày)'),
                      ),
                      DropdownMenuItem(
                        value: 'AFTERNOON',
                        child: Text('Buổi chiều (0.5 ngày)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _halfDayOption = v);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                _buildLabel(
                  widget.forcePermissionSymbol == null
                      ? 'Lý do / Loại phép'
                      : 'Loại đơn',
                  required: true,
                ),
                const SizedBox(height: 8),
                // Dropdown load từ state.permissionTypes (API thật, không hardcode)
                BlocBuilder<LeaveBloc, LeaveState>(
                  buildWhen: (prev, cur) =>
                      prev.permissionTypes != cur.permissionTypes ||
                      prev.isLoading != cur.isLoading,
                  builder: (context, state) {
                    _tryAutoBindPermissionType(state);
                    if (state.isLoading && state.permissionTypes.isEmpty) {
                      return const LinearProgressIndicator();
                    }
                    if (widget.forcePermissionSymbol != null) {
                      final selected = state.permissionTypes
                          .where((e) => e.id == _selectedPermissionTypeId)
                          .firstOrNull;
                      return TextFormField(
                        enabled: false,
                        initialValue:
                            selected?.permissionType ?? 'Đang tải loại đơn...',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      // Ép menu xổ xuống có chiều cao tối đa và có thể cuộn
                      menuMaxHeight: 300,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      initialValue: _selectedPermissionTypeId,
                      isExpanded: true,
                      items: state.permissionTypes
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e.id,
                              child: Text(
                                e.permissionType,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPermissionTypeId = v),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn loại phép' : null,
                    );
                  },
                ),

                const SizedBox(height: 16),
                _buildLabel('Diễn giải', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Vui lòng nhập diễn giải'
                      : null,
                ),

                const SizedBox(height: 16),
                const Text(
                  'Tệp đính kèm...',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),

                // Attached Files List
                if (_attachedFiles.isNotEmpty)
                  Column(
                    children: _attachedFiles.map((file) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _attachedFiles.remove(file);
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                InkWell(
                  onTap: () {
                    // MOCK FILE PICKING
                    setState(() {
                      _attachedFiles.add(
                        'minh_chung_benh_an_${_attachedFiles.length + 1}.jpg',
                      );
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.upload_file_outlined,
                        color: Color(0xFF0B2D5B),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Thêm',
                        style: TextStyle(
                          color: Color(0xFF0B2D5B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: BlocBuilder<LeaveBloc, LeaveState>(
                builder: (context, state) {
                  return ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCACFD6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Color(0xFFCACFD6);
                            }
                            return const Color(0xFF00C389);
                          }),
                        ),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: state.isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Gửi yêu cầu',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 16,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    // Format numeric: DD/MM/YYYY
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Future<String> _fmtDateImageStyle(DateTime? d) async {
  //   // If we want "5 Feb 2026", we need DateFormat.
  //   // Keeping it simple.
  // }

  Future<void> _pickDate(bool isStart) async {
    // Ngày tối thiểu: ngày mai (không được xin nghỉ cho ngày hôm nay hoặc quá khứ)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final todayMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    final initialDate = isStart
        ? (_startDate != null && _startDate!.isAfter(todayMidnight)
              ? _startDate!
              : todayMidnight)
        : (_endDate != null && _endDate!.isAfter(todayMidnight)
              ? _endDate!
              : (_startDate ?? todayMidnight));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: todayMidnight, // ← chỉ chọn từ ngày mai trở đi
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(
                0xFFE55A00,
              ), // Màu cam chủ đạo cho ngày đang chọn và header
              onPrimary: Colors.white, // Màu chữ trên nền cam (Trắng)
              onSurface: Color(
                0xFF0B1B2B,
              ), // Màu chữ số ngày bình thường (Xanh đen)
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFFE55A00,
                ), // Màu chữ của nút OK/Cancel
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Nếu ngày kết thúc đang được chọn bé hơn ngày bắt đầu mới → reset
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }

        // Reset halfDayOption nếu chọn nhiều ngày
        if (!_isSameDay(_startDate, _endDate)) {
          _halfDayOption = 'ALL';
        }
      });
    }
  }

  // _submit() bất đồng bộ vì cần đọc AuthHelper (secure storage)
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày bắt đầu và kết thúc'),
          ),
        );
        return;
      }
      if (_selectedPermissionTypeId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không tìm thấy loại đơn phù hợp. Vui lòng kiểm tra PermissionType.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Lấy thông tin user từ secure session — không hardcode
      final employeeId = await AuthHelper.getEmployeeId();
      final siteId = await AuthHelper.getSiteId();
      // staffCode được dùng làm createBy/updateBy (theo convention của backend)
      final staffCode = await AuthHelper.getStaffCode();

      if (employeeId == null || staffCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không lấy được thông tin phiên đăng nhập. Vui lòng đăng nhập lại.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Tính số ngày nghỉ (qty)
      double qty = _endDate!.difference(_startDate!).inDays + 1.0;
      if (_isSameDay(_startDate, _endDate)) {
        if (_halfDayOption == 'MORNING' || _halfDayOption == 'AFTERNOON') {
          qty = 0.5;
        }
      }

      final req = LeaveRequest(
        // id không gửi khi tạo mới — backend tự sinh (PrimaryGeneratedColumn)
        employeeID: employeeId,
        status: 0, // 0 = draft / chờ nộp
        permissionType: _selectedPermissionTypeId!,
        fromDate: _startDate!,
        toDate: _endDate!,
        expired: _endDate!.add(
          const Duration(days: 30),
        ), // Convention: hết hạn sau 30 ngày
        qty: qty,
        year: _startDate!.year,
        description: _descCtrl.text.trim(),
        createBy: staffCode, // dùng staffCode theo convention của backend
        updateBy: staffCode,
        siteID: siteId,
        docType:
            'OLDocType', // Phải là 'OLDocType' để SP ApproveProgressSave xử lý đúng
      );

      if (mounted) {
        context.read<LeaveBloc>().add(LeaveRequestSubmitted(req));
      }
    }
  }

  void _tryAutoBindPermissionType(LeaveState state) {
    final forceSymbol = widget.forcePermissionSymbol?.trim().toUpperCase();
    if (_didAutoBindPermission || forceSymbol == null || forceSymbol.isEmpty) {
      return;
    }
    if (state.permissionTypes.isEmpty) return;

    final match = state.permissionTypes
        .where((e) => e.symbol.trim().toUpperCase() == forceSymbol)
        .firstOrNull;
    if (match != null) {
      setState(() {
        _selectedPermissionTypeId = match.id;
        _didAutoBindPermission = true;
      });
      return;
    }
    _didAutoBindPermission = true;
  }
}
