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

    // Test Contacts API
    const contacts = await ghl.contacts.search({
      locationId: locationId,
      limit: 5
    });

    const contactCount = contacts.contacts ? contacts.contacts.length : 0;

    res.status(200).json({
      success: true,
      message: `✅ Contacts API Test Successful! Found ${contactCount} contact(s) in the last 5 results.`,
      data: {
        contactCount,
        locationId,
        endpoint: 'contacts.search',
        scopes: ['View Contacts ✓', 'Edit Contacts ✓']
      }
    });

  } catch (error) {
    console.error('Contacts API test error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Contacts API Test Failed! Error: ${error.message}`,
      error: error.message
    });
  }
}