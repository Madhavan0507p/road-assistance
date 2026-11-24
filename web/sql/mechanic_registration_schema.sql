-- =============================================================================
-- Mechanic Registration & Partner Portal - MySQL Schema Migration Script
-- On Road Vehicle Breakdown Assistance Web Application
-- =============================================================================

-- 1. Safely extend the mechanics table with 5-Step Registration Wizard fields
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS first_name VARCHAR(60) NULL AFTER mechanic_code;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS last_name VARCHAR(60) NULL AFTER first_name;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS gender VARCHAR(20) DEFAULT 'Male' AFTER last_name;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS email_verified TINYINT(1) DEFAULT 0 AFTER email;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS shop_name VARCHAR(100) NULL AFTER workshop_name;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS shop_type VARCHAR(60) NULL AFTER shop_name;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS shop_contact_number VARCHAR(20) NULL AFTER phone;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS years_of_experience VARCHAR(40) NULL AFTER shop_type;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS opening_time VARCHAR(20) DEFAULT '09:00 AM' AFTER years_of_experience;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS closing_time VARCHAR(20) DEFAULT '07:00 PM' AFTER opening_time;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS shop_description VARCHAR(255) NULL AFTER closing_time;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS address_line_1 VARCHAR(255) NULL AFTER address;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS address_line_2 VARCHAR(255) NULL AFTER address_line_1;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS city VARCHAR(100) NULL AFTER address_line_2;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS district VARCHAR(100) NULL AFTER city;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS state VARCHAR(100) DEFAULT 'Tamil Nadu' AFTER district;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS pincode VARCHAR(10) NULL AFTER state;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS other_specialization VARCHAR(255) NULL AFTER specialization;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS account_status VARCHAR(20) DEFAULT 'Active' AFTER approval_status;
ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Synchronize shop_name and owner_name for existing records
UPDATE mechanics SET shop_name = workshop_name WHERE shop_name IS NULL OR shop_name = '';
UPDATE mechanics SET first_name = SUBSTRING_INDEX(owner_name, ' ', 1), last_name = SUBSTRING(owner_name, LENGTH(SUBSTRING_INDEX(owner_name, ' ', 1)) + 2) WHERE first_name IS NULL OR first_name = '';

-- 2. Create normalized table for multiple mechanic specializations
CREATE TABLE IF NOT EXISTS mechanic_specializations (
    specialization_id INT AUTO_INCREMENT PRIMARY KEY,
    mechanic_id INT NOT NULL,
    specialization_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mechanic_id) REFERENCES mechanics(mechanic_id) ON DELETE CASCADE,
    UNIQUE KEY unique_mech_spec (mechanic_id, specialization_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Create table for mechanic shop photos
CREATE TABLE IF NOT EXISTS mechanic_shop_photos (
    photo_id INT AUTO_INCREMENT PRIMARY KEY,
    mechanic_id INT NOT NULL,
    photo_path VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mechanic_id) REFERENCES mechanics(mechanic_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Temporary table / index for email OTP records
CREATE TABLE IF NOT EXISTS email_otp (
    otp_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified TINYINT(1) DEFAULT 0,
    attempt_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_otp (email, verified, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
