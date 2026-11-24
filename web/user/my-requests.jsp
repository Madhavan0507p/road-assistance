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
<%@ page import="com.roadassistance.service.ServiceRequestService" %>
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

    request.setAttribute("activeUserPage", "my-requests");

    int userId = currentUser.getUserId();
    String userFullName = (currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()) 
            ? currentUser.getFullName() : "Ravi Kumar";
    String userCode = "USR" + String.format("%03d", userId);

    // 2. Read Filter & Pagination Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String statusFilter = request.getParameter("status");
    if (statusFilter != null) statusFilter = statusFilter.trim(); else statusFilter = "";

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
    int pendingCount = 0;
    int acceptedCount = 0;
    int inProgressCount = 0;

    List requestRows = new ArrayList();
    int filteredTotal = 0;
    Map latestAutoCancelledReq = null;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // 0. Auto-cancel any accepted requests that have not moved to next stage within 15 minutes
            try {
                ServiceRequestService.autoCancelStagnantAcceptedRequests(conn, 15);
            } catch (Exception eAuto) {
                System.err.println("Notice in autoCancel check: " + eAuto.getMessage());
            }

            // Check if user has an auto-cancelled request to intimate them
            try {
                PreparedStatement psAuto = conn.prepareStatement(
                    "SELECT request_code, vehicle_number, breakdown_issue, additional_details, completed_date " +
                    "FROM service_requests " +
                    "WHERE (user_id = ? OR user_code = ? OR user_name = ?) " +
                    "  AND status = 'Cancelled' " +
                    "  AND additional_details LIKE '%Auto-cancelled%' " +
                    "ORDER BY request_id DESC LIMIT 1"
                );
                psAuto.setInt(1, userId);
                psAuto.setString(2, userCode);
                psAuto.setString(3, userFullName);
                ResultSet rsAuto = psAuto.executeQuery();
                if (rsAuto.next()) {
                    latestAutoCancelledReq = new HashMap();
                    latestAutoCancelledReq.put("code", rsAuto.getString("request_code"));
                    latestAutoCancelledReq.put("vehicle", rsAuto.getString("vehicle_number"));
                    latestAutoCancelledReq.put("issue", rsAuto.getString("breakdown_issue"));
                    latestAutoCancelledReq.put("details", rsAuto.getString("additional_details"));
                    latestAutoCancelledReq.put("date", rsAuto.getString("completed_date"));
                }
                rsAuto.close();
                psAuto.close();
            } catch (Exception ignored) {}

            // A. Statistics Query for Logged-in User (Active Non-Completed Requests Only)
            try {
                String statsSql = "SELECT " +
                        "COUNT(*) AS total_cnt, " +
                        "SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_cnt, " +
                        "SUM(CASE WHEN status IN ('Accepted', 'On The Way') THEN 1 ELSE 0 END) AS accepted_cnt, " +
                        "SUM(CASE WHEN status IN ('In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS in_progress_cnt " +
                        "FROM service_requests " +
                        "WHERE (user_id = ? OR user_code = ? OR user_name = ?) AND status != 'Completed'";
                ps = conn.prepareStatement(statsSql);
                ps.setInt(1, userId);
                ps.setString(2, userCode);
                ps.setString(3, userFullName);
                rs = ps.executeQuery();
                if (rs.next()) {
                    totalCount = rs.getInt("total_cnt");
                    pendingCount = rs.getInt("pending_cnt");
                    acceptedCount = rs.getInt("accepted_cnt");
                    inProgressCount = rs.getInt("in_progress_cnt");
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }

            // B. Build Filtered Query (Active Requests Only - Completed Requests Moved to Service History)
            StringBuilder countSql = new StringBuilder("SELECT COUNT(*) FROM service_requests WHERE (user_id = ? OR user_code = ? OR user_name = ?) AND status != 'Completed'");
            StringBuilder querySql = new StringBuilder(
                "SELECT sr.request_id, sr.request_code, sr.vehicle_number, sr.breakdown_issue, sr.location, sr.requested_date, sr.status, sr.mechanic_name, sr.service_cost, sr.additional_details, " +
                "COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                "COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                "COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, " +
                "COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image " +
                "FROM service_requests sr " +
                "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') AND uv.user_id = sr.user_id " +
                "WHERE (sr.user_id = ? OR sr.user_code = ? OR sr.user_name = ?) AND sr.status != 'Completed' " +
                "GROUP BY sr.request_id "
            );

            List params = new ArrayList();
            params.add(userId);
            params.add(userCode);
            params.add(userFullName);

            if (!search.isEmpty()) {
                countSql.append(" AND (request_code LIKE ? OR vehicle_number LIKE ? OR breakdown_issue LIKE ? OR location LIKE ?)");
                querySql.append(" AND (request_code LIKE ? OR vehicle_number LIKE ? OR breakdown_issue LIKE ? OR location LIKE ?)");
                String sParam = "%" + search + "%";
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
            }

            if (!statusFilter.isEmpty() && !"Completed".equalsIgnoreCase(statusFilter)) {
                countSql.append(" AND status = ?");
                querySql.append(" AND status = ?");
                params.add(statusFilter);
            }

            // Execute Count
            try {
                ps = conn.prepareStatement(countSql.toString());
                for (int i = 0; i < params.size(); i++) {
                    ps.setObject(i + 1, params.get(i));
                }
                rs = ps.executeQuery();
                if (rs.next()) {
                    filteredTotal = rs.getInt(1);
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }

            // C. Execute Paginated List Query
            querySql.append(" ORDER BY request_code DESC, request_id DESC LIMIT ? OFFSET ?");
            int offset = (currentPage - 1) * pageSize;

            try {
                ps = conn.prepareStatement(querySql.toString());
                int idx = 1;
                for (int i = 0; i < params.size(); i++) {
                    ps.setObject(idx++, params.get(i));
                }
                ps.setInt(idx++, pageSize);
                ps.setInt(idx++, offset);

                rs = ps.executeQuery();
                while (rs.next()) {
                    Map row = new HashMap();
                    String reqCode = rs.getString("request_code");
                    if (reqCode == null || reqCode.trim().isEmpty()) {
                        reqCode = "REQ" + (10000 + rs.getInt("request_id"));
                    }
                    row.put("id", rs.getInt("request_id"));
                    row.put("code", reqCode);
                    String vNum = rs.getString("vehicle_number");
                    if (vNum == null || vNum.trim().isEmpty()) vNum = "TN 45 AB 1234";
                    row.put("vehicle", vNum);

                    String issue = rs.getString("breakdown_issue");
                    if (issue == null || issue.trim().isEmpty()) issue = "Engine Overheating";
                    row.put("issue", issue);

                    String loc = rs.getString("location");
                    if (loc == null || loc.trim().isEmpty()) loc = "Manapparai (2.4 km)";
                    row.put("location", loc);

                    String rDateStr = rs.getString("requested_date");
                    if (rDateStr == null || rDateStr.trim().isEmpty()) {
                        rDateStr = "13-11-2026 • 10:24 AM";
                    }
                    row.put("requested_date", rDateStr);

                    String st = rs.getString("status");
                    if (st == null || st.trim().isEmpty()) st = "Pending";
                    row.put("status", st);

                    row.put("mechanic", rs.getString("mechanic_name"));
                    row.put("cost", rs.getString("service_cost"));
                    row.put("description", rs.getString("additional_details"));

                    // Determine Vehicle Model & Image from Database
                    String vModel = rs.getString("vehicle_model");
                    if (vModel == null || vModel.trim().isEmpty() || "Vehicle".equalsIgnoreCase(vModel.trim())) {
                        String vBrand = rs.getString("vehicle_brand");
                        vModel = (vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle";
                    }
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
                    row.put("model", vModel);
                    row.put("vehicle_img", vImg);
                    row.put("vehicle_type", vType != null ? vType : "Car");

                    // Determine Service Issue Icon
                    String issueIcon = "fa-solid fa-cogs";
                    String lowIssue = issue.toLowerCase();
                    if (lowIssue.contains("overheating") || lowIssue.contains("engine")) {
                        issueIcon = "fa-solid fa-car-crash";
                    } else if (lowIssue.contains("battery") || lowIssue.contains("jump")) {
                        issueIcon = "fa-solid fa-car-battery";
                    } else if (lowIssue.contains("tyre") || lowIssue.contains("puncture")) {
                        issueIcon = "fa-solid fa-compact-disc";
                    } else if (lowIssue.contains("general") || lowIssue.contains("service")) {
                        issueIcon = "fa-solid fa-gear";
                    } else if (lowIssue.contains("electrical") || lowIssue.contains("repair")) {
                        issueIcon = "fa-solid fa-bolt";
                    } else if (lowIssue.contains("brake")) {
                        issueIcon = "fa-solid fa-triangle-exclamation";
                    } else if (lowIssue.contains("clutch") || lowIssue.contains("gear")) {
                        issueIcon = "fa-solid fa-gears";
                    } else if (lowIssue.contains("fuel")) {
                        issueIcon = "fa-solid fa-gas-pump";
                    }
                    row.put("issue_icon", issueIcon);

                    // Parse Location and Distance
                    String locName = loc;
                    String locDist = "";
                    if (loc.contains("(") && loc.contains(")")) {
                        int p1 = loc.indexOf("(");
                        int p2 = loc.indexOf(")");
                        locName = loc.substring(0, p1).trim();
                        locDist = loc.substring(p1, p2 + 1).trim();
                    }
                    row.put("loc_name", locName);
                    row.put("loc_dist", locDist);

                    // Parse Date and Time
                    String pDate = rDateStr;
                    String pTime = "";
                    if (rDateStr.contains("•") || rDateStr.contains("·")) {
                        String delim = rDateStr.contains("•") ? "•" : "·";
                        String[] parts = rDateStr.split(delim);
                        pDate = parts[0].trim();
                        if (parts.length > 1) pTime = parts[1].trim();
                    } else if (rDateStr.contains(" ")) {
                        pDate = rDateStr;
                    }
                    if (pDate != null && !pDate.trim().isEmpty() && !pDate.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                        try {
                            Date parsed = null;
                            try { parsed = new SimpleDateFormat("MMM d, yyyy").parse(pDate); } catch(Exception ignored1) {}
                            if (parsed == null) {
                                try { parsed = new SimpleDateFormat("yyyy-MM-dd").parse(pDate); } catch(Exception ignored2) {}
                            }
                            if (parsed != null) {
                                pDate = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                            }
                        } catch(Exception ignored) {}
                    }
                    row.put("date_part", pDate);
                    row.put("time_part", pTime);

                    requestRows.add(row);
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    int totalPages = (int) Math.ceil((double) filteredTotal / pageSize);
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int showingStart = (filteredTotal == 0) ? 0 : (currentPage - 1) * pageSize + 1;
    int showingEnd = Math.min(currentPage * pageSize, filteredTotal);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Requests — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Common Dashboard Stylesheet (Fixed Sidebar & Topbar Shell) -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css?v=2.0">

    <!-- Dedicated User Service Requests Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-service-requests.css?v=2.0">

    <style>
        /* Interactive Detail Modal Styling */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(17, 24, 39, 0.75);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
            padding: 20px;
        }
        .modal-overlay.active {
            display: flex;
        }
        .detail-modal-card {
            background: #FFFFFF;
            border-radius: 20px;
            width: 100%;
            max-width: 580px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35);
            overflow: hidden;
            animation: modalFadeIn 0.25s ease-out;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: translateY(20px) scale(0.97); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }
        .detail-modal-header {
            background-color: #1F2937;
            padding: 20px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            color: #FFFFFF;
        }
        .detail-modal-header h3 {
            font-size: 18px;
            font-weight: 800;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .detail-modal-header h3 span {
            color: #F97316;
        }
        .btn-modal-close {
            background: rgba(255, 255, 255, 0.1);
            border: none;
            color: #FFFFFF;
            font-size: 16px;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background 0.2s;
        }
        .btn-modal-close:hover {
            background: rgba(249, 115, 22, 0.8);
        }
        .detail-modal-body {
            padding: 24px;
            display: flex;
            flex-direction: column;
            gap: 16px;
            max-height: 75vh;
            overflow-y: auto;
        }
        .detail-info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
        }
        .detail-item {
            background: #F9FAFB;
            padding: 12px 14px;
            border-radius: 10px;
            border: 1px solid #E5E7EB;
        }
        .detail-label {
            font-size: 11.5px;
            color: #6B7280;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            display: block;
            margin-bottom: 4px;
        }
        .detail-val {
            font-size: 14px;
            font-weight: 700;
            color: #1F2937;
        }
        .detail-full-row {
            grid-column: span 2;
        }
        .detail-modal-footer {
            padding: 16px 24px;
            background: #F9FAFB;
            border-top: 1px solid #E5E7EB;
            display: flex;
            justify-content: flex-end;
            gap: 12px;
        }
        .btn-modal-action {
            padding: 9px 20px;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 700;
            cursor: pointer;
            border: none;
            transition: all 0.2s;
        }
        .btn-modal-primary {
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            color: #FFFFFF;
        }
        .btn-modal-secondary {
            background: #E5E7EB;
            color: #374151;
        }
        .btn-modal-secondary:hover {
            background: #D1D5DB;
        }
    </style>
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <div class="my-requests-page-container">
                <div class="my-requests-main-card">

                    <!-- Page Header: Title + "+ New Request" Button -->
                    <div class="sr-header-row">
                        <div class="sr-title-group">
                            <div class="sr-title-icon-box">
                                <i class="fa-solid fa-clipboard-list"></i>
                            </div>
                            <div class="sr-title-text">
                                <h1>My <span class="accent-orange">Requests</span></h1>
                                <p>Track and manage your service requests easily.</p>
                            </div>
                        </div>

                        <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="btn-new-request">
                            <i class="fa-solid fa-plus"></i>
                            <span>New Request</span>
                        </a>
                    </div>

            <!-- Four Summary Metric Cards -->
            <div class="sr-stats-grid">
                <!-- Card 1: Active Requests -->
                <div class="sr-stat-card sr-card-total">
                    <div class="sr-stat-icon-box">
                        <i class="fa-solid fa-clipboard-list"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">Active Requests</span>
                        <span class="sr-stat-number"><%= totalCount %></span>
                    </div>
                </div>

                <!-- Card 2: Pending -->
                <div class="sr-stat-card sr-card-pending">
                    <div class="sr-stat-icon-box">
                        <i class="fa-regular fa-clock"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">Pending</span>
                        <span class="sr-stat-number"><%= pendingCount %></span>
                    </div>
                </div>

                <!-- Card 3: Accepted -->
                <div class="sr-stat-card sr-card-accepted">
                    <div class="sr-stat-icon-box">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">Accepted</span>
                        <span class="sr-stat-number"><%= acceptedCount %></span>
                    </div>
                </div>

                <!-- Card 4: In Progress -->
                <div class="sr-stat-card sr-card-inprogress" style="background-color: #FFF7ED; border: 1px solid #FFEDD5;">
                    <div class="sr-stat-icon-box" style="background: rgba(249, 115, 22, 0.18); color: #EA580C;">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">In Progress</span>
                        <span class="sr-stat-number"><%= inProgressCount %></span>
                    </div>
                </div>
            </div>

            <!-- Auto-Cancelled Re-Request Intimation Banner -->
            <% if (latestAutoCancelledReq != null) { %>
            <div class="auto-cancelled-top-banner" style="display: flex; align-items: center; justify-content: space-between; gap: 16px; background: #FFF7ED; border: 1.5px solid #FDBA74; border-left: 5px solid #EA580C; border-radius: 14px; padding: 16px 20px; margin-bottom: 22px; box-shadow: 0 4px 14px rgba(234, 88, 12, 0.08); flex-wrap: wrap;">
                <div style="display: flex; align-items: flex-start; gap: 14px;">
                    <div class="banner-icon-circle" style="width: 40px; height: 40px; border-radius: 50%; background: #FEE2E2; color: #DC2626; display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; box-shadow: 0 2px 8px rgba(220, 38, 38, 0.2);">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                    </div>
                    <div>
                        <div style="font-weight: 800; font-size: 15px; color: #9A3412; margin-bottom: 3px;">
                            Assistance Request Auto-Cancelled &bull; Re-Request Intimation
                        </div>
                        <div style="font-size: 13.5px; color: #7C2D12; line-height: 1.45;">
                            Your breakdown request <strong style="color: #1E293B;"><%= latestAutoCancelledReq.get("code") %></strong> for vehicle <strong style="color: #EA580C;"><%= latestAutoCancelledReq.get("vehicle") %></strong> was automatically cancelled because the mechanic did not advance the process to the next stage in time. Please re-request assistance to connect with an available mechanic.
                        </div>
                    </div>
                </div>
                <a href="${pageContext.request.contextPath}/user/request-assistance.jsp?reRequest=<%= latestAutoCancelledReq.get("code") %>" class="btn-banner-rerequest" style="display: inline-flex; align-items: center; gap: 8px; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFFFFF !important; font-weight: 700; font-size: 13px; padding: 10px 20px; border-radius: 10px; text-decoration: none; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.35); white-space: nowrap;">
                    <i class="fa-solid fa-rotate-right"></i> Re-Request Assistance Now
                </a>
            </div>
            <% } %>

            <!-- Main Service Requests Table Card -->
            <div class="sr-main-card">
                <!-- Card Header with Title and Search Form -->
                <div class="sr-card-header">
                    <div class="sr-card-title-group">
                        <i class="fa-solid fa-clipboard-list"></i>
                        <h2>My Service Requests</h2>
                    </div>

                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <a href="${pageContext.request.contextPath}/user/service-history.jsp" class="btn-history-nav" style="display: inline-flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 10px; background: #FFF7ED; border: 1.5px solid #FFEDD5; color: #EA580C; font-weight: 700; font-size: 13px; text-decoration: none; transition: all 0.2s;" title="View all completed services">
                            <i class="fa-solid fa-clock-rotate-left"></i>
                            <span>Service History</span>
                        </a>

                        <form action="my-requests.jsp" method="GET" class="sr-search-form">
                            <% if (!statusFilter.isEmpty()) { %>
                                <input type="hidden" name="status" value="<%= statusFilter %>">
                            <% } %>
                            <div class="sr-search-input-box">
                                <i class="fa-solid fa-magnifying-glass"></i>
                                <input type="text" 
                                       name="search" 
                                       class="sr-search-input" 
                                       placeholder="Search by Request ID..." 
                                       value="<%= search %>">
                            </div>
                            <button type="submit" class="btn-sr-search">
                                <i class="fa-solid fa-magnifying-glass"></i>
                                <span>Search</span>
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Table Responsive Container -->
                <div class="sr-table-container">
                    <% if (requestRows.isEmpty()) { %>
                        <div class="sr-empty-state">
                            <div class="sr-empty-icon">
                                <i class="fa-solid fa-inbox"></i>
                            </div>
                            <h3 class="sr-empty-title">No active requests found</h3>
                            <p class="sr-empty-desc">
                                <%= (!search.isEmpty() || !statusFilter.isEmpty()) 
                                    ? "No active requests matched your filter criteria. Try clearing search filters." 
                                    : "You currently have no active service requests. Completed services are available in Service History." %>
                            </p>
                            <div style="display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin-top: 14px;">
                                <a href="my-requests.jsp" class="btn-new-request" style="padding: 9px 18px; font-size: 13px;">
                                    <i class="fa-solid fa-arrow-rotate-left"></i>
                                    <span>Reset Filters</span>
                                </a>
                                <a href="${pageContext.request.contextPath}/user/service-history.jsp" class="btn-new-request" style="padding: 9px 18px; font-size: 13px; background: #111827; box-shadow: none;">
                                    <i class="fa-solid fa-clock-rotate-left"></i>
                                    <span>View Service History</span>
                                </a>
                            </div>
                        </div>
                    <% } else { %>
                        <table class="sr-data-table">
                            <thead>
                                <tr>
                                    <th style="width: 32px; text-align: center;">S.No</th>
                                    <th style="width: 95px;">Request ID</th>
                                    <th style="width: 155px;">Vehicle</th>
                                    <th style="width: 140px;">Service Issue</th>
                                    <th style="width: 130px;">Location</th>
                                    <th style="width: 130px;">Requested On</th>
                                    <th style="width: 115px;">Status</th>
                                    <th style="width: 175px; text-align: center;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    for (int i = 0; i < requestRows.size(); i++) {
                                        Map req = (Map) requestRows.get(i);
                                        int rowSerial = (currentPage - 1) * pageSize + (i + 1);
                                        String rCode = (String) req.get("code");
                                        String vNum = (String) req.get("vehicle");
                                        String vModel = (String) req.get("model");
                                        String vImg = (String) req.get("vehicle_img");
                                        String issue = (String) req.get("issue");
                                        String issueIcon = (String) req.get("issue_icon");
                                        String locName = (String) req.get("loc_name");
                                        String locDist = (String) req.get("loc_dist");
                                        String dPart = (String) req.get("date_part");
                                        String tPart = (String) req.get("time_part");
                                        String st = (String) req.get("status");
                                        String reqDesc = (String) req.get("description");
                                        boolean isAutoCancelled = (st != null && st.equalsIgnoreCase("Cancelled") && reqDesc != null && reqDesc.contains("Auto-cancelled"));
                                        boolean canReRequest = (st != null && (st.equalsIgnoreCase("Cancelled") || st.equalsIgnoreCase("Rejected")));

                                        // Status Pill Class & Icon
                                        String pillClass = "status-pill-pending";
                                        String iconClass = "fa-regular fa-clock";

                                        if (isAutoCancelled) {
                                            pillClass = "status-pill-rejected status-pill-auto-cancelled";
                                            iconClass = "fa-solid fa-triangle-exclamation";
                                        } else if ("Accepted".equalsIgnoreCase(st)) {
                                            pillClass = "status-pill-accepted";
                                            iconClass = "fa-solid fa-check";
                                        } else if ("Completed".equalsIgnoreCase(st)) {
                                            pillClass = "status-pill-completed";
                                            iconClass = "fa-solid fa-circle-check";
                                        } else if ("Rejected".equalsIgnoreCase(st) || "Cancelled".equalsIgnoreCase(st)) {
                                            pillClass = "status-pill-rejected";
                                            iconClass = "fa-solid fa-circle-xmark";
                                        } else if ("In Progress".equalsIgnoreCase(st)) {
                                            pillClass = "status-pill-pending";
                                            iconClass = "fa-regular fa-clock";
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
                                    <!-- 1. Row Index -->
                                    <td class="td-row-num"><%= rowSerial %></td>

                                    <!-- 2. Request ID Badge -->
                                    <td>
                                        <span class="badge-req-id"><%= rCode %></span>
                                    </td>

                                    <!-- 3. Vehicle with Thumbnail -->
                                    <td>
                                        <div class="vehicle-cell-box">
                                            <img src="<%= vImgSrc %>" 
                                                 alt="<%= vModel %>" 
                                                 class="vehicle-thumb-img"
                                                 onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-i20.png';">
                                            <div class="vehicle-text-info">
                                                <span class="vehicle-reg-no"><%= vNum %></span>
                                                <span class="vehicle-model-desc"><%= vModel %></span>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- 4. Service Issue -->
                                    <td>
                                        <div class="issue-cell-box">
                                            <i class="<%= issueIcon %>"></i>
                                            <span class="issue-name-text"><%= issue %></span>
                                        </div>
                                    </td>

                                    <!-- 5. Location -->
                                    <td>
                                        <div class="location-cell-box">
                                            <i class="fa-solid fa-location-dot"></i>
                                            <div class="location-text-info">
                                                <span class="location-name"><%= locName %></span>
                                                <% if (!locDist.isEmpty()) { %>
                                                    <span class="location-dist"><%= locDist %></span>
                                                <% } %>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- 6. Requested On (Date & Time) -->
                                    <td>
                                        <div class="datetime-cell-box">
                                            <div class="datetime-row">
                                                <i class="fa-regular fa-calendar"></i>
                                                <span><%= dPart %></span>
                                            </div>
                                            <% if (!tPart.isEmpty()) { %>
                                            <div class="datetime-row">
                                                <i class="fa-regular fa-clock"></i>
                                                <span><%= tPart %></span>
                                            </div>
                                            <% } %>
                                        </div>
                                    </td>

                                    <!-- 7. Status Pill -->
                                    <td>
                                        <span class="status-pill <%= pillClass %>" title="<%= isAutoCancelled ? "Auto-cancelled: The mechanic did not move the process to the next stage within the required timeframe." : "" %>">
                                            <i class="<%= iconClass %>"></i>
                                            <%= isAutoCancelled ? "Auto-Cancelled" : st %>
                                        </span>
                                    </td>

                                    <!-- 8. Action: View & Re-Request Buttons -->
                                    <td style="text-align: center;">
                                        <div style="display: flex; align-items: center; justify-content: center; gap: 8px; flex-wrap: nowrap;">
                                            <button type="button" 
                                                    class="btn-action-view"
                                                    style="white-space: nowrap; flex-shrink: 0;"
                                                    onclick="showDetailModal('<%= rCode %>', '<%= vNum %>', '<%= vModel %>', '<%= issue %>', '<%= locName + (locDist.isEmpty() ? "" : " " + locDist) %>', '<%= dPart + (tPart.isEmpty() ? "" : " • " + tPart) %>', '<%= isAutoCancelled ? "Auto-Cancelled" : st %>', '<%= (req.get("mechanic") != null ? req.get("mechanic") : "Mechanic Network") %>', '<%= (req.get("description") != null ? req.get("description").toString().replace("'", "\\'") : "Roadside vehicle breakdown assistance requested.") %>')">
                                                <i class="fa-regular fa-eye"></i>
                                                <span>View</span>
                                            </button>
                                            <% if (canReRequest) { %>
                                                <a href="${pageContext.request.contextPath}/user/request-assistance.jsp?reRequest=<%= rCode %>" 
                                                   class="btn-action-rerequest" 
                                                   style="display: inline-flex; align-items: center; gap: 5px; background: #FFF7ED; border: 1.5px solid #F97316; color: #EA580C !important; font-size: 11.5px; font-weight: 700; padding: 5px 10px; border-radius: 7px; text-decoration: none; white-space: nowrap; flex-shrink: 0;"
                                                   title="Re-request roadside assistance for vehicle <%= vNum %>">
                                                    <i class="fa-solid fa-rotate-right"></i>
                                                    <span>Re-Request</span>
                                                </a>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } %>
                </div>

                <!-- Pagination Footer -->
                <div class="sr-pagination-footer">
                    <div class="sr-record-count-text">
                        Showing <%= showingStart %> to <%= showingEnd %> of <%= filteredTotal %> requests
                    </div>

                    <div class="sr-pagination-controls">
                        <!-- Previous Page -->
                        <% if (currentPage > 1) { %>
                            <a href="my-requests.jsp?page=<%= currentPage - 1 %><%= !search.isEmpty() ? "&search=" + search : "" %><%= !statusFilter.isEmpty() ? "&status=" + statusFilter : "" %>" 
                               class="btn-pagination">Previous</a>
                        <% } else { %>
                            <span class="btn-pagination disabled">Previous</span>
                        <% } %>

                        <!-- Page Number Buttons (Matching 1, 2, 3 in Reference) -->
                        <%
                            int pStart = 1;
                            int pEnd = Math.max(1, totalPages);
                            for (int p = pStart; p <= pEnd; p++) {
                        %>
                            <% if (p == currentPage) { %>
                                <span class="btn-pagination active"><%= p %></span>
                            <% } else { %>
                                <a href="my-requests.jsp?page=<%= p %><%= !search.isEmpty() ? "&search=" + search : "" %><%= !statusFilter.isEmpty() ? "&status=" + statusFilter : "" %>" 
                                   class="btn-pagination"><%= p %></a>
                            <% } %>
                        <% } %>

                        <!-- Next Page -->
                        <% if (currentPage < totalPages) { %>
                            <a href="my-requests.jsp?page=<%= currentPage + 1 %><%= !search.isEmpty() ? "&search=" + search : "" %><%= !statusFilter.isEmpty() ? "&status=" + statusFilter : "" %>" 
                               class="btn-pagination">Next</a>
                        <% } else { %>
                            <span class="btn-pagination disabled">Next</span>
                        <% } %>
                    </div>
                </div>

            </div>
        </div>

    </main>
</div>

    <!-- Universal Rich Service Request Details Modal -->
    <jsp:include page="/common/service-request-view-modal.jsp" />

    <!-- JavaScript Interactions -->
    <script>
        // Detail Modal Operations
        function showDetailModal(code, vnum, vmodel, issue, loc, date, status, mech, notes) {
            window.openServiceRequestModal({
                code: code,
                vehicleNumber: vnum,
                brandModel: vmodel,
                issue: issue,
                location: loc,
                reqDate: date,
                status: status,
                mechName: mech,
                description: notes
            });
        }

        function closeDetailModal() {
            window.closeServiceRequestModal();
        }

        function handleOverlayClick(event) {
            window.closeServiceRequestModal();
        }

        // Close modal on Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeDetailModal();
            }
        });
    </script>
</body>
</html>
