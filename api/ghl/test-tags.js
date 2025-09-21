import { HighLevel } from '@gohighlevel/api-client';

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

    // Initialize GoHighLevel SDK
    const ghl = new HighLevel({
      privateIntegrationToken: privateToken
    });

    // Test Tags API
    const tags = await ghl.contacts.getTags({
      locationId: locationId
    });

    const tagCount = tags.tags ? tags.tags.length : 0;

    res.status(200).json({
      success: true,
      message: `✅ Tags API Test Successful! Found ${tagCount} tag(s) in this location.`,
      data: {
        tagCount,
        locationId,
        endpoint: 'contacts.getTags',
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