-- Initialization script for Approval Workflow Database
-- You can use this to populate initial sample approval blocks or configurations.

-- Example: Insert a generic approval block
INSERT INTO approval_workflow_block (name, description, block_type, rule_definition)
VALUES 
    ('Basic Manager Approval', 'A standard approval step for a department manager', 'generic',
     '{"rules": [{"condition": "amount > 1000", "action": "require_manager_approval"}]}')
ON CONFLICT DO NOTHING;

-- Example: Insert a workflow config
INSERT INTO approval_workflow_config (name, description)
VALUES
    ('Purchase Request Workflow', 'A default workflow for new purchase requests')
ON CONFLICT DO NOTHING;

-- Example: Insert step configs (assume block ID and workflow config ID of 1)
INSERT INTO approval_workflow_step_config (workflow_config_id, step_order, block_id, name, is_parallel, is_mandatory)
VALUES
    (1, 1, 1, 'Manager Approval', FALSE, TRUE)
ON CONFLICT DO NOTHING;

-- Add similar inserts for your own approval blocks or initial workflow configs as needed.

-- Example: Insert approver assignments for a step instance (assume step instance ID of 1, adjust as needed)
INSERT INTO approval_workflow_instance_step_approver (step_instance_id, approver_id, status)
VALUES
    (1, 'manager_jane', 'pending'),
    (1, 'manager_bob', 'pending')
ON CONFLICT DO NOTHING;
