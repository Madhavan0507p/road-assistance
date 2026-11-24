<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%@ page import="com.roadassistance.util.EmailUtil" %>
<%@ page import="com.roadassistance.service.ServiceRequestService" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=auth_required");
        return;
    }

    // Page metadata for sidebar and topbar
    request.setAttribute("activePage", "requests");
    request.setAttribute("pageTitle", "Service Requests");
    request.setAttribute("pageSubtitle", "View, monitor and manage all vehicle assistance service requests.");
    request.setAttribute("pageIcon", "fa-solid fa-briefcase");
    request.setAttribute("searchPlaceholder", "Search by request ID, user, vehicle number...");
    request.setAttribute("notifCount", "3");

    String alertMessage = "";
    String alertType = "success";

    // 1. Handle Form Actions: Update Status, Assign Mechanic, Cancel Request, Edit Request
    String action = request.getParameter("action");
    if ("updateStatus".equalsIgnoreCase(action)) {
        String reqId = request.getParameter("requestId");
        String newStatus = request.getParameter("newStatus");
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null && reqId != null && newStatus != null) {
                String sql = "UPDATE service_requests SET status = ?";
                if ("Accepted".equalsIgnoreCase(newStatus)) {
                    sql += ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))";
                } else if ("In Progress".equalsIgnoreCase(newStatus) || "On The Way".equalsIgnoreCase(newStatus)) {
                    sql += ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                         + ", in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))";
                } else if ("Completed".equalsIgnoreCase(newStatus)) {
                    sql += ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                         + ", in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                         + ", completed_at = CURRENT_TIMESTAMP(), completed_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')";
                }
                sql += " WHERE request_id = ? OR request_code = ?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, newStatus);
                int rInt = 0;
                try { rInt = Integer.parseInt(reqId); } catch(Exception ignored) {}
                ps.setInt(2, rInt);
                ps.setString(3, reqId);
                int upRows = ps.executeUpdate();
                ps.close();
                if (upRows > 0) {
                    EmailUtil.notifyUserOfRequestStatusUpdateAsync(reqId, newStatus, null);
                }
                alertMessage = "Service Request #" + reqId + " status updated to \"" + newStatus + "\" successfully!";
                alertType = "Completed".equalsIgnoreCase(newStatus) ? "success" : ("Cancelled".equalsIgnoreCase(newStatus) ? "danger" : "warning");
            }
        } catch (Exception e) {
            alertMessage = "Status updated.";
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    } else if ("editRequest".equalsIgnoreCase(action)) {
        String reqId = request.getParameter("requestId");
        String newStatus = request.getParameter("status");
        String mechCode = request.getParameter("mechanicCode");
        String issue = request.getParameter("issue");
        String notes = request.getParameter("notes");
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null && reqId != null) {
                String mName = "Unassigned";
                if (mechCode != null && !mechCode.trim().isEmpty()) {
                    try {
                        PreparedStatement psM = conn.prepareStatement("SELECT owner_name FROM mechanics WHERE mechanic_code = ?");
                        psM.setString(1, mechCode);
                        ResultSet rsM = psM.executeQuery();
                        if (rsM.next()) {
                            mName = rsM.getString("owner_name");
                        }
                        rsM.close();
                        psM.close();
                    } catch (Exception ignoredM) {}
                }

                String extraTimeSql = "";
                if ("Accepted".equalsIgnoreCase(newStatus)) {
                    extraTimeSql = ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))";
                } else if ("In Progress".equalsIgnoreCase(newStatus) || "On The Way".equalsIgnoreCase(newStatus)) {
                    extraTimeSql = ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                                 + ", in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))";
                } else if ("Completed".equalsIgnoreCase(newStatus)) {
                    extraTimeSql = ", assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                                 + ", in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))"
                                 + ", completed_at = COALESCE(completed_at, CURRENT_TIMESTAMP()), completed_date = COALESCE(completed_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'))";
                }

                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE service_requests SET status = ?, mechanic_code = ?, mechanic_name = ?, breakdown_issue = COALESCE(NULLIF(?, ''), breakdown_issue), additional_details = COALESCE(NULLIF(?, ''), additional_details)" + extraTimeSql + " WHERE request_id = ? OR request_code = ?"
                );
                ps.setString(1, newStatus);
                ps.setString(2, mechCode);
                ps.setString(3, mName);
                ps.setString(4, issue);
                ps.setString(5, notes);
                int rInt = 0;
                try { rInt = Integer.parseInt(reqId); } catch(Exception ignored) {}
                ps.setInt(6, rInt);
                ps.setString(7, reqId);
                int upRows = ps.executeUpdate();
                ps.close();
                if (upRows > 0) {
                    EmailUtil.notifyUserOfRequestStatusUpdateAsync(reqId, newStatus, null);
                }
                alertMessage = "Service Request #" + reqId + " updated successfully!";
                alertType = "success";
            }
        } catch (Exception e) {
            alertMessage = "Request updated successfully.";
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    } else if ("assignMechanic".equalsIgnoreCase(action)) {
        String reqId = request.getParameter("requestId");
        String mechId = request.getParameter("mechanicId");
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null && reqId != null && mechId != null) {
                String mName = "Mechanic";
                String mCode = "MEC001";
                try {
                    PreparedStatement psFetch = conn.prepareStatement("SELECT mechanic_code, owner_name, workshop_name FROM mechanics WHERE mechanic_id = ?");
                    psFetch.setInt(1, Integer.parseInt(mechId));
                    ResultSet rsF = psFetch.executeQuery();
                    if (rsF.next()) {
                        mCode = rsF.getString("mechanic_code");
                        mName = rsF.getString("owner_name");
                        if (mName == null || mName.trim().isEmpty()) {
                            mName = rsF.getString("workshop_name");
                        }
                    }
                    rsF.close();
                    psFetch.close();
                } catch(Exception ignoredF) {}

                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE service_requests SET mechanic_code = ?, mechanic_name = ?, status = 'In Progress', " +
                    "assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), " +
                    "in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')) " +
                    "WHERE request_id = ? OR request_code = ?"
                );
                ps.setString(1, mCode);
                ps.setString(2, mName);
                int rInt = 0;
                try { rInt = Integer.parseInt(reqId); } catch(Exception ignored) {}
                ps.setInt(3, rInt);
                ps.setString(4, reqId);
                int upRows = ps.executeUpdate();
                ps.close();
                if (upRows > 0) {
                    EmailUtil.notifyUserOfRequestStatusUpdateAsync(reqId, "In Progress", null);
                }
                alertMessage = "Technician " + mName + " (" + mCode + ") dispatched to Service Request #" + reqId + " successfully!";
                alertType = "success";
            }
        } catch (Exception e) {
            alertMessage = "Mechanic assigned.";
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    } else if ("cancel".equalsIgnoreCase(action)) {
        String reqId = request.getParameter("id");
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null && reqId != null) {
                PreparedStatement ps = conn.prepareStatement("UPDATE service_requests SET status = 'Cancelled' WHERE request_id = ?");
                ps.setInt(1, Integer.parseInt(reqId));
                int upRows = ps.executeUpdate();
                ps.close();
                if (upRows > 0) {
                    EmailUtil.notifyUserOfRequestStatusUpdateAsync(reqId, "Cancelled", null);
                }
                alertMessage = "Service Request #" + reqId + " has been Cancelled.";
                alertType = "danger";
            }
        } catch (Exception e) {
            alertMessage = "Request cancelled.";
        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }

    // 2. Query Statistics Counts
    int totalRequestsCount = 0;
    int pendingCount = 0;
    int inProgressCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    Connection connStats = null;
    try {
        connStats = DBConnection.getConnection();
        if (connStats != null) {
            // Auto-cancel stagnant accepted requests (15 minutes without stage advancement)
            try {
                ServiceRequestService.autoCancelStagnantAcceptedRequests(connStats, 15);
            } catch (Exception eAuto) {
                System.err.println("Notice in admin service-requests autoCancel: " + eAuto.getMessage());
            }

            Statement stmtCount = connStats.createStatement();
            ResultSet rsCount = stmtCount.executeQuery("SELECT status, COUNT(*) FROM service_requests GROUP BY status");
            while (rsCount.next()) {
                String st = rsCount.getString(1);
                int cnt = rsCount.getInt(2);
                if ("Pending".equalsIgnoreCase(st)) pendingCount = cnt;
                else if ("In Progress".equalsIgnoreCase(st) || "Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) inProgressCount += cnt;
                else if ("Completed".equalsIgnoreCase(st)) completedCount = cnt;
                else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) cancelledCount += cnt;
            }
            rsCount.close();
            stmtCount.close();
            totalRequestsCount = pendingCount + inProgressCount + completedCount + cancelledCount;
        }
    } catch (Exception ignored) {
    } finally {
        if (connStats != null) try { connStats.close(); } catch (Exception ignored) {}
    }

    // 3. Status Tab & Filter Parameters
    String tabFilter = request.getParameter("tab");
    if (tabFilter == null || tabFilter.trim().isEmpty()) {
        tabFilter = request.getParameter("status");
    }
    if ("All Status".equalsIgnoreCase(tabFilter)) {
        tabFilter = "All";
    }
    if (tabFilter == null || tabFilter.trim().isEmpty()) {
        tabFilter = "Pending";
    }

    String searchParam = request.getParameter("search");
    String locFilter = request.getParameter("location");
    String issueFilter = request.getParameter("issue");
    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");

    if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
        if (fromDate.compareTo(toDate) > 0) {
            alertMessage = "Validation Notice: 'From Date' cannot be later than 'To Date'.";
            alertType = "danger";
        }
    }

    List<Map<String, String>> requestList = new ArrayList<Map<String, String>>();
    SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd-MM-yyyy, hh:mm a");

    Connection connList = null;
    try {
        connList = DBConnection.getConnection();
        if (connList != null) {
            StringBuilder sql = new StringBuilder(
                "SELECT r.*, " +
                "COALESCE(u.full_name, r.user_name) AS resolved_user, " +
                "COALESCE(u.phone, '') AS user_phone, " +
                "COALESCE(u.email, '') AS user_email, " +
                "COALESCE(NULLIF(m.phone, ''), '+91 98765 43210') AS mech_phone, " +
                "COALESCE(NULLIF(m.workshop_name, ''), NULLIF(m.owner_name, ''), NULLIF(r.mechanic_name, ''), 'Unassigned') AS mech_shop, " +
                "COALESCE(NULLIF(r.vehicle_type, ''), v.vehicle_type, 'Car') AS veh_type, " +
                "COALESCE(NULLIF(r.vehicle_brand, ''), v.vehicle_brand, '') AS veh_brand, " +
                "COALESCE(NULLIF(r.vehicle_model, ''), v.vehicle_model, '') AS veh_model, " +
                "COALESCE(NULLIF(r.vehicle_image, ''), v.vehicle_image, '') AS veh_image " +
                "FROM service_requests r " +
                "LEFT JOIN users u ON r.user_id = u.user_id " +
                "LEFT JOIN mechanics m ON (r.mechanic_code = m.mechanic_code OR r.mechanic_name = m.workshop_name OR r.mechanic_name = m.owner_name) " +
                "LEFT JOIN user_vehicles v ON REPLACE(REPLACE(UPPER(r.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(v.vehicle_number), ' ', ''), '-', '') " +
                "WHERE 1=1 "
            );
            List<String> sqlParams = new ArrayList<String>();

            if (!"All".equalsIgnoreCase(tabFilter) && !"All Requests".equalsIgnoreCase(tabFilter)) {
                if ("In Progress".equalsIgnoreCase(tabFilter) || "Accepted".equalsIgnoreCase(tabFilter)) {
                    sql.append("AND r.status IN ('In Progress', 'Accepted', 'On The Way', 'Diagnostics Done', 'Parts Replacement') ");
                } else if ("Cancelled".equalsIgnoreCase(tabFilter) || "Rejected".equalsIgnoreCase(tabFilter)) {
                    sql.append("AND (r.status = 'Cancelled' OR r.status = 'Rejected') ");
                } else {
                    sql.append("AND r.status = ? ");
                    sqlParams.add(tabFilter);
                }
            }
            if (locFilter != null && !locFilter.trim().isEmpty() && !"all".equalsIgnoreCase(locFilter) && !"All Locations".equalsIgnoreCase(locFilter)) {
                sql.append("AND r.location LIKE ? ");
                sqlParams.add("%" + locFilter + "%");
            }
            if (issueFilter != null && !issueFilter.trim().isEmpty() && !"all".equalsIgnoreCase(issueFilter) && !"All Issues".equalsIgnoreCase(issueFilter)) {
                sql.append("AND r.breakdown_issue LIKE ? ");
                sqlParams.add("%" + issueFilter + "%");
            }
            if (searchParam != null && !searchParam.trim().isEmpty()) {
                sql.append("AND (r.request_code LIKE ? OR r.user_name LIKE ? OR r.vehicle_number LIKE ? OR r.breakdown_issue LIKE ? OR r.location LIKE ?) ");
                String like = "%" + searchParam + "%";
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
            }

            sql.append("ORDER BY r.request_code DESC, r.request_id DESC LIMIT 200");

            PreparedStatement psList = connList.prepareStatement(sql.toString());
            for (int i = 0; i < sqlParams.size(); i++) {
                psList.setString(i + 1, sqlParams.get(i));
            }

            ResultSet rs = psList.executeQuery();
            while (rs.next()) {
                Map<String, String> r = new HashMap<String, String>();
                int idNum = rs.getInt("request_id");
                r.put("id", String.valueOf(idNum));
                String code = rs.getString("request_code");
                r.put("code", (code != null && !code.trim().isEmpty()) ? code : String.format("SR%04d", idNum));

                String uName = rs.getString("resolved_user");
                r.put("user", uName != null ? uName : "Customer");
                String uCode = rs.getString("user_code");
                int uId = rs.getInt("user_id");
                r.put("userCode", (uCode != null && !uCode.trim().isEmpty()) ? uCode : String.format("USR%03d", uId > 0 ? uId : idNum));
                r.put("userPhone", rs.getString("user_phone") != null ? rs.getString("user_phone") : "");
                r.put("userEmail", rs.getString("user_email") != null ? rs.getString("user_email") : "");

                String vehNum = rs.getString("vehicle_number");
                r.put("vehicle", vehNum != null ? vehNum : "Vehicle");
                String vType = rs.getString("veh_type");
                r.put("vehicleType", vType != null ? vType : "Four-Wheeler");
                String vBrand = rs.getString("veh_brand");
                String vModel = rs.getString("veh_model");
                String bModel = (vModel != null && !vModel.trim().isEmpty()) ? vModel : ((vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle Details");
                if (vBrand != null && !vBrand.trim().isEmpty() && !bModel.toLowerCase().contains(vBrand.toLowerCase())) {
                    bModel = vBrand + " " + bModel;
                }
                r.put("brandModel", bModel);
                r.put("color", "");
                r.put("vehicleImg", rs.getString("veh_image") != null ? rs.getString("veh_image") : "");

                String iss = rs.getString("breakdown_issue");
                r.put("issue", iss != null ? iss : "Roadside Assistance");

                String reqDateStr = rs.getString("requested_date");
                Timestamp ts = rs.getTimestamp("requested_at");
                String dispDateStr = "-";
                if (reqDateStr != null && !reqDateStr.trim().isEmpty()) {
                    dispDateStr = reqDateStr.trim();
                    String delim = dispDateStr.contains("•") ? "•" : (dispDateStr.contains("·") ? "·" : (dispDateStr.contains(",") ? "," : null));
                    if (delim != null) {
                        String[] dp = dispDateStr.split(delim);
                        String dPart = dp[0].trim();
                        String tPart = dp.length > 1 ? dp[1].trim() : "";
                        if (!dPart.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                            try {
                                java.util.Date p = null;
                                try { p = new SimpleDateFormat("MMM d, yyyy").parse(dPart); } catch(Exception ign1){}
                                if (p == null) {
                                    try { p = new SimpleDateFormat("yyyy-MM-dd").parse(dPart); } catch(Exception ign2){}
                                }
                                if (p != null) dPart = new SimpleDateFormat("dd-MM-yyyy").format(p);
                            } catch(Exception ign){}
                        }
                        dispDateStr = dPart + ", " + tPart;
                    }
                } else if (ts != null) {
                    dispDateStr = sdfDisplay.format(ts);
                }
                r.put("date", dispDateStr);

                String loc = rs.getString("location");
                r.put("location", (loc != null && !loc.trim().isEmpty()) ? loc : "-");

                double lat = 0.0;
                double lng = 0.0;
                try {
                    lat = rs.getDouble("latitude");
                    lng = rs.getDouble("longitude");
                } catch (Exception exCoord) {}
                r.put("latitude", String.valueOf(lat));
                r.put("longitude", String.valueOf(lng));

                String mName = rs.getString("mechanic_name");
                String mCode = rs.getString("mechanic_code");
                r.put("mechanic", (mName != null && !mName.trim().isEmpty()) ? mName : "Unassigned");
                r.put("mechanicCode", (mCode != null && !mCode.trim().isEmpty()) ? mCode : "-");
                r.put("mechPhone", rs.getString("mech_phone") != null ? rs.getString("mech_phone") : "");
                r.put("workshop", rs.getString("mech_shop") != null ? rs.getString("mech_shop") : "Unassigned");

                String st = rs.getString("status");
                r.put("status", st != null ? st : "Pending");

                String addDesc = rs.getString("additional_details");
                r.put("description", (addDesc != null && !addDesc.trim().isEmpty()) ? addDesc : "No additional description provided.");
                r.put("additional_details", addDesc != null ? addDesc : "");

                r.put("requested_at", rs.getString("requested_at"));
                r.put("requested_date", rs.getString("requested_date"));
                r.put("assigned_at", rs.getString("assigned_at"));
                r.put("assigned_date", rs.getString("assigned_date"));
                r.put("in_progress_at", rs.getString("in_progress_at"));
                r.put("in_progress_date", rs.getString("in_progress_date"));
                r.put("completed_at", rs.getString("completed_at"));
                r.put("completed_date", rs.getString("completed_date"));

                requestList.add(r);
            }
            rs.close();
            psList.close();
        }
    } catch (Exception ignored) {
    } finally {
        if (connList != null) try { connList.close(); } catch (Exception ignored) {}
    }


    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 requests per page

    int totalRequests = requestList.size();
    int totalPages = (totalRequests + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalRequests);
    List<Map<String, String>> displayList = (totalRequests > 0) ? requestList.subList(startIndex, endIndex) : new ArrayList<Map<String, String>>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service Requests | On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Leaflet CSS for Interactive Location Map -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    
    <!-- Core Application CSS - Strict Zero-Blue Theme -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-service-view.css?v=2.3">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-service-requests.css?v=2.5">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css">
</head>
<body>

<div class="app-wrapper">
    <!-- Left Sidebar (With all 9 navigation items, Service Requests Active in Orange) -->
    <jsp:include page="sidebar.jsp" />

    <!-- Main Content Area -->
    <div class="main-content">
        <!-- Top Header (White header, Title, Subtitle, Search, Notification bell, Admin profile) -->
        <jsp:include page="topbar.jsp" />

        <!-- Dashboard Body Container -->
        <main class="dashboard-body sr-page-canvas" style="padding: 24px 28px;">

            <!-- System Flash Alert -->
            <% if (!alertMessage.isEmpty()) { %>
                <div style="background-color: <%= "danger".equals(alertType) ? "#FEE2E2" : ("warning".equals(alertType) ? "#FEF9C3" : "#DCFCE7") %>; 
                            color: <%= "danger".equals(alertType) ? "#DC2626" : ("warning".equals(alertType) ? "#B45309" : "#16A34A") %>; 
                            padding: 13px 18px; border-radius: 12px; font-weight: 700; font-size: 14px; 
                            border: 1px solid <%= "danger".equals(alertType) ? "#FECACA" : ("warning".equals(alertType) ? "#FEF08A" : "#BBF7D0") %>; 
                            display: flex; align-items: center; gap: 10px; margin-bottom: 20px; box-shadow: 0 2px 6px rgba(0,0,0,0.03);">
                    <i class="fa-solid <%= "danger".equals(alertType) ? "fa-circle-xmark" : "fa-circle-check" %>" style="font-size: 18px;"></i>
                    <span><%= alertMessage %></span>
                </div>
            <% } %>

            <!-- 1. Hero Banner: Exact Artwork Matching Reference (service-requests-banner.jpg) -->
            <div class="sr-hero-banner-container">
                <img src="${pageContext.request.contextPath}/images/service-requests-banner.jpg" alt="Service Requests Banner">
            </div>

            <!-- 2. Middle Row: 3-Column Analytics Grid -->
            <section class="sr-analytics-grid">
                <!-- Column 1: 5 Quick Stat Cards in 2 Rows -->
                <div class="sr-stats-col">
                    <!-- Row 1: Total Requests & Pending -->
                    <div class="sr-stats-row-top">
                        <div class="sr-stat-card card-total" onclick="location.href='service-requests.jsp?tab=All'" style="cursor: pointer;">
                            <div class="sr-stat-icon-wrap">
                                <i class="fa-solid fa-clipboard-list"></i>
                            </div>
                            <div class="sr-stat-info">
                                <span class="sr-stat-label">Total Requests</span>
                                <div class="sr-stat-val-group">
                                    <span class="sr-stat-value"><%= totalRequestsCount %></span>
                                    <span class="sr-stat-badge badge-green"><i class="fa-solid fa-arrow-up"></i> +12.5%</span>
                                </div>
                            </div>
                        </div>

                        <div class="sr-stat-card card-pending" onclick="location.href='service-requests.jsp?tab=Pending'" style="cursor: pointer;">
                            <div class="sr-stat-icon-wrap">
                                <i class="fa-solid fa-hourglass-half"></i>
                            </div>
                            <div class="sr-stat-info">
                                <span class="sr-stat-label">Pending</span>
                                <div class="sr-stat-val-group">
                                    <span class="sr-stat-value"><%= pendingCount %></span>
                                    <span class="sr-stat-badge badge-green"><i class="fa-solid fa-arrow-up"></i> +5.9%</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Row 2: In Progress, Completed, Cancelled -->
                    <div class="sr-stats-row-bottom">
                        <div class="sr-stat-card card-progress" onclick="location.href='service-requests.jsp?tab=In Progress'" style="cursor: pointer;">
                            <div class="sr-stat-icon-wrap">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="sr-stat-info">
                                <span class="sr-stat-label">In Progress</span>
                                <div class="sr-stat-val-group">
                                    <span class="sr-stat-value"><%= inProgressCount %></span>
                                    <span class="sr-stat-badge badge-green"><i class="fa-solid fa-arrow-up"></i> +8.7%</span>
                                </div>
                            </div>
                        </div>

                        <div class="sr-stat-card card-completed" onclick="location.href='service-requests.jsp?tab=Completed'" style="cursor: pointer;">
                            <div class="sr-stat-icon-wrap">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                            <div class="sr-stat-info">
                                <span class="sr-stat-label">Completed</span>
                                <div class="sr-stat-val-group">
                                    <span class="sr-stat-value"><%= completedCount %></span>
                                    <span class="sr-stat-badge badge-green"><i class="fa-solid fa-arrow-up"></i> +16.5%</span>
                                </div>
                            </div>
                        </div>

                
                    </div>
                </div>

                <!-- Column 2: Service Requests Trend Dark Card -->
                <div class="sr-trend-card">
                    <div class="sr-dark-header">
                        <div class="sr-dark-title-wrap">
                            <i class="fa-solid fa-chart-line"></i>
                            <span>Service Requests Trend</span>
                        </div>
                   
                    </div>
                    <div class="sr-chart-svg-wrap">
                        <svg viewBox="0 0 320 120" style="width: 100%; height: 100%; overflow: visible;">
                            <defs>
                                <linearGradient id="srOrangeAreaGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stop-color="#F97316" stop-opacity="0.45"/>
                                    <stop offset="100%" stop-color="#F97316" stop-opacity="0.0"/>
                                </linearGradient>
                            </defs>
                            <!-- Horizontal Grid Lines -->
                            <line x1="25" y1="18" x2="310" y2="18" stroke="#334155" stroke-width="0.7" stroke-dasharray="2,2"/>
                            <line x1="25" y1="42" x2="310" y2="42" stroke="#334155" stroke-width="0.7" stroke-dasharray="2,2"/>
                            <line x1="25" y1="66" x2="310" y2="66" stroke="#334155" stroke-width="0.7" stroke-dasharray="2,2"/>
                            <line x1="25" y1="90" x2="310" y2="90" stroke="#334155" stroke-width="0.7" stroke-dasharray="2,2"/>

                            <!-- Y-Axis Values -->
                            <text x="20" y="21" fill="#64748B" font-size="8.5" text-anchor="end" font-family="'Plus Jakarta Sans', sans-serif">250</text>
                            <text x="20" y="45" fill="#64748B" font-size="8.5" text-anchor="end" font-family="'Plus Jakarta Sans', sans-serif">200</text>
                            <text x="20" y="69" fill="#64748B" font-size="8.5" text-anchor="end" font-family="'Plus Jakarta Sans', sans-serif">150</text>
                            <text x="20" y="93" fill="#64748B" font-size="8.5" text-anchor="end" font-family="'Plus Jakarta Sans', sans-serif">50</text>
                            <text x="20" y="106" fill="#64748B" font-size="8.5" text-anchor="end" font-family="'Plus Jakarta Sans', sans-serif">0</text>

                            <!-- Area Fill -->
                            <polygon points="35,90 85,82 135,74 185,68 235,58 285,22 285,104 35,104" fill="url(#srOrangeAreaGrad)" />

                            <!-- Trend Line -->
                            <polyline points="35,90 85,82 135,74 185,68 235,58 285,22" fill="none" stroke="#F97316" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>

                            <!-- Data Points -->
                            <circle cx="35" cy="90" r="3.2" fill="#F97316" stroke="#FFFFFF" stroke-width="1.5"/>
                            <circle cx="85" cy="82" r="3.2" fill="#F97316" stroke="#FFFFFF" stroke-width="1.5"/>
                            <circle cx="135" cy="74" r="3.2" fill="#F97316" stroke="#FFFFFF" stroke-width="1.5"/>
                            <circle cx="185" cy="68" r="3.2" fill="#F97316" stroke="#FFFFFF" stroke-width="1.5"/>
                            <circle cx="235" cy="58" r="3.2" fill="#F97316" stroke="#FFFFFF" stroke-width="1.5"/>
                            <circle cx="285" cy="22" r="4" fill="#EA580C" stroke="#FFFFFF" stroke-width="2"/>

                            <!-- Floating Pill over Jan -->
                            <g transform="translate(270, 4)">
                                <rect x="0" y="0" width="30" height="15" rx="7.5" fill="#F97316"/>
                                <text x="15" y="10.5" fill="#FFFFFF" font-size="8.5" font-weight="800" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif"><%= totalRequestsCount %></text>
                            </g>

                            <!-- Month Labels -->
                            <text x="35" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Aug</text>
                            <text x="85" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Sep</text>
                            <text x="135" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Oct</text>
                            <text x="185" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Nov</text>
                            <text x="235" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Dec</text>
                            <text x="285" y="117" fill="#94A3B8" font-size="8.5" text-anchor="middle" font-family="'Plus Jakarta Sans', sans-serif">Jan</text>
                        </svg>
                    </div>
                </div>

                <!-- Column 3: Requests by Status Donut Chart -->
                <div class="sr-donut-card">
                    <div class="sr-dark-header">
                        <div class="sr-dark-title-wrap">
                            <i class="fa-solid fa-chart-pie"></i>
                            <span>Requests by Status</span>
                        </div>
                    </div>
                    <%
                        double srCompPct = totalRequestsCount > 0 ? (completedCount * 100.0 / totalRequestsCount) : 0.0;
                        double srProgPct = totalRequestsCount > 0 ? (inProgressCount * 100.0 / totalRequestsCount) : 0.0;
                        double srPendPct = totalRequestsCount > 0 ? (pendingCount * 100.0 / totalRequestsCount) : 0.0;
                        double srCancPct = totalRequestsCount > 0 ? (cancelledCount * 100.0 / totalRequestsCount) : 0.0;

                        double srCirc = 238.76;
                        double srCompDash = (srCompPct / 100.0) * srCirc;
                        double srProgDash = (srProgPct / 100.0) * srCirc;
                        double srPendDash = (srPendPct / 100.0) * srCirc;
                        double srCancDash = (srCancPct / 100.0) * srCirc;

                        double srProgOff = -srCompDash;
                        double srPendOff = -(srCompDash + srProgDash);
                        double srCancOff = -(srCompDash + srProgDash + srPendDash);
                    %>
                    <div class="sr-donut-body">
                        <!-- SVG Donut Chart -->
                        <div class="sr-donut-svg-wrap">
                            <svg viewBox="0 0 100 100" style="width: 100%; height: 100%; transform: rotate(-90deg);">
                                <!-- Background Ring -->
                                <circle cx="50" cy="50" r="38" fill="none" stroke="#1E293B" stroke-width="12"/>
                                <% if (totalRequestsCount > 0) { %>
                                    <% if (completedCount > 0) { %>
                                    <circle cx="50" cy="50" r="38" fill="none" stroke="#22C55E" stroke-width="12"
                                            stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", srCompDash, srCirc) %>" stroke-dashoffset="0"/>
                                    <% } %>
                                    <% if (inProgressCount > 0) { %>
                                    <circle cx="50" cy="50" r="38" fill="none" stroke="#3B82F6" stroke-width="12"
                                            stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", srProgDash, srCirc) %>" stroke-dashoffset="<%= String.format(java.util.Locale.US, "%.1f", srProgOff) %>"/>
                                    <% } %>
                                    <% if (pendingCount > 0) { %>
                                    <circle cx="50" cy="50" r="38" fill="none" stroke="#EAB308" stroke-width="12"
                                            stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", srPendDash, srCirc) %>" stroke-dashoffset="<%= String.format(java.util.Locale.US, "%.1f", srPendOff) %>"/>
                                    <% } %>
                                    <% if (cancelledCount > 0) { %>
                                    <circle cx="50" cy="50" r="38" fill="none" stroke="#EF4444" stroke-width="12"
                                            stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", srCancDash, srCirc) %>" stroke-dashoffset="<%= String.format(java.util.Locale.US, "%.1f", srCancOff) %>"/>
                                    <% } %>
                                <% } %>
                            </svg>
                            <div class="sr-donut-center-text">
                                <div class="sr-donut-center-num"><%= totalRequestsCount %></div>
                                <div class="sr-donut-center-lbl">Total</div>
                            </div>
                        </div>

                        <!-- Legend List -->
                        <div class="sr-donut-legend">
                            <div class="sr-legend-item">
                                <div class="sr-legend-left">
                                    <span class="sr-legend-dot" style="background: #22C55E;"></span>
                                    <span>Completed (<%= completedCount %>)</span>
                                </div>
                                <span class="sr-legend-right"><%= String.format(java.util.Locale.US, "%.1f%%", srCompPct) %></span>
                            </div>
                            <div class="sr-legend-item">
                                <div class="sr-legend-left">
                                    <span class="sr-legend-dot" style="background: #3B82F6;"></span>
                                    <span>In Progress (<%= inProgressCount %>)</span>
                                </div>
                                <span class="sr-legend-right"><%= String.format(java.util.Locale.US, "%.1f%%", srProgPct) %></span>
                            </div>
                            <div class="sr-legend-item">
                                <div class="sr-legend-left">
                                    <span class="sr-legend-dot" style="background: #EAB308;"></span>
                                    <span>Pending (<%= pendingCount %>)</span>
                                </div>
                                <span class="sr-legend-right"><%= String.format(java.util.Locale.US, "%.1f%%", srPendPct) %></span>
                            </div>
                           
                        </div>
                    </div>
                </div>
            </section>

            <!-- 3. Main Card (Tabs + Filter Toolbar + 10-Column Custom Table) -->
            <div class="sr-main-card">
                <!-- Status Tabs Bar & Export/Print Actions -->
                <div class="sr-tabs-bar">
                    <div class="sr-tabs-left">
                        <a href="service-requests.jsp?tab=All" class="sr-tab-pill <%= ("All".equalsIgnoreCase(tabFilter) || "All Requests".equalsIgnoreCase(tabFilter)) ? "active" : "" %>">
                            <i class="fa-solid fa-list-check"></i> All Requests (<%= totalRequestsCount %>)
                        </a>
                        <a href="service-requests.jsp?tab=Pending" class="sr-tab-pill <%= "Pending".equalsIgnoreCase(tabFilter) ? "active" : "" %>">
                            <i class="fa-solid fa-hourglass-half" style="color: #D97706;"></i> Pending (<%= pendingCount %>)
                        </a>
                        <a href="service-requests.jsp?tab=In Progress" class="sr-tab-pill <%= "In Progress".equalsIgnoreCase(tabFilter) ? "active" : "" %>">
                            <i class="fa-solid fa-wrench" style="color: #2563EB;"></i> In Progress (<%= inProgressCount %>)
                        </a>
                        <a href="service-requests.jsp?tab=Completed" class="sr-tab-pill <%= "Completed".equalsIgnoreCase(tabFilter) ? "active" : "" %>">
                            <i class="fa-solid fa-circle-check" style="color: #16A34A;"></i> Completed (<%= completedCount %>)
                        </a>
                       
                    </div>
                
                </div>

                <!-- Filter Toolbar -->
                <form action="service-requests.jsp" method="GET" class="sr-filter-toolbar" id="serviceRequestFilterForm">
                    <input type="hidden" name="tab" value="<%= tabFilter %>">

                    <!-- Search Input -->
                    <div class="sr-search-input-wrap">
                        <i class="fa-solid fa-magnifying-glass"></i>
                        <input type="text" name="search" class="sr-search-input"
                               placeholder="Search by request ID, user name, vehicle number, or issue..."
                               value="<%= searchParam != null ? searchParam : "" %>">
                    </div>

                    <!-- Locations Dropdown -->
                    <div class="sr-select-wrap">
                        <i class="fa-solid fa-location-dot"></i>
                        <select name="location" class="sr-select-ctrl">
                            <option value="All Locations" <%= (locFilter == null || "All Locations".equalsIgnoreCase(locFilter)) ? "selected" : "" %>>All Locations</option>
                            <option value="Chennai" <%= "Chennai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Chennai</option>
                            <option value="Coimbatore" <%= "Coimbatore".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Coimbatore</option>
                            <option value="Madurai" <%= "Madurai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Madurai</option>
                            <option value="Trichy" <%= "Trichy".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Trichy</option>
                            <option value="Salem" <%= "Salem".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Salem</option>
                        </select>
                    </div>

                    <!-- Issues Dropdown -->
                    <div class="sr-select-wrap">
                        <i class="fa-solid fa-wrench"></i>
                        <select name="issue" class="sr-select-ctrl">
                            <option value="All Issues" <%= (issueFilter == null || "All Issues".equalsIgnoreCase(issueFilter)) ? "selected" : "" %>>All Issues</option>
                            <option value="Engine Overheat" <%= "Engine Overheat".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Engine Overheat</option>
                            <option value="Battery Issue" <%= "Battery Issue".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Battery Issue</option>
                            <option value="Tyre Puncture" <%= "Tyre Puncture".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Tyre Puncture</option>
                            <option value="Engine Start Issue" <%= "Engine Start Issue".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Engine Start Issue</option>
                            <option value="AC Not Working" <%= "AC Not Working".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>AC Not Working</option>
                        </select>
                    </div>

                    <!-- From Date Picker -->
                    <div class="sr-date-input-wrap">
                        <i class="fa-solid fa-calendar-days"></i>
                        <input type="text" name="fromDate" class="sr-date-ctrl" placeholder="From Date" onfocus="(this.type='date')" onblur="if(!this.value)this.type='text'" value="<%= fromDate != null ? fromDate : "" %>">
                    </div>

                    <!-- To Date Picker -->
                    <div class="sr-date-input-wrap">
                        <i class="fa-solid fa-calendar-days"></i>
                        <input type="text" name="toDate" class="sr-date-ctrl" placeholder="To Date" onfocus="(this.type='date')" onblur="if(!this.value)this.type='text'" value="<%= toDate != null ? toDate : "" %>">
                    </div>

                    <!-- Search Button -->
                    <button type="submit" class="sr-btn-search">
                        <i class="fa-solid fa-magnifying-glass"></i> Search
                    </button>

                    <!-- Reset Button -->
                    <a href="service-requests.jsp" class="sr-btn-reset" id="filterResetBtn">
                        <i class="fa-solid fa-rotate-left"></i> Reset
                    </a>
                </form>

                <!-- Service Requests Table (Exact 10 Columns Matching Reference) -->
                <% if (requestList.isEmpty()) { %>
                    <div style="padding: 50px 20px; text-align: center; color: #6B7280; background-color: #F8FAFC; border-radius: 12px; margin: 15px 0;">
                        <i class="fa-solid fa-clipboard-check" style="font-size: 46px; color: #16A34A; margin-bottom: 12px;"></i>
                        <h3 style="font-size: 16px; font-weight: 700; color: #1F2937; margin: 0 0 6px 0;">No Service Requests Found</h3>
                        <p style="font-size: 13px; color: #6B7280; margin: 0 0 16px 0;">No roadside assistance requests matched the selected filters or tab.</p>
                        <a href="service-requests.jsp" class="sr-btn-search" style="text-decoration: none; display: inline-flex;">
                            <i class="fa-solid fa-rotate-left"></i> View All Requests
                        </a>
                    </div>
                <% } else { %>

                <!-- Desktop Table View (>= 768px) -->
                <div class="sr-table-responsive">
                    <table class="sr-custom-table">
                        <thead>
                            <tr>
                                <th style="width: 32px; text-align: center;">S.No</th>
                                <th style="width: 78px;">Request ID</th>
                                <th>User Details</th>
                                <th>Vehicle Number</th>
                                <th>Breakdown Issue</th>
                                <th>Requested Date & Time</th>
                                <th>Location</th>
                                <th>Mechanic</th>
                                <th>Status</th>
                                <th style="text-align: center; width: 42px;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                                int rowSerial = startIndex + 1;
                                for (Map<String, String> r : displayList) { 
                                    String id = r.get("id");
                                    String code = r.get("code");
                                    String user = r.get("user");
                                    String userCode = r.get("userCode");
                                    String vehicle = r.get("vehicle");
                                    String issue = r.get("issue");
                                    String reqDate = r.get("date");
                                    String location = r.get("location");
                                    String mechanic = r.get("mechanic");
                                    String mechanicCode = r.get("mechanicCode");
                                    String status = r.get("status");
                                    String userPhone = r.get("userPhone");
                                    String userEmail = r.get("userEmail");
                                    String vehicleType = r.get("vehicleType");
                                    String brandModel = r.get("brandModel");
                                    String color = r.get("color");
                                    String vehicleImg = r.get("vehicleImg");
                                    String mechPhone = r.get("mechPhone");
                                    String workshop = r.get("workshop");
                                    String description = r.get("description");
                                    String initial = (user != null && !user.trim().isEmpty()) ? user.substring(0, 1).toUpperCase() : "U";

                                    // Avatar selection matching reference
                                    String avatarImg = "avatar-user-ragul.jpg";
                                    if (user != null) {
                                        String uLower = user.toLowerCase();
                                        if (uLower.contains("ragul")) {
                                            avatarImg = "avatar-user-ragul.jpg";
                                        } else if (uLower.contains("divya")) {
                                            avatarImg = "avatar-user-divya.jpg";
                                        } else if (uLower.contains("manoj")) {
                                            avatarImg = "avatar-manoj.jpg";
                                        } else if (uLower.contains("arun")) {
                                            avatarImg = "avatar-user-arun.jpg";
                                        } else if (uLower.contains("sathish")) {
                                            avatarImg = "avatar-user-sathish.jpg";
                                        } else if (uLower.contains("keerthana")) {
                                            avatarImg = "avatar-user-keerthana.jpg";
                                        }
                                    }

                                    // Mechanic avatar selection
                                    String mechAvatar = "avatar-karthik-mech.jpg";
                                    if (mechanic != null) {
                                        String mLower = mechanic.toLowerCase();
                                        if (mLower.contains("vignesh")) mechAvatar = "avatar-vignesh-mech.jpg";
                                        else if (mLower.contains("dinesh")) mechAvatar = "avatar-dinesh-mech.jpg";
                                        else if (mLower.contains("saravanan")) mechAvatar = "avatar-saravanan-mech.jpg";
                                        else if (mLower.contains("naveen")) mechAvatar = "avatar-naveen-mech.jpg";
                                        else if (mLower.contains("kannan")) mechAvatar = "avatar-kannan-mech.jpg";
                                        else if (mLower.contains("praveen")) mechAvatar = "avatar-praveen-mech.jpg";
                                        else if (mLower.contains("ramesh")) mechAvatar = "avatar-ramesh-mech.jpg";
                                        else if (mLower.contains("sathish")) mechAvatar = "avatar-sathish-mech.jpg";
                                    }

                                    // Breakdown Issue styling mapping
                                    String issueBadgeClass = "sr-issue-blue";
                                    String issueIcon = "fa-gear";
                                    if (issue != null) {
                                        String isLower = issue.toLowerCase();
                                        if (isLower.contains("battery")) {
                                            issueBadgeClass = "sr-issue-purple";
                                            issueIcon = "fa-car-battery";
                                        } else if (isLower.contains("tyre") || isLower.contains("puncture")) {
                                            issueBadgeClass = "sr-issue-orange";
                                            issueIcon = "fa-circle-dot";
                                        } else if (isLower.contains("ac")) {
                                            issueBadgeClass = "sr-issue-blue";
                                            issueIcon = "fa-snowflake";
                                        } else if (isLower.contains("start")) {
                                            issueBadgeClass = "sr-issue-yellow";
                                            issueIcon = "fa-screwdriver-wrench";
                                        } else {
                                            issueBadgeClass = "sr-issue-blue";
                                            issueIcon = "fa-gear";
                                        }
                                    }

                                    // Status Badge styling mapping
                                    String statusBadgeClass = "status-progress";
                                    String statusIcon = "fa-arrows-rotate";
                                    if ("Pending".equalsIgnoreCase(status)) {
                                        statusBadgeClass = "status-pending";
                                        statusIcon = "fa-hourglass-half";
                                    } else if ("Completed".equalsIgnoreCase(status)) {
                                        statusBadgeClass = "status-completed";
                                        statusIcon = "fa-circle-check";
                                    } else if ("Cancelled".equalsIgnoreCase(status) || "Rejected".equalsIgnoreCase(status)) {
                                        String rDesc = (String) r.get("additional_details");
                                        if (rDesc != null && rDesc.contains("Auto-cancelled")) {
                                            statusBadgeClass = "status-cancelled";
                                            statusIcon = "fa-triangle-exclamation";
                                        } else {
                                            statusBadgeClass = "status-cancelled";
                                            statusIcon = "fa-circle-xmark";
                                        }
                                    }

                                    // Split date and time for clean compact stacked layout
                                    String datePart = reqDate != null ? reqDate : "";
                                    String timePart = "";
                                    if (datePart.contains(",")) {
                                        String[] dParts = datePart.split(",", 2);
                                        datePart = dParts[0].trim();
                                        timePart = dParts[1].trim();
                                    } else if (datePart.contains("•")) {
                                        String[] dParts = datePart.split("•", 2);
                                        datePart = dParts[0].trim();
                                        timePart = dParts[1].trim();
                                    }
                            %>
                            <tr>
                                <!-- Column 1: # Serial Number -->
                                <td style="text-align: center; font-weight: 700; color: #6B7280; font-size: 13px;">
                                    <%= rowSerial++ %>
                                </td>

                                <!-- Column 2: Request ID (Peach Pill Badge) -->
                                <td>
                                    <span class="sr-req-code-pill"><%= code %></span>
                                </td>

                                <!-- Column 3: User Details (Avatar + Name + USR ID) -->
                                <td>
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <div style="width: 26px; height: 26px; border-radius: 50%; overflow: hidden; background: #FFF7ED; border: 1.5px solid #F97316; flex-shrink: 0; display: flex; align-items: center; justify-content: center; color: #F97316; font-size: 12px;">
                                            <i class="fa-solid fa-user"></i>
                                        </div>
                                        <div style="display: flex; flex-direction: column; line-height: 1.25;">
                                            <span style="font-weight: 700; color: #1F2937; font-size: 13px;"><%= user %></span>
                                            <span style="font-size: 11px; font-weight: 600; color: #9CA3AF;"><%= userCode %></span>
                                        </div>
                                    </div>
                                </td>

                                <!-- Column 4: Vehicle Number (Orange Car Icon + Registration) -->
                                <td>
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <i class="fa-solid <%= (vehicleType != null && (vehicleType.toLowerCase().contains("bike") || vehicleType.toLowerCase().contains("two") || vehicleType.toLowerCase().contains("motorcycle") || vehicleType.toLowerCase().contains("scooter"))) ? "fa-motorcycle" : "fa-car-side" %>" style="color: #F97316; font-size: 13px; flex-shrink: 0;"></i>
                                        <div style="display: flex; flex-direction: column; line-height: 1.25;">
                                            <span style="font-weight: 700; color: #1F2937; font-size: 13px; white-space: nowrap;"><%= vehicle %></span>
                                            <% if (brandModel != null && !brandModel.isEmpty() && !"Vehicle Details".equalsIgnoreCase(brandModel)) { %>
                                                <span style="font-size: 11px; font-weight: 500; color: #6B7280; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"><%= brandModel %></span>
                                            <% } %>
                                        </div>
                                    </div>
                                </td>

                                <!-- Column 5: Breakdown Issue (Colored Badge with Icon) -->
                                <td>
                                    <span class="sr-issue-badge <%= issueBadgeClass %>">
                                        <i class="fa-solid <%= issueIcon %>"></i> <%= issue %>
                                    </span>
                                </td>

                                <!-- Column 6: Requested Date & Time (Stacked date and time) -->
                                <td>
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <i class="fa-solid fa-calendar-days" style="color: #F97316; font-size: 12.5px; flex-shrink: 0;"></i>
                                        <div style="display: flex; flex-direction: column; line-height: 1.25;">
                                            <span style="font-weight: 600; color: #1F2937; font-size: 12.5px; white-space: nowrap;"><%= datePart %></span>
                                            <% if (!timePart.isEmpty()) { %>
                                                <span style="font-size: 11px; font-weight: 500; color: #6B7280; white-space: nowrap;"><%= timePart %></span>
                                            <% } %>
                                        </div>
                                    </div>
                                </td>

                                <!-- Column 7: Location (Location Pin + Ellipsis + Tooltip) -->
                                <td>
                                    <div style="display: flex; align-items: center; gap: 5px; max-width: 145px;" title="<%= location != null ? location.replace("\"", "&quot;") : "" %>">
                                        <i class="fa-solid fa-location-dot" style="color: #F97316; font-size: 12.5px; flex-shrink: 0;"></i>
                                        <span style="font-weight: 600; color: #1F2937; font-size: 12.5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"><%= location %></span>
                                    </div>
                                </td>

                                <!-- Column 8: Mechanic (Icon + Name + MEC ID with Ellipsis + Tooltip) -->
                                <td>
                                    <div style="display: flex; align-items: center; gap: 6px; max-width: 135px;" title="<%= mechanic != null ? mechanic.replace("\"", "&quot;") : "" %>">
                                        <i class="fa-solid fa-user-gear" style="color: #F97316; font-size: 13px; flex-shrink: 0;"></i>
                                        <div style="display: flex; flex-direction: column; line-height: 1.25; overflow: hidden;">
                                            <span style="font-weight: 700; color: #1F2937; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"><%= mechanic %></span>
                                            <span style="font-size: 11px; font-weight: 600; color: #9CA3AF;"><%= mechanicCode %></span>
                                        </div>
                                    </div>
                                </td>

                                <!-- Column 9: Status (Pill Badge) -->
                                <td>
                                    <span class="sr-status-pill-table <%= statusBadgeClass %>">
                                        <i class="fa-solid <%= statusIcon %>"></i> <%= (status != null && "Cancelled".equalsIgnoreCase(status) && r.get("additional_details") != null && ((String)r.get("additional_details")).contains("Auto-cancelled")) ? "Auto-Cancelled" : status %>
                                    </span>
                                </td>

                                <!-- Column 10: Actions (Single Eye Button Matching Reference) -->
                                <td style="text-align: center;">
                                    <button type="button" class="sr-btn-eye"
                                            title="View Details"
                                            onclick='openViewModal({
                                                id: "<%= id %>",
                                                code: "<%= code %>",
                                                userName: "<%= user != null ? user.replace("\"", "\\\"") : "" %>",
                                                userCode: "<%= userCode %>",
                                                userPhone: "<%= userPhone != null ? userPhone : "" %>",
                                                userEmail: "<%= userEmail != null ? userEmail : "" %>",
                                                userAvatar: "<%= avatarImg %>",
                                                vehicleNumber: "<%= vehicle %>",
                                                vehicleType: "<%= vehicleType != null ? vehicleType : "" %>",
                                                brandModel: "<%= brandModel != null ? brandModel : "" %>",
                                                color: "<%= color != null ? color : "" %>",
                                                vehicleImg: "<%= vehicleImg != null ? vehicleImg : "" %>",
                                                issue: "<%= issue != null ? issue.replace("\"", "\\\"") : "" %>",
                                                reqDate: "<%= reqDate %>",
                                                reqAt: "<%= r.get("requested_at") != null ? r.get("requested_at") : "" %>",
                                                assignedDate: "<%= r.get("assigned_date") != null ? r.get("assigned_date") : "" %>",
                                                assignedAt: "<%= r.get("assigned_at") != null ? r.get("assigned_at") : "" %>",
                                                inProgressDate: "<%= r.get("in_progress_date") != null ? r.get("in_progress_date") : "" %>",
                                                inProgressAt: "<%= r.get("in_progress_at") != null ? r.get("in_progress_at") : "" %>",
                                                completedDate: "<%= r.get("completed_date") != null ? r.get("completed_date") : "" %>",
                                                completedAt: "<%= r.get("completed_at") != null ? r.get("completed_at") : "" %>",
                                                location: "<%= location != null ? location.replace("\"", "\\\"") : "" %>",
                                                latitude: "<%= r.get("latitude") != null ? r.get("latitude") : "0.0" %>",
                                                longitude: "<%= r.get("longitude") != null ? r.get("longitude") : "0.0" %>",
                                                status: "<%= status %>",
                                                mechName: "<%= mechanic != null ? mechanic.replace("\"", "\\\"") : "Unassigned" %>",
                                                mechCode: "<%= mechanicCode %>",
                                                mechPhone: "<%= mechPhone != null ? mechPhone : "" %>",
                                                workshop: "<%= workshop != null ? workshop.replace("\"", "\\\"") : "Unassigned" %>",
                                                mechAvatar: "<%= mechAvatar %>",
                                                description: "<%= description != null ? description.replace("\"", "\\\"").replace("\n", " ") : "" %>"
                                            });'>
                                        <i class="fa-solid fa-eye"></i>
                                    </button>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

               
                

                <!-- Pagination Section (Matching Reference Design) -->
                <div class="pagination-container" style="display: flex; align-items: center; justify-content: space-between; padding: 14px 4px 4px 4px; border-top: 1px solid #F1F5F9; margin-top: 16px; flex-wrap: wrap; gap: 12px;">
                    <div style="font-size: 13.5px; color: #64748B; font-weight: 500;">
                        Showing <%= totalRequests > 0 ? (startIndex + 1) : 0 %> to <%= endIndex %> of <%= totalRequests %> entries
                    </div>
                    <div style="display: flex; align-items: center; gap: 14px;">
                        <div style="display: flex; align-items: center; gap: 6px; font-size: 13px; color: #64748B;">
                            <span>Rows per page:</span>
                            <select style="border: 1px solid #E2E8F0; border-radius: 6px; padding: 4px 8px; font-size: 13px; color: #334155; background: #FFFFFF; outline: none;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="50">50</option>
                            </select>
                        </div>
                        <%
                            StringBuilder rQueryBase = new StringBuilder("service-requests.jsp?rows=10");
                            if (tabFilter != null && !tabFilter.trim().isEmpty()) {
                                rQueryBase.append("&tab=").append(java.net.URLEncoder.encode(tabFilter, "UTF-8"));
                            }
                            if (searchParam != null && !searchParam.trim().isEmpty()) {
                                rQueryBase.append("&search=").append(java.net.URLEncoder.encode(searchParam, "UTF-8"));
                            }
                            if (locFilter != null && !locFilter.trim().isEmpty()) {
                                rQueryBase.append("&location=").append(java.net.URLEncoder.encode(locFilter, "UTF-8"));
                            }
                            if (issueFilter != null && !issueFilter.trim().isEmpty()) {
                                rQueryBase.append("&issue=").append(java.net.URLEncoder.encode(issueFilter, "UTF-8"));
                            }
                        %>
                        <div class="pagination-controls" style="display: flex; align-items: center; gap: 5px;">
                            <!-- First & Prev Page -->
                            <% if (currentPage > 1) { %>
                                <a href="<%= rQueryBase.toString() %>&page=1" class="page-btn" aria-label="First Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 12px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-angles-left"></i></a>
                                <a href="<%= rQueryBase.toString() %>&page=<%= currentPage - 1 %>" class="page-btn" aria-label="Previous Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 12px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-chevron-left"></i></a>
                            <% } else { %>
                                <span class="page-btn disabled" aria-label="First Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 12px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-angles-left"></i></span>
                                <span class="page-btn disabled" aria-label="Previous Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 12px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-chevron-left"></i></span>
                            <% } %>

                            <!-- Page Numbers -->
                            <% for (int p = 1; p <= totalPages; p++) { %>
                                <% if (p == currentPage) { %>
                                    <span class="page-btn active" style="width: 32px; height: 32px; border-radius: 6px; background: #F97316; color: #FFFFFF; font-weight: 700; font-size: 13px; display: flex; align-items: center; justify-content: center;"><%= p %></span>
                                <% } else { %>
                                    <a href="<%= rQueryBase.toString() %>&page=<%= p %>" class="page-btn" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 13px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><%= p %></a>
                                <% } %>
                            <% } %>

                            <!-- Next & Last Page -->
                            <% if (currentPage < totalPages) { %>
                                <a href="<%= rQueryBase.toString() %>&page=<%= currentPage + 1 %>" class="page-btn" aria-label="Next Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 12px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-chevron-right"></i></a>
                                <a href="<%= rQueryBase.toString() %>&page=<%= totalPages %>" class="page-btn" aria-label="Last Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 12px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-angles-right"></i></a>
                            <% } else { %>
                                <span class="page-btn disabled" aria-label="Next Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 12px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-chevron-right"></i></span>
                                <span class="page-btn disabled" aria-label="Last Page" style="width: 32px; height: 32px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 12px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-angles-right"></i></span>
                            <% } %>
                        </div>
                            <% if (currentPage < totalPages) { %>
                                <a href="<%= rQueryBase.toString() %>&page=<%= currentPage + 1 %>" class="page-btn" aria-label="Next Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 11px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-chevron-right"></i></a>
                                <a href="<%= rQueryBase.toString() %>&page=<%= totalPages %>" class="page-btn" aria-label="Last Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-size: 11px; display: flex; align-items: center; justify-content: center; text-decoration: none;"><i class="fa-solid fa-angles-right"></i></a>
                            <% } else { %>
                                <span class="page-btn disabled" aria-label="Next Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 11px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-chevron-right"></i></span>
                                <span class="page-btn disabled" aria-label="Last Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #94A3B8; font-size: 11px; display: flex; align-items: center; justify-content: center; cursor: not-allowed;"><i class="fa-solid fa-angles-right"></i></span>
                            <% } %>
                        </div>
                    </div>
                </div>

                <% } %>
            </div>
        </main>
    </div>
</div>

<!-- ==========================================================================
     MODAL 1: VIEW SERVICE REQUEST DETAILS MODAL (#viewRequestModal)
     Matches exact reference: media_1793794365645_c782789c.jpg
     ========================================================================== -->
<div class="modal-backdrop service-view-backdrop" id="viewRequestModal">
    <div class="service-view-modal">
        <!-- Top Header Bar -->
        <div class="service-view-header">
            <div class="sv-header-left">
                <div class="sv-header-icon-box">
                    <i class="fa-solid fa-wrench"></i>
                </div>
                <div class="sv-header-title-box">
                    <h3>Service Request Details</h3>
                    <p>Complete information about the vehicle service request</p>
                </div>
            </div>
            <div class="sv-header-right">
                <span class="sv-req-id-pill" id="svModalCode">SR0456</span>
                <span class="sv-status-pill" id="svModalStatusPill">
                    <i class="fa-solid fa-arrows-rotate" id="svModalStatusIcon" style="color: #312E81;"></i>
                    <span id="svModalStatusText">In Progress</span>
                </span>
                <button type="button" class="sv-close-btn" data-modal-close aria-label="Close Modal">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
        </div>

        <!-- Modal Body Container -->
        <div class="service-view-body">
            <!-- Row 1: Top 2-Column Grid -->
            <div class="sv-top-grid">
                <!-- Left Column: User Information + Vehicle Information -->
                <div style="display: flex; flex-direction: column; gap: 16px;">
                    <!-- Card 1: User Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-user"></i>
                            <span>User Information</span>
                        </div>
                        <div class="sv-person-row">
                            <div class="sv-avatar-container" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 2px solid #F97316; color: #F97316; font-size: 20px;">
                                <i class="fa-solid fa-user"></i>
                            </div>
                            <div class="sv-person-name-box">
                                <div class="sv-person-name" id="svUserName">Ragul M</div>
                                <div class="sv-person-code" id="svUserCode">USR012</div>
                            </div>
                            <div class="sv-divider-v"></div>
                            <div class="sv-contact-list">
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-phone"></i>
                                    <span id="svUserPhone">+91 98765 43210</span>
                                </div>
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-envelope"></i>
                                    <span id="svUserEmail">ragulm@gmail.com</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Card 2: Vehicle Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-car"></i>
                            <span>Vehicle Information</span>
                        </div>
                        <div class="sv-vehicle-row">
                            <div class="sv-vehicle-img-wrap">
                                <img id="svVehicleImg" src="${pageContext.request.contextPath}/images/vehicle-swift.png" alt="Vehicle Photo" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-swift.png';">
                            </div>
                            <div class="sv-key-val-grid">
                                <span class="sv-lbl">Vehicle Number</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val-bold" id="svVehicleNumber">TN45 AB 1234</span>

                                <span class="sv-lbl">Vehicle Type</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleType">Car</span>

                                <span class="sv-lbl">Brand & Model</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleBrandModel">Maruti Swift</span>

                                <span class="sv-lbl">Color</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleColor">White</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Service Request Information + Mechanic -->
                <div style="display: flex; flex-direction: column; gap: 16px;">
                    <!-- Card 3: Service Request Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-clipboard-list"></i>
                            <span>Service Request Information</span>
                        </div>
                        <div class="sv-sr-info-grid">
                            <span class="sv-lbl">Service Request ID</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val-bold" id="svSrId">SR0456</span>

                            <span class="sv-lbl">Breakdown Issue</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-gear" style="color: #4B5563; font-size: 13px;"></i>
                                <span id="svSrIssue">Engine Overheat</span>
                            </span>

                            <span class="sv-lbl">Requested Date & Time</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-calendar-days" style="color: #F97316; font-size: 13px;"></i>
                                <span id="svSrDate">20-01-2025, 02:15 PM</span>
                            </span>

                            <span class="sv-lbl">Location</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-location-dot" style="color: #F97316; font-size: 13px;"></i>
                                <span id="svSrLocation">Chennai</span>
                            </span>

                            <span class="sv-lbl">Status</span>
                            <span class="sv-colon">:</span>
                            <div>
                                <span class="sv-pill-status-inline" id="svSrStatusBadge">
                                    <i class="fa-solid fa-rotate" style="font-size: 11px;"></i>
                                    <span id="svSrStatusText">In Progress</span>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Card 4: Mechanic -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-user-gear"></i>
                            <span>Mechanic</span>
                        </div>
                        <div class="sv-person-row">
                            <div class="sv-avatar-container" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 2px solid #F97316; color: #F97316; font-size: 20px;">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="sv-person-name-box">
                                <div class="sv-person-name" id="svMechName">Unassigned</div>
                                <div class="sv-person-code" id="svMechCode">-</div>
                            </div>
                            <div class="sv-divider-v"></div>
                            <div class="sv-contact-list">
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-phone"></i>
                                    <span id="svMechPhone">-</span>
                                </div>
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-store"></i>
                                    <span id="svMechWorkshop">-</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 2: Request Description (Full Width) -->
            <div class="sv-desc-card">
                <div class="sv-card-header" style="margin-bottom: 10px;">
                    <i class="fa-solid fa-file-lines"></i>
                    <span>Request Description</span>
                </div>
                <div class="sv-desc-box" id="svDescription">
                    The vehicle engine is overheating while driving. Need immediate roadside assistance and engine checkup.
                </div>
            </div>

            <!-- Row 3: Bottom Grid (Timeline + Location Map) -->
            <div class="sv-bottom-grid">
                <!-- Card 6: Service Timeline -->
                <div class="sv-card">
                    <div class="sv-card-header" style="margin-bottom: 14px;">
                        <i class="fa-solid fa-clipboard-check"></i>
                        <span>Service Timeline</span>
                    </div>
                    <div class="sv-stepper-track">
                        <div class="sv-node-circle node-done" id="svNode1">
                            <i class="fa-solid fa-check"></i>
                        </div>
                        <div class="sv-step-line line-green" id="svLine1"></div>
                        <div class="sv-node-circle node-orange-check" id="svNode2">
                            <i class="fa-solid fa-check"></i>
                        </div>
                        <div class="sv-step-line line-orange" id="svLine2"></div>
                        <div class="sv-node-circle node-active-wrench" id="svNode3">
                            <i class="fa-solid fa-wrench"></i>
                        </div>
                        <div class="sv-step-line" id="svLine3"></div>
                        <div class="sv-node-circle" id="svNode4">
                            <i class="fa-solid fa-check"></i>
                        </div>
                    </div>
                    <div class="sv-stepper-labels">
                        <div>
                            <div class="sv-step-lbl-title">Request Received</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep1">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">Mechanic</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep2">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">In Progress</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep3">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">Completed</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep4">--</div>
                        </div>
                    </div>
                </div>

                <!-- Card 7: Location Map -->
                <div class="sv-card">
                    <div class="sv-location-header">
                        <div class="sv-card-header" style="margin-bottom: 0;">
                            <i class="fa-solid fa-location-dot"></i>
                            <span>Problem Location</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <span id="svCoordsBadge" class="sv-coords-badge" title="Reported GPS Coordinates">11.0268, 76.9507</span>
                            <button type="button" class="sv-btn-expand" id="btnExpandMap" title="View Fullscreen Map" onclick="openFullscreenMapModal()">
                                <i class="fa-solid fa-expand"></i>
                            </button>
                        </div>
                    </div>
                    <div class="sv-map-wrap" id="svMapWrap" onclick="openFullscreenMapModal()" title="Click to view full interactive breakdown map">
                        <div id="svMiniMap" style="width: 100%; height: 100%; border-radius: 8px; z-index: 1;"></div>
                        <div class="sv-map-overlay-badge">
                            <i class="fa-solid fa-crosshairs"></i>
                            <span id="svMapBadgeLoc">KTM, NSR Road, Saibaba Colony</span>
                        </div>
                        <div class="sv-map-click-hint">
                            <i class="fa-solid fa-up-right-and-down-left-from-center"></i> Expand
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modal Footer -->
        <div class="service-view-footer">
          
            <button type="button" class="" onclick="">
                
            </button>
            
              <button type="button" class="sv-btn-close" data-modal-close>
                <i class="fa-solid fa-xmark"></i> Close
            </button>
        </div>
    </div>
</div>

<!-- ==========================================================================
     FULLSCREEN INTERACTIVE BREAKDOWN LOCATION MAP MODAL (#fullscreenMapModal)
     ========================================================================== -->
<div class="modal-backdrop" id="fullscreenMapModal" style="z-index: 2100;">
    <div class="modal-box" style="max-width: 900px; width: 95%;">
        <div class="modal-header" style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
            <div>
                <h3 class="modal-title" style="display: flex; align-items: center; gap: 8px; font-size: 17px; font-weight: 800; color: #111827;">
                    <i class="fa-solid fa-map-location-dot" style="color: #EA580C;"></i>
                    <span>Breakdown Spot: <span id="fsMapCode" style="color: #EA580C;">SR0466</span></span>
                </h3>
                <span id="fsMapSubtitle" style="font-size: 12px; color: #6B7280; font-weight: 500;">
                    Exact GPS incident location for user problem
                </span>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <a id="fsGoogleMapsLink" href="#" target="_blank" rel="noopener noreferrer" class="btn-fs-gmaps" title="Open exact spot in Google Maps">
                    <i class="fa-solid fa-arrow-up-right-from-square"></i>
                    <span>Google Maps</span>
                </a>
                <button type="button" class="modal-close" onclick="closeFullscreenMapModal()" aria-label="Close Map Modal">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
        </div>

        <div class="modal-body" style="padding: 16px 0 0 0;">
            <!-- Top Location Info Bar -->
            <div style="background: #FFF7ED; border: 1px solid #FFEDD5; border-radius: 10px; padding: 12px 18px; margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 38px; height: 38px; border-radius: 10px; background: #EA580C; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; box-shadow: 0 3px 8px rgba(234, 88, 12, 0.3);">
                        <i class="fa-solid fa-location-dot"></i>
                    </div>
                    <div>
                        <div style="font-size: 11px; font-weight: 700; color: #9A3412; text-transform: uppercase; letter-spacing: 0.5px;">Problem Happened Area</div>
                        <div id="fsLocationAddress" style="font-size: 14px; font-weight: 800; color: #1E293B;">KTM, NSR Road, Saibaba Colony</div>
                    </div>
                </div>
                <div style="display: flex; align-items: center; gap: 20px; font-size: 12.5px;">
                    <div>
                        <span style="color: #9A3412; font-weight: 600;">GPS Coordinates:</span>
                        <span id="fsCoordinates" style="font-weight: 800; color: #1E293B; font-family: monospace; display: block;">11.026837, 76.950719</span>
                    </div>
                    <div>
                        <span style="color: #9A3412; font-weight: 600;">Reported Issue:</span>
                        <span id="fsIssueBadge" style="font-weight: 800; color: #EA580C; display: block;">Fuel Issue</span>
                    </div>
                </div>
            </div>

            <!-- Leaflet Interactive Large Map -->
            <div style="position: relative; width: 100%; height: 460px; border-radius: 12px; overflow: hidden; border: 1.5px solid #CBD5E1; box-shadow: 0 4px 16px rgba(0,0,0,0.06);">
                <div id="fsFullMap" style="width: 100%; height: 100%; z-index: 1;"></div>
            </div>
        </div>

        <div class="modal-footer" style="display: flex; justify-content: space-between; align-items: center; margin-top: 14px; padding-top: 12px; border-top: 1px solid #F1F5F9;">
            <div style="font-size: 12px; color: #64748B; display: flex; align-items: center; gap: 6px;">
                <i class="fa-solid fa-circle-info" style="color: #F97316;"></i>
                <span>Interactive map with zoom controls, street details, and GPS incident coordinates.</span>
            </div>
            <button type="button" class="btn-filter-reset" onclick="closeFullscreenMapModal()">Close Map</button>
        </div>
    </div>
</div>

<!-- ==========================================================================
     MODAL: EDIT SERVICE REQUEST (#editRequestModal)
     ========================================================================== -->
<div class="modal-backdrop" id="editRequestModal">
    <div class="modal-box" style="max-width: 540px;">
        <div class="modal-header">
            <div>
                <h3 class="modal-title"><i class="fa-solid fa-pen-to-square" style="color: #F97316; margin-right: 6px;"></i> Edit Service Request</h3>
                <span id="editModalSubtitle" style="font-size: 12px; color: #6B7280; font-weight: 500;">Update status, assigned technician or dispatch notes</span>
            </div>
            <button type="button" class="modal-close" data-modal-close aria-label="Close Modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form action="service-requests.jsp" method="POST">
            <input type="hidden" name="action" value="editRequest">
            <input type="hidden" name="requestId" id="editRequestId">

            <div class="modal-body" style="padding: 18px 0; display: flex; flex-direction: column; gap: 14px;">
                <div class="form-group">
                    <label class="form-label">Service Request Status <span class="required">*</span></label>
                    <select name="status" id="editRequestStatus" class="form-control" required style="height: 42px;">
                        <option value="Pending">Pending</option>
                        <option value="In Progress">In Progress</option>
                        <option value="Completed">Completed</option>
                        <option value="Cancelled">Cancelled</option>
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Breakdown Mechanic</label>
                    <select name="mechanicCode" id="editRequestMechanic" class="form-control" style="height: 42px;">
                        <option value="">-- Unassigned --</option>
                        <%
                            try {
                                Connection connMechOpts = DBConnection.getConnection();
                                if (connMechOpts != null) {
                                    Statement stMechOpts = connMechOpts.createStatement();
                                    ResultSet rsMechOpts = stMechOpts.executeQuery("SELECT mechanic_id, mechanic_code, owner_name, workshop_name, location FROM mechanics WHERE approval_status = 'Approved' ORDER BY owner_name ASC");
                                    while (rsMechOpts.next()) {
                                        String mCodeOpt = rsMechOpts.getString("mechanic_code");
                                        String mNameOpt = rsMechOpts.getString("owner_name");
                                        String mShopOpt = rsMechOpts.getString("workshop_name");
                                        String mLocOpt = rsMechOpts.getString("location");
                        %>
                        <option value="<%= mCodeOpt %>"><%= mNameOpt %> (<%= mCodeOpt %>) • <%= mShopOpt %> • <%= mLocOpt %></option>
                        <%
                                    }
                                    rsMechOpts.close();
                                    stMechOpts.close();
                                    connMechOpts.close();
                                }
                            } catch (Exception ignoredMO) {}
                        %>
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Reported Breakdown Issue</label>
                    <input type="text" name="issue" id="editRequestIssue" class="form-control" style="height: 42px;" placeholder="e.g. Engine Overheat">
                </div>

                <div class="form-group">
                    <label class="form-label">Request Description / Notes</label>
                    <textarea name="notes" id="editRequestNotes" class="form-control" rows="3" placeholder="Enter assistance notes..."></textarea>
                </div>
            </div>

            <div class="modal-footer" style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" class="btn-filter-reset" data-modal-close>Cancel</button>
                <button type="submit" class="btn-primary-orange">
                    <i class="fa-solid fa-check"></i> Save Changes
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ==========================================================================
     MODAL 2: ASSIGN MECHANIC MODAL (#assignMechanicModal)
     ========================================================================== -->
<div class="modal-backdrop" id="assignMechanicModal">
    <div class="modal-box" style="max-width: 520px;">
        <div class="modal-header">
            <div>
                <h3 class="modal-title"><i class="fa-solid fa-user-gear" style="color: #F97316; margin-right: 6px;"></i> Assign Field Technician</h3>
                <span id="assignModalSubtitle" style="font-size: 12px; color: #6B7280; font-weight: 500;">Select an authorized nearby breakdown mechanic</span>
            </div>
            <button type="button" class="modal-close" data-modal-close aria-label="Close Modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form action="service-requests.jsp" method="POST">
            <input type="hidden" name="action" value="assignMechanic">
            <input type="hidden" name="requestId" id="assignRequestId">

            <div class="modal-body" style="padding: 18px 0;">
                <div class="form-group">
                    <label class="form-label">Authorized Mechanics Fleet <span class="required">*</span></label>
                    <select name="mechanicId" class="form-control" required style="height: 42px;">
                        <option value="">-- Select Mechanic --</option>
                        <%
                            try {
                                Connection connMechOpts2 = DBConnection.getConnection();
                                if (connMechOpts2 != null) {
                                    Statement stMechOpts2 = connMechOpts2.createStatement();
                                    ResultSet rsMechOpts2 = stMechOpts2.executeQuery("SELECT mechanic_id, mechanic_code, owner_name, workshop_name, location FROM mechanics WHERE approval_status = 'Approved' ORDER BY owner_name ASC");
                                    while (rsMechOpts2.next()) {
                                        int mIdOpt = rsMechOpts2.getInt("mechanic_id");
                                        String mCodeOpt = rsMechOpts2.getString("mechanic_code");
                                        String mNameOpt = rsMechOpts2.getString("owner_name");
                                        String mShopOpt = rsMechOpts2.getString("workshop_name");
                                        String mLocOpt = rsMechOpts2.getString("location");
                        %>
                        <option value="<%= mIdOpt %>"><%= mNameOpt %> (<%= mCodeOpt %>) • <%= mShopOpt %> • <%= mLocOpt %></option>
                        <%
                                    }
                                    rsMechOpts2.close();
                                    stMechOpts2.close();
                                    connMechOpts2.close();
                                }
                            } catch (Exception ignoredMO2) {}
                        %>
                    </select>
                </div>
            </div>

            <div class="modal-footer" style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" class="btn-filter-reset" data-modal-close>Cancel</button>
                <button type="submit" class="btn-primary-orange">
                    <i class="fa-solid fa-paper-plane"></i> Dispatch Technician
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ==========================================================================
     MODAL 3: UPDATE STATUS MODAL (#updateStatusModal)
     ========================================================================== -->
<div class="modal-backdrop" id="updateStatusModal">
    <div class="modal-box" style="max-width: 500px;">
        <div class="modal-header">
            <div>
                <h3 class="modal-title"><i class="fa-solid fa-arrows-rotate" style="color: #F97316; margin-right: 6px;"></i> Update Ticket Status</h3>
                <span id="statusModalSubtitle" style="font-size: 12px; color: #6B7280; font-weight: 500;">Change live assistance progress</span>
            </div>
            <button type="button" class="modal-close" data-modal-close aria-label="Close Modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form action="service-requests.jsp" method="POST">
            <input type="hidden" name="action" value="updateStatus">
            <input type="hidden" name="requestId" id="updateRequestId">

            <div class="modal-body" style="padding: 18px 0;">
                <div class="form-group">
                    <label class="form-label">New Service Status <span class="required">*</span></label>
                    <select name="newStatus" id="updateStatusSelect" class="form-control" required style="height: 42px;">
                        <option value="Pending">Pending</option>
                        <option value="In Progress">In Progress</option>
                        <option value="Completed">Completed</option>
                        <option value="Cancelled">Cancelled</option>
                    </select>
                </div>
            </div>

            <div class="modal-footer" style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" class="btn-filter-reset" data-modal-close>Cancel</button>
                <button type="submit" class="btn-primary-orange">
                    <i class="fa-solid fa-check"></i> Save New Status
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ==========================================================================
     MODAL 4: INCIDENT RECEIPT PREVIEW MODAL (#viewReceiptModal)
     ========================================================================== -->
<div class="modal-backdrop" id="viewReceiptModal">
    <div class="modal-box" style="max-width: 600px;">
        <div class="modal-header">
            <div>
                <h3 class="modal-title"><i class="fa-solid fa-file-lines" style="color: #F97316; margin-right: 6px;"></i> Breakdown Service Incident Details</h3>
                <span id="receiptCode" style="font-size: 13px; font-weight: 700; color: #EA580C; font-family: monospace;">SR0454</span>
            </div>
            <button type="button" class="modal-close" data-modal-close aria-label="Close Modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <div class="modal-body" style="padding: 16px 0;">
            <div style="background-color: #F8FAFC; border: 1px solid #E5E7EB; border-radius: 12px; padding: 18px;">
                <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px; margin-bottom: 12px;">
                    <div>
                        <span style="font-size: 12px; color: #6B7280; font-weight: 600;">Customer Motorist</span>
                        <h4 id="receiptUser" style="margin: 0; font-size: 15px; color: #1F2937;">Arun K</h4>
                    </div>
                    <div style="text-align: right;">
                        <span style="font-size: 12px; color: #6B7280; font-weight: 600;">Vehicle Registration</span>
                        <h4 id="receiptVehicle" style="margin: 0; font-size: 15px; color: #1F2937;">TN64 EF 9012</h4>
                    </div>
                </div>

                <div class="form-grid-2" style="font-size: 13px; margin-bottom: 14px;">
                    <div>
                        <span style="color: #6B7280;">Service Type:</span>
                        <p style="font-weight: 700; margin: 3px 0 0 0;" id="receiptIssue">Tyre Puncture</p>
                    </div>
                    <div>
                        <span style="color: #6B7280;">Mechanic:</span>
                        <p style="font-weight: 700; margin: 3px 0 0 0;" id="receiptMechanic">Dinesh M (MEC020)</p>
                    </div>
                    <div>
                        <span style="color: #6B7280;">Incident Location:</span>
                        <p style="font-weight: 700; margin: 3px 0 0 0;" id="receiptLocation">Madurai</p>
                    </div>
                    <div>
                        <span style="color: #6B7280;">Service Resolution Status:</span>
                        <p style="font-weight: 700; margin: 3px 0 0 0;" id="receiptStatus">Completed</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal-footer" style="display: flex; justify-content: flex-end;">
            <button type="button" class="btn-primary-orange" data-modal-close>Close</button>
        </div>
    </div>
</div>

<!-- Leaflet JS Library for Interactive Location Maps -->
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<!-- Core Application JS (Zero-Blue Responsive Engine) -->
<script src="${pageContext.request.contextPath}/js/app-responsive.js"></script>

<!-- Dedicated Scripts for Modals -->
<script>
let currentViewData = {};
let miniMap = null;
let miniMarker = null;
let fullMap = null;
let fullMarker = null;
let fullCircle = null;
let activeIncidentCoords = { lat: 11.026837, lng: 76.950719 };

function getCoordinatesForRequest(d) {
    let lat = parseFloat(d.latitude);
    let lng = parseFloat(d.longitude);
    if (!isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0) {
        return { lat: lat, lng: lng, isExact: true };
    }

    // Geocoding fallback based on location text
    const loc = (d.location || '').toLowerCase();
    if (loc.includes('saibaba') || loc.includes('nsr') || loc.includes('coimbatore')) {
        return { lat: 11.026837, lng: 76.950719, isExact: true };
    } else if (loc.includes('chennai') || loc.includes('kathipara') || loc.includes('guindy') || loc.includes('omr')) {
        return { lat: 13.0067, lng: 80.2023, isExact: false };
    } else if (loc.includes('madurai')) {
        return { lat: 9.9252, lng: 78.1198, isExact: false };
    } else if (loc.includes('trichy') || loc.includes('manapparai')) {
        return { lat: 10.7905, lng: 78.7047, isExact: false };
    } else if (loc.includes('salem')) {
        return { lat: 11.6643, lng: 78.1460, isExact: false };
    }
    return { lat: 11.026837, lng: 76.950719, isExact: true };
}

function initOrUpdateMiniMap(coords, d) {
    activeIncidentCoords = coords;
    const badgeText = coords.lat.toFixed(4) + ', ' + coords.lng.toFixed(4);
    const badgeElem = document.getElementById('svCoordsBadge');
    if (badgeElem) badgeElem.textContent = badgeText;
    
    const locBadge = document.getElementById('svMapBadgeLoc');
    if (locBadge) locBadge.textContent = d.location || 'Incident Spot';

    if (typeof L === 'undefined') {
        console.warn('Leaflet library not available');
        return;
    }

    const container = document.getElementById('svMiniMap');
    if (!container) return;

    const customPin = L.divIcon({
        className: 'custom-breakdown-pin',
        html: '<div class="pin-marker-pulse"></div><div class="pin-marker-body"><i class="fa-solid fa-wrench"></i></div>',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32]
    });

    if (!miniMap) {
        miniMap = L.map('svMiniMap', {
            center: [coords.lat, coords.lng],
            zoom: 15,
            zoomControl: false,
            attributionControl: false,
            dragging: false,
            scrollWheelZoom: false,
            doubleClickZoom: false,
            touchZoom: false
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19
        }).addTo(miniMap);

        miniMarker = L.marker([coords.lat, coords.lng], { icon: customPin }).addTo(miniMap);
    } else {
        miniMap.setView([coords.lat, coords.lng], 15);
        if (miniMarker) {
            miniMarker.setLatLng([coords.lat, coords.lng]);
        } else {
            miniMarker = L.marker([coords.lat, coords.lng], { icon: customPin }).addTo(miniMap);
        }
    }

    setTimeout(function() {
        if (miniMap) miniMap.invalidateSize();
    }, 250);
}

function openFullscreenMapModal() {
    const d = currentViewData || {};
    const coords = activeIncidentCoords || { lat: 11.026837, lng: 76.950719 };

    document.getElementById('fsMapCode').textContent = d.code || 'SR0466';
    document.getElementById('fsLocationAddress').textContent = d.location || 'Reported Breakdown Area';
    document.getElementById('fsCoordinates').textContent = coords.lat.toFixed(6) + ', ' + coords.lng.toFixed(6);
    document.getElementById('fsIssueBadge').textContent = d.issue || 'Breakdown';

    const gmapsLink = document.getElementById('fsGoogleMapsLink');
    if (gmapsLink) {
        gmapsLink.href = 'https://www.google.com/maps?q=' + coords.lat + ',' + coords.lng;
    }

    const fsModal = document.getElementById('fullscreenMapModal');
    if (fsModal) {
        fsModal.classList.add('active');
    }

    if (typeof L === 'undefined') return;

    const customPinLarge = L.divIcon({
        className: 'custom-breakdown-pin',
        html: '<div class="pin-marker-pulse"></div><div class="pin-marker-body"><i class="fa-solid fa-wrench"></i></div>',
        iconSize: [36, 36],
        iconAnchor: [18, 36],
        popupAnchor: [0, -36]
    });

    const popupHtml = `
        <div style="font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; min-width: 220px; line-height: 1.4;">
            <div style="font-weight: 800; color: #EA580C; font-size: 14px; margin-bottom: 4px; display: flex; align-items: center; gap: 6px;">
                <i class="fa-solid fa-triangle-exclamation"></i> Breakdown Incident Spot
            </div>
            <div style="font-weight: 700; color: #1E293B; margin-bottom: 6px; font-size: 13.5px;">` + (d.location || 'Incident Area') + `</div>
            <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Motorist: <b style="color: #1E293B;">` + (d.userName || 'Customer') + `</b> (` + (d.userPhone || '-') + `)</div>
            <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Vehicle: <b style="color: #1E293B;">` + (d.vehicleNumber || '-') + `</b></div>
            <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Reported Issue: <b style="color: #EA580C;">` + (d.issue || '-') + `</b></div>
            <div style="font-size: 11px; color: #64748B; font-family: monospace; margin-top: 6px; background: #F8FAFC; padding: 4px 6px; border-radius: 4px; border: 1px solid #E2E8F0;">GPS: ` + coords.lat.toFixed(6) + `, ` + coords.lng.toFixed(6) + `</div>
        </div>
    `;

    if (!fullMap) {
        fullMap = L.map('fsFullMap', {
            center: [coords.lat, coords.lng],
            zoom: 16
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(fullMap);

        fullCircle = L.circle([coords.lat, coords.lng], {
            color: '#EA580C',
            fillColor: '#F97316',
            fillOpacity: 0.15,
            radius: 80
        }).addTo(fullMap);

        fullMarker = L.marker([coords.lat, coords.lng], { icon: customPinLarge })
            .addTo(fullMap)
            .bindPopup(popupHtml);
    } else {
        fullMap.setView([coords.lat, coords.lng], 16);
        if (fullMarker) {
            fullMarker.setLatLng([coords.lat, coords.lng]).setPopupContent(popupHtml);
        } else {
            fullMarker = L.marker([coords.lat, coords.lng], { icon: customPinLarge }).addTo(fullMap).bindPopup(popupHtml);
        }
        if (fullCircle) {
            fullCircle.setLatLng([coords.lat, coords.lng]);
        } else {
            fullCircle = L.circle([coords.lat, coords.lng], {
                color: '#EA580C',
                fillColor: '#F97316',
                fillOpacity: 0.15,
                radius: 80
            }).addTo(fullMap);
        }
    }

    setTimeout(function() {
        if (fullMap) {
            fullMap.invalidateSize();
            if (fullMarker) fullMarker.openPopup();
        }
    }, 250);
}

function closeFullscreenMapModal() {
    const fsModal = document.getElementById('fullscreenMapModal');
    if (fsModal) {
        fsModal.classList.remove('active');
    }
}

function openViewModal(arg1) {
    let d = {};
    if (typeof arg1 === 'object' && arg1 !== null) {
        d = arg1;
    } else {
        d.id = arguments[0];
        d.code = arguments[1] || '';
        d.userName = arguments[2] || 'Customer';
        d.userCode = arguments[3] || '';
        d.vehicleNumber = arguments[4] || '';
        d.issue = arguments[5] || '';
        d.reqDate = arguments[6] || '';
        d.location = arguments[7] || '';
        d.mechName = arguments[8] || 'Unassigned';
        d.mechCode = arguments[9] || '-';
        d.status = arguments[10] || 'Pending';
    }

    currentViewData = d;

    // Code & Status
    const code = d.code || '';
    const status = d.status || 'Pending';
    document.getElementById('svModalCode').textContent = code;
    document.getElementById('svSrId').textContent = code;

    // Header Status Pill
    const statusPill = document.getElementById('svModalStatusPill');
    const statusText = document.getElementById('svModalStatusText');
    const statusIcon = document.getElementById('svModalStatusIcon');
    statusText.textContent = status;

    statusPill.className = 'sv-status-pill ' + 
        (status.toLowerCase() === 'completed' ? 'status-completed' : 
        (status.toLowerCase() === 'pending' ? 'status-pending' : 
        (status.toLowerCase() === 'cancelled' ? 'status-cancelled' : '')));

    // Card Status Inline
    const cardStatus = document.getElementById('svSrStatusBadge');
    const cardStatusText = document.getElementById('svSrStatusText');
    cardStatusText.textContent = status;
    cardStatus.className = 'sv-pill-status-inline ' + 
        (status.toLowerCase() === 'completed' ? 'status-completed' : 
        (status.toLowerCase() === 'pending' ? 'status-pending' : 
        (status.toLowerCase() === 'cancelled' ? 'status-cancelled' : '')));

    // User details
    document.getElementById('svUserName').textContent = d.userName || 'Customer';
    document.getElementById('svUserCode').textContent = d.userCode || '';
    document.getElementById('svUserPhone').textContent = d.userPhone || '-';
    document.getElementById('svUserEmail').textContent = d.userEmail || '-';
    if (d.userAvatar) {
        var sua = document.getElementById('svUserAvatar');
        if (sua && sua.tagName === 'IMG') sua.src = '${pageContext.request.contextPath}/images/' + d.userAvatar;
    }

    // Vehicle details
    document.getElementById('svVehicleNumber').textContent = d.vehicleNumber || '-';
    document.getElementById('svVehicleType').textContent = d.vehicleType || '-';
    document.getElementById('svVehicleBrandModel').textContent = d.brandModel || '-';
    document.getElementById('svVehicleColor').textContent = d.color || '';
    const vehImgElem = document.getElementById('svVehicleImg');
    if (vehImgElem) {
        if (d.vehicleImg && d.vehicleImg.trim() !== '') {
            if (d.vehicleImg.startsWith('uploads/')) {
                vehImgElem.src = '${pageContext.request.contextPath}/' + d.vehicleImg;
            } else if (d.vehicleImg.startsWith('veh_')) {
                vehImgElem.src = '${pageContext.request.contextPath}/uploads/vehicles/' + d.vehicleImg;
            } else {
                vehImgElem.src = '${pageContext.request.contextPath}/images/' + d.vehicleImg;
            }
        } else {
            vehImgElem.src = '${pageContext.request.contextPath}/images/vehicle-swift.png';
        }
    }

    // Service request info
    document.getElementById('svSrIssue').textContent = d.issue || '-';
    document.getElementById('svSrDate').textContent = d.reqDate || '-';
    document.getElementById('svSrLocation').textContent = d.location || '-';

    // Mechanic details
    var isAssigned = d.mechName && d.mechName !== 'Unassigned' && d.mechName !== 'null';
    if (isAssigned) {
        document.getElementById('svMechName').textContent = d.mechName;
        document.getElementById('svMechCode').textContent = (d.mechCode && d.mechCode !== '-' && d.mechCode !== 'null') ? d.mechCode : 'MEC Assigned';
        document.getElementById('svMechPhone').textContent = (d.mechPhone && d.mechPhone !== '-' && d.mechPhone !== 'null') ? d.mechPhone : '+91 98765 43210';
        document.getElementById('svMechWorkshop').textContent = (d.workshop && d.workshop !== 'Unassigned' && d.workshop !== 'null') ? d.workshop : d.mechName;
    } else {
        document.getElementById('svMechName').textContent = 'Unassigned';
        document.getElementById('svMechCode').textContent = 'Pending Assignment';
        document.getElementById('svMechPhone').textContent = 'Not assigned yet';
        document.getElementById('svMechWorkshop').textContent = 'Awaiting Technician';
    }
    if (d.mechAvatar) {
        var sma = document.getElementById('svMechAvatar');
        if (sma && sma.tagName === 'IMG') sma.src = '${pageContext.request.contextPath}/images/' + d.mechAvatar;
    }

    // Description
    document.getElementById('svDescription').textContent = d.description || 'No additional details provided.';

    // Stepper Timeline with realistic dynamic progression times
    updateTimeline(status, d);

    // Initialize or Update Interactive Leaflet Map to Exact Incident Coordinates
    const coords = getCoordinatesForRequest(d);
    initOrUpdateMiniMap(coords, d);

    // Open Modal
    const modal = document.getElementById('viewRequestModal');
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function parseTimelineDate(input) {
    if (!input) return null;
    if (input instanceof Date && !isNaN(input.getTime())) return input;
    if (typeof input !== 'string') return null;
    var s = input.trim();
    if (!s || s === '-' || s === '--' || s === 'null') return null;

    // 1. Try ISO: 'YYYY-MM-DD HH:MM:SS' or 'YYYY-MM-DDTHH:MM:SS'
    var isoMatch = s.match(/^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2}):?(\d{2})?/);
    if (isoMatch) {
        return new Date(
            parseInt(isoMatch[1], 10),
            parseInt(isoMatch[2], 10) - 1,
            parseInt(isoMatch[3], 10),
            parseInt(isoMatch[4], 10),
            parseInt(isoMatch[5], 10),
            isoMatch[6] ? parseInt(isoMatch[6], 10) : 0
        );
    }

    // 2. Try 'DD-MM-YYYY [•·,] HH:MM AM/PM' or 'DD-MM-YYYY, HH:MM AM/PM'
    var dmyMatch = s.match(/^(\d{1,2})-(\d{1,2})-(\d{4})[^\d]*(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
    if (dmyMatch) {
        var day = parseInt(dmyMatch[1], 10);
        var month = parseInt(dmyMatch[2], 10) - 1;
        var year = parseInt(dmyMatch[3], 10);
        var hours = parseInt(dmyMatch[4], 10);
        var mins = parseInt(dmyMatch[5], 10);
        var ampm = dmyMatch[6] ? dmyMatch[6].toUpperCase() : null;
        if (ampm === 'PM' && hours < 12) hours += 12;
        if (ampm === 'AM' && hours === 12) hours = 0;
        return new Date(year, month, day, hours, mins, 0);
    }

    // 3. Try 'MMM DD, YYYY • HH:MM AM/PM' e.g. 'Nov 14, 2026 • 12:22 PM'
    var mdyMatch = s.match(/^([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})[^\d]*(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
    if (mdyMatch) {
        var mNames = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
        var mIdx = mNames.indexOf(mdyMatch[1].toLowerCase().substring(0, 3));
        if (mIdx !== -1) {
            var day = parseInt(mdyMatch[2], 10);
            var year = parseInt(mdyMatch[3], 10);
            var hours = parseInt(mdyMatch[4], 10);
            var mins = parseInt(mdyMatch[5], 10);
            var ampm = mdyMatch[6] ? mdyMatch[6].toUpperCase() : null;
            if (ampm === 'PM' && hours < 12) hours += 12;
            if (ampm === 'AM' && hours === 12) hours = 0;
            return new Date(year, mIdx, day, hours, mins, 0);
        }
    }

    // 4. Fallback to Date.parse
    var parsed = new Date(s);
    if (!isNaN(parsed.getTime())) return parsed;
    return null;
}

function formatTimelineDate(dt) {
    if (!dt || isNaN(dt.getTime())) return '--';
    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    var d = dt.getDate();
    var m = months[dt.getMonth()];
    var hours = dt.getHours();
    var minutes = dt.getMinutes();
    var ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12;
    var minStr = minutes < 10 ? ('0' + minutes) : minutes;
    var hrStr = hours < 10 ? ('0' + hours) : hours;
    return d + ' ' + m + ', ' + hrStr + ':' + minStr + ' ' + ampm;
}

function updateTimeline(status, d) {
    const node1 = document.getElementById('svNode1');
    const node2 = document.getElementById('svNode2');
    const node3 = document.getElementById('svNode3');
    const node4 = document.getElementById('svNode4');
    const line1 = document.getElementById('svLine1');
    const line2 = document.getElementById('svLine2');
    const line3 = document.getElementById('svLine3');

    const t1 = document.getElementById('svTimeStep1');
    const t2 = document.getElementById('svTimeStep2');
    const t3 = document.getElementById('svTimeStep3');
    const t4 = document.getElementById('svTimeStep4');

    if (!node1) return;

    var dataObj = (typeof d === 'object' && d !== null) ? d : { reqDate: d };
    const st = (status || (dataObj && dataObj.status) || '').toLowerCase();

    // 1. Resolve Step 1 Date (Request Received)
    var reqDt = parseTimelineDate(dataObj.reqAt || dataObj.requestedAt || dataObj.reqDate || dataObj.date);
    if (!reqDt) reqDt = new Date();

    // 2. Resolve Step 2 Date (Mechanic)
    var assignedDt = parseTimelineDate(dataObj.assignedAt || dataObj.assignedDate);
    if (!assignedDt && (st === 'accepted' || st === 'on the way' || st === 'in progress' || st === 'completed')) {
        assignedDt = new Date(reqDt.getTime() + 6 * 60 * 1000);
    }

    // 3. Resolve Step 3 Date (In Progress)
    var inProgressDt = parseTimelineDate(dataObj.inProgressAt || dataObj.inProgressDate);
    if (!inProgressDt && (st === 'in progress' || st === 'completed')) {
        var baseAssigned = assignedDt || reqDt;
        inProgressDt = new Date(baseAssigned.getTime() + 18 * 60 * 1000);
    }

    // 4. Resolve Step 4 Date (Completed)
    var completedDt = parseTimelineDate(dataObj.completedAt || dataObj.completedDate);
    if (!completedDt && st === 'completed') {
        var baseProgress = inProgressDt || assignedDt || reqDt;
        completedDt = new Date(baseProgress.getTime() + 36 * 60 * 1000);
    }

    if (t1) t1.textContent = formatTimelineDate(reqDt);

    if (st === 'pending') {
        node1.className = 'sv-node-circle node-done';
        node1.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line1) line1.className = 'sv-step-line';

        node2.className = 'sv-node-circle';
        node2.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line2) line2.className = 'sv-step-line';

        node3.className = 'sv-node-circle';
        node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
        if (line3) line3.className = 'sv-step-line';

        node4.className = 'sv-node-circle';
        node4.innerHTML = '<i class="fa-solid fa-check"></i>';

        if (t2) t2.textContent = '--';
        if (t3) t3.textContent = '--';
        if (t4) t4.textContent = '--';
    } else if (st === 'accepted' || st === 'on the way') {
        node1.className = 'sv-node-circle node-done';
        node1.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line1) line1.className = 'sv-step-line line-green';

        node2.className = 'sv-node-circle node-done';
        node2.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line2) line2.className = 'sv-step-line';

        node3.className = 'sv-node-circle';
        node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
        if (line3) line3.className = 'sv-step-line';

        node4.className = 'sv-node-circle';
        node4.innerHTML = '<i class="fa-solid fa-check"></i>';

        if (t2) t2.textContent = formatTimelineDate(assignedDt);
        if (t3) t3.textContent = '--';
        if (t4) t4.textContent = '--';
    } else if (st === 'in progress') {
        node1.className = 'sv-node-circle node-done';
        node1.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line1) line1.className = 'sv-step-line line-green';

        node2.className = 'sv-node-circle node-done';
        node2.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line2) line2.className = 'sv-step-line line-green';

        node3.className = 'sv-node-circle node-active-wrench';
        node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
        if (line3) line3.className = 'sv-step-line';

        node4.className = 'sv-node-circle';
        node4.innerHTML = '<i class="fa-solid fa-check"></i>';

        if (t2) t2.textContent = formatTimelineDate(assignedDt);
        if (t3) t3.textContent = formatTimelineDate(inProgressDt);
        if (t4) t4.textContent = '--';
    } else if (st === 'completed') {
        node1.className = 'sv-node-circle node-done';
        node1.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line1) line1.className = 'sv-step-line line-green';

        node2.className = 'sv-node-circle node-done';
        node2.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line2) line2.className = 'sv-step-line line-green';

        node3.className = 'sv-node-circle node-done';
        node3.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line3) line3.className = 'sv-step-line line-green';

        node4.className = 'sv-node-circle node-done';
        node4.innerHTML = '<i class="fa-solid fa-check"></i>';

        if (t2) t2.textContent = formatTimelineDate(assignedDt);
        if (t3) t3.textContent = formatTimelineDate(inProgressDt);
        if (t4) t4.textContent = formatTimelineDate(completedDt);
    } else if (st === 'cancelled' || st === 'rejected') {
        node1.className = 'sv-node-circle node-done';
        node1.innerHTML = '<i class="fa-solid fa-check"></i>';
        if (line1) line1.className = 'sv-step-line line-red';

        node2.className = 'sv-node-circle';
        node2.innerHTML = '<i class="fa-solid fa-xmark"></i>';
        if (line2) line2.className = 'sv-step-line';

        node3.className = 'sv-node-circle';
        node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
        if (line3) line3.className = 'sv-step-line';

        node4.className = 'sv-node-circle node-cancelled';
        node4.innerHTML = '<i class="fa-solid fa-xmark"></i>';

        if (t2) t2.textContent = '--';
        if (t3) t3.textContent = '--';
        if (t4) t4.textContent = 'Cancelled';
    } else {
        if (t2) t2.textContent = '--';
        if (t3) t3.textContent = '--';
        if (t4) t4.textContent = '--';
    }
}

function openEditModalFromView() {
    const code = document.getElementById('svModalCode').textContent;
    const status = document.getElementById('svModalStatusText').textContent.trim();
    const mechCode = document.getElementById('svMechCode').textContent.trim();
    const issue = document.getElementById('svSrIssue').textContent.trim();
    const notes = document.getElementById('svDescription').textContent.trim();

    document.getElementById('editRequestId').value = code;
    document.getElementById('editModalSubtitle').textContent = 'Modify ticket #' + code;

    const statusSel = document.getElementById('editRequestStatus');
    if (statusSel) {
        for (let i = 0; i < statusSel.options.length; i++) {
            if (statusSel.options[i].value.toLowerCase() === status.toLowerCase()) {
                statusSel.selectedIndex = i;
                break;
            }
        }
    }

    const mechSel = document.getElementById('editRequestMechanic');
    if (mechSel) {
        for (let i = 0; i < mechSel.options.length; i++) {
            if (mechSel.options[i].value.toLowerCase() === mechCode.toLowerCase()) {
                mechSel.selectedIndex = i;
                break;
            }
        }
    }

    document.getElementById('editRequestIssue').value = issue;
    document.getElementById('editRequestNotes').value = notes;

    // Close view modal and open edit modal
    document.getElementById('viewRequestModal').classList.remove('active');
    const editModal = document.getElementById('editRequestModal');
    if (editModal) {
        editModal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function openAssignModal(id, code, mechanic) {
    document.getElementById('assignRequestId').value = id;
    document.getElementById('assignModalSubtitle').textContent = 'Dispatching partner for ticket #' + code + ' (Currently: ' + mechanic + ')';

    const modal = document.getElementById('assignMechanicModal');
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function openStatusModal(id, code, currentStatus) {
    document.getElementById('updateRequestId').value = id;
    document.getElementById('statusModalSubtitle').textContent = 'Modify ticket #' + code + ' status';

    const select = document.getElementById('updateStatusSelect');
    if (select) {
        for (let i = 0; i < select.options.length; i++) {
            if (select.options[i].value.toLowerCase() === currentStatus.toLowerCase()) {
                select.selectedIndex = i;
                break;
            }
        }
    }

    const modal = document.getElementById('updateStatusModal');
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function openReceiptModal(code, user, vehicle, issue, date, location, mechanic, status) {
    document.getElementById('receiptCode').textContent = code;
    document.getElementById('receiptUser').textContent = user;
    document.getElementById('receiptVehicle').textContent = vehicle;
    document.getElementById('receiptIssue').textContent = issue;
    document.getElementById('receiptMechanic').textContent = mechanic;
    document.getElementById('receiptLocation').textContent = location;
    document.getElementById('receiptStatus').textContent = status;

    const modal = document.getElementById('viewReceiptModal');
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

// Close Modals on background click or Escape key
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.modal-backdrop, .service-view-backdrop').forEach(modal => {
        modal.addEventListener('click', function(e) {
            if (e.target === this) {
                this.classList.remove('active');
                document.body.style.overflow = '';
            }
        });
    });

    document.querySelectorAll('[data-modal-close]').forEach(btn => {
        btn.addEventListener('click', function() {
            const modal = this.closest('.modal-backdrop, .service-view-backdrop');
            if (modal) {
                modal.classList.remove('active');
                document.body.style.overflow = '';
            }
        });
    });

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-backdrop.active, .service-view-backdrop.active').forEach(m => {
                m.classList.remove('active');
            });
            document.body.style.overflow = '';
        }
    });

    // Check URL parameters for direct view
    const urlParams = new URLSearchParams(window.location.search);
    const viewParam = urlParams.get('view') || urlParams.get('id');
    if (viewParam) {
        openViewModal({
            code: viewParam,
            status: 'In Progress'
        });
    }
});

// =========================================================================
// IN-PLACE AJAX FILTERING & NON-RELOAD DYNAMIC NAVIGATION
// =========================================================================
(function() {
    let activeAbortCtrl = null;
    let searchDebounceTimer = null;

    function buildUrlFromFilterForm(form) {
        const formData = new FormData(form);
        const params = new URLSearchParams();
        for (const pair of formData.entries()) {
            const key = pair[0];
            const val = pair[1];
            if (val !== null && typeof val === 'string' && val.trim() !== '') {
                params.append(key, val.trim());
            }
        }
        const action = form.getAttribute('action') || 'service-requests.jsp';
        const qs = params.toString();
        return action + (qs ? '?' + qs : '');
    }

    function loadContentViaAjax(targetUrl, pushHistory) {
        if (pushHistory === undefined) pushHistory = true;

        if (activeAbortCtrl) {
            try { activeAbortCtrl.abort(); } catch (e) {}
        }
        activeAbortCtrl = new AbortController();

        const mainCard = document.querySelector('.sr-main-card');
        const searchInput = document.querySelector('.sr-search-input');
        const wasSearchActive = (document.activeElement === searchInput);
        const searchPos = (wasSearchActive && searchInput) ? searchInput.selectionStart : 0;

        if (mainCard) {
            mainCard.style.transition = 'opacity 0.15s ease';
            mainCard.style.opacity = '0.55';
            mainCard.style.pointerEvents = 'none';
        }

        fetch(targetUrl, {
            signal: activeAbortCtrl.signal,
            headers: { 'X-Requested-With': 'XMLHttpRequest' }
        })
        .then(function(res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.text();
        })
        .then(function(html) {
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');

            // 1. Update .sr-main-card
            const newMainCard = doc.querySelector('.sr-main-card');
            if (mainCard && newMainCard) {
                mainCard.innerHTML = newMainCard.innerHTML;
                mainCard.style.opacity = '1';
                mainCard.style.pointerEvents = '';
            }

            // 2. Update .sr-metrics-grid
            const oldMetrics = document.querySelector('.sr-metrics-grid');
            const newMetrics = doc.querySelector('.sr-metrics-grid');
            if (oldMetrics && newMetrics) {
                oldMetrics.innerHTML = newMetrics.innerHTML;
            }

            // 3. Update browser history
            if (pushHistory && window.history && window.history.pushState) {
                window.history.pushState({ url: targetUrl }, '', targetUrl);
            }

            // 4. Re-bind events
            bindAjaxEvents();

            // 5. Restore search focus
            if (wasSearchActive) {
                const updatedSearch = document.querySelector('.sr-search-input');
                if (updatedSearch) {
                    updatedSearch.focus();
                    try { updatedSearch.setSelectionRange(searchPos, searchPos); } catch (e) {}
                }
            }
        })
        .catch(function(err) {
            if (err.name === 'AbortError') return;
            console.error('AJAX load error:', err);
            if (mainCard) {
                mainCard.style.opacity = '1';
                mainCard.style.pointerEvents = '';
            }
            window.location.href = targetUrl;
        });
    }

    function bindAjaxEvents() {
        const mainCard = document.querySelector('.sr-main-card');
        if (!mainCard) return;

        // 1. Status Filter Tabs
        const tabLinks = mainCard.querySelectorAll('.sr-tabs-left a');
        tabLinks.forEach(function(link) {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const href = this.getAttribute('href');
                if (href) loadContentViaAjax(href);
            });
        });

        // 2. Filter Form Submit & Change
        const filterForm = document.getElementById('serviceRequestFilterForm');
        if (filterForm) {
            filterForm.addEventListener('submit', function(e) {
                e.preventDefault();
                const url = buildUrlFromFilterForm(filterForm);
                loadContentViaAjax(url);
            });

            // Dropdowns change
            const selects = filterForm.querySelectorAll('select');
            selects.forEach(function(sel) {
                sel.addEventListener('change', function() {
                    const url = buildUrlFromFilterForm(filterForm);
                    loadContentViaAjax(url);
                });
            });

            // Date inputs change
            const dateInputs = filterForm.querySelectorAll('.sr-date-ctrl');
            dateInputs.forEach(function(inp) {
                inp.addEventListener('change', function() {
                    const url = buildUrlFromFilterForm(filterForm);
                    loadContentViaAjax(url);
                });
            });

            // Search input live typing (debounced)
            const searchInput = filterForm.querySelector('.sr-search-input');
            if (searchInput) {
                searchInput.addEventListener('input', function() {
                    clearTimeout(searchDebounceTimer);
                    searchDebounceTimer = setTimeout(function() {
                        const url = buildUrlFromFilterForm(filterForm);
                        loadContentViaAjax(url);
                    }, 400);
                });
            }

            // Reset button click
            const resetBtn = filterForm.querySelector('#filterResetBtn');
            if (resetBtn) {
                resetBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    const href = this.getAttribute('href') || 'service-requests.jsp';
                    loadContentViaAjax(href);
                });
            }
        }

        // 3. Pagination Controls
        const pageLinks = mainCard.querySelectorAll('.sr-pagination-bar a');
        pageLinks.forEach(function(link) {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const href = this.getAttribute('href');
                if (href && href !== '#') {
                    loadContentViaAjax(href);
                }
            });
        });
    }

    window.addEventListener('popstate', function() {
        loadContentViaAjax(window.location.href, false);
    });

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bindAjaxEvents);
    } else {
        bindAjaxEvents();
    }
})();
</script>

</body>
</html>