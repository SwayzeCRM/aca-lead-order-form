// Get locations from GoHighLevel to find Location ID
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
    const { privateToken } = req.body;

    if (!privateToken) {
      return res.status(400).json({
        error: 'Private token is required'
      });
    }

    // Get locations from GoHighLevel - this endpoint should work with private integration
    const url = `https://services.leadconnectorhq.com/locations/`;
    const headers = {
      'Authorization': `Bearer ${privateToken}`,
      'Version': '2021-07-28',
      'Content-Type': 'application/json'
    };

    console.log('Locations API Request:', {
      url,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${privateToken.substring(0, 8)}...`,
        'Version': headers.Version,
        'Content-Type': headers['Content-Type']
      }
    });

    const response = await fetch(url, {
      method: 'GET',
      headers
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Locations API Error Details:`, {
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
    console.log('Locations API response:', JSON.stringify(data, null, 2));

    // Handle different possible response structures
    let locations = [];

    if (Array.isArray(data)) {
      // If data is directly an array
      locations = data;
    } else if (data.locations && Array.isArray(data.locations)) {
      // If data has locations property
      locations = data.locations;
    } else if (data.data && Array.isArray(data.data)) {
      // If data has data property
      locations = data.data;
    } else {
      console.error('Unexpected locations response structure:', data);
    }

    // Transform locations to ensure they have the right structure
    const processedLocations = locations.map(location => ({
      id: location.id,
      name: location.name || location.businessName || 'Unnamed Location',
      businessName: location.businessName,
      address: location.address,
      city: location.city,
      state: location.state,
      country: location.country,
      phone: location.phone,
      email: location.email,
      website: location.website
    }));

    console.log('Processed locations:', processedLocations);

    res.status(200).json({
      success: true,
      locations: processedLocations,
      message: `Found ${processedLocations.length || 0} locations`,
      debug: {
        rawResponse: data,
        originalLength: locations.length,
        processedLength: processedLocations.length
      }
    });

  } catch (error) {
    console.error('Locations API error:', error);

    res.status(500).json({
      success: false,
      message: `❌ Failed to fetch locations: ${error.message}`,
      error: error.message
    });
  }
}