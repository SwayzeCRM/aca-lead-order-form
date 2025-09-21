// Get custom fields from GoHighLevel
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

    // Get custom fields from GoHighLevel - using correct endpoint with contact model
    const url = `https://services.leadconnectorhq.com/locations/${locationId}/customFields?model=contact`;
    const headers = {
      'Authorization': `Bearer ${privateToken}`,
      'Version': '2021-07-28',
      'Content-Type': 'application/json'
    };

    console.log('Custom Fields API Request:', {
      url,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${privateToken.substring(0, 8)}...`,
        'Version': headers.Version,
        'Content-Type': headers['Content-Type']
      },
      locationId
    });

    const response = await fetch(url, {
      method: 'GET',
      headers
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Custom Fields API Error Details:`, {
        status: response.status,
        statusText: response.statusText,
        errorBody: errorText,
        url: response.url,
        headers: Object.fromEntries(response.headers.entries())
      });
      throw new Error(`API request failed: ${response.status} ${response.statusText} - ${errorText}`);
    }

    const data = await response.json();

    // Log the response for debugging
    console.log('Custom Fields API response:', data);

    // Handle response structure based on API documentation
    const customFields = data.customFields || [];

    res.status(200).json({
      success: true,
      customFields: customFields,
      message: `Found ${customFields.length || 0} custom fields`,
      debug: data // Include raw response for debugging
    });

  } catch (error) {
    console.error('Custom fields API error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to fetch custom fields: ${error.message}`,
      error: error.message
    });
  }
}