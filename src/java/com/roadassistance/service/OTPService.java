package com.roadassistance.service;

import com.roadassistance.util.DBConnection;
import com.roadassistance.util.EmailUtil;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class OTPService {

    private static final SecureRandom random = new SecureRandom();
    
    // In-memory fallback cache if database is disconnected
    private static final Map<String, OTPRecord> memoryCache = new ConcurrentHashMap<String, OTPRecord>();

    private static class OTPRecord {
        final String email;
        final String otp;
        final long expiresAt;
        boolean verified;
        int attempts;

        OTPRecord(String email, String otp, long expiresAt) {
            this.email = email;
            this.otp = otp;
            this.expiresAt = expiresAt;
            this.verified = false;
            this.attempts = 0;
        }
    }

    public static class OTPResult {
        public final boolean success;
        public final String message;

        public OTPResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }

    public static OTPResult generateAndSendOTP(String email) {
        if (email == null || email.trim().isEmpty()) {
            return new OTPResult(false, "Invalid email address");
        }
        String cleanEmail = email.trim().toLowerCase();

        // 6-digit numeric OTP
        int num = random.nextInt(900000) + 100000;
        String otpCode = String.valueOf(num);

        // 5-minute expiration
        long now = System.currentTimeMillis();
        long expiryTime = now + (5 * 60 * 1000);
        Timestamp expiryTs = new Timestamp(expiryTime);

        boolean dbSaved = false;
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                // Invalidate old pending OTPs for this email
                String updateOld = "UPDATE email_otp SET verified = 2 WHERE email = ? AND verified = 0";
                ps = conn.prepareStatement(updateOld);
                ps.setString(1, cleanEmail);
                ps.executeUpdate();
                ps.close();

                // Insert new OTP record
                String insertSql = "INSERT INTO email_otp (email, otp_code, expires_at, verified, attempt_count) VALUES (?, ?, ?, 0, 0)";
                ps = conn.prepareStatement(insertSql);
                ps.setString(1, cleanEmail);
                ps.setString(2, otpCode);
                ps.setTimestamp(3, expiryTs);
                ps.executeUpdate();
                dbSaved = true;
            }
        } catch (Exception e) {
            System.err.println("OTPService generateAndSendOTP DB notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        // Cache in memory fallback
        memoryCache.put(cleanEmail, new OTPRecord(cleanEmail, otpCode, expiryTime));

        // Dispatch Email
        boolean sent = EmailUtil.sendOTPEmail(cleanEmail, otpCode);
        if (sent) {
            return new OTPResult(true, "A 6-digit verification code has been sent to " + cleanEmail);
        } else {
            return new OTPResult(false, "Failed to send OTP email. Please try again.");
        }
    }

    public static OTPResult verifyOTP(String email, String enteredOtp) {
        if (email == null || email.trim().isEmpty()) {
            return new OTPResult(false, "Email address is required");
        }
        if (enteredOtp == null || enteredOtp.trim().isEmpty()) {
            return new OTPResult(false, "Please enter the 6-digit OTP");
        }

        String cleanEmail = email.trim().toLowerCase();
        String cleanOtp = enteredOtp.trim().replaceAll("\\s+", "");

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String selectSql = "SELECT otp_id, otp_code, expires_at, attempt_count FROM email_otp "
                                 + "WHERE email = ? AND verified = 0 AND expires_at >= NOW() "
                                 + "ORDER BY created_at DESC LIMIT 1";
                ps = conn.prepareStatement(selectSql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();

                if (rs.next()) {
                    int otpId = rs.getInt("otp_id");
                    String dbCode = rs.getString("otp_code");
                    int attempts = rs.getInt("attempt_count");

                    if (attempts >= 5) {
                        return new OTPResult(false, "Too many failed attempts. Please request a new OTP.");
                    }

                    if (dbCode.equals(cleanOtp)) {
                        rs.close();
                        ps.close();
                        String updateSql = "UPDATE email_otp SET verified = 1 WHERE otp_id = ?";
                        ps = conn.prepareStatement(updateSql);
                        ps.setInt(1, otpId);
                        ps.executeUpdate();

                        // Mark memory cache verified as well
                        OTPRecord rec = memoryCache.get(cleanEmail);
                        if (rec != null) rec.verified = true;

                        return new OTPResult(true, "Email verified successfully!");
                    } else {
                        rs.close();
                        ps.close();
                        String incSql = "UPDATE email_otp SET attempt_count = attempt_count + 1 WHERE otp_id = ?";
                        ps = conn.prepareStatement(incSql);
                        ps.setInt(1, otpId);
                        ps.executeUpdate();

                        int remaining = 4 - attempts;
                        return new OTPResult(false, "Invalid OTP code. " + (remaining > 0 ? remaining + " attempts remaining." : "Please request a new OTP."));
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("OTPService verifyOTP DB notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        // Check fallback memory cache
        OTPRecord rec = memoryCache.get(cleanEmail);
        if (rec != null) {
            if (System.currentTimeMillis() > rec.expiresAt) {
                return new OTPResult(false, "OTP has expired. Please request a new OTP.");
            }
            if (rec.attempts >= 5) {
                return new OTPResult(false, "Too many failed attempts. Please request a new OTP.");
            }
            if (rec.otp.equals(cleanOtp)) {
                rec.verified = true;
                return new OTPResult(true, "Email verified successfully!");
            } else {
                rec.attempts++;
                int rem = 5 - rec.attempts;
                return new OTPResult(false, "Invalid OTP code. " + (rem > 0 ? rem + " attempts remaining." : "Please request a new OTP."));
            }
        }

        return new OTPResult(false, "Invalid or expired OTP. Please click Resend OTP.");
    }

    public static boolean isEmailVerified(String email) {
        if (email == null || email.trim().isEmpty()) return false;
        String cleanEmail = email.trim().toLowerCase();

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT otp_id FROM email_otp WHERE email = ? AND verified = 1 ORDER BY created_at DESC LIMIT 1";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                rs = ps.executeQuery();
                if (rs.next()) {
                    return true;
                }
            }
        } catch (Exception e) {
            System.err.println("OTPService isEmailVerified DB notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        OTPRecord rec = memoryCache.get(cleanEmail);
        return rec != null && rec.verified;
    }
}
