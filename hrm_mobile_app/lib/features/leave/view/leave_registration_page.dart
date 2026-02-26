import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/leave_request.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';

class LeaveRegistrationPage extends StatelessWidget {
  const LeaveRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveBloc(),
      child: const _LeaveRegistrationView(),
    );
  }
}

class _LeaveRegistrationView extends StatefulWidget {
  const _LeaveRegistrationView();

  @override
  State<_LeaveRegistrationView> createState() => _LeaveRegistrationViewState();
}

class _LeaveRegistrationViewState extends State<_LeaveRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedReason;
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final List<String> _attachedFiles = [];

  final List<String> _reasons = [
    'Nghỉ phép thường niên | Annual leave',
    'Nghỉ bù | Compensatory leave',
    'Nghỉ không lương | Unpaid leave',
    'Nghỉ ốm hưởng BHXH | Sick leave with social insurance benefits',
    'Nghỉ ngưng việc hay chờ việc | Standby or Temporary layoff',
    'Nghỉ bản thân kết hôn | Marriage leave',
    'Nghỉ ma chay (3 ngày) | Bereavement leave (3 days)',
    'Nghỉ người thân kết hôn | Leave for a relative\'s wedding',
    'Nghỉ tai nạn lao động | Leave due to workplace accident',
    'Nghỉ khám thai | Prenatal check-up leave',
    'Nghỉ Thai sản | Maternity leave',
    'Nghỉ ma chay (1 ngày) | Bereavement leave (1 day)',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveBloc, LeaveState>(
      listener: (context, state) {
        if (state.submitSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.submitSuccess!)));
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Đăng ký nghỉ', style: TextStyle(color: Color(0xFF0B1B2B), fontWeight: FontWeight.bold)),
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
                _buildLabel('Ngày bắt đầu', required: true),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmtDate(_startDate), style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmtDate(_endDate), style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
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
                  isExpanded: true,
                  items: _reasons.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                  validator: (v) => v == null ? 'Vui lòng chọn lý do' : null,
                ),

                const SizedBox(height: 16),
                _buildLabel('Địa điểm'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),
                _buildLabel('Diễn giải', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập diễn giải' : null,
                ),

                const SizedBox(height: 16),
                const Text('Tệp đính kèm...', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),

                // Attached Files List
                if (_attachedFiles.isNotEmpty)
                  Column(
                    children: _attachedFiles.map((file) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                                child: Icon(Icons.close, color: Colors.red, size: 18),
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
                       _attachedFiles.add('minh_chung_benh_an_${_attachedFiles.length + 1}.jpg');
                     });
                  },
                  child: Row(
                    children: [
                       const Icon(Icons.upload_file_outlined, color: Color(0xFF0B2D5B)),
                       const SizedBox(width: 8),
                       const Text('Thêm', style: TextStyle(color: Color(0xFF0B2D5B), fontWeight: FontWeight.bold)),
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
              child: BlocBuilder<LeaveBloc, LeaveState>(
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.day} ${d.month < 10 ? '0${d.month}' : d.month} ${d.year}';
     // Format like "5 Feb 2026" in image? Image shows "5 Feb 2026". 
     // Let's stick to simple DD/MM/YYYY for consistency with app or try to match image exact?
     // Image: "5 Feb 2026". 
     // Let's use simple numeric for now to be safe with Locales: DD/MM/YYYY
     return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
  
  // Future<String> _fmtDateImageStyle(DateTime? d) async {
  //   // If we want "5 Feb 2026", we need DateFormat.
  //   // Keeping it simple.
  // }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')));
        return;
      }
      
      final req = LeaveRequest(
        id: 0,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _selectedReason!,
        location: _locationCtrl.text,
        description: _descCtrl.text,
        status: 'PENDING',
        createdDate: DateTime.now(),
      );
      
      context.read<LeaveBloc>().add(LeaveRequestSubmitted(req));
    }
  }
}
