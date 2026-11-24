package com.roadassistance.controller;

import com.roadassistance.model.User;
import com.roadassistance.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;

@WebServlet(name = "RequestAssistanceServlet", urlPatterns = {"/user/request-assistance-submit", "/service-request/create"})
public class RequestAssistanceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/user/request-assistance.jsp");
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

        String vehicleNo = request.getParameter("vehicleNo");
        String issueType = request.getParameter("issueType");
        String customIssue = request.getParameter("customIssue");
        String locationAddress = request.getParameter("locationAddress");
        String latStr = request.getParameter("latitude");
        String lngStr = request.getParameter("longitude");
        String additionalDetails = request.getParameter("additionalDetails");
        String requestMode = request.getParameter("requestMode");
        String radiusStr = request.getParameter("broadcastRadius");

        // Validation & sanitization: FORCED Vehicle Selection
        if (vehicleNo == null || vehicleNo.trim().isEmpty() || vehicleNo.trim().startsWith("--")) {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"Please select your vehicle from the dropdown.\"}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/request-assistance.jsp?error=vehicle_required");
            }
            return;
        }
        vehicleNo = vehicleNo.trim();

        if (requestMode == null || requestMode.trim().isEmpty()) {
            requestMode = "Common";
        } else {
            requestMode = requestMode.trim();
        }

        int broadcastRadius = 10;
        try {
            if (radiusStr != null && !radiusStr.trim().isEmpty()) {
                broadcastRadius = Integer.parseInt(radiusStr.trim());
            }
        } catch (Exception ignored) {}

        if (issueType == null || issueType.trim().isEmpty()) {
            issueType = "Engine Overheating";
        } else {
            issueType = issueType.trim();
        }

        if ("Other Issue".equalsIgnoreCase(issueType) && customIssue != null && !customIssue.trim().isEmpty()) {
            issueType = customIssue.trim();
        }

        if (locationAddress == null || locationAddress.trim().isEmpty()) {
            locationAddress = "NH-83, Manapparai, Trichy - 621306";
        } else {
            locationAddress = locationAddress.trim();
        }

        Double latitude = 10.6074;
        Double longitude = 78.4190;
        try {
            if (latStr != null && !latStr.trim().isEmpty()) latitude = Double.parseDouble(latStr.trim());
            if (lngStr != null && !lngStr.trim().isEmpty()) longitude = Double.parseDouble(lngStr.trim());
        } catch (NumberFormatException ignored) {}

        if (additionalDetails != null) {
            additionalDetails = additionalDetails.trim();
            if (additionalDetails.length() > 250) {
                additionalDetails = additionalDetails.substring(0, 250);
            }
        } else {
            additionalDetails = "";
        }

        int userId = currentUser.getUserId();
        String userFullName = (currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()) 
                ? currentUser.getFullName().trim() : "Raj Kumar";
        String userCode = "USR" + String.format("%03d", userId);

        SimpleDateFormat sdfDate = new SimpleDateFormat("dd-MM-yyyy · hh:mm a");
        String requestedDateStr = sdfDate.format(new Date());

        String generatedRequestCode = "SR0464";
        boolean inserted = false;
        String errorMessage = null;

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                // Check if this vehicle is currently on an active breakdown request
                String checkActiveSql = 
                    "SELECT request_code, status, breakdown_issue FROM service_requests " +
                    "WHERE REPLACE(REPLACE(UPPER(vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(?), ' ', ''), '-', '') " +
                    "AND status NOT IN ('Completed', 'Cancelled', 'Rejected') " +
                    "ORDER BY request_id DESC LIMIT 1";

                try (PreparedStatement psCheck = conn.prepareStatement(checkActiveSql)) {
                    psCheck.setString(1, vehicleNo);
                    try (ResultSet rsCheck = psCheck.executeQuery()) {
                        if (rsCheck.next()) {
                            String activeReqCode = rsCheck.getString("request_code");
                            String activeStatus = rsCheck.getString("status");
                            String err = "Vehicle " + vehicleNo + " is currently on an active request (" + activeReqCode + " \u2014 " + activeStatus + "). You cannot raise another request for this vehicle until the current request is completed.";
                            if (isAjax) {
                                PrintWriter out = response.getWriter();
                                out.print("{\"success\":false,\"message\":\"" + err + "\",\"alreadyActive\":true,\"activeRequestCode\":\"" + activeReqCode + "\"}");
                                out.flush();
                            } else {
                                response.sendRedirect(request.getContextPath() + "/user/request-assistance.jsp?error=" + java.net.URLEncoder.encode(err, "UTF-8"));
                            }
                            return;
                        }
                    }
                }

                // Generate sequential unique request code
                Statement st = conn.createStatement();
                rs = st.executeQuery("SELECT COALESCE(MAX(CAST(SUBSTRING(request_code, 3) AS UNSIGNED)), 464) + 1 FROM service_requests");
                int nextId = 465;
                if (rs.next()) {
                    int val = rs.getInt(1);
                    if (val > 0) nextId = val;
                }
                rs.close();
                st.close();

                generatedRequestCode = String.format("SR%04d", nextId);

                // Fetch vehicle brand, model, type, and image from user_vehicles for this vehicle
                String vehBrand = null;
                String vehModel = null;
                String vehType = "Car";
                String vehImage = null;
                try (PreparedStatement psVeh = conn.prepareStatement(
                        "SELECT vehicle_brand, vehicle_model, vehicle_type, vehicle_image FROM user_vehicles " +
                        "WHERE REPLACE(REPLACE(UPPER(vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(?), ' ', ''), '-', '') " +
                        "AND user_id = ? LIMIT 1")) {
                    psVeh.setString(1, vehicleNo);
                    psVeh.setInt(2, userId);
                    try (ResultSet rsVeh = psVeh.executeQuery()) {
                        if (rsVeh.next()) {
                            vehBrand = rsVeh.getString("vehicle_brand");
                            vehModel = rsVeh.getString("vehicle_model");
                            vehType = rsVeh.getString("vehicle_type");
                            vehImage = rsVeh.getString("vehicle_image");
                        }
                    }
                } catch (Exception ign) {}
                if (vehType == null || vehType.trim().isEmpty()) vehType = "Car";

                String mechanicName = null;
                String mechanicCode = null;

                if ("Specific".equalsIgnoreCase(requestMode)) {
                    mechanicName = request.getParameter("mechanicName");
                    String mechanicIdStr = request.getParameter("mechanicId");
                    if (mechanicName != null && !mechanicName.trim().isEmpty() && !"Nearby Mechanics".equalsIgnoreCase(mechanicName.trim())) {
                        mechanicName = mechanicName.trim();
                        try (PreparedStatement psM = conn.prepareStatement(
                                "SELECT mechanic_code, workshop_name FROM mechanics WHERE workshop_name = ? OR owner_name = ? OR mechanic_id = ? LIMIT 1")) {
                            psM.setString(1, mechanicName);
                            psM.setString(2, mechanicName);
                            int mIdParsed = 0;
                            try { if (mechanicIdStr != null) mIdParsed = Integer.parseInt(mechanicIdStr.trim()); } catch (Exception ignored) {}
                            psM.setInt(3, mIdParsed);
                            try (ResultSet rsM = psM.executeQuery()) {
                                if (rsM.next()) {
                                    mechanicCode = rsM.getString("mechanic_code");
                                    mechanicName = rsM.getString("workshop_name");
                                }
                            }
                        } catch (Exception ign) {}
                    } else {
                        mechanicName = "Nearby Mechanics";
                        requestMode = "Common";
                    }
                } else {
                    mechanicName = "Nearby Mechanics";
                    mechanicCode = null;
                    requestMode = "Common";
                }

                String insertSql = "INSERT INTO service_requests (" +
                        "request_code, user_id, user_name, user_code, vehicle_number, " +
                        "breakdown_issue, location, mechanic_name, mechanic_code, status, requested_date, " +
                        "latitude, longitude, additional_details, vehicle_brand, vehicle_model, vehicle_type, vehicle_image, " +
                        "request_type, broadcast_radius" +
                        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

                ps = conn.prepareStatement(insertSql);
                ps.setString(1, generatedRequestCode);
                ps.setInt(2, userId);
                ps.setString(3, userFullName);
                ps.setString(4, userCode);
                ps.setString(5, vehicleNo);
                ps.setString(6, issueType);
                ps.setString(7, locationAddress);
                ps.setString(8, mechanicName);
                ps.setString(9, mechanicCode);
                ps.setString(10, requestedDateStr);
                ps.setDouble(11, latitude);
                ps.setDouble(12, longitude);
                ps.setString(13, additionalDetails);
                ps.setString(14, vehBrand);
                ps.setString(15, vehModel);
                ps.setString(16, vehType);
                ps.setString(17, vehImage);
                ps.setString(18, requestMode);
                ps.setInt(19, broadcastRadius);

                int affected = ps.executeUpdate();
                if (affected > 0) {
                    inserted = true;
                } else {
                    errorMessage = "Failed to create service request ticket.";
                }
            } else {
                errorMessage = "Database connection unavailable.";
            }
        } catch (Exception ex) {
            errorMessage = "Server error: " + ex.getMessage();
            ex.printStackTrace();
        } finally {
            DBConnection.closeQuietly(rs, ps, conn);
        }

        if (inserted) {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":true,\"requestCode\":\"" + generatedRequestCode + "\",\"message\":\"Breakdown request raised successfully!\",\"redirectUrl\":\"" + request.getContextPath() + "/user/my-requests.jsp?msg=request_submitted&code=" + generatedRequestCode + "\"}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/my-requests.jsp?msg=request_submitted&code=" + generatedRequestCode);
            }
        } else {
            if (isAjax) {
                PrintWriter out = response.getWriter();
                out.print("{\"success\":false,\"message\":\"" + (errorMessage != null ? errorMessage : "Could not submit request.") + "\"}");
                out.flush();
            } else {
                response.sendRedirect(request.getContextPath() + "/user/request-assistance.jsp?error=" + java.net.URLEncoder.encode(errorMessage != null ? errorMessage : "Submission failed", "UTF-8"));
            }
        }
    }
}
