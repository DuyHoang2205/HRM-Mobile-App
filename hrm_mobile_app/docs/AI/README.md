# 🤖 Chatbot CSKH - System Architecture & Sequence Diagram

**Complete microservices architecture documentation** for an AI-powered customer support chatbot for a clothing shop.

---

## 📁 Files Included

### 1. **chatbot_cskh_viewer.html** ⭐ (START HERE)
- **Interactive HTML viewer** with tabbed interface
- 4 main tabs:
  - 📊 **Architecture Overview** - Full system diagram
  - 🔄 **Sequence Diagram** - Request flow step-by-step
  - ⏱️ **Timing Analysis** - Latency breakdown & SLA targets
  - ⚠️ **Edge Cases** - Comprehensive error handling
- **Download link:** Open this file in any browser (no internet needed)
- **Best for:** Quick overview, presentations, team discussions

### 2. **chatbot_architecture_diagram.svg**
- **High-resolution SVG diagram** (1600×2400px)
- Shows all 7 layers:
  1. Flutter Frontend (Mobile App)
  2. NestJS Backend Gateway
  3. n8n Orchestrator
  4. Dify (AI + RAG)
  5. PostgreSQL Integration
  6. Human Handoff
  7. Observability & Monitoring
- Color-coded components (Blue=Flutter, Red=NestJS, Orange=n8n, Purple=Dify, Gray=PostgreSQL, etc.)
- Includes all edge cases and error paths
- **Best for:** Printing, detailed technical review, API documentation

### 3. **chatbot_sequence_diagram.mmd**
- **Mermaid syntax** - Standardized flowchart format
- Shows complete request lifecycle:
  - User input → Flutter validation → Network check
  - Online/Offline branches
  - NestJS authentication → Rate limiting → Message persistence
  - n8n context loading → Token truncation → Intent classification
  - Dify API call → RAG queries → LLM inference
  - Response routing → Database persistence
  - Escalation paths for human handoff
- **Best for:** GitHub integration, documentation wikis, version control
- **Usage:**
  ```bash
  # View in VSCode with Mermaid extension
  # Or online at: https://mermaid.live/
  # Paste content and view
  ```

---

## 🏗️ Architecture Overview

### Tech Stack
- **Frontend:** Flutter (Mobile App) with offline support (SQLite/Hive)
- **Backend Gateway:** NestJS (Node.js) with JWT auth, rate limiting
- **Workflow Orchestrator:** n8n with context management & token counting
- **AI Brain:** Dify with RAG knowledge base & LLM inference
- **Database:** PostgreSQL (message history, conversations, orders, inventory)
- **Notifications:** Slack/Telegram for agent alerts

### 7 System Layers

#### 1️⃣ Flutter Frontend
- ✓ User input validation
- ✓ Client-side file type checking (no Voice/Video/Exe)
- ⚠️ Offline mode: Save to SQLite → Queue for retry
- ✓ Message state tracking (pending → sent → delivered)
- ✓ JWT authentication with token refresh
- ⏱️ ~70ms per operation

#### 2️⃣ NestJS Backend Gateway
- ✓ JWT token validation
- ⚠️ Rate limiting: 100 req/min per user (returns 429 if exceeded)
- ✓ Message persistence to PostgreSQL
- ✓ Webhook formatting & signing
- ✓ Request deduplication (idempotent webhook retries)
- ⏱️ ~8-20ms per operation

#### 3️⃣ n8n Orchestrator
- ✓ Webhook parsing & validation
- ✓ Load conversation context from DB
- ⚠️ Token counting & truncation (>4K tokens)
- ✓ Intent classification (simple heuristic or Dify)
- ✓ Error handling & escalation routing
- ⏱️ ~40-55ms per operation

#### 4️⃣ Dify (AI + RAG)
- ✓ **Happy Path 1:** Size/Product inquiries → Query RAG KB → Accurate response
- ⚠️ **Edge Case:** Data contradiction → Ask for clarification
- ⚠️ **Edge Case:** Context switching → Detect new intent → Reset flow
- ❌ **Edge Case:** Out-of-scope questions → Polite refusal
- ⚠️ **Edge Case:** Low confidence (<60%) → Escalate to human
- **Happy Path 2:** Query order status → Return from DB
- ⏱️ ~1.5-3s per LLM call (bottleneck)

#### 5️⃣ PostgreSQL Integration
- ✓ Message history table (user_id, content, timestamp, metadata)
- ✓ Conversation sessions (session_id, context, state)
- ✓ Order tracking (order_id, status, items, tracking)
- ✓ Inventory management (product_id, stock, alternatives)
- ⚠️ **Edge Case:** Out of stock → Suggest alternatives
- ⏱️ ~15-30ms per query

#### 6️⃣ Human Handoff
- ⚠️ **Trigger:** Dify confidence < 60%, API timeout, user requests agent
- ✓ Close AI loop (mark conversation as escalated)
- ✓ Send notification to Slack/Telegram
- ✓ Create support ticket
- ✓ Agent joins live chat session
- ✓ Message routing (customer → agent, not AI)
- ⏱️ ~200-500ms for notification

#### 7️⃣ Observability & Monitoring
- 📊 **Metrics:** Latency, error rate, intent distribution, escalation rate
- 📝 **Logging:** Structured logs (JSON) → ELK Stack
- 🔐 **Security:** PII masking, JWT refresh, encryption at rest
- 🚨 **Alerting:** SLA violations, error spikes, timeout alerts
- ⏱️ Real-time monitoring dashboard

---

## ⏱️ Timing Analysis

### Happy Path: Product Inquiry
```
User Input (70ms)
  ↓
Flutter → NestJS (150ms network)
  ↓
NestJS: Auth + Rate Limit + Save (26ms)
  ↓
NestJS → n8n (75ms network)
  ↓
n8n: Parse + Load Context + Token Check (55ms)
  ↓
n8n → Dify (Query RAG + LLM Inference) ⭐ 1500-3000ms
  ↓
n8n → NestJS → Flutter (150ms network)
  ↓
Flutter: Update UI (15ms)
─────────────────────────────────────────
TOTAL: 2.0-2.5 seconds (p50)
       2.5 seconds (p95)
       4.0 seconds (p99)
```

### Edge Cases Add Extra Latency

| Edge Case | Extra Time | Total | Notes |
|-----------|-----------|-------|-------|
| ⚠️ Token Truncation | +20ms | 2.0-2.5s | Compress context in n8n |
| ⚠️ Context Switch | +100ms | 2.1-2.6s | Detect + reset flow |
| ⚠️ Low Confidence | +200ms | 2.2-2.8s | Extra validation + escalate |
| ❌ API Timeout | +5000ms | 5.0+ seconds | Fallback sent immediately |
| ❌ Rate Limited | Instant | ~100ms | Rejected at NestJS |
| 🔄 Offline Mode | Queued | On reconnect | Auto-retry with backoff |

### SLA Targets
- **p50 (median):** < 2.0 seconds
- **p95:** < 2.5 seconds
- **p99:** < 4.0 seconds
- **Error Rate:** < 1%
- **Availability:** 99.5%

---

## ⚠️ Edge Cases & Error Handling

### 🔵 Flutter Frontend
- ❌ **Invalid File:** Block Voice/Video/Exe at client → Show error
- ⏳ **Offline Mode:** Save to SQLite → Queue with exponential backoff (1s → 2s → 4s → 8s)
- ✓ **Message States:** pending → sent → delivered → read
- ✓ **Network Recovery:** Auto-sync when online reconnects

### 🔴 NestJS Gateway
- ✓ **JWT Expired:** Request refresh token → Retry → If both fail: 401 Unauthorized
- 🚦 **Rate Limit:** 100 req/min → Return 429 Too Many Requests
- ✓ **Deduplication:** Same message_id twice → Idempotent, no duplicate
- ❌ **Database Failure:** Return 503 Service Unavailable
- 🔄 **Webhook Timeout:** Retry 3x → If fails: queue in DLQ → Manual replay

### 🟠 n8n Orchestrator
- ⚠️ **Context Window:** If > 4K tokens → Truncate old messages
- 🆔 **Missing Context:** Session not found → Create new context
- 🎯 **Ambiguous Intent:** Multiple intents detected → Ask clarification
- ⏱️ **Dify Timeout:** Set 5s limit → If exceeded: send fallback + escalate
- 🔐 **Webhook Validation:** Verify signature → If invalid: reject (400)

### 🟣 Dify (AI)
- 📊 **Contradictory Data:** "1m8 tall, 40kg weight" (unrealistic) → Ask to confirm
- 🔄 **Context Switch:** Was asking size → Suddenly asks about return → Detect → Reset flow
- 🚫 **Out-of-Scope:** Gold prices, politics → Polite refusal
- 📈 **Low Confidence:** Score < 60% → Escalate to human
- 🧠 **Hallucination Prevention:** If info not in RAG KB → Low score → Escalate

### 🐘 PostgreSQL & Integration
- 📦 **Out of Stock:** Product stock = 0 → Call Dify → Suggest alternatives
- 🔍 **Order Not Found:** No matching order_id → Ask user for more details
- 🔒 **Concurrent Updates:** Use versioning/locking → Ensure data consistency
- 🐢 **Slow Query:** Complex JOIN > 2s → Timeout → Escalate

### 👤 Human Handoff
- ⏳ **No Agents Available:** Queue customer → Show wait time
- 📴 **Agent Disconnect:** Detect drop → Re-queue automatically
- 📧 **Slack API Down:** Retry 3x → Send backup email to team
- 📋 **History Transfer:** Full chat history passed to agent → No duplicate questions

---

## 🔐 Security & Compliance

### Authentication & Authorization
- **JWT Tokens:** 15-minute expiry, refresh token rotation
- **Secure Storage:** HTTP-only cookies, secure flag
- **User Isolation:** Each user's messages scoped by user_id

### Data Protection
- **PII Masking:** Phone numbers, emails hashed in logs
- **Encryption at Rest:** PostgreSQL pgcrypto extension
- **Encryption in Transit:** HTTPS/TLS for all APIs
- **Audit Logging:** All user actions logged with timestamp & trace_id

### Rate Limiting & DDoS Protection
- **Per-User Throttling:** 100 requests/minute per authenticated user
- **Per-IP Rate Limiting:** Geo-blocking for suspicious IPs
- **Request Signing:** Webhook requests signed with HMAC-SHA256
- **Input Validation:** XSS/SQL injection prevention at NestJS

---

## 📊 Monitoring & Observability

### Metrics Collected
- **Latency:** p50, p95, p99 per layer
- **Error Rate:** By component & error type
- **Intent Distribution:** Size inquiry vs Order check vs Refusal
- **Escalation Rate & Reasons:** Low confidence, timeout, user request
- **Offline Sync Queue:** Length & retry success rate
- **CSAT Score:** Per conversation (customer satisfaction)

### Logging Strategy
- **Structured Logs:** JSON format with trace_id
- **Destination:** ELK Stack (Elasticsearch, Logstash, Kibana)
- **Retention:** 90 days (GDPR compliance)
- **PII Protection:** Automatic masking of sensitive fields

### Alerting Rules
- **p95 Latency > 2.5s:** Page oncall engineer
- **Error Rate > 1%:** Immediate alert
- **Timeout Rate > 5%:** Investigate Dify/n8n connection
- **Offline Queue Length > 10K:** Trigger investigation
- **Agent Queue Wait > 5 min:** Alert ops team

---

## 🚀 Deployment & Operations

### CI/CD Pipeline
- **Unit Tests:** Per-layer testing (Flutter, NestJS, n8n)
- **Integration Tests:** Full flow testing (Flutter → Dify)
- **Load Testing:** Simulate 1000 concurrent users
- **Canary Deployment:** 10% traffic → 50% → 100%
- **Rollback:** Automatic rollback if error rate spikes > 2%

### Database Management
- **Read Replicas:** PostgreSQL streaming replication
- **Backups:** Daily snapshots, 30-day retention
- **Connection Pooling:** PgBouncer with 100-connection limit
- **Query Optimization:** Regular EXPLAIN ANALYZE reviews

### Scaling Strategy
- **Horizontal:** Multiple NestJS & n8n instances behind load balancer
- **Vertical:** PostgreSQL: increase RAM for caching
- **Async:** Queue heavy operations (webhooks, notifications)
- **Caching:** Redis for session data, hot knowledge base documents

---

## 📚 How to Use These Files

### For Quick Review
1. Open **chatbot_cskh_viewer.html** in browser
2. Click through 4 tabs: Architecture → Sequence → Timing → Edge Cases
3. Download SVG for printing/sharing

### For Technical Deep Dive
1. Review **chatbot_architecture_diagram.svg** side-by-side with this README
2. Trace each layer's responsibilities
3. Understand latency budget allocation
4. Check edge case handling paths

### For Mermaid Integration
1. Copy **chatbot_sequence_diagram.mmd** content
2. Paste into [mermaid.live](https://mermaid.live/)
3. Export as PNG/SVG
4. Or embed in GitHub README:
```markdown
```mermaid
[paste content here]
```
```

### For Presentations
1. Use **chatbot_cskh_viewer.html** as interactive demo
2. Share links with team
3. Print SVG for poster/whiteboard
4. Reference timing table for SLA discussions

---

## 🎯 Key Takeaways

| Component | Role | Latency | Failure Mode |
|-----------|------|---------|--------------|
| **Flutter** | Frontend UI + offline support | ~70ms | Network error → queue |
| **NestJS** | API gateway + rate limiting | ~26ms | Rate limited → 429 |
| **n8n** | Orchestration + context mgmt | ~55ms | Timeout → fallback |
| **Dify** | AI inference + RAG | **1.5-3s ⭐** | Low confidence → escalate |
| **PostgreSQL** | Data persistence | ~25ms | Slow query → escalate |
| **Slack** | Agent notifications | ~200-500ms | API down → retry email |

**Bottleneck:** Dify AI inference (1.5-3s) dominates total latency
**Mitigation:** Cache frequent queries, optimize RAG knowledge base, use model fallback

---

## 📞 Support & Questions

For questions about:
- **Architecture decisions:** See Layer descriptions above
- **Timing & SLAs:** See Timing Analysis section
- **Edge case handling:** See Edge Cases section
- **Security:** See Security & Compliance section
- **Monitoring:** See Observability section

---

**Version:** 1.0  
**Last Updated:** March 2025  
**Format:** SVG + Mermaid + HTML  
**Status:** Production-Ready ✅

