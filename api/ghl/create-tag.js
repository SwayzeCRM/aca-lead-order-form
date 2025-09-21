// Create a new tag in GoHighLevel
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
    const { privateToken, locationId, tagName } = req.body;

    if (!privateToken || !locationId || !tagName) {
      return res.status(400).json({
        error: 'Private token, location ID, and tag name are required'
      });
    }

    // Create tag in GoHighLevel
    const response = await fetch(`https://services.leadconnectorhq.com/locations/${locationId}/tags`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${privateToken}`,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        name: tagName
      })
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${await response.text()}`);
    }

    const data = await response.json();

    res.status(200).json({
      success: true,
      tag: data.tag || data,
      message: `✅ Tag "${tagName}" created successfully`
    });

  } catch (error) {
    console.error('Create tag API error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to create tag: ${error.message}`,
      error: error.message
    });
  }
}