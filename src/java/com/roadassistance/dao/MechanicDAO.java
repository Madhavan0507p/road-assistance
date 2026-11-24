package com.roadassistance.dao;

import com.roadassistance.model.Mechanic;
import com.roadassistance.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class MechanicDAO {

    // Fallback in-memory mechanics for offline database environments
    private static final List<Mechanic> DEMO_MECHANICS = new ArrayList<Mechanic>();

    static {
        DEMO_MECHANICS.add(new Mechanic(1, "Ravi Auto Services", "Ravi Kumar", "+91 98765 43210", "ravi@mechanic.com", "mech123", "Anna Salai, Chennai", "Approved"));
        DEMO_MECHANICS.add(new Mechanic(2, "Sathish Auto Garage", "Sathish M", "+91 97894 56780", "sathish@mechanic.com", "mech123", "Gandhipuram, Coimbatore", "Pending"));
        DEMO_MECHANICS.add(new Mechanic(3, "Praveen Auto Works", "Praveen K", "+91 94876 32109", "praveen@mechanic.com", "mech123", "Fairlands, Salem", "Blocked"));
        DEMO_MECHANICS.add(new Mechanic(4, "Dinesh Car Care", "Dinesh M", "+91 96325 90120", "dinesh@mechanic.com", "mech123", "Simmakkal, Madurai", "Pending"));
        DEMO_MECHANICS.add(new Mechanic(5, "Arun Motors", "Arun Prakash", "+91 96325 90120", "arun@mechanic.com", "mech123", "KK Nagar, Madurai", "Approved"));
    }

    public Mechanic authenticate(String email, String password) {
        if (email == null || password == null) return null;
        String cleanEmail = email.trim();
        String cleanPassword = password.trim();
        if (cleanEmail.isEmpty() || cleanPassword.isEmpty()) return null;

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT mechanic_id, mechanic_code, workshop_name, owner_name, specialization, phone, email, password, location, address, " +
                             "approval_status, blocked_reason, is_available, rating, created_at " +
                             "FROM mechanics WHERE LOWER(email) = LOWER(?) AND password = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                ps.setString(2, cleanPassword);
                rs = ps.executeQuery();
                if (rs.next()) {
                    Mechanic m = new Mechanic();
                    m.setMechanicId(rs.getInt("mechanic_id"));
                    m.setMechanicCode(rs.getString("mechanic_code"));
                    m.setWorkshopName(rs.getString("workshop_name"));
                    m.setOwnerName(rs.getString("owner_name"));
                    m.setSpecialization(rs.getString("specialization"));
                    m.setPhone(rs.getString("phone"));
                    m.setEmail(rs.getString("email"));
                    m.setPassword(rs.getString("password"));
                    m.setLocation(rs.getString("location"));
                    m.setAddress(rs.getString("address"));
                    m.setApprovalStatus(rs.getString("approval_status"));
                    m.setBlockedReason(rs.getString("blocked_reason"));
                    m.setAvailable(rs.getBoolean("is_available"));
                    m.setRating(rs.getDouble("rating"));
                    java.sql.Timestamp ts = rs.getTimestamp("created_at");
                    m.setCreatedAt(ts != null ? ts.toString() : "");
                    return m;
                }
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO authenticate DB query notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        // Check fallback demo accounts
        for (Mechanic m : DEMO_MECHANICS) {
            if (m.getEmail().equalsIgnoreCase(cleanEmail) && m.getPassword().equals(cleanPassword)) {
                return m;
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
                String sql = "SELECT mechanic_id FROM mechanics WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();
                if (rs.next()) return true;
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO isEmailRegistered error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (Mechanic m : DEMO_MECHANICS) {
            if (m.getEmail().equalsIgnoreCase(cleanEmail)) return true;
        }
        return false;
    }

    public Mechanic findByEmail(String email) {
        if (email == null) return null;
        String cleanEmail = email.trim().toLowerCase();

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT mechanic_id, mechanic_code, workshop_name, owner_name, specialization, phone, email, password, location, address, " +
                             "approval_status, blocked_reason, is_available, rating, created_at " +
                             "FROM mechanics WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();
                if (rs.next()) {
                    Mechanic m = new Mechanic();
                    m.setMechanicId(rs.getInt("mechanic_id"));
                    m.setMechanicCode(rs.getString("mechanic_code"));
                    m.setWorkshopName(rs.getString("workshop_name"));
                    m.setOwnerName(rs.getString("owner_name"));
                    m.setSpecialization(rs.getString("specialization"));
                    m.setPhone(rs.getString("phone"));
                    m.setEmail(rs.getString("email"));
                    m.setPassword(rs.getString("password"));
                    m.setLocation(rs.getString("location"));
                    m.setAddress(rs.getString("address"));
                    m.setApprovalStatus(rs.getString("approval_status"));
                    m.setBlockedReason(rs.getString("blocked_reason"));
                    m.setAvailable(rs.getBoolean("is_available"));
                    m.setRating(rs.getDouble("rating"));
                    java.sql.Timestamp ts = rs.getTimestamp("created_at");
                    m.setCreatedAt(ts != null ? ts.toString() : "");
                    return m;
                }
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO findByEmail error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (Mechanic m : DEMO_MECHANICS) {
            if (m.getEmail().equalsIgnoreCase(cleanEmail)) return m;
        }
        return null;
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
                String sql = "SELECT mechanic_id FROM mechanics WHERE REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+91', '') = ? " +
                             "OR REPLACE(REPLACE(REPLACE(shop_contact_number, ' ', ''), '-', ''), '+91', '') = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanPhone);
                ps.setString(2, cleanPhone);
                rs = ps.executeQuery();
                if (rs.next()) return true;
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO isPhoneRegistered error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        for (Mechanic m : DEMO_MECHANICS) {
            String norm = m.getPhone() != null ? m.getPhone().replaceAll("[^0-9]", "") : "";
            if (norm.startsWith("91") && norm.length() == 12) norm = norm.substring(2);
            if (norm.equals(cleanPhone)) return true;
        }
        return false;
    }

    public Mechanic registerMechanic(Mechanic m) {
        if (m == null) return null;

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn == null) return null;

            conn.setAutoCommit(false);

            String ownerName = (m.getFirstName() != null ? m.getFirstName().trim() : "") + 
                               (m.getLastName() != null && !m.getLastName().trim().isEmpty() ? " " + m.getLastName().trim() : "");
            if (ownerName.trim().isEmpty()) ownerName = m.getOwnerName();

            String shopName = m.getShopName() != null ? m.getShopName().trim() : m.getWorkshopName();
            String fullAddress = (m.getAddressLine1() != null ? m.getAddressLine1().trim() : "") +
                                 (m.getAddressLine2() != null && !m.getAddressLine2().trim().isEmpty() ? ", " + m.getAddressLine2().trim() : "") +
                                 (m.getCity() != null ? ", " + m.getCity().trim() : "") +
                                 (m.getDistrict() != null ? ", " + m.getDistrict().trim() : "") +
                                 (m.getState() != null ? ", " + m.getState().trim() : "") +
                                 (m.getPincode() != null ? " - " + m.getPincode().trim() : "");
            if (fullAddress.trim().isEmpty() || fullAddress.trim().equals(",")) {
                fullAddress = m.getAddress() != null ? m.getAddress() : "Tamil Nadu";
            }

            String primarySpec = (m.getSpecializations() != null && !m.getSpecializations().isEmpty()) ? 
                                 m.getSpecializations().get(0) : (m.getSpecialization() != null ? m.getSpecialization() : "General Service");

            // Pre-calculate unique mechanic_code
            String mechCode = m.getMechanicCode();
            if (mechCode == null || mechCode.trim().isEmpty()) {
                int nextId = 1;
                Statement st = conn.createStatement();
                ResultSet rsMax = st.executeQuery("SELECT COALESCE(MAX(mechanic_id), 0) + 1 FROM mechanics");
                if (rsMax.next()) {
                    nextId = rsMax.getInt(1);
                }
                rsMax.close();
                st.close();
                mechCode = "MEC" + String.format("%03d", nextId);
                m.setMechanicCode(mechCode);
            }

            String sql = "INSERT INTO mechanics (mechanic_code, first_name, last_name, gender, dob, owner_name, workshop_name, shop_name, shop_type, " +
                         "years_of_experience, opening_time, closing_time, shop_description, specialization, other_specialization, " +
                         "phone, shop_contact_number, email, email_verified, password, location, address, address_line_1, " +
                         "address_line_2, city, district, state, pincode, latitude, longitude, aadhaar_number, aadhaar_card_doc, id_proof_doc, " +
                         "approval_status, account_status, is_available, rating) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', 'Active', 0, 4.8)";

            ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
            ps.setString(1, mechCode);
            ps.setString(2, m.getFirstName());
            ps.setString(3, m.getLastName());
            ps.setString(4, m.getGender() != null ? m.getGender() : "Male");
            if (m.getDob() != null && !m.getDob().trim().isEmpty()) {
                try {
                    ps.setDate(5, java.sql.Date.valueOf(m.getDob().trim()));
                } catch (Exception e) {
                    ps.setNull(5, java.sql.Types.DATE);
                }
            } else {
                ps.setNull(5, java.sql.Types.DATE);
            }
            ps.setString(6, ownerName);
            ps.setString(7, shopName);
            ps.setString(8, shopName);
            ps.setString(9, m.getShopType() != null ? m.getShopType() : "Four Wheeler Service");
            ps.setString(10, m.getYearsOfExperience() != null ? m.getYearsOfExperience() : "3–5 years");
            ps.setString(11, m.getOpeningTime() != null ? m.getOpeningTime() : "09:00 AM");
            ps.setString(12, m.getClosingTime() != null ? m.getClosingTime() : "07:00 PM");
            ps.setString(13, m.getShopDescription());
            ps.setString(14, primarySpec);
            ps.setString(15, m.getOtherSpecialization());
            ps.setString(16, m.getPhone());
            ps.setString(17, m.getShopContactNumber() != null ? m.getShopContactNumber() : m.getPhone());
            ps.setString(18, m.getEmail() != null ? m.getEmail().trim().toLowerCase() : "");
            ps.setInt(19, m.isEmailVerified() ? 1 : 0);
            ps.setString(20, (m.getPassword() != null && !m.getPassword().trim().isEmpty()) ? m.getPassword().trim() : "mech123");
            ps.setString(21, m.getCity() != null ? m.getCity() : (m.getDistrict() != null ? m.getDistrict() : "Chennai"));
            ps.setString(22, fullAddress);
            ps.setString(23, m.getAddressLine1());
            ps.setString(24, m.getAddressLine2());
            ps.setString(25, m.getCity());
            ps.setString(26, m.getDistrict());
            ps.setString(27, m.getState() != null ? m.getState() : "Tamil Nadu");
            ps.setString(28, m.getPincode());
            ps.setDouble(29, m.getLatitude() != 0 ? m.getLatitude() : 10.7905);
            ps.setDouble(30, m.getLongitude() != 0 ? m.getLongitude() : 78.7047);
            ps.setString(31, m.getAadhaarNumber());
            ps.setString(32, m.getAadhaarCardDoc());
            ps.setString(33, m.getIdProofDoc());

            int affected = ps.executeUpdate();
            if (affected == 0) {
                conn.rollback();
                return null;
            }

            rs = ps.getGeneratedKeys();
            int newMechId = 0;
            if (rs.next()) {
                newMechId = rs.getInt(1);
            }
            m.setMechanicId(newMechId);
            ps.close();

            // Update mechanic_code to ensure exact match with assigned ID if different
            String finalMechCode = "MEC" + String.format("%03d", newMechId);
            m.setMechanicCode(finalMechCode);
            PreparedStatement psCode = conn.prepareStatement("UPDATE mechanics SET mechanic_code = ? WHERE mechanic_id = ?");
            psCode.setString(1, finalMechCode);
            psCode.setInt(2, newMechId);
            psCode.executeUpdate();
            psCode.close();

            // Insert specializations into mechanic_specializations table
            if (m.getSpecializations() != null && !m.getSpecializations().isEmpty()) {
                PreparedStatement psSpec = conn.prepareStatement(
                    "INSERT INTO mechanic_specializations (mechanic_id, specialization_name) VALUES (?, ?) " +
                    "ON DUPLICATE KEY UPDATE specialization_name = VALUES(specialization_name)"
                );
                for (String spec : m.getSpecializations()) {
                    if (spec != null && !spec.trim().isEmpty()) {
                        psSpec.setInt(1, newMechId);
                        psSpec.setString(2, spec.trim());
                        psSpec.executeUpdate();
                    }
                }
                psSpec.close();
            }

            // Insert shop photos into mechanic_shop_photos table
            if (m.getShopPhotos() != null && !m.getShopPhotos().isEmpty()) {
                PreparedStatement psPhoto = conn.prepareStatement(
                    "INSERT INTO mechanic_shop_photos (mechanic_id, photo_path, original_filename) VALUES (?, ?, ?)"
                );
                for (String photoPath : m.getShopPhotos()) {
                    if (photoPath != null && !photoPath.trim().isEmpty()) {
                        String origName = photoPath.contains("/") ? photoPath.substring(photoPath.lastIndexOf('/') + 1) : photoPath;
                        psPhoto.setInt(1, newMechId);
                        psPhoto.setString(2, photoPath.trim());
                        psPhoto.setString(3, origName);
                        psPhoto.executeUpdate();
                    }
                }
                psPhoto.close();
            }

            conn.commit();
            return m;

        } catch (Exception e) {
            System.err.println("MechanicDAO registerMechanic error: " + e.getMessage());
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) {}
            }
            return null;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); } catch (SQLException ignored) {}
            }
            DBConnection.closeQuietly(rs, ps, conn);
        }
    }

    public List<String> getSpecializations(int mechanicId) {
        List<String> list = new ArrayList<String>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT specialization_name FROM mechanic_specializations WHERE mechanic_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, mechanicId);
                rs = ps.executeQuery();
                while (rs.next()) {
                    list.add(rs.getString("specialization_name"));
                }
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO getSpecializations error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
        return list;
    }

    public List<String> getShopPhotos(int mechanicId) {
        List<String> list = new ArrayList<String>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT photo_path FROM mechanic_shop_photos WHERE mechanic_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, mechanicId);
                rs = ps.executeQuery();
                while (rs.next()) {
                    list.add(rs.getString("photo_path"));
                }
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO getShopPhotos error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
        return list;
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
                String sql = "UPDATE mechanics SET password = ?, updated_at = NOW() WHERE LOWER(email) = LOWER(?)";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanPassword);
                ps.setString(2, cleanEmail);
                int rows = ps.executeUpdate();
                if (rows > 0) return true;
            }
        } catch (Exception e) {
            System.err.println("MechanicDAO updatePassword error: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        // Memory fallback
        for (Mechanic m : DEMO_MECHANICS) {
            if (m.getEmail().equalsIgnoreCase(cleanEmail)) {
                m.setPassword(cleanPassword);
                return true;
            }
        }
        return false;
    }
}
