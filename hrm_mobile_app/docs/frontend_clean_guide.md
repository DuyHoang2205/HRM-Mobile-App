# HRM Flutter Frontend Clean Guide

## Target Folder Structure

```text
lib/
  app/
    theme/
  core/
    auth/
    constants/
    helpers/
    network/
    utils/
    widgets/
  features/
    <feature_name>/
      bloc/
      data/
      models/
      view/
      widgets/
```

## Prompt - UI Refactor

```text
Tôi đang làm app HRM bằng Flutter. Hãy refactor đoạn code UI dưới đây:

1) Decomposition:
- Tách Widget lớn thành Widget nhỏ theo vai trò rõ ràng (ví dụ: EmployeeListItem, SalaryBadge, HeaderSection).

2) Refactor Constants:
- Chuyển các giá trị cứng (màu sắc, font size, padding, radius) thành constants hoặc Theme.of(context).

3) Performance:
- Dùng const constructor ở nơi phù hợp để giảm rebuild.
- Tránh tạo object lặp trong build nếu có thể tái sử dụng.

4) Readability:
- Tổ chức lại cây widget tối đa 3-4 tầng lồng nhau.
- Đặt tên widget/hàm rõ nghĩa theo nghiệp vụ HRM.

Code: [Dán code Dart]
```

## Prompt - Logic & State Management

```text
Đây là logic xử lý [chức năng HRM] trong app Flutter. Hãy clean theo chuẩn Senior:

1) Separation of Concerns:
- Tách API call vào repository/service, BLoC chỉ điều phối state.
- UI chỉ render state và trigger event.

2) Error Handling:
- Dùng try-catch rõ ràng.
- Trả message thân thiện với user, không để lộ lỗi kỹ thuật raw.

3) Data Mapping:
- Parse JSON vào model class typed.
- Không dùng Map<String, dynamic> trực tiếp trong UI.

4) Naming:
- Đặt tên biến/hàm theo camelCase, rõ ý nghĩa nghiệp vụ.

Code: [Dán code logic]
```

## Prompt - Form & Validation

```text
Hãy refactor form này trong app HRM:

1) Validation:
- Dùng GlobalKey<FormState>.
- Validate đầy đủ: required, email format, số dương cho lương/giờ.

2) Reuse:
- Tách TextFormField thành custom widget dùng chung toàn project.

3) UX:
- Ẩn bàn phím khi submit thành công.
- Hiển thị lỗi gần field + thông báo tổng quát nếu cần.

Code: [Dán code form]
```

## Checklist

- Folder rõ ràng theo feature + layer (`bloc`, `data`, `models`, `view`, `widgets`).
- Không hardcode text: dùng localization (`intl`/`easy_localization`).
- Colors/Typography dùng `ThemeData`.
- Asset path tập trung trong 1 class (`AppAssets`).
- UI không gọi API trực tiếp.
- Model typed, tránh `dynamic` lan rộng.
