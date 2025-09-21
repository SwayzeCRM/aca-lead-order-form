-- ACA Lead Order Application Database Schema
-- Run this in your Supabase SQL Editor

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    location_id TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    api_key TEXT,
    agency_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    order_type TEXT NOT NULL CHECK (order_type IN ('individual', 'agency')),

    -- Contact Information
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT NOT NULL,

    -- Consent Information (Individual)
    first_name_license TEXT,
    last_name_license TEXT,
    consent_email TEXT,
    consent_phone TEXT,
    npn TEXT,

    -- Agency Information
    agency_name TEXT,
    agency_npn TEXT,
    agency_consent_phone TEXT,
    agency_consent_email TEXT,

    -- Order Details
    api_key TEXT NOT NULL,
    location_id TEXT NOT NULL,
    selected_states TEXT[] NOT NULL,
    state_count INTEGER NOT NULL,
    lead_quantity INTEGER NOT NULL CHECK (lead_quantity IN (50, 100, 200, 400)),
    selected_carriers TEXT[],
    additional_carriers TEXT,
    invoice_email TEXT NOT NULL,

    -- Legal
    legal_signature TEXT NOT NULL,
    signature_date DATE NOT NULL,

    -- Order Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'invoiced', 'paid', 'processing', 'delivered', 'completed')),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create saved_orders table for quick reordering
CREATE TABLE IF NOT EXISTS public.saved_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    order_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_location_id ON public.users(location_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_orders_user_id ON public.saved_orders(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER handle_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_saved_orders_updated_at
    BEFORE UPDATE ON public.saved_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Row Level Security Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_orders ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow service role to insert users (for auto-registration)
CREATE POLICY "Service role can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

-- Orders policies
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (user_id = auth.uid());

-- Saved orders policies
CREATE POLICY "Users can view own saved orders" ON public.saved_orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own saved orders" ON public.saved_orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own saved orders" ON public.saved_orders
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own saved orders" ON public.saved_orders
    FOR DELETE USING (user_id = auth.uid());