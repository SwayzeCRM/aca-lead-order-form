-- Simple migration to add admin columns safely
-- Run this in Supabase SQL Editor

-- Add role column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user', 'buyer'));

-- Add other admin fields to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add admin fields to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS assigned_admin UUID REFERENCES public.users(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS admin_notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS processing_notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS webhook_sent BOOLEAN DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS automation_triggered BOOLEAN DEFAULT false;

-- Set tim@swayzecrm.com as admin (change email if needed)
UPDATE public.users
SET role = 'admin'
WHERE email = 'tim@swayzecrm.com';

-- Create admin settings table
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

-- Create order status history table
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
    target_type TEXT,
    target_id TEXT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_assigned_admin ON public.orders(assigned_admin);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- Insert default admin settings
INSERT INTO public.admin_settings (setting_key, setting_value, description)
VALUES
    ('ghl_client_id', '', 'GoHighLevel OAuth Client ID'),
    ('ghl_client_secret', '', 'GoHighLevel OAuth Client Secret'),
    ('webhook_secret', '', 'Webhook secret for validating incoming requests'),
    ('default_pipeline_id', '', 'Default pipeline ID for lead orders'),
    ('notification_email', 'tim@swayzecrm.com', 'Admin email for notifications')
ON CONFLICT (setting_key) DO NOTHING;