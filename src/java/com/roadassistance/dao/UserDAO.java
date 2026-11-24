package com.roadassistance.dao;

import com.roadassistance.model.User;
import com.roadassistance.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    // Fallback in-memory users for offline database environments
    private static final List<User> DEMO_USERS = new ArrayList<User>();

    static {
        DEMO_USERS.add(new User(1, "Raj", "Kumar", "rajkumar@gmail.com", "+91 98765 43210", "Male", "user123", "Anna Nagar, Chennai", "Active", true));
        DEMO_USERS.add(new User(2, "Karthik", "S", "karthiks@gmail.com", "+91 97894 56780", "Male", "user123", "RS Puram, Coimbatore", "Inactive", true));
        DEMO_USERS.add(new User(3, "Praveen", "M", "praveenm@gmail.com", "+91 96325 90120", "Male", "user123", "KK Nagar, Madurai", "Active", true));
        DEMO_USERS.add(new User(4, "Divya", "R", "divyar@gmail.com", "+91 93456 78901", "Female", "user123", "Thillai Nagar, Trichy", "Active", true));
        DEMO_USERS.add(new User(5, "Arun", "V", "arunv@gmail.com", "+91 94876 32109", "Male", "user123", "Fairlands, Salem", "Blocked", true));
    }

    public User authenticate(String emailOrPhone, String password) {
        if (emailOrPhone == null || password == null) return null;
        String cleanInput = emailOrPhone.trim();
        String cleanPassword = password.trim();
        if (cleanInput.isEmpty() || cleanPassword.isEmpty()) return null;

        // Clean input for matching: strip spaces and leading +91 if present
        String digitsOnly = cleanInput.replaceAll("[^0-9]", "");
        if (digitsOnly.startsWith("91") && digitsOnly.length() == 12) {
            digitsOnly = digitsOnly.substring(2);
        }

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT user_id, first_name, last_name, full_name, email, phone, gender, dob, password, address, status, email_verified, terms_accepted, created_at " +
                             "FROM users WHERE (LOWER(email) = LOWER(?) OR REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+91', '') = ? OR phone = ?) AND password = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanInput);
                ps.setString(2, digitsOnly);
                ps.setString(3, cleanInput);
                ps.setString(4, cleanPassword);
                rs = ps.executeQuery();
                if (rs.next()) {
                    User u = new User();
                    u.setUserId(rs.getInt("user_id"));
                    u.setFirstName(rs.getString("first_name"));
                    u.setLastName(rs.getString("last_name"));
                    u.setFullName(rs.getString("full_name"));
                    u.setEmail(rs.getString("email"));
                    u.setPhone(rs.getString("phone"));
                    u.setGender(rs.getString("gender"));
                    u.setDob(rs.getString("dob"));
                    u.setPassword(rs.getString("password"));
                    u.setAddress(rs.getString("address"));
                    u.setStatus(rs.getString("status"));
                    u.setEmailVerified(rs.getInt("email_verified") == 1);
                    u.setTermsAccepted(rs.getInt("terms_accepted") == 1);
                    java.sql.Timestamp ts = rs.getTimestamp("created_at");
                    u.setCreatedAt(ts != null ? ts.toString() : "");
                    return u;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO authenticate DB query notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        // Check fallback demo accounts if database is empty/offline
        String normInput = cleanInput.replaceAll("[\\s-]", "");
        for (User u : DEMO_USERS) {
            String normPhone = u.getPhone() != null ? u.getPhone().replaceAll("[\\s-]", "") : "";
            if ((u.getEmail().equalsIgnoreCase(cleanInput) || normPhone.equals(normInput) || (u.getPhone() != null && u.getPhone().equalsIgnoreCase(cleanInput))) 
                    && u.getPassword().equals(cleanPassword)) {
                return u;
            }
        }

        return null;
    }

    public boolean isEmailRegistered(String email) {
        if (email == null || email.trim().isEmpty()) return false;
        String cleanEmail = email.trim().toLowerCase();

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT user_id FROM users WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();
                if (rs.next()) {
                    return true;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO isEmailRegistered error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (User u : DEMO_USERS) {
            if (u.getEmail().equalsIgnoreCase(cleanEmail)) return true;
        }

        return false;
    }

    public boolean isPhoneRegistered(String phone) {
        if (phone == null || phone.trim().isEmpty()) return false;
        String cleanPhone = phone.replaceAll("[^0-9]", "");
        if (cleanPhone.startsWith("91") && cleanPhone.length() == 12) {
            cleanPhone = cleanPhone.substring(2);
        }

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT user_id FROM users WHERE REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+91', '') = ? OR REPLACE(REPLACE(phone, ' ', ''), '-', '') = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanPhone);
                ps.setString(2, cleanPhone);
                rs = ps.executeQuery();
                if (rs.next()) {
                    return true;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO isPhoneRegistered error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (User u : DEMO_USERS) {
            String norm = u.getPhone() != null ? u.getPhone().replaceAll("[^0-9]", "") : "";
            if (norm.startsWith("91") && norm.length() == 12) norm = norm.substring(2);
            if (norm.equals(cleanPhone)) return true;
        }

        return false;
    }

    public User registerUser(String firstName, String lastName, String gender, String phone, String email, String password, boolean termsAccepted) {
        return registerUser(firstName, lastName, gender, null, phone, email, password, termsAccepted);
    }

    public User registerUser(String firstName, String lastName, String gender, String dob, String phone, String email, String password, boolean termsAccepted) {
        String cleanFirst = firstName != null ? firstName.trim() : "";
        String cleanLast = lastName != null ? lastName.trim() : "";
        String fullName = cleanFirst + (cleanLast.isEmpty() ? "" : " " + cleanLast);
        String cleanGender = gender != null ? gender.trim() : "Prefer not to say";
        String cleanDob = (dob != null && !dob.trim().isEmpty()) ? dob.trim() : null;
        String cleanPhone = phone != null ? phone.trim() : "";
        String cleanEmail = email != null ? email.trim().toLowerCase() : "";
        String cleanPass = (password != null && !password.trim().isEmpty()) ? password.trim() : "user123";

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "INSERT INTO users (first_name, last_name, full_name, email, phone, gender, dob, password, status, email_verified, terms_accepted) " +
                             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Inactive', 1, ?)";
                ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
                ps.setString(1, cleanFirst);
                ps.setString(2, cleanLast);
                ps.setString(3, fullName);
                ps.setString(4, cleanEmail);
                ps.setString(5, cleanPhone);
                ps.setString(6, cleanGender);
                if (cleanDob != null) {
                    try {
                        ps.setDate(7, java.sql.Date.valueOf(cleanDob));
                    } catch (Exception ex) {
                        ps.setNull(7, java.sql.Types.DATE);
                    }
                } else {
                    ps.setNull(7, java.sql.Types.DATE);
                }
                ps.setString(8, cleanPass);
                ps.setInt(9, termsAccepted ? 1 : 0);

                int rows = ps.executeUpdate();
                if (rows > 0) {
                    rs = ps.getGeneratedKeys();
                    int newId = 0;
                    if (rs.next()) {
                        newId = rs.getInt(1);
                    }
                    User newUser = new User(newId, cleanFirst, cleanLast, cleanEmail, cleanPhone, cleanGender, cleanPass, "", "Inactive", true);
                    newUser.setDob(cleanDob);
                    return newUser;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO registerUser error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        // Memory fallback if DB is offline
        int newId = DEMO_USERS.size() + 10;
        User newUser = new User(newId, cleanFirst, cleanLast, cleanEmail, cleanPhone, cleanGender, cleanPass, "", "Inactive", true);
        DEMO_USERS.add(newUser);
        return newUser;
    }

    public User findByEmail(String email) {
        if (email == null) return null;
        String cleanEmail = email.trim().toLowerCase();

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT user_id, first_name, last_name, full_name, email, phone, gender, password, address, status, email_verified, terms_accepted, created_at " +
                             "FROM users WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();
                if (rs.next()) {
                    User u = new User();
                    u.setUserId(rs.getInt("user_id"));
                    u.setFirstName(rs.getString("first_name"));
                    u.setLastName(rs.getString("last_name"));
                    u.setFullName(rs.getString("full_name"));
                    u.setEmail(rs.getString("email"));
                    u.setPhone(rs.getString("phone"));
                    u.setGender(rs.getString("gender"));
                    u.setPassword(rs.getString("password"));
                    u.setAddress(rs.getString("address"));
                    u.setStatus(rs.getString("status"));
                    u.setEmailVerified(rs.getInt("email_verified") == 1);
                    u.setTermsAccepted(rs.getInt("terms_accepted") == 1);
                    java.sql.Timestamp ts = rs.getTimestamp("created_at");
                    u.setCreatedAt(ts != null ? ts.toString() : "");
                    return u;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO findByEmail error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (User u : DEMO_USERS) {
            if (u.getEmail().equalsIgnoreCase(cleanEmail)) return u;
        }
        return null;
    }

    public User findById(int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT user_id, first_name, last_name, full_name, email, phone, gender, dob, password, address, status, email_verified, terms_accepted, created_at " +
                             "FROM users WHERE user_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, userId);
                rs = ps.executeQuery();
                if (rs.next()) {
                    User u = new User();
                    u.setUserId(rs.getInt("user_id"));
                    u.setFirstName(rs.getString("first_name"));
                    u.setLastName(rs.getString("last_name"));
                    u.setFullName(rs.getString("full_name"));
                    u.setEmail(rs.getString("email"));
                    u.setPhone(rs.getString("phone"));
                    u.setGender(rs.getString("gender"));
                    java.sql.Date dobDate = rs.getDate("dob");
                    u.setDob(dobDate != null ? dobDate.toString() : null);
                    u.setPassword(rs.getString("password"));
                    u.setAddress(rs.getString("address"));
                    u.setStatus(rs.getString("status"));
                    u.setEmailVerified(rs.getInt("email_verified") == 1);
                    u.setTermsAccepted(rs.getInt("terms_accepted") == 1);
                    java.sql.Timestamp ts = rs.getTimestamp("created_at");
                    u.setCreatedAt(ts != null ? ts.toString() : "");
                    return u;
                }
            }
        } catch (Exception e) {
            System.err.println("UserDAO findById error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (User u : DEMO_USERS) {
            if (u.getUserId() == userId) return u;
        }
        return null;
    }

    public boolean updateProfile(int userId, String firstName, String lastName, String gender, String dob, String phone, String address) {
        String cleanFirst = firstName != null ? firstName.trim() : "";
        String cleanLast = lastName != null ? lastName.trim() : "";
        String fullName = cleanFirst + (cleanLast.isEmpty() ? "" : " " + cleanLast);
        String cleanGender = gender != null ? gender.trim() : "Prefer not to say";
        String cleanDob = (dob != null && !dob.trim().isEmpty()) ? dob.trim() : null;
        String cleanPhone = phone != null ? phone.trim() : "";
        String cleanAddress = address != null ? address.trim() : "";

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "UPDATE users SET first_name = ?, last_name = ?, full_name = ?, gender = ?, dob = ?, phone = ?, address = ? WHERE user_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanFirst);
                ps.setString(2, cleanLast);
                ps.setString(3, fullName);
                ps.setString(4, cleanGender);
                if (cleanDob != null) {
                    try {
                        ps.setDate(5, java.sql.Date.valueOf(cleanDob));
                    } catch (Exception ex) {
                        ps.setNull(5, java.sql.Types.DATE);
                    }
                } else {
                    ps.setNull(5, java.sql.Types.DATE);
                }
                ps.setString(6, cleanPhone);
                ps.setString(7, cleanAddress);
                ps.setInt(8, userId);
                int rows = ps.executeUpdate();
                if (rows > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("UserDAO updateProfile error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        for (User u : DEMO_USERS) {
            if (u.getUserId() == userId) {
                u.setFirstName(cleanFirst);
                u.setLastName(cleanLast);
                u.setFullName(fullName);
                u.setGender(cleanGender);
                u.setDob(cleanDob);
                u.setPhone(cleanPhone);
                u.setAddress(cleanAddress);
                return true;
            }
        }
        return false;
    }

    public boolean updatePassword(String email, String newPassword) {
        if (email == null || newPassword == null || email.trim().isEmpty() || newPassword.trim().isEmpty()) {
            return false;
        }
        String cleanEmail = email.trim().toLowerCase();
        String cleanPassword = newPassword.trim();

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "UPDATE users SET password = ? WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanPassword);
                ps.setString(2, cleanEmail);
                int rows = ps.executeUpdate();
                if (rows > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("UserDAO updatePassword error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        // Memory fallback
        for (User u : DEMO_USERS) {
            if (u.getEmail().equalsIgnoreCase(cleanEmail)) {
                u.setPassword(cleanPassword);
                return true;
            }
        }
        return false;
    }
}
