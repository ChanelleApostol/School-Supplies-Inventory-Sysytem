-- ============================================================
-- setup.sql — Run this once in phpMyAdmin or MySQL CLI
-- to create the database and items table.
-- ============================================================

CREATE DATABASE IF NOT EXISTS calm_inventory
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE calm_inventory;

CREATE TABLE IF NOT EXISTS items (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100)   NOT NULL,
    quantity   INT UNSIGNED   NOT NULL DEFAULT 0,
    price      DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional: seed sample data
INSERT INTO items (name, quantity, price) VALUES
    ('Ballpen (Blue)',   120, 8.50),
    ('Notebook (80L)',    60, 45.00),
    ('Pencil #2',        200, 5.00),
    ('Ruler (30cm)',      40, 15.00),
    ('Eraser (White)',    90, 7.00);
