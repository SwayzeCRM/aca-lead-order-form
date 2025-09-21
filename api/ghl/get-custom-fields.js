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

    // Get custom fields from GoHighLevel
    const response = await fetch(`https://services.leadconnectorhq.com/locations/${locationId}/customFields`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${privateToken}`,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${await response.text()}`);
    }

    const data = await response.json();

    res.status(200).json({
      success: true,
      customFields: data.customFields || [],
      message: `Found ${data.customFields?.length || 0} custom fields`
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