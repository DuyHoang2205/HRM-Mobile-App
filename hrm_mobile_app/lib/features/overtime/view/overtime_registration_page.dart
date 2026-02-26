import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';
import '../data/overtime_repository.dart';
import '../models/overtime_reason.dart';

class OvertimeRegistrationPage extends StatelessWidget {
  const OvertimeRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OvertimeBloc(repository: OvertimeRepository()),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView();

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isNextDay = false;
  OvertimeReason? _selectedReason;
  final TextEditingController _reasonOtherCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _breakCtrl = TextEditingController();

  String? _selectedReeproDispatch;
  String? _selectedReeproProject;

  final List<String> _dispatchOptions = [
    'Điều động 1',
    'Điều động 2',
    'Điều động 3',
  ];
  final List<String> _projectOptions = [
    'Dự án Alpha',
    'Dự án Beta',
    'Dự án Gamma',
  ];

  @override
  void dispose() {
    _reasonOtherCtrl.dispose();
    _descCtrl.dispose();
    _breakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state.status == OvertimeStatus.submitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo yêu cầu làm ngoài giờ thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.status == OvertimeStatus.submitFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Đăng ký làm thêm',
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Ngày', required: true),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmtDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF9AA6B2),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Bắt đầu', required: true),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startTime == null
                                        ? '--:--'
                                        : _fmtTime(_startTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF9AA6B2),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Kết thúc', required: true),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickTime(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endTime == null
                                        ? '--:--'
                                        : _fmtTime(_endTime),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF9AA6B2),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: _isNextDay,
                        activeColor: const Color(0xFF0B2A5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        onChanged: (v) =>
                            setState(() => _isNextDay = v ?? false),
                      ),
                    ),
                    const Text(
                      'Làm thêm sang ngày hôm sau',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildLabel('Lý do', required: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<OvertimeReason>(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9AA6B2),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  value: _selectedReason,
                  hint: const Text('Chọn lý do'),
                  items: OvertimeReason.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: SizedBox(
                            width:
                                MediaQuery.of(context).size.width -
                                80, // Prevent overflow
                            child: Text(
                              '${e.labelVi} | ${e.labelEn}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                  validator: (v) => v == null ? 'Vui lòng chọn lý do' : null,
                  isExpanded: true,
                ),

                if (_selectedReason == OvertimeReason.other) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonOtherCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do khác',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập lý do'
                        : null,
                  ),
                ],

                const SizedBox(height: 20),
                _buildLabel('Diễn giải', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Nhập diễn giải...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập diễn giải'
                      : null,
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                const SizedBox(height: 12),

                const Text(
                  'Thông tin bổ sung',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0B1B2B),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breakCtrl,
                  decoration: InputDecoration(
                    hintText: 'Số phút nghỉ giữa giờ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                _buildLabel('Điều động ReePro'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9AA6B2),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  value: _selectedReeproDispatch,
                  hint: const Text('Lựa chọn'),
                  items: _dispatchOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReeproDispatch = v),
                ),

                const SizedBox(height: 16),
                _buildLabel('Công trình ReePro'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9AA6B2),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0B2A5B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  value: _selectedReeproProject,
                  hint: const Text('Lựa chọn'),
                  items: _projectOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReeproProject = v),
                ),

                const SizedBox(height: 80), // padding for bottom button
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: BlocBuilder<OvertimeBloc, OvertimeState>(
                builder: (context, state) {
                  final isSubmitting =
                      state.status == OvertimeStatus.submitting;
                  final btnColor = const Color(0xFF0B2A5B);
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Gửi yêu cầu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
          fontSize: 15,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0B2A5B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0B2A5B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    bool hasTimeError = false;
    if (_startTime == null || _endTime == null) {
      hasTimeError = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (hasTimeError) return;

      final finalReason = _selectedReason == OvertimeReason.other
          ? _reasonOtherCtrl.text
          : _selectedReason!.labelVi;
      context.read<OvertimeBloc>().add(
        SubmitOvertimeRequest(
          date: _selectedDate,
          startTime: _fmtTime(_startTime),
          endTime: _fmtTime(_endTime),
          reason: finalReason,
          description: _descCtrl.text,
          isNextDay: _isNextDay,
          breakMinutes: int.tryParse(_breakCtrl.text) ?? 0,
          reeproDispatch: _selectedReeproDispatch,
          reeproProject: _selectedReeproProject,
        ),
      );
    }
  }
}
