package com.roadassistance.controller;

import com.roadassistance.dao.UserDAO;
import com.roadassistance.model.User;
import com.roadassistance.service.OTPService;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "RegisterUserServlet", urlPatterns = {"/auth/register-user", "/register-user", "/UserRegistrationServlet"})
public class RegisterUserServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private static final Pattern NAME_PATTERN = Pattern.compile("^[A-Za-z\\s]{2,50}$");
    private static final Pattern LAST_NAME_PATTERN = Pattern.compile("^[A-Za-z\\s]{1,50}$");
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[6-9][0-9]{9}$");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$");
    private static final Pattern PASSWORD_PATTERN = Pattern.compile("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*(),.?\":{}|<>\\-_=+]).{8,12}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/user/register.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String gender = request.getParameter("gender");
        String dob = request.getParameter("dob");
        String phone = request.getParameter("phone");
        String email = request.getParameter("email");
        String otp = request.getParameter("otp");
        String terms = request.getParameter("terms");
        String password = request.getParameter("password");

        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"));

        // Validation: First Name (letters and spaces only)
        if (firstName == null || firstName.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your first name.", "firstName");
            return;
        }
        if (!NAME_PATTERN.matcher(firstName.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "First name must contain letters only (no numbers or symbols).", "firstName");
            return;
        }

        // Validation: Last Name (letters and spaces only)
        if (lastName == null || lastName.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your last name.", "lastName");
            return;
        }
        if (!LAST_NAME_PATTERN.matcher(lastName.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "Last name must contain letters only (no numbers or symbols).", "lastName");
            return;
        }

        // Validation: Gender
        if (gender == null || gender.trim().isEmpty() || "Select Gender".equalsIgnoreCase(gender.trim())) {
            sendResponse(request, response, isAjax, false, "Please select your gender.", "gender");
            return;
        }

        // Validation: Date of Birth (Must be at least 18 years old)
        if (dob == null || dob.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your date of birth.", "dob");
            return;
        }
        try {
            java.time.LocalDate birthDate = java.time.LocalDate.parse(dob.trim());
            java.time.LocalDate today = java.time.LocalDate.now();
            if (birthDate.isAfter(today)) {
                sendResponse(request, response, isAjax, false, "Date of birth cannot be in the future.", "dob");
                return;
            }
            java.time.Period period = java.time.Period.between(birthDate, today);
            if (period.getYears() < 18) {
                sendResponse(request, response, isAjax, false, "You must be at least 18 years old to create an account.", "dob");
                return;
            }
        } catch (Exception ex) {
            sendResponse(request, response, isAjax, false, "Please enter a valid date of birth (YYYY-MM-DD).", "dob");
            return;
        }

        // Validation: Phone Number (10 digits starting with 6-9, no +91 prefix required)
        if (phone == null || phone.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your phone number.", "phone");
            return;
        }
        String cleanPhone = phone.replaceAll("[^0-9]", "");
        if (cleanPhone.startsWith("91") && cleanPhone.length() == 12) {
            cleanPhone = cleanPhone.substring(2);
        }
        if (!PHONE_PATTERN.matcher(cleanPhone).matches()) {
            sendResponse(request, response, isAjax, false, "Phone number must start with 6, 7, 8, or 9 and be exactly 10 digits.", "phone");
            return;
        }
        if (userDAO.isPhoneRegistered(cleanPhone)) {
            sendResponse(request, response, isAjax, false, "This phone number is already registered. Please sign in or use a different number.", "phone");
            return;
        }

        // Validation: Password (8-12 characters, 1 uppercase, 1 lowercase, 1 digit, 1 special symbol)
        if (password == null || password.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please create a password for your account.", "password");
            return;
        }
        if (!PASSWORD_PATTERN.matcher(password).matches()) {
            sendResponse(request, response, isAjax, false, "Password must be 8-12 characters with at least 1 uppercase, 1 lowercase, 1 number, and 1 special symbol.", "password");
            return;
        }

        // Validation: Email
        if (email == null || email.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your email address.", "email");
            return;
        }
        String cleanEmail = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(cleanEmail).matches()) {
            sendResponse(request, response, isAjax, false, "Please enter a valid email address.", "email");
            return;
        }
        if (userDAO.isEmailRegistered(cleanEmail)) {
            sendResponse(request, response, isAjax, false, "An account with this email address already exists. Please sign in.", "email");
            return;
        }

        // Validation: Terms & Conditions
        if (terms == null || (!"true".equalsIgnoreCase(terms) && !"on".equalsIgnoreCase(terms) && !"1".equals(terms))) {
            sendResponse(request, response, isAjax, false, "You must agree to the Terms & Conditions and Privacy Policy to create an account.", "terms");
            return;
        }

        // Verification: Check if Email is Verified
        HttpSession session = request.getSession(true);
        boolean isVerified = Boolean.TRUE.equals(session.getAttribute("verified_email_" + cleanEmail))
                || OTPService.isEmailVerified(cleanEmail);

        if (!isVerified) {
            // Check if OTP was supplied with registration submit
            if (otp != null && !otp.trim().isEmpty()) {
                OTPService.OTPResult otpCheck = OTPService.verifyOTP(cleanEmail, otp.trim());
                if (!otpCheck.success) {
                    sendResponse(request, response, isAjax, false, otpCheck.message, "otp");
                    return;
                }
                isVerified = true;
            } else {
                sendResponse(request, response, isAjax, false, "Please verify your email address with the OTP before creating your account.", "otp");
                return;
            }
        }

        // Store clean 10-digit phone in database with DOB
        User newUser = userDAO.registerUser(firstName.trim(), lastName.trim(), gender.trim(), dob.trim(), cleanPhone, cleanEmail, password, true);

        if (newUser == null) {
            sendResponse(request, response, isAjax, false, "Failed to create account due to a system error. Please try again.", "system");
            return;
        }

        // Do NOT automatically sign in; redirect user to login page
        session.removeAttribute("user");
        session.removeAttribute("userRole");
        session.removeAttribute("userName");
        session.removeAttribute("userEmail");

        String redirectUrl = request.getContextPath() + "/user/login.jsp?msg=registered_pending&email=" + java.net.URLEncoder.encode(cleanEmail, "UTF-8");

        if (isAjax) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.print("{\"success\": true, \"message\": \"Account registered successfully! Your account is pending administrator activation. Please wait for an administrator to activate your credentials.\", \"redirectUrl\": \"" + redirectUrl + "\"}");
        } else {
            response.sendRedirect(redirectUrl);
        }
    }

    private void sendResponse(HttpServletRequest request, HttpServletResponse response, boolean isAjax, boolean success, String message, String field)
            throws IOException {
        if (isAjax) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.print("{\"success\": " + success + ", \"message\": \"" + escapeJson(message) + "\", \"field\": \"" + escapeJson(field) + "\"}");
        } else {
            response.sendRedirect(request.getContextPath() + "/user/register.jsp?error=" + java.net.URLEncoder.encode(message, "UTF-8"));
        }
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
