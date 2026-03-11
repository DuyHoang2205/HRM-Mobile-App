# Hướng Dẫn Nghiệm Thu (UAT) & Kịch Bản Kiểm Thử Chấm Công
***Tài liệu dành cho Business Analyst (BA) & Tester hướng dẫn Khách Hàng nghiệm thu***

Ngày cập nhật: 11/03/2026

---

## 🎯 1. Mục đích tài liệu
Tài liệu này giúp BA giải thích cho khách hàng hiểu rõ **cách Hệ thống Backend và Ứng dụng Di động (Mobile App) phối hợp xử lý 9 tình huống chấm công thực tế**.
Đồng thời, tài liệu cung cấp **các bước kiểm thử (test steps)** dễ hiểu nhất để khách hàng / Ban giám đốc có thể tự mình kiểm chứng kết quả chiếu trực tiếp trên Ứng dụng điện thoại.

> **💡 Nguyên lý cốt lõi cần giải thích cho khách hàng (Quan trọng):**
> Ứng dụng Mobile chỉ đóng vai trò **"Hiển thị thông minh"**. Toàn bộ các phép tính toán phức tạp (như: trừ giờ nghỉ trưa, tính phút đi trễ, gom gộp ca làm đêm qua ngày, tính phép, tính OT...) đều được xử lý tự động, bảo mật và chính xác tuyệt đối tại **Hệ thống Máy chủ (Database)** của công ty. Nhờ vậy, chấm dứt hoàn toàn khả năng người dùng gian lận hay can thiệp vào giờ làm.

---

## 📝 2. Điều kiện chuẩn bị trước khi Test cùng Khách hàng
1. **Mạng hoạt động:** Mobile App và Backend Server phải kết nối thông suốt với Database.
2. **Kịch bản dữ liệu:** Do chúng ta không thể "ngồi chờ" thời gian thực trôi qua để test quét thẻ, BA hoặc Tester cần phối hợp với IT để **giả lập (Insert SQL)** các dữ liệu quẹt thẻ (Check-in/Check-out) vào hệ thống cho từng kịch bản cụ thể. Đi kèm với lệnh Insert là chọn đúng thông tin ca làm việc.
3. **Thao tác trên App:** Sau khi IT tạo xong dữ liệu giả rồi, khách hàng sẽ mở ứng dụng HRM Mobile -> Vào mục **"Chấm công"** -> Chọn **"Công tháng"** để quan sát màu sắc trên lịch và **chạm vào từng ngày** để đọc các câu phân tích giải thích tự động.

---

## 🧪 3. Các kịch bản kiểm thử (Test Cases)

Dưới đây là 9 kịch bản kiểm thử tương ứng với 9 nhóm nghiệp vụ chính. 
*(IT sẽ chạy lệnh SQL mô phỏng ở dưới DB, Khách hàng cầm điện thoại để kiểm chứng UI).*

### Kịch bản 1: Nhân viên đi trễ / Về sớm
*   **Mục đích:** Kiểm tra việc hệ thống tự nhận diện và tính toán chính xác số phút đi trễ hoặc về sớm so với cấu hình Ca mà không cần ai dò tay.
*   **Thao tác giả lập:** IT tạo log Check-in lúc `09:20` (trễ) và Check-out lúc `17:30` (cho ca 08:00 - 17:00).
*   **Kết quả Khách hàng thấy trên App:** 
    *   Bấm vào ngày đó, màn hình in ra rõ ràng các thông số: `Đi trễ (phút): 80`.
    *   App tự động hiển thị câu giải thích cực kỳ thân thiện: *"Có phát sinh đi trễ/về sớm, hệ thống sẽ áp dụng quy tắc trừ công theo cấu hình HR."*

### Kịch bản 2: Nhân viên làm không đủ số giờ tối thiểu của ca
*   **Mục đích:** App tự cảnh báo khi nhân viên làm dưới số giờ bắt buộc để được tính là 1 ngày công.
*   **Thao tác giả lập:** Tạo log Check-in lúc `09:00` và Check-out lúc `11:00` (chỉ làm 2 tiếng).
*   **Kết quả Khách hàng thấy trên App:** 
    *   Ngày công bị đổi màu Vàng (Ký hiệu `x/P` hoặc `x` cảnh báo lỗi).
    *   Giờ làm thực tế là `2.00` tiếng, nhỏ hơn Giờ yêu cầu quy định (VD: `8.00`).

### Kịch bản 3: Nhân viên chấm công (quẹt thẻ) lặp đi lặp lại nhiều lần
*   **Mục đích:** Chứng minh thiết bị / hệ thống đủ thông minh để không tính sai công do thiết bị nhảy đúp, hoặc nhân sự quét lộn xộn.
*   **Thao tác giả lập:** Tạo 4 lần quẹt thẻ rung tung trong ngày: `08:10`, `10:30`, `13:10`, `18:05`.
*   **Kết quả Khách hàng thấy trên App:** 
    *   Dù có 4 chục dòng log thì App cũng tự động bóc tách gọn gàng: `Vào đầu tiên: 08:10`, `Ra cuối cùng: 18:05`. 
    *   Ngày công tính xanh (`1`) bình thường.

### Kịch bản 4: Tự động trừ rỗng thời gian nghỉ giữa ca (nghỉ trưa)
*   **Mục đích:** Đảm bảo hệ thống không gian lận chi phí giờ làm của cty, thời gian nghỉ (từ `12h00` - `13h00`) phải bị trừ đi tự động.
*   **Điều kiện ca:** Ca làm việc phải được HR cài đặt có khung giờ nghỉ (Break time).
*   **Kết quả Khách hàng thấy trên App:** 
    *   App hiển thị minh bạch thông số: `Trừ nghỉ giữa ca (phút): 60`.
    *   Kèm câu giải thích cho nhân sự an tâm: *"Đã tự động trừ thời gian nghỉ giữa ca."*

### Kịch bản 5: Quên Check-out (Hoặc Check-in)
*   **Mục đích:** Phát hiện tức thì khuyết mốc thời gian để nhắc nhân viên (chống mất công oan) hoặc chặn trục lợi.
*   **Thao tác giả lập:** Chỉ tạo 1 mốc Check-in lúc `08:00`, cố tình bỏ rỗng mốc Check-out chiều đi về.
*   **Kết quả Khách hàng thấy trên App:** 
    *   Ngày trên lịch nháy màu Vàng khẩn, ký hiệu `x`.
    *   Trong tab giải thích nhắc khéo thẳng thắn: *"Thiếu log Check-out. Cần đơn giải trình để tính lại công."*

### Kịch bản 6: Làm ca đêm vắt qua hai ngày
*   **Mục đích:** Đảm bảo hệ thống gom trọn vẹn ca đêm thành 1 dòng mạch lạc, không "bẻ đôi" ca ra khiến rớt công rớt lương của nhân sự trực ca.
*   **Thao tác giả lập:** Quẹt thẻ Vào lúc `22:00 hôm nay` và Ra lúc `06:05 sáng mai`.
*   **Kết quả Khách hàng thấy trên App:** 
    *   Toàn bộ ca làm kéo dài 8 tiếng được ghi nhận gộp chung vào ngày hôm nay. Ngày mai được để trống hoàn toàn hợp lệ.
    *   App hiển thị câu giải thích rất thông minh: *"Ca qua ngày đã được gom thành một ngày công."*

### Kịch bản 7: Nửa ngày đi làm + Nửa ngày xin nghỉ phép
*   **Mục đích:** Xử lý triệt để rắc rối về hiển thị ca gãy: Sáng làm việc bình thường, chiều xin về (có đơn từ đàng hoàng).
*   **Thao tác giả lập:** Tạo 1 log quẹt thẻ buổi sáng + 1 Đơn xin nghỉ phép `0.5 ngày` buổi chiều (Đã duyệt bằng quyền Manage).
*   **Kết quả Khách hàng thấy trên App:**
    *   Ngày chuyển sang ký hiệu `x/P` màu Vàng (Vừa có số lượng làm việc, vừa có phép xía vào).
    *   App hiển thị giải thích: *"Kết hợp nửa ngày công thực tế và nửa ngày nghỉ phép."* Không ai bị hiểu lầm.

### Kịch bản 8: Nhân viên đi công tác xa (có đơn duyệt)
*   **Mục đích:** Xóa bỏ nghi ngờ dính lỗi "Nghỉ không phép" cho đội Sales/Thị trường nhờ sức mạnh Cổng kết nối Đơn từ.
*   **Thao tác giả lập:** Tạo Đơn Công tác đã duyệt, ngày hôm đó cố tình trống sạch log quẹt thẻ máy chấm công.
*   **Kết quả Khách hàng thấy trên App:** 
    *   Lịch công uyển chuyển đổi hẳn sang ký hiệu `C` mang một màu Xanh dương mát mắt.
    *   App hiển thị giải thích: *"Ngày công tác đã được duyệt."*

### Kịch bản 9: Xử lý Tăng ca (Overtime - OT) chặt chẽ
*   **Mục đích:** Chứng minh tính minh bạch trong đãi ngộ: Làm trễ là việc của anh, nhưng phải "Có Đơn & Có Duyệt" thì công ty mới tính tiền OT!
*   **Nửa kịch bản 9A (Cố tình ở lại trễ không xin phép):** Nhân viên làm lố 2 tiếng, nhưng không viết Đơn xin OT.
    *   *Kết quả trên App hiển thị:* Tách số rạch ròi. `OT đủ điều kiện: 120 phút` (App báo là có nán lại nha). `OT đã duyệt: 0 phút`. 
    *   *Câu giải thích chặn đầu báo:* *"Có thời gian ngoài giờ nhưng chưa có đơn OT duyệt nên chưa tính OT."*
*   **Nửa kịch bản 9B (Đàng hoàng có đơn xin OT đã duyệt):** Có đơn xin OT 2 tiếng được Manager ký duyệt qua hệ thống Zensuite.
    *   *Kết quả trên App hiển thị:* Nhảy số `OT đã duyệt: 120 phút`. 
    *   *Câu giải thích:* *"Đã có OT được duyệt và được cộng theo chính sách."*

---

## ✅ 4. Checklist Ký Nhận Nghiệm Thu Dành Cho Khách Hàng (Sign-off)

Khi UAT (Demo/Test), BA cần lần lượt xác nhận cùng Khách hàng và tick chọn vào 4 chỉ mục cực xịn này:

- [ ] **1. Mắt nhìn - UI/UX:** Lịch công được tô màu cực kỳ trực quan, lướt 3 giây là biết nhân viên khỏe hay đang dính phốt. (Xanh - Đủ công, Vàng - Có lỗi/Khuyết, Đỏ - Xin nghỉ, Xanh dương - Đi công tác).
- [ ] **2. Thấu đáo - Số Liệu:** Popup khi chạm vào mỗi ngày chứa đầy đủ 100% các dữ liệu tinh tế nhất mà một kế toán nhân sự cần (Giờ In/Out, Tính trễ/sớm/OT/Trừ nghỉ).
- [ ] **3. Thông thái - "Giải Thích Tự Động":** App có cơ chế AI bằng Rule cực kỳ thông minh. Thấy nhân sự sai ở đâu, có đơn phép chỗ nào là tự động "in ra câu giải thích bằng tiếng việt có dấu" để nhân sự đỡ phải cãi nhau với HR.
- [ ] **4. Bảo Mật - Cấu trúc chống Hack:** Khách hàng hiểu rõ cơ chế: Mobile App không tính công ảo trên điện thoại. Nó hiển thị trung thực dữ liệu đã qua nhào nặn bảo vệ 2 lớp chuẩn mực từ Máy chủ Server, chống vạn khả năng nhân sự gian lận qua ứng dụng.
