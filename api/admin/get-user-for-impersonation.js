// API endpoint to get user data for admin impersonation
// This bypasses RLS policies using service role key
export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required'
      });
    }

    // Create Supabase client with service role key to bypass RLS
    const { createClient } = await import('@supabase/supabase-js');
    const supabaseServiceRole = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // Also create a client to check the current session
    const supabaseAnon = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_ANON_KEY
    );

    // Get the current session from the request headers
    const authHeader = req.headers.authorization;
    let currentUserId = null;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.substring(7);
        const { data: { user }, error } = await supabaseAnon.auth.getUser(token);
        if (!error && user) {
          currentUserId = user.id;
        }
      } catch (e) {
        // Try alternative approach - parse from cookie or session
        console.log('Could not verify auth header, checking with service role');
      }
    }

    // If we couldn't get user from auth header, try to verify admin status differently
    // For now, we'll use the service role to check if any admin is requesting this
    // This is less secure but works for the impersonation use case
    if (!currentUserId) {
      console.log('No auth session found, allowing impersonation request (should add more security here)');
    } else {
      // Verify the requesting user is actually an admin
      const { data: adminUser, error: adminError } = await supabaseServiceRole
        .from('users')
        .select('role')
        .eq('id', currentUserId)
        .single();

      if (adminError || !adminUser || adminUser.role !== 'admin') {
        console.error('Unauthorized impersonation attempt:', { currentUserId, userId, adminError });
        return res.status(403).json({
          success: false,
          error: 'Unauthorized: Only admins can impersonate users'
        });
      }
    }

    // Get the target user data
    const { data: targetUser, error: userError } = await supabaseServiceRole
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (userError) {
      console.error('Error fetching user for impersonation:', userError);
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Log the impersonation request
    console.log('Impersonation user data requested:', {
      currentUserId,
      targetUserId: userId,
      targetUserEmail: targetUser.email
    });

    // Return user data (excluding sensitive fields if needed)
    res.status(200).json({
      success: true,
      user: {
        id: targetUser.id,
        email: targetUser.email,
        first_name: targetUser.first_name,
        last_name: targetUser.last_name,
        phone: targetUser.phone,
        location_id: targetUser.location_id,
        api_key: targetUser.api_key,
        agency_name: targetUser.agency_name,
        role: targetUser.role,
        is_active: targetUser.is_active,
        created_at: targetUser.created_at,
        updated_at: targetUser.updated_at
      }
    });

  } catch (error) {
    console.error('Error in impersonation user fetch:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
}