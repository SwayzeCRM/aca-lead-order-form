-- Check if tim@swayzecrm.com has admin role
SELECT email, role, is_active, api_key, created_at
FROM public.users
WHERE email = 'tim@swayzecrm.com';

-- If no results, the user doesn't exist yet
-- If role is NULL or 'user', we need to update it