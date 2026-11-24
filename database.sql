-- =============================================================================
-- On Road Vehicle Breakdown Assistance - Complete Database Setup Script
-- Database Name: road_assistance_db
-- Compatibility: MySQL 5.7+ / MySQL 8.0+ / MariaDB / XAMPP / WampServer / phpMyAdmin
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `road_assistance_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `road_assistance_db`;

-- =============================================================================
-- 1. ADMIN CREDENTIALS TABLE (`admins`)
-- =============================================================================
DROP TABLE IF EXISTS `admins`;

CREATE TABLE `admins` (
    `admin_id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `role` VARCHAR(50) DEFAULT 'Administrator',
    `status` VARCHAR(20) DEFAULT 'Active',
    `last_login` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Default Administrator Accounts
INSERT INTO `admins` (`admin_id`, `username`, `password`, `full_name`, `email`, `role`, `status`) VALUES
(1, 'admin', 'admin123', 'Administrator', 'admin@roadassistance.com', 'Super Administrator', 'Active'),
(2, 'superadmin', 'admin123', 'System Controller', 'support@roadassistance.com', 'Platform Admin', 'Active');

-- =============================================================================
-- 2. REGISTERED USERS TABLE (`users`)
-- =============================================================================
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
    `user_id` INT AUTO_INCREMENT PRIMARY KEY,
    `first_name` VARCHAR(50) DEFAULT NULL,
    `last_name` VARCHAR(50) DEFAULT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `phone` VARCHAR(20) NOT NULL,
    `gender` VARCHAR(20) DEFAULT 'Prefer not to say',
    `password` VARCHAR(255) NOT NULL,
    `vehicle_number` VARCHAR(50) DEFAULT NULL,
    `vehicle_model` VARCHAR(100) DEFAULT NULL,
    `address` VARCHAR(255) DEFAULT NULL,
    `status` ENUM('Active', 'Inactive', 'Blocked') DEFAULT 'Active',
    `email_verified` TINYINT(1) DEFAULT 0,
    `terms_accepted` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Sample Users
INSERT INTO `users` (`user_id`, `first_name`, `last_name`, `full_name`, `email`, `phone`, `gender`, `password`, `vehicle_number`, `vehicle_model`, `address`, `status`, `email_verified`, `terms_accepted`) VALUES
(1, 'Raj', 'Kumar', 'Raj Kumar', 'rajkumar@gmail.com', '+91 98765 43210', 'Male', 'user123', 'TN 10 AB 1234', 'Hyundai Creta', 'Chennai, Tamil Nadu', 'Active', 1, 1),
(2, 'Karthik', 'S', 'Karthik S', 'karthiks@gmail.com', '+91 97894 56780', 'Male', 'user123', 'TN 22 CD 5678', 'Maruti Swift', 'Coimbatore, Tamil Nadu', 'Inactive', 1, 1),
(3, 'Praveen', 'M', 'Praveen M', 'praveenm@gmail.com', '+91 96325 90120', 'Male', 'user123', 'TN 11 EF 9012', 'Tata Nexon', 'Madurai, Tamil Nadu', 'Active', 1, 1),
(4, 'Divya', 'R', 'Divya R', 'divyar@gmail.com', '+91 93456 78901', 'Female', 'user123', 'TN 09 GH 3456', 'Honda City', 'Trichy, Tamil Nadu', 'Active', 1, 1),
(5, 'Arun', 'V', 'Arun V', 'arunv@gmail.com', '+91 94876 32109', 'Male', 'user123', 'TN 38 JK 7788', 'Mahindra XUV700', 'Salem, Tamil Nadu', 'Blocked', 1, 1);

-- =============================================================================
-- 2b. EMAIL OTP VERIFICATION TABLE (`email_otp`)
-- =============================================================================
DROP TABLE IF EXISTS `email_otp`;

CREATE TABLE `email_otp` (
    `otp_id` INT AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(100) NOT NULL,
    `otp_code` VARCHAR(10) NOT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    `verified` TINYINT(1) DEFAULT 0,
    `attempt_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 3. MECHANICS & WORKSHOPS TABLE (`mechanics`)
-- =============================================================================
DROP TABLE IF EXISTS `mechanics`;

CREATE TABLE `mechanics` (
    `mechanic_id` INT AUTO_INCREMENT PRIMARY KEY,
    `mechanic_code` VARCHAR(20) NOT NULL UNIQUE,
    `owner_name` VARCHAR(100) NOT NULL,
    `workshop_name` VARCHAR(100) NOT NULL,
    `specialization` VARCHAR(100) DEFAULT 'General Service',
    `phone` VARCHAR(20) NOT NULL,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `location` VARCHAR(100) NOT NULL,
    `address` VARCHAR(255) NOT NULL,
    `latitude` DOUBLE DEFAULT 13.0827,
    `longitude` DOUBLE DEFAULT 80.2707,
    `approval_status` ENUM('Pending', 'Approved', 'Blocked', 'Rejected') DEFAULT 'Pending',
    `blocked_reason` VARCHAR(255) DEFAULT NULL,
    `rejection_reason` VARCHAR(255) DEFAULT NULL,
    `is_available` BOOLEAN DEFAULT TRUE,
    `rating` DECIMAL(2,1) DEFAULT 4.8,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Sample Mechanics
INSERT INTO `mechanics` (`mechanic_id`, `mechanic_code`, `owner_name`, `workshop_name`, `specialization`, `phone`, `email`, `password`, `location`, `address`, `approval_status`, `blocked_reason`, `is_available`, `rating`) VALUES
(1, 'MEC001', 'Ravi Kumar', 'Ravi Auto Services', 'General Service', '+91 98765 43210', 'ravi@mechanic.com', 'mech123', 'Chennai', 'Anna Nagar, Chennai', 'Approved', NULL, TRUE, 4.9),
(2, 'MEC002', 'Sathish M', 'Sathish Auto Garage', 'Engine Repair', '+91 97894 56780', 'sathish@mechanic.com', 'mech123', 'Coimbatore', 'RS Puram, Coimbatore', 'Pending', NULL, TRUE, 4.7),
(3, 'MEC003', 'Arun Prakash', 'Arun Motors', 'Tyre & Wheel', '+91 96325 90120', 'arun@mechanic.com', 'mech123', 'Madurai', 'KK Nagar, Madurai', 'Approved', NULL, TRUE, 4.8),
(4, 'MEC004', 'Manoj R', 'Manoj Car Care', 'Battery Service', '+91 93456 78901', 'manoj@mechanic.com', 'mech123', 'Trichy', 'Thillai Nagar, Trichy', 'Approved', NULL, TRUE, 4.6),
(5, 'MEC005', 'Praveen K', 'Praveen Auto Works', 'Engine & AC', '+91 94876 32109', 'praveen@mechanic.com', 'mech123', 'Salem', 'Fairlands, Salem', 'Blocked', 'Policy Violation', FALSE, 4.2),
(6, 'MEC008', 'Ramesh D', 'Ramesh Car Care', 'General Service', '+91 93654 78901', 'ramesh@mechanic.com', 'mech123', 'Trichy', 'Cantonment, Trichy', 'Blocked', 'Multiple Complaints', FALSE, 4.1),
(7, 'MEC011', 'Kannan M', 'Kannan Auto Service', 'Tyre & Wheel', '+91 98765 21098', 'kannan@mechanic.com', 'mech123', 'Madurai', 'Simmakkal, Madurai', 'Blocked', 'Poor Service', FALSE, 3.9),
(8, 'MEC014', 'Suresh R', 'Suresh Motors', 'Battery Service', '+91 93456 78921', 'suresh@mechanic.com', 'mech123', 'Coimbatore', 'Gandhipuram, Coimbatore', 'Blocked', 'Invalid Documents', FALSE, 4.0),
(9, 'MEC017', 'Muthu V', 'Muthu Auto Garage', 'Engine Repair', '+91 97890 45678', 'muthu@mechanic.com', 'mech123', 'Chennai', 'Velachery, Chennai', 'Blocked', 'Account Misuse', FALSE, 3.8),
(10, 'MEC018', 'Karthik R', 'Karthik Auto Garage', 'General Service', '+91 98765 43210', 'karthik@mechanic.com', 'mech123', 'Chennai', 'Guindy, Chennai', 'Pending', NULL, TRUE, 4.5),
(11, 'MEC019', 'Vignesh S', 'Vignesh Motors', 'Engine Repair', '+91 97894 56780', 'vignesh@mechanic.com', 'mech123', 'Coimbatore', 'Peelamedu, Coimbatore', 'Pending', NULL, TRUE, 4.6),
(12, 'MEC020', 'Dinesh M', 'Dinesh Car Care', 'Tyre & Wheel', '+91 96325 90120', 'dinesh@mechanic.com', 'mech123', 'Madurai', 'Mattuthavani, Madurai', 'Pending', NULL, TRUE, 4.7),
(13, 'MEC021', 'Saravanan P', 'Saravanan Auto Services', 'Battery Service', '+91 93456 78901', 'saravanan@mechanic.com', 'mech123', 'Trichy', 'Central Bus Stand, Trichy', 'Pending', NULL, TRUE, 4.8),
(14, 'MEC022', 'Naveen K', 'Naveen Auto Works', 'Engine & AC', '+91 94876 32109', 'naveen@mechanic.com', 'mech123', 'Salem', 'New Bus Stand, Salem', 'Pending', NULL, TRUE, 4.9);

-- =============================================================================
-- 4. SERVICE REQUESTS TABLE (`service_requests`)
-- =============================================================================
DROP TABLE IF EXISTS `service_requests`;

CREATE TABLE `service_requests` (
    `request_id` INT AUTO_INCREMENT PRIMARY KEY,
    `request_code` VARCHAR(20) NOT NULL UNIQUE,
    `user_name` VARCHAR(100) NOT NULL,
    `user_code` VARCHAR(20) NOT NULL,
    `vehicle_number` VARCHAR(50) NOT NULL,
    `breakdown_issue` VARCHAR(100) NOT NULL,
    `location` VARCHAR(100) NOT NULL,
    `mechanic_name` VARCHAR(100) DEFAULT 'Unassigned',
    `mechanic_code` VARCHAR(20) DEFAULT NULL,
    `status` ENUM('Pending', 'Accepted', 'In Progress', 'Completed', 'Cancelled', 'Rejected') DEFAULT 'Pending',
    `requested_date` VARCHAR(50) DEFAULT NULL,
    `completed_date` VARCHAR(50) DEFAULT NULL,
    `assigned_date` VARCHAR(50) DEFAULT NULL,
    `in_progress_date` VARCHAR(50) DEFAULT NULL,
    `requested_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `assigned_at` TIMESTAMP NULL DEFAULT NULL,
    `in_progress_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Sample Service Requests
INSERT INTO `service_requests` (`request_id`, `request_code`, `user_name`, `user_code`, `vehicle_number`, `breakdown_issue`, `location`, `mechanic_name`, `mechanic_code`, `status`, `requested_date`) VALUES
(1, 'SR0456', 'Ragul M', 'USR012', 'TN45 AB 1234', 'Engine Overheat', 'Chennai', 'Karthik R', 'MEC018', 'In Progress', '20 Jan 2025, 02:15 PM'),
(2, 'SR0455', 'Divya S', 'USR078', 'TN38 CD 5678', 'Battery Issue', 'Coimbatore', 'Vignesh S', 'MEC019', 'Pending', '20 Jan 2025, 11:40 AM'),
(3, 'SR0454', 'Arun K', 'USR065', 'TN64 EF 9012', 'Tyre Puncture', 'Madurai', 'Dinesh M', 'MEC020', 'Completed', '19 Jan 2025, 06:20 PM'),
(4, 'SR0453', 'Sathish R', 'USR043', 'TN72 GH 3344', 'Engine Start Issue', 'Trichy', 'Saravanan P', 'MEC021', 'Cancelled', '19 Jan 2025, 10:05 AM'),
(5, 'SR0452', 'Keerthana V', 'USR021', 'TN45 JK 7788', 'AC Not Working', 'Salem', 'Naveen K', 'MEC022', 'Completed', '18 Jan 2025, 04:30 PM');

-- Verify Database and Tables
SELECT 'Database road_assistance_db created and seeded successfully!' AS status;
SELECT admin_id, username, password, full_name, role FROM admins;
