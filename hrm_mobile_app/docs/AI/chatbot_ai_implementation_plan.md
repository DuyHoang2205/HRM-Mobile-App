# 🤖 Kế hoạch Triển khai: AI Chatbot ERP/HRM Nội bộ

**Mục tiêu thực sự:** Chatbot giúp nhân viên tự phục vụ: hỏi chấm công, nghỉ phép, bảng lương...  
**Chiến lược:** Build THÊM module `chatbot` vào backend HRM hiện có – **không xóa gì cả**  
**Proof of concept:** Demo thuyết phục sếp → sau đó mở rộng sang shop quần áo  
**Stack:** Flutter App (hiện có) + NestJS HRM Backend + n8n + Dify  

---

## 🔍 Phân tích Backend Hiện có

### Các entity/module quan trọng có thể dùng cho chatbot:
| Entity/Table | Module | Chatbot dùng để |
|---|---|---|
| `User` (rowPointer, no_, name) | `user` | Xác định nhân viên đang chat |
| `UsersFlutter` (Username, Password) | `dev` | Auth cho Flutter app (đã có luồng này!) |
| `AttendanceTime` (attendCode, authDate, authTime) | `attendance` | Tra cứu chấm công |
| `OnLeaveFile` (employeeID, dayEarn, surplus) | `onleavefile` | Số ngày phép còn lại |
| `OnLeaveFileLine` (fromDate, toDate, status, qty) | `onleaveline` | Lịch sử đơn nghỉ phép |

### Auth hiện tại:
- Bảng `UsersFlutter` đã có: `Username`, `Password` – **tái dùng luôn**
- JWT RS256 đã setup, `JwtAuthGuard` đã có
- DB connections: `hrmDatasource` (mainDB) + `configMDM` (MDM DB)

---

## 🗺️ Kiến trúc Tổng thể

```
[Flutter Mobile App]
      │  JWT Auth
      ▼
[NestJS HRM Backend - Port 3004]
      ├── ... (200 module HRM cũ, giữ nguyên)
      └── /api/chatbot/ ← MODULE MỚI
              │
              │ 5s timeout + fallback
              ▼
         [n8n Orchestrator - Port 5678]
              │
              ├── Query HRM DB → Attendance/Leave data
              │
              └── → [Dify AI + RAG]
                       │
                       └── Trả lời bằng tiếng Việt
```

---

## 🗄️ Database Design (Chỉ THÊM, không sửa)

### Schema mới: `chatbot` (trong cùng MSSQL DB)
> ⚠️ Chỉ CREATE bảng mới. Không DROP, không ALTER bảng nào của ERP.

#### `chatbot.chat_sessions`
```sql
CREATE SCHEMA chatbot;

CREATE TABLE chatbot.chat_sessions (
  id            UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  user_no       NVARCHAR(50)    NOT NULL,   -- ref User.no_ (không FK cứng để an toàn)
  employee_id   INT             NULL,       -- ref Employee nếu map được
  state         NVARCHAR(20)    NOT NULL DEFAULT 'active',
  -- 'active' | 'escalated' | 'closed'
  context       NVARCHAR(MAX)   NULL,       -- JSON: last N messages cho n8n
  created_at    DATETIME2       DEFAULT GETDATE(),
  updated_at    DATETIME2       DEFAULT GETDATE()
);
CREATE INDEX idx_chat_sessions_user ON chatbot.chat_sessions(user_no);
```

#### `chatbot.chat_messages`
```sql
CREATE TABLE chatbot.chat_messages (
  id               UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  message_id       NVARCHAR(100)   NOT NULL UNIQUE,  -- idempotency key từ client
  session_id       UNIQUEIDENTIFIER NOT NULL,
  user_no          NVARCHAR(50)    NOT NULL,
  role             NVARCHAR(20)    NOT NULL,  -- 'user' | 'assistant' | 'system'
  content          NVARCHAR(MAX)   NOT NULL,
  intent           NVARCHAR(100)   NULL,      -- 'check_attendance' | 'check_leave' | etc
  confidence_score FLOAT           NULL,
  is_fallback      BIT             DEFAULT 0,
  created_at       DATETIME2       DEFAULT GETDATE()
);
CREATE INDEX idx_chat_messages_session ON chatbot.chat_messages(session_id);
CREATE INDEX idx_chat_messages_msg_id  ON chatbot.chat_messages(message_id);
```

#### `chatbot.bot_logs` (ghi lỗi để debug)
```sql
CREATE TABLE chatbot.bot_logs (
  id           UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  session_id   UNIQUEIDENTIFIER NULL,
  message_id   NVARCHAR(100)   NULL,
  event_type   NVARCHAR(50)    NOT NULL,  -- 'n8n_timeout' | 'dify_error' | 'fallback_sent'
  payload      NVARCHAR(MAX)   NULL,
  error_detail NVARCHAR(MAX)   NULL,
  created_at   DATETIME2       DEFAULT GETDATE()
);
```

---

## 📁 Cấu trúc Code Mới (Thêm vào src/module/)

```
src/module/
├── ... (200 module cũ, giữ nguyên)
└── chatbot/                          ← TẠO MỚI
    ├── chatbot.module.ts
    ├── chatbot.controller.ts         # POST/GET endpoints
    ├── chatbot.service.ts            # Business logic + query HRM data
    ├── webhook.service.ts            # Gọi n8n + xử lý timeout/fallback
    ├── dto/
    │   ├── send-message.dto.ts
    │   └── chat-history.dto.ts
    └── entities/
        ├── chat-session.entity.ts
        ├── chat-message.entity.ts
        └── bot-log.entity.ts
```

---

## 🔌 API Endpoints Mới

| Method | Path | Auth | Mô tả |
|---|---|---|---|
| `POST` | `/api/chatbot/messages` | JWT | Gửi tin nhắn → trả lời AI |
| `GET` | `/api/chatbot/sessions/:sessionId/messages` | JWT | Lịch sử chat |
| `POST` | `/api/chatbot/sessions` | JWT | Tạo session mới |
| `GET` | `/api/chatbot/sessions` | JWT | Danh sách session của user |

---

## 💬 Intents mà Chatbot ERP sẽ hiểu

| Intent | Ví dụ câu hỏi | n8n sẽ làm gì |
|---|---|---|
| `check_attendance` | "Tôi chưa chấm công hôm nay chưa?" | Query `AttendanceTime` theo employeeID + ngày |
| `check_leave_balance` | "Tôi còn bao nhiêu ngày phép?" | Query `OnLeaveFile` theo employeeID + year |
| `check_leave_history` | "Đơn nghỉ phép của tôi đang ở trạng thái gì?" | Query `OnLeaveFileLine` theo employeeID |
| `submit_leave_request` | "Tôi muốn xin nghỉ ngày mai" | Hướng dẫn user làm đúng trên app |
| `check_salary` | "Lương tháng này của tôi là bao nhiêu?" | Query bảng lương (nếu được phép) |
| `general_question` | "Quy định nghỉ phép như thế nào?" | Dify RAG → tài liệu nội bộ |

---

## 🔧 Giai đoạn Thực hiện

### Giai đoạn 1: Setup DB + Module skeleton (1-2 ngày)
- [ ] Chạy SQL tạo schema `chatbot` và 3 bảng
- [ ] Tạo `chatbot.module.ts`, entities, DTOs
- [ ] Đăng ký `ChatbotModule` vào `app.module.ts` 
- [ ] Thêm route `/api/chatbot` vào `RouterModule`
- [ ] Verify build không lỗi: `yarn start:dev`

### Giai đoạn 2: Core API (2-3 ngày)
- [ ] `POST /api/chatbot/messages`:
  - Nhận `{ message_id, content, session_id? }`
  - Deduplication check (`message_id` unique)
  - Lưu message (role='user')
  - Gọi `ChatbotService.resolveUserContext()` → lấy thông tin nhân viên từ DB HRM
  - Gọi `WebhookService.sendToN8n()` với timeout 5s
  - Lưu reply (role='assistant') 
  - Trả về response
- [ ] `GET /api/chatbot/sessions/:sessionId/messages` 
- [ ] Rate limiting: thêm `@nestjs/throttler` vào `ChatbotModule`

### Giai đoạn 3: n8n Workflow (2-3 ngày)
- [ ] Cài n8n local (Docker)
- [ ] Tạo workflow: Webhook → Load HRM context → Intent detect → Dify/Query DB → Response
- [ ] Node query HRM DB: attendance, leave balance
- [ ] Tích hợp Dify cho câu hỏi chính sách

### Giai đoạn 4: Flutter ChatPage (2-3 ngày)
- [ ] Tạo `ChatPage` với bubble UI
- [ ] `ChatBloc` + `ChatRepository`
- [ ] Offline queue (Hive) cho tin nhắn chưa gửi
- [ ] Auto-sync khi có mạng

---

## 🔗 Tích hợp vào `app.module.ts` Hiện có

```typescript
// Chỉ thêm 2 dòng, không xóa gì:

// 1. Import ở đầu file:
import { ChatbotModule } from './module/chatbot/chatbot.module';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

// 2. Trong @Module({ imports: [...] }):
ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
ChatbotModule,

// 3. Trong RouterModule.register([...]):
{ path: 'chatbot', module: ChatbotModule },

// 4. Trong providers: (nếu muốn global throttle):
{ provide: APP_GUARD, useClass: ThrottlerGuard },
```

---

## 📡 n8n Workflow cho HRM Context

### Flow khi nhân viên hỏi "Tôi còn bao nhiêu ngày phép?":
```
1. NestJS gọi n8n webhook với:
   {
     user_no: "EMP001",
     employee_id: 123,
     message: "Tôi còn bao nhiêu ngày phép?",
     session_id: "...",
     history: [last 5 messages]
   }

2. n8n: Intent Classification
   → Detect "check_leave_balance"

3. n8n: Query HRM DB
   SELECT dayEarn, surplus, pendingPermit, year
   FROM OnLeaveFile
   WHERE employeeID = 123 AND year = 2026

4. n8n: Gọi Dify với context:
   "Nhân viên EMP001 hỏi về ngày phép.
    Data từ DB: còn 5 ngày phép, đang chờ duyệt 2 ngày.
    Hãy trả lời lịch sự bằng tiếng Việt."

5. n8n: POST response về NestJS callback URL

6. NestJS: Lưu reply + trả về Flutter
```

---

## 🎯 Demo Data để Thuyết phục Sếp

### Seed data cần tạo cho test local:
```sql
-- Tạo 1 user test trong bảng đã có sẵn (không tạo bảng mới)
-- Dùng bất kỳ user nào đang có trong DB HRM local

-- Seed chat history demo
INSERT INTO chatbot.chat_sessions (id, user_no, employee_id, state)
VALUES (NEWID(), 'EMP001', 1, 'active');
```

### Kịch bản demo (5 phút):
1. **"Tôi chưa chấm công hôm nay chưa?"** → Bot tra DB → "Bạn đã chấm công lúc 8:05 sáng tại Cổng A"
2. **"Tôi còn bao nhiêu ngày phép?"** → Bot tra DB → "Bạn còn 5 ngày phép năm nay"
3. **"Đơn xin nghỉ ngày 20/3 của tôi đã được duyệt chưa?"** → Bot tra DB → Trả status cụ thể
4. **"Quy định tăng ca của công ty như thế nào?"** → Dify RAG → Trả lời từ tài liệu nội bộ

---

## ⚠️ Lưu ý Quan trọng

> [!IMPORTANT]
> **Không cần migrate data.** DB HRM local đã có data thật. Chỉ cần thêm schema `chatbot` là đủ.

> [!TIP]
> **Auth tái dùng:** `UsersFlutter` table đã có. Dùng luôn `JwtAuthGuard` đang hoạt động trong app Flutter. Không cần tạo auth mới.

> [!WARNING]
> **n8n query DB HRM:** Cấp quyền READ-ONLY cho n8n user vào các bảng cần thiết. Không cho n8n ghi vào bảng ERP.

> [!CAUTION]
> **Dify RAG content:** Upload tài liệu nội bộ (quy chế, nội quy, FAQ nhân sự) vào Dify KB. Không hardcode rules trong code.

---

## 📦 Packages Cần Thêm

```bash
# Trong real_BE/VSCode-darwin-universal.zip/
yarn add @nestjs/throttler @nestjs/axios axios
# Các package khác (mssql, typeorm, jwt) đã có sẵn
```

---

## 📅 Timeline Ước tính (1 Dev)

| Giai đoạn | Thời gian | Kết quả |
|---|---|---|
| DB + Module skeleton | 1-2 ngày | CRUD chatbot hoạt động |
| Core API + n8n basic | 3-4 ngày | Bot trả lời được |
| Dify + RAG | 2-3 ngày | Bot hiểu chính sách |
| Flutter ChatPage | 2-3 ngày | Mobile app demo |
| **Demo cho sếp** | **~10 ngày** | **Proof of Concept** ✅ |
