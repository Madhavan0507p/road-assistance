package com.roadassistance.controller;

import com.roadassistance.dao.MechanicDAO;
import com.roadassistance.service.OTPService;
import com.roadassistance.util.DBConnection;
import com.roadassistance.util.EmailUtil;

import java.io.IOException;
import java.io.PrintWriter;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "MechanicOtpServlet", urlPatterns = {"/auth/mechanic-send-otp", "/auth/mechanic-verify-otp"})
public class MechanicOtpServlet extends HttpServlet {

    private final MechanicDAO mechanicDAO = new MechanicDAO();
    private static final SecureRandom random = new SecureRandom();
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String path = request.getServletPath();
        if (path.endsWith("send-otp")) {
            handleSendOtp(request, response);
        } else if (path.endsWith("verify-otp")) {
            handleVerifyOtp(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleSendOtp(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Email address is required.\"}");
            return;
        }

        String cleanEmail = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(cleanEmail).matches()) {
            out.print("{\"success\": false, \"message\": \"Please enter a valid email address (e.g. mechanic@domain.com).\"}");
            return;
        }

        if (mechanicDAO.isEmailRegistered(cleanEmail)) {
            out.print("{\"success\": false, \"message\": \"An account with this email address already exists. Please sign in or use a different email.\"}");
            return;
        }

        HttpSession session = request.getSession(true);

        // Server-side cooldown: prevent spam requests within 20 seconds
        Long lastSent = (Long) session.getAttribute("mechanic_otp_last_sent");
        long now = System.currentTimeMillis();
        if (lastSent != null && (now - lastSent) < 20000) {
            long waitSecs = (20000 - (now - lastSent)) / 1000;
            out.print("{\"success\": false, \"message\": \"Please wait " + waitSecs + " seconds before requesting a new OTP.\"}");
            return;
        }

        // Generate 6-digit secure numeric OTP
        int num = random.nextInt(900000) + 100000;
        String otpCode = String.valueOf(num);

        // 2-minute expiration as requested
        long expiryTime = now + (2 * 60 * 1000);
        Timestamp expiryTs = new Timestamp(expiryTime);

        // Store securely in session
        session.setAttribute("mechanic_reg_otp", otpCode);
        session.setAttribute("mechanic_reg_otp_email", cleanEmail);
        session.setAttribute("mechanic_reg_otp_expiry", expiryTime);
        session.setAttribute("mechanic_reg_otp_attempts", 0);
        session.setAttribute("mechanic_otp_last_sent", now);
        session.removeAttribute("mechanic_email_verified");

        // Record in email_otp table in MySQL
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
            }
        } catch (Exception e) {
            System.err.println("MechanicOtpServlet DB log notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        // Dispatch email via JavaMail SMTP
        boolean sent = EmailUtil.sendOTPEmail(cleanEmail, otpCode);
        if (sent) {
            out.print("{\"success\": true, \"message\": \"A 6-digit verification code has been sent to " + escapeJson(cleanEmail) + "\"}");
        } else {
            out.print("{\"success\": false, \"message\": \"Failed to dispatch OTP email. Please verify your email configuration.\"}");
        }
    }

    private void handleVerifyOtp(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String email = request.getParameter("email");
        String enteredOtp = request.getParameter("otp");

        if (email == null || email.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Email address is required.\"}");
            return;
        }
        if (enteredOtp == null || enteredOtp.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Please enter the 6-digit verification OTP.\"}");
            return;
        }

        String cleanEmail = email.trim().toLowerCase();
        String cleanOtp = enteredOtp.replaceAll("[^0-9]", "");

        if (cleanOtp.length() != 6) {
            out.print("{\"success\": false, \"message\": \"OTP must be exactly 6 digits.\"}");
            return;
        }

        HttpSession session = request.getSession(false);
        if (session == null) {
            out.print("{\"success\": false, \"message\": \"Registration session expired. Please request a new OTP.\"}");
            return;
        }

        String sessionOtp = (String) session.getAttribute("mechanic_reg_otp");
        String sessionEmail = (String) session.getAttribute("mechanic_reg_otp_email");
        Long expiryTime = (Long) session.getAttribute("mechanic_reg_otp_expiry");
        Integer attempts = (Integer) session.getAttribute("mechanic_reg_otp_attempts");

        if (attempts == null) attempts = 0;
        if (attempts >= 5) {
            out.print("{\"success\": false, \"message\": \"Maximum verification attempts exceeded. Please request a new OTP.\"}");
            return;
        }

        long now = System.currentTimeMillis();
        if (sessionOtp == null || sessionEmail == null || expiryTime == null || now > expiryTime) {
            out.print("{\"success\": false, \"message\": \"Verification OTP has expired. Please click Resend OTP.\"}");
            return;
        }

        if (!cleanEmail.equalsIgnoreCase(sessionEmail)) {
            out.print("{\"success\": false, \"message\": \"Email does not match the OTP recipient. Please request a new OTP.\"}");
            return;
        }

        if (!sessionOtp.equals(cleanOtp)) {
            attempts++;
            session.setAttribute("mechanic_reg_otp_attempts", attempts);
            int remaining = 5 - attempts;
            out.print("{\"success\": false, \"message\": \"Invalid OTP code. " + remaining + " attempts remaining.\"}");
            return;
        }

        // OTP verified successfully
        session.setAttribute("mechanic_email_verified", Boolean.TRUE);
        session.setAttribute("mechanic_verified_email", cleanEmail);
        session.removeAttribute("mechanic_reg_otp"); // Invalidate used OTP

        // Update database status
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "UPDATE email_otp SET verified = 1 WHERE email = ? AND otp_code = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, cleanEmail);
                ps.setString(2, cleanOtp);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            System.err.println("MechanicOtpServlet DB update notice: " + e.getMessage());
        } finally {
            DBConnection.closeQuietly(null, ps, conn);
        }

        out.print("{\"success\": true, \"message\": \"Email verified successfully! You can now proceed to Work Specialization.\"}");
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
