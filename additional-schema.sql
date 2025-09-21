-- Additional SQL to run in Supabase SQL Editor if email confirmation is still causing issues

-- Create a function to handle user creation with auto-confirmation
CREATE OR REPLACE FUNCTION create_user_with_location(
    user_email TEXT,
    user_password TEXT,
    location_id TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Create auth user
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        user_email,
        crypt(user_password, gen_salt('bf')),
        NOW(),
        NULL,
        NULL,
        '{"provider": "email", "providers": ["email"]}',
        '{}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO new_user_id;

    -- Create user profile
    INSERT INTO public.users (id, email, location_id)
    VALUES (new_user_id, user_email, location_id);

    -- Return success with user data
    SELECT json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', user_email,
        'location_id', location_id
    ) INTO result;

    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_user_with_location TO anon, authenticated;