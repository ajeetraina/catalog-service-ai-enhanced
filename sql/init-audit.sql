-- Create audit database and user
CREATE DATABASE catalog_audit;
CREATE USER audit_user WITH PASSWORD 'audit_pass';
GRANT ALL PRIVILEGES ON DATABASE catalog_audit TO audit_user;

-- Use audit database
\c catalog_audit;

-- Create audit tables
CREATE TABLE IF NOT EXISTS mcp_audit_log (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(255),
    tool_name VARCHAR(255),
    event_type VARCHAR(50),
    risk_score DECIMAL(3,2),
    pii_count INTEGER DEFAULT 0,
    sensitive_count INTEGER DEFAULT 0,
    compliance_score DECIMAL(3,2),
    content_hash VARCHAR(64),
    metadata JSONB
);

CREATE TABLE IF NOT EXISTS security_incidents (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    incident_type VARCHAR(255),
    session_id VARCHAR(255),
    tool_name VARCHAR(255),
    severity VARCHAR(20),
    description TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    metadata JSONB
);

-- Create indexes
CREATE INDEX idx_audit_session_id ON mcp_audit_log(session_id);
CREATE INDEX idx_audit_timestamp ON mcp_audit_log(timestamp);
CREATE INDEX idx_incidents_severity ON security_incidents(severity);
CREATE INDEX idx_incidents_timestamp ON security_incidents(timestamp);

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO audit_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO audit_user;
