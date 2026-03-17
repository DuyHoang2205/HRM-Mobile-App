# Overtime Flow: Backend + Frontend

## 1. Mobile frontend dang gui gi

Frontend OT nam o:
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/overtime/data/overtime_repository.dart`
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/overtime/view/overtime_registration_page.dart`
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/overtime/bloc/overtime_bloc.dart`

### Tao don tang ca
Mobile gui:
- `POST /decisionOvertime`

Body duoc build tu `OvertimeRequest.toJson()`:
- `status`
- `fromDate`
- `toDate`
- `requestBy`
- `reason`
- `note`
- `shiftID`
- `qty`
- `ignore`
- `createBy`
- `updateBy`
- `docType = 'OTDocType'`
- `siteID`
- neu update thi co them `id`

### Logic status trong mobile
- HR tao phieu: `status = 2`
- Nhan vien tu dang ky: `status = 0`

### Danh sach OT
Mobile load:
- `GET /decisionOvertime/:siteID`

Sau do loc client-side:
- HR: thay tat ca
- Nhan vien: chi thay `requestBy == employeeId cua minh`

### Danh sach nhan vien cho HR
Mobile goi:
- `GET /employee/list-employee?site=KIA`

### Danh sach ca OT
Mobile goi:
- `GET /shift/getShiftOvertime/:siteID`

## 2. Backend dang xu ly gi

Backend OT nam o:
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/decisionovertime/decisionOvertime.controller.ts`
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/decisionovertime/decisionOvertime.service.ts`
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/decisionovertime/entities/decisionOvertime.entity.ts`

### Route backend
- `POST /decisionOvertime`
  - save record vao entity `DecisionOvertime`
  - khong goi stored procedure save rieng
- `GET /decisionOvertime/:siteID`
  - lay tat ca ban ghi OT theo site
- `GET /decisionOvertime/detail/:siteID`
  - goi `DecisionOvertimeGetAll @siteID`
- `GET /decisionOvertime/:period/:siteID`
  - goi `DecisionOvertimeGetByUser @period, @username, @siteID`
- `POST /decisionOvertime/getByOrganization/:siteID`
  - goi `DecisionOvertimeGetByUser_bk @period, @username, @siteID, @organization`
- `GET /decisionOvertime/getByID/:siteID/:decisionID`
  - lay chi tiet 1 don
- `DELETE /decisionOvertime/:id`
  - xoa don

## 3. Dashboard/trang danh sach OT hien status nhu the nao

Frontend khong doc thang status SQL de hien text cuoi cung. No tinh client-side trong:
- `/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/lib/features/overtime/helpers/overtime_status_helper.dart`

Cac trang thai hien thi:
- `Sắp tới`
- `Trong ca`
- `Nghỉ phép`
- `Hoàn thành`
- `Vắng mặt`

Logic:
- neu co leave da duyet overlap voi OT -> `Nghỉ phép`
- neu chua toi gio -> `Sắp tới`
- neu dang trong khoang OT -> `Trong ca`
- neu da qua gio va co attendance trong ngay -> `Hoàn thành`
- neu da qua gio va khong co attendance -> `Vắng mặt`

## 4. Nhung DB objects quan trong de kiem tra OT

### Table/entity
- `DecisionOvertime`
- `Shift`
- `Employee`
- `AttendanceTime`
- `OnLeaveFileLine`
- `PermissionType`
- `WorkOfDayPlan`

### Stored procedure / route lien quan
- `DecisionOvertimeGetAll`
- `DecisionOvertimeGetByUser`
- `DecisionOvertimeGetByUser_bk`
- `GetListShiftOvertime`
- `GetShiftByDate`
- `AttendanceGetWithDay`
- `sp_GetDailyTimesheetSummary`

## 5. Y nghia symbol day trong bang cong ma UI dang dung

Trong UI timesheet hien tai, cac symbol quan trong de demo la:
- `1`: di lam du cong
- `0`: khong co cong / khong co scan / khong co don duoc overlay
- `X`: thieu log check-in/check-out
- `P`: nghi phep full ngay da duyet
- `C`: cong tac da duyet
- `x/P`: nua ngay cong + nua ngay phep

Luu y:
- `P`, `C`, `x/P` hien len nho overlay leave client-side trong `attendance_bloc.dart`
- nghia la can co du lieu leave that trong `OnLeaveFileLine` va `PermissionType`
