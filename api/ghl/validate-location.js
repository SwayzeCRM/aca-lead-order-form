// Validate Location ID exists in GoHighLevel
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
    const { locationId } = req.body;

    if (!locationId) {
      return res.status(400).json({
        success: false,
        error: 'Location ID is required'
      });
    }

    // Get admin's private token from Supabase
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // Get admin settings to retrieve the private token
    const { data: settings, error: settingsError } = await supabase
      .from('admin_settings')
      .select('pit_token')
      .eq('key', 'ghl_private_integration_token')
      .single();

    if (settingsError || !settings || !settings.pit_token) {
      console.error('Admin settings error:', settingsError);
      return res.status(500).json({
        success: false,
        error: 'Private integration token not configured'
      });
    }

    const privateToken = settings.pit_token;

    // Try to get location details from GoHighLevel
    const url = `https://services.leadconnectorhq.com/locations/${locationId}`;
    const headers = {
      'Authorization': `Bearer ${privateToken}`,
      'Version': '2021-07-28',
      'Content-Type': 'application/json'
    };

    console.log('Location validation request:', {
      url,
      locationId,
      authHeader: `Bearer ${privateToken.substring(0, 8)}...`
    });

    const response = await fetch(url, {
      method: 'GET',
      headers
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Location validation error:`, {
        status: response.status,
        statusText: response.statusText,
        errorBody: errorText,
        locationId
      });

      if (response.status === 404) {
        return res.status(200).json({
          success: false,
          valid: false,
          error: 'Location ID not found',
          locationId
        });
      }

      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }

    const locationData = await response.json();
    console.log('Location validation successful:', locationData);

    // Location exists, return success with location details
    res.status(200).json({
      success: true,
      valid: true,
      locationId,
      location: {
        id: locationData.id,
        name: locationData.name || locationData.businessName || 'Unknown Location',
        businessName: locationData.businessName,
        address: locationData.address,
        city: locationData.city,
        state: locationData.state,
        country: locationData.country
      }
    });

  } catch (error) {
    console.error('Location validation error:', error);

    res.status(500).json({
      success: false,
      valid: false,
      error: error.message,
      locationId: req.body.locationId
    });
  }
}