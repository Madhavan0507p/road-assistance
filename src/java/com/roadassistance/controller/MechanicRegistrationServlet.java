package com.roadassistance.controller;

import com.roadassistance.dao.MechanicDAO;
import com.roadassistance.model.Mechanic;
import com.roadassistance.util.DBConnection;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet(name = "MechanicRegistrationServlet", urlPatterns = {"/auth/mechanic-register", "/mechanic-register", "/MechanicRegistrationServlet"})
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB
    maxFileSize = 10 * 1024 * 1024,        // 10 MB per photo
    maxRequestSize = 35 * 1024 * 1024      // 35 MB total request
)
public class MechanicRegistrationServlet extends HttpServlet {

    private final MechanicDAO mechanicDAO = new MechanicDAO();

    // Regex Validation Patterns
    private static final Pattern NAME_PATTERN = Pattern.compile("^[A-Za-z\\s]{2,60}$");
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[6-9][0-9]{9}$");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$");
    private static final Pattern PINCODE_PATTERN = Pattern.compile("^[0-9]{6}$");
    private static final Pattern PASSWORD_PATTERN = Pattern.compile("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*(),.?\":{}|<>\\-_=+]).{8,12}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/mechanic/register.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"));

        // =====================================================================
        // 1. EXTRACT FORM PARAMETERS
        // =====================================================================
        // Step 1: Personal Details
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String gender = request.getParameter("gender");
        String dob = request.getParameter("dob");
        String mobileNumber = request.getParameter("mobileNumber");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        // Step 3: Work Specialization
        String[] specializations = request.getParameterValues("specializations");
        String otherSpecialization = request.getParameter("otherSpecialization");

        // Step 4: Shop Details
        String shopName = request.getParameter("shopName");
        String shopType = request.getParameter("shopType");
        String shopContactNumber = request.getParameter("shopContactNumber");
        String yearsOfExperience = request.getParameter("yearsOfExperience");
        String openingTime = request.getParameter("openingTime");
        String closingTime = request.getParameter("closingTime");
        String shopDescription = request.getParameter("shopDescription");

        // Step 5: Shop Address & Location
        String addressLine1 = request.getParameter("addressLine1");
        String addressLine2 = request.getParameter("addressLine2");
        String city = request.getParameter("city");
        String district = request.getParameter("district");
        String state = request.getParameter("state");
        String pincode = request.getParameter("pincode");
        String latStr = request.getParameter("latitude");
        String lngStr = request.getParameter("longitude");

        // =====================================================================
        // 2. SERVER-SIDE VALIDATION
        // =====================================================================
        // First Name
        if (firstName == null || firstName.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your first name.", "firstName", 1);
            return;
        }
        if (!NAME_PATTERN.matcher(firstName.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "First name must contain letters only (no numbers or symbols).", "firstName", 1);
            return;
        }

        // Last Name
        if (lastName == null || lastName.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your last name.", "lastName", 1);
            return;
        }
        if (!Pattern.compile("^[A-Za-z\\s]{1,60}$").matcher(lastName.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "Last name must contain letters only (no numbers or symbols).", "lastName", 1);
            return;
        }

        // Gender
        if (gender == null || gender.trim().isEmpty() || "Select gender".equalsIgnoreCase(gender.trim())) {
            sendResponse(request, response, isAjax, false, "Please select your gender.", "gender", 1);
            return;
        }

        // Date of Birth (Must be at least 18 years old)
        if (dob == null || dob.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your date of birth.", "dob", 1);
            return;
        }
        try {
            java.time.LocalDate birthDate = java.time.LocalDate.parse(dob.trim());
            java.time.LocalDate today = java.time.LocalDate.now();
            if (birthDate.isAfter(today)) {
                sendResponse(request, response, isAjax, false, "Date of birth cannot be in the future.", "dob", 1);
                return;
            }
            java.time.Period period = java.time.Period.between(birthDate, today);
            if (period.getYears() < 18) {
                sendResponse(request, response, isAjax, false, "You must be at least 18 years old to create a mechanic account.", "dob", 1);
                return;
            }
        } catch (java.time.format.DateTimeParseException e) {
            sendResponse(request, response, isAjax, false, "Please enter a valid date of birth (YYYY-MM-DD).", "dob", 1);
            return;
        }

        // Mobile Number
        if (mobileNumber == null || mobileNumber.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your 10-digit mobile number.", "mobileNumber", 1);
            return;
        }
        String cleanMobile = mobileNumber.replaceAll("[^0-9]", "");
        if (cleanMobile.startsWith("91") && cleanMobile.length() == 12) {
            cleanMobile = cleanMobile.substring(2);
        }
        if (!PHONE_PATTERN.matcher(cleanMobile).matches()) {
            sendResponse(request, response, isAjax, false, "Mobile number must start with 6, 7, 8, or 9 and be exactly 10 digits.", "mobileNumber", 1);
            return;
        }
        if (mechanicDAO.isPhoneRegistered(cleanMobile)) {
            sendResponse(request, response, isAjax, false, "This mobile number is already registered with another mechanic account.", "mobileNumber", 1);
            return;
        }

        // Email Address
        if (email == null || email.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your email address.", "email", 1);
            return;
        }
        String cleanEmail = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(cleanEmail).matches()) {
            sendResponse(request, response, isAjax, false, "Please enter a valid email address.", "email", 1);
            return;
        }
        if (mechanicDAO.isEmailRegistered(cleanEmail)) {
            sendResponse(request, response, isAjax, false, "An account with this email address already exists. Please sign in.", "email", 1);
            return;
        }

        // Password (optional or validated if provided)
        if (password == null || password.trim().isEmpty()) {
            password = "mech123"; // Standard default password
        }

        // Aadhaar Number (12 digits only)
        String aadhaarNumber = request.getParameter("aadhaarNumber");
        String cleanAadhaar = aadhaarNumber != null ? aadhaarNumber.replaceAll("[^0-9]", "") : "";
        if (cleanAadhaar.isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your 12-digit Aadhaar number.", "aadhaarNumber", 1);
            return;
        }
        if (cleanAadhaar.length() != 12) {
            sendResponse(request, response, isAjax, false, "Aadhaar number must be exactly 12 digits (" + cleanAadhaar.length() + "/12 entered).", "aadhaarNumber", 1);
            return;
        }

        // Step 2 Validation: Confirm Email OTP was verified in session
        HttpSession session = request.getSession(false);
        boolean emailVerified = false;
        if (session != null) {
            Boolean verifiedFlag = (Boolean) session.getAttribute("mechanic_email_verified");
            String verifiedEmail = (String) session.getAttribute("mechanic_verified_email");
            if (Boolean.TRUE.equals(verifiedFlag) && cleanEmail.equalsIgnoreCase(verifiedEmail)) {
                emailVerified = true;
            }
        }

        // Robust Fallback: Also check MySQL email_otp table directly
        if (!emailVerified) {
            Connection connOtp = null;
            PreparedStatement psOtp = null;
            ResultSet rsOtp = null;
            try {
                connOtp = DBConnection.getConnection();
                if (connOtp != null) {
                    // Check if this email has a verified OTP within the last 2 hours
                    String checkSql = "SELECT otp_id FROM email_otp WHERE email = ? AND verified = 1 AND created_at >= (NOW() - INTERVAL 2 HOUR) ORDER BY otp_id DESC LIMIT 1";
                    psOtp = connOtp.prepareStatement(checkSql);
                    psOtp.setString(1, cleanEmail);
                    rsOtp = psOtp.executeQuery();
                    if (rsOtp.next()) {
                        emailVerified = true;
                    }
                }
            } catch (Exception ex) {
                System.err.println("DB OTP fallback check notice: " + ex.getMessage());
            } finally {
                DBConnection.closeQuietly(rsOtp, psOtp, connOtp);
            }
        }

        if (!emailVerified) {
            sendResponse(request, response, isAjax, false, "Please verify your email address via the 6-digit OTP before completing registration.", "otp", 2);
            return;
        }

        // Step 3 Validation: Specializations
        List<String> specList = new ArrayList<String>();
        if (specializations != null) {
            for (String s : specializations) {
                if (s != null && !s.trim().isEmpty()) {
                    specList.add(s.trim());
                }
            }
        }
        boolean hasOther = (otherSpecialization != null && !otherSpecialization.trim().isEmpty());
        if (specList.isEmpty() && !hasOther) {
            sendResponse(request, response, isAjax, false, "Select at least one service or enter an other service.", "specializations", 3);
            return;
        }

        // Step 4 Validation: Shop Details
        if (shopName == null || shopName.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your shop / garage name.", "shopName", 4);
            return;
        }
        if (shopType == null || shopType.trim().isEmpty() || "Select shop type".equalsIgnoreCase(shopType.trim())) {
            sendResponse(request, response, isAjax, false, "Please select your shop type.", "shopType", 4);
            return;
        }
        if (shopContactNumber == null || shopContactNumber.trim().isEmpty()) {
            shopContactNumber = cleanMobile;
        } else {
            shopContactNumber = shopContactNumber.replaceAll("[^0-9]", "");
            if (shopContactNumber.startsWith("91") && shopContactNumber.length() == 12) {
                shopContactNumber = shopContactNumber.substring(2);
            }
            if (!PHONE_PATTERN.matcher(shopContactNumber).matches()) {
                sendResponse(request, response, isAjax, false, "Shop contact number must start with 6, 7, 8, or 9 and be 10 digits.", "shopContactNumber", 4);
                return;
            }
        }

        if (yearsOfExperience == null || yearsOfExperience.trim().isEmpty() || "Select experience".equalsIgnoreCase(yearsOfExperience.trim())) {
            yearsOfExperience = "3–5 years";
        }
        if (openingTime == null || openingTime.trim().isEmpty()) {
            openingTime = "09:00 AM";
        }
        if (closingTime == null || closingTime.trim().isEmpty()) {
            closingTime = "07:00 PM";
        }

        // Step 5 Validation: Address & Location
        if (addressLine1 == null || addressLine1.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter your shop address (Address Line 1).", "addressLine1", 5);
            return;
        }
        if (city == null || city.trim().isEmpty()) {
            sendResponse(request, response, isAjax, false, "Please enter city or town.", "city", 5);
            return;
        }
        if (!Pattern.compile("^[A-Za-z\\s]{2,60}$").matcher(city.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "City must contain letters and spaces only.", "city", 5);
            return;
        }
        if (district == null || district.trim().isEmpty() || "Select district".equalsIgnoreCase(district.trim())) {
            sendResponse(request, response, isAjax, false, "Please select your district.", "district", 5);
            return;
        }
        if (state == null || state.trim().isEmpty()) {
            state = "Tamil Nadu";
        }
        if (pincode == null || pincode.trim().isEmpty() || !PINCODE_PATTERN.matcher(pincode.trim()).matches()) {
            sendResponse(request, response, isAjax, false, "Enter a valid 6-digit Indian postal pincode.", "pincode", 5);
            return;
        }

        double latitude = 10.7905;
        double longitude = 78.7047;
        try {
            if (latStr != null && !latStr.trim().isEmpty()) latitude = Double.parseDouble(latStr.trim());
            if (lngStr != null && !lngStr.trim().isEmpty()) longitude = Double.parseDouble(lngStr.trim());
        } catch (NumberFormatException ignored) {}

        // =====================================================================
        // 3. FILE UPLOADS: SHOP PHOTOS
        // =====================================================================
        List<String> photoPaths = new ArrayList<String>();
        try {
            String uploadDir = getServletContext().getRealPath("/uploads/mechanic_photos");
            File dir;
            if (uploadDir != null) {
                dir = new File(uploadDir);
            } else {
                dir = new File(System.getProperty("java.io.tmpdir"), "road_assistance_uploads");
            }
            if (!dir.exists()) {
                dir.mkdirs();
            }

            Collection<Part> parts = request.getParts();
            int photoCount = 0;
            for (Part part : parts) {
                if ("shopPhotos".equals(part.getName()) && part.getSize() > 0 && photoCount < 5) {
                    String submittedName = part.getSubmittedFileName();
                    if (submittedName != null && !submittedName.trim().isEmpty()) {
                        String ext = "";
                        int dotIdx = submittedName.lastIndexOf('.');
                        if (dotIdx > 0) ext = submittedName.substring(dotIdx).toLowerCase();

                        if (Arrays.asList(".jpg", ".jpeg", ".png", ".webp").contains(ext)) {
                            String safeFileName = "shop_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
                            File targetFile = new File(dir, safeFileName);
                            try (InputStream in = part.getInputStream()) {
                                Files.copy(in, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                            }
                            photoPaths.add("/uploads/mechanic_photos/" + safeFileName);
                            photoCount++;
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("Shop photo upload notice: " + ex.getMessage());
        }

        // =====================================================================
        // 3B. FILE UPLOADS: AADHAAR CARD & ID PROOF DOCUMENTS
        // =====================================================================
        String aadhaarDocPath = null;
        String idProofDocPath = null;
        try {
            String docUploadDir = getServletContext().getRealPath("/uploads/mechanic_documents");
            File dDir;
            if (docUploadDir != null) {
                dDir = new File(docUploadDir);
            } else {
                dDir = new File(System.getProperty("java.io.tmpdir"), "road_assistance_documents");
            }
            if (!dDir.exists()) {
                dDir.mkdirs();
            }

            Part aPart = null;
            try { aPart = request.getPart("aadhaarCardDoc"); } catch (Exception ignored) {}
            if (aPart != null && aPart.getSize() > 0) {
                String orig = aPart.getSubmittedFileName();
                if (orig != null && !orig.trim().isEmpty()) {
                    String ext = "";
                    int dIdx = orig.lastIndexOf('.');
                    if (dIdx > 0) ext = orig.substring(dIdx).toLowerCase();
                    if (Arrays.asList(".jpg", ".jpeg", ".png", ".webp", ".pdf").contains(ext)) {
                        String sName = "aadhaar_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
                        File tFile = new File(dDir, sName);
                        try (InputStream in = aPart.getInputStream()) {
                            Files.copy(in, tFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                        }
                        aadhaarDocPath = "/uploads/mechanic_documents/" + sName;
                    }
                }
            }

            Part idPart = null;
            try { idPart = request.getPart("idProofDoc"); } catch (Exception ignored) {}
            if (idPart != null && idPart.getSize() > 0) {
                String orig = idPart.getSubmittedFileName();
                if (orig != null && !orig.trim().isEmpty()) {
                    String ext = "";
                    int dIdx = orig.lastIndexOf('.');
                    if (dIdx > 0) ext = orig.substring(dIdx).toLowerCase();
                    if (Arrays.asList(".jpg", ".jpeg", ".png", ".webp", ".pdf").contains(ext)) {
                        String sName = "idproof_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
                        File tFile = new File(dDir, sName);
                        try (InputStream in = idPart.getInputStream()) {
                            Files.copy(in, tFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                        }
                        idProofDocPath = "/uploads/mechanic_documents/" + sName;
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("Document upload notice: " + ex.getMessage());
        }

        // =====================================================================
        // 4. ASSEMBLE MECHANIC ENTITY
        // =====================================================================
        Mechanic mech = new Mechanic();
        mech.setAadhaarNumber(cleanAadhaar);
        mech.setAadhaarCardDoc(aadhaarDocPath != null ? aadhaarDocPath : "");
        mech.setIdProofDoc(idProofDocPath != null ? idProofDocPath : (aadhaarDocPath != null ? aadhaarDocPath : ""));
        mech.setFirstName(firstName.trim());
        mech.setLastName(lastName.trim());
        mech.setOwnerName(firstName.trim() + " " + lastName.trim());
        mech.setGender(gender.trim());
        mech.setDob(dob != null ? dob.trim() : null);
        mech.setPhone(cleanMobile);
        mech.setShopContactNumber(shopContactNumber.trim());
        mech.setEmail(cleanEmail);
        mech.setEmailVerified(true);
        mech.setPassword(password);
        mech.setShopName(shopName.trim());
        mech.setWorkshopName(shopName.trim());
        mech.setShopType(shopType.trim());
        mech.setYearsOfExperience(yearsOfExperience.trim());
        mech.setOpeningTime(openingTime.trim());
        mech.setClosingTime(closingTime.trim());
        mech.setShopDescription(shopDescription != null ? shopDescription.trim() : "");
        mech.setSpecializations(specList);
        mech.setOtherSpecialization(hasOther ? otherSpecialization.trim() : null);
        mech.setAddressLine1(addressLine1.trim());
        mech.setAddressLine2(addressLine2 != null ? addressLine2.trim() : "");
        mech.setCity(city.trim());
        mech.setDistrict(district.trim());
        mech.setState(state.trim());
        mech.setPincode(pincode.trim());
        mech.setLocation(city.trim());
        mech.setLatitude(latitude);
        mech.setLongitude(longitude);
        mech.setShopPhotos(photoPaths);
        mech.setApprovalStatus("Pending");
        mech.setAccountStatus("Active");
        mech.setAvailable(false);

        // =====================================================================
        // 5. DATABASE TRANSACTION
        // =====================================================================
        Mechanic registered = mechanicDAO.registerMechanic(mech);

        if (registered == null) {
            sendResponse(request, response, isAjax, false, "System error occurred while creating mechanic account. Please try again.", "system", 5);
            return;
        }

        // Clear temporary session data
        if (session != null) {
            session.removeAttribute("mechanic_email_verified");
            session.removeAttribute("mechanic_verified_email");
            session.removeAttribute("mechanic_reg_otp");
        }

        String redirectUrl = request.getContextPath() + "/mechanic/login.jsp?msg=registered_pending&workshop=" + java.net.URLEncoder.encode(shopName.trim(), "UTF-8");

        if (isAjax) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.print("{\"success\": true, \"message\": \"Mechanic registration submitted successfully! Your account is awaiting administrator approval.\", \"redirectUrl\": \"" + redirectUrl + "\"}");
        } else {
            response.sendRedirect(redirectUrl);
        }
    }

    private void sendResponse(HttpServletRequest request, HttpServletResponse response, boolean isAjax, boolean success, String message, String field, int step)
            throws IOException {
        if (isAjax) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.print("{\"success\": " + success + ", \"message\": \"" + escapeJson(message) + "\", \"field\": \"" + escapeJson(field) + "\", \"step\": " + step + "}");
        } else {
            response.sendRedirect(request.getContextPath() + "/mechanic/register.jsp?error=" + java.net.URLEncoder.encode(message, "UTF-8"));
        }
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}
