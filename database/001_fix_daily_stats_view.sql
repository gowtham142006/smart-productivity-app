-- =====================================================
-- Migration: Fix daily_stats VIEW
-- Date: 2026-07-22
-- Description: Rewrite daily_stats VIEW using
--   pre-aggregated subqueries to eliminate the
--   cartesian product that inflated focus_minutes.
--
-- ROOT CAUSE: The old VIEW joined tasks × habits ×
--   pomodoro_sessions in a single FROM, causing each
--   pomodoro row to be duplicated per task row.
--   SUM(ps.duration) was multiplied by the task count.
--
-- FIX: Aggregate each source table independently,
--   then FULL OUTER JOIN the results. This guarantees
--   focus_minutes = exact SUM of stored durations.
--
-- IMPORTANT: Apply this via the Supabase SQL Editor.
--
-- NOTE: Because the query structure changes, PostgreSQL
--   may reject CREATE OR REPLACE VIEW. If so, run:
--     DROP VIEW IF EXISTS daily_stats;
--   before running this migration.
-- =====================================================

CREATE OR REPLACE VIEW daily_stats AS
SELECT
    COALESCE(ts.user_id, hs.user_id, ps_agg.user_id) AS user_id,
    COALESCE(ts.date, hs.date, ps_agg.date) AS date,
    COALESCE(ts.tasks_completed, 0) AS tasks_completed,
    COALESCE(ts.tasks_created, 0) AS tasks_created,
    COALESCE(hs.habits_completed, 0) AS habits_completed,
    COALESCE(ps_agg.focus_minutes, 0) AS focus_minutes,
    COALESCE(ps_agg.pomodoro_sessions, 0) AS pomodoro_sessions
FROM (
    -- Task stats: one row per (user, date)
    SELECT
        user_id,
        DATE(created_at) AS date,
        COUNT(*) FILTER (WHERE is_completed = true) AS tasks_completed,
        COUNT(*) AS tasks_created
    FROM tasks
    GROUP BY user_id, DATE(created_at)
) ts
FULL OUTER JOIN (
    -- Habit stats: one row per (user, date)
    SELECT
        h.user_id,
        hl.completed_at AS date,
        COUNT(DISTINCT hl.id) AS habits_completed
    FROM habit_logs hl
    JOIN habits h ON h.id = hl.habit_id
    GROUP BY h.user_id, hl.completed_at
) hs ON hs.user_id = ts.user_id AND hs.date = ts.date
FULL OUTER JOIN (
    -- Pomodoro stats: one row per (user, date)
    -- focus_minutes = exact SUM of stored durations
    SELECT
        user_id,
        DATE(ended_at) AS date,
        COALESCE(SUM(duration) FILTER (WHERE completed = true), 0) AS focus_minutes,
        COUNT(id) FILTER (WHERE completed = true) AS pomodoro_sessions
    FROM pomodoro_sessions
    GROUP BY user_id, DATE(ended_at)
) ps_agg
    ON ps_agg.user_id = COALESCE(ts.user_id, hs.user_id)
   AND ps_agg.date = COALESCE(ts.date, hs.date);
