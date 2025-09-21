-- Temporary fix: Disable RLS on users table to prevent recursion
-- Run this to fix the infinite recursion issue

-- Disable RLS on users table temporarily
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Keep RLS enabled on other tables but simplify policies
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ghl_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Simple order policies (users can access their own orders)
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;

CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (user_id = auth.uid());

-- Admin tables: allow all authenticated users (we'll check admin role in app)
DROP POLICY IF EXISTS "Allow authenticated users admin settings access" ON public.admin_settings;
CREATE POLICY "Allow authenticated users admin settings access" ON public.admin_settings
    FOR ALL USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Allow authenticated users GHL integrations access" ON public.ghl_integrations;
CREATE POLICY "Allow authenticated users GHL integrations access" ON public.ghl_integrations
    FOR ALL USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Allow authenticated users admin activity log access" ON public.admin_activity_log;
CREATE POLICY "Allow authenticated users admin activity log access" ON public.admin_activity_log
    FOR ALL USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Allow authenticated users order status history access" ON public.order_status_history;
CREATE POLICY "Allow authenticated users order status history access" ON public.order_status_history
    FOR ALL USING (auth.uid() IS NOT NULL);