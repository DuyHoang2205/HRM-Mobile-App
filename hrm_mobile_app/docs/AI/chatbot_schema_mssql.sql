IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'chatbot')
BEGIN
    EXEC('CREATE SCHEMA chatbot');
END
GO

IF OBJECT_ID('chatbot.chat_sessions', 'U') IS NULL
BEGIN
    CREATE TABLE chatbot.chat_sessions (
        id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        user_no NVARCHAR(50) NOT NULL,
        employee_id INT NULL,
        state NVARCHAR(20) NOT NULL DEFAULT 'active',
        context NVARCHAR(MAX) NULL,
        escalation_reason NVARCHAR(200) NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_chat_sessions PRIMARY KEY (id)
    );
END
GO

IF OBJECT_ID('chatbot.chat_messages', 'U') IS NULL
BEGIN
    CREATE TABLE chatbot.chat_messages (
        id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        message_id NVARCHAR(100) NOT NULL,
        session_id UNIQUEIDENTIFIER NOT NULL,
        user_no NVARCHAR(50) NOT NULL,
        role NVARCHAR(20) NOT NULL,
        content NVARCHAR(MAX) NOT NULL,
        intent NVARCHAR(100) NULL,
        confidence_score FLOAT NULL,
        is_fallback BIT NOT NULL DEFAULT 0,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_chat_messages PRIMARY KEY (id),
        CONSTRAINT UQ_chat_messages_message_id UNIQUE (message_id),
        CONSTRAINT FK_chat_messages_session
            FOREIGN KEY (session_id) REFERENCES chatbot.chat_sessions(id)
    );
END
GO

IF OBJECT_ID('chatbot.bot_logs', 'U') IS NULL
BEGIN
    CREATE TABLE chatbot.bot_logs (
        id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        session_id UNIQUEIDENTIFIER NULL,
        message_id NVARCHAR(100) NULL,
        event_type NVARCHAR(50) NOT NULL,
        payload NVARCHAR(MAX) NULL,
        error_detail NVARCHAR(MAX) NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_bot_logs PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_chat_sessions_user_no'
      AND object_id = OBJECT_ID('chatbot.chat_sessions')
)
BEGIN
    CREATE INDEX IX_chat_sessions_user_no
        ON chatbot.chat_sessions(user_no, updated_at DESC);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_chat_messages_session_created'
      AND object_id = OBJECT_ID('chatbot.chat_messages')
)
BEGIN
    CREATE INDEX IX_chat_messages_session_created
        ON chatbot.chat_messages(session_id, created_at);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_chat_messages_user_created'
      AND object_id = OBJECT_ID('chatbot.chat_messages')
)
BEGIN
    CREATE INDEX IX_chat_messages_user_created
        ON chatbot.chat_messages(user_no, created_at DESC);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bot_logs_session_created'
      AND object_id = OBJECT_ID('chatbot.bot_logs')
)
BEGIN
    CREATE INDEX IX_bot_logs_session_created
        ON chatbot.bot_logs(session_id, created_at DESC);
END
GO
