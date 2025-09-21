-- Add workflow settings support to admin_settings table
-- Run this in Supabase SQL Editor

-- The workflow settings will be stored as key-value pairs in the existing admin_settings table
-- No schema changes needed, but here are the keys that will be used:

/*
Workflow Settings Keys:
- workflow_enabled: 'true' | 'false'
- workflow_create_contact: 'true' | 'false'
- workflow_add_pipeline: 'true' | 'false'
- workflow_add_tags: 'true' | 'false'
- workflow_pipeline_id: GoHighLevel Pipeline ID
- workflow_order_tags: Comma-separated list of tags
- workflow_order_value_field: Custom field name for order value
*/

-- Insert default workflow settings (optional)
INSERT INTO public.admin_settings (setting_key, setting_value, created_at, updated_at) VALUES
    ('workflow_enabled', 'false', NOW(), NOW()),
    ('workflow_create_contact', 'true', NOW(), NOW()),
    ('workflow_add_pipeline', 'false', NOW(), NOW()),
    ('workflow_add_tags', 'true', NOW(), NOW()),
    ('workflow_pipeline_id', '', NOW(), NOW()),
    ('workflow_order_tags', 'new-order,aca-customer', NOW(), NOW()),
    ('workflow_order_value_field', 'order_value', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- Verify the settings were inserted
SELECT setting_key, setting_value
FROM public.admin_settings
WHERE setting_key LIKE 'workflow_%'
ORDER BY setting_key;