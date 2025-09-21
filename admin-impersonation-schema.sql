-- Database schema for admin impersonation functionality
-- This allows admins to "login as" users for debugging and testing

-- Create impersonation_log table to track admin impersonation sessions
CREATE TABLE IF NOT EXISTS impersonation_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    session_duration_minutes INTEGER,
    reason TEXT DEFAULT 'Admin debugging/testing',
    admin_ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_impersonation_log_admin_id ON impersonation_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_target_user_id ON impersonation_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_started_at ON impersonation_log(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_impersonation_log_is_active ON impersonation_log(is_active);

-- Add comments for documentation
COMMENT ON TABLE impersonation_log IS 'Tracks admin impersonation sessions for audit and security purposes';
COMMENT ON COLUMN impersonation_log.admin_id IS 'ID of the admin user who initiated the impersonation';
COMMENT ON COLUMN impersonation_log.target_user_id IS 'ID of the user being impersonated';
COMMENT ON COLUMN impersonation_log.started_at IS 'When the impersonation session began';
COMMENT ON COLUMN impersonation_log.ended_at IS 'When the impersonation session ended (NULL if still active)';
COMMENT ON COLUMN impersonation_log.session_duration_minutes IS 'Calculated duration of the session in minutes';
COMMENT ON COLUMN impersonation_log.reason IS 'Reason for impersonation (e.g., debugging, testing)';
COMMENT ON COLUMN impersonation_log.is_active IS 'Whether this impersonation session is currently active';

-- Function to automatically calculate session duration when ended
CREATE OR REPLACE FUNCTION calculate_impersonation_duration()
RETURNS TRIGGER AS $$
BEGIN
    -- If ended_at is being set and was previously NULL, calculate duration
    IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL THEN
        NEW.session_duration_minutes = EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 60;
        NEW.is_active = FALSE;
    END IF;

    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically calculate duration and update timestamps
CREATE TRIGGER impersonation_log_update_trigger
    BEFORE UPDATE ON impersonation_log
    FOR EACH ROW
    EXECUTE FUNCTION calculate_impersonation_duration();

-- Row Level Security for impersonation_log
ALTER TABLE impersonation_log ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can view impersonation logs
CREATE POLICY "Admins can view impersonation logs" ON impersonation_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Policy: Only admins can create impersonation logs
CREATE POLICY "Admins can create impersonation logs" ON impersonation_log
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
        AND admin_id = auth.uid()
    );

-- Policy: Only admins can update impersonation logs
CREATE POLICY "Admins can update impersonation logs" ON impersonation_log
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Create a view for active impersonation sessions
CREATE OR REPLACE VIEW active_impersonation_sessions AS
SELECT
    il.id,
    il.admin_id,
    a.email as admin_email,
    a.first_name || ' ' || a.last_name as admin_name,
    il.target_user_id,
    u.email as target_user_email,
    u.first_name || ' ' || u.last_name as target_user_name,
    il.started_at,
    EXTRACT(EPOCH FROM (NOW() - il.started_at)) / 60 as current_duration_minutes,
    il.reason
FROM impersonation_log il
JOIN users a ON il.admin_id = a.id
JOIN users u ON il.target_user_id = u.id
WHERE il.is_active = TRUE
ORDER BY il.started_at DESC;

COMMENT ON VIEW active_impersonation_sessions IS 'Shows all currently active admin impersonation sessions with user details';

-- Function to end all active impersonation sessions for cleanup
CREATE OR REPLACE FUNCTION end_all_impersonation_sessions()
RETURNS INTEGER AS $$
DECLARE
    ended_count INTEGER;
BEGIN
    UPDATE impersonation_log
    SET ended_at = NOW(),
        is_active = FALSE
    WHERE is_active = TRUE;

    GET DIAGNOSTICS ended_count = ROW_COUNT;
    RETURN ended_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION end_all_impersonation_sessions IS 'Emergency function to end all active impersonation sessions';