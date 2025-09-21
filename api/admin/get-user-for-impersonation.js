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
    const { userId, adminId } = req.body;

    if (!userId || !adminId) {
      return res.status(400).json({
        success: false,
        error: 'User ID and Admin ID are required'
      });
    }

    // Create Supabase client with service role key to bypass RLS
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // Verify the requesting user is actually an admin
    const { data: adminUser, error: adminError } = await supabase
      .from('users')
      .select('role')
      .eq('id', adminId)
      .single();

    if (adminError || !adminUser || adminUser.role !== 'admin') {
      console.error('Unauthorized impersonation attempt:', { adminId, userId, adminError });
      return res.status(403).json({
        success: false,
        error: 'Unauthorized: Only admins can impersonate users'
      });
    }

    // Get the target user data
    const { data: targetUser, error: userError } = await supabase
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
      adminId,
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