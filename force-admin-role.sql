-- Force set the user as admin
-- Run this in Supabase SQL Editor

-- First check if the user exists
SELECT email, role, id FROM public.users WHERE email = 'tim@swayzecrm.com';

-- Update the role to admin
UPDATE public.users
SET role = 'admin'
WHERE email = 'tim@swayzecrm.com';

-- Verify it worked
SELECT email, role, id FROM public.users WHERE email = 'tim@swayzecrm.com';