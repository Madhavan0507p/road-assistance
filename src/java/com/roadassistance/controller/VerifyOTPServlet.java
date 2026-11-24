package com.roadassistance.controller;

import com.roadassistance.service.OTPService;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "VerifyOTPServlet", urlPatterns = {"/auth/verify-otp", "/verify-otp"})
public class VerifyOTPServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String email = request.getParameter("email");
        String otp = request.getParameter("otp");

        if (email == null || email.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Email address is required.\"}");
            return;
        }

        if (otp == null || otp.trim().isEmpty()) {
            out.print("{\"success\": false, \"message\": \"Please enter the 6-digit OTP code.\"}");
            return;
        }

        email = email.trim().toLowerCase();
        otp = otp.trim();

        OTPService.OTPResult result = OTPService.verifyOTP(email, otp);

        if (result.success) {
            HttpSession session = request.getSession(true);
            session.setAttribute("verified_email_" + email, Boolean.TRUE);
            session.setAttribute("last_verified_email", email);

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
