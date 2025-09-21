// Check what scopes the private integration token has
export default async function handler(req, res) {
  // Enable CORS for your domain
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { privateToken, locationId } = req.body;

    if (!privateToken || !locationId) {
      return res.status(400).json({
        error: 'Private token and location ID are required'
      });
    }

    console.log('Checking token scopes and permissions...');

    // Try to get user info to see what scopes are available
    const userResponse = await fetch(`https://services.leadconnectorhq.com/users/`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${privateToken}`,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      }
    });

    console.log('User info response status:', userResponse.status);

    if (userResponse.ok) {
      const userData = await userResponse.json();
      console.log('User data received:', userData);
    }

    // Try to get location info
    const locationResponse = await fetch(`https://services.leadconnectorhq.com/locations/${locationId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${privateToken}`,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      }
    });

    console.log('Location info response status:', locationResponse.status);

    if (locationResponse.ok) {
      const locationData = await locationResponse.json();
      console.log('Location data received:', locationData);
    }

    res.status(200).json({
      success: true,
      message: 'Token scope check completed - see server logs for details',
      userApiStatus: userResponse.status,
      locationApiStatus: locationResponse.status,
      debug: {
        userOk: userResponse.ok,
        locationOk: locationResponse.ok
      }
    });

  } catch (error) {
    console.error('Token scope check error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to check token scopes: ${error.message}`,
      error: error.message
    });
  }
}