-- Admin Schema Updates
-- Run this after the main schema to add admin functionality

-- Add user roles and admin-specific fields to users table
DO $$
BEGIN
    -- Add role column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE public.users ADD COLUMN role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user', 'buyer'));
    END IF;

    -- Add admin-specific fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'is_active') THEN
        ALTER TABLE public.users ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'notes') THEN
        ALTER TABLE public.users ADD COLUMN notes TEXT;
    END IF;
END $$;

-- Create admin settings table for GoHighLevel OAuth integration
CREATE TABLE IF NOT EXISTS public.admin_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value TEXT,
    encrypted BOOLEAN DEFAULT false,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id)
);

-- Create GoHighLevel integrations table
CREATE TABLE IF NOT EXISTS public.ghl_integrations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    location_id TEXT UNIQUE NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    location_name TEXT,
    is_active BOOLEAN DEFAULT true,
    webhook_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id)
);

-- Add order management fields
DO $$
BEGIN
    -- Add assigned admin field to orders
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'assigned_admin') THEN
        ALTER TABLE public.orders ADD COLUMN assigned_admin UUID REFERENCES public.users(id);
    END IF;

    -- Add admin notes field to orders
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'admin_notes') THEN
        ALTER TABLE public.orders ADD COLUMN admin_notes TEXT;
    END IF;

    -- Add processing notes field
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'processing_notes') THEN
        ALTER TABLE public.orders ADD COLUMN processing_notes TEXT;
    END IF;

    -- Add webhook sent tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'webhook_sent') THEN
        ALTER TABLE public.orders ADD COLUMN webhook_sent BOOLEAN DEFAULT false;
    END IF;

    -- Add automation triggered tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'automation_triggered') THEN
        ALTER TABLE public.orders ADD COLUMN automation_triggered BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Create order status history table for tracking changes
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    old_status TEXT,
    new_status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(id),
    change_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin activity log
CREATE TABLE IF NOT EXISTS public.admin_activity_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES public.users(id) NOT NULL,
    action TEXT NOT NULL,
    target_type TEXT, -- 'user', 'order', 'settings', etc.
    target_id TEXT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_admin ON public.orders(assigned_admin);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON public.order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_admin_id ON public.admin_activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_created_at ON public.admin_activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ghl_integrations_location_id ON public.ghl_integrations(location_id);

-- Add triggers for updated_at on new tables
CREATE TRIGGER handle_admin_settings_updated_at
    BEFORE UPDATE ON public.admin_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_ghl_integrations_updated_at
    BEFORE UPDATE ON public.ghl_integrations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Row Level Security for admin tables
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ghl_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Admin settings policies (only admins can access)
CREATE POLICY "Admins can view admin settings" ON public.admin_settings
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can modify admin settings" ON public.admin_settings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- GHL integrations policies (only admins can access)
CREATE POLICY "Admins can view GHL integrations" ON public.ghl_integrations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can modify GHL integrations" ON public.ghl_integrations
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Order status history policies
CREATE POLICY "Users can view order status history for their orders" ON public.order_status_history
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can modify order status history" ON public.order_status_history
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Admin activity log policies (only admins can view)
CREATE POLICY "Admins can view admin activity log" ON public.admin_activity_log
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can insert admin activity log" ON public.admin_activity_log
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Update existing policies to allow admin access
-- Drop and recreate user policies to include admin access
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

CREATE POLICY "Users can view own profile or admins can view all" ON public.users
    FOR SELECT USING (
        auth.uid() = id
        OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can update own profile or admins can update all" ON public.users
    FOR UPDATE USING (
        auth.uid() = id
        OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Update orders policies to allow admin access
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;

CREATE POLICY "Users can view own orders or admins can view all" ON public.orders
    FOR SELECT USING (
        user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can update own orders or admins can update all" ON public.orders
    FOR UPDATE USING (
        user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Set tim@swayzecrm.com as admin (update this email if needed)
UPDATE public.users
SET role = 'admin'
WHERE email = 'tim@swayzecrm.com';

-- If tim@swayzecrm.com doesn't exist, this will do nothing
-- You'll need to create the user first or update the email

-- Insert default admin settings
INSERT INTO public.admin_settings (setting_key, setting_value, description)
VALUES
    ('ghl_client_id', '', 'GoHighLevel OAuth Client ID'),
    ('ghl_client_secret', '', 'GoHighLevel OAuth Client Secret'),
    ('webhook_secret', '', 'Webhook secret for validating incoming requests'),
    ('default_pipeline_id', '', 'Default pipeline ID for lead orders'),
    ('notification_email', 'tim@swayzecrm.com', 'Admin email for notifications')
ON CONFLICT (setting_key) DO NOTHING;