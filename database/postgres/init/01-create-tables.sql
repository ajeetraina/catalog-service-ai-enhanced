-- Create products table for approved catalog items
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    vendor_name VARCHAR(255) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    evaluation_score INTEGER DEFAULT 0,
    evaluation_reasoning TEXT,
    confidence_level DECIMAL(3,2) DEFAULT 0.0,
    agent_insights JSONB,
    approval_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Create indexes for better query performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_vendor ON products(vendor_name);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_score ON products(evaluation_score);
CREATE INDEX idx_products_created ON products(created_at);

-- Create audit table for product changes
CREATE TABLE IF NOT EXISTS product_audit (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    action VARCHAR(50) NOT NULL,
    agent_decision TEXT,
    evaluation_details JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    changed_by VARCHAR(100)
);

-- Insert sample data
INSERT INTO products (vendor_name, product_name, description, price, category, evaluation_score, evaluation_reasoning, confidence_level, approval_date) VALUES
('NVIDIA', 'Jetson Nano Developer Kit', 'NVIDIA Jetson Nano Developer Kit is a small, powerful computer that lets you run multiple neural networks in parallel for applications like image classification, object detection, segmentation, and speech processing.', 199.00, 'Electronics', 87, 'Strong technical specifications with innovative AI capabilities. Competitive pricing for the development board market.', 0.92, NOW()),
('Raspberry Pi Foundation', 'Raspberry Pi 5 8GB', 'The latest Raspberry Pi 5 with 8GB RAM, featuring a quad-core ARM Cortex-A76 processor, dual 4K display support, and improved connectivity options.', 80.00, 'Electronics', 78, 'Well-established product with strong community support. Good value for educational and hobbyist use.', 0.88, NOW());
