CREATE INDEX idx_tasks_user
ON tasks(user_id);

CREATE INDEX idx_tasks_due
ON tasks(due_date);

CREATE INDEX idx_habits_user
ON habits(user_id);

CREATE INDEX idx_habit_logs_user
ON habit_logs(user_id);

CREATE INDEX idx_chat_messages_conversation
ON chat_messages(conversation_id);

CREATE INDEX idx_calendar_events_user
ON calendar_events(user_id);

CREATE INDEX idx_calendar_events_start
ON calendar_events(start_datetime);

CREATE INDEX idx_notifications_user
ON notifications(user_id);

CREATE INDEX idx_notifications_created
ON notifications(created_at DESC);