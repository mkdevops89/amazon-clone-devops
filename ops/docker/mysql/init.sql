CREATE DATABASE IF NOT EXISTS amazonlike_db;
USE amazonlike_db;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'USER'
);

CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    category VARCHAR(50)
);

-- Seed Data
INSERT INTO products (name, description, price, image_url, category) VALUES
('Wireless Headphones', 'Premium noise-cancelling headphones.', 299.99, '/images/headphones.jpg', 'Electronics'),
('Smart Watch', 'Fitness tracker with health monitoring.', 199.99, '/images/watch.jpg', 'Electronics'),
('Running Shoes', 'Lightweight and comfortable.', 89.99, '/images/shoes.jpg', 'Fashion');

INSERT INTO users (username, password, role) VALUES ('admin', 'admin', 'ADMIN');
