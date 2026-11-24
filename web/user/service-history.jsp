<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="com.roadassistance.model.User" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%
    // Prevent browser back-button caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 1. Session Authentication Check
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
        return;
    }

    request.setAttribute("activeUserPage", "history");

    int userId = currentUser.getUserId();
    String userFullName = (currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()) 
            ? currentUser.getFullName() : "Madhavan P";
    String userCode = "USR" + String.format("%03d", userId);

    // Handle Rating Submission Action (AJAX or form POST)
    String reqAction = request.getParameter("action");
    if ("submitRating".equalsIgnoreCase(reqAction)) {
        String reqCode = request.getParameter("requestCode");
        String ratingParam = request.getParameter("rating");
        String commentsParam = request.getParameter("comments");
        if (commentsParam == null) commentsParam = "";
        
        boolean ratingSaved = false;
        String message = "";
        double newRatingVal = 5.0;
        
        if (reqCode != null && !reqCode.trim().isEmpty() && ratingParam != null && !ratingParam.trim().isEmpty()) {
            try {
                newRatingVal = Double.parseDouble(ratingParam.trim());
                if (newRatingVal < 1.0) newRatingVal = 1.0;
                if (newRatingVal > 5.0) newRatingVal = 5.0;
                
                Connection actConn = null;
                PreparedStatement actPs = null;
                ResultSet actRs = null;
                try {
                    actConn = DBConnection.getConnection();
                    if (actConn != null) {
                        // Check previous rating and mechanic code
                        Double prevRating = null;
                        String mechCode = null;
                        String checkSql = "SELECT rating, mechanic_code FROM service_requests WHERE request_code = ? AND user_id = ? AND status = 'Completed'";
                        actPs = actConn.prepareStatement(checkSql);
                        actPs.setString(1, reqCode.trim());
                        actPs.setInt(2, userId);
                        actRs = actPs.executeQuery();
                        boolean found = false;
                        if (actRs.next()) {
                            found = true;
                            double r = actRs.getDouble("rating");
                            if (!actRs.wasNull()) {
                                prevRating = r;
                            }
                            mechCode = actRs.getString("mechanic_code");
                        }
                        actRs.close();
                        actPs.close();
                        
                        if (found) {
                            // Update service_requests table
                            String updateSql = "UPDATE service_requests SET rating = ?, rating_comments = ? WHERE request_code = ? AND user_id = ?";
                            actPs = actConn.prepareStatement(updateSql);
                            actPs.setDouble(1, newRatingVal);
                            actPs.setString(2, commentsParam.trim());
                            actPs.setString(3, reqCode.trim());
                            actPs.setInt(4, userId);
                            actPs.executeUpdate();
                            actPs.close();
                            ratingSaved = true;
                            message = "Rating submitted successfully!";
                            
                            // Update mechanic rating & reviews count
                            if (mechCode != null && !mechCode.trim().isEmpty()) {
                                String mechQuery = "SELECT rating, reviews_count FROM mechanics WHERE mechanic_code = ?";
                                actPs = actConn.prepareStatement(mechQuery);
                                actPs.setString(1, mechCode);
                                actRs = actPs.executeQuery();
                                if (actRs.next()) {
                                    double mRating = actRs.getDouble("rating");
                                    if (actRs.wasNull() || mRating <= 0) mRating = 4.8;
                                    int mReviews = actRs.getInt("reviews_count");
                                    if (actRs.wasNull() || mReviews < 0) mReviews = 100;
                                    
                                    double updatedMechRating;
                                    int updatedReviewsCount;
                                    if (prevRating == null) {
                                        updatedReviewsCount = mReviews + 1;
                                        updatedMechRating = ((mRating * mReviews) + newRatingVal) / updatedReviewsCount;
                                    } else {
                                        updatedReviewsCount = mReviews;
                                        updatedMechRating = ((mRating * mReviews) - prevRating.doubleValue() + newRatingVal) / (mReviews > 0 ? mReviews : 1);
                                    }
                                    if (updatedMechRating > 5.0) updatedMechRating = 5.0;
                                    if (updatedMechRating < 1.0) updatedMechRating = 1.0;
                                    updatedMechRating = Math.round(updatedMechRating * 10.0) / 10.0;
                                    
                                    actRs.close();
                                    actPs.close();
                                    
                                    String updateMechSql = "UPDATE mechanics SET rating = ?, reviews_count = ? WHERE mechanic_code = ?";
                                    actPs = actConn.prepareStatement(updateMechSql);
                                    actPs.setDouble(1, updatedMechRating);
                                    actPs.setInt(2, updatedReviewsCount);
                                    actPs.setString(3, mechCode);
                                    actPs.executeUpdate();
                                    actPs.close();
                                } else {
                                    actRs.close();
                                    actPs.close();
                                }
                            }
                        } else {
                            message = "Completed service request not found.";
                        }
                    }
                } finally {
                    DBConnection.closeQuietly(actRs, actPs, actConn);
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                message = "Error: " + ex.getMessage();
            }
        } else {
            message = "Missing request code or rating.";
        }
        
        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With")) 
                         || "true".equalsIgnoreCase(request.getParameter("ajax"));
        if (isAjax) {
            response.setContentType("application/json;charset=UTF-8");
            if (ratingSaved) {
                response.getWriter().write("{\"success\":true,\"rating\":\"" + String.format("%.1f", newRatingVal) + "\",\"message\":\"" + message + "\"}");
            } else {
                response.getWriter().write("{\"success\":false,\"message\":\"" + message.replace("\"", "\\\"") + "\"}");
            }
            return;
        } else {
            response.sendRedirect(request.getContextPath() + "/user/service-history.jsp?msg=" + (ratingSaved ? "rated_success" : "rated_failed"));
            return;
        }
    }

    // 2. Read Filter & Pagination Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String filterVehicle = request.getParameter("vehicle");
    if (filterVehicle != null) filterVehicle = filterVehicle.trim(); else filterVehicle = "";

    String filterServiceType = request.getParameter("serviceType");
    if (filterServiceType != null) filterServiceType = filterServiceType.trim(); else filterServiceType = "";

    String filterDate = request.getParameter("dateRange");
    if (filterDate != null) filterDate = filterDate.trim(); else filterDate = "";

    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try {
            currentPage = Integer.parseInt(pageParam.trim());
            if (currentPage < 1) currentPage = 1;
        } catch (NumberFormatException ignored) {}
    }

    int pageSize = 10; // Exactly 10 rows per page

    // 3. Database Operations
    int totalCount = 0;
    int completedCount = 0;
    int totalVehiclesServiced = 0;
    double totalAmountSpent = 0.0;
    int topRatedCount = 0;

    List userVehiclesList = new ArrayList();
    List requestRows = new ArrayList();
    int filteredTotal = 0;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // A. Summary Statistics for Logged-in User (Completed Services Only)
            try {
                String statsSql = "SELECT " +
                        "COUNT(*) AS completed_cnt, " +
                        "COUNT(DISTINCT vehicle_number) AS vehicle_cnt, " +
                        "COALESCE(SUM(CAST(REPLACE(REPLACE(NULLIF(service_cost,''), '₹', ''), ',', '') AS DECIMAL(10,2))), 0) AS total_spent, " +
                        "COUNT(CASE WHEN rating >= 4 THEN 1 END) AS top_rated_cnt " +
                        "FROM service_requests " +
                        "WHERE user_id = ? AND status = 'Completed'";
                ps = conn.prepareStatement(statsSql);
                ps.setInt(1, userId);
                rs = ps.executeQuery();
                if (rs.next()) {
                    completedCount = rs.getInt("completed_cnt");
                    totalCount = completedCount;
                    totalVehiclesServiced = rs.getInt("vehicle_cnt");
                    totalAmountSpent = rs.getDouble("total_spent");
                    topRatedCount = rs.getInt("top_rated_cnt");
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Service history stats query notice: " + ex.getMessage());
            }

            // B. User Registered Vehicles for Dropdown Filter
            try {
                ps = conn.prepareStatement(
                    "SELECT vehicle_number, vehicle_model FROM user_vehicles WHERE user_id = ? ORDER BY vehicle_id ASC"
                );
                ps.setInt(1, userId);
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map v = new HashMap();
                    v.put("number", rs.getString("vehicle_number"));
                    v.put("model", rs.getString("vehicle_model"));
                    userVehiclesList.add(v);
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Service history vehicles query notice: " + ex.getMessage());
            }

            // C. Build Dynamic WHERE Clause (Strictly Completed Services Only)
            StringBuilder whereClause = new StringBuilder(" WHERE r.user_id = ? AND r.status = 'Completed' ");
            List paramValues = new ArrayList();
            paramValues.add(userId);

            if (!search.isEmpty()) {
                whereClause.append(" AND (r.request_code LIKE ? OR r.vehicle_number LIKE ? OR r.breakdown_issue LIKE ? OR v.vehicle_model LIKE ? OR r.mechanic_name LIKE ?) ");
                String searchPattern = "%" + search + "%";
                paramValues.add(searchPattern);
                paramValues.add(searchPattern);
                paramValues.add(searchPattern);
                paramValues.add(searchPattern);
                paramValues.add(searchPattern);
            }

            if (!filterVehicle.isEmpty() && !"All".equalsIgnoreCase(filterVehicle)) {
                whereClause.append(" AND r.vehicle_number = ? ");
                paramValues.add(filterVehicle);
            }

            if (!filterServiceType.isEmpty() && !"All".equalsIgnoreCase(filterServiceType)) {
                whereClause.append(" AND r.breakdown_issue LIKE ? ");
                paramValues.add("%" + filterServiceType + "%");
            }

            if (!filterDate.isEmpty() && !"All Time".equalsIgnoreCase(filterDate) && !"All".equalsIgnoreCase(filterDate)) {
                if ("Today".equalsIgnoreCase(filterDate)) {
                    whereClause.append(" AND (DATE(r.requested_at) = CURDATE() OR r.requested_date LIKE CONCAT('%', DATE_FORMAT(CURDATE(), '%b %d, %Y'), '%')) ");
                } else if ("Last 7 Days".equalsIgnoreCase(filterDate)) {
                    whereClause.append(" AND (DATE(r.requested_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)) ");
                } else if ("Last 30 Days".equalsIgnoreCase(filterDate)) {
                    whereClause.append(" AND (DATE(r.requested_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) ");
                } else if ("Last 3 Months".equalsIgnoreCase(filterDate)) {
                    whereClause.append(" AND (DATE(r.requested_at) >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)) ");
                } else {
                    // Specific month filter (e.g. "Oct 2025", "Sep 2025", etc.)
                    whereClause.append(" AND r.requested_date LIKE ? ");
                    paramValues.add("%" + filterDate + "%");
                }
            }

            // D. Count Total Matching Records for Pagination
            try {
                String countSql = "SELECT COUNT(*) FROM service_requests r " +
                                  "LEFT JOIN user_vehicles v ON REPLACE(REPLACE(UPPER(r.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(v.vehicle_number), ' ', ''), '-', '') " +
                                  whereClause.toString();
                ps = conn.prepareStatement(countSql);
                for (int i = 0; i < paramValues.size(); i++) {
                    ps.setObject(i + 1, paramValues.get(i));
                }
                rs = ps.executeQuery();
                if (rs.next()) {
                    filteredTotal = rs.getInt(1);
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Filtered count query notice: " + ex.getMessage());
            }

            // E. Fetch Paginated Records
            int offset = (currentPage - 1) * pageSize;
            try {
                String dataSql = "SELECT r.request_id, r.request_code, r.vehicle_number, " +
                                 "COALESCE(NULLIF(r.vehicle_brand, ''), v.vehicle_brand, '') AS vehicle_brand, " +
                                 "COALESCE(NULLIF(r.vehicle_model, ''), v.vehicle_model, 'Vehicle') AS vehicle_model, " +
                                 "COALESCE(NULLIF(r.vehicle_type, ''), v.vehicle_type, 'Car') AS vehicle_type, " +
                                 "COALESCE(NULLIF(r.vehicle_image, ''), v.vehicle_image, '') AS vehicle_image, " +
                                 "r.breakdown_issue, r.location, r.mechanic_name, r.mechanic_code, r.status, " +
                                 "r.requested_date, r.requested_at, r.service_cost, r.rating, r.rating_comments, r.additional_details, " +
                                 "m.location AS mech_location, m.phone AS mech_phone, m.profile_image AS mech_image " +
                                 "FROM service_requests r " +
                                 "LEFT JOIN user_vehicles v ON REPLACE(REPLACE(UPPER(r.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(v.vehicle_number), ' ', ''), '-', '') " +
                                 "LEFT JOIN mechanics m ON (r.mechanic_code = m.mechanic_code OR r.mechanic_name = m.workshop_name) " +
                                 whereClause.toString() +
                                 " ORDER BY r.request_code DESC, r.request_id DESC LIMIT ? OFFSET ?";
                ps = conn.prepareStatement(dataSql);
                int pIdx = 1;
                for (int i = 0; i < paramValues.size(); i++) {
                    ps.setObject(pIdx++, paramValues.get(i));
                }
                ps.setInt(pIdx++, pageSize);
                ps.setInt(pIdx++, offset);

                rs = ps.executeQuery();
                SimpleDateFormat sdfDateOnly = new SimpleDateFormat("dd-MM-yyyy");
                SimpleDateFormat sdfTimeOnly = new SimpleDateFormat("hh:mm a");

                while (rs.next()) {
                    Map row = new HashMap();
                    row.put("id", rs.getInt("request_id"));
                    row.put("code", rs.getString("request_code"));
                    
                    String vNum = rs.getString("vehicle_number");
                    row.put("vehicle", vNum);
                    
                    String vModel = rs.getString("vehicle_model");
                    if (vModel == null || vModel.trim().isEmpty() || "Vehicle".equalsIgnoreCase(vModel.trim())) {
                        String vBrand = rs.getString("vehicle_brand");
                        vModel = (vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle";
                    }
                    row.put("model", vModel);

                    String vType = rs.getString("vehicle_type");
                    String vImg = rs.getString("vehicle_image");
                    if (vImg == null || vImg.trim().isEmpty()) {
                        if (vType != null && (vType.equalsIgnoreCase("Bike") || vType.equalsIgnoreCase("Motorcycle") || vType.equalsIgnoreCase("Two Wheeler") || vType.equalsIgnoreCase("Scooter"))) {
                            vImg = (vType.equalsIgnoreCase("Scooter")) ? "vehicle-activa.png" : "vehicle-pulsar-lg.jpg";
                        } else if (vModel != null && vModel.toLowerCase().contains("nexon")) {
                            vImg = "vehicle-nexon.png";
                        } else if (vModel != null && vModel.toLowerCase().contains("brezza")) {
                            vImg = "vehicle-brezza.png";
                        } else {
                            vImg = "vehicle-i20.png";
                        }
                    }
                    row.put("vehicle_img", vImg);
                    row.put("vehicle_type", vType != null ? vType : "Car");

                    row.put("issue", rs.getString("breakdown_issue"));
                    row.put("status", rs.getString("status"));
                    row.put("location", rs.getString("location"));
                    row.put("details", rs.getString("additional_details"));

                    // Date & Time formatting
                    String rDateStr = rs.getString("requested_date");
                    String dispDate = "13-11-2026";
                    String dispTime = "10:24 AM";

                    if (rDateStr != null && (rDateStr.contains("•") || rDateStr.contains("·"))) {
                        String delim = rDateStr.contains("•") ? "•" : "·";
                        String[] parts = rDateStr.split(delim);
                        dispDate = parts[0].trim();
                        if (parts.length > 1) dispTime = parts[1].trim();
                    } else if (rDateStr != null && rDateStr.contains("/")) {
                        String[] parts = rDateStr.split("/");
                        dispDate = parts[0].trim();
                        if (parts.length > 1) dispTime = parts[1].trim();
                    } else if (rs.getTimestamp("requested_at") != null) {
                        Date ts = new Date(rs.getTimestamp("requested_at").getTime());
                        dispDate = sdfDateOnly.format(ts);
                        dispTime = sdfTimeOnly.format(ts);
                    } else if (rDateStr != null && !rDateStr.trim().isEmpty()) {
                        dispDate = rDateStr.trim();
                    }

                    if (dispDate != null && !dispDate.trim().isEmpty() && !dispDate.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                        try {
                            Date parsed = null;
                            try { parsed = new SimpleDateFormat("MMM d, yyyy").parse(dispDate); } catch(Exception ignored1) {}
                            if (parsed == null) {
                                try { parsed = new SimpleDateFormat("yyyy-MM-dd").parse(dispDate); } catch(Exception ignored2) {}
                            }
                            if (parsed != null) {
                                dispDate = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                            }
                        } catch(Exception ignored) {}
                    }
                    row.put("date", dispDate);
                    row.put("time", dispTime);

                    // Mechanic details
                    String mName = rs.getString("mechanic_name");
                    row.put("mechanic", mName != null ? mName : "Unassigned");
                    
                    String mLoc = rs.getString("mech_location");
                    if (mLoc == null || mLoc.trim().isEmpty()) {
                        if ("Sathish Auto Works".equalsIgnoreCase(mName)) mLoc = "Manapparai";
                        else if ("Kumar Vehicle Service".equalsIgnoreCase(mName)) mLoc = "Manapparai";
                        else if ("R K Motors".equalsIgnoreCase(mName)) mLoc = "Thuraiyur Road";
                        else if ("Sri Auto Service".equalsIgnoreCase(mName)) mLoc = "Manapparai";
                        else mLoc = "Manapparai";
                    } else {
                        if (mLoc.contains(",")) {
                            mLoc = mLoc.split(",")[0].trim();
                        }
                    }
                    row.put("mech_loc", mLoc);

                    String mImg = rs.getString("mech_image");
                    if (mImg == null || mImg.trim().isEmpty()) {
                        if ("Sathish Auto Works".equalsIgnoreCase(mName)) mImg = "find-mech-sathish.jpg";
                        else if ("Kumar Vehicle Service".equalsIgnoreCase(mName)) mImg = "find-mech-kumar.jpg";
                        else if ("R K Motors".equalsIgnoreCase(mName)) mImg = "find-mech-rk.jpg";
                        else if ("Sri Auto Service".equalsIgnoreCase(mName)) mImg = "find-mech-sri.jpg";
                        else mImg = "find-mech-sathish.jpg";
                    }
                    row.put("mech_img", mImg);
                    row.put("phone", rs.getString("mech_phone"));

                    // Rating formatting
                    double rating = rs.getDouble("rating");
                    if (rs.wasNull() || rating <= 0) {
                        row.put("rating", "—");
                    } else {
                        row.put("rating", String.format("%.1f", rating));
                    }
                    String rComments = rs.getString("rating_comments");
                    row.put("rating_comments", rComments != null ? rComments : "");

                    requestRows.add(row);
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Paginated data query notice: " + ex.getMessage());
            }

        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }

    int totalPages = (int) Math.ceil((double) filteredTotal / pageSize);
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int showingStart = (filteredTotal > 0) ? ((currentPage - 1) * pageSize + 1) : 0;
    int showingEnd = Math.min(currentPage * pageSize, filteredTotal);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service History — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Theme & Dedicated Page Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-service-history.css?v=6.0">

    <!-- Embedded Fail-Safe Rating Modal Styles (Theme Guarantee & Anti-Cache) -->
    <style>
        /* Backdrop Overlay */
        #modalServiceRating {
            position: fixed !important;
            inset: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            background: rgba(15, 23, 42, 0.78) !important;
            backdrop-filter: blur(6px) !important;
            -webkit-backdrop-filter: blur(6px) !important;
            z-index: 99999 !important;
            align-items: center !important;
            justify-content: center !important;
            padding: 20px !important;
            box-sizing: border-box !important;
        }

        /* Modal Card */
        .rating-modal-card {
            background: #FFFFFF !important;
            width: 100% !important;
            max-width: 540px !important;
            border-radius: 20px !important;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.4) !important;
            border: 1.5px solid #E2E8F0 !important;
            padding: 26px 28px !important;
            position: relative !important;
            animation: rmPopIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) !important;
            box-sizing: border-box !important;
            font-family: 'Plus Jakarta Sans', sans-serif !important;
        }

        @keyframes rmPopIn {
            from {
                opacity: 0;
                transform: scale(0.94) translateY(10px);
            }
            to {
                opacity: 1;
                transform: scale(1) translateY(0);
            }
        }

        /* Header */
        .rating-modal-header {
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            padding-bottom: 16px !important;
            border-bottom: 1px solid #F1F5F9 !important;
        }

        .rm-header-left {
            display: flex !important;
            align-items: center !important;
            gap: 12px !important;
        }

        .rm-star-icon-box {
            width: 44px !important;
            height: 44px !important;
            border-radius: 12px !important;
            background: #FFF7ED !important;
            border: 1.5px solid #FFEDD5 !important;
            color: #F59E0B !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 20px !important;
            flex-shrink: 0 !important;
            box-shadow: 0 2px 8px rgba(245, 158, 11, 0.2) !important;
        }

        .rm-modal-title {
            font-size: 18.5px !important;
            font-weight: 800 !important;
            color: #111827 !important;
            margin: 0 !important;
            letter-spacing: -0.2px !important;
        }

        .rm-modal-sub {
            font-size: 12px !important;
            color: #64748B !important;
            margin: 2px 0 0 0 !important;
            font-weight: 500 !important;
        }

        .rm-close-btn {
            border: none !important;
            background: #F8FAFC !important;
            color: #64748B !important;
            width: 32px !important;
            height: 32px !important;
            border-radius: 8px !important;
            cursor: pointer !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 14px !important;
            transition: all 0.15s ease !important;
            border: 1px solid #E2E8F0 !important;
        }

        .rm-close-btn:hover {
            background: #FEE2E2 !important;
            color: #DC2626 !important;
            border-color: #FECACA !important;
        }

        /* Service Banner */
        .rm-service-banner {
            background: linear-gradient(135deg, #F8FAFC 0%, #F1F5F9 100%) !important;
            border: 1.5px solid #E2E8F0 !important;
            border-radius: 14px !important;
            padding: 14px 16px !important;
            margin: 16px 0 !important;
        }

        .rm-service-banner-top {
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            margin-bottom: 10px !important;
        }

        .rm-req-badge {
            background: #111827 !important;
            color: #FFFFFF !important;
            font-weight: 800 !important;
            font-size: 12px !important;
            padding: 3px 9px !important;
            border-radius: 6px !important;
            letter-spacing: 0.5px !important;
        }

        .rm-status-badge {
            background: #DCFCE7 !important;
            color: #166534 !important;
            font-weight: 700 !important;
            font-size: 11.5px !important;
            padding: 3px 9px !important;
            border-radius: 6px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 5px !important;
            border: 1px solid #BBF7D0 !important;
        }

        .rm-service-meta {
            display: flex !important;
            flex-direction: column !important;
            gap: 6px !important;
        }

        .rm-meta-item {
            font-size: 12.5px !important;
            color: #334155 !important;
            display: flex !important;
            align-items: center !important;
            gap: 8px !important;
            font-weight: 600 !important;
        }

        .rm-meta-item i {
            color: #F97316 !important;
            font-size: 12px !important;
            width: 16px !important;
            text-align: center !important;
        }

        /* Star Rating Section */
        .rm-rating-section {
            text-align: center !important;
            padding: 8px 0 16px 0 !important;
        }

        .rm-section-label {
            font-size: 12px !important;
            font-weight: 700 !important;
            color: #64748B !important;
            display: block !important;
            margin-bottom: 6px !important;
            text-transform: uppercase !important;
            letter-spacing: 0.4px !important;
        }

        .rm-stars-container {
            display: inline-flex !important;
            align-items: center !important;
            gap: 8px !important;
            padding: 8px 18px !important;
            background: #FFFBEB !important;
            border: 1.5px dashed #FDE68A !important;
            border-radius: 16px !important;
            margin: 6px auto 10px auto !important;
        }

        .rm-star-btn {
            border: none !important;
            background: transparent !important;
            font-size: 34px !important;
            color: #CBD5E1 !important;
            cursor: pointer !important;
            transition: all 0.15s ease !important;
            padding: 2px 4px !important;
            line-height: 1 !important;
        }

        .rm-star-btn:hover,
        .rm-star-btn.hover,
        .rm-star-btn.active {
            color: #F59E0B !important;
            transform: scale(1.15) !important;
            filter: drop-shadow(0 2px 4px rgba(245, 158, 11, 0.4)) !important;
        }

        .rm-score-caption {
            font-size: 13.5px !important;
            font-weight: 700 !important;
            color: #EA580C !important;
            min-height: 20px !important;
        }

        /* Quick Compliment Tags */
        .rm-tags-section {
            margin-bottom: 16px !important;
        }

        .rm-tag-chips {
            display: flex !important;
            flex-wrap: wrap !important;
            gap: 7px !important;
            margin-top: 6px !important;
        }

        .rm-chip {
            background: #F8FAFC !important;
            border: 1.5px solid #E2E8F0 !important;
            border-radius: 20px !important;
            padding: 6px 13px !important;
            font-size: 12px !important;
            font-weight: 600 !important;
            color: #475569 !important;
            cursor: pointer !important;
            transition: all 0.15s ease !important;
            font-family: inherit !important;
        }

        .rm-chip:hover {
            background: #FFF7ED !important;
            border-color: #FDBA74 !important;
            color: #C2410C !important;
        }

        .rm-chip.active {
            background: #FFF7ED !important;
            border-color: #F97316 !important;
            color: #EA580C !important;
            font-weight: 700 !important;
            box-shadow: 0 2px 6px rgba(249, 115, 22, 0.2) !important;
        }

        /* Comments Section */
        .rm-comments-section {
            margin-bottom: 14px !important;
        }

        .rm-char-count {
            font-size: 11px !important;
            color: #94A3B8 !important;
            font-weight: 600 !important;
        }

        .rm-textarea {
            width: 100% !important;
            border: 1.5px solid #E2E8F0 !important;
            border-radius: 12px !important;
            padding: 12px 14px !important;
            font-size: 13.5px !important;
            font-family: inherit !important;
            resize: none !important;
            outline: none !important;
            box-sizing: border-box !important;
            transition: border-color 0.2s, box-shadow 0.2s !important;
            line-height: 1.45 !important;
            color: #1E293B !important;
            background: #FFFFFF !important;
        }

        .rm-textarea:focus {
            border-color: #F97316 !important;
            box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.12) !important;
        }

        .rm-alert-box {
            padding: 10px 14px !important;
            border-radius: 10px !important;
            font-size: 12.5px !important;
            font-weight: 600 !important;
            margin-bottom: 14px !important;
            text-align: center !important;
        }

        .rm-alert-box.success {
            background: #ECFDF5 !important;
            color: #065F46 !important;
            border: 1px solid #A7F3D0 !important;
        }

        .rm-alert-box.error {
            background: #FEF2F2 !important;
            color: #991B1B !important;
            border: 1px solid #FECACA !important;
        }

        /* Footer Actions */
        .rating-modal-footer {
            display: flex !important;
            align-items: center !important;
            justify-content: flex-end !important;
            gap: 12px !important;
            padding-top: 16px !important;
            border-top: 1px solid #F1F5F9 !important;
            margin-top: 6px !important;
        }

        .rm-btn-cancel {
            height: 42px !important;
            padding: 0 20px !important;
            background: #FFFFFF !important;
            border: 1.5px solid #CBD5E1 !important;
            border-radius: 9px !important;
            color: #475569 !important;
            font-size: 13px !important;
            font-weight: 700 !important;
            cursor: pointer !important;
            font-family: inherit !important;
            transition: all 0.15s ease !important;
        }

        .rm-btn-cancel:hover {
            background: #F1F5F9 !important;
            color: #0F172A !important;
            border-color: #94A3B8 !important;
        }

        .rm-btn-submit {
            height: 42px !important;
            padding: 0 24px !important;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%) !important;
            border: none !important;
            border-radius: 9px !important;
            color: #FFFFFF !important;
            font-size: 13px !important;
            font-weight: 700 !important;
            cursor: pointer !important;
            font-family: inherit !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 8px !important;
            box-shadow: 0 2px 8px rgba(249, 115, 22, 0.3) !important;
            transition: all 0.15s ease !important;
        }

        .rm-btn-submit:hover {
            background: #EA580C !important;
            transform: translateY(-1px) !important;
            box-shadow: 0 4px 12px rgba(249, 115, 22, 0.4) !important;
        }
    </style>
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Main Layout Shell: Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <!-- Left Sidebar Navigation -->
        <jsp:include page="sidebar.jsp" />

        <!-- Main Content Area -->
        <main class="main-dashboard-canvas">
            <div class="sh-page-container">
                <div class="sh-main-card">

                    <!-- Header Row: Title & Breadcrumb -->
                    <div class="sh-header-row">
                        <div class="sh-title-group">
                            <div class="sh-icon-badge">
                                <i class="fa-solid fa-clock-rotate-left"></i>
                            </div>
                            <div class="sh-title-text">
                                <h1>Service <span class="accent-orange">History</span></h1>
                                <p>View all your completed and past breakdown assistance services.</p>
                            </div>
                        </div>

                        <!-- Breadcrumb -->
                        <div class="sh-breadcrumb">
                            <i class="fa-solid fa-house"></i>
                            <a href="${pageContext.request.contextPath}/user/dashboard.jsp">Dashboard</a>
                            <span class="separator">&gt;</span>
                            <span class="active-item">Service History</span>
                        </div>
                    </div>

                    <!-- Four Summary Statistic Cards (Completed Services Data Only) -->
                    <div class="sh-stats-grid">
                        <!-- 1. Completed Services -->
                        <div class="sh-stat-card sh-stat-completed">
                            <div class="sh-stat-info">
                                <span class="sh-stat-label">Completed Services</span>
                                <span class="sh-stat-value"><%= completedCount %></span>
                            </div>
                            <div class="sh-stat-icon-box">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                        </div>

                        <!-- 2. Vehicles Serviced -->
                        <div class="sh-stat-card sh-stat-total">
                            <div class="sh-stat-info">
                                <span class="sh-stat-label">Vehicles Serviced</span>
                                <span class="sh-stat-value"><%= totalVehiclesServiced %></span>
                            </div>
                            <div class="sh-stat-icon-box">
                                <i class="fa-solid fa-car"></i>
                            </div>
                        </div>

                        <!-- 3. Total Amount Spent -->
                        <div class="sh-stat-card sh-stat-inprogress" style="background: #FFF7ED; border-color: #FED7AA;">
                            <div class="sh-stat-info">
                                <span class="sh-stat-label" style="color: #9A3412;">Total Spent</span>
                                <span class="sh-stat-value" style="color: #C2410C;">₹<%= (int)totalAmountSpent %></span>
                            </div>
                            <div class="sh-stat-icon-box" style="background: rgba(249, 115, 22, 0.15); color: #EA580C;">
                                <i class="fa-solid fa-indian-rupee-sign"></i>
                            </div>
                        </div>

                        <!-- 4. Top Rated / Quality -->
                        <div class="sh-stat-card sh-stat-cancelled" style="background: #FEF9C3; border-color: #FEF08A;">
                            <div class="sh-stat-info">
                                <span class="sh-stat-label" style="color: #854D0E;">5-Star Rated</span>
                                <span class="sh-stat-value" id="shStatTopRatedVal" style="color: #A16207;"><%= topRatedCount %></span>
                            </div>
                            <div class="sh-stat-icon-box" style="background: rgba(234, 179, 8, 0.2); color: #CA8A04;">
                                <i class="fa-solid fa-star"></i>
                            </div>
                        </div>
                    </div>

                    <!-- Search and Filter Toolbar -->
                    <form method="GET" action="service-history.jsp" class="sh-filter-toolbar" id="shFilterForm">
                        <!-- Search Box -->
                        <div class="sh-search-box">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <input type="text" name="search" class="sh-search-input" 
                                   placeholder="Search by Request ID, Vehicle or Mechanic..." 
                                   value="<%= search %>">
                        </div>

                        <!-- Vehicle Filter -->
                        <div class="sh-select-group">
                            <i class="fa-solid fa-car"></i>
                            <select name="vehicle" class="sh-select" onchange="document.getElementById('shFilterForm').submit()">
                                <option value="" <%= filterVehicle.isEmpty() ? "selected" : "" %>>All Vehicles</option>
                                <%
                                    for (int i = 0; i < userVehiclesList.size(); i++) {
                                        Map v = (Map) userVehiclesList.get(i);
                                        String vNum = (String) v.get("number");
                                        String vMod = (String) v.get("model");
                                        boolean isSel = vNum.equalsIgnoreCase(filterVehicle);
                                %>
                                <option value="<%= vNum %>" <%= isSel ? "selected" : "" %>><%= vNum %> - <%= vMod %></option>
                                <%  } %>
                            </select>
                        </div>

                        <!-- Service Type Filter -->
                        <div class="sh-select-group">
                            <i class="fa-solid fa-gear"></i>
                            <select name="serviceType" class="sh-select" onchange="document.getElementById('shFilterForm').submit()">
                                <option value="" <%= filterServiceType.isEmpty() ? "selected" : "" %>>All Service Types</option>
                                <option value="Engine Overheating" <%= "Engine Overheating".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Engine Overheating</option>
                                <option value="Battery Jump Start" <%= "Battery Jump Start".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Battery Jump Start</option>
                                <option value="Tyre Puncture" <%= "Tyre Puncture".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Tyre / Puncture</option>
                                <option value="General Service" <%= "General Service".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>General Service</option>
                                <option value="Electrical Repair" <%= "Electrical Repair".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Electrical Repair</option>
                                <option value="Brake Problem" <%= "Brake Problem".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Brake Problem</option>
                                <option value="Cooling System" <%= "Cooling System".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Cooling System</option>
                                <option value="Clutch & Gear Problem" <%= "Clutch & Gear Problem".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Clutch & Gear Problem</option>
                                <option value="Fuel Issue" <%= "Fuel Issue".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Fuel Issue</option>
                                <option value="Other Issue" <%= "Other Issue".equalsIgnoreCase(filterServiceType) ? "selected" : "" %>>Other Issue</option>
                            </select>
                        </div>

                        <!-- Date Range Filter -->
                        <div class="sh-select-group">
                            <i class="fa-regular fa-calendar-days"></i>
                            <select name="dateRange" class="sh-select" onchange="document.getElementById('shFilterForm').submit()">
                                <option value="" <%= filterDate.isEmpty() ? "selected" : "" %>>All Time</option>
                                <option value="Today" <%= "Today".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Today</option>
                                <option value="Last 7 Days" <%= "Last 7 Days".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Last 7 Days</option>
                                <option value="Last 30 Days" <%= "Last 30 Days".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Last 30 Days</option>
                                <option value="Oct 2025" <%= "Oct 2025".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Oct 2025</option>
                                <option value="Sep 2025" <%= "Sep 2025".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Sep 2025</option>
                                <option value="Aug 2025" <%= "Aug 2025".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Aug 2025</option>
                                <option value="Jul 2025" <%= "Jul 2025".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Jul 2025</option>
                                <option value="Jun 2025" <%= "Jun 2025".equalsIgnoreCase(filterDate) ? "selected" : "" %>>Jun 2025</option>
                            </select>
                        </div>

                        <!-- Search Button -->
                        <button type="submit" class="btn-sh-search">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <span>Search</span>
                        </button>
                    </form>

                    <!-- Service History Table Container -->
                    <div class="sh-table-container">
                        <% if (requestRows.isEmpty()) { %>
                            <div class="sh-empty-state">
                                <div class="sh-empty-icon">
                                    <i class="fa-solid fa-magnifying-glass"></i>
                                </div>
                                <h3>No Service History Found</h3>
                                <p>No assistance records match your search criteria. Try modifying your filters.</p>
                                <a href="service-history.jsp" class="btn-sh-reset">
                                    <i class="fa-solid fa-arrow-rotate-left"></i>
                                    <span>Reset All Filters</span>
                                </a>
                            </div>
                        <% } else { %>
                            <div class="sh-table-responsive">
                                <table class="sh-table">
                                    <thead>
                                        <tr>
                                            <th style="width: 32px; text-align: center;">S.No</th>
                                            <th style="width: 85px;">Request ID</th>
                                            <th style="width: 170px;">Vehicle</th>
                                            <th style="width: 145px;">Service Type</th>
                                            <th style="width: 170px;">Mechanic</th>
                                            <th style="width: 135px;">Service Date &amp; Time</th>
                                            <th style="width: 100px;">Status</th>
                                            <th style="width: 65px;">Rating</th>
                                            <th style="width: 105px; text-align: center;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            for (int i = 0; i < requestRows.size(); i++) {
                                                Map r = (Map) requestRows.get(i);
                                                int rowNum = (currentPage - 1) * pageSize + i + 1;
                                                String reqCode = (String) r.get("code");
                                                String vNum = (String) r.get("vehicle");
                                                String vModel = (String) r.get("model");
                                                String vImg = (String) r.get("vehicle_img");
                                                String issue = (String) r.get("issue");
                                                String mName = (String) r.get("mechanic");
                                                String mLoc = (String) r.get("mech_loc");
                                                String mImg = (String) r.get("mech_img");
                                                String sDate = (String) r.get("date");
                                                String sTime = (String) r.get("time");
                                                String status = (String) r.get("status");
                                                String rating = (String) r.get("rating");
                                                String details = (String) r.get("details");
                                                String phone = (String) r.get("phone");

                                                // Service Type Icon
                                                String svcIcon = "fa-solid fa-wrench";
                                                if (issue != null) {
                                                    String lowIssue = issue.toLowerCase();
                                                    if (lowIssue.contains("overheating") || lowIssue.contains("engine")) {
                                                        svcIcon = "fa-solid fa-fire";
                                                    } else if (lowIssue.contains("battery")) {
                                                        svcIcon = "fa-solid fa-car-battery";
                                                    } else if (lowIssue.contains("tyre") || lowIssue.contains("puncture")) {
                                                        svcIcon = "fa-solid fa-circle-dot";
                                                    } else if (lowIssue.contains("general") || lowIssue.contains("service")) {
                                                        svcIcon = "fa-solid fa-gear";
                                                    } else if (lowIssue.contains("electrical")) {
                                                        svcIcon = "fa-solid fa-bolt";
                                                    } else if (lowIssue.contains("brake")) {
                                                        svcIcon = "fa-solid fa-triangle-exclamation";
                                                    } else if (lowIssue.contains("cooling")) {
                                                        svcIcon = "fa-solid fa-snowflake";
                                                    } else if (lowIssue.contains("clutch") || lowIssue.contains("gear")) {
                                                        svcIcon = "fa-solid fa-gears";
                                                    } else if (lowIssue.contains("fuel")) {
                                                        svcIcon = "fa-solid fa-gas-pump";
                                                    }
                                                }

                                                // Status CSS Class & Icon
                                                String statusClass = "completed";
                                                String statusIcon = "fa-solid fa-check";
                                                if ("In Progress".equalsIgnoreCase(status)) {
                                                    statusClass = "in-progress";
                                                    statusIcon = "fa-regular fa-clock";
                                                } else if ("Pending".equalsIgnoreCase(status)) {
                                                    statusClass = "pending";
                                                    statusIcon = "fa-regular fa-clock";
                                                } else if ("Accepted".equalsIgnoreCase(status)) {
                                                    statusClass = "accepted";
                                                    statusIcon = "fa-solid fa-check";
                                                } else if ("Cancelled".equalsIgnoreCase(status)) {
                                                    statusClass = "cancelled";
                                                    statusIcon = "fa-regular fa-circle-xmark";
                                                }

                                                String vImgSrc;
                                                if (vImg != null && (vImg.startsWith("http://") || vImg.startsWith("https://"))) {
                                                    vImgSrc = vImg;
                                                } else if (vImg != null && vImg.startsWith("veh_")) {
                                                    vImgSrc = request.getContextPath() + "/uploads/vehicles/" + vImg;
                                                } else if (vImg != null && vImg.startsWith("uploads/")) {
                                                    vImgSrc = request.getContextPath() + "/" + vImg;
                                                } else {
                                                    vImgSrc = request.getContextPath() + "/images/" + (vImg != null && !vImg.trim().isEmpty() ? vImg : "vehicle-i20.png");
                                                }
                                        %>
                                        <tr>
                                            <!-- 1. Serial # -->
                                            <td class="col-num"><%= rowNum %></td>

                                            <!-- 2. Request ID Badge -->
                                            <td>
                                                <span class="badge-req-id"><%= reqCode %></span>
                                            </td>

                                            <!-- 3. Vehicle Image + Number + Model -->
                                            <td>
                                                <div class="sh-vehicle-cell">
                                                    <img src="<%= vImgSrc %>" 
                                                         alt="<%= vModel %>" 
                                                         class="sh-vehicle-thumb"
                                                         onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-i20.png';">
                                                    <div class="sh-vehicle-info">
                                                        <span class="sh-vehicle-reg"><%= vNum %></span>
                                                        <span class="sh-vehicle-model"><%= vModel %></span>
                                                    </div>
                                                </div>
                                            </td>

                                            <!-- 4. Service Type Icon + Name -->
                                            <td>
                                                <div class="sh-service-type-cell">
                                                    <i class="<%= svcIcon %>"></i>
                                                    <span><%= issue %></span>
                                                </div>
                                            </td>

                                            <!-- 5. Mechanic Portrait + Name + Location -->
                                            <td>
                                                <div class="sh-mechanic-cell">
                                                    <div class="sh-mechanic-thumb" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 1.5px solid #F97316; color: #F97316; font-size: 13px; border-radius: 50%; width: 34px; height: 34px; flex-shrink: 0;">
                                                        <i class="fa-solid fa-wrench"></i>
                                                    </div>
                                                    <div class="sh-mechanic-info">
                                                        <span class="sh-mechanic-name"><%= mName %></span>
                                                        <span class="sh-mechanic-loc"><%= mLoc %></span>
                                                    </div>
                                                </div>
                                            </td>

                                            <!-- 6. Service Date & Time -->
                                            <td>
                                                <div class="sh-datetime-cell">
                                                    <div class="sh-dt-row">
                                                        <i class="fa-regular fa-calendar"></i>
                                                        <span><%= sDate %></span>
                                                    </div>
                                                    <div class="sh-dt-row">
                                                        <i class="fa-regular fa-clock"></i>
                                                        <span><%= sTime %></span>
                                                    </div>
                                                </div>
                                            </td>

                                            <!-- 7. Status Badge -->
                                            <td>
                                                <span class="sh-status-badge <%= statusClass %>">
                                                    <i class="<%= statusIcon %>"></i>
                                                    <span><%= status %></span>
                                                </span>
                                            </td>

                                            <!-- 8. Rating -->
                                            <td style="text-align: center;">
                                                <% 
                                                    String ratingComments = (String) r.get("rating_comments");
                                                    if (ratingComments == null) ratingComments = "";
                                                    String safeComments = ratingComments.replace("\"", "&quot;").replace("'", "&#39;");
                                                    String fullVehicle = (vNum != null ? vNum : "") + " — " + (vModel != null ? vModel : "");
                                                    String safeVehicle = fullVehicle.replace("\"", "&quot;").replace("'", "&#39;");
                                                    String safeMech = (mName != null ? mName : "Unassigned").replace("\"", "&quot;").replace("'", "&#39;");
                                                    String safeIssue = (issue != null ? issue : "").replace("\"", "&quot;").replace("'", "&#39;");
                                                %>
                                                <% if (!"—".equals(rating)) { %>
                                                    <button type="button" class="btn-sh-rated" 
                                                            data-code="<%= reqCode != null ? reqCode : "" %>"
                                                            data-mech="<%= safeMech %>"
                                                            data-issue="<%= safeIssue %>"
                                                            data-vmodel="<%= safeVehicle %>"
                                                            data-rating="<%= rating %>"
                                                            data-comments="<%= safeComments %>"
                                                            onclick="openRatingModalFromBtn(this)" 
                                                            title="Rated <%= rating %> ★ (Click to edit rating)">
                                                        <i class="fa-solid fa-star"></i>
                                                        <span><%= rating %></span>
                                                    </button>
                                                <% } else { %>
                                                    <button type="button" class="btn-sh-rate" 
                                                            data-code="<%= reqCode != null ? reqCode : "" %>"
                                                            data-mech="<%= safeMech %>"
                                                            data-issue="<%= safeIssue %>"
                                                            data-vmodel="<%= safeVehicle %>"
                                                            data-rating=""
                                                            data-comments=""
                                                            onclick="openRatingModalFromBtn(this)"
                                                            title="Rate this completed service">
                                                        <i class="fa-regular fa-star"></i>
                                                        <span>Rate</span>
                                                    </button>
                                                <% } %>
                                            </td>

                                            <!-- 9. View Details Action Button -->
                                            <td style="text-align: center;">
                                                <button type="button" class="btn-sh-view" 
                                                        data-code="<%= reqCode != null ? reqCode : "" %>"
                                                        data-vnum="<%= vNum != null ? vNum : "" %>"
                                                        data-vmodel="<%= vModel != null ? vModel : "" %>"
                                                        data-issue="<%= issue != null ? issue : "" %>"
                                                        data-mech="<%= mName != null ? mName : "Unassigned" %>"
                                                        data-loc="<%= mLoc != null ? mLoc : "—" %>"
                                                        data-phone="<%= phone != null ? phone : "—" %>"
                                                        data-datetime="<%= sDate %> <%= sTime %>"
                                                        data-status="<%= status != null ? status : "Pending" %>"
                                                        data-rating="<%= rating != null ? rating : "—" %>"
                                                        data-comments="<%= safeComments %>"
                                                        onclick="openServiceDetailsModalFromBtn(this)">
                                                    <i class="fa-regular fa-eye"></i>
                                                    <span>View Details</span>
                                                    <span class="sh-details-payload" style="display: none;"><%= details != null && !details.trim().isEmpty() ? details : "Vehicle diagnosed and repaired as per standard breakdown assistance procedure." %></span>
                                                </button>
                                            </td>
                                        </tr>
                                        <%  } %>
                                    </tbody>
                                </table>
                            </div>

                            <!-- 5. Table Footer: Results Count + Pagination Controls -->
                            <div class="sh-table-footer">
                                <div class="sh-showing-text">
                                    Showing <%= showingStart %> to <%= showingEnd %> of <%= filteredTotal %> services
                                </div>

                                <div class="sh-pagination">
                                    <!-- Previous Button -->
                                    <%
                                        String queryBase = "service-history.jsp?search=" + java.net.URLEncoder.encode(search, "UTF-8")
                                                + "&vehicle=" + java.net.URLEncoder.encode(filterVehicle, "UTF-8")
                                                + "&serviceType=" + java.net.URLEncoder.encode(filterServiceType, "UTF-8")
                                                + "&dateRange=" + java.net.URLEncoder.encode(filterDate, "UTF-8");
                                    %>
                                    <a href="<%= (currentPage > 1) ? (queryBase + "&page=" + (currentPage - 1)) : "#" %>" 
                                       class="sh-page-btn <%= (currentPage <= 1) ? "disabled" : "" %>"
                                       aria-label="Previous Page">
                                        &lt; Previous
                                    </a>

                                    <!-- Page Number Buttons -->
                                    <%
                                        for (int p = 1; p <= totalPages; p++) {
                                            boolean isCurr = (p == currentPage);
                                    %>
                                    <a href="<%= isCurr ? "#" : (queryBase + "&page=" + p) %>" 
                                       class="sh-page-btn <%= isCurr ? "active" : "" %>">
                                        <%= p %>
                                    </a>
                                    <%  } %>

                                    <!-- Next Button -->
                                    <a href="<%= (currentPage < totalPages) ? (queryBase + "&page=" + (currentPage + 1)) : "#" %>" 
                                       class="sh-page-btn <%= (currentPage >= totalPages) ? "disabled" : "" %>"
                                       aria-label="Next Page">
                                        Next &gt;
                                    </a>
                                </div>
                            </div>
                        <% } %>
                    </div>

                </div>
            </div>
        </main>
    </div>

    <!-- Universal Rich Service Request Details Modal -->
    <jsp:include page="/common/service-request-view-modal.jsp" />

    <!-- RATING & REVIEW MODAL -->
    <div class="modal-backdrop" id="modalServiceRating" style="display: none; z-index: 2200; align-items: center; justify-content: center; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.6); backdrop-filter: blur(4px);">
        <div class="rating-modal-card">
            <!-- Modal Header -->
            <div class="rating-modal-header">
                <div class="rm-header-left">
                    <div class="rm-star-icon-box">
                        <i class="fa-solid fa-star"></i>
                    </div>
                    <div>
                        <h3 class="rm-modal-title">Rate Service Experience</h3>
                        <p class="rm-modal-sub">Share your feedback to help improve workshop quality</p>
                    </div>
                </div>
                <button type="button" class="rm-close-btn" onclick="closeRatingModal()" aria-label="Close Rating Modal">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>

            <!-- Service Info Summary Banner -->
            <div class="rm-service-banner">
                <div class="rm-service-banner-top">
                    <span class="rm-req-badge" id="rmReqCode">SR0472</span>
                    <span class="rm-status-badge"><i class="fa-solid fa-circle-check"></i> Completed Service</span>
                </div>
                <div class="rm-service-meta">
                    <div class="rm-meta-item">
                        <i class="fa-solid fa-wrench"></i>
                        <span id="rmMechName">Sathish Multi-brand Garage</span>
                    </div>
                    <div class="rm-meta-item">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                        <span id="rmIssueName">Tyre / Puncture</span>
                    </div>
                    <div class="rm-meta-item">
                        <i class="fa-solid fa-car"></i>
                        <span id="rmVehicleInfo">TN 45 BT 6229 — BMW M5 Competition</span>
                    </div>
                </div>
            </div>

            <!-- Rating Section -->
            <div class="rm-rating-section">
                <label class="rm-section-label">Your Overall Experience</label>
                <div class="rm-stars-container" id="rmStarContainer">
                    <button type="button" class="rm-star-btn active" data-score="1" onclick="setRatingScore(1)" onmouseenter="previewRating(1)" onmouseleave="resetRatingPreview()">
                        <i class="fa-solid fa-star"></i>
                    </button>
                    <button type="button" class="rm-star-btn active" data-score="2" onclick="setRatingScore(2)" onmouseenter="previewRating(2)" onmouseleave="resetRatingPreview()">
                        <i class="fa-solid fa-star"></i>
                    </button>
                    <button type="button" class="rm-star-btn active" data-score="3" onclick="setRatingScore(3)" onmouseenter="previewRating(3)" onmouseleave="resetRatingPreview()">
                        <i class="fa-solid fa-star"></i>
                    </button>
                    <button type="button" class="rm-star-btn active" data-score="4" onclick="setRatingScore(4)" onmouseenter="previewRating(4)" onmouseleave="resetRatingPreview()">
                        <i class="fa-solid fa-star"></i>
                    </button>
                    <button type="button" class="rm-star-btn active" data-score="5" onclick="setRatingScore(5)" onmouseenter="previewRating(5)" onmouseleave="resetRatingPreview()">
                        <i class="fa-solid fa-star"></i>
                    </button>
                </div>
                <div class="rm-score-caption" id="rmScoreCaption">5.0 ★ — Excellent! Highly recommended</div>
                <input type="hidden" id="rmRatingValue" value="5">
                <input type="hidden" id="rmHiddenReqCode" value="">
            </div>

            <!-- Quick Compliment Tags -->
            <div class="rm-tags-section">
                <label class="rm-section-label" style="font-size: 12px; color: #64748B;">Quick Tags (Click to include):</label>
                <div class="rm-tag-chips">
                    <button type="button" class="rm-chip" onclick="toggleReviewTag(this, 'Quick & On-Time Arrival')">⚡ Quick Arrival</button>
                    <button type="button" class="rm-chip" onclick="toggleReviewTag(this, 'Skilled & Professional')">🔧 Skilled Technician</button>
                    <button type="button" class="rm-chip" onclick="toggleReviewTag(this, 'Fair & Transparent Pricing')">💰 Fair Pricing</button>
                    <button type="button" class="rm-chip" onclick="toggleReviewTag(this, 'Polite & Courteous')">🤝 Courteous</button>
                    <button type="button" class="rm-chip" onclick="toggleReviewTag(this, 'Highly Recommended')">⭐ Highly Recommended</button>
                </div>
            </div>

            <!-- Detailed Feedback Comments -->
            <div class="rm-comments-section">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                    <label for="rmReviewComments" class="rm-section-label" style="margin-bottom: 0;">Review Comments (Optional)</label>
                    <span class="rm-char-count" id="rmCharCount">0 / 500</span>
                </div>
                <textarea id="rmReviewComments" class="rm-textarea" rows="3" maxlength="500" 
                          placeholder="Share details about the technician's arrival, repair quality, communication, or overall assistance..."
                          oninput="updateCharCount()"></textarea>
            </div>

            <!-- Alert / Status message container -->
            <div id="rmAlertMsg" class="rm-alert-box" style="display: none;"></div>

            <!-- Modal Actions Footer -->
            <div class="rating-modal-footer">
                <button type="button" class="rm-btn-cancel" onclick="closeRatingModal()">Cancel</button>
                <button type="button" class="rm-btn-submit" id="rmBtnSubmit" onclick="submitServiceRating()">
                    <i class="fa-solid fa-paper-plane"></i>
                    <span>Submit Rating</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Floating Notification Toast Container -->
    <div id="shToastContainer" class="sh-toast-container"></div>

    <!-- Interactive JavaScript -->
    <script>
        var activeRatingBtn = null;
        var selectedRating = 5;

        var ratingCaptions = {
            1: "1.0 ★ — Poor service",
            2: "2.0 ★ — Fair, needs improvement",
            3: "3.0 ★ — Good / Satisfactory",
            4: "4.0 ★ — Very Good service",
            5: "5.0 ★ — Excellent! Highly recommended"
        };

        function openRatingModalFromBtn(btn) {
            if (!btn) return;
            var code = btn.getAttribute('data-code') || '';
            var mech = btn.getAttribute('data-mech') || 'Unassigned';
            var issue = btn.getAttribute('data-issue') || '';
            var vmodel = btn.getAttribute('data-vmodel') || '';
            var rating = btn.getAttribute('data-rating') || '';
            var comments = btn.getAttribute('data-comments') || '';
            openRatingModal(code, mech, issue, vmodel, rating, comments, btn);
        }

        function openRatingModal(code, mech, issue, vmodel, rating, comments, triggeringBtn) {
            activeRatingBtn = triggeringBtn || null;
            document.getElementById('rmReqCode').textContent = code || '—';
            document.getElementById('rmMechName').textContent = mech || 'Workshop';
            document.getElementById('rmIssueName').textContent = issue || 'Breakdown Assistance';
            document.getElementById('rmVehicleInfo').textContent = vmodel || 'Registered Vehicle';
            document.getElementById('rmHiddenReqCode').value = code || '';
            document.getElementById('rmReviewComments').value = comments || '';
            updateCharCount();

            // Clear tags active state
            var chips = document.querySelectorAll('.rm-chip');
            chips.forEach(function(c) {
                var txt = c.textContent.replace(/^[^\w\s]+/, '').trim();
                if (comments && comments.indexOf(txt) !== -1) {
                    c.classList.add('active');
                } else {
                    c.classList.remove('active');
                }
            });

            // Set score
            var score = parseInt(rating, 10);
            if (!score || score < 1 || score > 5) {
                score = 5;
            }
            setRatingScore(score);

            // Clear previous alerts
            var alertBox = document.getElementById('rmAlertMsg');
            alertBox.style.display = 'none';
            alertBox.className = 'rm-alert-box';
            alertBox.textContent = '';

            var submitBtn = document.getElementById('rmBtnSubmit');
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Submit Rating</span>';

            var modal = document.getElementById('modalServiceRating');
            modal.style.display = 'flex';
        }

        function closeRatingModal() {
            var modal = document.getElementById('modalServiceRating');
            modal.style.display = 'none';
        }

        function setRatingScore(score) {
            selectedRating = score;
            document.getElementById('rmRatingValue').value = score;
            highlightStars(score);
            document.getElementById('rmScoreCaption').textContent = ratingCaptions[score] || (score + '.0 ★');
        }

        function previewRating(score) {
            highlightStars(score);
            document.getElementById('rmScoreCaption').textContent = ratingCaptions[score] || (score + '.0 ★');
        }

        function resetRatingPreview() {
            highlightStars(selectedRating);
            document.getElementById('rmScoreCaption').textContent = ratingCaptions[selectedRating] || (selectedRating + '.0 ★');
        }

        function highlightStars(score) {
            var starBtns = document.querySelectorAll('#rmStarContainer .rm-star-btn');
            starBtns.forEach(function(btn) {
                var s = parseInt(btn.getAttribute('data-score'), 10);
                if (s <= score) {
                    btn.classList.add('active');
                } else {
                    btn.classList.remove('active');
                }
            });
        }

        function toggleReviewTag(chip, tagText) {
            var textarea = document.getElementById('rmReviewComments');
            var curr = textarea.value.trim();
            if (chip.classList.contains('active')) {
                chip.classList.remove('active');
                curr = curr.replace(tagText, '').replace(/,\s*,/g, ',').replace(/^,\s*/, '').replace(/,\s*$/, '').trim();
                textarea.value = curr;
            } else {
                chip.classList.add('active');
                if (curr.length > 0) {
                    textarea.value = curr + ', ' + tagText;
                } else {
                    textarea.value = tagText;
                }
            }
            updateCharCount();
        }

        function updateCharCount() {
            var textarea = document.getElementById('rmReviewComments');
            var count = textarea.value.length;
            document.getElementById('rmCharCount').textContent = count + ' / 500';
        }

        function showShToast(msg, type) {
            var container = document.getElementById('shToastContainer');
            if (!container) return;
            var toast = document.createElement('div');
            toast.className = 'sh-toast ' + (type || 'success');
            var iconClass = (type === 'error') ? 'fa-solid fa-circle-exclamation' : 'fa-solid fa-circle-check';
            toast.innerHTML = '<i class="' + iconClass + '" style="color: ' + (type === 'error' ? '#EF4444' : '#10B981') + ';"></i> <span>' + msg + '</span>';
            container.appendChild(toast);
            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transform = 'translateY(10px)';
                toast.style.transition = 'all 0.3s ease';
                setTimeout(function() { toast.remove(); }, 300);
            }, 3500);
        }

        function submitServiceRating() {
            var reqCode = document.getElementById('rmHiddenReqCode').value.trim();
            var ratingVal = document.getElementById('rmRatingValue').value.trim();
            var comments = document.getElementById('rmReviewComments').value.trim();
            var submitBtn = document.getElementById('rmBtnSubmit');
            var alertBox = document.getElementById('rmAlertMsg');

            if (!reqCode) {
                alertBox.textContent = 'Invalid request identifier.';
                alertBox.className = 'rm-alert-box error';
                alertBox.style.display = 'block';
                return;
            }

            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Saving...</span>';

            var params = 'action=submitRating' +
                         '&requestCode=' + encodeURIComponent(reqCode) +
                         '&rating=' + encodeURIComponent(ratingVal) +
                         '&comments=' + encodeURIComponent(comments) +
                         '&ajax=true';

            fetch('service-history.jsp', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params
            })
            .then(function(res) {
                return res.json();
            })
            .then(function(data) {
                if (data.success) {
                    alertBox.textContent = data.message || 'Rating submitted successfully!';
                    alertBox.className = 'rm-alert-box success';
                    alertBox.style.display = 'block';

                    // Update Table Cell Button if present
                    if (activeRatingBtn) {
                        activeRatingBtn.className = 'btn-sh-rated';
                        activeRatingBtn.setAttribute('data-rating', data.rating);
                        activeRatingBtn.setAttribute('data-comments', comments);
                        activeRatingBtn.setAttribute('title', 'Rated ' + data.rating + ' ★ (Click to edit rating)');
                        activeRatingBtn.innerHTML = '<i class="fa-solid fa-star"></i> <span>' + data.rating + '</span>';
                    }

                    // Dynamically update Top Stat Card if score >= 4
                    var statSpan = document.getElementById('shStatTopRatedVal');
                    if (statSpan && parseFloat(ratingVal) >= 4) {
                        var currStat = parseInt(statSpan.textContent.trim(), 10) || 0;
                        if (!activeRatingBtn || !activeRatingBtn.hasAttribute('data-previously-rated')) {
                            statSpan.textContent = currStat + 1;
                            if (activeRatingBtn) activeRatingBtn.setAttribute('data-previously-rated', 'true');
                        }
                    }

                    showShToast('Rating of ' + data.rating + ' ★ submitted for ' + reqCode + '!', 'success');

                    setTimeout(function() {
                        closeRatingModal();
                    }, 800);
                } else {
                    alertBox.textContent = data.message || 'Failed to submit rating.';
                    alertBox.className = 'rm-alert-box error';
                    alertBox.style.display = 'block';
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Submit Rating</span>';
                }
            })
            .catch(function(err) {
                alertBox.textContent = 'Network or server error occurred. Please try again.';
                alertBox.className = 'rm-alert-box error';
                alertBox.style.display = 'block';
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Submit Rating</span>';
            });
        }

        function openServiceDetailsModalFromBtn(btn) {
            if (!btn) return;
            var code = btn.getAttribute('data-id') || btn.getAttribute('data-code') || '';
            var vNum = btn.getAttribute('data-vnum') || '';
            var vModel = btn.getAttribute('data-vmodel') || '';
            var issue = btn.getAttribute('data-issue') || '';
            var mech = btn.getAttribute('data-mech') || 'Unassigned';
            var loc = btn.getAttribute('data-loc') || '—';
            var phone = btn.getAttribute('data-phone') || '—';
            var dt = btn.getAttribute('data-datetime') || '—';
            var status = btn.getAttribute('data-status') || 'Pending';
            var rating = btn.getAttribute('data-rating') || '—';
            var comments = btn.getAttribute('data-comments') || '';
            var notesSpan = btn.querySelector('.sh-details-payload');
            var details = notesSpan ? notesSpan.textContent : '';

            // Inject "Rate Service" button in view modal footer actions
            var actionsContainer = document.getElementById('svModalContextActions');
            if (actionsContainer) {
                var rateBtnText = (rating && rating !== '—') ? ('Rated ★ ' + rating + ' (Edit)') : 'Rate Service';
                var rateBtnIcon = (rating && rating !== '—') ? 'fa-solid fa-star' : 'fa-regular fa-star';
                var safeVInfo = (vNum + ' — ' + vModel).replace(/'/g, "\\'");
                var safeMech = mech.replace(/'/g, "\\'");
                var safeIssue = issue.replace(/'/g, "\\'");
                var safeRating = (rating === '—') ? '' : rating;
                var safeComments = comments.replace(/'/g, "\\'");

                actionsContainer.innerHTML = '<button type="button" class="btn-action-primary" style="background: #F97316; border: 1.5px solid #EA580C; color: #FFFFFF; font-weight: 700; padding: 7px 16px; border-radius: 8px; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; font-size: 13px;" onclick="closeServiceRequestModal(); openRatingModal(\'' + code + '\', \'' + safeMech + '\', \'' + safeIssue + '\', \'' + safeVInfo + '\', \'' + safeRating + '\', \'' + safeComments + '\', null);"><i class="' + rateBtnIcon + '"></i> ' + rateBtnText + '</button>';
            }

            window.openServiceRequestModal({
                code: code,
                vehicleNumber: vNum,
                brandModel: vModel,
                issue: issue,
                mechName: mech,
                location: loc,
                mechPhone: phone,
                reqDate: dt,
                status: status,
                description: details,
                rating: rating,
                comments: comments
            });
        }

        window.openRatingModal = openRatingModal;
        window.closeRatingModal = closeRatingModal;

        function closeServiceDetailsModal() {
            window.closeServiceRequestModal();
        }

        // Close on ESC key or Backdrop Click
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeRatingModal();
                closeServiceDetailsModal();
            }
        });

        document.getElementById('modalServiceRating').addEventListener('click', function(e) {
            if (e.target === this) {
                closeRatingModal();
            }
        });
    </script>
</body>
</html>
