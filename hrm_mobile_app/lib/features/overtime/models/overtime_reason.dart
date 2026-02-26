enum OvertimeReason {
  buildPlan(
    'Tăng ca để xây dựng kế hoạch năm tới',
    'Work overtime to build next year\'s plan',
  ),
  arisingWork(
    'Tăng ca xử lý công việc phát sinh',
    'Work overtime to handle arising work',
  ),
  meetDeadline('Tăng ca chạy Deadline', 'Work overtime to meet the deadline'),
  other('Lý do khác', 'Other'),
  noAttendance(
    'Tăng ca xử lý công việc (không chấm công)',
    'Work overtime to handle work (no attendance)',
  ),
  approvedPlan(
    'Tăng ca theo kế hoạch đã được phê duyệt',
    'Approved overtime plan',
  );

  final String labelVi;
  final String labelEn;

  const OvertimeReason(this.labelVi, this.labelEn);
}
