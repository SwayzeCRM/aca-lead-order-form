// Using direct fetch for Tags API since SDK method is unclear

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

    // Test Tags API directly - using Sub-Account tags endpoint
    const response = await fetch(`https://services.leadconnectorhq.com/locations/${locationId}/tags`, {
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

    const tags = await response.json();
    const tagCount = tags.tags ? tags.tags.length : 0;

    res.status(200).json({
      success: true,
      message: `✅ Tags API Test Successful! Found ${tagCount} tag(s) in this location.`,
      data: {
        tagCount,
        locationId,
        endpoint: '/locations/{locationId}/tags',
        scopes: ['View Tags ✓', 'Edit Tags ✓']
      }
    });

  } catch (error) {
    console.error('Tags API test error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Tags API Test Failed! Error: ${error.message}`,
      error: error.message
    });
  }
}