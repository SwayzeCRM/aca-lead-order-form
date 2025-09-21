// Get pipelines from GoHighLevel
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

    // Get pipelines from GoHighLevel - using the correct opportunities endpoint
    const url = `https://services.leadconnectorhq.com/opportunities/pipelines?locationId=${locationId}`;
    const headers = {
      'Authorization': `Bearer ${privateToken}`,
      'Version': '2021-07-28',
      'Content-Type': 'application/json'
    };

    console.log('Pipelines API Request:', {
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
      console.error(`Pipelines API Error Details:`, {
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
    console.log('Pipelines API response:', data);

    // Handle different possible response structures
    const pipelines = data.pipelines || data || [];

    res.status(200).json({
      success: true,
      pipelines: pipelines,
      message: `Found ${pipelines.length || 0} pipelines`,
      debug: data // Include raw response for debugging
    });

  } catch (error) {
    console.error('Pipelines API error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to fetch pipelines: ${error.message}`,
      error: error.message
    });
  }
}