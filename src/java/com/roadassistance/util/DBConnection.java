package com.roadassistance.util;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * =============================================================================
 * On Road Vehicle Breakdown Assistance - Dedicated Database Connection Manager
 * =============================================================================
 * 
 * Centralized, cloud-ready database connection utility supporting:
 * - Aiven for MySQL (SSL Mode Required, custom dynamic port, cloud host)
 * - Render.com Environment Variables (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL)
 * - Single Connection String (DATABASE_URL, MYSQL_URL, DB_URL, AIVEN_MYSQL_URL)
 * - Local Development (XAMPP / WAMP / MySQL on localhost:3306)
 * - Auto-provisioning of all 8 core tables and default administrator credentials
 * =============================================================================
 */
public class DBConnection {

    // Database Configuration Defaults (for local development)
    private static final String DEFAULT_HOST = "localhost";
    private static final String DEFAULT_PORT = "3306";
    private static final String DEFAULT_DB_NAME = "road_assistance_db";
    private static final String DEFAULT_USER = "root";
    private static final String DEFAULT_PASS = ""; 

    private static volatile boolean initialized = false;

    // Parsed cache from single URI (DATABASE_URL / MYSQL_URL) if present
    private static String uriHost = null;
    private static String uriPort = null;
    private static String uriDbName = null;
    private static String uriUser = null;
    private static String uriPass = null;
    private static boolean uriParsed = false;

    // Load JDBC Driver upon class loading
    static {
        loadDriver();
        parseDbUriOnce();
    }

    /**
     * Loads the MySQL JDBC Driver safely with fallback support.
     */
    private static void loadDriver() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            try {
                Class.forName("com.mysql.jdbc.Driver");
            } catch (ClassNotFoundException ex) {
                System.err.println("[DBConnection] Notice: MySQL JDBC Driver not found in classpath: " + ex.getMessage());
            }
        }
    }

    /**
     * Safely reads environment variables or System properties.
     */
    private static String getEnvOrProp(String... keys) {
        for (String k : keys) {
            String prop = System.getProperty(k);
            if (prop != null && !prop.trim().isEmpty()) return prop.trim();
            String env = System.getenv(k);
            if (env != null && !env.trim().isEmpty()) return env.trim();
        }
        return null;
    }

    /**
     * Parses a single DATABASE_URL or MYSQL_URL if provided (e.g. from Aiven or Render).
     */
    private static synchronized void parseDbUriOnce() {
        if (uriParsed) return;
        uriParsed = true;
        String raw = getEnvOrProp("DATABASE_URL", "MYSQL_URL", "DB_URL", "AIVEN_MYSQL_URL");
        if (raw == null || raw.trim().isEmpty()) return;
        raw = raw.trim();
        try {
            String clean = raw;
            if (clean.startsWith("jdbc:mysql://")) {
                clean = clean.substring("jdbc:".length());
            }
            if (clean.startsWith("mysql://") || clean.startsWith("mysql2://")) {
                clean = "http://" + clean.substring(clean.indexOf("://") + 3);
            }
            URI uri = new URI(clean);
            if (uri.getHost() != null && !uri.getHost().trim().isEmpty()) {
                uriHost = uri.getHost().trim();
            }
            if (uri.getPort() > 0) {
                uriPort = String.valueOf(uri.getPort());
            }
            String path = uri.getPath();
            if (path != null && path.length() > 1) {
                String db = path.substring(1);
                if (db.contains("?")) db = db.substring(0, db.indexOf("?"));
                if (!db.trim().isEmpty()) uriDbName = db.trim();
            }
            String userInfo = uri.getUserInfo();
            if (userInfo != null && !userInfo.isEmpty()) {
                int colon = userInfo.indexOf(':');
                if (colon >= 0) {
                    uriUser = userInfo.substring(0, colon);
                    uriPass = userInfo.substring(colon + 1);
                } else {
                    uriUser = userInfo;
                }
            }
        } catch (Exception e) {
            System.err.println("[DBConnection] Notice parsing database URI: " + e.getMessage());
        }
    }

    /**
     * Retrieves the database host.
     */
    public static String getHost() {
        String val = getEnvOrProp("DB_HOST", "MYSQL_HOST", "MYSQLHOST");
        if (val != null) return val;
        if (uriHost != null) return uriHost;
        return DEFAULT_HOST;
    }

    /**
     * Retrieves the database port.
     */
    public static String getPort() {
        String val = getEnvOrProp("DB_PORT", "MYSQL_PORT", "MYSQLPORT");
        if (val != null) return val;
        if (uriPort != null) return uriPort;
        return DEFAULT_PORT;
    }

    /**
     * Retrieves the database name.
     */
    public static String getDbName() {
        String val = getEnvOrProp("DB_NAME", "MYSQL_DATABASE", "MYSQLDATABASE");
        if (val != null) return val;
        if (uriDbName != null) return uriDbName;
        return DEFAULT_DB_NAME;
    }

    /**
     * Retrieves the database username.
     */
    public static String getUser() {
        String val = getEnvOrProp("DB_USER", "MYSQL_USER", "MYSQLUSER");
        if (val != null) return val;
        if (uriUser != null) return uriUser;
        return DEFAULT_USER;
    }

    /**
     * Retrieves the database password.
     */
    public static String getPassword() {
        String val = getEnvOrProp("DB_PASSWORD", "MYSQL_PASSWORD", "MYSQLPASSWORD");
        if (val != null) return val;
        if (uriPass != null) return uriPass;
        return DEFAULT_PASS;
    }

    /**
     * Checks if SSL is enabled for MySQL connections.
     * Auto-detects remote cloud databases (such as Aiven) to require SSL.
     */
    public static boolean isSslEnabled() {
        String val = getEnvOrProp("DB_SSL", "MYSQL_SSL", "MYSQLSSL");
        if (val != null) {
            return "true".equalsIgnoreCase(val) || "required".equalsIgnoreCase(val) || "yes".equalsIgnoreCase(val) || "1".equals(val);
        }
        String host = getHost();
        return host != null && !host.equalsIgnoreCase("localhost") && !host.equals("127.0.0.1") && !host.equals("0.0.0.0");
    }

    /**
     * Returns the full JDBC URL for the application database.
     */
    public static String getJdbcUrl() {
        StringBuilder sb = new StringBuilder();
        sb.append("jdbc:mysql://").append(getHost()).append(":").append(getPort()).append("/").append(getDbName());
        sb.append("?allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8");
        if (isSslEnabled()) {
            sb.append("&useSSL=true&sslMode=REQUIRED&verifyServerCertificate=false");
        } else {
            sb.append("&useSSL=false");
        }
        return sb.toString();
    }

    /**
     * Returns the root JDBC URL for local database initialization.
     */
    private static String getRootJdbcUrl() {
        StringBuilder sb = new StringBuilder();
        sb.append("jdbc:mysql://").append(getHost()).append(":").append(getPort()).append("/");
        sb.append("?allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8");
        if (isSslEnabled()) {
            sb.append("&useSSL=true&sslMode=REQUIRED&verifyServerCertificate=false");
        } else {
            sb.append("&useSSL=false");
        }
        return sb.toString();
    }

    /**
     * Primary factory method to obtain an active Database Connection.
     * Can be called from any Servlet, DAO, Service, or JSP scriptlet:
     * 
     * <pre>
     * Connection conn = DBConnection.getConnection();
     * </pre>
     * 
     * @return Active java.sql.Connection
     * @throws SQLException If database connection fails
     */
    public static Connection getConnection() throws SQLException {
        loadDriver();
        if (!initialized) {
            initializeDatabase();
        }
        return DriverManager.getConnection(getJdbcUrl(), getUser(), getPassword());
    }

    /**
     * Tests if the database connection can be established successfully.
     * 
     * @return true if connection succeeds, false otherwise
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Safely closes a Connection.
     */
    public static void close(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException ignored) {}
        }
    }

    /**
     * Safely closes a Statement (or PreparedStatement).
     */
    public static void close(Statement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException ignored) {}
        }
    }

    /**
     * Safely closes a ResultSet.
     */
    public static void close(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException ignored) {}
        }
    }

    /**
     * Closes multiple AutoCloseable resources quietly without throwing exceptions.
     */
    public static void closeQuietly(AutoCloseable... closeables) {
        if (closeables == null) return;
        for (AutoCloseable c : closeables) {
            if (c != null) {
                try {
                    c.close();
                } catch (Exception ignored) {}
            }
        }
    }

    /**
     * Automatically ensures the database schema and default credentials exist.
     */
    private static synchronized void initializeDatabase() {
        if (initialized) return;

        // If running locally, attempt to create database if not exists
        if (!isSslEnabled() && "localhost".equalsIgnoreCase(getHost())) {
            Connection rootConn = null;
            Statement stmt = null;
            try {
                rootConn = DriverManager.getConnection(getRootJdbcUrl(), getUser(), getPassword());
                stmt = rootConn.createStatement();
                stmt.executeUpdate("CREATE DATABASE IF NOT EXISTS " + getDbName() + " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            } catch (Exception ignored) {
            } finally {
                closeQuietly(stmt, rootConn);
            }
        }

        // Verify and provision tables if not already created
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(getJdbcUrl(), getUser(), getPassword());
            createTablesIfNotExist(conn);
            initialized = true;
        } catch (Exception e) {
            System.err.println("[DBConnection] Table provisioning notice: " + e.getMessage());
            initialized = true; // prevent repeated retries on non-fatal errors
        } finally {
            closeQuietly(conn);
        }
    }

    /**
     * Auto-provisions all 8 core application tables with current schema.
     */
    private static void createTablesIfNotExist(Connection conn) {
        Statement stmt = null;
        try {
            stmt = conn.createStatement();

            // 1. Admins Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS admins (" +
                "admin_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "username VARCHAR(50) UNIQUE NOT NULL, " +
                "password VARCHAR(255) NOT NULL, " +
                "full_name VARCHAR(100) NOT NULL, " +
                "email VARCHAR(100) UNIQUE NOT NULL, " +
                "role VARCHAR(50) DEFAULT 'Administrator', " +
                "status VARCHAR(20) DEFAULT 'Active', " +
                "last_login TIMESTAMP NULL DEFAULT NULL, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
            );

            // 2. Users Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS users (" +
                "user_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "first_name VARCHAR(50) DEFAULT NULL, " +
                "last_name VARCHAR(50) DEFAULT NULL, " +
                "full_name VARCHAR(100) NOT NULL, " +
                "email VARCHAR(100) UNIQUE NOT NULL, " +
                "phone VARCHAR(20) NOT NULL, " +
                "gender VARCHAR(20) DEFAULT 'Prefer not to say', " +
                "dob DATE DEFAULT NULL, " +
                "password VARCHAR(255) NOT NULL, " +
                "vehicle_number VARCHAR(50) DEFAULT NULL, " +
                "vehicle_model VARCHAR(100) DEFAULT NULL, " +
                "address VARCHAR(255) DEFAULT NULL, " +
                "status ENUM('Active', 'Inactive', 'Blocked') DEFAULT 'Active', " +
                "email_verified TINYINT(1) DEFAULT 0, " +
                "terms_accepted TINYINT(1) DEFAULT 1, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
            );

            // 3. Mechanics Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS mechanics (" +
                "mechanic_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "mechanic_code VARCHAR(20) UNIQUE DEFAULT NULL, " +
                "first_name VARCHAR(60) DEFAULT NULL, " +
                "last_name VARCHAR(60) DEFAULT NULL, " +
                "gender VARCHAR(20) DEFAULT 'Male', " +
                "dob DATE DEFAULT NULL, " +
                "owner_name VARCHAR(100) NOT NULL, " +
                "workshop_name VARCHAR(100) NOT NULL, " +
                "shop_name VARCHAR(100) DEFAULT NULL, " +
                "shop_type VARCHAR(60) DEFAULT NULL, " +
                "years_of_experience VARCHAR(40) DEFAULT NULL, " +
                "opening_time VARCHAR(20) DEFAULT '09:00 AM', " +
                "closing_time VARCHAR(20) DEFAULT '07:00 PM', " +
                "shop_description VARCHAR(255) DEFAULT NULL, " +
                "specialization VARCHAR(100) DEFAULT 'General Service', " +
                "other_specialization VARCHAR(255) DEFAULT NULL, " +
                "phone VARCHAR(20) NOT NULL, " +
                "aadhaar_number VARCHAR(20) DEFAULT NULL, " +
                "aadhaar_card_doc VARCHAR(255) DEFAULT NULL, " +
                "id_proof_doc VARCHAR(255) DEFAULT NULL, " +
                "shop_contact_number VARCHAR(20) DEFAULT NULL, " +
                "email VARCHAR(100) UNIQUE NOT NULL, " +
                "email_verified TINYINT(1) DEFAULT 0, " +
                "password VARCHAR(255) NOT NULL, " +
                "location VARCHAR(100) NOT NULL, " +
                "address VARCHAR(255) NOT NULL, " +
                "address_line_1 VARCHAR(255) DEFAULT NULL, " +
                "address_line_2 VARCHAR(255) DEFAULT NULL, " +
                "city VARCHAR(100) DEFAULT NULL, " +
                "district VARCHAR(100) DEFAULT NULL, " +
                "state VARCHAR(100) DEFAULT 'Tamil Nadu', " +
                "pincode VARCHAR(10) DEFAULT NULL, " +
                "latitude DOUBLE DEFAULT 13.0827, " +
                "longitude DOUBLE DEFAULT 80.2707, " +
                "approval_status ENUM('Pending', 'Approved', 'Blocked', 'Rejected') DEFAULT 'Pending', " +
                "account_status VARCHAR(20) DEFAULT 'Active', " +
                "blocked_reason VARCHAR(255) DEFAULT NULL, " +
                "rejection_reason VARCHAR(255) DEFAULT NULL, " +
                "is_available TINYINT(1) DEFAULT 1, " +
                "rating DECIMAL(2,1) DEFAULT 4.8, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                "service_types VARCHAR(255) DEFAULT 'Car & Bike Service, Battery, General Repair', " +
                "reviews_count INT DEFAULT 100, " +
                "profile_image VARCHAR(255) DEFAULT 'find-mech-sathish.jpg', " +
                "status_text VARCHAR(30) DEFAULT 'Available', " +
                "blocked_date VARCHAR(50) DEFAULT NULL)"
            );

            // 4. Service Requests Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS service_requests (" +
                "request_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "request_code VARCHAR(20) UNIQUE NOT NULL, " +
                "user_id INT DEFAULT NULL, " +
                "user_name VARCHAR(100) NOT NULL, " +
                "user_code VARCHAR(20) NOT NULL, " +
                "vehicle_number VARCHAR(50) NOT NULL, " +
                "breakdown_issue VARCHAR(100) NOT NULL, " +
                "location VARCHAR(100) NOT NULL, " +
                "mechanic_name VARCHAR(100) DEFAULT 'Unassigned', " +
                "mechanic_code VARCHAR(20) DEFAULT NULL, " +
                "status VARCHAR(30) DEFAULT 'Pending', " +
                "requested_date VARCHAR(50) DEFAULT NULL, " +
                "completed_date VARCHAR(50) DEFAULT NULL, " +
                "assigned_date VARCHAR(50) DEFAULT NULL, " +
                "in_progress_date VARCHAR(50) DEFAULT NULL, " +
                "requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "assigned_at TIMESTAMP NULL DEFAULT NULL, " +
                "in_progress_at TIMESTAMP NULL DEFAULT NULL, " +
                "completed_at TIMESTAMP NULL DEFAULT NULL, " +
                "service_cost DECIMAL(10,2) DEFAULT NULL, " +
                "rating DECIMAL(2,1) DEFAULT NULL, " +
                "latitude DOUBLE DEFAULT NULL, " +
                "longitude DOUBLE DEFAULT NULL, " +
                "additional_details TEXT DEFAULT NULL, " +
                "vehicle_brand VARCHAR(100) DEFAULT NULL, " +
                "vehicle_model VARCHAR(100) DEFAULT NULL, " +
                "vehicle_type VARCHAR(50) DEFAULT 'Car', " +
                "vehicle_image VARCHAR(255) DEFAULT NULL, " +
                "request_type VARCHAR(30) DEFAULT 'Common', " +
                "broadcast_radius INT DEFAULT 15, " +
                "rating_comments TEXT DEFAULT NULL)"
            );

            // 5. Email OTP Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS email_otp (" +
                "otp_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "email VARCHAR(100) NOT NULL, " +
                "otp_code VARCHAR(10) NOT NULL, " +
                "expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                "verified TINYINT(1) DEFAULT 0, " +
                "attempt_count INT DEFAULT 0, " +
                "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, " +
                "KEY email_idx (email))"
            );

            // 6. User Vehicles Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS user_vehicles (" +
                "vehicle_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "user_id INT NOT NULL, " +
                "vehicle_number VARCHAR(50) NOT NULL, " +
                "vehicle_brand VARCHAR(100) DEFAULT NULL, " +
                "vehicle_model VARCHAR(100) NOT NULL, " +
                "manufacturing_year INT DEFAULT NULL, " +
                "vehicle_type VARCHAR(50) DEFAULT 'Four Wheeler', " +
                "fuel_type VARCHAR(30) DEFAULT 'Petrol', " +
                "is_primary TINYINT(1) DEFAULT 0, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "vehicle_status VARCHAR(30) DEFAULT 'Active', " +
                "registration_date VARCHAR(50) DEFAULT 'May 10, 2023', " +
                "insurance_expiry VARCHAR(50) DEFAULT 'May 09, 2026', " +
                "insurance_provider VARCHAR(100) DEFAULT NULL, " +
                "insurance_policy_number VARCHAR(100) DEFAULT NULL, " +
                "vehicle_image VARCHAR(255) DEFAULT NULL, " +
                "vehicle_photos TEXT DEFAULT NULL, " +
                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                "KEY user_id_idx (user_id))"
            );

            // 7. Mechanic Specializations Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS mechanic_specializations (" +
                "specialization_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "mechanic_id INT NOT NULL, " +
                "specialization_name VARCHAR(100) NOT NULL, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "UNIQUE KEY unique_mech_spec (mechanic_id, specialization_name))"
            );

            // 8. Mechanic Shop Photos Table
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS mechanic_shop_photos (" +
                "photo_id INT PRIMARY KEY AUTO_INCREMENT, " +
                "mechanic_id INT NOT NULL, " +
                "photo_path VARCHAR(255) NOT NULL, " +
                "original_filename VARCHAR(255) NOT NULL, " +
                "uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "KEY mech_photo_idx (mechanic_id))"
            );

            // Seed Default Admin Accounts
            stmt.executeUpdate(
                "INSERT INTO admins (username, password, full_name, email, role, status) " +
                "VALUES ('admin', '123', 'Administrator', 'admin@roadassistance.com', 'Super Administrator', 'Active') " +
                "ON DUPLICATE KEY UPDATE password = VALUES(password)"
            );

            stmt.executeUpdate(
                "INSERT INTO admins (username, password, full_name, email, role, status) " +
                "VALUES ('superadmin', 'admin123', 'System Controller', 'support@roadassistance.com', 'Platform Admin', 'Active') " +
                "ON DUPLICATE KEY UPDATE password = VALUES(password)"
            );

        } catch (Exception e) {
            System.err.println("[DBConnection] Notice provisioning default schema: " + e.getMessage());
        } finally {
            closeQuietly(stmt);
        }
    }

    /**
     * Diagnostic CLI runner to verify connection parameters and connectivity.
     */
    public static void main(String[] args) {
        System.out.println("=================================================");
        System.out.println("Testing DBConnection Diagnostic Tool");
        System.out.println("=================================================");
        System.out.println("Host:      " + getHost());
        System.out.println("Port:      " + getPort());
        System.out.println("Database:  " + getDbName());
        System.out.println("User:      " + getUser());
        System.out.println("SSL Mode:  " + (isSslEnabled() ? "REQUIRED" : "DISABLED"));
        System.out.println("JDBC URL:  " + getJdbcUrl());
        System.out.println("Testing connection...");
        try (Connection conn = getConnection()) {
            if (conn != null && !conn.isClosed()) {
                System.out.println("SUCCESS: Connected to database successfully!");
                System.out.println("Catalog:   " + conn.getCatalog());
            } else {
                System.out.println("FAILURE: Connection returned null or closed.");
            }
        } catch (Exception e) {
            System.err.println("ERROR: Connection failed: " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("=================================================");
    }
}
