# Chatbot Backend Test Guide

## 1. Tạo schema và bảng chatbot trên MSSQL

Chạy file:

- [chatbot_schema_mssql.sql](/Users/baoduy/Documents/work/HRM-Mobile-App/hrm_mobile_app/docs/AI/chatbot_schema_mssql.sql)

Sau khi chạy, verify:

```sql
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'chatbot'
ORDER BY t.name;
```

Kỳ vọng:

- `bot_logs`
- `chat_messages`
- `chat_sessions`

## 2. Lấy token đăng nhập

```bash
curl 'http://erp.vietgoat.com:854/erp/Users/weblogin' \
  -X POST \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --data-raw '{"No_":"admin","Password":"111","site":"KIA"}'
```

Lấy `accessToken` từ response rồi export:

```bash
export TOKEN='PASTE_ACCESS_TOKEN_HERE'
```

## 3. Tạo session chatbot

```bash
curl -i 'http://erp.vietgoat.com:854/hrm/api/chatbot/sessions' \
  -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --insecure
```

Response mẫu:

```json
{
  "id": "session-uuid",
  "user_no": "admin",
  "employee_id": 8847,
  "state": "active"
}
```

Lưu `id` vào:

```bash
export CHAT_SESSION_ID='PASTE_SESSION_ID_HERE'
```

## 4. Gửi tin nhắn

```bash
curl -i 'http://erp.vietgoat.com:854/hrm/api/chatbot/messages' \
  -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --data-raw "{
    \"message_id\": \"msg-$(date +%s)-manual\",
    \"session_id\": \"$CHAT_SESSION_ID\",
    \"content\": \"Tôi muốn hỏi về chấm công tháng này\"
  }" \
  --insecure
```

## 5. Xem lịch sử hội thoại

```bash
curl -i "http://erp.vietgoat.com:854/hrm/api/chatbot/sessions/$CHAT_SESSION_ID/messages?limit=50&offset=0" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/json' \
  --insecure
```

## 6. Chuyển hội thoại cho HR

```bash
curl -i "http://erp.vietgoat.com:854/hrm/api/chatbot/sessions/$CHAT_SESSION_ID/escalate" \
  -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --data-raw '{"reason":"Người dùng cần HR hỗ trợ trực tiếp"}' \
  --insecure
```

## 7. Xem data vừa tạo trong SQL

```sql
SELECT TOP 20 *
FROM chatbot.chat_sessions
ORDER BY updated_at DESC;

SELECT TOP 50 *
FROM chatbot.chat_messages
ORDER BY created_at DESC;

SELECT TOP 50 *
FROM chatbot.bot_logs
ORDER BY created_at DESC;
```

## Notes

- Route backend hiện tại:
  - `POST /hrm/api/chatbot/sessions`
  - `GET /hrm/api/chatbot/sessions`
  - `GET /hrm/api/chatbot/sessions/:sessionId/messages`
  - `POST /hrm/api/chatbot/messages`
  - `POST /hrm/api/chatbot/sessions/:sessionId/escalate`
- `webhook.service.ts` hiện đang là fallback rule-based.
- Bước nối n8n/Dify thật sẽ thay thế phần reply trong backend mà không cần đổi contract mobile.
