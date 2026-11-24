-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 17, 2026 at 11:54 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `road_assistance_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` varchar(50) DEFAULT 'Administrator',
  `status` varchar(20) DEFAULT 'Active',
  `last_login` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `username`, `password`, `full_name`, `email`, `role`, `status`, `last_login`, `created_at`) VALUES
(1, 'admin', '123', 'Administrator', 'admin@roadassistance.com', 'Super Administrator', 'Active', '2026-11-17 10:45:59', '2026-11-03 10:58:28'),
(46, 'superadmin', 'admin123', 'System Controller', 'support@roadassistance.com', 'Platform Admin', 'Active', NULL, '2026-11-04 07:09:33');

-- --------------------------------------------------------

--
-- Table structure for table `email_otp`
--

CREATE TABLE `email_otp` (
  `otp_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp_code` varchar(10) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `verified` tinyint(1) DEFAULT 0,
  `attempt_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_otp`
--

INSERT INTO `email_otp` (`otp_id`, `email`, `otp_code`, `expires_at`, `verified`, `attempt_count`, `created_at`) VALUES
(22, 'madhavan0507p@gmail.com', '724964', '2026-11-13 15:05:04', 2, 0, '2026-11-13 15:04:18'),
(23, 'madhavan0507p@gmail.com', '840210', '2026-11-13 15:13:24', 2, 0, '2026-11-13 15:05:04'),
(24, 'sathish@gmail.com', '757416', '2026-11-13 15:15:29', 2, 0, '2026-11-13 15:05:43'),
(25, 'madhavan0507p@gmail.com', '258306', '2026-11-13 15:15:06', 2, 0, '2026-11-13 15:13:24'),
(26, 'madhavan0507p@gmail.com', '104071', '2026-11-14 04:56:38', 2, 0, '2026-11-13 15:15:06'),
(27, 'sathish@gmail.com', '629168', '2026-11-13 09:50:29', 0, 0, '2026-11-13 15:15:29'),
(28, 'madhavan0507p@gmail.com', '564030', '2026-11-14 04:58:05', 2, 0, '2026-11-14 04:56:38'),
(29, 'madhavan0507p@gmail.com', '144797', '2026-11-14 05:28:13', 2, 0, '2026-11-14 04:58:05'),
(30, 'mathivanan292005@gmail.com', '185247', '2026-11-14 07:28:22', 2, 0, '2026-11-14 05:01:40'),
(31, 'madhavan0507p@gmail.com', '417230', '2026-11-14 06:35:39', 2, 0, '2026-11-14 05:28:13'),
(32, 'madhavan0507p@gmail.com', '406119', '2026-11-14 06:36:09', 2, 0, '2026-11-14 06:35:39'),
(33, 'madhavan0507p@gmail.com', '660818', '2026-11-14 06:38:31', 2, 0, '2026-11-14 06:36:09'),
(34, 'madhavan0507p@gmail.com', '340323', '2026-11-14 06:39:00', 2, 0, '2026-11-14 06:38:31'),
(35, 'madhavan0507p@gmail.com', '131569', '2026-11-14 06:39:25', 1, 0, '2026-11-14 06:39:00'),
(36, 'madhavan0507p@gmail.com', '840868', '2026-11-14 06:44:28', 2, 0, '2026-11-14 06:43:31'),
(37, 'madhavan0507p@gmail.com', '843918', '2026-11-14 06:44:44', 1, 0, '2026-11-14 06:44:28'),
(38, 'mathivanan292005@gmail.com', '455501', '2026-11-14 09:58:01', 2, 0, '2026-11-14 07:28:22'),
(39, 'madhavan0507p@gmail.com', '120172', '2026-11-14 07:45:50', 1, 0, '2026-11-14 07:45:33'),
(40, 'testmech_fix_check@gmail.com', '424415', '2026-11-14 08:26:26', 1, 0, '2026-11-14 08:26:22'),
(45, 'mechtest_browser@example.com', '279325', '2026-11-14 08:34:55', 1, 0, '2026-11-14 08:34:52'),
(50, 'madhavan0507p@gmail.com', '781410', '2026-11-14 09:00:13', 1, 0, '2026-11-14 08:59:51'),
(51, 'mechtesttimer1794647079835@example.com', '764236', '2026-11-14 03:36:44', 0, 0, '2026-11-14 09:04:44'),
(52, 'mechtesttimer1794647117912@example.com', '669368', '2026-11-14 03:37:23', 0, 0, '2026-11-14 09:05:23'),
(53, 'mechtesttimer1794647334967@gmail.com', '944285', '2026-11-14 03:40:59', 0, 0, '2026-11-14 09:08:59'),
(54, 'mathivanan292005@gmail.com', '124646', '2026-11-14 09:58:35', 1, 0, '2026-11-14 09:58:01'),
(55, 'madhavan0507p@gmail.com', '571215', '2026-11-17 05:09:32', 1, 0, '2026-11-17 05:09:09');

-- --------------------------------------------------------

--
-- Table structure for table `mechanics`
--

CREATE TABLE `mechanics` (
  `mechanic_id` int(11) NOT NULL,
  `mechanic_code` varchar(20) DEFAULT NULL,
  `first_name` varchar(60) DEFAULT NULL,
  `last_name` varchar(60) DEFAULT NULL,
  `gender` varchar(20) DEFAULT 'Male',
  `dob` date DEFAULT NULL,
  `owner_name` varchar(100) NOT NULL,
  `workshop_name` varchar(100) NOT NULL,
  `shop_name` varchar(100) DEFAULT NULL,
  `shop_type` varchar(60) DEFAULT NULL,
  `years_of_experience` varchar(40) DEFAULT NULL,
  `opening_time` varchar(20) DEFAULT '09:00 AM',
  `closing_time` varchar(20) DEFAULT '07:00 PM',
  `shop_description` varchar(255) DEFAULT NULL,
  `specialization` varchar(100) DEFAULT 'General Service',
  `other_specialization` varchar(255) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `aadhaar_number` varchar(20) DEFAULT NULL,
  `aadhaar_card_doc` varchar(255) DEFAULT NULL,
  `id_proof_doc` varchar(255) DEFAULT NULL,
  `shop_contact_number` varchar(20) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `email_verified` tinyint(1) DEFAULT 0,
  `password` varchar(255) NOT NULL,
  `location` varchar(100) NOT NULL,
  `address` varchar(255) NOT NULL,
  `address_line_1` varchar(255) DEFAULT NULL,
  `address_line_2` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT 'Tamil Nadu',
  `pincode` varchar(10) DEFAULT NULL,
  `latitude` double DEFAULT 13.0827,
  `longitude` double DEFAULT 80.2707,
  `approval_status` enum('Pending','Approved','Blocked','Rejected') DEFAULT 'Pending',
  `account_status` varchar(20) DEFAULT 'Active',
  `blocked_reason` varchar(255) DEFAULT NULL,
  `rejection_reason` varchar(255) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT 1,
  `rating` decimal(2,1) DEFAULT 4.8,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `service_types` varchar(255) DEFAULT 'Car & Bike Service, Battery, General Repair',
  `reviews_count` int(11) DEFAULT 100,
  `profile_image` varchar(255) DEFAULT 'find-mech-sathish.jpg',
  `status_text` varchar(30) DEFAULT 'Available',
  `blocked_date` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `mechanics`
--

INSERT INTO `mechanics` (`mechanic_id`, `mechanic_code`, `first_name`, `last_name`, `gender`, `dob`, `owner_name`, `workshop_name`, `shop_name`, `shop_type`, `years_of_experience`, `opening_time`, `closing_time`, `shop_description`, `specialization`, `other_specialization`, `phone`, `aadhaar_number`, `aadhaar_card_doc`, `id_proof_doc`, `shop_contact_number`, `email`, `email_verified`, `password`, `location`, `address`, `address_line_1`, `address_line_2`, `city`, `district`, `state`, `pincode`, `latitude`, `longitude`, `approval_status`, `account_status`, `blocked_reason`, `rejection_reason`, `is_available`, `rating`, `created_at`, `updated_at`, `service_types`, `reviews_count`, `profile_image`, `status_text`, `blocked_date`) VALUES
(2, 'MEC002', 'Sathish', 'K', 'Male', '1995-06-15', 'Sathish K', 'Sathish Garage', 'Sathish Garage', 'Multi-brand Garage', 'Less than 1 year', '09:00 AM', '07:00 PM', 'Expert Multi-brand Car & Bike Assistance with Mobile Units', 'AC Service', '', '9876543210', '548291847291', 'sample_aadhaar_card.png', 'sample_id_proof.png', '9865776456', 'mathivanan292005@gmail.com', 0, '123', 'Podanur', 'Ward 85, Podanur', 'Ward 85', '', 'Podanur', 'Coimbatore', 'Tamil Nadu', '641001', 10.987284, 76.955666, 'Approved', 'Blocked', 'Multiple customer complaints regarding overcharging or improper repairs.', NULL, 1, 4.9, '2026-11-03 04:30:00', '2026-11-17 07:58:44', 'Engine Repair, Battery Service, Electrical Repair, Towing Assistance', 159, 'find-mech-sathish.jpg', 'Available', '17-11-2026, 11:50 AM'),
(40, 'MEC040', 'Mechanic', 'M', 'Male', '2008-10-28', 'Mechanic M', 'Feanix Work Shop', 'Feanix Work Shop', 'Two Wheeler Service', 'Less than 1 year', '09:00 AM', '07:00 PM', '', 'Two Wheeler Repair', NULL, '6383112065', '548291847291', 'sample_aadhaar_card.png', 'sample_id_proof.png', '6383112061', 'madhavan0507@gmail.com', 1, '1234', 'Coimbatore', 'Sri Sairam towers,NSR road,, saibaba colony, Coimbatore., Coimbatore, Coimbatore, Tamil Nadu - 621306', 'Sri Sairam towers,NSR road,', 'saibaba colony, Coimbatore.', 'Coimbatore', 'Coimbatore', 'Tamil Nadu', '621306', 11.0268, 76.9507, 'Approved', 'Active', NULL, NULL, 1, 4.8, '2026-11-14 09:01:27', '2026-11-17 05:08:29', 'Two Wheeler Service, Engine Repair, Battery, General Repair', 100, 'find-mech-sathish.jpg', 'Available', NULL),
(41, 'MEC041', 'Machanic', 'B', 'Male', '2008-11-05', 'Machanic B', 'Jerry  Work Shop', 'Jerry  Work Shop', 'Four Wheeler Service', 'Less than 1 year', '09:00 AM', '07:00 PM', 'We have specialist mechanics', 'Engine Repair', NULL, '9368524847', '548291847291', 'sample_aadhaar_card.png', 'sample_id_proof.png', '7898234567', 'mathivanan2925@gmail.com', 1, 'Mathivanan@0', 'Coimbatore', 'Velandipalayam, Ward 13, Coimbatore, Coimbatore, Tamil Nadu - 641001', 'Velandipalayam', 'Ward 13', 'Coimbatore', 'Coimbatore', 'Tamil Nadu', '641001', 11.0279, 76.9327, 'Blocked', 'Blocked', 'Violation of platform code of conduct and automotive safety policies.', NULL, 0, 4.8, '2026-11-14 10:00:48', '2026-11-17 07:31:53', 'Car & Bike Service, Battery, General Repair', 100, 'find-mech-sathish.jpg', 'Available', '17-11-2026, 01:01 PM'),
(42, 'MEC042', 'Suresh Kumar', 'S', 'Male', '2008-11-05', 'Suresh Kumar S', 'Godwin Garage', 'Godwin Garage', 'Four Wheeler Service', 'Less than 1 year', '09:00 AM', '07:00 PM', 'We have well experiened workers', 'Engine Repair', NULL, '6383112875', '617478291250', '/uploads/mechanic_documents/aadhaar_1794892268547_85578ca5.jpg', '/uploads/mechanic_documents/idproof_1794892268549_2f2ffe31.jpg', '7898234567', 'madhavan0507p@gmail.com', 1, '12', 'Coimbatore', 'KTM, NSR Road, Saibaba Colony, Coimbatore, Coimbatore, Tamil Nadu - 641001', 'KTM, NSR Road', 'Saibaba Colony', 'Coimbatore', 'Coimbatore', 'Tamil Nadu', '641001', 11.0268, 76.9507, 'Pending', 'Active', NULL, NULL, 0, 4.8, '2026-11-17 05:11:08', '2026-11-17 05:17:56', 'Car & Bike Service, Battery, General Repair', 100, 'find-mech-sathish.jpg', 'Available', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `mechanic_shop_photos`
--

CREATE TABLE `mechanic_shop_photos` (
  `photo_id` int(11) NOT NULL,
  `mechanic_id` int(11) NOT NULL,
  `photo_path` varchar(255) NOT NULL,
  `original_filename` varchar(255) NOT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `mechanic_shop_photos`
--

INSERT INTO `mechanic_shop_photos` (`photo_id`, `mechanic_id`, `photo_path`, `original_filename`, `uploaded_at`) VALUES
(11, 42, '/uploads/mechanic_photos/shop_1794892268541_dd4b9e60.webp', 'shop_1794892268541_dd4b9e60.webp', '2026-11-17 05:11:08'),
(12, 2, '/uploads/mechanic_photos/shop_2_1794902133223_wp9153425.webp', 'wp9153425.webp', '2026-11-17 07:55:33');

-- --------------------------------------------------------

--
-- Table structure for table `mechanic_specializations`
--

CREATE TABLE `mechanic_specializations` (
  `specialization_id` int(11) NOT NULL,
  `mechanic_id` int(11) NOT NULL,
  `specialization_name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `mechanic_specializations`
--

INSERT INTO `mechanic_specializations` (`specialization_id`, `mechanic_id`, `specialization_name`, `created_at`) VALUES
(22, 40, 'Engine Repair', '2026-11-14 09:01:27'),
(23, 40, 'Battery Service', '2026-11-14 09:01:27'),
(24, 40, 'Clutch & Gear', '2026-11-14 09:01:27'),
(25, 40, 'Brake Service', '2026-11-14 09:01:27'),
(26, 41, 'Engine Repair', '2026-11-14 10:00:48'),
(27, 41, 'Battery Service', '2026-11-14 10:00:48'),
(28, 41, 'Tyre / Puncture', '2026-11-14 10:00:48'),
(29, 41, 'Brake Service', '2026-11-14 10:00:48'),
(30, 41, 'Electrical Repair', '2026-11-14 10:00:48'),
(31, 42, 'Engine Repair', '2026-11-17 05:11:08'),
(32, 42, 'Battery Service', '2026-11-17 05:11:08'),
(33, 42, 'Tyre / Puncture', '2026-11-17 05:11:08'),
(34, 42, 'Electrical Repair', '2026-11-17 05:11:08');

-- --------------------------------------------------------

--
-- Table structure for table `service_requests`
--

CREATE TABLE `service_requests` (
  `request_id` int(11) NOT NULL,
  `request_code` varchar(20) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(100) NOT NULL,
  `user_code` varchar(20) NOT NULL,
  `vehicle_number` varchar(50) NOT NULL,
  `breakdown_issue` varchar(100) NOT NULL,
  `location` varchar(100) NOT NULL,
  `mechanic_name` varchar(100) DEFAULT 'Unassigned',
  `mechanic_code` varchar(20) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'Pending',
  `requested_date` varchar(50) DEFAULT NULL,
  `completed_date` varchar(50) DEFAULT NULL,
  `assigned_date` varchar(50) DEFAULT NULL,
  `in_progress_date` varchar(50) DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `assigned_at` timestamp NULL DEFAULT NULL,
  `in_progress_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `service_cost` decimal(10,2) DEFAULT NULL,
  `rating` decimal(2,1) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `additional_details` text DEFAULT NULL,
  `vehicle_brand` varchar(100) DEFAULT NULL,
  `vehicle_model` varchar(100) DEFAULT NULL,
  `vehicle_type` varchar(50) DEFAULT 'Car',
  `vehicle_image` varchar(255) DEFAULT NULL,
  `request_type` varchar(30) DEFAULT 'Common',
  `broadcast_radius` int(11) DEFAULT 15,
  `rating_comments` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `service_requests`
--

INSERT INTO `service_requests` (`request_id`, `request_code`, `user_id`, `user_name`, `user_code`, `vehicle_number`, `breakdown_issue`, `location`, `mechanic_name`, `mechanic_code`, `status`, `requested_date`, `completed_date`, `assigned_date`, `in_progress_date`, `requested_at`, `assigned_at`, `in_progress_at`, `completed_at`, `service_cost`, `rating`, `latitude`, `longitude`, `additional_details`, `vehicle_brand`, `vehicle_model`, `vehicle_type`, `vehicle_image`, `request_type`, `broadcast_radius`, `rating_comments`) VALUES
(231, 'SR0465', 12, 'Ravi Kumar', 'USR012', 'TN 45 CY 6778', 'Engine Overheating', 'NSR Road, Coimbatore - 641001', 'Sathish Garage', 'MEC002', 'Completed', '17-11-2026 · 03:22 PM', '17-11-2026 · 03:30 PM', '17-11-2026 · 03:29 PM', '17-11-2026 · 03:29 PM', '2026-11-17 09:52:57', '2026-11-17 09:59:33', '2026-11-17 09:59:56', '2026-11-17 10:00:12', NULL, NULL, 11.026798, 76.949955, ' | [Update: Work Completed]', 'Royal Enfield', 'Classic 350', 'Two Wheeler', 'vehicle-pulsar-lg.jpg', 'Common', 10, NULL),
(232, 'SR0466', 12, 'Ravi Kumar', 'USR012', 'TN 45 CY 6778', 'Engine Overheating', '6th Street, Coimbatore - 641001', 'Feanix Work Shop', 'MEC040', 'Pending', '17-11-2026 · 03:33 PM', NULL, NULL, NULL, '2026-11-17 10:03:06', NULL, NULL, NULL, NULL, NULL, 11.032517, 76.944298, '', 'Royal Enfield', 'Classic 350', 'Two Wheeler', 'vehicle-pulsar-lg.jpg', 'Specific', 10, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `gender` varchar(20) DEFAULT 'Prefer not to say',
  `dob` date DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `vehicle_number` varchar(50) DEFAULT NULL,
  `vehicle_model` varchar(100) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `status` enum('Active','Inactive','Blocked') DEFAULT 'Active',
  `email_verified` tinyint(1) DEFAULT 0,
  `terms_accepted` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `first_name`, `last_name`, `full_name`, `email`, `phone`, `gender`, `dob`, `password`, `vehicle_number`, `vehicle_model`, `address`, `status`, `email_verified`, `terms_accepted`, `created_at`) VALUES
(12, 'Ravi', 'Kumar', 'Ravi Kumar', 'madhavan0507p@gmail.com', '9875823977', 'Male', '1998-08-20', '123', NULL, NULL, '45, Green Avenue, Saibaba Colony, Coimbatore - 641011', 'Active', 1, 1, '2026-11-04 04:49:30');

-- --------------------------------------------------------

--
-- Table structure for table `user_vehicles`
--

CREATE TABLE `user_vehicles` (
  `vehicle_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `vehicle_number` varchar(50) NOT NULL,
  `vehicle_brand` varchar(100) DEFAULT NULL,
  `vehicle_model` varchar(100) NOT NULL,
  `manufacturing_year` int(11) DEFAULT NULL,
  `vehicle_type` varchar(50) DEFAULT 'Four Wheeler',
  `fuel_type` varchar(30) DEFAULT 'Petrol',
  `is_primary` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `vehicle_status` varchar(30) DEFAULT 'Active',
  `registration_date` varchar(50) DEFAULT 'May 10, 2023',
  `insurance_expiry` varchar(50) DEFAULT 'May 09, 2026',
  `insurance_provider` varchar(100) DEFAULT NULL,
  `insurance_policy_number` varchar(100) DEFAULT NULL,
  `vehicle_image` varchar(255) DEFAULT NULL,
  `vehicle_photos` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_vehicles`
--

INSERT INTO `user_vehicles` (`vehicle_id`, `user_id`, `vehicle_number`, `vehicle_brand`, `vehicle_model`, `manufacturing_year`, `vehicle_type`, `fuel_type`, `is_primary`, `created_at`, `vehicle_status`, `registration_date`, `insurance_expiry`, `insurance_provider`, `insurance_policy_number`, `vehicle_image`, `vehicle_photos`, `updated_at`) VALUES
(125, 12, 'TN 45 BT 6229', 'BMW', 'BMW M5 Competition', 2022, 'Car', 'Diesel', 1, '2026-11-13 05:27:15', 'Active', '2026-08-16', '2031-11-13', 'Bajaj Allianz General Insurance', 'POl3464328761528', 'veh_12_1794547635886_1.jpg', '[\"veh_12_1794547635886_1.jpg\",\"veh_12_1794547635890_2.jpg\",\"veh_12_1794547635896_3.jpg\"]', '2026-11-14 11:49:05'),
(131, 12, 'TN 45 CY 6778', 'Royal Enfield', 'Classic 350', NULL, 'Two Wheeler', 'Petrol', 0, '2026-11-15 16:52:00', 'Active', 'May 10, 2023', 'May 09, 2026', NULL, NULL, 'vehicle-pulsar-lg.jpg', NULL, '2026-11-15 16:52:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `email_otp`
--
ALTER TABLE `email_otp`
  ADD PRIMARY KEY (`otp_id`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `mechanics`
--
ALTER TABLE `mechanics`
  ADD PRIMARY KEY (`mechanic_id`),
  ADD UNIQUE KEY `mechanic_code` (`mechanic_code`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `mechanic_shop_photos`
--
ALTER TABLE `mechanic_shop_photos`
  ADD PRIMARY KEY (`photo_id`),
  ADD KEY `mechanic_id` (`mechanic_id`);

--
-- Indexes for table `mechanic_specializations`
--
ALTER TABLE `mechanic_specializations`
  ADD PRIMARY KEY (`specialization_id`),
  ADD UNIQUE KEY `unique_mech_spec` (`mechanic_id`,`specialization_name`);

--
-- Indexes for table `service_requests`
--
ALTER TABLE `service_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD UNIQUE KEY `request_code` (`request_code`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_vehicles`
--
ALTER TABLE `user_vehicles`
  ADD PRIMARY KEY (`vehicle_id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=365;

--
-- AUTO_INCREMENT for table `email_otp`
--
ALTER TABLE `email_otp`
  MODIFY `otp_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT for table `mechanics`
--
ALTER TABLE `mechanics`
  MODIFY `mechanic_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `mechanic_shop_photos`
--
ALTER TABLE `mechanic_shop_photos`
  MODIFY `photo_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `mechanic_specializations`
--
ALTER TABLE `mechanic_specializations`
  MODIFY `specialization_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `service_requests`
--
ALTER TABLE `service_requests`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=233;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `user_vehicles`
--
ALTER TABLE `user_vehicles`
  MODIFY `vehicle_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=132;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `mechanic_shop_photos`
--
ALTER TABLE `mechanic_shop_photos`
  ADD CONSTRAINT `mechanic_shop_photos_ibfk_1` FOREIGN KEY (`mechanic_id`) REFERENCES `mechanics` (`mechanic_id`) ON DELETE CASCADE;

--
-- Constraints for table `mechanic_specializations`
--
ALTER TABLE `mechanic_specializations`
  ADD CONSTRAINT `mechanic_specializations_ibfk_1` FOREIGN KEY (`mechanic_id`) REFERENCES `mechanics` (`mechanic_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
