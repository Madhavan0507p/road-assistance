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
    // Anti-cache headers to secure back-navigation
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 1. Session Authentication & Approval Verification
    Mechanic currentMech = (Mechanic) session.getAttribute("mechanic");
    if (currentMech == null || !currentMech.isApproved()) {
        if (session != null) {
            session.removeAttribute("mechanic");
        }
        String redirectParam = (currentMech != null && currentMech.isBlocked()) ? "error=blocked" : ((currentMech != null && currentMech.isPending()) ? "error=pending" : "msg=auth_required");
        response.sendRedirect(request.getContextPath() + "/mechanic/login.jsp?" + redirectParam);
        return;
    }

    request.setAttribute("activeMechPage", "dashboard");

    // Dynamic Display Variables
    String mechCode = currentMech.getMechanicCode() != null ? currentMech.getMechanicCode() : "MEC003";
    String workshopName = currentMech.getWorkshopName() != null ? currentMech.getWorkshopName() : "Kumar Auto Works";
    String ownerName = currentMech.getFirstName() != null ? currentMech.getFirstName() : 
                      (currentMech.getOwnerName() != null ? currentMech.getOwnerName() : "Kumar");
    if (ownerName.contains(" ")) {
        ownerName = ownerName.split(" ")[0]; // First name for "Welcome back, Kumar!"
    }
    String phone = currentMech.getPhone() != null ? currentMech.getPhone() : "+91 98765 43210";
    String address = currentMech.getAddress() != null ? currentMech.getAddress() : "Manapparai, Trichy – 621306";
    String approvalStatus = currentMech.getApprovalStatus() != null ? currentMech.getApprovalStatus() : "Approved";
    double shopLat = currentMech.getLatitude() != 0.0 ? currentMech.getLatitude() : 11.0268;
    double shopLng = currentMech.getLongitude() != 0.0 ? currentMech.getLongitude() : 76.9507;

    // Dynamic Date Formatted as dd-MM-yyyy
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd-MM-yyyy");
    String formattedCurrentDate = sdfDate.format(new Date());

    // 2. Query Statistics & Recent Requests from MySQL
    int totalRequests = 0;
    int pendingRequests = 0;
    int acceptedRequests = 0;
    int completedRequests = 0;
    int rejectedRequests = 0;

    List recentRequests = new ArrayList();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String shopPhoto = "mechanic-workshop-sample.jpg";

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {
            // 0. Refresh workshop location, address & shop photo
            try {
                PreparedStatement psMech = conn.prepareStatement("SELECT latitude, longitude, address, workshop_name, profile_image FROM mechanics WHERE mechanic_id = ?");
                psMech.setInt(1, currentMech.getMechanicId());
                ResultSet rsMech = psMech.executeQuery();
                if (rsMech.next()) {
                    if (rsMech.getDouble("latitude") != 0.0) shopLat = rsMech.getDouble("latitude");
                    if (rsMech.getDouble("longitude") != 0.0) shopLng = rsMech.getDouble("longitude");
                    if (rsMech.getString("address") != null && !rsMech.getString("address").trim().isEmpty()) address = rsMech.getString("address");
                    if (rsMech.getString("workshop_name") != null && !rsMech.getString("workshop_name").trim().isEmpty()) workshopName = rsMech.getString("workshop_name");
                    if (rsMech.getString("profile_image") != null && !rsMech.getString("profile_image").trim().isEmpty()) shopPhoto = rsMech.getString("profile_image");
                }
                rsMech.close();
                psMech.close();

                // Check for real uploaded workshop photos
                PreparedStatement psPhoto = conn.prepareStatement("SELECT photo_path FROM mechanic_shop_photos WHERE mechanic_id = ? ORDER BY photo_id ASC LIMIT 1");
                psPhoto.setInt(1, currentMech.getMechanicId());
                ResultSet rsPhoto = psPhoto.executeQuery();
                if (rsPhoto.next()) {
                    String p = rsPhoto.getString("photo_path");
                    if (p != null && !p.trim().isEmpty()) shopPhoto = p.trim();
                }
                rsPhoto.close();
                psPhoto.close();
            } catch (Exception ex) {
                // Keep default
            }

            // A. Statistics
            try {
                String statsSql = "SELECT " +
                    "COUNT(*) AS total_cnt, " +
                    "SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_cnt, " +
                    "SUM(CASE WHEN status IN ('Accepted', 'On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS accepted_cnt, " +
                    "SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_cnt, " +
                    "SUM(CASE WHEN status = 'Rejected' OR status = 'Cancelled' THEN 1 ELSE 0 END) AS rejected_cnt " +
                    "FROM service_requests " +
                    "WHERE ((mechanic_code = ? OR mechanic_name = ? OR mechanic_name LIKE ?) " +
                    "   OR (status = 'Pending' AND (mechanic_code IS NULL OR mechanic_code = '' OR mechanic_name = 'Unassigned' OR mechanic_name = 'Nearby Mechanics' OR request_type = 'Common' OR request_type = 'Broadcast' OR mechanic_name IS NULL OR mechanic_name = '')))";
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
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Mechanic stats query warning: " + ex.getMessage());
            }

            // B. Recent Service Requests with Real Vehicle Details
            try {
                String reqSql = "SELECT sr.request_id, sr.request_code, sr.vehicle_number, sr.breakdown_issue, sr.location, " +
                    "sr.requested_date, sr.requested_at, sr.status, sr.service_cost, sr.user_name, " +
                    "COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                    "COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                    "COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, " +
                    "COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type " +
                    "FROM service_requests sr " +
                    "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                    "WHERE ((sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) " +
                    "   OR (sr.status = 'Pending' AND (sr.mechanic_code IS NULL OR sr.mechanic_code = '' OR sr.mechanic_name = 'Unassigned' OR sr.mechanic_name = 'Nearby Mechanics' OR sr.request_type = 'Common' OR sr.request_type = 'Broadcast' OR sr.mechanic_name IS NULL OR sr.mechanic_name = ''))) " +
                    "ORDER BY sr.requested_at DESC LIMIT 10";
                ps = conn.prepareStatement(reqSql);
                ps.setString(1, mechCode);
                ps.setString(2, workshopName);
                ps.setString(3, "%" + workshopName + "%");
                rs = ps.executeQuery();

                SimpleDateFormat sdfDateOnly = new SimpleDateFormat("dd-MM-yyyy");
                SimpleDateFormat sdfTimeOnly = new SimpleDateFormat("hh:mm a");

                while (rs.next()) {
                    Map row = new HashMap();
                    row.put("id", rs.getInt("request_id"));
                    row.put("code", rs.getString("request_code"));
                    
                    String vNum = rs.getString("vehicle_number");
                    row.put("vnum", vNum != null ? vNum : "TN 45 CY 6778");
                    
                    // Vehicle Model & Thumbnail dynamically retrieved from DB
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
                    row.put("vmodel", vModel);
                    row.put("vimg", vImg);
                    row.put("vtype", vType != null ? vType : "Car");

                    // Service Issue
                    String issue = rs.getString("breakdown_issue");
                    row.put("issue", issue);
                    
                    // Issue Icon
                    String issueIcon = "fa-solid fa-wrench";
                    if (issue != null) {
                        String iLower = issue.toLowerCase();
                        if (iLower.contains("overheat") || iLower.contains("engine")) issueIcon = "fa-solid fa-car-burst";
                        else if (iLower.contains("battery") || iLower.contains("jump")) issueIcon = "fa-solid fa-car-battery";
                        else if (iLower.contains("tyre") || iLower.contains("puncture")) issueIcon = "fa-solid fa-circle-dot";
                        else if (iLower.contains("general") || iLower.contains("service")) issueIcon = "fa-solid fa-gear";
                        else if (iLower.contains("electric")) issueIcon = "fa-solid fa-bolt";
                        else if (iLower.contains("brake")) issueIcon = "fa-solid fa-triangle-exclamation";
                        else if (iLower.contains("tow")) issueIcon = "fa-solid fa-truck-pickup";
                    }
                    row.put("issueIcon", issueIcon);

                    // Location & Distance
                    String loc = rs.getString("location");
                    String locName = loc != null ? loc : "Manapparai";
                    String locDist = "";
                    if (locName.contains("(") && locName.contains(")")) {
                        int start = locName.indexOf("(");
                        int end = locName.indexOf(")");
                        locDist = locName.substring(start, end + 1);
                        locName = locName.substring(0, start).trim();
                    }
                    row.put("locName", locName);
                    row.put("locDist", locDist);

                    // Date & Time
                    String rDateStr = rs.getString("requested_date");
                    String dispDate = "13-11-2026";
                    String dispTime = "10:24 AM";
                    if (rDateStr != null && (rDateStr.contains("•") || rDateStr.contains("·"))) {
                        String delim = rDateStr.contains("•") ? "•" : "·";
                        String[] parts = rDateStr.split(delim);
                        dispDate = parts[0].trim();
                        if (parts.length > 1) dispTime = parts[1].trim();
                    } else if (rs.getTimestamp("requested_at") != null) {
                        Date ts = new Date(rs.getTimestamp("requested_at").getTime());
                        dispDate = sdfDateOnly.format(ts);
                        dispTime = sdfTimeOnly.format(ts);
                    } else if (rDateStr != null) {
                        dispDate = rDateStr;
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

                    // Status
                    String status = rs.getString("status");
                    row.put("status", status != null ? status : "Pending");

                    recentRequests.add(row);
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Recent requests query warning: " + ex.getMessage());
            }
        }
    } catch (Exception e) {
        System.err.println("Database error in mechanic dashboard: " + e.getMessage());
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mechanic Dashboard — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Dedicated Mechanic Dashboard Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">
</head>
<body>

    <!-- 1. Top Navigation Bar (Dark Charcoal, Logo, Hamburger, Notifications, Avatar) -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Left Sidebar + White Canvas Main Content -->
    <div class="mech-dashboard-shell">
        <!-- Fixed Left Sidebar with Automotive Sunset Road Background Image -->
        <jsp:include page="sidebar.jsp" />

        <!-- Main Dashboard Canvas -->
        <main class="mech-main-canvas">
            
            <!-- Dashboard Page Heading & Date Card -->
            <div class="mech-header-row">
                <div class="mech-title-group">
                    <div class="mech-title-icon">
                        <i class="fa-solid fa-wrench"></i>
                    </div>
                    <div class="mech-title-text">
                        <h1>Mechanic <span class="accent-orange">Dashboard</span></h1>
                        <p>Welcome back, <%= ownerName %>! Manage your service requests and assist vehicle owners.</p>
                    </div>
                </div>

                <!-- Date Card -->
                <div class="mech-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= formattedCurrentDate %></span>
                </div>
            </div>

            <!-- Two-Column Main Dashboard Layout -->
            <div class="mech-dashboard-grid">
                
                <!-- ================= LEFT COLUMN ================= -->
                <div class="mech-left-col">
                    
                    <!-- 1. Large Mechanic Hero Banner -->
                    <section class="mech-hero-banner">
                        <div class="hero-banner-content">
                            <div class="hero-icon-title-row">
                                <div class="hero-service-icon">
                                    <i class="fa-solid fa-truck-pickup"></i>
                                </div>
                                <h2 class="hero-banner-title">
                                    Ready to Assist
                                    <span class="accent-orange">On the Road!</span>
                                </h2>
                            </div>
                            <p class="hero-banner-desc">
                                Respond to requests, provide quick service, and help vehicle owners get back on track.
                            </p>
                        </div>
                    </section>

                    <!-- 2. Five Dashboard Statistic Cards -->
                    <section class="mech-stats-grid">
                        <!-- Card 1: Total Requests -->
                        <div class="stat-metric-card stat-card-total" onclick="location.href='${pageContext.request.contextPath}/mechanic/service-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View All Service Requests">
                            <div class="stat-card-icon-box">
                                <i class="fa-solid fa-clipboard-list"></i>
                            </div>
                            <div class="stat-card-info">
                                <span class="stat-card-label">Total Requests</span>
                                <span class="stat-card-number"><%= totalRequests %></span>
                            </div>
                        </div>

                        <!-- Card 2: Pending -->
                        <div class="stat-metric-card stat-card-pending" onclick="location.href='${pageContext.request.contextPath}/mechanic/pending-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View Pending Requests">
                            <div class="stat-card-icon-box">
                                <i class="fa-regular fa-clock"></i>
                            </div>
                            <div class="stat-card-info">
                                <span class="stat-card-label">Pending</span>
                                <span class="stat-card-number"><%= pendingRequests %></span>
                            </div>
                        </div>

                        <!-- Card 3: Accepted -->
                        <div class="stat-metric-card stat-card-accepted" onclick="location.href='${pageContext.request.contextPath}/mechanic/accepted-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View Accepted & In-Progress Requests">
                            <div class="stat-card-icon-box">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                            <div class="stat-card-info">
                                <span class="stat-card-label">Accepted</span>
                                <span class="stat-card-number"><%= acceptedRequests %></span>
                            </div>
                        </div>

                        <!-- Card 4: Completed -->
                        <div class="stat-metric-card stat-card-completed" onclick="location.href='${pageContext.request.contextPath}/mechanic/service-history.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View Completed Service History">
                            <div class="stat-card-icon-box">
                                <i class="fa-solid fa-screwdriver-wrench"></i>
                            </div>
                            <div class="stat-card-info">
                                <span class="stat-card-label">Completed</span>
                                <span class="stat-card-number"><%= completedRequests %></span>
                            </div>
                        </div>

                        <!-- Card 5: Rejected -->
                        <div class="stat-metric-card stat-card-rejected" onclick="location.href='${pageContext.request.contextPath}/mechanic/service-requests.jsp?status=Cancelled'" role="button" tabindex="0" style="cursor: pointer;" title="View Rejected & Cancelled Requests">
                            <div class="stat-card-icon-box">
                                <i class="fa-solid fa-circle-xmark"></i>
                            </div>
                            <div class="stat-card-info">
                                <span class="stat-card-label">Rejected</span>
                                <span class="stat-card-number"><%= rejectedRequests %></span>
                            </div>
                        </div>
                    </section>

                    <!-- 3. Recent Service Requests Card & Table -->
                    <section class="mech-table-card">
                        <div class="table-card-header">
                            <div class="table-card-title-group">
                                <i class="fa-solid fa-clipboard-list"></i>
                                <h2>Recent Service Requests</h2>
                            </div>
                            <a href="${pageContext.request.contextPath}/mechanic/service-requests.jsp" class="link-view-all">
                                <span>View All Requests</span>
                                <i class="fa-solid fa-arrow-right"></i>
                            </a>
                        </div>

                        <div class="mech-table-container">
                            <% if (recentRequests.isEmpty()) { %>
                                <div class="table-empty-state">
                                    <div class="table-empty-icon">
                                        <i class="fa-solid fa-wrench"></i>
                                    </div>
                                    <h4 class="table-empty-title">No service requests available yet</h4>
                                    <p class="table-empty-desc">New roadside breakdown assistance requests from nearby drivers will appear here.</p>
                                </div>
                            <% } else { %>
                                <table class="mech-data-table">
                                    <thead>
                                        <tr>
                                            <th>S.No</th>
                                            <th>Request ID</th>
                                            <th>Vehicle</th>
                                            <th>Service Issue</th>
                                            <th>Location</th>
                                            <th>Requested On</th>
                                            <th>Status</th>
                                            <th style="text-align: center;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            for (int i = 0; i < recentRequests.size(); i++) {
                                                Map req = (Map) recentRequests.get(i);
                                                String st = (String) req.get("status");
                                                String pillClass = "status-pill-pending";
                                                String iconClass = "fa-regular fa-clock";

                                                if ("Accepted".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                                                    pillClass = "status-pill-accepted";
                                                    iconClass = "fa-solid fa-wrench";
                                                } else if ("On The Way".equalsIgnoreCase(st)) {
                                                    pillClass = "status-pill-accepted";
                                                    iconClass = "fa-solid fa-motorcycle";
                                                } else if ("Completed".equalsIgnoreCase(st)) {
                                                    pillClass = "status-pill-completed";
                                                    iconClass = "fa-solid fa-circle-check";
                                                } else if ("Rejected".equalsIgnoreCase(st) || "Cancelled".equalsIgnoreCase(st)) {
                                                    pillClass = "status-pill-rejected";
                                                    iconClass = "fa-solid fa-circle-xmark";
                                                }

                                                String vImgVal = (String) req.get("vimg");
                                                String vImgSrc;
                                                if (vImgVal != null && (vImgVal.startsWith("http://") || vImgVal.startsWith("https://"))) {
                                                    vImgSrc = vImgVal;
                                                } else if (vImgVal != null && vImgVal.startsWith("veh_")) {
                                                    vImgSrc = request.getContextPath() + "/uploads/vehicles/" + vImgVal;
                                                } else if (vImgVal != null && vImgVal.startsWith("uploads/")) {
                                                    vImgSrc = request.getContextPath() + "/" + vImgVal;
                                                } else {
                                                    vImgSrc = request.getContextPath() + "/images/" + (vImgVal != null && !vImgVal.trim().isEmpty() ? vImgVal : "vehicle-i20.png");
                                                }
                                        %>
                                        <tr>
                                            <td class="td-row-num"><%= (i + 1) %></td>
                                            <td>
                                                <span class="badge-req-id"><%= req.get("code") %></span>
                                            </td>
                                            <td>
                                                <div class="vehicle-cell-box">
                                                    <img src="<%= vImgSrc %>" 
                                                         alt="<%= req.get("vmodel") %>" 
                                                         class="vehicle-thumb-img"
                                                         onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-i20.png';">
                                                    <div class="vehicle-text-info">
                                                        <span class="vehicle-reg-no"><%= req.get("vnum") %></span>
                                                        <span class="vehicle-model-desc"><%= req.get("vmodel") %></span>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="issue-cell-box">
                                                    <i class="<%= req.get("issueIcon") %>"></i>
                                                    <span class="issue-name-text"><%= req.get("issue") %></span>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="location-cell-box">
                                                    <i class="fa-solid fa-location-dot"></i>
                                                    <div class="location-text-info">
                                                        <span class="location-name"><%= req.get("locName") %></span>
                                                        <% if (!((String)req.get("locDist")).isEmpty()) { %>
                                                            <span class="location-dist"><%= req.get("locDist") %></span>
                                                        <% } %>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="datetime-cell-box">
                                                    <div class="datetime-row">
                                                        <i class="fa-regular fa-calendar"></i>
                                                        <span><%= req.get("date") %></span>
                                                    </div>
                                                    <div class="datetime-row">
                                                        <i class="fa-regular fa-clock"></i>
                                                        <span><%= req.get("time") %></span>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="status-pill <%= pillClass %>">
                                                    <i class="<%= iconClass %>"></i>
                                                    <%= st %>
                                                </span>
                                            </td>
                                            <td style="text-align: center;">
                                                <button type="button" 
                                                   class="btn-action-view" 
                                                   onclick="openServiceRequestModal('<%= req.get("code") %>')"
                                                   title="View Request Details"
                                                   style="border: none; background: transparent; cursor: pointer;">
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
                    </section>

                </div>

                <!-- ================= RIGHT COLUMN ================= -->
                <div class="mech-right-col">
                    
                    <!-- 1. Profile Status Card -->
                    <div class="mech-status-card">
                        <div class="status-card-header">
                            <div class="status-card-title-group">
                                <i class="fa-solid fa-shield-halved"></i>
                                <h3>Profile Status</h3>
                            </div>
                            <span class="badge-approval <%= "Approved".equalsIgnoreCase(approvalStatus) ? "badge-approval-approved" : ("Pending".equalsIgnoreCase(approvalStatus) ? "badge-approval-pending" : "badge-approval-rejected") %>">
                                <%= approvalStatus %>
                            </span>
                        </div>
                        <p class="status-card-desc">
                            <% if ("Approved".equalsIgnoreCase(approvalStatus)) { %>
                                Your profile is verified and active. You can now accept service requests.
                            <% } else if ("Pending".equalsIgnoreCase(approvalStatus)) { %>
                                Your registration documents are under administrative review.
                            <% } else { %>
                                Your mechanic account is currently flagged. Please contact support.
                            <% } %>
                        </p>
                    </div>

                    <!-- 2. Quick Actions Card -->
                    <div class="mech-quick-actions-card">
                        <div class="quick-actions-header">
                            <i class="fa-solid fa-bolt"></i>
                            <h3>Quick Actions</h3>
                        </div>
                        <div class="quick-actions-btns">
                            <a href="${pageContext.request.contextPath}/mechanic/service-requests.jsp" class="btn-quick-primary">
                                <i class="fa-solid fa-plus"></i>
                                <span>View New Requests</span>
                            </a>
                            <a href="${pageContext.request.contextPath}/mechanic/service-history.jsp" class="btn-quick-secondary">
                                <i class="fa-solid fa-clock-rotate-left"></i>
                                <span>View Service History</span>
                            </a>
                        </div>
                    </div>

                    <!-- 3. My Workshop Card -->
                    <div class="mech-workshop-card">
                        <div class="workshop-header">
                            <i class="fa-solid fa-store"></i>
                            <h3>My Workshop</h3>
                        </div>

                        <!-- Workshop Photo (Dynamically loaded from mechanic_shop_photos) -->
                        <div class="workshop-photo-box">
                            <%
                                if (shopPhoto != null && !shopPhoto.trim().isEmpty()) {
                                    String photoSrcUrl = "";
                                    if (shopPhoto.startsWith("/")) {
                                        photoSrcUrl = request.getContextPath() + shopPhoto;
                                    } else if (shopPhoto.startsWith("http")) {
                                        photoSrcUrl = shopPhoto;
                                    } else {
                                        photoSrcUrl = request.getContextPath() + "/images/" + shopPhoto;
                                    }
                            %>
                            <img src="<%= photoSrcUrl %>" 
                                 alt="<%= workshopName %>" 
                                 class="workshop-photo-img">
                            <% } else { %>
                            <div class="workshop-photo-empty" style="width: 100%; height: 160px; border-radius: 12px; background: #F8FAFC; border: 2px dashed #CBD5E1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px; color: #94A3B8;">
                                <i class="fa-solid fa-store" style="font-size: 28px; color: #CBD5E1;"></i>
                                <span style="font-size: 13px; font-weight: 600;">No Workshop Photo Uploaded</span>
                            </div>
                            <% } %>
                        </div>

                        <!-- Workshop Info -->
                        <div class="workshop-details-content">
                            <h4 class="workshop-title-name"><%= workshopName %></h4>

                            <div class="workshop-info-row">
                                <i class="fa-solid fa-location-dot"></i>
                                <span><%= address %></span>
                            </div>

                            <div class="workshop-info-row">
                                <i class="fa-solid fa-phone"></i>
                                <strong><%= phone %></strong>
                            </div>

                            <div class="workshop-info-row" style="margin-top: 4px;">
                                <i class="fa-solid fa-location-crosshairs" style="color: #EA580C;"></i>
                                <span style="font-size: 12px; font-weight: 700; color: #1E293B;">
                                    <%= String.format(java.util.Locale.US, "%.4f", shopLat) %>° N, <%= String.format(java.util.Locale.US, "%.4f", shopLng) %>° E
                                </span>
                            </div>

                            <!-- Action Buttons: Choose on Map / GPS & Edit Profile -->
                            <div style="display: flex; gap: 8px; margin-top: 14px; flex-direction: column;">
                                <a href="${pageContext.request.contextPath}/mechanic/profile.jsp#garageMapSection" class="btn-workshop-map" style="display: flex; align-items: center; justify-content: center; gap: 8px; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFFFFF; font-weight: 700; font-size: 13px; padding: 10px 14px; border-radius: 10px; text-decoration: none; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.25); transition: transform 0.2s;">
                                    <i class="fa-solid fa-map-location-dot"></i>
                                    <span>Choose on Map / GPS</span>
                                </a>
                                <a href="${pageContext.request.contextPath}/mechanic/profile.jsp" class="btn-edit-profile" style="margin-top: 0;">
                                    <i class="fa-solid fa-pen"></i>
                                    <span>Edit Profile</span>
                                </a>
                            </div>
                        </div>
                    </div>

                </div>

            </div>

        </main>
    </div>

    <!-- Client-side Scripts: Sidebar Toggle & Dropdown Handlers -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // Profile Dropdown Toggle
            var profileBtn = document.getElementById('mechProfileBtn');
            var profileWrapper = document.getElementById('mechProfileWrapper');
            var profileDropdown = document.getElementById('mechProfileDropdown');

            if (profileBtn && profileWrapper && profileDropdown) {
                profileBtn.addEventListener('click', function (e) {
                    e.stopPropagation();
                    var isShowing = profileDropdown.classList.contains('show');
                    if (isShowing) {
                        profileDropdown.classList.remove('show');
                        profileWrapper.classList.remove('active');
                        profileBtn.setAttribute('aria-expanded', 'false');
                    } else {
                        profileDropdown.classList.add('show');
                        profileWrapper.classList.add('active');
                        profileBtn.setAttribute('aria-expanded', 'true');
                    }
                });

                document.addEventListener('click', function (e) {
                    if (!profileWrapper.contains(e.target)) {
                        profileDropdown.classList.remove('show');
                        profileWrapper.classList.remove('active');
                        profileBtn.setAttribute('aria-expanded', 'false');
                    }
                });
            }
        });
    </script>
<jsp:include page="/common/service-request-view-modal.jsp" />
</body>
</html>
