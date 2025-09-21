-- Database schema updates for "Purchasing For Others" functionality
-- This allows buyers to purchase leads for other CRM accounts

-- Add columns to orders table for purchasing for others
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS purchased_for_location_id TEXT,
ADD COLUMN IF NOT EXISTS buyer_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS is_purchased_for_other BOOLEAN DEFAULT FALSE;

-- Create buyer_relationships table to track which accounts a buyer can purchase for
CREATE TABLE IF NOT EXISTS buyer_relationships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location_id TEXT NOT NULL,
    location_name TEXT,
    relationship_type TEXT DEFAULT 'client', -- 'client', 'agency', 'partner'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),

    -- Ensure unique buyer-location relationships
    UNIQUE(buyer_id, location_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_purchased_for_location_id ON orders(purchased_for_location_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_buyer_relationships_buyer_id ON buyer_relationships(buyer_id);
CREATE INDEX IF NOT EXISTS idx_buyer_relationships_location_id ON buyer_relationships(location_id);

-- Add comments for documentation
COMMENT ON COLUMN orders.purchased_for_location_id IS 'Location ID of the CRM account these leads are purchased for (if different from buyer)';
COMMENT ON COLUMN orders.buyer_id IS 'User ID of the person who actually made the purchase (for tracking buyer relationships)';
COMMENT ON COLUMN orders.is_purchased_for_other IS 'True if this order was purchased for a different CRM account than the buyers own';

COMMENT ON TABLE buyer_relationships IS 'Tracks which CRM accounts a buyer is authorized to purchase leads for';
COMMENT ON COLUMN buyer_relationships.buyer_id IS 'User who can make purchases for the location';
COMMENT ON COLUMN buyer_relationships.location_id IS 'GoHighLevel location ID they can purchase for';
COMMENT ON COLUMN buyer_relationships.location_name IS 'Friendly name of the location/business';
COMMENT ON COLUMN buyer_relationships.relationship_type IS 'Type of relationship: client, agency, partner, etc.';

-- Update orders table trigger to handle purchased_for_location_id
CREATE OR REPLACE FUNCTION update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();

    -- If this is a purchase for another location, set the flags
    IF NEW.purchased_for_location_id IS NOT NULL AND NEW.purchased_for_location_id != NEW.location_id THEN
        NEW.is_purchased_for_other = TRUE;

        -- Set buyer_id to the current user if not already set
        IF NEW.buyer_id IS NULL THEN
            NEW.buyer_id = NEW.user_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to orders table
DROP TRIGGER IF EXISTS orders_updated_at_trigger ON orders;
CREATE TRIGGER orders_updated_at_trigger
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_orders_updated_at();

-- Row Level Security for buyer_relationships
ALTER TABLE buyer_relationships ENABLE ROW LEVEL SECURITY;

-- Policy: Buyers can see their own relationships
CREATE POLICY "Buyers can view their own relationships" ON buyer_relationships
    FOR SELECT
    USING (buyer_id = auth.uid());

-- Policy: Buyers can insert their own relationships (admin approval may be required)
CREATE POLICY "Buyers can create relationships" ON buyer_relationships
    FOR INSERT
    WITH CHECK (buyer_id = auth.uid());

-- Policy: Buyers can update their own relationships
CREATE POLICY "Buyers can update their own relationships" ON buyer_relationships
    FOR UPDATE
    USING (buyer_id = auth.uid());

-- Policy: Admins can do everything
CREATE POLICY "Admins can manage all buyer relationships" ON buyer_relationships
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Create updated_at trigger for buyer_relationships
CREATE OR REPLACE FUNCTION update_buyer_relationships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER buyer_relationships_updated_at_trigger
    BEFORE UPDATE ON buyer_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_buyer_relationships_updated_at();

-- Add helpful views for reporting
CREATE OR REPLACE VIEW buyer_purchase_summary AS
SELECT
    br.buyer_id,
    u.email as buyer_email,
    u.first_name || ' ' || u.last_name as buyer_name,
    br.location_id,
    br.location_name,
    br.relationship_type,
    COUNT(o.id) as total_orders,
    SUM(
        CASE o.lead_quantity
            WHEN 50 THEN 1500
            WHEN 100 THEN 3000
            WHEN 200 THEN 6000
            WHEN 400 THEN 12000
            ELSE 0
        END
    ) as total_spent,
    MAX(o.created_at) as last_order_date
FROM buyer_relationships br
LEFT JOIN users u ON br.buyer_id = u.id
LEFT JOIN orders o ON br.location_id = o.purchased_for_location_id AND br.buyer_id = o.buyer_id
WHERE br.is_active = TRUE
GROUP BY br.buyer_id, u.email, u.first_name, u.last_name, br.location_id, br.location_name, br.relationship_type
ORDER BY total_spent DESC NULLS LAST;

COMMENT ON VIEW buyer_purchase_summary IS 'Summary of purchases made by buyers for each location they have relationships with';