package com.roadassistance.controller;

import com.roadassistance.dao.UserDAO;
import com.roadassistance.service.OTPService;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "SendOTPServlet", urlPatterns = {"/auth/send-otp", "/send-otp"})
public class SendOTPServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Please enter a valid email address.\"}");
            return;
        }

        email = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(email).matches()) {
            out.print("{\"success\": false, \"message\": \"Please enter a valid email format (e.g. name@domain.com).\"}");
            return;
        }

        // Check if email already registered
        if (userDAO.isEmailRegistered(email)) {
            out.print("{\"success\": false, \"message\": \"An account with this email address already exists. Please sign in.\"}");
            return;
        }

        // Generate and send OTP
        OTPService.OTPResult result = OTPService.generateAndSendOTP(email);
        request.getSession(true).setAttribute("reg_pending_email", email);

        if (result.success) {
            out.print("{\"success\": true, \"message\": \"" + escapeJson(result.message) + "\"}");
        } else {
            out.print("{\"success\": false, \"message\": \"" + escapeJson(result.message) + "\"}");
        }
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
