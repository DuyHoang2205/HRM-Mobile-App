# Luồng Công Tác Mobile-First (Flutter + NestJS)

Ngày cập nhật: **2026-03-12**

## Mục tiêu
- Dùng App Mobile để tạo và theo dõi đơn công tác.
- Không cần tách luồng web riêng cho công tác.
- Vẫn map đúng bảng công bằng ký hiệu `C` (nếu backend/SP đã map `PermissionType.Symbol='C'`).

## Backend mới (additive, không phá API cũ)
Module mới trong backend:
- `/Users/baoduy/Documents/work/real_BE/VSCode-darwin-universal.zip/src/module/business-trip-mobile`

Route mới:
- `GET /api/businessTripMobile/permissionType/:siteID`
  - Trả loại phép công tác (`Symbol='C'`) theo site.
- `GET /api/businessTripMobile/:employeeID/:year/:siteID`
  - Trả danh sách đơn công tác của nhân viên trong năm.
- `POST /api/businessTripMobile`
  - Tạo đơn công tác.
  - Backend tự resolve `PermissionType` có `Symbol='C'` và insert vào `OnLeaveFileLine`.

## Mobile flow
- Home > `Thư mục` > `Công tác`.
- Màn Công tác dùng lại UI đơn nghỉ phép nhưng chạy ở `businessTripMode`.
- Khi tạo đơn:
  - App vẫn gửi payload chuẩn như đơn nghỉ phép.
  - Nếu backend mới sẵn sàng: gọi `POST /businessTripMobile`.
  - Nếu backend chưa deploy: tự fallback về `POST /onLeaveFileLine`.

## Kết nối dữ liệu bảng công
- Bảng công vẫn lấy từ API daily summary.
- Nếu SP đã map đúng `PermissionType.Symbol='C'` thì ngày công tác sẽ hiện `C`.

## Checklist test nhanh
1. Mở app bằng user có quyền tạo đơn.
2. Vào `Công tác`, tạo đơn 1 ngày.
3. Kiểm tra API trả về thành công (`ADD`).
4. Mở lại danh sách Công tác, thấy đơn vừa tạo.
5. Duyệt đơn theo luồng hiện tại của hệ thống (nếu cần).
6. Mở bảng công ngày đó, xác nhận hiển thị `C` (nếu SP đã join/map).

