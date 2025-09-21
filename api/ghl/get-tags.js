// Get tags from GoHighLevel
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

    // Get tags from GoHighLevel - using the corrected tags endpoint
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

    const data = await response.json();

    // Log the response for debugging
    console.log('Tags API response:', data);

    // Handle different possible response structures
    const tags = data.tags || data || [];

    res.status(200).json({
      success: true,
      tags: tags,
      message: `Found ${tags.length || 0} tags`,
      debug: data // Include raw response for debugging
    });

  } catch (error) {
    console.error('Tags API error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to fetch tags: ${error.message}`,
      error: error.message
    });
  }
}