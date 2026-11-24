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

    request.setAttribute("activeMechPage", "history");

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

    // 2. Read Search, Filter & Pagination Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String issueFilter = request.getParameter("issue");
    if (issueFilter != null) issueFilter = issueFilter.trim(); else issueFilter = "";

    String statusFilter = request.getParameter("status");
    if (statusFilter != null) statusFilter = statusFilter.trim(); else statusFilter = "";

    String fromDate = request.getParameter("fromDate");
    if (fromDate != null) fromDate = fromDate.trim(); else fromDate = "";

    String toDate = request.getParameter("toDate");
    if (toDate != null) toDate = toDate.trim(); else toDate = "";

    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 rows per page

    // Dynamic Current Date Display
    SimpleDateFormat sdfDisplayDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDisplayDate.format(new Date());

    // 3. Database Queries: Statistics & Filtered History (Completed Services Only)
    int totalServices = 0;
    int completedCount = 0;
    int vehicleCount = 0;
    int customerCount = 0;
    double totalRevenue = 0.0;

    List allHistoryList = new ArrayList();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // A. Statistics Query (Completed Services Only)
            try {
                String statsSql = "SELECT " +
                        "COUNT(*) AS completed_cnt, " +
                        "COUNT(DISTINCT vehicle_number) AS vehicle_cnt, " +
                        "COUNT(DISTINCT user_name) AS customer_cnt, " +
                        "COALESCE(SUM(CAST(REPLACE(REPLACE(NULLIF(service_cost,''), '₹', ''), ',', '') AS DECIMAL(10,2))), 0) AS total_rev " +
                        "FROM service_requests " +
                        "WHERE (mechanic_code = ? OR mechanic_name = ? OR mechanic_name LIKE ?) " +
                        "  AND status = 'Completed'";
                ps = conn.prepareStatement(statsSql);
                ps.setString(1, mechCode);
                ps.setString(2, workshopName);
                ps.setString(3, "%" + workshopName + "%");
                rs = ps.executeQuery();
                if (rs.next()) {
                    completedCount = rs.getInt("completed_cnt");
                    totalServices = completedCount;
                    vehicleCount = rs.getInt("vehicle_cnt");
                    customerCount = rs.getInt("customer_cnt");
                    totalRevenue = rs.getDouble("total_rev");
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }

            // B. Filtered Service History Records Query (Completed Services Only)
            StringBuilder querySql = new StringBuilder(
                "SELECT sr.request_id, sr.request_code, sr.user_id, sr.user_name, sr.vehicle_number, sr.breakdown_issue, sr.location, sr.requested_date, sr.completed_date, sr.status, sr.additional_details, sr.service_cost, " +
                "       COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                "       COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                "       COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, " +
                "       COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, " +
                "       (SELECT u.phone FROM users u WHERE u.user_id = sr.user_id OR u.full_name = sr.user_name LIMIT 1) AS customer_phone " +
                "FROM service_requests sr " +
                "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                "WHERE (sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) " +
                "  AND sr.status = 'Completed'"
            );

            List params = new ArrayList();
            params.add(mechCode);
            params.add(workshopName);
            params.add("%" + workshopName + "%");

            if (!search.isEmpty()) {
                querySql.append(" AND (sr.request_code LIKE ? OR sr.vehicle_number LIKE ? OR sr.breakdown_issue LIKE ? OR sr.location LIKE ? OR sr.user_name LIKE ?)");
                String sParam = "%" + search + "%";
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
            }

            if (!issueFilter.isEmpty()) {
                querySql.append(" AND sr.breakdown_issue LIKE ?");
                params.add("%" + issueFilter + "%");
            }

            if (!fromDate.isEmpty()) {
                querySql.append(" AND sr.requested_date >= ?");
                params.add(fromDate);
            }

            if (!toDate.isEmpty()) {
                querySql.append(" AND sr.requested_date <= ?");
                params.add(toDate + " 23:59:59");
            }

            // Order: Most recent completed services first
            querySql.append(" ORDER BY sr.request_id DESC");

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

                    String vNum = rs.getString("vehicle_number");
                    if (vNum == null || vNum.trim().isEmpty()) vNum = "TN 48 EF 8901";
                    row.put("vehicle", vNum);

                    String issue = rs.getString("breakdown_issue");
                    if (issue == null || issue.trim().isEmpty()) issue = "General Service";
                    row.put("issue", issue);

                    String loc = rs.getString("location");
                    if (loc == null || loc.trim().isEmpty()) loc = "Manapparai (5.8 km)";
                    row.put("location", loc);

                    String rDateStr = rs.getString("requested_date");
                    if (rDateStr == null || rDateStr.trim().isEmpty()) {
                        rDateStr = "13-11-2026 • 11:05 AM";
                    }
                    row.put("requested_date", rDateStr);

                    String cDateStr = rs.getString("completed_date");
                    row.put("completed_date", cDateStr);

                    String st = rs.getString("status");
                    if (st == null || st.trim().isEmpty()) st = "Completed";
                    row.put("status", st);

                    row.put("description", rs.getString("additional_details"));
                    row.put("customer_name", rs.getString("user_name") != null ? rs.getString("user_name") : "Madhavan P");
                    String userPhone = rs.getString("customer_phone");
                    if (userPhone == null || userPhone.trim().isEmpty()) {
                        userPhone = "+91 98765 43210";
                    }
                    row.put("customer_phone", userPhone);

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

                    // Determine Service Issue Icon matching reference
                    String issueIcon = "fa-solid fa-gear";
                    String lowIssue = issue.toLowerCase();
                    if (lowIssue.contains("tyre") || lowIssue.contains("puncture")) {
                        issueIcon = "fa-solid fa-compact-disc";
                    } else if (lowIssue.contains("battery") || lowIssue.contains("jump")) {
                        issueIcon = "fa-solid fa-car-battery";
                    } else if (lowIssue.contains("electrical") || lowIssue.contains("repair")) {
                        issueIcon = "fa-solid fa-bolt";
                    } else if (lowIssue.contains("general") || lowIssue.contains("service")) {
                        issueIcon = "fa-solid fa-gear";
                    } else if (lowIssue.contains("overheating") || lowIssue.contains("engine")) {
                        issueIcon = "fa-solid fa-cogs";
                    } else if (lowIssue.contains("fuel")) {
                        issueIcon = "fa-solid fa-gas-pump";
                    } else if (lowIssue.contains("spark") || lowIssue.contains("plug")) {
                        issueIcon = "fa-solid fa-bolt-lightning";
                    } else if (lowIssue.contains("wheel") || lowIssue.contains("alignment")) {
                        issueIcon = "fa-solid fa-circle-notch";
                    } else if (lowIssue.contains("ac") || lowIssue.contains("gas")) {
                        issueIcon = "fa-solid fa-snowflake";
                    } else if (lowIssue.contains("brake") || lowIssue.contains("pad")) {
                        issueIcon = "fa-solid fa-triangle-exclamation";
                    } else if (lowIssue.contains("clutch") || lowIssue.contains("transmission")) {
                        issueIcon = "fa-solid fa-gears";
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

                    // Parse Requested Date and Time safely as dd-MM-yyyy
                    String reqDate = "13-11-2026";
                    String reqTime = "11:05 AM";
                    if (rDateStr != null && !rDateStr.trim().isEmpty()) {
                        java.util.regex.Matcher dm = java.util.regex.Pattern.compile("(\\d{2}-\\d{2}-\\d{4})").matcher(rDateStr);
                        if (dm.find()) {
                            reqDate = dm.group(1);
                        } else {
                            java.util.regex.Matcher dm2 = java.util.regex.Pattern.compile("([A-Za-z]{3}\\s+\\d{1,2},\\s*\\d{4})").matcher(rDateStr);
                            if (dm2.find()) {
                                try {
                                    Date p = new SimpleDateFormat("MMM d, yyyy").parse(dm2.group(1));
                                    reqDate = new SimpleDateFormat("dd-MM-yyyy").format(p);
                                } catch(Exception ign) {
                                    reqDate = dm2.group(1);
                                }
                            }
                        }
                        java.util.regex.Matcher tm = java.util.regex.Pattern.compile("(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm))").matcher(rDateStr);
                        if (tm.find()) reqTime = tm.group(1);
                    }
                    row.put("req_date", reqDate);
                    row.put("req_time", reqTime);

                    // Parse Completed Date and Time as dd-MM-yyyy
                    String compDate = "";
                    String compTime = "";
                    if (cDateStr != null && !cDateStr.trim().isEmpty() && !"-".equals(cDateStr.trim())) {
                        java.util.regex.Matcher cdm = java.util.regex.Pattern.compile("(\\d{2}-\\d{2}-\\d{4})").matcher(cDateStr);
                        if (cdm.find()) {
                            compDate = cdm.group(1);
                        } else {
                            java.util.regex.Matcher cdm2 = java.util.regex.Pattern.compile("([A-Za-z]{3}\\s+\\d{1,2},\\s*\\d{4})").matcher(cDateStr);
                            if (cdm2.find()) {
                                try {
                                    Date p = new SimpleDateFormat("MMM d, yyyy").parse(cdm2.group(1));
                                    compDate = new SimpleDateFormat("dd-MM-yyyy").format(p);
                                } catch(Exception ign) {
                                    compDate = cdm2.group(1);
                                }
                            }
                        }
                        java.util.regex.Matcher ctm = java.util.regex.Pattern.compile("(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm))").matcher(cDateStr);
                        if (ctm.find()) compTime = ctm.group(1);
                    }
                    row.put("comp_date", compDate);
                    row.put("comp_time", compTime);

                    allHistoryList.add(row);
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

    int totalFilteredServices = allHistoryList.size();
    int totalPages = (totalFilteredServices + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalFilteredServices);

    List pageHistoryList = new ArrayList();
    for (int k = startIndex; k < endIndex; k++) {
        pageHistoryList.add(allHistoryList.get(k));
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Service History — Mechanic Portal</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Mechanic Shell & Base Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">

    <!-- Dedicated Service History Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-service-history.css">
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
            <div class="sh-header-row">
                <div class="sh-title-group">
                    <div class="sh-title-icon-box">
                        <i class="fa-solid fa-clock-rotate-left"></i>
                    </div>
                    <div class="sh-title-text">
                        <h1>Service <span class="accent-orange">History</span></h1>
                        <p>View all your completed and past service requests.</p>
                    </div>
                </div>

                <div class="sh-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <!-- Four Statistic Summary Cards (Completed Service History Data Only) -->
            <div class="sh-stats-grid">
                <!-- Card 1: Completed Services -->
                <div class="sh-stat-card sh-card-completed">
                    <div class="sh-stat-icon-box">
                        <i class="fa-solid fa-check"></i>
                    </div>
                    <div class="sh-stat-info">
                        <span class="sh-stat-label">Completed Services</span>
                        <span class="sh-stat-number" id="statCompleted"><%= completedCount %></span>
                    </div>
                </div>

                <!-- Card 2: Total Revenue -->
                <div class="sh-stat-card sh-card-total">
                    <div class="sh-stat-icon-box">
                        <i class="fa-solid fa-indian-rupee-sign"></i>
                    </div>
                    <div class="sh-stat-info">
                        <span class="sh-stat-label">Total Revenue</span>
                        <span class="sh-stat-number">₹<%= (int)totalRevenue %></span>
                    </div>
                </div>

                <!-- Card 3: Vehicles Serviced -->
                <div class="sh-stat-card sh-card-inprogress" style="background-color: #FFF7ED; border-color: #FED7AA;">
                    <div class="sh-stat-icon-box" style="background: rgba(249, 115, 22, 0.18); color: #EA580C;">
                        <i class="fa-solid fa-car"></i>
                    </div>
                    <div class="sh-stat-info">
                        <span class="sh-stat-label">Vehicles Serviced</span>
                        <span class="sh-stat-number"><%= vehicleCount %></span>
                    </div>
                </div>

                <!-- Card 4: Motorists Served -->
                <div class="sh-stat-card sh-card-rejected" style="background-color: #ECFDF5; border-color: #A7F3D0;">
                    <div class="sh-stat-icon-box" style="background: rgba(16, 185, 129, 0.2); color: #059669;">
                        <i class="fa-solid fa-users"></i>
                    </div>
                    <div class="sh-stat-info">
                        <span class="sh-stat-label">Motorists Served</span>
                        <span class="sh-stat-number"><%= customerCount %></span>
                    </div>
                </div>
            </div>

            <!-- Search and Filter Toolbar -->
            <form action="service-history.jsp" method="GET" class="sh-toolbar-form" id="filterForm">
                <!-- 1. Search Box -->
                <div class="sh-search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" 
                           name="search" 
                           class="sh-search-input" 
                           placeholder="Search by Request ID, Vehicle No., or Service Issue..." 
                           value="<%= search %>">
                </div>

                <!-- 2. Breakdown Issue Dropdown -->
                <div class="sh-select-box">
                    <select name="issue" class="sh-select-control" onchange="this.form.submit()">
                        <option value="" <%= issueFilter.isEmpty() ? "selected" : "" %>>All Breakdown Issues</option>
                        <option value="Engine" <%= "Engine".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Engine Issue</option>
                        <option value="Battery" <%= "Battery".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Battery Jumpstart</option>
                        <option value="Tyre" <%= "Tyre".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Tyre / Puncture</option>
                        <option value="Fuel" <%= "Fuel".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Fuel Issue</option>
                        <option value="Brake" <%= "Brake".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Brake Failure</option>
                        <option value="Electrical" <%= "Electrical".equalsIgnoreCase(issueFilter) ? "selected" : "" %>>Electrical Repair</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- 3. Date Range Group (From Date - To Date) -->
                <div class="sh-date-range-group">
                    <div class="sh-date-input-box">
                        <i class="fa-regular fa-calendar"></i>
                        <input type="text" 
                               name="fromDate" 
                               class="sh-date-control" 
                               placeholder="From Date" 
                               value="<%= fromDate %>"
                               onfocus="(this.type='date')" 
                               onblur="if(!this.value)this.type='text'">
                    </div>

                    <span class="sh-date-sep">-</span>

                    <div class="sh-date-input-box">
                        <i class="fa-regular fa-calendar"></i>
                        <input type="text" 
                               name="toDate" 
                               class="sh-date-control" 
                               placeholder="To Date" 
                               value="<%= toDate %>"
                               onfocus="(this.type='date')" 
                               onblur="if(!this.value)this.type='text'">
                    </div>
                </div>

                <!-- 4. Orange Search Button -->
                <button type="submit" class="btn-sh-search">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <span>Search</span>
                </button>
            </form>

            <!-- Service History Main Card -->
            <div class="sh-main-card">
                <!-- Section Header with Title and Export Report Button -->
                <div class="sh-card-header">
                    <div class="sh-card-title-group">
                        <i class="fa-solid fa-clipboard-check"></i>
                        <h2>Service History</h2>
                    </div>

                    <!-- Export Report Button (Outlined Orange) -->
                    <button type="button" class="btn-sh-export" onclick="exportServiceHistoryReport()">
                        <i class="fa-solid fa-arrow-down-to-bracket"></i>
                        <span>Export Report</span>
                    </button>
                </div>

                <!-- Responsive Table Container -->
                <div class="sh-table-container">
                    <% if (totalFilteredServices == 0) { %>
                        <div class="sh-empty-state">
                            <div class="sh-empty-icon">
                                <i class="fa-solid fa-clock-rotate-left"></i>
                            </div>
                            <h3 class="sh-empty-title">No service history found</h3>
                            <p class="sh-empty-desc">
                                <%= (!search.isEmpty() || !statusFilter.isEmpty() || !fromDate.isEmpty() || !toDate.isEmpty()) 
                                    ? "No service records matched your filters. Try clearing search criteria." 
                                    : "You don't have any past or completed breakdown service requests yet." %>
                            </p>
                            <% if (!search.isEmpty() || !statusFilter.isEmpty() || !fromDate.isEmpty() || !toDate.isEmpty()) { %>
                                <a href="service-history.jsp" class="btn-sh-search" style="text-decoration:none; display:inline-flex; padding:8px 18px;">
                                    <i class="fa-solid fa-arrow-rotate-left"></i>
                                    <span>Clear Filters</span>
                                </a>
                            <% } %>
                        </div>
                    <% } else { %>
                        <table class="sh-data-table" id="serviceHistoryTable">
                            <thead>
                                <tr>
                                    <th style="width: 32px; text-align: center;">S.No</th>
                                    <th style="width: 90px;">Request ID</th>
                                    <th style="width: 175px;">Vehicle</th>
                                    <th style="width: 155px;">Service Issue</th>
                                    <th style="width: 135px;">Location</th>
                                    <th style="width: 135px;">Requested On</th>
                                    <th style="width: 135px;">Completed On</th>
                                    <th style="width: 110px; text-align: center;">Status</th>
                                    <th style="width: 80px; text-align: center;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    for (int i = 0; i < pageHistoryList.size(); i++) {
                                        Map req = (Map) pageHistoryList.get(i);
                                        int rowSerial = startIndex + i + 1;
                                        String rCode = (String) req.get("code");
                                        String vNum = (String) req.get("vehicle");
                                        String vModel = (String) req.get("model");
                                        String vImg = (String) req.get("vehicle_img");
                                        String issue = (String) req.get("issue");
                                        String issueIcon = (String) req.get("issue_icon");
                                        String locName = (String) req.get("loc_name");
                                        String locDist = (String) req.get("loc_dist");
                                        String reqDate = (String) req.get("req_date");
                                        String reqTime = (String) req.get("req_time");
                                        String compDate = (String) req.get("comp_date");
                                        String compTime = (String) req.get("comp_time");
                                        String st = (String) req.get("status");
                                        String cName = (String) req.get("customer_name");
                                        String cPhone = (String) req.get("customer_phone");
                                        String desc = (String) req.get("description");
                                        if (desc == null || desc.trim().isEmpty()) desc = "Breakdown assistance record for " + vModel + " (" + vNum + "). Status: " + st;

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

                                        // Status Pill Class & Icon
                                        String statusPillClass = "status-pill-completed";
                                        String statusIcon = "fa-solid fa-check";
                                        if ("In Progress".equalsIgnoreCase(st) || "Accepted".equalsIgnoreCase(st)) {
                                            statusPillClass = "status-pill-inprogress";
                                            statusIcon = "fa-regular fa-clock";
                                        } else if ("Rejected".equalsIgnoreCase(st) || "Cancelled".equalsIgnoreCase(st)) {
                                            statusPillClass = "status-pill-rejected";
                                            statusIcon = "fa-solid fa-xmark";
                                        }
                                %>
                                <tr id="row-<%= rCode %>"
                                    data-req-code="<%= rCode %>"
                                    data-vehicle="<%= vNum %>"
                                    data-model="<%= vModel %>"
                                    data-issue="<%= issue %>"
                                    data-location="<%= locName %> <%= locDist %>"
                                    data-req-date="<%= reqDate %> <%= reqTime %>"
                                    data-comp-date="<%= (!compDate.isEmpty() ? compDate + " " + compTime : "-") %>"
                                    data-status="<%= st %>"
                                    data-customer="<%= cName %>"
                                    data-phone="<%= cPhone %>"
                                    data-desc="<%= desc.replace("\"", "&quot;") %>">
                                    
                                    <!-- 1. Row Number -->
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
                                                <span><%= reqDate %></span>
                                            </div>
                                            <% if (!reqTime.isEmpty()) { %>
                                            <div class="datetime-row">
                                                <i class="fa-regular fa-clock"></i>
                                                <span><%= reqTime %></span>
                                            </div>
                                            <% } %>
                                        </div>
                                    </td>

                                    <!-- 7. Completed On (Date & Time or Dash) -->
                                    <td>
                                        <% if (!compDate.isEmpty()) { %>
                                            <div class="datetime-cell-box">
                                                <div class="datetime-row">
                                                    <i class="fa-regular fa-calendar"></i>
                                                    <span><%= compDate %></span>
                                                </div>
                                                <% if (!compTime.isEmpty()) { %>
                                                <div class="datetime-row">
                                                    <i class="fa-regular fa-clock"></i>
                                                    <span><%= compTime %></span>
                                                </div>
                                                <% } %>
                                            </div>
                                        <% } else { %>
                                            <span class="dash-text">-</span>
                                        <% } %>
                                    </td>

                                    <!-- 8. Status Pill Badge -->
                                    <td style="text-align: center;">
                                        <span class="status-pill <%= statusPillClass %>">
                                            <i class="<%= statusIcon %>"></i>
                                            <span><%= st %></span>
                                        </span>
                                    </td>

                                    <!-- 9. Action: View Button -->
                                    <td style="text-align: center;">
                                        <button type="button" 
                                                class="btn-sh-view" 
                                                id="btn-view-<%= rCode %>"
                                                onclick="openViewModal('<%= rCode %>')"
                                                title="View service details">
                                            <i class="fa-regular fa-eye"></i>
                                            <span>View</span>
                                        </button>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } %>
                </div>

                <!-- Footer with Record Counter and Pagination Controls -->
                <div class="sh-footer-row">
                    <div class="sh-record-count-text" id="footerRecordCount">
                        <% if (totalFilteredServices > 0) { %>
                            Showing <%= startIndex + 1 %> to <%= endIndex %> of <%= totalFilteredServices %> requests
                        <% } else { %>
                            Showing 0 of 0 requests
                        <% } %>
                    </div>

                    <% if (totalPages > 1) { %>
                    <div class="sh-pagination-controls">
                        <!-- Previous Page Button -->
                        <% if (currentPage > 1) { %>
                            <a href="service-history.jsp?page=<%= currentPage - 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&status=<%= java.net.URLEncoder.encode(statusFilter, "UTF-8") %>&fromDate=<%= java.net.URLEncoder.encode(fromDate, "UTF-8") %>&toDate=<%= java.net.URLEncoder.encode(toDate, "UTF-8") %>" 
                               class="sh-page-btn" 
                               aria-label="Previous Page">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="sh-page-btn disabled" disabled>
                                <i class="fa-solid fa-chevron-left"></i>
                            </button>
                        <% } %>

                        <!-- Page Numbers -->
                        <% for (int p = 1; p <= totalPages; p++) { %>
                            <% if (p == currentPage) { %>
                                <button type="button" class="sh-page-btn active"><%= p %></button>
                            <% } else { %>
                                <a href="service-history.jsp?page=<%= p %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&status=<%= java.net.URLEncoder.encode(statusFilter, "UTF-8") %>&fromDate=<%= java.net.URLEncoder.encode(fromDate, "UTF-8") %>&toDate=<%= java.net.URLEncoder.encode(toDate, "UTF-8") %>" 
                                   class="sh-page-btn">
                                    <%= p %>
                                </a>
                            <% } %>
                        <% } %>

                        <!-- Next Page Button -->
                        <% if (currentPage < totalPages) { %>
                            <a href="service-history.jsp?page=<%= currentPage + 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&status=<%= java.net.URLEncoder.encode(statusFilter, "UTF-8") %>&fromDate=<%= java.net.URLEncoder.encode(fromDate, "UTF-8") %>&toDate=<%= java.net.URLEncoder.encode(toDate, "UTF-8") %>" 
                               class="sh-page-btn" 
                               aria-label="Next Page">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="sh-page-btn disabled" disabled>
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

    <!-- Client-Side JavaScript: Modals, Export Report, Keyboard Shortcuts -->
    <script>
        // --- 1. View Details Modal ---
        function openViewModal(reqCode) {
            const row = document.getElementById('row-' + reqCode);
            const ds = row ? row.dataset : {};
            window.openServiceRequestModal({
                code: reqCode,
                userName: ds.customer,
                userPhone: ds.phone,
                vehicleNumber: ds.vehicle,
                brandModel: ds.model,
                issue: ds.issue,
                location: ds.location,
                status: ds.status,
                reqDate: ds.reqDate,
                description: ds.desc
            });
        }

        function closeViewModal() {
            window.closeServiceRequestModal();
        }

        // Close modal on Escape or outside click
        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') closeViewModal();
        });

        document.querySelectorAll('.sh-modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) closeViewModal();
            });
        });

        // --- 2. Export Service History Report (CSV Download) ---
        function exportServiceHistoryReport() {
            const table = document.getElementById('serviceHistoryTable');
            if (!table) {
                alert('No service history data to export.');
                return;
            }

            const rows = table.querySelectorAll('tbody tr');
            if (!rows.length) {
                alert('No service records to export.');
                return;
            }

            let csvContent = 'data:text/csv;charset=utf-8,';
            csvContent += 'Serial No,Request ID,Vehicle Number,Vehicle Model,Service Issue,Location,Requested On,Completed On,Status\\n';

            rows.forEach(r => {
                const sNo = r.querySelector('.td-row-num') ? r.querySelector('.td-row-num').textContent.trim() : '';
                const reqId = r.dataset.reqCode || '';
                const vNum = r.dataset.vehicle || '';
                const vModel = r.dataset.model || '';
                const issue = r.dataset.issue || '';
                const loc = r.dataset.location || '';
                const reqDate = (r.dataset.reqDate || '').replace(/,/g, '');
                const compDate = (r.dataset.compDate || '').replace(/,/g, '');
                const st = r.dataset.status || '';

                const line = [sNo, reqId, vNum, vModel, issue, loc, reqDate, compDate, st]
                    .map(item => '"' + item.replace(/"/g, '""') + '"')
                    .join(',');
                csvContent += line + '\\n';
            });

            const encodedUri = encodeURI(csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            link.setAttribute('download', 'Mechanic_Service_History_Report.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    </script>

</body>
</html>
