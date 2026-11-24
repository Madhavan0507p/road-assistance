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

    request.setAttribute("activeMechPage", "requests");

    String mechCode = currentMech.getMechanicCode();
    if (mechCode == null || mechCode.trim().isEmpty()) mechCode = "MEC003";

    String workshopName = currentMech.getWorkshopName();
    if (workshopName == null || workshopName.trim().isEmpty()) {
        workshopName = currentMech.getShopName();
    }
    if (workshopName == null || workshopName.trim().isEmpty()) workshopName = "SpeedFix Auto Works";

    String ownerName = currentMech.getOwnerName();
    if (ownerName == null || ownerName.trim().isEmpty()) {
        ownerName = currentMech.getFirstName();
    }
    if (ownerName == null || ownerName.trim().isEmpty()) ownerName = "Murugan";

    // Handle Accept & Reject Request Action
    String action = request.getParameter("action");
    String reqIdParam = request.getParameter("reqId");
    String msg = request.getParameter("msg");

    if (("accept".equalsIgnoreCase(action) || "reject".equalsIgnoreCase(action)) && reqIdParam != null && !reqIdParam.trim().isEmpty()) {
        Connection actConn = null;
        PreparedStatement actPs = null;
        try {
            actConn = DBConnection.getConnection();
            if (actConn != null) {
                String actSql;
                if ("accept".equalsIgnoreCase(action)) {
                    actSql = "UPDATE service_requests SET status = 'Accepted', mechanic_code = ?, mechanic_name = ?, assigned_at = CURRENT_TIMESTAMP(), assigned_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p') WHERE (request_id = ? OR request_code = ?) AND status = 'Pending'";
                    actPs = actConn.prepareStatement(actSql);
                    actPs.setString(1, mechCode);
                    actPs.setString(2, workshopName);
                    int rInt = 0;
                    try { rInt = Integer.parseInt(reqIdParam.trim()); } catch (Exception ignored) {}
                    actPs.setInt(3, rInt);
                    actPs.setString(4, reqIdParam.trim());
                } else {
                    actSql = "UPDATE service_requests SET status = 'Rejected' WHERE (request_id = ? OR request_code = ?) AND status = 'Pending'";
                    actPs = actConn.prepareStatement(actSql);
                    int rInt = 0;
                    try { rInt = Integer.parseInt(reqIdParam.trim()); } catch (Exception ignored) {}
                    actPs.setInt(1, rInt);
                    actPs.setString(2, reqIdParam.trim());
                }
                int actRows = actPs.executeUpdate();
                if (actRows > 0) {
                    String st = "accept".equalsIgnoreCase(action) ? "Accepted" : "Rejected";
                    EmailUtil.notifyUserOfRequestStatusUpdateAsync(reqIdParam, st, null);
                }
            }
        } catch (Exception ex) {
            System.err.println("Request action error: " + ex.getMessage());
        } finally {
            if (actPs != null) try { actPs.close(); } catch (Exception ignored) {}
            if (actConn != null) try { actConn.close(); } catch (Exception ignored) {}
        }
        String redirectMsg = "accept".equalsIgnoreCase(action) ? "accepted" : "rejected";
        response.sendRedirect("service-requests.jsp?msg=" + redirectMsg + "&reqId=" + java.net.URLEncoder.encode(reqIdParam, "UTF-8"));
        return;
    }

    SimpleDateFormat sdfDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDate.format(new Date());

    // 2. Read Search, Filter & Pagination Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String statusFilter = request.getParameter("status");
    if (statusFilter != null) statusFilter = statusFilter.trim(); else statusFilter = "";

    String issueFilter = request.getParameter("issue");
    if (issueFilter != null) issueFilter = issueFilter.trim(); else issueFilter = "";

    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try {
            currentPage = Integer.parseInt(pageParam.trim());
            if (currentPage < 1) currentPage = 1;
        } catch (Exception ignored) {}
    }
    int pageSize = 10; // Exactly 10 rows per page

    // 3. Query Database for Service Requests & Statistics (Active In-Service Requests Only: 'On The Way' & 'In Progress')
    List<Map<String, String>> allRequests = new ArrayList<Map<String, String>>();
    int statTotal = 0;
    int statOnTheWay = 0;
    int statInProgress = 0;
    int statAccepted = 0;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {
            // A. Statistics Query for In-Service Requests (Strictly Excludes Pending and Completed)
            try {
                String statsSql = "SELECT " +
                    "SUM(CASE WHEN sr.status IN ('On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS active_cnt, " +
                    "SUM(CASE WHEN sr.status = 'On The Way' THEN 1 ELSE 0 END) AS ontheway_cnt, " +
                    "SUM(CASE WHEN sr.status IN ('In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS inprogress_cnt, " +
                    "SUM(CASE WHEN sr.status = 'Accepted' THEN 1 ELSE 0 END) AS accepted_cnt " +
                    "FROM service_requests sr " +
                    "WHERE (sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) " +
                    "  AND sr.status IN ('On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement', 'Accepted')";
                ps = conn.prepareStatement(statsSql);
                ps.setString(1, mechCode);
                ps.setString(2, workshopName);
                ps.setString(3, "%" + workshopName + "%");
                rs = ps.executeQuery();
                if (rs.next()) {
                    statTotal = rs.getInt("active_cnt");
                    statOnTheWay = rs.getInt("ontheway_cnt");
                    statInProgress = rs.getInt("inprogress_cnt");
                    statAccepted = rs.getInt("accepted_cnt");
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Stats query warning: " + ex.getMessage());
            }

            // B. Filtered In-Service Requests Query (Strictly Excludes Pending and Completed)
            StringBuilder q = new StringBuilder();
            q.append("SELECT sr.request_id, sr.request_code, sr.user_name, ");
            q.append("(SELECT u.phone FROM users u WHERE u.user_id = sr.user_id OR u.full_name = sr.user_name LIMIT 1) AS user_phone, ");
            q.append("sr.vehicle_number, ");
            q.append("COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, ");
            q.append("COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, ");
            q.append("COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, ");
            q.append("COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, ");
            q.append("sr.breakdown_issue, sr.location, sr.service_cost, sr.status, sr.requested_date, sr.requested_at, sr.additional_details ");
            q.append("FROM service_requests sr ");
            q.append("LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') ");
            q.append("WHERE (sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) ");

            List<Object> qParams = new ArrayList<Object>();
            qParams.add(mechCode);
            qParams.add(workshopName);
            qParams.add("%" + workshopName + "%");

            if (!search.isEmpty()) {
                q.append("AND (sr.request_code LIKE ? OR sr.user_name LIKE ? OR sr.vehicle_number LIKE ? OR sr.location LIKE ? OR sr.breakdown_issue LIKE ?) ");
                String pattern = "%" + search + "%";
                qParams.add(pattern);
                qParams.add(pattern);
                qParams.add(pattern);
                qParams.add(pattern);
                qParams.add(pattern);
            }
            if (!statusFilter.isEmpty() && !"All".equalsIgnoreCase(statusFilter) && !"All Requests".equalsIgnoreCase(statusFilter) && !"All In-Service".equalsIgnoreCase(statusFilter)) {
                if ("In Progress".equalsIgnoreCase(statusFilter)) {
                    q.append("AND sr.status IN ('In Progress', 'Diagnostics Done', 'Parts Replacement') ");
                } else if ("On The Way".equalsIgnoreCase(statusFilter)) {
                    q.append("AND sr.status IN ('On The Way') ");
                } else if ("Accepted".equalsIgnoreCase(statusFilter)) {
                    q.append("AND sr.status = 'Accepted' ");
                } else {
                    q.append("AND sr.status = ? ");
                    qParams.add(statusFilter);
                }
            } else {
                // Default: STRICTLY ONLY show In Progress and On The Way requests (EXCEPT Pending and Completed)
                q.append("AND sr.status IN ('On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement') ");
            }
            if (!issueFilter.isEmpty() && !"All".equalsIgnoreCase(issueFilter)) {
                q.append("AND sr.breakdown_issue LIKE ? ");
                qParams.add("%" + issueFilter + "%");
            }
            q.append("ORDER BY sr.request_id DESC");

            ps = conn.prepareStatement(q.toString());
            for (int i = 0; i < qParams.size(); i++) {
                ps.setObject(i + 1, qParams.get(i));
            }
            rs = ps.executeQuery();

            SimpleDateFormat sdfDateOnly = new SimpleDateFormat("dd-MM-yyyy");
            SimpleDateFormat sdfTimeOnly = new SimpleDateFormat("hh:mm a");

            while (rs.next()) {
                Map<String, String> row = new HashMap<String, String>();
                int rId = rs.getInt("request_id");
                String code = rs.getString("request_code");
                if (code == null || code.trim().isEmpty()) code = "SR" + (1000 + rId);

                row.put("id", String.valueOf(rId));
                row.put("code", code);

                String uName = rs.getString("user_name");
                row.put("user", (uName != null && !uName.trim().isEmpty()) ? uName : "Motorist");

                String uPhone = rs.getString("user_phone");
                row.put("phone", (uPhone != null && !uPhone.trim().isEmpty()) ? uPhone : "+91 98765 43210");

                String vNum = rs.getString("vehicle_number");
                row.put("vnum", (vNum != null && !vNum.trim().isEmpty()) ? vNum : "TN 10 AB 1234");

                String vModel = rs.getString("vehicle_model");
                if (vModel == null || vModel.trim().isEmpty() || "Vehicle".equalsIgnoreCase(vModel.trim())) {
                    String vBrand = rs.getString("vehicle_brand");
                    vModel = (vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle";
                }
                row.put("vmodel", vModel);

                String issue = rs.getString("breakdown_issue");
                row.put("issue", (issue != null && !issue.trim().isEmpty()) ? issue : "General Repair");

                String loc = rs.getString("location");
                row.put("loc", (loc != null && !loc.trim().isEmpty()) ? loc : "Location unavailable");

                String st = rs.getString("status");
                row.put("status", (st != null && !st.trim().isEmpty()) ? st : "Pending");

                // Formatted requested date & time
                String rDateStr = rs.getString("requested_date");
                String dDate = "13-11-2026";
                String dTime = "11:00 AM";
                if (rs.getTimestamp("requested_at") != null) {
                    Date ts = new Date(rs.getTimestamp("requested_at").getTime());
                    dDate = sdfDateOnly.format(ts);
                    dTime = sdfTimeOnly.format(ts);
                } else if (rDateStr != null && (rDateStr.contains("•") || rDateStr.contains("·") || rDateStr.contains(" - "))) {
                    String delim = rDateStr.contains("•") ? "•" : (rDateStr.contains("·") ? "·" : " - ");
                    String[] parts = rDateStr.split(delim);
                    dDate = parts[0].trim();
                    if (parts.length > 1) dTime = parts[1].trim();
                } else if (rDateStr != null) {
                    dDate = rDateStr;
                }

                if (dDate != null && !dDate.trim().isEmpty() && !dDate.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                    try {
                        Date parsed = null;
                        try { parsed = new SimpleDateFormat("MMM d, yyyy").parse(dDate); } catch(Exception ign1){}
                        if (parsed == null) {
                            try { parsed = new SimpleDateFormat("yyyy-MM-dd").parse(dDate); } catch(Exception ign2){}
                        }
                        if (parsed != null) dDate = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                    } catch(Exception ign){}
                }
                row.put("date", dDate);
                row.put("time", dTime);

                String notes = rs.getString("additional_details");
                row.put("notes", (notes != null && !notes.trim().isEmpty()) ? notes : "No additional problem description provided.");

                allRequests.add(row);
            }
        }
    } catch (Exception e) {
        System.err.println("Database error in mechanic service requests: " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    // 4. Calculate Pagination (Strictly 10 data per page)
    int totalCount = allRequests.size();
    if (statTotal == 0 && totalCount > 0) statTotal = totalCount;
    int totalPages = (totalCount + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalCount);
    List<Map<String, String>> pageRequests = (totalCount > 0) ? allRequests.subList(startIndex, endIndex) : new ArrayList<Map<String, String>>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service Requests — Mechanic Portal</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Mechanic Shell & Base Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">

    <!-- Dedicated Service Requests Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-service-requests.css?v=2.6">
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
            <div class="sr-header-row">
                <div class="sr-title-group">
                    <div class="sr-title-icon-box">
                        <i class="fa-solid fa-wrench"></i>
                    </div>
                    <div class="sr-title-text">
                        <h1>Service <span class="accent-orange">Requests</span></h1>
                        <p>Track, manage, and monitor all service requests assigned to your workshop.</p>
                    </div>
                </div>

                <div class="sr-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <% if ("accepted".equalsIgnoreCase(msg)) { %>
                <div style="background-color: #ECFDF5; border: 1px solid #A7F3D0; color: #065F46; padding: 12px 18px; border-radius: 10px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; font-weight: 600; font-size: 14px;">
                    <i class="fa-solid fa-circle-check" style="color: #10B981; font-size: 18px;"></i>
                    <span>Service Request #<%= reqIdParam != null ? reqIdParam : "" %> accepted successfully! Dispatched to your workshop.</span>
                </div>
            <% } else if ("rejected".equalsIgnoreCase(msg)) { %>
                <div style="background-color: #FEF2F2; border: 1px solid #FECACA; color: #991B1B; padding: 12px 18px; border-radius: 10px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; font-weight: 600; font-size: 14px;">
                    <i class="fa-solid fa-circle-xmark" style="color: #DC2626; font-size: 18px;"></i>
                    <span>Service Request #<%= reqIdParam != null ? reqIdParam : "" %> has been rejected.</span>
                </div>
            <% } %>

            <!-- Four Summary Metric Cards (In-Service Dispatches Only: 'On The Way' & 'In Progress') -->
            <div class="sr-stats-grid">
                <!-- Card 1: Total Active In-Service Requests -->
                <div class="sr-stat-card sr-card-total">
                    <div class="sr-stat-icon-box">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">Active In-Service</span>
                        <span class="sr-stat-number"><%= statTotal %></span>
                    </div>
                </div>

                <!-- Card 2: On The Way -->
                <div class="sr-stat-card sr-card-accepted" style="background-color: #FEF3C7; border: 1px solid #FDE68A;">
                    <div class="sr-stat-icon-box" style="background: rgba(245, 158, 11, 0.18); color: #D97706;">
                        <i class="fa-solid fa-motorcycle"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">On The Way</span>
                        <span class="sr-stat-number"><%= statOnTheWay %></span>
                    </div>
                </div>

                <!-- Card 3: In Progress -->
                <div class="sr-stat-card sr-card-inprogress" style="background-color: #FFF7ED; border: 1px solid #FFEDD5;">
                    <div class="sr-stat-icon-box" style="background: rgba(249, 115, 22, 0.18); color: #EA580C;">
                        <i class="fa-solid fa-wrench"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">In Progress</span>
                        <span class="sr-stat-number"><%= statInProgress %></span>
                    </div>
                </div>

                <!-- Card 4: Assigned / Dispatched -->
                <div class="sr-stat-card sr-card-accepted">
                    <div class="sr-stat-icon-box">
                        <i class="fa-solid fa-clipboard-check"></i>
                    </div>
                    <div class="sr-stat-info">
                        <span class="sr-stat-label">Accepted Units</span>
                        <span class="sr-stat-number"><%= statAccepted %></span>
                    </div>
                </div>
            </div>

            <!-- Status Filter Tabs (Only In-Service Stages; Pending is in Pending Requests, Completed is in Service History) -->
            <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; margin-bottom: 18px;">
                <div class="sr-filter-tabs" style="margin-bottom: 0;">
                    <a href="service-requests.jsp<%= !search.isEmpty() ? "?search=" + java.net.URLEncoder.encode(search, "UTF-8") : "" %>" 
                       class="sr-filter-tab <%= statusFilter.isEmpty() || "All".equalsIgnoreCase(statusFilter) || "All In-Service".equalsIgnoreCase(statusFilter) ? "active" : "" %>">
                        <span>All In-Service</span>
                        <span class="sr-tab-badge"><%= statTotal %></span>
                    </a>
                    <a href="service-requests.jsp?status=On The Way<%= !search.isEmpty() ? "&search=" + java.net.URLEncoder.encode(search, "UTF-8") : "" %>" 
                       class="sr-filter-tab <%= "On The Way".equalsIgnoreCase(statusFilter) ? "active" : "" %>">
                        <span>On The Way</span>
                        <span class="sr-tab-badge"><%= statOnTheWay %></span>
                    </a>
                    <a href="service-requests.jsp?status=In Progress<%= !search.isEmpty() ? "&search=" + java.net.URLEncoder.encode(search, "UTF-8") : "" %>" 
                       class="sr-filter-tab <%= "In Progress".equalsIgnoreCase(statusFilter) ? "active" : "" %>">
                        <span>In Progress</span>
                        <span class="sr-tab-badge"><%= statInProgress %></span>
                    </a>
                </div>

                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                    <a href="${pageContext.request.contextPath}/mechanic/pending-requests.jsp" class="btn-history-nav" style="display: inline-flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 10px; background: #FEF3C7; border: 1.5px solid #FDE68A; color: #D97706; font-weight: 700; font-size: 13px; text-decoration: none; transition: all 0.2s;" title="View all pending requests awaiting acceptance">
                        <i class="fa-solid fa-clock"></i>
                        <span>Pending Requests &rarr;</span>
                    </a>
                    <a href="${pageContext.request.contextPath}/mechanic/service-history.jsp" class="btn-history-nav" style="display: inline-flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 10px; background: #FFF7ED; border: 1.5px solid #FFEDD5; color: #EA580C; font-weight: 700; font-size: 13px; text-decoration: none; transition: all 0.2s;" title="View all finalized service records">
                        <i class="fa-solid fa-clock-rotate-left"></i>
                        <span>Service History &rarr;</span>
                    </a>
                </div>
            </div>

            <!-- Search and Filter Toolbar -->
            <form action="service-requests.jsp" method="GET" class="sr-toolbar-form">
                <% if (!statusFilter.isEmpty()) { %>
                    <input type="hidden" name="status" value="<%= statusFilter %>">
                <% } %>

                <!-- 1. Search Box -->
                <div class="sr-search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" 
                           name="search" 
                           class="sr-search-input" 
                           placeholder="Search by ticket code, motorist, vehicle number, or location..." 
                           value="<%= search %>">
                </div>

                <!-- 2. Service Issue Dropdown -->
                <div class="sr-select-box">
                    <select name="issue" class="sr-select-control">
                        <option value="" <%= issueFilter.isEmpty() ? "selected" : "" %>>All Breakdown Issues</option>
                        <option value="Engine" <%= "Engine".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Engine Issue</option>
                        <option value="Battery" <%= "Battery".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Battery Jumpstart</option>
                        <option value="Tyre" <%= "Tyre".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Tyre / Puncture</option>
                        <option value="Brake" <%= "Brake".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Brake Failure</option>
                        <option value="Coolant" <%= "Coolant".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Coolant Leak</option>
                        <option value="Clutch" <%= "Clutch".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Clutch / Transmission</option>
                        <option value="Electrical" <%= "Electrical".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Electrical Repair</option>
                        <option value="AC" <%= "AC".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>AC Service</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- Submit Button -->
                <button type="submit" class="btn-sr-search">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <span>Search</span>
                </button>

                <!-- Reset Button -->
                <% if (!search.isEmpty() || !statusFilter.isEmpty() || !issueFilter.isEmpty()) { %>
                    <a href="service-requests.jsp" class="btn-sr-reset" title="Clear all filters">
                        <i class="fa-solid fa-rotate-left"></i>
                        <span>Reset</span>
                    </a>
                <% } %>
            </form>

            <!-- Main Table Card -->
            <div class="sr-main-card">
                <div class="sr-card-header">
                    <div class="sr-card-title-group">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                        <h2>Active In-Service Requests</h2>
                    </div>
                    <span style="font-size: 13px; font-weight: 600; color: #64748B;">
                        Showing page <%= currentPage %> of <%= totalPages %> (<%= totalCount %> active requests)
                    </span>
                </div>

                <!-- Responsive Table -->
                <div class="sr-table-container">
                    <table class="sr-data-table">
                        <thead>
                            <tr>
                                <th>TICKET</th>
                                <th>MOTORIST</th>
                                <th>VEHICLE</th>
                                <th>ISSUE</th>
                                <th>LOCATION</th>
                                <th>STATUS</th>
                                <th>REQUESTED DATE</th>
                                <th style="text-align: right; min-width: 170px;">ACTION</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (pageRequests.isEmpty()) { %>
                            <tr>
                                <td colspan="8" style="text-align: center; padding: 48px 20px;">
                                    <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px;">
                                        <div style="width: 52px; height: 52px; border-radius: 50%; background: #FFF7ED; display: flex; align-items: center; justify-content: center; color: #F97316; font-size: 22px;">
                                            <i class="fa-solid fa-screwdriver-wrench"></i>
                                        </div>
                                        <h3 style="margin: 0; font-size: 16px; color: #1E293B; font-weight: 700;">No Active In-Service Requests</h3>
                                        <p style="margin: 0; font-size: 13px; color: #64748B;">
                                            Requests in 'On The Way' or 'In Progress' stages will appear here.<br>
                                            Check <a href="pending-requests.jsp" style="color: #F97316; font-weight: 600;">Pending Requests</a> for incoming dispatches or <a href="service-history.jsp" style="color: #F97316; font-weight: 600;">Service History</a> for completed services.
                                        </p>
                                    </div>
                                </td>
                            </tr>
                            <% } else { %>
                                <% for (Map<String, String> r : pageRequests) { 
                                    String st = r.get("status");
                                    String statusBadgeClass = "badge-status-inprogress";
                                    String statusIcon = "fa-wrench";
                                    if ("On The Way".equalsIgnoreCase(st)) {
                                        statusBadgeClass = "badge-status-accepted";
                                        statusIcon = "fa-motorcycle";
                                    } else if ("Accepted".equalsIgnoreCase(st)) {
                                        statusBadgeClass = "badge-status-accepted";
                                        statusIcon = "fa-circle-check";
                                    }
                                %>
                                <tr>
                                    <!-- Ticket Code -->
                                    <td>
                                        <span class="sr-ticket-badge"><%= r.get("code") %></span>
                                    </td>

                                    <!-- Motorist Info -->
                                    <td>
                                        <div class="sr-user-cell">
                                            <div class="sr-user-avatar">
                                                <i class="fa-solid fa-user"></i>
                                            </div>
                                            <div>
                                                <span class="sr-user-name"><%= r.get("user") %></span>
                                                <span class="sr-user-phone"><%= r.get("phone") %></span>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- Vehicle -->
                                    <td>
                                        <span class="sr-vehicle-number"><%= r.get("vnum") %></span>
                                        <span class="sr-vehicle-model"><%= r.get("vmodel") %></span>
                                    </td>

                                    <!-- Issue -->
                                    <td>
                                        <span style="font-weight: 600; color: #1E293B;"><%= r.get("issue") %></span>
                                    </td>

                                    <!-- Location -->
                                    <td>
                                        <div style="display: flex; align-items: center; gap: 6px;">
                                            <i class="fa-solid fa-location-dot" style="color: #F97316; font-size: 12px;"></i>
                                            <span><%= r.get("loc") %></span>
                                        </div>
                                    </td>

                                    <!-- Status Badge -->
                                    <td>
                                        <span class="badge-status <%= statusBadgeClass %>">
                                            <i class="fa-solid <%= statusIcon %>"></i>
                                            <%= st %>
                                        </span>
                                    </td>

                                    <!-- Date & Time -->
                                    <td>
                                        <div style="font-size: 12.5px;">
                                            <span style="color: #1E293B; font-weight: 600; display: block;"><%= r.get("date") %></span>
                                            <span style="color: #64748B; font-size: 11.5px;"><%= r.get("time") %></span>
                                        </div>
                                    </td>

                                    <!-- Actions -->
                                    <td style="text-align: right;">
                                        <div class="sr-actions-cell" style="justify-content: flex-end;">
                                            <button type="button" 
                                                    class="btn-table-action btn-action-view" 
                                                    onclick="openReqDetailModal('<%= r.get("code") %>', '<%= r.get("user") %>', '<%= r.get("phone") %>', '<%= r.get("vnum") %>', '<%= r.get("vmodel") %>', '<%= r.get("issue") %>', '<%= r.get("loc") %>', '<%= r.get("status") %>', '<%= r.get("date") %> • <%= r.get("time") %>', '<%= r.get("notes").replace("\\", "\\\\").replace("'", "\\'").replace("\"", "&quot;").replace("\n", " ").replace("\r", " ") %>', '<%= r.get("id") %>')" 
                                                    title="View Full Details">
                                                <i class="fa-regular fa-eye"></i>
                                                <span>View</span>
                                            </button>
                                            
                                            <a href="${pageContext.request.contextPath}/mechanic/accepted-requests.jsp" 
                                               class="btn-table-action" 
                                               style="background-color: #FFF7ED; color: #EA580C; border: 1px solid #FDBA74; padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 700; text-decoration: none; display: inline-flex; align-items: center; gap: 5px;" 
                                               title="Advance Status in Pipeline">
                                                <i class="fa-solid fa-timeline"></i>
                                                <span>Pipeline</span>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <!-- Footer with Record Counter and 10-per-page Pagination Controls -->
                <div class="sr-pagination-container">
                    <div class="sr-pagination-info">
                        Showing <%= totalCount > 0 ? (startIndex + 1) : 0 %> to <%= endIndex %> of <%= totalCount %> requests
                    </div>

                    <% if (totalPages > 1) { 
                        String queryPrefix = "service-requests.jsp?";
                        if (!search.isEmpty()) queryPrefix += "search=" + java.net.URLEncoder.encode(search, "UTF-8") + "&";
                        if (!statusFilter.isEmpty()) queryPrefix += "status=" + java.net.URLEncoder.encode(statusFilter, "UTF-8") + "&";
                        if (!issueFilter.isEmpty()) queryPrefix += "issue=" + java.net.URLEncoder.encode(issueFilter, "UTF-8") + "&";
                    %>
                    <div class="sr-pagination-controls">
                        <!-- Previous Page -->
                        <% if (currentPage > 1) { %>
                            <a href="<%= queryPrefix %>page=<%= currentPage - 1 %>" class="sr-page-btn" aria-label="Previous Page">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>
                        <% } else { %>
                            <span class="sr-page-btn disabled">
                                <i class="fa-solid fa-chevron-left"></i>
                            </span>
                        <% } %>

                        <!-- Page Numbers -->
                        <% for (int p = 1; p <= totalPages; p++) { %>
                            <% if (p == currentPage) { %>
                                <span class="sr-page-btn active"><%= p %></span>
                            <% } else { %>
                                <a href="<%= queryPrefix %>page=<%= p %>" class="sr-page-btn"><%= p %></a>
                            <% } %>
                        <% } %>

                        <!-- Next Page -->
                        <% if (currentPage < totalPages) { %>
                            <a href="<%= queryPrefix %>page=<%= currentPage + 1 %>" class="sr-page-btn" aria-label="Next Page">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>
                        <% } else { %>
                            <span class="sr-page-btn disabled">
                                <i class="fa-solid fa-chevron-right"></i>
                            </span>
                        <% } %>
                    </div>
                    <% } %>
                </div>

            </div>

        </main>
    </div>

    <!-- Universal Rich Service Request Details Modal -->
    <jsp:include page="/common/service-request-view-modal.jsp" />

    <script>
        function openReqDetailModal(code, user, phone, vnum, vmodel, issue, loc, status, date, notes, id) {
            window.openServiceRequestModal({
                id: id,
                code: code,
                userName: user,
                userPhone: phone,
                vehicleNumber: vnum,
                brandModel: vmodel,
                issue: issue,
                location: loc,
                status: status,
                reqDate: date,
                description: notes
            });
        }

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
                const filterTabs = document.querySelector('.sr-filter-tabs');
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

                    // 2. Update .sr-filter-tabs
                    const newFilterTabs = doc.querySelector('.sr-filter-tabs');
                    if (filterTabs && newFilterTabs) {
                        filterTabs.innerHTML = newFilterTabs.innerHTML;
                    }

                    // 3. Update .sr-stats-grid
                    const oldStats = document.querySelector('.sr-stats-grid');
                    const newStats = doc.querySelector('.sr-stats-grid');
                    if (oldStats && newStats) {
                        oldStats.innerHTML = newStats.innerHTML;
                    }

                    // 4. Update history
                    if (pushHistory && window.history && window.history.pushState) {
                        window.history.pushState({ url: targetUrl }, '', targetUrl);
                    }

                    // 5. Re-bind events
                    bindAjaxEvents();

                    // 6. Restore search focus
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
                // 1. Status Filter Tabs
                const tabLinks = document.querySelectorAll('.sr-filter-tabs a');
                tabLinks.forEach(function(link) {
                    link.addEventListener('click', function(e) {
                        e.preventDefault();
                        const href = this.getAttribute('href');
                        if (href) loadContentViaAjax(href);
                    });
                });

                // 2. Filter Form Submit & Change
                const filterForm = document.querySelector('.sr-toolbar-form');
                if (filterForm) {
                    filterForm.addEventListener('submit', function(e) {
                        e.preventDefault();
                        const url = buildUrlFromFilterForm(filterForm);
                        loadContentViaAjax(url);
                    });

                    // Dropdown change
                    const select = filterForm.querySelector('select');
                    if (select) {
                        select.addEventListener('change', function() {
                            const url = buildUrlFromFilterForm(filterForm);
                            loadContentViaAjax(url);
                        });
                    }

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
                    const resetBtn = filterForm.querySelector('.btn-sr-reset');
                    if (resetBtn) {
                        resetBtn.addEventListener('click', function(e) {
                            e.preventDefault();
                            const href = this.getAttribute('href') || 'service-requests.jsp';
                            loadContentViaAjax(href);
                        });
                    }
                }

                // 3. Pagination Controls
                const pageLinks = document.querySelectorAll('.sr-pagination-group a, .sr-pagination-bar a');
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
