# Tài liệu Giải Thích Tính Năng Chấm Công Trên Ứng Dụng Di Động
### Dành cho Khách hàng & Người dùng cuối
---

> Tài liệu này mô tả cách ứng dụng HRM Mobile xử lý các tình huống chấm công thực tế.
> Không cần hiểu về kỹ thuật — chỉ cần nắm rõ tình huống và kết quả hiển thị.

---

## 📱 Bảng ký hiệu trên Lịch công

Trên màn hình Lịch Công, mỗi ô trong tháng sẽ hiển thị một trong các ký hiệu sau:

| Ký hiệu | Màu sắc | Ý nghĩa |
|---------|---------|---------|
| `1` | 🟢 Xanh lá | Đủ công — Vào và ra đúng giờ, đủ giờ làm việc |
| `x` | 🟡 Vàng | Lỗi công — Thiếu giờ vào hoặc giờ ra, cần giải trình |
| `x/P` | 🟡 Vàng | Nửa ngày làm + Nửa ngày phép đã được duyệt |
| `P` | 🔴 Đỏ | Ngày nghỉ phép đã được HR duyệt toàn bộ |
| `C` | 🔵 Xanh dương | Ngày đi công tác đã được duyệt |
| `0` | ⬜ Xám | Ngày nghỉ / Chưa có dữ liệu chấm công |

> 💡 **Mẹo:** Nhấn vào bất kỳ ô nào trên lịch để xem chi tiết (giờ vào, giờ ra, số giờ làm, lý do ký hiệu, v.v.)

---

## 🗂️ Các Tình Huống Thường Gặp

---

### 📌 Tình huống 1: Nhân viên đi trễ hoặc về sớm hơn quy định

**Mô tả:**
Nhân viên làm ca 8:00 – 17:00, nhưng vào lúc 8:15 (trễ 15 phút) hoặc về lúc 16:45 (sớm 15 phút).

**Ứng dụng xử lý như thế nào?**
- Khi nhân viên bấm nút **"Ra ca"** mà chưa đến giờ quy định, App sẽ **hiện cảnh báo** và yêu cầu nhập **Lý do về sớm** (ví dụ: Khám bệnh, Việc gia đình...).
- Lý do này sẽ được gửi lên hệ thống để bộ phận HR xem xét.
- HR có thể cấu hình quy tắc: đi trễ dưới 15 phút thì vẫn 1 công; trên 30 phút thì trừ công...

**Kết quả hiển thị:** Tùy cấu hình của HR, ngày đó có thể vẫn là `1` (đủ công) hoặc bị trừ một phần.

---

### 📌 Tình huống 2: Nhân viên làm chưa đủ số giờ tối thiểu

**Mô tả:**
Ca quy định làm 8 tiếng. Nhân viên vào lúc 9:00, ra lúc 11:00 (chỉ làm 2 tiếng).

**Ứng dụng xử lý như thế nào?**
- Hệ thống tự động so sánh tổng giờ làm thực tế với số giờ tối thiểu do HR cấu hình cho từng ca.
- Nếu không đạt → tự động đánh dấu ngày đó là lỗi hoặc thiếu công.

**Kết quả hiển thị:** `x/P` (nửa công) hoặc `x` (lỗi công), tùy tình huống.

---

### 📌 Tình huống 3: Nhân viên quẹt thẻ/vân tay nhiều lần trong ngày

**Mô tả:**
Thiết bị chấm công ghi nhận nhiều lần quét: 8:30, 9:12, 11:30, 13:00, 18:00.

**Ứng dụng xử lý như thế nào?**
- Hệ thống **tự động lọc** lấy mốc vào sớm nhất (8:30) và mốc ra muộn nhất (18:00).
- Không bị tính nhầm do quẹt lặp.

**Kết quả hiển thị:** `1` — Đủ công bình thường.

---

### 📌 Tình huống 4: Ca làm việc có giờ nghỉ giữa ca (nghỉ trưa)

**Mô tả:**
Ca 8:00 – 17:00, với 1 tiếng nghỉ trưa từ 12:00 – 13:00. Nhân viên quẹt vào 8:00, quẹt ra 17:00.

**Ứng dụng xử lý như thế nào?**
- Hệ thống **tự động trừ 1 tiếng nghỉ trưa** ra khỏi tổng thời gian.
- Kết quả: 17:00 – 8:00 = 9 tiếng, trừ 1 tiếng nghỉ = **8 tiếng làm việc thực tế**.
- Nhân viên không bị oan vì giờ nghỉ trưa được tính toán tự động theo cấu hình ca.

**Kết quả hiển thị:** `1` — Đủ công.

---

### 📌 Tình huống 5: Quên quẹt thẻ ra (hoặc vào)

**Mô tả:**
Nhân viên quẹt vào 8:00 buổi sáng, nhưng chiều về quên quẹt ra.

**Ứng dụng xử lý như thế nào?**
1. Hệ thống phát hiện thiếu lượt ra → đánh dấu ngày đó là `x` (lỗi).
2. Nhân viên thấy ký hiệu `x` trên lịch → vào App để **nộp Đơn Giải Trình** (ghi rõ lý do).
3. HR xem xét và duyệt đơn.
4. Sau khi duyệt, hệ thống tự động bổ sung giờ ra → ngày đó chuyển thành `1`.

**Kết quả hiển thị:** Ban đầu `x`, sau khi HR duyệt đổi thành `1`.

---

### 📌 Tình huống 6: Ca làm đêm, vắt qua 2 ngày (Ca qua ngày)

**Mô tả:**
Nhân viên làm ca đêm từ 22:00 Thứ Hai đến 6:00 Thứ Ba.

**Ứng dụng xử lý như thế nào?**
- Hệ thống nhận diện ca đêm qua cờ đặc biệt do HR cấu hình.
- Toàn bộ thời gian ca đêm được gom vào **1 ngày công** (Thứ Hai), không tách thành 2 ngày.

**Kết quả hiển thị:** Thứ Hai hiện `1` — Thứ Ba để trống (hoặc tùy ca có thể điều chỉnh).

> ⚙️ *Tính năng này cần HR cấu hình "Ca qua ngày" trên hệ thống.*

---

### 📌 Tình huống 7: Làm nửa ngày + xin nghỉ phép nửa ngày

**Mô tả:**
Nhân viên làm buổi sáng (8:00 – 12:00), buổi chiều xin nghỉ phép và đã được HR duyệt.

**Ứng dụng xử lý như thế nào?**
- Hệ thống cộng: **0.5 công thực tế** (buổi sáng có quẹt thẻ) **+ 0.5 công phép** (đơn phép đã duyệt).
- Kết quả = **1 công đầy đủ**.

**Kết quả hiển thị:** `x/P` — Hiển thị nửa công + nửa phép để dễ nhận biết.

---

### 📌 Tình huống 8: Nhân viên đi công tác, không chấm công tại văn phòng

**Mô tả:**
Nhân viên đi công tác từ ngày 10 – 12/03. Có Đơn Công Tác được duyệt. Trong 3 ngày đó không có lượt quẹt thẻ.

**Ứng dụng xử lý như thế nào?**
- Hệ thống tra cứu đơn công tác đã duyệt.
- Tự động bổ sung công cho 3 ngày đó theo đơn.

**Kết quả hiển thị:** `C` (Công tác) — màu xanh dương, thay cho `x` không đáng có.

> ⚙️ *Cần bộ phận nghiệp vụ cấu hình liên kết Đơn Công Tác với Hệ thống Chấm công.*

---

### 📌 Tình huống 9: Làm thêm giờ (OT) nhưng không có Đơn OT

**Mô tả:**
Ca kết thúc lúc 17:00. Nhân viên về lúc 20:00. Dư 3 tiếng.

**Ứng dụng xử lý như thế nào?**
- Hệ thống chỉ tính đến 17:00 (1 công chuẩn).
- 3 tiếng dư **không được tính là OT** trừ khi có **Đơn OT được HR/Quản lý duyệt trước**.
- Nếu có Đơn OT duyệt → hệ thống cộng thêm phần OT vào bảng lương theo hệ số cấu hình.

**Kết quả hiển thị:** `1` (đủ 1 công chuẩn). Phần OT hiển thị riêng trong bảng tổng hợp nếu được duyệt.

---

## ❓ Câu hỏi thường gặp

**Hỏi: Nhân viên quên quẹt thẻ thì phải làm gì?**
> Vào App → Tab "Lịch công" → Nhấn vào ô ngày bị `x` → Nộp Đơn Giải Trình. HR sẽ xem xét và điều chỉnh.

**Hỏi: Ký hiệu trên lịch không đúng với thực tế thì phải làm gì?**
> Báo lại cho HR để kiểm tra cấu hình ca làm việc hoặc dữ liệu chấm công trên thiết bị.

**Hỏi: Nếu thiết bị chấm công bị lỗi, không ghi nhận được thì sao?**
> HR có thể nhập thủ công giờ chấm công và xử lý đơn giải trình. Hệ thống sẽ tính lại tự động.

**Hỏi: Làm thêm ngoài giờ mà không có đơn thì có được tính không?**
> Không. Chính sách bảo vệ cả nhân viên và công ty: OT chỉ được tính khi có văn bản (đơn) được duyệt hợp lệ.

---

*Tài liệu được soạn thảo bởi Team Phát triển HRM Mobile — Cập nhật: 11/03/2026*
