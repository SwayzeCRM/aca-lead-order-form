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

    // Test Opportunities API
    const opportunities = await ghl.opportunities.search({
      location_id: locationId,
      limit: 5
    });

    const opportunityCount = opportunities.opportunities ? opportunities.opportunities.length : 0;

    res.status(200).json({
      success: true,
      message: `✅ Opportunities API Test Successful! Found ${opportunityCount} opportunit(ies) in the last 5 results.`,
      data: {
        opportunityCount,
        locationId,
        endpoint: 'opportunities.search',
        scopes: ['View Opportunities ✓']
      }
    });

  } catch (error) {
    console.error('Opportunities API test error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Opportunities API Test Failed! Error: ${error.message}`,
      error: error.message
    });
  }
}