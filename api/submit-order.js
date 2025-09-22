// API endpoint to submit order after successful payment
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const orderData = req.body;

    // Validate required fields
    if (!orderData.paymentIntentId || !orderData.totalAmount) {
      return res.status(400).json({ error: 'Missing required payment information' });
    }

    // Generate unique order ID
    const orderId = `ACA-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    // Prepare order data for database
    const dbOrderData = {
      id: orderId,
      user_id: orderData.userId || null, // You'll need to pass this from frontend
      order_type: orderData.orderType,
      lead_quantity: parseInt(orderData.leadQuantity),
      total_amount: orderData.totalAmount,
      payment_status: 'paid',
      payment_intent_id: orderData.paymentIntentId,

      // Customer information
      customer_email: orderData.invoiceEmail,
      customer_name: orderData.individual_firstName
        ? `${orderData.individual_firstName} ${orderData.individual_lastName}`
        : orderData.agency_contactName,
      customer_phone: orderData.individual_contactPhone || orderData.agency_contactPhone,

      // Business information (for agencies)
      business_name: orderData.agency_businessName || null,
      business_address: orderData.agency_businessAddress || null,
      business_city: orderData.agency_businessCity || null,
      business_state: orderData.agency_businessState || null,
      business_zip: orderData.agency_businessZip || null,

      // Order details
      selected_states: orderData.selectedStates,
      selected_carriers: orderData.selectedCarriers,
      additional_carriers: orderData.additionalCarriers || null,
      api_key: orderData.apiKey,

      // Location information (if purchasing for others)
      target_location_id: orderData.targetLocationId || null,

      // Timestamps
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),

      // Status
      status: 'pending',
      notes: `Order placed via web form. Payment Intent: ${orderData.paymentIntentId}`
    };

    // Insert order into database
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert(dbOrderData)
      .select()
      .single();

    if (orderError) {
      console.error('Database error:', orderError);
      throw new Error('Failed to save order to database');
    }

    // TODO: Send confirmation email
    // TODO: Notify admin of new order
    // TODO: Trigger lead generation process

    console.log('Order submitted successfully:', {
      orderId: orderId,
      amount: orderData.totalAmount,
      paymentIntentId: orderData.paymentIntentId
    });

    res.status(200).json({
      success: true,
      orderId: orderId,
      message: 'Order submitted successfully'
    });

  } catch (error) {
    console.error('Error submitting order:', error);
    res.status(500).json({
      error: 'Failed to submit order',
      details: error.message
    });
  }
}