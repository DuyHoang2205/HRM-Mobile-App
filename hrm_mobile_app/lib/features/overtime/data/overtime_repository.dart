import '../models/overtime_model.dart';

class OvertimeRepository {
  // Danh sách Mock Data hardcode dựa trên thiết kế Figma (Pic 2 & Pic 5)
  // Static để có thể share giữa các trang khi load lại Repo
  static final List<OvertimeModel> _mockData = [
    OvertimeModel(
      id: '1',
      date: DateTime(2026, 5, 22),
      startTime: '09:00',
      endTime: '23:00',
      totalHours: 14.0,
      reason: 'Tăng ca để xây dựng kế hoạch năm tới',
      description: 'lmao',
      breakMinutes: 5,
      reeproDispatch: 'Điều động 1',
      reeproProject: 'Dự án Alpha',
      approverName: 'Phạm Văn D',
      status: 'Chờ duyệt',
    ),
    OvertimeModel(
      id: '2',
      date: DateTime(2026, 1, 18),
      startTime: '18:00',
      endTime: '22:00',
      totalHours: 4.0,
      reason: 'Tăng ca chạy Deadline',
      description: 'Hoàn thiện báo cáo dự án trước deadline',
      breakMinutes: 30,
      reeproDispatch: null,
      reeproProject: null,
      approverName: 'Phạm Văn D',
      status: 'Đã duyệt',
      isNextDay: false,
    ),
  ];

  Future<List<OvertimeModel>> fetchOvertimeRequests() async {
    // Giả lập delay từ network
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_mockData); // clone list to avoid external modification
  }

  Future<void> createOvertimeRequest(OvertimeModel newRequest) async {
    // Giả lập delay từ network
    await Future.delayed(const Duration(milliseconds: 800));
    _mockData.insert(0, newRequest); // Thêm vào đầu list
  }
}
