package com.roadassistance.controller;

import com.roadassistance.model.User;
import com.roadassistance.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.Year;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.regex.Pattern;

/**
 * VehicleServlet handles vehicle management operations including:
 * - Duplicate registration number check (AJAX)
 * - Add new vehicle with multipart photo uploads
 * - Edit vehicle details with all form inputs and optional photo updates
 * - Server-side validation and database persistence
 */
@WebServlet(name = "VehicleServlet", urlPatterns = {"/VehicleServlet", "/user/vehicle-action", "/user/add-vehicle-submit"})
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,       // 1 MB
    maxFileSize = 1024 * 1024 * 5,          // 5 MB per image
    maxRequestSize = 1024 * 1024 * 25       // 25 MB total
)
public class VehicleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Strict Indian Registration Format: AA 00 AA 0000 or AA 00 A 0000
    private static final Pattern REG_PATTERN = Pattern.compile("^[A-Z]{2}\\s\\d{2}\\s[A-Z]{1,2}\\s\\d{4}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");

        // 1. Duplicate Registration Number Check (AJAX)
        if ("check_duplicate".equalsIgnoreCase(action)) {
            response.setContentType("application/json;charset=UTF-8");
            PrintWriter out = response.getWriter();
            
            String regNo = request.getParameter("reg_no");
            if (regNo == null || regNo.trim().isEmpty()) {
                out.print("{\"exists\":false}");
                out.flush();
                return;
            }

            String normalized = normalizeRegNo(regNo);
            int excludeId = 0;
            try {
                String excludeStr = request.getParameter("exclude_id");
                if (excludeStr != null && !excludeStr.trim().isEmpty()) {
                    excludeId = Integer.parseInt(excludeStr.trim());
                }
            } catch (Exception ignored) {}

            boolean exists = (excludeId > 0) ? checkDuplicateRegForOtherVehicle(normalized, excludeId) : checkDuplicateReg(normalized);
            out.print("{\"exists\":" + exists + ",\"normalized\":\"" + escapeJson(normalized) + "\"}");
            out.flush();
            return;
        }

        // Default redirect
        response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"));

        HttpSession session = request.getSession(false);
        User currentUser = (session != null) ? (User) session.getAttribute("user") : null;

        if (currentUser == null) {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"Session expired. Please log in again.\"}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
            }
            return;
        }

        String action = request.getParameter("action");
        if ("edit".equalsIgnoreCase(action)) {
            handleEditVehicle(request, response, currentUser, isAjax);
        } else {
            handleAddVehicle(request, response, currentUser, isAjax);
        }
    }

    /**
     * Handles adding a new vehicle with multipart photo uploads and validation.
     */
    private void handleAddVehicle(HttpServletRequest request, HttpServletResponse response, User currentUser, boolean isAjax)
            throws ServletException, IOException {
        
        int userId = currentUser.getUserId();

        // 1. Extract Form Parameters
        String vehicleType = request.getParameter("vehicle_type");
        String customVehicleType = request.getParameter("custom_vehicle_type");
        if ("Other".equalsIgnoreCase(vehicleType) && customVehicleType != null && !customVehicleType.trim().isEmpty()) {
            vehicleType = customVehicleType.trim();
        }

        String regNumber = request.getParameter("registration_number");
        String vehicleBrand = request.getParameter("vehicle_brand");
        String customBrand = request.getParameter("custom_brand");
        if ("Other".equalsIgnoreCase(vehicleBrand) && customBrand != null && !customBrand.trim().isEmpty()) {
            vehicleBrand = customBrand.trim();
        }

        String vehicleModel = request.getParameter("vehicle_model");
        String mfgYearStr = request.getParameter("manufacturing_year");
        String fuelType = request.getParameter("fuel_type");
        String customFuelType = request.getParameter("custom_fuel_type");
        if ("Other".equalsIgnoreCase(fuelType) && customFuelType != null && !customFuelType.trim().isEmpty()) {
            fuelType = customFuelType.trim();
        }

        String registrationDate = request.getParameter("registration_date");
        String insuranceProvider = request.getParameter("insurance_provider");
        String customProvider = request.getParameter("custom_insurance_provider");
        if ("Other".equalsIgnoreCase(insuranceProvider) && customProvider != null && !customProvider.trim().isEmpty()) {
            insuranceProvider = customProvider.trim();
        }

        String policyNumber = request.getParameter("insurance_policy_number");
        String insuranceValidTill = request.getParameter("insurance_valid_till");

        // 2. Server-Side Validations
        List<String> errors = new ArrayList<String>();

        if (vehicleType == null || vehicleType.trim().isEmpty()) {
            errors.add("Please select a vehicle type.");
        }
        if (regNumber == null || regNumber.trim().isEmpty()) {
            errors.add("Please enter your vehicle registration number.");
        } else {
            regNumber = normalizeRegNo(regNumber);
            if (!REG_PATTERN.matcher(regNumber).matches()) {
                errors.add("Registration number must follow the format: TN 45 CY 6778.");
            } else if (checkDuplicateReg(regNumber)) {
                errors.add("This vehicle registration number is already registered.");
            }
        }

        if (vehicleBrand == null || vehicleBrand.trim().isEmpty()) {
            errors.add("Please select a vehicle brand.");
        }
        if (vehicleModel == null || vehicleModel.trim().isEmpty()) {
            errors.add("Please enter your vehicle model.");
        }

        int mfgYear = 0;
        try {
            mfgYear = Integer.parseInt(mfgYearStr);
            int currentYear = Year.now().getValue();
            if (mfgYear < 1980 || mfgYear > currentYear) {
                errors.add("Manufacturing year must be between 1980 and " + currentYear + ".");
            }
        } catch (Exception e) {
            errors.add("Please select a valid manufacturing year.");
        }

        if (fuelType == null || fuelType.trim().isEmpty()) {
            errors.add("Please select the fuel type.");
        }

        if (!errors.isEmpty()) {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"" + escapeJson(errors.get(0)) + "\",\"errors\":[" + joinErrors(errors) + "]}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/add-vehicle.jsp?error=" + java.net.URLEncoder.encode(errors.get(0), "UTF-8"));
            }
            return;
        }

        // 3. Process Uploaded Photos (Optional, up to 5 photos)
        File uploadDirFile = getUploadDirectory();
        List<String> savedPhotoFilenames = processUploadedPhotos(request, userId, uploadDirFile);

        // Determine Primary Vehicle Image
        String primaryImage = null;
        if (!savedPhotoFilenames.isEmpty()) {
            primaryImage = savedPhotoFilenames.get(0);
        } else {
            // Appropriate fallback based on vehicle type/model
            if (vehicleType != null && (vehicleType.toLowerCase().contains("motorcycle") || vehicleType.toLowerCase().contains("two wheeler"))) {
                primaryImage = "vehicle-pulsar-lg.jpg";
            } else if (vehicleType != null && vehicleType.toLowerCase().contains("scooter")) {
                primaryImage = "vehicle-activa.png";
            } else if (vehicleModel != null && vehicleModel.toLowerCase().contains("brezza")) {
                primaryImage = "vehicle-brezza.png";
            } else if (vehicleModel != null && vehicleModel.toLowerCase().contains("nexon")) {
                primaryImage = "vehicle-nexon.png";
            } else {
                primaryImage = "vehicle-i20-lg.jpg";
            }
        }

        String photosJson = buildPhotosJson(savedPhotoFilenames);

        // 4. Save to Database
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            // Check if user has any existing vehicles (if 0, make this primary)
            int userVehCount = 0;
            ps = conn.prepareStatement("SELECT COUNT(*) FROM user_vehicles WHERE user_id = ?");
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                userVehCount = rs.getInt(1);
            }
            rs.close();
            ps.close();

            int isPrimary = (userVehCount == 0) ? 1 : 0;

            String insertSql = "INSERT INTO user_vehicles (" +
                    "user_id, vehicle_number, vehicle_brand, vehicle_model, " +
                    "manufacturing_year, vehicle_type, fuel_type, is_primary, " +
                    "vehicle_status, registration_date, insurance_expiry, " +
                    "insurance_provider, insurance_policy_number, vehicle_image, vehicle_photos" +
                    ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Active', ?, ?, ?, ?, ?, ?)";

            ps = conn.prepareStatement(insertSql);
            ps.setInt(1, userId);
            ps.setString(2, regNumber);
            ps.setString(3, vehicleBrand.trim());
            ps.setString(4, vehicleModel.trim());
            ps.setInt(5, mfgYear);
            ps.setString(6, vehicleType.trim());
            ps.setString(7, fuelType.trim());
            ps.setInt(8, isPrimary);
            ps.setString(9, (registrationDate != null && !registrationDate.trim().isEmpty()) ? registrationDate.trim() : null);
            ps.setString(10, (insuranceValidTill != null && !insuranceValidTill.trim().isEmpty()) ? insuranceValidTill.trim() : null);
            ps.setString(11, (insuranceProvider != null && !insuranceProvider.trim().isEmpty()) ? insuranceProvider.trim() : null);
            ps.setString(12, (policyNumber != null && !policyNumber.trim().isEmpty()) ? policyNumber.trim() : null);
            ps.setString(13, primaryImage);
            ps.setString(14, photosJson);

            int rows = ps.executeUpdate();

            if (rows > 0) {
                if (isAjax) {
                    PrintWriter out = response.getWriter();
                    out.print("{\"success\":true,\"message\":\"Vehicle registered successfully!\",\"redirectUrl\":\"" + 
                            request.getContextPath() + "/user/vehicles.jsp?msg=added\"}");
                    out.flush();
                } else {
                    response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=added");
                }
            } else {
                throw new Exception("No rows inserted.");
            }

        } catch (Exception ex) {
            System.err.println("Error saving vehicle: " + ex.getMessage());
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"Failed to save vehicle: " + escapeJson(ex.getMessage()) + "\"}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/add-vehicle.jsp?error=save_failed");
            }
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
    }

    /**
     * Handles editing an existing vehicle with all input fields matching add-vehicle form.
     */
    private void handleEditVehicle(HttpServletRequest request, HttpServletResponse response, User currentUser, boolean isAjax)
            throws ServletException, IOException {
        
        int userId = currentUser.getUserId();

        // 1. Extract Vehicle ID
        int vehicleId = 0;
        try {
            vehicleId = Integer.parseInt(request.getParameter("vehicle_id"));
        } catch (Exception e) {
            sendErrorResponse(response, isAjax, request.getContextPath() + "/user/vehicles.jsp", "Invalid vehicle ID.");
            return;
        }

        // 2. Extract Form Parameters
        String vehicleType = request.getParameter("vehicle_type");
        String customVehicleType = request.getParameter("custom_vehicle_type");
        if ("Other".equalsIgnoreCase(vehicleType) && customVehicleType != null && !customVehicleType.trim().isEmpty()) {
            vehicleType = customVehicleType.trim();
        }

        String regNumber = request.getParameter("registration_number");
        if (regNumber == null || regNumber.trim().isEmpty()) {
            regNumber = request.getParameter("vehicle_number"); // Fallback
        }

        String vehicleBrand = request.getParameter("vehicle_brand");
        String customBrand = request.getParameter("custom_brand");
        if ("Other".equalsIgnoreCase(vehicleBrand) && customBrand != null && !customBrand.trim().isEmpty()) {
            vehicleBrand = customBrand.trim();
        }

        String vehicleModel = request.getParameter("vehicle_model");
        String mfgYearStr = request.getParameter("manufacturing_year");
        String fuelType = request.getParameter("fuel_type");
        String customFuelType = request.getParameter("custom_fuel_type");
        if ("Other".equalsIgnoreCase(fuelType) && customFuelType != null && !customFuelType.trim().isEmpty()) {
            fuelType = customFuelType.trim();
        }

        String registrationDate = request.getParameter("registration_date");
        String insuranceProvider = request.getParameter("insurance_provider");
        String customProvider = request.getParameter("custom_insurance_provider");
        if ("Other".equalsIgnoreCase(insuranceProvider) && customProvider != null && !customProvider.trim().isEmpty()) {
            insuranceProvider = customProvider.trim();
        }

        String policyNumber = request.getParameter("insurance_policy_number");
        String insuranceValidTill = request.getParameter("insurance_valid_till");
        if (insuranceValidTill == null || insuranceValidTill.trim().isEmpty()) {
            insuranceValidTill = request.getParameter("insurance_expiry"); // Fallback
        }

        String vehicleStatus = request.getParameter("vehicle_status");
        if (vehicleStatus == null || vehicleStatus.trim().isEmpty()) {
            vehicleStatus = "Active";
        }

        String isPrimaryStr = request.getParameter("is_primary");
        int isPrimary = ("1".equals(isPrimaryStr) || "true".equalsIgnoreCase(isPrimaryStr)) ? 1 : 0;

        // 3. Server-Side Validations
        List<String> errors = new ArrayList<String>();

        if (vehicleType == null || vehicleType.trim().isEmpty()) {
            errors.add("Please select a vehicle type.");
        }
        if (regNumber == null || regNumber.trim().isEmpty()) {
            errors.add("Please enter your vehicle registration number.");
        } else {
            regNumber = normalizeRegNo(regNumber);
            if (!REG_PATTERN.matcher(regNumber).matches()) {
                errors.add("Registration number must follow the format: TN 45 CY 6778.");
            } else if (checkDuplicateRegForOtherVehicle(regNumber, vehicleId)) {
                errors.add("This vehicle registration number is already registered to another vehicle.");
            }
        }

        if (vehicleBrand == null || vehicleBrand.trim().isEmpty()) {
            errors.add("Please select a vehicle brand.");
        }
        if (vehicleModel == null || vehicleModel.trim().isEmpty()) {
            errors.add("Please enter your vehicle model.");
        }

        int mfgYear = 0;
        try {
            mfgYear = Integer.parseInt(mfgYearStr);
            int currentYear = Year.now().getValue();
            if (mfgYear < 1980 || mfgYear > currentYear) {
                errors.add("Manufacturing year must be between 1980 and " + currentYear + ".");
            }
        } catch (Exception e) {
            // Keep default if not provided
            mfgYear = Year.now().getValue();
        }

        if (fuelType == null || fuelType.trim().isEmpty()) {
            errors.add("Please select the fuel type.");
        }

        if (!errors.isEmpty()) {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"" + escapeJson(errors.get(0)) + "\",\"errors\":[" + joinErrors(errors) + "]}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?error=" + java.net.URLEncoder.encode(errors.get(0), "UTF-8"));
            }
            return;
        }

        // 4. Process Any New Uploaded Photos
        File uploadDirFile = getUploadDirectory();
        List<String> savedPhotoFilenames = processUploadedPhotos(request, userId, uploadDirFile);
        boolean hasNewPhotos = !savedPhotoFilenames.isEmpty();

        // 5. Update Database
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            // Verify vehicle exists and belongs to current user
            ps = conn.prepareStatement("SELECT vehicle_id, vehicle_image, vehicle_photos FROM user_vehicles WHERE vehicle_id = ? AND user_id = ?");
            ps.setInt(1, vehicleId);
            ps.setInt(2, userId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                sendErrorResponse(response, isAjax, request.getContextPath() + "/user/vehicles.jsp", "Vehicle not found or unauthorized.");
                return;
            }
            rs.close();
            ps.close();

            // If isPrimary == 1, reset other vehicles
            if (isPrimary == 1) {
                ps = conn.prepareStatement("UPDATE user_vehicles SET is_primary = 0 WHERE user_id = ?");
                ps.setInt(1, userId);
                ps.executeUpdate();
                ps.close();
            }

            StringBuilder updateSql = new StringBuilder("UPDATE user_vehicles SET ");
            updateSql.append("vehicle_number = ?, vehicle_brand = ?, vehicle_model = ?, manufacturing_year = ?, ");
            updateSql.append("vehicle_type = ?, fuel_type = ?, vehicle_status = ?, registration_date = ?, ");
            updateSql.append("insurance_expiry = ?, insurance_provider = ?, insurance_policy_number = ?, is_primary = ? ");
            if (hasNewPhotos) {
                updateSql.append(", vehicle_image = ?, vehicle_photos = ? ");
            }
            updateSql.append("WHERE vehicle_id = ? AND user_id = ?");

            ps = conn.prepareStatement(updateSql.toString());
            int idx = 1;
            ps.setString(idx++, regNumber);
            ps.setString(idx++, vehicleBrand != null ? vehicleBrand.trim() : "");
            ps.setString(idx++, vehicleModel != null ? vehicleModel.trim() : "");
            ps.setInt(idx++, mfgYear);
            ps.setString(idx++, vehicleType != null ? vehicleType.trim() : "");
            ps.setString(idx++, fuelType != null ? fuelType.trim() : "");
            ps.setString(idx++, vehicleStatus != null ? vehicleStatus.trim() : "Active");
            ps.setString(idx++, (registrationDate != null && !registrationDate.trim().isEmpty()) ? registrationDate.trim() : null);
            ps.setString(idx++, (insuranceValidTill != null && !insuranceValidTill.trim().isEmpty()) ? insuranceValidTill.trim() : null);
            ps.setString(idx++, (insuranceProvider != null && !insuranceProvider.trim().isEmpty()) ? insuranceProvider.trim() : null);
            ps.setString(idx++, (policyNumber != null && !policyNumber.trim().isEmpty()) ? policyNumber.trim() : null);
            ps.setInt(idx++, isPrimary);

            if (hasNewPhotos) {
                String primaryImage = savedPhotoFilenames.get(0);
                String photosJson = buildPhotosJson(savedPhotoFilenames);
                ps.setString(idx++, primaryImage);
                ps.setString(idx++, photosJson);
            }

            ps.setInt(idx++, vehicleId);
            ps.setInt(idx++, userId);

            int rows = ps.executeUpdate();

            if (rows > 0) {
                if (isAjax) {
                    PrintWriter out = response.getWriter();
                    out.print("{\"success\":true,\"message\":\"Vehicle updated successfully!\",\"redirectUrl\":\"" + 
                            request.getContextPath() + "/user/vehicles.jsp?msg=updated\"}");
                    out.flush();
                } else {
                    response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=updated");
                }
            } else {
                throw new Exception("No rows updated.");
            }

        } catch (Exception ex) {
            System.err.println("Error updating vehicle: " + ex.getMessage());
            sendErrorResponse(response, isAjax, request.getContextPath() + "/user/vehicles.jsp", "Failed to update vehicle: " + ex.getMessage());
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
    }

    /**
     * Resolves the target upload directory, creating it if necessary.
     */
    private File getUploadDirectory() {
        String uploadDir = getServletContext().getRealPath("/uploads/vehicles");
        if (uploadDir == null) {
            uploadDir = "C:\\Users\\madhavan\\AppData\\Roaming\\NetBeans\\8.2\\config\\GF_4.1.1\\domain1\\applications\\Road_Assistance\\uploads\\vehicles";
        }
        File uploadDirFile = new File(uploadDir);
        if (!uploadDirFile.exists()) {
            uploadDirFile.mkdirs();
        }
        return uploadDirFile;
    }

    /**
     * Processes uploaded files under name 'photos' or 'vehicle_photos', saving to both deployed webapp and project workspace.
     */
    private List<String> processUploadedPhotos(HttpServletRequest request, int userId, File uploadDirFile) {
        List<String> savedPhotoFilenames = new ArrayList<String>();
        String projectWebDir = "c:\\Users\\madhavan\\Documents\\NetBeansProjects\\Road Assistance\\web\\uploads\\vehicles";
        File projectUploadsDir = new File(projectWebDir);
        if (!projectUploadsDir.exists()) {
            projectUploadsDir.mkdirs();
        }

        // Also ensure GlassFish applications uploads directory exists
        String gfAppDir = "C:\\Users\\madhavan\\AppData\\Roaming\\NetBeans\\8.2\\config\\GF_4.1.1\\domain1\\applications\\Road_Assistance\\uploads\\vehicles";
        File gfUploadsDir = new File(gfAppDir);
        if (!gfUploadsDir.exists()) {
            gfUploadsDir.mkdirs();
        }

        try {
            Collection<Part> parts = request.getParts();
            int photoCount = 0;
            for (Part part : parts) {
                String pName = part.getName();
                if (("photos".equals(pName) || "vehicle_photos".equals(pName)) && part.getSize() > 0) {
                    if (photoCount >= 5) break;

                    String submittedName = part.getSubmittedFileName();
                    if (submittedName != null && !submittedName.trim().isEmpty()) {
                        String ext = getFileExtension(submittedName).toLowerCase();
                        if (".jpg".equals(ext) || ".jpeg".equals(ext) || ".png".equals(ext)) {
                            if (part.getSize() <= 5 * 1024 * 1024) {
                                String savedName = "veh_" + userId + "_" + System.currentTimeMillis() + "_" + (photoCount + 1) + ext;
                                File targetFile = new File(uploadDirFile, savedName);
                                
                                // Use getInputStream with Files.copy to avoid vendor-specific path prepending
                                try (java.io.InputStream input = part.getInputStream()) {
                                    Files.copy(input, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                                }
                                savedPhotoFilenames.add(savedName);

                                // Also ensure copied to GlassFish deployed application directory if different
                                try {
                                    if (!targetFile.getAbsolutePath().equalsIgnoreCase(new File(gfUploadsDir, savedName).getAbsolutePath())) {
                                        Files.copy(targetFile.toPath(), new File(gfUploadsDir, savedName).toPath(), StandardCopyOption.REPLACE_EXISTING);
                                    }
                                } catch (Exception eGf) {
                                    System.err.println("Notice copying to GF app dir: " + eGf.getMessage());
                                }

                                // Dual-write to project workspace directory
                                try {
                                    if (projectUploadsDir.exists()) {
                                        File workspaceTarget = new File(projectUploadsDir, savedName);
                                        Files.copy(targetFile.toPath(), workspaceTarget.toPath(), StandardCopyOption.REPLACE_EXISTING);
                                    }
                                } catch (Exception eCopy) {
                                    System.err.println("Notice copying vehicle photo to workspace: " + eCopy.getMessage());
                                }

                                photoCount++;
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("Notice: Photo upload processing: " + ex.getMessage());
        }
        return savedPhotoFilenames;
    }

    /**
     * Converts a list of photo filenames to JSON array string.
     */
    private String buildPhotosJson(List<String> savedPhotoFilenames) {
        if (savedPhotoFilenames == null || savedPhotoFilenames.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < savedPhotoFilenames.size(); i++) {
            sb.append("\"").append(escapeJson(savedPhotoFilenames.get(i))).append("\"");
            if (i < savedPhotoFilenames.size() - 1) sb.append(",");
        }
        sb.append("]");
        return sb.toString();
    }

    private void sendErrorResponse(HttpServletResponse response, boolean isAjax, String redirectUrl, String message) throws IOException {
        if (isAjax) {
            PrintWriter out = response.getWriter();
            out.print("{\"success\":false,\"message\":\"" + escapeJson(message) + "\"}");
            out.flush();
        } else {
            response.sendRedirect(redirectUrl + "?error=" + java.net.URLEncoder.encode(message, "UTF-8"));
        }
    }

    /**
     * Normalizes a registration number into AA 00 AA 0000 format.
     */
    public static String normalizeRegNo(String raw) {
        if (raw == null) return "";
        String clean = raw.replaceAll("[^a-zA-Z0-9]", "").toUpperCase();
        if (clean.length() == 10) {
            return clean.substring(0, 2) + " " + 
                   clean.substring(2, 4) + " " + 
                   clean.substring(4, 6) + " " + 
                   clean.substring(6, 10);
        } else if (clean.length() == 9) {
            return clean.substring(0, 2) + " " + 
                   clean.substring(2, 4) + " " + 
                   clean.substring(4, 5) + " " + 
                   clean.substring(5, 9);
        }
        return raw.trim().toUpperCase();
    }

    /**
     * Checks if a vehicle registration number is already registered in user_vehicles.
     */
    private boolean checkDuplicateReg(String regNo) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            String clean = regNo.replaceAll("\\s+", "").toUpperCase();
            ps = conn.prepareStatement("SELECT vehicle_id FROM user_vehicles WHERE REPLACE(UPPER(vehicle_number), ' ', '') = ?");
            ps.setString(1, clean);
            rs = ps.executeQuery();
            return rs.next();
        } catch (Exception e) {
            System.err.println("checkDuplicateReg notice: " + e.getMessage());
            return false;
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
    }

    /**
     * Checks if a registration number is registered to any vehicle other than excludeId.
     */
    private boolean checkDuplicateRegForOtherVehicle(String regNo, int excludeId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            String clean = regNo.replaceAll("\\s+", "").toUpperCase();
            ps = conn.prepareStatement("SELECT vehicle_id FROM user_vehicles WHERE REPLACE(UPPER(vehicle_number), ' ', '') = ? AND vehicle_id <> ?");
            ps.setString(1, clean);
            ps.setInt(2, excludeId);
            rs = ps.executeQuery();
            return rs.next();
        } catch (Exception e) {
            System.err.println("checkDuplicateRegForOtherVehicle notice: " + e.getMessage());
            return false;
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }
    }

    private String getFileExtension(String name) {
        if (name == null) return "";
        int idx = name.lastIndexOf(".");
        return idx >= 0 ? name.substring(idx) : "";
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }

    private String joinErrors(List<String> errors) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < errors.size(); i++) {
            sb.append("\"").append(escapeJson(errors.get(i))).append("\"");
            if (i < errors.size() - 1) sb.append(",");
        }
        return sb.toString();
    }
}
