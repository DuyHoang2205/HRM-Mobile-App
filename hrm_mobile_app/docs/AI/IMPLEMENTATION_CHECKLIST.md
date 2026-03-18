# 📋 Chatbot CSKH - Implementation Checklist

## Phase 1: Planning & Architecture (Week 1-2)

### Architecture Review
- [ ] Team review of system architecture diagram
- [ ] Review all 7 layers and responsibilities
- [ ] Identify dependencies between components
- [ ] Discuss potential bottlenecks (Dify latency)
- [ ] Plan database schema (ERD review)

### API Specification
- [ ] Define NestJS endpoints:
  - [ ] `POST /chat/messages` - Send message
  - [ ] `GET /chat/messages/:sessionId` - Get history
  - [ ] `POST /chat/escalate` - Escalate to human
  - [ ] `GET /orders/:userId` - Fetch orders
- [ ] Define webhook contract with n8n
- [ ] Define Slack notification payload format
- [ ] Create Postman collection for API testing

### Database Planning
- [ ] Create PostgreSQL schema:
  - [ ] `messages` table (user_id, content, timestamp, metadata)
  - [ ] `conversation_sessions` table (session_id, context, state)
  - [ ] `orders` table (order_id, user_id, status, items)
  - [ ] `products` table (product_id, name, stock, size_chart)
  - [ ] Create indexes on user_id, session_id, message_id
- [ ] Plan connection pooling (PgBouncer config)
- [ ] Set up read replicas for scaling

### Security Planning
- [ ] Design JWT token lifecycle (15-min expiry, refresh token)
- [ ] Plan PII masking strategy for logs
- [ ] Design encryption at rest (pgcrypto or TDE)
- [ ] Plan rate limiting implementation (100 req/min)
- [ ] Set up webhook signature verification (HMAC-SHA256)

---

## Phase 2: Frontend Development (Week 2-4)

### Flutter App Setup
- [ ] Create Flutter project structure
- [ ] Set up Firebase/Auth0 for JWT tokens
- [ ] Implement offline support:
  - [ ] SQLite/Hive local database schema
  - [ ] Queue data structure for retry
  - [ ] Exponential backoff retry logic (1s → 2s → 4s → 8s)
- [ ] Implement network monitoring (connectivity_plus package)

### Input Validation
- [ ] Add file type validation (reject Voice/Video/Exe)
- [ ] Show file size limits to user
- [ ] Add error toast notifications

### Message State Management
- [ ] Implement state machine: pending → sent → delivered → read
- [ ] Add UI indicators for each state
- [ ] Update local cache on each state change

### Network Handling
- [ ] Implement HTTP client with JWT interceptor
- [ ] Add request/response logging with trace_id
- [ ] Implement retry logic with exponential backoff
- [ ] Handle network disconnection gracefully
- [ ] Auto-sync offline messages when online

### Offline Sync Implementation
- [ ] Save message to SQLite when offline
- [ ] Show "syncing..." indicator to user
- [ ] Implement retry queue processor
- [ ] Handle sync failure scenarios
- [ ] Show retry status to user

### Testing
- [ ] Unit tests for validation logic
- [ ] Widget tests for UI components
- [ ] Integration tests for offline sync
- [ ] E2E tests with mock backend

---

## Phase 3: Backend Development (Week 3-6)

### NestJS Project Setup
- [ ] Initialize NestJS project
- [ ] Set up TypeORM with PostgreSQL
- [ ] Configure environment variables
- [ ] Set up logging (Winston or Pino)

### Authentication & Authorization
- [ ] Implement JWT strategy (NestJS Passport)
- [ ] Create auth endpoints:
  - [ ] `POST /auth/login`
  - [ ] `POST /auth/refresh`
  - [ ] `POST /auth/logout`
- [ ] Implement token refresh middleware
- [ ] Add role-based access control (RBAC) for admin endpoints

### Rate Limiting
- [ ] Install `@nestjs/throttler` package
- [ ] Configure rate limit: 100 req/min per user
- [ ] Add custom rate limiting guards
- [ ] Test 429 response on exceeded limit

### Message Handling
- [ ] Create Message entity (TypeORM)
- [ ] Implement message persistence:
  - [ ] `POST /chat/messages` endpoint
  - [ ] Validate and sanitize input (XSS prevention)
  - [ ] Save to PostgreSQL
  - [ ] Return message_id to client
- [ ] Implement message retrieval:
  - [ ] `GET /chat/messages/:sessionId`
  - [ ] Pagination support
  - [ ] Filter by date range

### Webhook Management
- [ ] Create webhook service
- [ ] Format payload with metadata:
  - [ ] user_id, message_id, content
  - [ ] conversation_id, timestamp
  - [ ] user_profile (name, preferences)
- [ ] Sign webhook with HMAC-SHA256
- [ ] Implement retry logic (3x with backoff)
- [ ] Add webhook event logging

### Database Integration
- [ ] Create all entities (Message, Session, Order, Product)
- [ ] Set up foreign keys and relationships
- [ ] Create database migrations
- [ ] Add database seeding for test data
- [ ] Optimize queries (N+1 problem prevention)

### Error Handling
- [ ] Create centralized error handler
- [ ] Define error response format (status, code, message)
- [ ] Handle specific error cases:
  - [ ] JWT expired → 401
  - [ ] Rate limited → 429
  - [ ] Invalid input → 400
  - [ ] Database error → 500 (with fallback)
- [ ] Add request logging (trace_id correlation)

### Testing
- [ ] Unit tests for services
- [ ] Integration tests for endpoints
- [ ] Load testing (simulate 100+ req/s)
- [ ] Database transaction testing
- [ ] Webhook retry testing

---

## Phase 4: Orchestration Layer (Week 4-7)

### n8n Workflow Setup
- [ ] Create n8n instance (Docker or cloud)
- [ ] Set up database for workflow persistence
- [ ] Configure webhook endpoint for NestJS

### Webhook Receiver Node
- [ ] Create webhook trigger node
- [ ] Parse incoming payload
- [ ] Validate signature (HMAC-SHA256)
- [ ] Extract user_id, message_id, content
- [ ] Add error handling for invalid payloads

### Context Management
- [ ] Create database connector node
- [ ] Load conversation history from PostgreSQL
- [ ] Implement session_id logic
- [ ] Store conversation context in n8n variables
- [ ] Handle missing conversation (create new)

### Token Optimization
- [ ] Create token counting node (TikToken library)
- [ ] Set threshold: 4K tokens max
- [ ] Implement message truncation logic:
  - [ ] Keep system prompt
  - [ ] Keep recent messages (last 5-10)
  - [ ] Drop old messages
- [ ] Log token count for monitoring

### Intent Classification
- [ ] Create intent detection node
- [ ] Define intents:
  - [ ] "ask_size" → Product inquiry
  - [ ] "check_order" → Order status
  - [ ] "return_request" → Return/exchange
  - [ ] "general_question" → Fallback
- [ ] Route based on intent

### Dify Integration
- [ ] Create HTTP request node for Dify API
- [ ] Set timeout to 5 seconds
- [ ] Format prompt:
  - [ ] System prompt: "You are a helpful clothing shop assistant"
  - [ ] Context: conversation history
  - [ ] User message: current message
- [ ] Handle response: extract text + confidence score
- [ ] Implement retry logic (3x on timeout)

### Database Query Node
- [ ] Create PostgreSQL connector for n8n
- [ ] Implement order lookup query:
  - [ ] `SELECT * FROM orders WHERE user_id = ? AND order_id = ?`
  - [ ] Return order details
- [ ] Implement inventory check:
  - [ ] `SELECT stock_level FROM products WHERE product_id = ?`
  - [ ] Suggest alternatives if out of stock

### Response Routing
- [ ] Route response back to NestJS
- [ ] Include metadata:
  - [ ] response_id, intent, confidence_score
  - [ ] session_id, timestamp
- [ ] Handle escalation routing:
  - [ ] If confidence < 60% → escalate flag
  - [ ] Create Slack notification
  - [ ] Update conversation state to "escalated"

### Error Handling
- [ ] Set up error catch nodes
- [ ] Handle Dify timeout → fallback message
- [ ] Handle database error → escalate
- [ ] Handle invalid intent → ask clarification
- [ ] Log all errors with context

### Testing
- [ ] Unit tests for each node
- [ ] End-to-end workflow testing
- [ ] Error scenario testing (timeout, db failure)
- [ ] Performance testing (latency monitoring)

---

## Phase 5: AI Integration (Week 5-8)

### Dify Setup
- [ ] Create Dify workspace
- [ ] Set up knowledge base (RAG):
  - [ ] Upload size chart PDF
  - [ ] Upload product catalog
  - [ ] Upload return/exchange policy
  - [ ] Upload FAQ documents
- [ ] Configure document chunking (1024 tokens per chunk)
- [ ] Set up vector embedding (OpenAI or local)

### Knowledge Base Management
- [ ] Create admin API for KB updates
  - [ ] Upload new documents
  - [ ] Update existing documents
  - [ ] Delete outdated documents
- [ ] Set up scheduling for KB refresh (daily)
- [ ] Monitor KB quality (embedding coverage)

### LLM Configuration
- [ ] Choose LLM provider:
  - [ ] OpenAI (Claude) - recommended
  - [ ] Anthropic (Claude)
  - [ ] Local model (Llama 2)
- [ ] Configure model parameters:
  - [ ] Temperature: 0.3 (low for consistency)
  - [ ] Max tokens: 500
  - [ ] Top-p: 0.9
- [ ] Set up cost monitoring/limits

### Response Generation
- [ ] Create system prompt:
  - [ ] Role: helpful clothing shop assistant
  - [ ] Tone: friendly and professional
  - [ ] Constraints: only answer about clothing
- [ ] Create few-shot examples:
  - [ ] Size inquiry example
  - [ ] Order status example
  - [ ] Return policy example
- [ ] Implement confidence scoring

### Refusal Handling
- [ ] Configure rejection rules:
  - [ ] Off-topic detection
  - [ ] Rude/abusive language detection
  - [ ] Toxicity filtering
- [ ] Create refusal responses:
  - [ ] "I can only help with clothing items"
  - [ ] "Let me escalate you to a human agent"

### Edge Case Handling
- [ ] Contradictory data detection:
  - [ ] Validate user input (height/weight/size)
  - [ ] Flag inconsistencies
  - [ ] Request clarification
- [ ] Context switch detection:
  - [ ] Detect intent change
  - [ ] Reset conversation context
  - [ ] Notify user of context change
- [ ] Confidence scoring:
  - [ ] Score each response 0-100%
  - [ ] Escalate if < 60%
  - [ ] Track low-confidence patterns

### Testing
- [ ] Test size recommendation accuracy
- [ ] Test order lookup scenarios
- [ ] Test refusal cases (off-topic)
- [ ] Test edge cases (contradictory data)
- [ ] Benchmark response quality (BLEU score)
- [ ] Load test (concurrent requests)

---

## Phase 6: Database & Integration (Week 6-7)

### PostgreSQL Setup
- [ ] Create database and user
- [ ] Create schema (tables, indexes, constraints)
- [ ] Load initial data (products, sizes)
- [ ] Set up backups (daily snapshots)
- [ ] Configure connection pooling (PgBouncer)
- [ ] Set up monitoring (query performance)

### Message History Table
- [ ] Create messages table:
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES sessions(id),
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  intent VARCHAR(50),
  confidence_score FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_session_id (session_id),
  INDEX idx_user_id (user_id),
  FULLTEXT INDEX idx_content (content)
);
```
- [ ] Create indexes for common queries
- [ ] Set up partitioning by date (if large volume)

### Conversation Sessions Table
- [ ] Create sessions table:
```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  context JSONB,
  state VARCHAR(20), -- active, escalated, closed
  escalation_reason VARCHAR(100),
  assigned_agent_id UUID,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
- [ ] Track session state transitions
- [ ] Store conversation context (JSONB)

### Order Integration
- [ ] Create orders table (or connect to existing)
- [ ] Implement order lookup by user_id + order_id
- [ ] Add order status updates (webhook from fulfillment)
- [ ] Track order history per user

### Product Inventory
- [ ] Create products table:
  - [ ] product_id, name, description
  - [ ] size_chart (JSONB with sizes/measurements)
  - [ ] stock_level, reorder_point
  - [ ] related_products (alternatives)
- [ ] Implement stock check query
- [ ] Set up inventory sync (cron job from ERP)

### Data Synchronization
- [ ] Set up cron jobs for data sync:
  - [ ] Orders: sync every 30 min from fulfillment system
  - [ ] Inventory: sync every hour
  - [ ] Product info: sync daily
- [ ] Implement error handling for sync failures
- [ ] Log all sync operations

### Testing
- [ ] Test all CRUD operations
- [ ] Test query performance (EXPLAIN ANALYZE)
- [ ] Test concurrent access (locks/deadlocks)
- [ ] Test backup/restore process
- [ ] Test data consistency (foreign keys)

---

## Phase 7: Observability & Monitoring (Week 7-8)

### Logging Infrastructure
- [ ] Set up ELK Stack:
  - [ ] Elasticsearch: log storage
  - [ ] Logstash: log processing
  - [ ] Kibana: visualization/dashboards
- [ ] Configure log shipping from all components
- [ ] Set up log retention (90 days)

### Structured Logging
- [ ] Add trace_id to all logs
- [ ] Log format: JSON with timestamp, level, message, context
- [ ] PII masking:
  - [ ] Hash phone numbers
  - [ ] Hash email addresses
  - [ ] Mask payment info
- [ ] Log levels: ERROR, WARN, INFO, DEBUG

### Metrics Collection
- [ ] Set up metrics stack (Prometheus + Grafana)
- [ ] Define metrics per layer:
  - [ ] **Flutter:** App startup time, crash rate
  - [ ] **NestJS:** Request latency, error rate, QPS
  - [ ] **n8n:** Workflow execution time, error rate
  - [ ] **Dify:** API latency, confidence score distribution
  - [ ] **PostgreSQL:** Query time, connection pool usage
- [ ] Create dashboards:
  - [ ] System health overview
  - [ ] Latency breakdown per layer
  - [ ] Error rate trends
  - [ ] Intent distribution
  - [ ] Escalation metrics

### SLA Monitoring
- [ ] Track p50, p95, p99 latency
- [ ] Monitor error rate (target: < 1%)
- [ ] Track availability (target: 99.5%)
- [ ] Create SLA dashboard (real-time)

### Alerting Rules
- [ ] Set up alert rules:
  - [ ] p95 latency > 2.5s → page oncall
  - [ ] Error rate > 1% → immediate alert
  - [ ] Database connection pool > 80% → warn
  - [ ] Offline queue > 10K messages → investigate
  - [ ] No agents available > 5 min → escalate
- [ ] Set up notification channels:
  - [ ] Slack for warnings
  - [ ] PagerDuty for critical alerts
  - [ ] Email for summary reports

### Distributed Tracing
- [ ] Set up tracing (Jaeger or Datadog)
- [ ] Add trace context to all requests
- [ ] Trace flows:
  - [ ] Flutter → NestJS → n8n → Dify
  - [ ] n8n → PostgreSQL
- [ ] Create trace dashboards

### Testing
- [ ] Verify log shipping working
- [ ] Test metric collection accuracy
- [ ] Test alert triggering
- [ ] Test dashboard refreshing
- [ ] Load test monitoring system

---

## Phase 8: Human Handoff & Support (Week 8+)

### Slack Integration
- [ ] Create Slack app
- [ ] Set up bot tokens
- [ ] Create support queue channel (#support-queue)
- [ ] Implement message formatting for escalations:
  - [ ] User name + context
  - [ ] Conversation history (last 5 messages)
  - [ ] "Join Chat" button (link to support interface)
- [ ] Test notification delivery

### Support Ticket System
- [ ] Create tickets table in PostgreSQL
- [ ] Implement ticket creation on escalation
- [ ] Track ticket status: open → in_progress → resolved
- [ ] Link ticket to conversation
- [ ] Track agent assignment

### Agent Chat Interface
- [ ] Build or integrate agent UI:
  - [ ] List of queued customers
  - [ ] One-click join conversation
  - [ ] Full conversation history visible
  - [ ] Message sending (bypass AI)
  - [ ] Close ticket / resolve
- [ ] Implement message routing:
  - [ ] Detect AI-off message (from agent)
  - [ ] Route to customer directly
  - [ ] Don't process through Dify

### Testing
- [ ] Test escalation flow end-to-end
- [ ] Test agent join/message sending
- [ ] Test conversation history transfer
- [ ] Test ticket lifecycle

---

## Phase 9: Testing & QA (Week 9)

### Unit Testing
- [ ] Flutter:
  - [ ] Validation logic
  - [ ] Offline sync logic
  - [ ] State management
- [ ] NestJS:
  - [ ] JWT validation
  - [ ] Rate limiting
  - [ ] Database queries
- [ ] n8n:
  - [ ] Token counting
  - [ ] Intent classification
  - [ ] Response formatting

### Integration Testing
- [ ] Flutter ↔ NestJS API
- [ ] NestJS ↔ PostgreSQL
- [ ] NestJS ↔ n8n webhook
- [ ] n8n ↔ Dify API
- [ ] n8n ↔ PostgreSQL queries

### E2E Testing
- [ ] Happy path: User sends message → Gets answer
- [ ] Offline path: Offline message → Auto-sync
- [ ] Escalation path: Low confidence → Human agent
- [ ] Error paths: Timeout → Fallback response

### Load Testing
- [ ] Simulate 100 concurrent users
- [ ] Simulate 500 concurrent users
- [ ] Measure latency at each level
- [ ] Monitor database connections
- [ ] Check Dify API rate limits
- [ ] Verify offline queue handling

### Security Testing
- [ ] Test JWT token validation
- [ ] Test rate limiting bypass attempts
- [ ] Test SQL injection prevention
- [ ] Test XSS prevention
- [ ] Test webhook signature verification
- [ ] Test PII masking in logs

---

## Phase 10: Deployment & Launch (Week 10+)

### Pre-Launch Checklist
- [ ] All tests passing (unit, integration, E2E)
- [ ] Load testing results acceptable
- [ ] Security audit completed
- [ ] Documentation complete
- [ ] Team trained on deployment/ops
- [ ] Runbooks created for common issues
- [ ] On-call rotation established

### Deployment Strategy
- [ ] Set up CI/CD pipeline
- [ ] Canary deployment (10% → 50% → 100%)
- [ ] Automated rollback on error spike
- [ ] Health checks for all components
- [ ] Database migration strategy

### Post-Launch
- [ ] Monitor metrics closely (first 24 hours)
- [ ] Respond to user feedback
- [ ] Fix any bugs/performance issues
- [ ] Iterate based on usage patterns
- [ ] Plan Phase 2 improvements

---

## Estimated Timeline

| Phase | Duration | Team Size |
|-------|----------|-----------|
| 1. Planning | 2 weeks | 3 people (architect, PM, tech lead) |
| 2. Frontend | 2-3 weeks | 2 Flutter devs |
| 3. Backend | 3 weeks | 2 NestJS devs |
| 4. Orchestration | 3 weeks | 1 n8n specialist |
| 5. AI Integration | 3 weeks | 1 ML engineer + prompt engineer |
| 6. Database | 1 week | 1 DBA |
| 7. Observability | 2 weeks | 1 DevOps engineer |
| 8. Support | 1 week | 1 backend dev |
| 9. Testing & QA | 2 weeks | 2 QA engineers |
| 10. Launch | 1 week | Whole team |
| **TOTAL** | **~10 weeks** | **8-10 people** |

---

## Dependencies & Tools

### Required Services
- [ ] PostgreSQL (database)
- [ ] Dify (AI platform)
- [ ] n8n (orchestration)
- [ ] OpenAI/Anthropic API (LLM)
- [ ] Slack workspace (notifications)
- [ ] Firebase/Auth0 (authentication)
- [ ] Elasticsearch/Kibana (logging)
- [ ] Prometheus/Grafana (monitoring)

### Required Tools
- [ ] Flutter SDK
- [ ] Node.js v18+
- [ ] Docker/Docker Compose
- [ ] Git/GitHub
- [ ] Postman (API testing)
- [ ] VS Code + extensions

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Dify API latency | High | Cache frequent queries, use fallback model |
| Database performance | High | Read replicas, query optimization, indexing |
| Offline sync queue overflow | Medium | Cleanup old queued messages, priority queue |
| Rate limiting issues | Medium | Implement smarter throttling, per-IP limits |
| Token overflow in context | Medium | Aggressive truncation, summarization |
| Agent availability | Medium | Queuing system, estimated wait time |
| Data contradictions | Low | Validation rules, ask for confirmation |

---

## Success Metrics

- [ ] **Latency:** p95 < 2.5 seconds ✅
- [ ] **Availability:** 99.5% uptime ✅
- [ ] **Error Rate:** < 1% ✅
- [ ] **User Satisfaction:** CSAT > 4.0/5.0 ✅
- [ ] **Escalation Rate:** < 20% ✅
- [ ] **Cost:** < $0.10 per message ✅

---

**Last Updated:** March 2025  
**Status:** Ready for development  
**Questions?** Refer to architecture documentation
