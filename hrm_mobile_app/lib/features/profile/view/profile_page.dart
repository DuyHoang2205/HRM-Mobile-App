import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showPersonalDetails = false;
  bool _showContactInfo = false;
  bool _showWorkInfo = false;
  bool _showEducation = false;
  bool _showContracts = false;
  bool _showWorkHistory = false;

  String _displayText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return 'N/A';
    return text;
  }

  String _labelText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return 'N/A';
    if (double.tryParse(text) != null) return 'N/A';
    return text;
  }

  String _addressText(String? street, String? district, String? city) {
    final parts = <String>[
      if ((street ?? '').trim().isNotEmpty) street!.trim(),
      if ((district ?? '').trim().isNotEmpty &&
          double.tryParse(district!.trim()) == null)
        district.trim(),
      if ((city ?? '').trim().isNotEmpty &&
          double.tryParse(city!.trim()) == null)
        city.trim(),
    ];
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            color: Color(0xFF0B1B2B),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              if (profileState.status == ProfileStatus.failure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Không thể tải hồ sơ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profileState.error ?? 'Đã xảy ra lỗi không xác định',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProfileBloc>().add(const ProfileRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B2D5B),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final profile = profileState.profile;
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(const ProfileRequested());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      // Top Section: Basic Info
                      _buildBasicInfo(homeState, profile),
                      const SizedBox(height: 20),

                      // Middle Section: Status Rows
                      _buildInfoRow(
                        Icons.business_center_outlined,
                        'Phòng ban',
                        _labelText(profile?.department),
                      ),
                      _buildInfoRow(
                        Icons.account_tree_outlined,
                        'Bộ phận',
                        _labelText(profile?.organization),
                      ),
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Chức danh',
                        _labelText(profile?.position),
                      ),
                      _buildInfoRow(
                        Icons.assignment_ind_outlined,
                        'Loại nhân viên',
                        _displayText(profile?.employeeType),
                      ),
                      _buildInfoRow(
                        Icons.check_circle_outline,
                        'Tình trạng',
                        _displayText(profile?.status),
                      ),

                      const SizedBox(height: 24),

                      // Expandable Sections
                      _buildExpandableSection(
                        title: 'Thông tin cá nhân chi tiết',
                        icon: Icons.person_pin_outlined,
                        isExpanded: _showPersonalDetails,
                        onToggle: () => setState(() => _showPersonalDetails = !_showPersonalDetails),
                        child: _buildDetailedInfo(profile),
                      ),
                      
                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Thông tin liên hệ',
                        icon: Icons.contact_phone_outlined,
                        isExpanded: _showContactInfo,
                        onToggle: () => setState(() => _showContactInfo = !_showContactInfo),
                        child: _buildContactInfo(profile),
                      ),

                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Thông tin công việc',
                        icon: Icons.work_outline,
                        isExpanded: _showWorkInfo,
                        onToggle: () => setState(() => _showWorkInfo = !_showWorkInfo),
                        child: _buildWorkInfo(profile),
                      ),

                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Thông tin học vấn',
                        icon: Icons.school_outlined,
                        isExpanded: _showEducation,
                        onToggle: () => setState(() => _showEducation = !_showEducation),
                        child: _buildEducationInfo(profile),
                      ),

                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Thông tin hợp đồng',
                        icon: Icons.history_edu_outlined,
                        isExpanded: _showContracts,
                        onToggle: () => setState(() => _showContracts = !_showContracts),
                        child: _buildContractInfo(profile),
                      ),

                      const SizedBox(height: 12),
                      _buildExpandableSection(
                        title: 'Quá trình làm việc',
                        icon: Icons.timeline,
                        isExpanded: _showWorkHistory,
                        onToggle: () => setState(() => _showWorkHistory = !_showWorkHistory),
                        child: _buildWorkHistoryInfo(profile),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFF0B2D5B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isExpanded ? Colors.white : const Color(0xFF0B2D5B),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? Colors.white : const Color(0xFF0B1B2B),
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: isExpanded ? Colors.white : const Color(0xFF9AA6B2),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: child,
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(HomeState homeState, UserProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0B2D5B), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              homeState.initials.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B2D5B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (profile?.fullName != null && profile!.fullName.isNotEmpty) 
                      ? profile.fullName 
                      : homeState.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B2B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã: ${profile?.code ?? 'N/A'} | MCC: ${profile?.attendCode ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B778C),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile?.gender ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047481),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0B2D5B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B778C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1B2B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(UserProfile? profile) {
    return _buildDetailCard([
      _buildDetailItem('Ngày sinh', profile?.birthday ?? 'N/A'),
      _buildDetailItem('Nơi sinh', _labelText(profile?.birthPlace)),
      _buildDetailItem('CMND/CCCD', profile?.identityNum ?? 'N/A'),
      _buildDetailItem('Ngày cấp', profile?.datePro ?? 'N/A'),
      _buildDetailItem('Nơi cấp', profile?.placePro ?? 'N/A'),
      _buildDetailItem('Dân tộc', profile?.ethnic ?? 'N/A'),
      _buildDetailItem('Số tài khoản', profile?.accountNum ?? 'N/A'),
      _buildDetailItem('Ngân hàng', profile?.bankName ?? 'N/A'),
      _buildDetailItem('Mã số thuế', profile?.taxCode ?? 'N/A'),
      _buildDetailItem('Số BHXH', profile?.insuranceNum ?? 'N/A'),
    ]);
  }

  Widget _buildContactInfo(UserProfile? profile) {
    return _buildDetailCard([
      _buildDetailItem('Gmail', profile?.email ?? 'N/A'),
      _buildDetailItem('Zalo', profile?.zalo ?? 'N/A'),
      _buildDetailItem('Facebook', profile?.facebook ?? 'N/A'),
      _buildDetailItem('SĐT 1', profile?.phone1 ?? 'N/A'),
      _buildDetailItem('SĐT 2', profile?.phone2 ?? 'N/A'),
      const Divider(height: 24),
      const Text('THƯỜNG TRÚ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0B2D5B))),
      const SizedBox(height: 8),
      _buildDetailItem(
        'Địa chỉ',
        _addressText(profile?.streetPri, profile?.districtPri, profile?.cityPri),
      ),
      const Divider(height: 24),
      const Text('TẠM TRÚ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0B2D5B))),
      const SizedBox(height: 8),
      _buildDetailItem(
        'Địa chỉ',
        _addressText(profile?.streetSec, profile?.districtSec, profile?.citySec),
      ),
    ]);
  }

  Widget _buildWorkInfo(UserProfile? profile) {
    return _buildDetailCard([
      _buildDetailItem('Ngày ký HĐ', profile?.dateSign ?? 'N/A'),
      _buildDetailItem('Ngày kết thúc HĐ', profile?.dateSignEnd ?? 'N/A'),
      _buildDetailItem('Loại hợp đồng', profile?.contractType ?? 'N/A'),
      _buildDetailItem('Số HĐLĐ', profile?.contractNum ?? 'N/A'),
      _buildDetailItem('Số phụ lục HĐ', profile?.appendixNum ?? 'N/A'),
      _buildDetailItem('Ngày bắt đầu LV', profile?.dateStart ?? 'N/A'),
      _buildDetailItem('Ngày kết thúc thử việc', profile?.dateEnd ?? 'N/A'),
      _buildDetailItem('Ngày nghỉ việc', profile?.dateResign ?? 'N/A'),
      _buildDetailItem('Nhóm lao động', profile?.laborGroup ?? 'N/A'),
      _buildDetailItem('Tự động chấm công', profile?.isIgnoreScan == true ? 'Có' : 'Không'),
    ]);
  }

  Widget _buildEducationInfo(UserProfile? profile) {
    if (profile == null || profile.education.isEmpty) {
      return _buildDetailCard([const Center(child: Text('Không có dữ liệu'))]);
    }
    return Column(
      children: profile.education.map((edu) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: _buildDetailCard([
          _buildDetailItem('Trình độ', edu.level ?? 'N/A'),
          _buildDetailItem('Nơi đào tạo', edu.school ?? 'N/A'),
          _buildDetailItem('Khoa', edu.faculty ?? 'N/A'),
          _buildDetailItem('Năm tốt nghiệp', edu.graduationYear?.toString() ?? 'N/A'),
          _buildDetailItem('Xếp hạng', edu.rank ?? 'N/A'),
        ]),
      )).toList(),
    );
  }

  Widget _buildContractInfo(UserProfile? profile) {
    if (profile == null || profile.contracts.isEmpty) {
      return _buildDetailCard([const Center(child: Text('Không có dữ liệu'))]);
    }
    return Column(
      children: profile.contracts.map((contract) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: _buildDetailCard([
          _buildDetailItem('Loại hợp đồng', contract.contractType ?? 'N/A'),
          _buildDetailItem('Ngày ký', contract.signDate ?? 'N/A'),
          _buildDetailItem('Số HĐ', contract.contractNum ?? 'N/A'),
          _buildDetailItem('Bắt đầu', contract.startDate ?? 'N/A'),
          _buildDetailItem('Kết thúc', contract.endDate ?? 'N/A'),
          _buildDetailItem('Trạng thái', contract.status ?? 'N/A'),
        ]),
      )).toList(),
    );
  }

  Widget _buildWorkHistoryInfo(UserProfile? profile) {
    if (profile == null || profile.workHistory.isEmpty) {
      return _buildDetailCard([const Center(child: Text('Không có dữ liệu'))]);
    }
    return Column(
      children: profile.workHistory.map((history) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: _buildDetailCard([
          _buildDetailItem('Hành động', history.action ?? 'N/A'),
          _buildDetailItem('Ngày hiệu lực', history.effectiveDate ?? 'N/A'),
          _buildDetailItem('Trạng thái', history.status ?? 'N/A'),
          _buildDetailItem('Từ/đến cty', history.fromTo ?? 'N/A'),
        ]),
      )).toList(),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B778C),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1B2B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
