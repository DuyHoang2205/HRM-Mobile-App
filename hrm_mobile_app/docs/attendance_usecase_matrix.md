# Attendance Use Case Matrix (HRM Mobile + NestJS + SQL)

## Scope
- Frontend: Flutter mobile app (`attendance`, `checkin`, `timesheet`).
- Backend: NestJS API + SQL Server stored procedures.
- Date: March 10, 2026.

## Current Summary
- Mobile already supports:
  - Early check-out blocking by shift end time (`/shift/getShiftByDay`).
  - Timesheet day evaluation by `First In / Last Out`.
  - Break-time deduction from worked duration.
  - Minimum worked duration per day loaded dynamically from shift (`timeCalculate`/`workTime`) instead of hardcoded `7h45`.
- Backend currently exposes raw attendance + shift data, but most payroll-grade rules are not centralized yet.

---

## 1) Use Case Matrix

| STT | Use Case | Kịch bản | Logic xử lý | Current Status (Mobile & BE) | Next Step |
|---|---|---|---|---|---|
| 1 | Đi trễ / Về sớm | Ca 08:00 - 17:00. User check-in 08:15, check-out 16:50. | Hệ thống đối chiếu thời gian cho phép. Nếu vượt quá, tính toán phút trễ/sớm và trừ vào ngày công (vd: trễ < 30p trừ 0.1 công). | **Partial:** Mobile đã chặn chặn về sớm, bắt điền lý do (TimekeepingOffset). | Backend cần tích hợp Rule engine trừ công khi tính Payroll. |
| 2 | Không đạt số giờ làm tối thiểu | User check-in 09:00, check-out 10:00 cho ca 9 tiếng. | Hệ thống cấu hình Thời gian Out - In >= 7tiếng45phút thì mới tính 1 ngày công. | **Implemented (Mobile):** Tự tham chiếu `timeCalculate` từ ca để tính đủ/thiếu giờ. | Backend cần sync Logic này vào SP chốt công cuối ngày. |
| 3 | Chấm công nhiều lần trong ngày | User có thói quen quét vân tay nhiều lần (09:00, 10:15, 12:00, 13:00, 18:00). | Tính công theo First In (log đầu) và Last Out (log cuối). | **Implemented (Mobile):** App đã lấy hàm Max/Min cho Check-in/out. | Backend cần SP lọc in/out chính xác để ráp thành Timesheet chuẩn. |
| 4 | Nghỉ giữa ca | Ca 08:00-17:00, nghỉ trưa 12:00-13:00. User in 08:00, out 17:00. | Hệ thống tự động trừ 1 tiếng nghỉ trưa ra khỏi tổng thời gian làm việc (còn 8h). | **Implemented (Mobile):** App đã check `startBreak`, `endBreak` để trừ hao. | Mọi API Timesheet backend cần trừ Break tự động. |
| 5 | Thiếu log In hoặc Out | User check-in 08:00, chiều về quên check-out. | Bảng công báo vắng (0 công). User phải tạo Đơn giải trình. Khi duyệt, hệ thống tự điền log Out (vd: 17:00) và tính lại. | **Implemented (Mobile):** Mobile flow gửi API Đơn giải trình (vào `timekeepingoffset`) kèm tham số `wordReason` đã hoạt động. | HR duyệt Đơn giải trình trên web -> Backend cập nhật log Attendance. |
| 6 | Ca làm việc qua ngày | Ca 22:00(T) - 06:00(T+1). User in 21:50, out 06:10. | Không tách 2 ngày công. Flag ca đêm gom 2 logs lại tính cho Ngày T. | **Partial:** Mobile chưa gom chuỗi group log qua ngày hoàn chỉnh. | Backend cần cắm cờ `isCrossDay` xử lý pair array, trả sẵn mốc về. |
| 7 | Làm việc nửa ngày + Đơn phép nửa ngày | User làm sáng (08:00-12:00), chiều xin phép năm (Annual Leave). | Cộng dồn [0.5 công thực tế] + [0.5 công phép]. Bảng công hiện `x/P`. | **Not implemented:** Chưa gom Đơn và Chấm công vào 1 kết quả. | Backend tạo SP tính tổng hợp (Daily Result) trả về `daySymbol`. |
| 8 | Có log chấm công + Đơn đi công tác | User đi công tác xa, không chấm tại VP, nhưng có đơn 10/10-12/10. | Bổ sung Đơn vào dữ liệu. 10-12/10 tự động fill 1 công/ngày, nhãn "C". | **Not implemented:** Chưa xử lý nhãn "C" phối hợp Đơn. | Backend tạo SP Daily Result đè công tác vào log trống. |
| 9 | Làm thêm giờ nhưng không có đơn OT | Ca kết thúc 17:00. User check-out 20:00 (Dư 3 tiếng). | Lấy tối đa 17:00 (1 công chuẩn). 3 tiếng dư không tính vào công, chỉ map OT khi có OT Request duyệt. | **Partial:** Backend có flow Đơn OT nhưng chưa trừ cấn trừ tổng kết ngày. | Backend chốt công thức `otEligibleMinutes` và `otApprovedMinutes`. |

---

## 2) What Exists in Backend (Confirmed)

- Attendance APIs:
  - `POST /api/attendance/byEmployee/:siteID` -> `AttendanceFilterByEmployee`
  - `POST /api/attendance/getScanByDay/:siteID` -> `AttendanceGetWithDay`
- Shift APIs:
  - `POST /api/shift/getShiftByDay` -> `GetShiftByDate`
  - Shift entity has: `workTime`, `timeCalculate`, `startBreak`, `endBreak`, `isCrossDay`
- OT flow:
  - Create OT: `POST /api/decisionOvertime` (save OT record)
  - Approval: `POST /api/decisionApply/:siteID/:decisionID` -> `DecisionApplySave`
  - `DecisionApplySave` currently inserts `WorkPlan` on approval, does **not** update `WorkOfDayPlan`

---

## 3) Recommended Implementation Plan

## Phase 1 (High Impact, Fast)
1. Add backend endpoint/SP for authoritative daily attendance result per employee-date:
   - Inputs: `employeeId`, `fromDate`, `toDate`, `siteID`
   - Output fields:
     - `workDate`, `firstIn`, `lastOut`, `workedMinutes`
     - `lateMinutes`, `earlyLeaveMinutes`
     - `requiredMinutes`, `breakMinutes`
     - `daySymbol` (`N`, `x`, `x/P`, `C`, ...)
     - `otEligibleMinutes`, `otApprovedMinutes`
2. Use this endpoint in mobile Timesheet tab instead of local-only inference for final labels.

## Phase 2 (Policy Engine)
1. Add policy tables:
   - `AttendancePolicy` (site/department/shift scope)
   - `LateEarlyPenaltyRule` (minute range -> fraction deduction)
2. Integrate policies into backend attendance daily result SP.

## Phase 3 (Exception Workflows)
1. Missing OUT + explanation approval:
   - On approval, generate or patch out-log with approved time.
2. Business trip + leave merge:
   - Resolve precedence order and output single final symbol per day.

---

## 4) SQL/SP Checklist for Backend Team

```sql
-- A) Verify shift config used for minimum hours/break
SELECT ID, Code, Title, workTime, timeCalculate, startBreak, endBreak, isCrossDay
FROM dbo.Shift
WHERE ID IN (
    SELECT DISTINCT ShiftID
    FROM dbo.WorkPlan
    WHERE EmployeeID = @EmployeeID
      AND DateApply BETWEEN @FromDate AND @ToDate
);

-- B) Verify raw scans for one day (source data)
EXEC dbo.AttendanceGetWithDay @EmployeeID = @EmployeeID, @Day = @Date;

-- C) Verify aggregated scans from byEmployee range
EXEC dbo.AttendanceFilterByEmployee
    @EmployeeID = @EmployeeID,
    @FromDate = @FromDate,
    @ToDate = @ToDate,
    @SiteID = @SiteID;

-- D) Verify OT approval impact
SELECT *
FROM dbo.DecisionOvertime
WHERE RequestBy = @EmployeeID
  AND FromDate <= @ToDate
  AND ToDate >= @FromDate;

SELECT *
FROM dbo.DecisionApply
WHERE EmployeeID = @EmployeeID;
```

---

## 5) Mobile Follow-up Tasks (After Backend Daily Result API)

1. Replace local timesheet status inference with backend daily result.
2. Keep local fallback (current logic) only when API is unavailable.
3. Display detailed reasons in UI tooltip/dialog:
   - `Đi trễ 18 phút`, `Về sớm 10 phút`, `Thiếu OUT`, `0.5 công + 0.5 phép`, etc.

---

## 6) Decision Notes

- Do not hardcode minimum day threshold (`7h45`) globally.
- Use shift-driven config (`timeCalculate` preferred, fallback `workTime`).
- Final payroll-impact rules should be backend source-of-truth to avoid divergence between mobile and payroll.

