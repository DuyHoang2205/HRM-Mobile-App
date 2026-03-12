import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceExplanationPage extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final String? initialShift;
  final int? initialShiftId;

  const AttendanceExplanationPage({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialShift,
    this.initialShiftId,
  });

  @override
  State<AttendanceExplanationPage> createState() =>
      _AttendanceExplanationPageState();
}

class _AttendanceExplanationPageState extends State<AttendanceExplanationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DioClient _dioClient = DioClient();
  final TextEditingController _descriptionController = TextEditingController();
  final List<PlatformFile> _attachments = <PlatformFile>[];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedShiftId;
  String? _selectedReason;
  String _penalty = 'Có';

  bool _loadingShiftOptions = false;
  List<_ShiftOption> _shiftOptions = const <_ShiftOption>[];

  final List<String> _reasons = const <String>[
    'Quên chấm công',
    'Thiết bị lỗi',
    'Đi công tác',
    'Sự cố cá nhân',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
    _loadShiftOptions();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadShiftOptions();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _loadShiftOptions() async {
    final date = _selectedDate;
    if (date == null) return;

    setState(() => _loadingShiftOptions = true);
    try {
      final employeeID = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      if (employeeID == null || employeeID <= 0) {
        if (!mounted) return;
        setState(() {
          _shiftOptions = const <_ShiftOption>[];
          _selectedShiftId = null;
        });
        return;
      }

      final day =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _dioClient.dio.post(
        'shift/getShiftByDay',
        data: {'employeeID': employeeID, 'date': day, 'siteID': siteID},
      );

      List<dynamic> rows = response.data is List
          ? response.data as List
          : const [];
      var options = rows
          .whereType<Map>()
          .map((row) {
            final map = Map<String, dynamic>.from(row);
            final id =
                (map['id'] as num?)?.toInt() ??
                (map['ID'] as num?)?.toInt() ??
                0;
            final title =
                (map['title'] ??
                        map['Title'] ??
                        map['code'] ??
                        map['Code'] ??
                        'Ca #$id')
                    .toString();
            final code = (map['code'] ?? map['Code'] ?? '').toString();
            final from = (map['fromTime'] ?? map['FromTime'] ?? '').toString();
            final to = (map['toTime'] ?? map['ToTime'] ?? '').toString();
            return _ShiftOption(
              id: id,
              title: title,
              code: code,
              fromTime: from,
              toTime: to,
            );
          })
          .where((option) => option.id > 0)
          .toList();

      if (options.isEmpty) {
        final allShiftResponse = await _dioClient.dio.get('shift/$siteID');
        rows = allShiftResponse.data is List
            ? allShiftResponse.data as List
            : const [];
        options = rows
            .whereType<Map>()
            .map((row) {
              final map = Map<String, dynamic>.from(row);
              final id =
                  (map['id'] as num?)?.toInt() ??
                  (map['ID'] as num?)?.toInt() ??
                  0;
              final title =
                  (map['title'] ??
                          map['Title'] ??
                          map['code'] ??
                          map['Code'] ??
                          'Ca #$id')
                      .toString();
              final code = (map['code'] ?? map['Code'] ?? '').toString();
              final from = (map['fromTime'] ?? map['FromTime'] ?? '')
                  .toString();
              final to = (map['toTime'] ?? map['ToTime'] ?? '').toString();
              return _ShiftOption(
                id: id,
                title: title,
                code: code,
                fromTime: from,
                toTime: to,
              );
            })
            .where((option) => option.id > 0)
            .toList();
      }

      int? picked;
      if (options.isNotEmpty) {
        if (widget.initialShiftId != null && widget.initialShiftId! > 0) {
          picked = options
              .where((option) => option.id == widget.initialShiftId)
              .map((option) => option.id)
              .firstOrNull;
        }
        final initialShiftName = _norm(widget.initialShift ?? '');
        if (initialShiftName.isNotEmpty) {
          picked = options
              .where(
                (option) =>
                    _norm(option.title) == initialShiftName ||
                    _norm(option.code) == initialShiftName ||
                    _norm(option.label).contains(initialShiftName) ||
                    initialShiftName.contains(_norm(option.title)),
              )
              .map((option) => option.id)
              .firstOrNull;
        }
        picked ??= options.first.id;
      } else if (widget.initialShiftId != null && widget.initialShiftId! > 0) {
        final fallback = _ShiftOption(
          id: widget.initialShiftId!,
          title: (widget.initialShift ?? '').trim().isEmpty
              ? 'Ca đã phân'
              : widget.initialShift!.trim(),
          code: '',
          fromTime: '',
          toTime: '',
        );
        options.add(fallback);
        picked = fallback.id;
      }

      if (!mounted) return;
      setState(() {
        _shiftOptions = options;
        _selectedShiftId = picked;
      });
    } catch (_) {
      debugPrint('Cannot load shift options for explanation form');
      if (!mounted) return;
      setState(() {
        _shiftOptions = const <_ShiftOption>[];
        _selectedShiftId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingShiftOptions = false);
      }
    }
  }

  String _norm(String text) => text.trim().toLowerCase();

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateIso(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final date = _selectedDate;
    final time = _selectedTime;
    final reason = _selectedReason;
    if (date == null ||
        time == null ||
        reason == null ||
        _selectedShiftId == null) {
      return;
    }

    final detail = _descriptionController.text.trim();
    final reasonPayload = detail.isEmpty ? reason : '$reason - $detail';
    final attachmentPaths = _attachments
        .map((file) => file.path ?? '')
        .where((path) => path.isNotEmpty)
        .toList();

    context.read<AttendanceBloc>().add(
      AttendanceChangeSubmitted(
        date: _formatDateIso(date),
        time:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
        shiftID: _selectedShiftId!,
        reason: reasonPayload,
        note: detail,
        attachmentPaths: attachmentPaths,
      ),
    );
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const <String>[
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'mp4',
        'mov',
        'mkv',
        'avi',
        'webm',
      ],
    );
    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        final duplicated = _attachments.any((item) => item.path == path);
        if (!duplicated) _attachments.add(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          previous.changeSuccessMessage != current.changeSuccessMessage ||
          previous.error != current.error,
      listener: (context, state) {
        if ((state.changeSuccessMessage ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi giải trình thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if ((state.error ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            title: const Text(
              'Giải trình chấm công',
              style: TextStyle(
                color: Color(0xFF0B1B2B),
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF0B1B2B)),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 14),
                    _buildDescriptionCard(),
                    const SizedBox(height: 14),
                    _buildAttachmentCard(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isSubmittingChange ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C389),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isSubmittingChange
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CẬP NHẬT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E9F0)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              if (compact) {
                return Column(
                  children: [
                    _FieldCard(
                      label: 'Ngày *',
                      value: _formatDate(_selectedDate),
                      suffixIcon: Icons.calendar_month_outlined,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 10),
                    _FieldCard(
                      label: 'Giờ *',
                      value: _formatTime(_selectedTime),
                      suffixIcon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 10),
                    _buildShiftDropdown(),
                    const SizedBox(height: 10),
                    _buildReasonDropdown(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FieldCard(
                          label: 'Ngày *',
                          value: _formatDate(_selectedDate),
                          suffixIcon: Icons.calendar_month_outlined,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FieldCard(
                          label: 'Giờ *',
                          value: _formatTime(_selectedTime),
                          suffixIcon: Icons.access_time,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildShiftDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildReasonDropdown()),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            enabled: false,
            initialValue: _penalty,
            decoration: InputDecoration(
              labelText: 'Phạt tiền',
              labelStyle: const TextStyle(color: Color(0xFF8B96A7)),
              filled: true,
              fillColor: const Color(0xFFF2F5F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E9F0)),
      ),
      child: TextFormField(
        controller: _descriptionController,
        minLines: 6,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Nhập mô tả',
          labelText: 'Mô tả',
          alignLabelWithHint: true,
          labelStyle: const TextStyle(color: Color(0xFF8B96A7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đính kèm',
            style: TextStyle(
              color: Color(0xFF8B96A7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_attachments.isNotEmpty) ...[
            Column(
              children: _attachments.map((file) {
                final name = file.name;
                final ext = name.contains('.')
                    ? name.split('.').last.toLowerCase()
                    : '';
                final isVideo = const <String>[
                  'mp4',
                  'mov',
                  'mkv',
                  'avi',
                  'webm',
                ].contains(ext);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVideo
                            ? Icons.videocam_outlined
                            : Icons.insert_drive_file_outlined,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _attachments.remove(file);
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickAttachments,
              icon: const Icon(Icons.upload_file),
              label: const Text('CHỌN ẢNH/VIDEO/TỆP'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C389)),
                foregroundColor: const Color(0xFF00C389),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('shift_${_selectedShiftId}_${_shiftOptions.length}'),
      initialValue: _selectedShiftId?.toString(),
      isExpanded: true,
      hint: _loadingShiftOptions
          ? const Text('Đang tải ca...')
          : const Text('Ca'),
      decoration: _dropdownDecoration('Ca'),
      items: _shiftOptions
          .map(
            (shift) => DropdownMenuItem<String>(
              value: shift.id.toString(),
              child: Text(shift.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _loadingShiftOptions
          ? null
          : (value) =>
                setState(() => _selectedShiftId = int.tryParse(value ?? '')),
      validator: (value) => value == null ? 'Vui lòng chọn ca làm' : null,
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedReason,
      isExpanded: true,
      hint: const Text('Lý do *'),
      decoration: _dropdownDecoration('Lý do *'),
      items: _reasons
          .map(
            (reason) => DropdownMenuItem<String>(
              value: reason,
              child: Text(reason, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedReason = value;
          _penalty = value == 'Thiết bị lỗi' ? 'Không' : 'Có';
        });
      },
      validator: (value) => value == null ? 'Vui lòng chọn lý do' : null,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8B96A7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData suffixIcon;
  final VoidCallback onTap;

  const _FieldCard({
    required this.label,
    required this.value,
    required this.suffixIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B96A7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(suffixIcon, size: 20, color: const Color(0xFF9AA6B2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftOption {
  final int id;
  final String title;
  final String code;
  final String fromTime;
  final String toTime;

  const _ShiftOption({
    required this.id,
    required this.title,
    required this.code,
    required this.fromTime,
    required this.toTime,
  });

  String get label {
    final from = _clock(fromTime);
    final to = _clock(toTime);
    if (from.isEmpty || to.isEmpty) return title;
    return '$title ($from - $to)';
  }

  String _clock(String raw) {
    final text = raw.trim();
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return '';
    return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
  }
}
