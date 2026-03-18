# 🚩 BÁO CÁO BÀN GIAO: Dự án AI Chatbot ERP/HRM

## 1. Ngữ cảnh dự án (Context)
- **Mục tiêu:** Xây dựng Chatbot AI cho nhân viên tra cứu thông tin ERP nội bộ (chấm công, nghỉ phép, lương, quy chế...).
- **Chiến lược:** Build **THÊM** module `chatbot` vào backend NestJS HRM hiện có (không xóa module cũ). 
- **Tech Stack:** NestJS (MSSQL/TypeORM) + n8n + Dify + Flutter.
- **Dữ liệu:** Tra cứu trực tiếp từ các bảng HRM (`AttendanceTime`, `OnLeaveFile`, `OnLeaveFileLine`, `User`).

## 2. Những gì ĐÃ HOÀN THÀNH ✅
- [x] **Phân tích:** Đã đọc toàn bộ tài liệu trong `/docs/AI/` và cấu trúc backend `real_BE`.
- [x] **Kế hoạch:** Đã tạo kế hoạch chi tiết tại: `chatbot_ai_implementation_plan.md`.
- [x] **Thiết kế Database:** Đã thống nhất schema `chatbot` trên MSSQL với các bảng `chat_sessions`, `chat_messages`, `bot_logs`.
- [x] **Code Part 1 (Entities):** Đã tạo xong 3 entities tại `src/module/chatbot/entities/`:
    - `ChatSession`: Quản lý phiên chat, trạng thái (active/escalated).
    - `ChatMessage`: Lưu tin nhắn, hỗ trợ deduplication bằng `messageId`.
    - `BotLog`: Ghi log các lỗi n8n timeout/AI fallback.
- [x] **Code Part 2 (DTOs):** Đã tạo xong các DTOs tại `src/module/chatbot/dto/`:
    - `SendMessageDto`: Nhận tin nhắn từ Flutter kèm idempotency key.
    - `ChatHistoryQueryDto`: Phân trang lịch sử chat.

## 3. Cấu trúc thư mục hiện tại (Backend)
```
src/module/chatbot/
├── chatbot.module.ts (Chưa tạo)
├── chatbot.controller.ts (Chưa tạo)
├── chatbot.service.ts (Chưa tạo)
├── webhook.service.ts (Chưa tạo)
├── dto/
│   ├── send-message.dto.ts ✅
│   └── chat-history.dto.ts ✅
└── entities/
    ├── chat-session.entity.ts ✅
    ├── chat-message.entity.ts ✅
    └── bot-log.entity.ts ✅
```

## 4. Nhiệm vụ cho AI TIẾP THEO (Next Steps) 🚀

### A. Hoàn thiện NestJS Module (Ưu tiên 1)
1. **Tạo `ChatbotService`**: 
    - Logic tìm/tạo session.
    - Logic kiểm tra trùng lặp tin nhắn (`messageId`).
    - Query dữ liệu context (thông tin nhân viên) để gửi kèm sang n8n.
2. **Tạo `WebhookService`**: 
    - Dùng `Axios` để gọi sang n8n với `timeout: 5000`.
    - Xử lý lỗi/timeout để trả về message fallback lịch sự ("Hệ thống bận...").
3. **Tạo `ChatbotController`**: 
    - Endpoint `POST /api/chatbot/messages`.
    - Endpoint `GET /api/chatbot/sessions/:id/messages`.
4. **Đăng ký module**: Thêm `ChatbotModule` vào `app.module.ts` và cấu trúc `RouterModule`.

### B. Setup Infra & SQL (Ưu tiên 2)
1. Chạy SQL Script để tạo schema `chatbot` và 3 bảng tương ứng trong MSSQL local.
2. Cài đặt n8n (Docker) và tạo workflow cơ bản nhận webhook từ NestJS.
3. Cấu hình Dify (RAG) với tài liệu nội bộ công ty.

### C. Flutter Integration (Ưu tiên 3)
1. Tạo UI ChatPage và tích hợp ChatBloc để gọi các API mới.

---
**Lưu ý cho AI mới:** Tuyệt đối không xóa các module HRM hiện có. Chatbot phải được build song song và tương tác với dữ liệu của các module đó.
