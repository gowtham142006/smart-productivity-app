-- =====================================================
-- AI Productivity App
-- Database Schema
-- Database: Supabase PostgreSQL
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PROFILES
-- =====================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- CATEGORIES
-- =====================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#5B67F1',
    icon TEXT DEFAULT 'folder',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- TASKS
-- =====================================================

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,

    title TEXT,
    description TEXT,

    priority TEXT DEFAULT 'medium',

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,

    due_date TIMESTAMPTZ,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- NOTES
-- =====================================================

CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    title TEXT,
    content TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =====================================================
-- HABITS
-- =====================================================

CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    description TEXT,

    frequency TEXT DEFAULT 'daily',

    target_days INTEGER DEFAULT 30,

    color TEXT DEFAULT '#5B67F1',
    icon TEXT DEFAULT 'check_circle',

    reminder_time TIME,

    current_streak INTEGER DEFAULT 0,
    best_streak INTEGER DEFAULT 0,

    target_count INTEGER DEFAULT 1,
    goal_type TEXT DEFAULT 'count',

    sort_order INTEGER DEFAULT 0,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- HABIT LOGS
-- =====================================================

CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,

    completed_at DATE DEFAULT CURRENT_DATE,

    status TEXT DEFAULT 'completed',

    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE (habit_id, completed_at)
);  

-- =====================================================
-- POMODORO SESSIONS
-- =====================================================

CREATE TABLE pomodoro_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES auth.users(id)
        ON DELETE CASCADE,

    task_id UUID
        REFERENCES tasks(id)
        ON DELETE SET NULL,

    duration INTEGER,

    completed BOOLEAN DEFAULT FALSE,

    started_at TIMESTAMPTZ,

    ended_at TIMESTAMPTZ,

    interruptions INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- DAILY STATS
-- =====================================================

CREATE TABLE daily_stats (
    user_id UUID REFERENCES auth.users(id)
        ON DELETE CASCADE,

    date DATE,

    tasks_created BIGINT,

    tasks_completed BIGINT,

    habits_completed BIGINT,

    focus_minutes BIGINT
);

-- =====================================================
-- NOTIFICATION SETTINGS
-- =====================================================

CREATE TABLE notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES auth.users(id)
        ON DELETE CASCADE,

    task_reminder BOOLEAN DEFAULT TRUE,

    habit_reminder BOOLEAN DEFAULT TRUE,

    pomodoro_reminder BOOLEAN DEFAULT TRUE,

    daily_digest BOOLEAN DEFAULT TRUE,

    reminder_time TIME DEFAULT '08:00:00',

    timezone TEXT DEFAULT 'Asia/Kolkata',

    sound_enabled BOOLEAN DEFAULT TRUE,

    vibration_enabled BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- CHAT CONVERSATIONS
-- =====================================================

CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    title TEXT DEFAULT 'New Chat',

    created_at TIMESTAMPTZ DEFAULT now(),

    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- CHAT MESSAGES
-- =====================================================

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    conversation_id UUID NOT NULL
        REFERENCES chat_conversations(id)
        ON DELETE CASCADE,

    user_id UUID
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    role TEXT NOT NULL,

    content TEXT NOT NULL,

    created_at TIMESTAMPTZ DEFAULT now(),

    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- END OF SCHEMA
-- =====================================================