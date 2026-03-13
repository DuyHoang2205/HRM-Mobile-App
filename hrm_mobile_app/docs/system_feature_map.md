# Bản đồ tính năng & quan hệ giữa các module
## HRM Mobile App ↔ NestJS Backend ↔ SQL Server

> Cập nhật: 11/03/2026

---

## 🗺️ Sơ đồ tổng quan — Luồng dữ liệu chính

```
[Nhân viên dùng App]
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│                    HRM MOBILE APP (Flutter)                  │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌─────────────┐  │
│  │ Chấm công│ │ Nghỉ phép│ │   OT/Tăng  │ │  Bảng lương │  │
│  │ (Check-  │ │  (Leave) │ │   ca (OT)  │ │  (Salary    │  │
│  │  in/out) │ │          │ │            │ │   Slip)     │  │
│  └────┬─────┘ └────┬─────┘ └─────┬──────┘ └──────┬──────┘  │
└───────┼────────────┼─────────────┼───────────────┼──────────┘
        │            │             │               │
        ▼            ▼             ▼               ▼
┌─────────────────────────────────────────────────────────────┐
│               NestJS REST API Backend                        │
│  /attendance  /onLeaveFileLine  /decisionovertime  /salary  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   SQL Server Database                        │
│  AttendanceTime | OnLeaveFileLine | DecisionOvertime         │
│  WorkPlan | Shift | Employee | SalaryCalculate | SalarySlip  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Các màn hình hiện có trên App Mobile

| Màn hình | Flutter Feature | Chức năng chính |
|----------|----------------|----------------|
| Chấm công | `checkin` | Bấm nút Vào / Ra ca, kiểm tra vị trí GPS, cảnh báo về sớm |
| Bảng công (Timesheet) | `attendance` | Xem lịch tháng/tuần theo ký hiệu công, xem chi tiết từng ngày |
| Nghỉ phép | `leave` | Xem đơn nghỉ phép, tạo đơn mới, theo dõi trạng thái duyệt |
| OT / Tăng ca | `overtime` | Xem đơn OT, tạo đơn tăng ca mới, theo dõi giờ được duyệt |
| Trang chủ | `home` | Dashboard tổng hợp thông báo, trạng thái hôm nay |
| Đăng nhập | `auth` | Xác thực JWT |

> 🔴 **Chú ý:** Hiện tại App **chưa có màn hình Bảng lương (Salary Slip)**. Chỉ Backend có API.

---

## 🔗 Quan hệ nghiệp vụ giữa các module

### 1. CHẤM CÔNG → BẢNG LƯƠNG (Mạch quan trọng nhất)

```
Nhân viên check-in
       │
       ▼
AttendanceTime (bảng DB) ← ghi nhận mỗi lần quẹt
       │
       ▼
sp_GetDailyTimesheetSummary ← tính toán ngày công
       │
       ├── Đủ công → daySymbol = "1"
       ├── Thiếu giờ → daySymbol = "x/P"
       ├── Thiếu log → daySymbol = "x"
       └── Nghỉ phép (JOIN OnLeaveFileLine) → daySymbol = "P"
       │
       ▼
SalaryCalculate SP (CaculateEmployeeSalary)
       │
     Đọc tổng ngày công tháng × Lương cơ bản
       │ + Phụ cấp (Allowance)
       │ + OT được duyệt (DecisionOvertime)
       │ - Trừ vắng (Absence deduction)
       │ - Bảo hiểm (Insurance)
       │
       ▼
SalarySlip (Phiếu lương)
```

---

### 2. NGHỈ PHÉP → BẢNG CÔNG → LƯƠNG

```
NV tạo Đơn Nghỉ Phép (Leave Request)
       │  POST /api/onLeaveFileLine
       ▼
OnLeaveFileLine (DB) [fromDate, toDate, qty ngày, status]
       │
       │ HR duyệt → status = 3 (Approved)
       ▼
sp_GetDailyTimesheetSummary JOIN OnLeaveFileLine
       │  → daySymbol = "P" (toàn ngày) hoặc "x/P" (nửa ngày)
       ▼
SalaryCalculate: ngày nghỉ phép = ngày công bình thường (không trừ lương)
```

**Các loại phép hiện tại (PermissionType):**
- Nghỉ phép năm
- Nghỉ không hưởng lương
- Nghỉ bù (CompensatoryLeave)
- Nghỉ thai sản / ốm đau

---

### 3. OT / TĂNG CA → LƯƠNG

```
NV nộp Đơn OT (Overtime Request)
       │  POST /api/decisionovertime
       ▼
DecisionOvertime (DB) [fromDate, toDate, shiftID, qty giờ OT]
       │
       │ Manager duyệt → status = Approved
       ▼
sp_GetDailyTimesheetSummary:
       │  → otEligibleMinutes (giờ tăng ca thực tế)
       │  → otApprovedMinutes (giờ OT được duyệt)
       ▼
SalaryCalculate:
       │  Giờ OT × Hệ số OT (150% / 200% / 300%)
       ▼
SalarySlip: Cột "Phụ cấp OT"
```

---

### 4. CÔNG TÁC → BẢNG CÔNG (Chưa hoàn chỉnh)

```
NV nộp Đơn Công Tác (Business Trip)
       │  [Module chưa xác định rõ trong Backend]
       ▼
[Bảng DB chứa đơn công tác - cần xác nhận tên bảng]
       │
       │ Duyệt → Các ngày công tác = 1 ngày công
       ▼
sp_GetDailyTimesheetSummary:
       │  → daySymbol = "C" (Công tác)
       ▼
SalaryCalculate: ngày công tác = ngày công bình thường + phụ cấp công tác
```

> ⚠️ **Lưu ý:** Backend hiện tại không có module `business-trip` riêng. Cần xác nhận tên bảng chứa dữ liệu đơn công tác trong DB.

---

### 5. CA LÀM VIỆC → TẤT CẢ CÁC MODULE

```
Shift (Bảng ca)
├── workTime: Tổng giờ ca (vd: 9 tiếng)
├── timeCalculate: Giờ tối thiểu tính 1 công (vd: 7.75 = 7h45')
├── startBreak / endBreak: Giờ nghỉ trưa
├── fromTime / toTime: Giờ bắt đầu/kết thúc ca
└── isCrossDay: Ca qua ngày (ca đêm)
       │
       ├── → Chấm công: App dùng để cảnh báo ra ca sớm
       ├── → Bảng công: SP dùng để tính giờ đạt/không đạt
       ├── → OT: Đơn OT phải khai ca làm việc
       └── → Lương: Ca xác định hệ số OT áp dụng
```

---

## 💰 Cấu trúc tính lương (Salary Calculation)

```
Lương tháng = Lương cơ bản (Basic Salary)
            × (Ngày công thực tế / Ngày công chuẩn)
            + Phụ cấp cố định (Fixed Allowance)
            + Phụ cấp biến động (Variable Allowance)
            + OT được duyệt × Hệ số
            - Trừ vắng không phép
            - Bảo hiểm BHXH/BHYT/BHTN
            - Thuế TNCN
            = NET SALARY
```

**Các SP liên quan đến lương:**
- `SalaryCaculate` — Chạy tính toán lương theo kỳ
- `CaculateEmployeeSalary` — Lưu kết quả lương từng nhân viên
- `GetSalarySlipByEmployeeID` — Lấy phiếu lương của 1 người
- `GetSalarySlipByPeriod` — Lấy toàn bộ phiếu lương theo kỳ

---

## 📋 Luồng duyệt đơn (Approval Workflow)

Mọi đơn từ (Phép, OT, Giải trình, Công tác) đều đi qua cùng 1 engine phê duyệt:

```
Nhân viên tạo đơn
       │
       ▼ status = 0 (Chờ duyệt)
Quản lý trực tiếp xem xét
       │
       ├── Duyệt → status = 3 (Approved)
       │            ↓ Hệ thống tự cập nhật bảng công / lương
       │
       └── Từ chối → status = 4 (Rejected)
                      ↓ NV nhận thông báo, có thể nộp lại
```

**Engine phê duyệt:** `ApproveProgressSave` SP + bảng `ApproveProgress`

---

## 🚦 Trạng thái hiện tại — Tính năng App vs Backend

| Tính năng | App Mobile | Backend API | DB SP | Trạng thái |
|-----------|-----------|------------|-------|-----------|
| Check-in/out | ✅ | ✅ | ✅ | **Hoàn chỉnh** |
| Bảng công tháng/tuần | ✅ | ✅ | ✅ (local) | **Hoạt động Local** |
| Xem phép / tạo đơn phép | ✅ | ✅ | ✅ | **Hoàn chỉnh** |
| Xem OT / tạo đơn OT | ✅ | ✅ | ✅ | **Hoàn chỉnh** |
| Đơn giải trình thiếu log | ✅ UI | ✅ | - | **Cần test E2E** |
| Ký hiệu "P" từ đơn phép | ✅ UI | ⏳ SP join | - | **SP chưa join** |
| Ký hiệu "C" từ đơn công tác | ✅ UI | ❌ | - | **Backend chưa làm** |
| OT vào bảng công | ✅ UI | ⏳ SP join | - | **SP chưa join** |
| Phiếu lương (Salary Slip) | ❌ Chưa có màn hình | ✅ API | ✅ | **App chưa làm** |
| Thông báo push | ❌ | ❌ | - | **Chưa làm** |

---

## 🔧 Việc cần làm để hoàn thiện hệ thống

### Ưu tiên cao (Backend DB)
1. **Deploy SP `sp_GetDailyTimesheetSummary`** lên server Production/VPN
   Ghi chu KIA: DB KIA ban dau chua co proc nay. Da co script bo sung tai [sp_GetDailyTimesheetSummary_kia.sql](/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/docs/sp_GetDailyTimesheetSummary_kia.sql) va checklist verify tai [kia_backend_summary_verification.md](/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/docs/kia_backend_summary_verification.md).
2. **JOIN đơn nghỉ phép** vào SP để nhả cờ `P` và `x/P`
3. **JOIN đơn OT** vào SP để trả `otEligibleMinutes` / `otApprovedMinutes`

### Ưu tiên trung bình (Mobile App)
4. **Màn hình Phiếu lương** — Xem lương theo kỳ, chi tiết từng khoản
5. **Notification** — Thông báo khi đơn được duyệt/từ chối

### Ưu tiên thấp (Tương lai)
6. **Module Công tác** — Tạo đơn công tác trên App
7. **Module Chấm công bù** — Cho ca đêm qua ngày
