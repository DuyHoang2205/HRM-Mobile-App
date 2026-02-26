import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/overtime_request.dart';
import '../bloc/overtime_bloc.dart';
import '../bloc/overtime_event.dart';
import '../bloc/overtime_state.dart';

class OvertimeRegistrationPage extends StatelessWidget {
  const OvertimeRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We create a new Bloc for submission since the ListPage bloc might be disposed if we replace route,
    // but here we are pushing, so ListPage is still there. 
    // However, it's cleaner to have a dedicated provider or pass the existing one.
    // Since ListPage logic is "Fetch List", and Registration is "Submit", they can share or use separate.
    // I'll create a new Bloc instance for simplicity of isolation.
    return BlocProvider(
      create: (_) => OvertimeBloc(),
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
  String? _selectedReason;
  final TextEditingController _reasonOtherCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _breakCtrl = TextEditingController();
  String? _selectedReeProMobilization;
  String? _selectedReeProProject;

  final List<String> _reasons = [
    'Tăng ca để xây dựng kế hoạch năm tới',
    'Tăng ca xử lý công việc phát sinh',
    'Tăng ca chạy Deadline',
    'Lý do khác | Other',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state.submitSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.submitSuccess!)));
          Navigator.of(context).pop(true); // Return true to refresh list
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Đăng ký làm thêm', style: TextStyle(color: Color(0xFF0B1B2B), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1B2B)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmtTime(_startTime), style: const TextStyle(fontSize: 16)),
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmtTime(_endTime), style: const TextStyle(fontSize: 16)),
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Checkbox(
                      value: _isNextDay,
                      activeColor: const Color(0xFF00C389),
                      onChanged: (v) => setState(() => _isNextDay = v ?? false),
                    ),
                    const Text('Làm thêm sang ngày hôm sau'),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildLabel('Lý do', required: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  initialValue: _selectedReason,
                  items: _reasons.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                  validator: (v) => v == null ? 'Vui lòng chọn lý do' : null,
                  isExpanded: true,
                ),

                if (_selectedReason == 'Lý do khác | Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonOtherCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do khác',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildLabel('Diễn giải', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập diễn giải' : null,
                ),

                const SizedBox(height: 16),
                const Text('Thông tin bổ sung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _breakCtrl,
                  decoration: InputDecoration(
                    hintText: 'Số phút nghỉ giữa giờ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                 DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Điều động ReePro',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  initialValue: _selectedReeProMobilization,
                  items: const [DropdownMenuItem(value: 'Option 1', child: Text('Option 1'))], // Placeholder
                  onChanged: (v) => setState(() => _selectedReeProMobilization = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Công trình ReePro',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  initialValue: _selectedReeProProject,
                  items: const [DropdownMenuItem(value: 'Project A', child: Text('Project A'))], // Placeholder
                  onChanged: (v) => setState(() => _selectedReeProProject = v),
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: BlocBuilder<OvertimeBloc, OvertimeState>(
                builder: (context, state) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCACFD6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                         if (states.contains(WidgetState.disabled)) return const Color(0xFFCACFD6);
                         return const Color(0xFF00C389);
                      }), 
                    ),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: state.isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontSize: 16)),
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
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        children: [
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
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
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    if (_formKey.currentState?.validate() ?? false) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc')));
        return;
      }
      
      final req = OvertimeRequest(
        id: 0, // new
        date: _selectedDate,
        startTime: _fmtTime(_startTime),
        endTime: _fmtTime(_endTime),
        isNextDay: _isNextDay,
        reason: _selectedReason == 'Lý do khác | Other' ? (_reasonOtherCtrl.text) : _selectedReason!,
        description: _descCtrl.text,
        status: 'PENDING',
        createdDate: DateTime.now(),
      );
      
      context.read<OvertimeBloc>().add(OvertimeRequestSubmitted(req));
    }
  }
}
