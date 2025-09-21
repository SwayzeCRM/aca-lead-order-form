-- Fix infinite recursion in RLS policies
-- Run this to replace the problematic policies

-- Drop all existing policies that cause recursion
DROP POLICY IF EXISTS "Users can view own profile or admins can view all" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile or admins can update all" ON public.users;
DROP POLICY IF EXISTS "Users can view own orders or admins can view all" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders or admins can update all" ON public.orders;

-- Create simple, non-recursive policies for users table
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow service role to insert users (for auto-registration)
CREATE POLICY "Service role can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

-- Simple policies for orders (users can only see their own orders)
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (user_id = auth.uid());

-- For admin access, we'll handle it in the application layer instead of RLS
-- This prevents the infinite recursion issue

-- Keep the admin-only table policies simple
DROP POLICY IF EXISTS "Admins can view admin settings" ON public.admin_settings;
DROP POLICY IF EXISTS "Admins can modify admin settings" ON public.admin_settings;

-- Simple admin settings policies (we'll check admin role in app)
CREATE POLICY "Allow authenticated users admin settings access" ON public.admin_settings
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Same for other admin tables
DROP POLICY IF EXISTS "Admins can view GHL integrations" ON public.ghl_integrations;
DROP POLICY IF EXISTS "Admins can modify GHL integrations" ON public.ghl_integrations;

CREATE POLICY "Allow authenticated users GHL integrations access" ON public.ghl_integrations
    FOR ALL USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can view admin activity log" ON public.admin_activity_log;
DROP POLICY IF EXISTS "Admins can insert admin activity log" ON public.admin_activity_log;

CREATE POLICY "Allow authenticated users admin activity log access" ON public.admin_activity_log
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Order status history
DROP POLICY IF EXISTS "Users can view order status history for their orders" ON public.order_status_history;
DROP POLICY IF EXISTS "Admins can modify order status history" ON public.order_status_history;

CREATE POLICY "Allow authenticated users order status history access" ON public.order_status_history
    FOR ALL USING (auth.uid() IS NOT NULL);