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
<%@ page import="com.roadassistance.model.Mechanic" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%@ page import="com.roadassistance.util.EmailUtil" %>
<%
    // Prevent browser back-button caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 1. Mechanic Session Authentication & Approval Verification
    Mechanic currentMech = (Mechanic) session.getAttribute("mechanic");
    if (currentMech == null || !currentMech.isApproved()) {
        if (session != null) {
            session.removeAttribute("mechanic");
        }
        String redirectParam = (currentMech != null && currentMech.isBlocked()) ? "error=blocked" : ((currentMech != null && currentMech.isPending()) ? "error=pending" : "msg=auth_required");
        response.sendRedirect(request.getContextPath() + "/mechanic/login.jsp?" + redirectParam);
        return;
    }

    request.setAttribute("activeMechPage", "pending");

    String mechCode = currentMech.getMechanicCode();
    if (mechCode == null || mechCode.trim().isEmpty()) mechCode = "MEC003";

    String workshopName = currentMech.getWorkshopName();
    if (workshopName == null || workshopName.trim().isEmpty()) {
        workshopName = currentMech.getShopName();
    }
    if (workshopName == null || workshopName.trim().isEmpty()) workshopName = "Kumar Auto Works";

    String ownerName = currentMech.getOwnerName();
    if (ownerName == null || ownerName.trim().isEmpty()) {
        ownerName = currentMech.getFirstName();
    }
    if (ownerName == null || ownerName.trim().isEmpty()) ownerName = "Kumar";

    // 2. Handle Accept and Reject Actions (via AJAX or GET)
    String action = request.getParameter("action");
    String targetReqId = request.getParameter("reqId");
    String isAjax = request.getParameter("ajax");

    if (action != null && targetReqId != null && !targetReqId.trim().isEmpty()) {
        targetReqId = targetReqId.trim();
        String newStatus = "accept".equalsIgnoreCase(action) ? "Accepted" : ("reject".equalsIgnoreCase(action) ? "Rejected" : null);

        if (newStatus != null) {
            Connection actionConn = null;
            PreparedStatement actionPs = null;
            boolean updateSuccess = false;
            try {
                actionConn = DBConnection.getConnection();
                if (actionConn != null) {
                    int parsedId = 0;
                    try { parsedId = Integer.parseInt(targetReqId); } catch (Exception ignored) {}

                    if ("accept".equalsIgnoreCase(action)) {
                        String updateSql = "UPDATE service_requests SET status = 'Accepted', mechanic_code = ?, mechanic_name = ?, assigned_at = CURRENT_TIMESTAMP(), assigned_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p') WHERE (request_code = ? OR request_id = ?) AND status = 'Pending'";
                        actionPs = actionConn.prepareStatement(updateSql);
                        actionPs.setString(1, mechCode);
                        actionPs.setString(2, workshopName);
                        actionPs.setString(3, targetReqId);
                        actionPs.setInt(4, parsedId);
                    } else {
                        String updateSql = "UPDATE service_requests SET status = 'Rejected' WHERE (request_code = ? OR request_id = ?) AND status = 'Pending'";
                        actionPs = actionConn.prepareStatement(updateSql);
                        actionPs.setString(1, targetReqId);
                        actionPs.setInt(2, parsedId);
                    }

                    int rowsUpdated = actionPs.executeUpdate();
                    updateSuccess = (rowsUpdated > 0);
                    if (updateSuccess) {
                        EmailUtil.notifyUserOfRequestStatusUpdateAsync(targetReqId, newStatus, null);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (actionPs != null) try { actionPs.close(); } catch (Exception ignored) {}
                if (actionConn != null) try { actionConn.close(); } catch (Exception ignored) {}
            }

            if ("true".equalsIgnoreCase(isAjax)) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                out.print("{\"success\": " + updateSuccess + ", \"action\": \"" + action + "\", \"reqId\": \"" + targetReqId + "\", \"newStatus\": \"" + newStatus + "\"}");
                return;
            } else {
                response.sendRedirect("pending-requests.jsp?msg=" + action + "&reqId=" + targetReqId);
                return;
            }
        }
    }

    // 3. Read Search & Filter Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String serviceIssueFilter = request.getParameter("serviceIssue");
    if (serviceIssueFilter != null) serviceIssueFilter = serviceIssueFilter.trim(); else serviceIssueFilter = "";

    String sortOrder = request.getParameter("sort");
    if (sortOrder != null) sortOrder = sortOrder.trim(); else sortOrder = "newest";

    String msg = request.getParameter("msg");
    String msgReqId = request.getParameter("reqId");

    // Dynamic Current Date Display
    SimpleDateFormat sdfDisplayDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDisplayDate.format(new Date());

    // 4. Database Queries: Statistics & Pending List
    int totalRequests = 0;
    int pendingRequests = 0;
    int acceptedRequests = 0;
    int completedRequests = 0;
    int rejectedRequests = 0;

    List pendingList = new ArrayList();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // A. Statistics Query
            try {
                String statsSql = "SELECT " +
                        "COUNT(*) AS total_cnt, " +
                        "SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_cnt, " +
                        "SUM(CASE WHEN status IN ('Accepted', 'On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS accepted_cnt, " +
                        "SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_cnt, " +
                        "SUM(CASE WHEN status = 'Rejected' OR status = 'Cancelled' THEN 1 ELSE 0 END) AS rejected_cnt " +
                        "FROM service_requests " +
                        "WHERE ((mechanic_code = ? OR mechanic_name = ? OR mechanic_name LIKE ?) " +
                        "   OR (status = 'Pending' AND (mechanic_code IS NULL OR mechanic_code = '' OR mechanic_name = 'Unassigned' OR mechanic_name = 'Nearby Mechanics' OR mechanic_name IS NULL OR mechanic_name = '' OR request_type = 'Common' OR request_type = 'Broadcast')))";
                ps = conn.prepareStatement(statsSql);
                ps.setString(1, mechCode);
                ps.setString(2, workshopName);
                ps.setString(3, "%" + workshopName + "%");
                rs = ps.executeQuery();
                if (rs.next()) {
                    totalRequests = rs.getInt("total_cnt");
                    pendingRequests = rs.getInt("pending_cnt");
                    acceptedRequests = rs.getInt("accepted_cnt");
                    completedRequests = rs.getInt("completed_cnt");
                    rejectedRequests = rs.getInt("rejected_cnt");
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }

            // B. Filtered Pending Requests Query
            StringBuilder querySql = new StringBuilder(
                "SELECT sr.request_id, sr.request_code, sr.user_name, " +
                "  (SELECT u.phone FROM users u WHERE u.user_id = sr.user_id OR u.full_name = sr.user_name LIMIT 1) AS user_phone, " +
                "  sr.vehicle_number, " +
                "  COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                "  COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                "  COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, " +
                "  COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, " +
                "  sr.breakdown_issue, sr.location, sr.requested_date, sr.requested_at, sr.status, sr.additional_details " +
                "FROM service_requests sr " +
                "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                "WHERE ((sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) " +
                "   OR (sr.status = 'Pending' AND (sr.mechanic_code IS NULL OR sr.mechanic_code = '' OR sr.mechanic_name = 'Unassigned' OR sr.mechanic_name = 'Nearby Mechanics' OR sr.mechanic_name IS NULL OR sr.mechanic_name = '' OR sr.request_type = 'Common' OR sr.request_type = 'Broadcast'))) " +
                "  AND sr.status = 'Pending'"
            );

            List params = new ArrayList();
            params.add(mechCode);
            params.add(workshopName);
            params.add("%" + workshopName + "%");

            if (!search.isEmpty()) {
                querySql.append(" AND (sr.request_code LIKE ? OR sr.vehicle_number LIKE ? OR sr.location LIKE ? OR sr.breakdown_issue LIKE ? OR sr.user_name LIKE ?)");
                String sParam = "%" + search + "%";
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
            }

            if (!serviceIssueFilter.isEmpty() && !"all".equalsIgnoreCase(serviceIssueFilter)) {
                querySql.append(" AND sr.breakdown_issue LIKE ?");
                params.add("%" + serviceIssueFilter + "%");
            }

            if ("oldest".equalsIgnoreCase(sortOrder)) {
                querySql.append(" ORDER BY sr.request_id DESC");
            } else {
                querySql.append(" ORDER BY sr.request_id ASC");
            }

            try {
                ps = conn.prepareStatement(querySql.toString());
                for (int i = 0; i < params.size(); i++) {
                    ps.setObject(i + 1, params.get(i));
                }

                rs = ps.executeQuery();
                while (rs.next()) {
                    Map row = new HashMap();
                    String reqCode = rs.getString("request_code");
                    if (reqCode == null || reqCode.trim().isEmpty()) {
                        reqCode = "REQ" + (10000 + rs.getInt("request_id"));
                    }
                    row.put("id", rs.getInt("request_id"));
                    row.put("code", reqCode);

                    String uName = rs.getString("user_name");
                    if (uName == null || uName.trim().isEmpty()) uName = "Vehicle Owner";
                    row.put("user_name", uName);

                    String uPhone = rs.getString("user_phone");
                    if (uPhone == null || uPhone.trim().isEmpty()) uPhone = "+91 98758 23975";
                    row.put("user_phone", uPhone);

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
                        java.sql.Timestamp ts = rs.getTimestamp("requested_at");
                        if (ts != null) {
                            rDateStr = new SimpleDateFormat("dd-MM-yyyy • hh:mm a").format(ts);
                        } else {
                            rDateStr = "13-11-2026 • 10:24 AM";
                        }
                    }
                    if (rDateStr != null && !rDateStr.trim().isEmpty()) {
                        String delim = rDateStr.contains("•") ? "•" : (rDateStr.contains("·") ? "·" : null);
                        if (delim != null) {
                            String[] p = rDateStr.split(delim);
                            String dPart = p[0].trim();
                            String tPart = p.length > 1 ? p[1].trim() : "";
                            if (!dPart.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                                try {
                                    Date parsed = null;
                                    try { parsed = new SimpleDateFormat("MMM d, yyyy").parse(dPart); } catch(Exception ign1){}
                                    if (parsed == null) {
                                        try { parsed = new SimpleDateFormat("yyyy-MM-dd").parse(dPart); } catch(Exception ign2){}
                                    }
                                    if (parsed != null) dPart = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                                } catch(Exception ign){}
                            }
                            rDateStr = dPart + " • " + tPart;
                        }
                    }
                    row.put("requested_date", rDateStr);

                    String st = rs.getString("status");
                    if (st == null || st.trim().isEmpty()) st = "Pending";
                    row.put("status", st);

                    String notes = rs.getString("additional_details");
                    if (notes == null || notes.trim().isEmpty()) notes = "Customer requested roadside assistance for " + issue + ".";
                    row.put("notes", notes);
                    row.put("description", notes);

                    // Determine Vehicle Model & Thumbnail Image from Database
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
                        issueIcon = "fa-solid fa-cogs";
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
                    if (rDateStr.contains("•")) {
                        String[] parts = rDateStr.split("•");
                        pDate = parts[0].trim();
                        if (parts.length > 1) pTime = parts[1].trim();
                    } else if (rDateStr.contains(" ")) {
                        pDate = rDateStr;
                    }
                    row.put("date_part", pDate);
                    row.put("time_part", pTime);

                    pendingList.add(row);
                }
            } catch (Exception ex) {
                ex.printStackTrace();
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

    int pendingFilteredCount = pendingList.size();

    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 rows per page

    int totalPages = (pendingFilteredCount + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, pendingFilteredCount);
    List displayList = (pendingFilteredCount > 0) ? pendingList.subList(startIndex, endIndex) : new ArrayList();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pending Requests — Mechanic Portal</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Mechanic Shell & Base Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">

    <!-- Dedicated Pending Requests Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-pending-requests.css?v=2.2">
</head>
<body>

    <!-- 1. Top Navigation Bar (Dark Charcoal, Logo, Hamburger, Notifications, Avatar) -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Left Sidebar + Main White Canvas -->
    <div class="mech-dashboard-shell">

        <!-- Fixed Left Sidebar with Automotive Sunset Road Background Image -->
        <jsp:include page="sidebar.jsp" />

        <!-- Main Content White Canvas -->
        <main class="mech-main-canvas">

            <!-- Page Header: Title + Dynamic Current Date Card -->
            <div class="pr-header-row">
                <div class="pr-title-group">
                    <div class="pr-title-icon-box">
                        <i class="fa-solid fa-clock"></i>
                    </div>
                    <div class="pr-title-text">
                        <h1>Pending <span class="accent-orange">Requests</span></h1>
                        <p>Service requests that are waiting for your response.</p>
                    </div>
                </div>

                <div class="pr-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <!-- Feedback Notification Banner if redirected -->
            <% if ("accept".equalsIgnoreCase(msg)) { %>
                <div class="pr-alert-banner pr-alert-success" id="statusNotification">
                    <span><i class="fa-solid fa-circle-check"></i> Request <strong><%= msgReqId != null ? msgReqId : "" %></strong> was successfully accepted and moved to Accepted Requests!</span>
                    <button type="button" class="pr-alert-close" onclick="document.getElementById('statusNotification').remove()">&times;</button>
                </div>
            <% } else if ("reject".equalsIgnoreCase(msg)) { %>
                <div class="pr-alert-banner pr-alert-rejected" id="statusNotification">
                    <span><i class="fa-solid fa-circle-xmark"></i> Request <strong><%= msgReqId != null ? msgReqId : "" %></strong> was rejected.</span>
                    <button type="button" class="pr-alert-close" onclick="document.getElementById('statusNotification').remove()">&times;</button>
                </div>
            <% } %>

            <!-- Dynamic Toast Container for AJAX Actions -->
            <div id="dynamicAlertContainer"></div>

            <!-- Four Summary Metric Cards -->
            <div class="pr-stats-grid">
                <!-- Card 1: Total Requests -->
                <div class="pr-stat-card pr-card-total">
                    <div class="pr-stat-icon-box">
                        <i class="fa-solid fa-clipboard-list"></i>
                    </div>
                    <div class="pr-stat-info">
                        <span class="pr-stat-label">Total Requests</span>
                        <span class="pr-stat-number" id="statTotalRequests"><%= totalRequests %></span>
                    </div>
                </div>

                <!-- Card 2: Pending Requests -->
                <div class="pr-stat-card pr-card-pending">
                    <div class="pr-stat-icon-box">
                        <i class="fa-solid fa-clock"></i>
                    </div>
                    <div class="pr-stat-info">
                        <span class="pr-stat-label">Pending Requests</span>
                        <span class="pr-stat-number" id="statPendingRequests"><%= pendingRequests %></span>
                    </div>
                </div>

                <!-- Card 3: Accepted Requests -->
                <div class="pr-stat-card pr-card-accepted">
                    <div class="pr-stat-icon-box">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <div class="pr-stat-info">
                        <span class="pr-stat-label">Accepted Requests</span>
                        <span class="pr-stat-number" id="statAcceptedRequests"><%= acceptedRequests %></span>
                    </div>
                </div>

                <!-- Card 4: Completed Requests -->
                <div class="pr-stat-card pr-card-completed">
                    <div class="pr-stat-icon-box">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div class="pr-stat-info">
                        <span class="pr-stat-label">Completed Requests</span>
                        <span class="pr-stat-number" id="statCompletedRequests"><%= completedRequests %></span>
                    </div>
                </div>
            </div>

            <!-- Search and Filter Toolbar -->
            <form action="pending-requests.jsp" method="GET" class="pr-toolbar-form">
                <!-- 1. Search Box -->
                <div class="pr-search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" 
                           name="search" 
                           class="pr-search-input" 
                           placeholder="Search by Request ID, Vehicle No, or Location..." 
                           value="<%= search %>">
                </div>

                <!-- 2. Service Issue Dropdown -->
                <div class="pr-select-box">
                    <select name="serviceIssue" class="pr-select-control" onchange="this.form.submit()">
                        <option value="" <%= serviceIssueFilter.isEmpty() ? "selected" : "" %>>Select Service Issue</option>
                        <option value="Engine Overheating" <%= "Engine Overheating".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Engine Overheating</option>
                        <option value="General Service" <%= "General Service".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>General Service</option>
                        <option value="Battery Jump Start" <%= "Battery Jump Start".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Battery Jump Start</option>
                        <option value="Electrical Repair" <%= "Electrical Repair".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Electrical Repair</option>
                        <option value="Tyre Puncture" <%= "Tyre Puncture".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Tyre Puncture</option>
                        <option value="Engine Issue" <%= "Engine Issue".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Engine Issue</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- 3. Sort Dropdown -->
                <div class="pr-select-box">
                    <select name="sort" class="pr-select-control" onchange="this.form.submit()">
                        <option value="newest" <%= !"oldest".equalsIgnoreCase(sortOrder) ? "selected" : "" %>>Sort by Oldest</option>
                        <option value="oldest" <%= "oldest".equalsIgnoreCase(sortOrder) ? "selected" : "" %>>Sort by Newest</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- 4. Orange Search Button -->
                <button type="submit" class="btn-pr-search">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <span>Search</span>
                </button>
            </form>

            <!-- Pending Service Requests Section -->
            <div class="pr-main-card">
                <!-- Section Header with Title and Pending Count Badge -->
                <div class="pr-card-header">
                    <div class="pr-card-title-group">
                        <i class="fa-solid fa-calendar-check"></i>
                        <h2>Pending Service Requests</h2>
                    </div>

                    <div class="pr-badge-count" id="badgePendingCount">
                        <span><%= pendingFilteredCount %> Pending Requests</span>
                    </div>
                </div>

                <!-- Responsive Table Container -->
                <div class="pr-table-container">
                    <% if (pendingList.isEmpty()) { %>
                        <div class="pr-empty-state">
                            <div class="pr-empty-icon">
                                <i class="fa-solid fa-clipboard-check"></i>
                            </div>
                            <h3 class="pr-empty-title">No Pending Requests</h3>
                            <p class="pr-empty-desc">
                                <%= (!search.isEmpty() || !serviceIssueFilter.isEmpty()) 
                                    ? "No pending requests matched your search criteria. Try clearing filters." 
                                    : "You don't have any service requests waiting for your response." %>
                            </p>
                            <% if (!search.isEmpty() || !serviceIssueFilter.isEmpty()) { %>
                                <a href="pending-requests.jsp" class="btn-pr-search" style="text-decoration:none; display:inline-flex; padding:8px 18px;">
                                    <i class="fa-solid fa-arrow-rotate-left"></i>
                                    <span>Reset Filters</span>
                                </a>
                            <% } %>
                        </div>
                    <% } else { %>
                        <table class="pr-data-table" id="pendingRequestsTable">
                            <thead>
                                <tr>
                                    <th style="width: 28px; text-align: center;">S.No</th>
                                    <th style="width: 85px;">Request ID</th>
                                    <th style="width: 155px;">Vehicle</th>
                                    <th style="width: 120px;">Service Issue</th>
                                    <th style="width: 145px;">Location</th>
                                    <th style="width: 140px;">Requested On</th>
                                    <th style="width: 80px;">Status</th>
                                    <th style="width: 200px; text-align: center;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    for (int i = 0; i < displayList.size(); i++) {
                                        Map req = (Map) displayList.get(i);
                                        int rowSerial = startIndex + i + 1;
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

                                        String uName = (String) req.get("user_name");
                                        if (uName == null || uName.trim().isEmpty()) uName = "Vehicle Owner";
                                        String uPhone = (String) req.get("user_phone");
                                        if (uPhone == null || uPhone.trim().isEmpty()) uPhone = "+91 98758 23975";
                                        String fullLoc = (String) req.get("location");
                                        if (fullLoc == null || fullLoc.trim().isEmpty()) fullLoc = locName;
                                        String fullDate = (String) req.get("requested_date");
                                        if (fullDate == null || fullDate.trim().isEmpty()) fullDate = dPart + (!tPart.isEmpty() ? " • " + tPart : "");
                                        String rawNotes = (String) req.get("notes");
                                        if (rawNotes == null || rawNotes.trim().isEmpty()) rawNotes = "Customer requested roadside assistance for " + issue + ".";
                                        String safeNotes = rawNotes.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "&quot;").replace("\n", " ").replace("\r", " ");

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
                                <tr id="row-<%= rCode %>">
                                    <!-- 1. Serial Number -->
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
                                        <span class="status-pill-pending">
                                            <i class="fa-regular fa-clock"></i>
                                            <span><%= st %></span>
                                        </span>
                                    </td>

                                    <!-- 8. Actions: View, Accept & Reject -->
                                    <td style="text-align: center;">
                                        <div class="pr-actions-group">
                                            <!-- View Details Button -->
                                            <button type="button" 
                                                    class="btn-pr-action btn-pr-view" 
                                                    id="btn-view-<%= rCode %>"
                                                    onclick="openReqDetailModal('<%= rCode %>', '<%= uName.replace("'", "\\'") %>', '<%= uPhone.replace("'", "\\'") %>', '<%= vNum %>', '<%= vModel.replace("'", "\\'") %>', '<%= issue.replace("'", "\\'") %>', '<%= fullLoc.replace("'", "\\'") %>', '<%= st %>', '<%= fullDate.replace("'", "\\'") %>', '<%= safeNotes %>')"
                                                    title="View Problem Details">
                                                <i class="fa-regular fa-eye"></i>
                                                <span>View</span>
                                            </button>

                                            <!-- Accept Button (Green Outline) -->
                                            <button type="button" 
                                                    class="btn-pr-action btn-pr-accept" 
                                                    id="btn-accept-<%= rCode %>"
                                                    onclick="executeRequestAction('accept', '<%= rCode %>')"
                                                    title="Accept this service request">
                                                <i class="fa-solid fa-check"></i>
                                                <span>Accept</span>
                                            </button>

                                          
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } %>
                </div>

                <!-- Footer with Record Counter and Pagination Controls -->
                <div class="pr-footer-row">
                    <div class="pr-record-count-text" id="footerRecordCount">
                        <% if (pendingFilteredCount > 0) { %>
                            Showing <%= startIndex + 1 %> to <%= endIndex %> of <%= pendingFilteredCount %> requests
                        <% } else { %>
                            Showing 0 of 0 requests
                        <% } %>
                    </div>

                    <% if (totalPages > 1) { %>
                    <div class="pr-pagination-controls">
                        <!-- Previous Page Button -->
                        <% if (currentPage > 1) { %>
                            <a href="pending-requests.jsp?page=<%= currentPage - 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                               class="btn-pr-page" aria-label="Previous Page">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="btn-pr-page disabled" disabled>
                                <i class="fa-solid fa-chevron-left"></i>
                            </button>
                        <% } %>

                        <!-- Page Numbers -->
                        <% for (int p = 1; p <= totalPages; p++) { %>
                            <% if (p == currentPage) { %>
                                <button type="button" class="btn-pr-page active"><%= p %></button>
                            <% } else { %>
                                <a href="pending-requests.jsp?page=<%= p %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                                   class="btn-pr-page"><%= p %></a>
                            <% } %>
                        <% } %>

                        <!-- Next Page Button -->
                        <% if (currentPage < totalPages) { %>
                            <a href="pending-requests.jsp?page=<%= currentPage + 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                               class="btn-pr-page" aria-label="Next Page">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="btn-pr-page disabled" disabled>
                                <i class="fa-solid fa-chevron-right"></i>
                            </button>
                        <% } %>
                    </div>
                    <% } %>
                </div>

            </div>

        </main>
    </div>

    <!-- Universal Rich Service Request Details Modal -->
    <jsp:include page="/common/service-request-view-modal.jsp" />

    <!-- Client-Side JavaScript: Double-click Prevention, AJAX Actions, Dynamic Count Update, View Modal -->
    <script>
        let activeModalCode = null;

        function openReqDetailModal(code, user, phone, vnum, vmodel, issue, loc, status, date, notes) {
            activeModalCode = code;
            window.openServiceRequestModal({
                code: code,
                userName: user,
                userPhone: phone,
                vehicleNumber: vnum,
                brandModel: vmodel,
                issue: issue,
                location: loc,
                status: status || 'Pending',
                reqDate: date,
                description: notes
            });
        }

        function closeReqDetailModal() {
            window.closeServiceRequestModal();
            activeModalCode = null;
        }

        function handleDetailOverlayClick(event) {
            window.closeServiceRequestModal();
        }

        function acceptFromModal() {
            if (activeModalCode) {
                const code = activeModalCode;
                closeReqDetailModal();
                executeRequestAction('accept', code);
            }
        }

        function rejectFromModal() {
            if (activeModalCode) {
                const code = activeModalCode;
                closeReqDetailModal();
                executeRequestAction('reject', code);
            }
        }

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeReqDetailModal();
            }
        });
        function executeRequestAction(actionType, reqCode) {
            const btnAccept = document.getElementById('btn-accept-' + reqCode);
            const btnReject = document.getElementById('btn-reject-' + reqCode);
            const rowElem = document.getElementById('row-' + reqCode);

            if (actionType === 'reject') {
                if (!confirm('Are you sure you want to reject service request ' + reqCode + '?')) {
                    return;
                }
            }

            // Disable buttons to prevent duplicate submission
            if (btnAccept) btnAccept.disabled = true;
            if (btnReject) btnReject.disabled = true;

            const activeBtn = actionType === 'accept' ? btnAccept : btnReject;
            const originalHtml = activeBtn ? activeBtn.innerHTML : '';
            if (activeBtn) {
                activeBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>' + (actionType === 'accept' ? 'Accepting...' : 'Rejecting...') + '</span>';
            }

            // Submit via AJAX
            fetch('pending-requests.jsp?action=' + encodeURIComponent(actionType) + '&reqId=' + encodeURIComponent(reqCode) + '&ajax=true', {
                method: 'POST',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Smoothly animate and remove row
                    if (rowElem) {
                        rowElem.style.transition = 'all 0.3s ease';
                        rowElem.style.opacity = '0';
                        rowElem.style.transform = 'translateX(20px)';
                        setTimeout(() => {
                            rowElem.remove();
                            updateDynamicCounters(actionType);
                            renumberSerialNumbers();
                        }, 300);
                    }

                    // Display notification banner
                    showToastNotification(
                        actionType === 'accept' 
                            ? 'Request <strong>' + reqCode + '</strong> successfully accepted! Moved to Accepted Requests.'
                            : 'Request <strong>' + reqCode + '</strong> was rejected.',
                        actionType === 'accept' ? 'success' : 'rejected'
                    );
                } else {
                    alert('Failed to update request ' + reqCode + '. Please try again.');
                    if (btnAccept) btnAccept.disabled = false;
                    if (btnReject) btnReject.disabled = false;
                    if (activeBtn) activeBtn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.warn('AJAX request failed, falling back to page reload:', error);
                window.location.href = 'pending-requests.jsp?action=' + encodeURIComponent(actionType) + '&reqId=' + encodeURIComponent(reqCode);
            });
        }

        function updateDynamicCounters(actionType) {
            // Pending Requests Card
            const statPending = document.getElementById('statPendingRequests');
            if (statPending) {
                let cur = parseInt(statPending.textContent.trim()) || 0;
                if (cur > 0) statPending.textContent = (cur - 1);
            }

            // Accepted Requests Card
            if (actionType === 'accept') {
                const statAccepted = document.getElementById('statAcceptedRequests');
                if (statAccepted) {
                    let cur = parseInt(statAccepted.textContent.trim()) || 0;
                    statAccepted.textContent = (cur + 1);
                }
            }

            // Section Header Badge
            const badgeCount = document.getElementById('badgePendingCount');
            const tbody = document.querySelector('#pendingRequestsTable tbody');
            const remaining = tbody ? tbody.querySelectorAll('tr').length : 0;

            if (badgeCount) {
                badgeCount.innerHTML = '<span>' + remaining + ' Pending Requests</span>';
            }

            // Footer count
            const footerCount = document.getElementById('footerRecordCount');
            if (footerCount) {
                footerCount.textContent = 'Showing 1 to ' + remaining + ' of ' + remaining + ' requests';
            }

            // If empty, show empty state
            if (remaining === 0 && tbody) {
                const tableContainer = document.querySelector('.pr-table-container');
                if (tableContainer) {
                    tableContainer.innerHTML = `
                        <div class="pr-empty-state">
                            <div class="pr-empty-icon">
                                <i class="fa-solid fa-clipboard-check"></i>
                            </div>
                            <h3 class="pr-empty-title">No Pending Requests</h3>
                            <p class="pr-empty-desc">You don't have any service requests waiting for your response.</p>
                            <a href="dashboard.jsp" class="btn-pr-search" style="text-decoration:none; display:inline-flex; padding:8px 18px;">
                                <i class="fa-solid fa-house"></i>
                                <span>Go to Dashboard</span>
                            </a>
                        </div>
                    `;
                }
            }
        }

        function renumberSerialNumbers() {
            const rows = document.querySelectorAll('#pendingRequestsTable tbody tr');
            rows.forEach((row, idx) => {
                const numCell = row.querySelector('.td-row-num');
                if (numCell) numCell.textContent = (idx + 1);
            });
        }

        function showToastNotification(message, type) {
            const container = document.getElementById('dynamicAlertContainer');
            if (!container) return;

            const banner = document.createElement('div');
            banner.className = 'pr-alert-banner ' + (type === 'success' ? 'pr-alert-success' : 'pr-alert-rejected');
            banner.innerHTML = `
                <span><i class="fa-solid ` + (type === 'success' ? 'fa-circle-check' : 'fa-circle-xmark') + `"></i> ` + message + `</span>
                <button type="button" class="pr-alert-close" onclick="this.parentElement.remove()">&times;</button>
            `;
            container.appendChild(banner);

            setTimeout(() => {
                if (banner.parentElement) {
                    banner.style.transition = 'opacity 0.4s ease';
                    banner.style.opacity = '0';
                    setTimeout(() => banner.remove(), 400);
                }
            }, 6000);
        }
    </script>
</body>
</html>
