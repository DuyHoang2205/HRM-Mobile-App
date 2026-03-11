# Ma Trận Use Case Chấm Công (ZENSUITE HRM)

Ngày cập nhật: **2026-03-10**

## Phạm vi
- Mobile: Flutter (`attendance`, `checkin`, `timesheet`)
- Backend: NestJS + SQL Server
- SP chính: `dbo.sp_Mobile_GetDailyTimesheetSummary`
- API chính: `POST /api/attendance/mobile/daily-summary/:siteID`

## Trạng thái triển khai

| STT | Use case | Trạng thái | Triển khai thực tế |
|---|---|---|---|
| 1 | Đi trễ / Về sớm | Done | SP đã trả `lateMinutes`, `earlyLeaveMinutes`; Mobile hiển thị trong popup chi tiết. |
| 2 | Không đạt giờ tối thiểu | Done | SP so sánh `NetWorkedMinutes` với `timeCalculate`/`workTime` theo từng ca (không hard-code). |
| 3 | Chấm công nhiều lần | Done | SP dùng `MIN(AuthTime)` cho `firstIn` và `MAX(AuthTime)` cho `lastOut`. |
| 4 | Trừ nghỉ giữa ca | Done | SP tính overlap giữa giờ làm thực tế và `startBreak/endBreak`, trả `breakMinutesDeducted`. |
| 5 | Thiếu log In/Out | Done | SP trả `missingType` + `daySymbol='x'` khi thiếu log hoặc chỉ có 1 mốc chấm công. |
| 6 | Ca qua ngày | Done | SP tự nhận diện ca qua ngày bằng `isCrossDay` hoặc `toTime <= fromTime`, gom mốc qua ngày T+1. |
| 7 | Nửa ngày công + nửa ngày phép | Done | SP join `OnLeaveFileLine` + `PermissionType`, trả `daySymbol='x/P'` khi có phép bán phần + có log làm việc. |
| 8 | Đơn công tác | Done | SP dùng `PermissionType.Symbol='C'` để ưu tiên trả `daySymbol='C'`. |
| 9 | OT có/không có đơn | Done | SP trả `otEligibleMinutes` (phát sinh thực tế) và `otApprovedMinutes` (join `DecisionOverTime` + `DecisionApply`, status=3). |

## Quy tắc ký hiệu ngày công (daySymbol)
- `1`: Đủ công theo ngưỡng ca.
- `x`: Lỗi chấm công (thiếu log).
- `x/P`: Chưa đủ giờ hoặc kết hợp công + phép bán phần.
- `P` / `1L`: Nghỉ phép đã duyệt (full ngày).
- `C`: Công tác đã duyệt.
- `0`: Không phát sinh công / nghỉ.

## Dữ liệu API Daily Summary đã chuẩn hóa
SP hiện trả các trường chính sau (Mobile đã parse):
- `date`, `shiftCode`, `shiftTitle`, `shiftFromTime`, `shiftToTime`
- `firstIn`, `lastOut`
- `rawWorkedHours`, `breakMinutesDeducted`, `requiredHours`, `timeCalculate`
- `lateMinutes`, `earlyLeaveMinutes`
- `otEligibleMinutes`, `otApprovedMinutes`
- `isCrossDay`, `missingType`, `workFraction`, `leaveFraction`, `leaveType`, `businessTripCode`, `finalizeStatus`
- `daySymbol`

## File đã cập nhật

### Backend
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/attendance/sp_Mobile_GetDailyTimesheetSummary.sql`
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/attendance/attendance.service.ts`

### Mobile
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/attendance/models/daily_summary.dart`
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/attendance/bloc/attendance_bloc.dart`
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/attendance/view/timesheet_page.dart`
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/checkin/bloc/checkin_bloc.dart`

## Ghi chú vận hành
- Điều kiện duyệt đơn hiện đang dùng `Status = 3` (OT/Leave) theo dữ liệu hệ thống hiện tại.
- `PermissionType.Symbol` là nguồn xác định `P/C` trong bảng công.
- Mobile chỉ hiển thị theo kết quả SP (Backend là nguồn sự thật).
- Không hard-code ngưỡng công tối thiểu trong App. Ngưỡng được đọc từ `timeCalculate/workTime` theo từng ca.
- Không hard-code mapping user test (`admin`, `baoduy`) trong CheckInBloc.
- Runtime API và bù giờ ca có thể cấu hình bằng `--dart-define`:
  - `API_BASE_URL`
  - `SHIFT_HOUR_COMPENSATION`
