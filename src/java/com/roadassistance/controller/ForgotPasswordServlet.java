package com.roadassistance.controller;

import com.roadassistance.dao.MechanicDAO;
import com.roadassistance.dao.UserDAO;
import com.roadassistance.model.Mechanic;
import com.roadassistance.model.User;
import com.roadassistance.service.OTPService;
import com.roadassistance.service.OTPService.OTPResult;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "ForgotPasswordServlet", urlPatterns = {"/auth/forgot-password", "/ForgotPasswordServlet"})
public class ForgotPasswordServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final MechanicDAO mechanicDAO = new MechanicDAO();

    // Password requirements: 8-12 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special character
    private static final Pattern UPPERCASE_PAT = Pattern.compile("[A-Z]");
    private static final Pattern LOWERCASE_PAT = Pattern.compile("[a-z]");
    private static final Pattern DIGIT_PAT = Pattern.compile("[0-9]");
    private static final Pattern SPECIAL_PAT = Pattern.compile("[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String role = request.getParameter("role");
        String contextPath = request.getContextPath();
        if ("mechanic".equalsIgnoreCase(role)) {
            response.sendRedirect(contextPath + "/mechanic/forgot-password.jsp");
        } else {
            response.sendRedirect(contextPath + "/user/forgot-password.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        String action = request.getParameter("action");
        String role = request.getParameter("role");
        if (role == null || role.trim().isEmpty()) {
            role = "user";
        } else {
            role = role.trim().toLowerCase();
        }

        PrintWriter out = response.getWriter();

        if ("send_otp".equalsIgnoreCase(action) || "check_email".equalsIgnoreCase(action)) {
            handleSendOtp(request, response, out, role);
        } else if ("verify_otp".equalsIgnoreCase(action)) {
            handleVerifyOtp(request, response, out, role);
        } else if ("resend_otp".equalsIgnoreCase(action)) {
            handleResendOtp(request, response, out, role);
        } else if ("reset_password".equalsIgnoreCase(action)) {
            handleResetPassword(request, response, out, role);
        } else {
            writeJson(out, false, "INVALID_ACTION", "Invalid forgot password action specified.", null);
        }
    }

    private void handleSendOtp(HttpServletRequest request, HttpServletResponse response, PrintWriter out, String role) {
        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            email = request.getParameter("identifier");
        }
        if (email == null || email.trim().isEmpty()) {
            writeJson(out, false, "MISSING_EMAIL", "Please enter your registered email address.", null);
            return;
        }

        String cleanEmail = email.trim().toLowerCase();

        if ("mechanic".equals(role)) {
            Mechanic mech = mechanicDAO.findByEmail(cleanEmail);
            if (mech == null) {
                writeJson(out, false, "NOT_FOUND", "Email does not exist in our workshop network.", null);
                return;
            }
            if (mech.isBlocked()) {
                writeJson(out, false, "BLOCKED", "Your mechanic account has been blocked by administrator. You cannot reset password or sign in. Please contact support.", null);
                return;
            }
        } else {
            User user = userDAO.findByEmail(cleanEmail);
            if (user == null) {
                writeJson(out, false, "NOT_FOUND", "Email does not exist in our user records.", null);
                return;
            }
            if (user.isBlocked()) {
                writeJson(out, false, "BLOCKED", "Your user account has been blocked by administrator. You cannot reset password or sign in. Please contact support.", null);
                return;
            }
        }

        // Generate and dispatch OTP
        OTPResult result = OTPService.generateAndSendOTP(cleanEmail);
        if (result.success) {
            HttpSession session = request.getSession(true);
            session.setAttribute("fp_email", cleanEmail);
            session.setAttribute("fp_role", role);
            session.setAttribute("fp_otp_sent", Boolean.TRUE);
            session.removeAttribute("fp_verified");
            session.removeAttribute("fp_verified_email");

            writeJson(out, true, "OTP_SENT", "A 6-digit verification OTP has been sent to " + cleanEmail, cleanEmail);
        } else {
            writeJson(out, false, "OTP_SEND_FAILED", result.message, null);
        }
    }

    private void handleVerifyOtp(HttpServletRequest request, HttpServletResponse response, PrintWriter out, String role) {
        String email = request.getParameter("email");
        String otp = request.getParameter("otp");

        if (email == null || email.trim().isEmpty()) {
            HttpSession session = request.getSession(false);
            if (session != null) {
                email = (String) session.getAttribute("fp_email");
            }
        }

        if (email == null || email.trim().isEmpty()) {
            writeJson(out, false, "MISSING_EMAIL", "Email address is missing. Please start again.", null);
            return;
        }

        if (otp == null || otp.trim().isEmpty()) {
            writeJson(out, false, "MISSING_OTP", "Please enter the 6-digit verification OTP.", null);
            return;
        }

        String cleanEmail = email.trim().toLowerCase();
        String cleanOtp = otp.trim().replaceAll("\\s+", "");

        OTPResult result = OTPService.verifyOTP(cleanEmail, cleanOtp);
        if (result.success) {
            HttpSession session = request.getSession(true);
            session.setAttribute("fp_verified", Boolean.TRUE);
            session.setAttribute("fp_verified_email", cleanEmail);
            session.setAttribute("fp_role", role);

            writeJson(out, true, "OTP_VERIFIED", "Verification successful! Please choose a new password.", cleanEmail);
        } else {
            writeJson(out, false, "OTP_INVALID", result.message, null);
        }
    }

    private void handleResendOtp(HttpServletRequest request, HttpServletResponse response, PrintWriter out, String role) {
        handleSendOtp(request, response, out, role);
    }

    private void handleResetPassword(HttpServletRequest request, HttpServletResponse response, PrintWriter out, String role) {
        String email = request.getParameter("email");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        HttpSession session = request.getSession(false);
        String sessionEmail = session != null ? (String) session.getAttribute("fp_verified_email") : null;
        Boolean isVerified = session != null ? (Boolean) session.getAttribute("fp_verified") : null;

        if (email == null || email.trim().isEmpty()) {
            email = sessionEmail;
        }

        if (email == null || email.trim().isEmpty()) {
            writeJson(out, false, "MISSING_EMAIL", "Email address is required.", null);
            return;
        }

        String cleanEmail = email.trim().toLowerCase();

        // Enforce OTP verification before password reset
        if (isVerified == null || !isVerified || sessionEmail == null || !sessionEmail.equalsIgnoreCase(cleanEmail)) {
            // Also check OTP service state as a fallback
            if (!OTPService.isEmailVerified(cleanEmail)) {
                writeJson(out, false, "NOT_VERIFIED", "Verification session expired or OTP not verified. Please verify your OTP first.", null);
                return;
            }
        }

        if (newPassword == null || newPassword.trim().isEmpty()) {
            writeJson(out, false, "EMPTY_PASSWORD", "Please enter a new password.", null);
            return;
        }
        if (confirmPassword == null || confirmPassword.trim().isEmpty()) {
            writeJson(out, false, "EMPTY_CONFIRM_PASSWORD", "Please confirm your new password.", null);
            return;
        }

        String cleanPass = newPassword.trim();
        String cleanConfirm = confirmPassword.trim();

        // 1. Passwords must match
        if (!cleanPass.equals(cleanConfirm)) {
            writeJson(out, false, "MISMATCH", "New Password and Confirm Password do not match.", null);
            return;
        }

        // 2. Length must be 8 - 12 characters
        if (cleanPass.length() < 8 || cleanPass.length() > 12) {
            writeJson(out, false, "INVALID_LENGTH", "Password length must be between 8 and 12 characters.", null);
            return;
        }

        // 3. At least one uppercase letter
        if (!UPPERCASE_PAT.matcher(cleanPass).find()) {
            writeJson(out, false, "NO_UPPERCASE", "Password must contain at least one uppercase letter (A-Z).", null);
            return;
        }

        // 4. At least one lowercase letter
        if (!LOWERCASE_PAT.matcher(cleanPass).find()) {
            writeJson(out, false, "NO_LOWERCASE", "Password must contain at least one lowercase letter (a-z).", null);
            return;
        }

        // 5. At least one numeric digit
        if (!DIGIT_PAT.matcher(cleanPass).find()) {
            writeJson(out, false, "NO_DIGIT", "Password must contain at least one numeric digit (0-9).", null);
            return;
        }

        // 6. At least one special symbol
        if (!SPECIAL_PAT.matcher(cleanPass).find()) {
            writeJson(out, false, "NO_SPECIAL", "Password must contain at least one special symbol (!@#$%^&*...).", null);
            return;
        }

        // Double check blocked status before persisting new password
        if ("mechanic".equals(role)) {
            Mechanic mech = mechanicDAO.findByEmail(cleanEmail);
            if (mech == null) {
                writeJson(out, false, "NOT_FOUND", "Email does not exist in our workshop network.", null);
                return;
            }
            if (mech.isBlocked()) {
                writeJson(out, false, "BLOCKED", "Your mechanic account has been blocked by administrator. You cannot reset password.", null);
                return;
            }

            boolean updated = mechanicDAO.updatePassword(cleanEmail, cleanPass);
            if (updated) {
                if (session != null) {
                    session.removeAttribute("fp_email");
                    session.removeAttribute("fp_verified");
                    session.removeAttribute("fp_verified_email");
                    session.removeAttribute("fp_role");
                }
                String redirect = request.getContextPath() + "/mechanic/login.jsp?msg=password_reset_success";
                writeJson(out, true, "SUCCESS", "Password reset successfully! Redirecting to login...", redirect);
            } else {
                writeJson(out, false, "UPDATE_FAILED", "Failed to update password in database. Please try again.", null);
            }
        } else {
            User user = userDAO.findByEmail(cleanEmail);
            if (user == null) {
                writeJson(out, false, "NOT_FOUND", "Email does not exist in our user records.", null);
                return;
            }
            if (user.isBlocked()) {
                writeJson(out, false, "BLOCKED", "Your user account has been blocked by administrator. You cannot reset password.", null);
                return;
            }

            boolean updated = userDAO.updatePassword(cleanEmail, cleanPass);
            if (updated) {
                if (session != null) {
                    session.removeAttribute("fp_email");
                    session.removeAttribute("fp_verified");
                    session.removeAttribute("fp_verified_email");
                    session.removeAttribute("fp_role");
                }
                String redirect = request.getContextPath() + "/user/login.jsp?msg=password_reset_success";
                writeJson(out, true, "SUCCESS", "Password reset successfully! Redirecting to login...", redirect);
            } else {
                writeJson(out, false, "UPDATE_FAILED", "Failed to update password in database. Please try again.", null);
            }
        }
    }

    private void writeJson(PrintWriter out, boolean success, String code, String message, String data) {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"success\":").append(success).append(",");
        sb.append("\"code\":\"").append(escapeJson(code)).append("\",");
        sb.append("\"message\":\"").append(escapeJson(message)).append("\"");
        if (data != null) {
            sb.append(",\"data\":\"").append(escapeJson(data)).append("\"");
            sb.append(",\"redirect\":\"").append(escapeJson(data)).append("\"");
        }
        sb.append("}");
        out.print(sb.toString());
        out.flush();
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
