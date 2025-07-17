-- DDL for Approval Workflow Database Schema
-- This schema supports configuration and runtime instances for approval workflows.

-- ===============================
-- Table: approval_workflow_block
-- Reusable approval logic/selection blocks, can have business rules stored as JSON
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_block (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    block_type VARCHAR(50) NOT NULL DEFAULT 'generic', -- e.g., 'generic', 'custom'
    rule_definition JSONB, -- Structure for the business rules/library
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===============================
-- Table: approval_workflow_config
-- Top-level workflow configurations, composed of steps
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_config (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===============================
-- Table: approval_workflow_step_config
-- Defines a step within a workflow configuration. Steps can reference a block.
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_step_config (
    id SERIAL PRIMARY KEY,
    workflow_config_id INTEGER NOT NULL REFERENCES approval_workflow_config(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL, -- supports sequential order
    block_id INTEGER REFERENCES approval_workflow_block(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_parallel BOOLEAN NOT NULL DEFAULT FALSE, -- true if multiple approvers act in parallel at this step
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    config JSONB, -- Additional step-level config (e.g., required approvals count)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(workflow_config_id, step_order)
);

-- ===============================
-- Table: approval_workflow_instance
-- Represents a running instance of a workflow.
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_instance (
    id SERIAL PRIMARY KEY,
    workflow_config_id INTEGER NOT NULL REFERENCES approval_workflow_config(id) ON DELETE SET NULL,
    business_object_id VARCHAR(100) NOT NULL, -- Reference to external entity being approved (e.g., document ID)
    status VARCHAR(32) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, cancelled, etc.
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    last_step INTEGER, -- Optionally track last active step
    context JSONB, -- Runtime context data
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===============================
-- Table: approval_workflow_instance_step
-- Tracks step-level state for each workflow instance.
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_instance_step (
    id SERIAL PRIMARY KEY,
    workflow_instance_id INTEGER NOT NULL REFERENCES approval_workflow_instance(id) ON DELETE CASCADE,
    step_config_id INTEGER NOT NULL REFERENCES approval_workflow_step_config(id) ON DELETE RESTRICT,
    block_id INTEGER REFERENCES approval_workflow_block(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, skipped, etc.
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    assigned_to VARCHAR(100), -- Approver user/group (if any)
    assignment_metadata JSONB, -- E.g., queue details, group assignment
    approval_result JSONB,    -- Result info (e.g., who approved, time, comments)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(workflow_instance_id, step_config_id)
);

-- Index to quickly find step configs for a workflow config
CREATE INDEX IF NOT EXISTS idx_step_config_workflow ON approval_workflow_step_config(workflow_config_id);

-- Index for querying all steps in a given workflow instance
CREATE INDEX IF NOT EXISTS idx_instance_step_instance_id ON approval_workflow_instance_step(workflow_instance_id);

-- Index for querying running/completed workflow instances for a business object
CREATE INDEX IF NOT EXISTS idx_instance_business_object ON approval_workflow_instance(business_object_id);

-- ===============================
-- Table: approval_workflow_instance_step_approver
-- Tracks individual approvers for each workflow step instance,
-- supporting multi-approver and parallel-approver steps.
-- ===============================
CREATE TABLE IF NOT EXISTS approval_workflow_instance_step_approver (
    id SERIAL PRIMARY KEY,
    step_instance_id INTEGER NOT NULL REFERENCES approval_workflow_instance_step(id) ON DELETE CASCADE,
    approver_id VARCHAR(100) NOT NULL, -- user ID or entity assigned as approver
    status VARCHAR(32) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, skipped, etc.
    actioned_at TIMESTAMPTZ, -- Time when approval/rejection happened
    comments TEXT,
    extra_metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(step_instance_id, approver_id)
);
CREATE INDEX IF NOT EXISTS idx_step_approver_instance_id ON approval_workflow_instance_step_approver(step_instance_id);

-- Make updated_at auto-update on row modification (PostgreSQL 12+ can use triggers or generated columns; here a trigger recommended)
-- Trigger definitions not included here (add separately if needed).

-- End of schema
