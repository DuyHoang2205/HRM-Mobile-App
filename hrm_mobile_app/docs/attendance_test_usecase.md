# Kịch Bản Test End-to-End Chấm Công (BA/UAT)

Ngày cập nhật: **2026-03-10**

## 1) Điều kiện trước khi test
- API backend local đã chạy.
- SP mới đã deploy vào DB đang dùng bởi backend.
- Mobile trỏ đúng base URL backend test.
- Có user test với `employeeID` hợp lệ (ví dụ `2`, `3195`).

## 2) API cần test
- `POST /api/attendance/mobile/daily-summary/:siteID`
- Body:
```json
{
  "employeeId": 2,
  "fromDate": "2026-03-01",
  "toDate": "2026-03-31"
}
```

## 3) Bộ test theo use case

### UC1 - Đi trễ / Về sớm
SQL chuẩn bị:
```sql
-- Ví dụ tạo log đi trễ/về sớm
-- (điều chỉnh AttendCode theo nhân viên test)
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime)
VALUES ('<ATTEND_CODE>', '2026-03-11', '09:20:00'), ('<ATTEND_CODE>', '2026-03-11', '17:30:00');
```
Kỳ vọng:
- `lateMinutes > 0`
- `earlyLeaveMinutes > 0` nếu trước giờ kết ca.

### UC2 - Thiếu giờ tối thiểu
SQL chuẩn bị:
```sql
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime)
VALUES ('<ATTEND_CODE>', '2026-03-12', '09:00:00'), ('<ATTEND_CODE>', '2026-03-12', '11:00:00');
```
Kỳ vọng:
- `rawWorkedHours` thấp hơn ngưỡng ca
- `daySymbol = 'x/P'`

### UC3 - Nhiều log trong ngày
SQL chuẩn bị:
```sql
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime)
VALUES
('<ATTEND_CODE>', '2026-03-13', '08:10:00'),
('<ATTEND_CODE>', '2026-03-13', '10:30:00'),
('<ATTEND_CODE>', '2026-03-13', '13:10:00'),
('<ATTEND_CODE>', '2026-03-13', '18:05:00');
```
Kỳ vọng:
- `firstIn = 08:10:00`
- `lastOut = 18:05:00`

### UC4 - Trừ nghỉ giữa ca
Điều kiện: Shift có `startBreak/endBreak`.
Kỳ vọng:
- `breakMinutesDeducted > 0`
- `rawWorkedHours` đã trừ break.

### UC5 - Thiếu log OUT
SQL chuẩn bị:
```sql
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime)
VALUES ('<ATTEND_CODE>', '2026-03-14', '08:00:00');
```
Kỳ vọng:
- `daySymbol = 'x'`
- `missingType = 'OUT'`

### UC6 - Ca qua ngày
Điều kiện: Shift có `isCrossDay=1` hoặc `toTime <= fromTime`.
SQL chuẩn bị:
```sql
INSERT INTO dbo.AttendanceTime (AttendCode, AuthDate, AuthTime)
VALUES
('<ATTEND_CODE>', '2026-03-15', '22:00:00'),
('<ATTEND_CODE>', '2026-03-16', '06:05:00');
```
Kỳ vọng:
- Dữ liệu ngày 2026-03-15 có `isCrossDay = 1`
- `lastOut` lấy từ ngày hôm sau.

### UC7 - Nửa ngày công + nửa ngày phép
Điều kiện: có đơn phép duyệt (`OnLeaveFileLine.Status=3`, `Qty=0.5`).
Kỳ vọng:
- `leaveFraction = 0.5`
- `daySymbol = 'x/P'` (khi có log làm việc cùng ngày).

### UC8 - Công tác
Điều kiện: đơn có `PermissionType.Symbol='C'`, đã duyệt.
Kỳ vọng:
- `daySymbol = 'C'`
- `businessTripCode` có dữ liệu.

### UC9 - OT có/không có đơn
Kỳ vọng:
- Không có đơn OT duyệt: `otEligibleMinutes > 0`, `otApprovedMinutes = 0`
- Có đơn OT duyệt (DecisionOverTime + DecisionApply, status=3): `otApprovedMinutes > 0`

## 4) Flow test trên Mobile
1. Đăng nhập user cần test.
2. Vào `Chấm công` -> tab `Bảng công` -> `Công tháng`.
3. Chạm vào từng ô ngày để mở popup chi tiết.
4. Đối chiếu các trường: `Ký hiệu`, `Vào đầu tiên`, `Ra cuối cùng`, `Giờ làm thực tế`, `Trừ nghỉ giữa ca`, `Đi trễ`, `Về sớm`, `OT`.

## 5) Checklist BA nghiệm thu
- Ký hiệu ngày (`1/x/x/P/P/C/0`) đúng với dữ liệu DB.
- Ca qua ngày không bị tách sai ngày công.
- Trễ/sớm và break hiển thị đúng số phút.
- OT đủ điều kiện và OT đã duyệt hiển thị đúng.
- Popup chi tiết tiếng Việt hiển thị đầy đủ và dễ hiểu.
