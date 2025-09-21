// Using direct fetch for Contacts API
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

    // Test Contacts API directly
    const response = await fetch(`https://services.leadconnectorhq.com/contacts/?locationId=${locationId}&limit=5`, {
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
    const contactCount = data.contacts ? data.contacts.length : 0;

    res.status(200).json({
      success: true,
      message: `✅ Contacts API Test Successful! Found ${contactCount} contact(s) in the last 5 results.`,
      data: {
        contactCount,
        locationId,
        endpoint: '/contacts/',
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