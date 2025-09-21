-- Add new columns to users table if they don't exist
-- Run this in Supabase SQL Editor after running the main schema

DO $$
BEGIN
    -- Add api_key column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'api_key') THEN
        ALTER TABLE public.users ADD COLUMN api_key TEXT;
    END IF;

    -- Add agency_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'agency_name') THEN
        ALTER TABLE public.users ADD COLUMN agency_name TEXT;
    END IF;
END $$;