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

    request.setAttribute("activeUserPage", "dashboard");

    int userId = currentUser.getUserId();
    String userCode = "USR" + String.format("%03d", userId);
    String userFullName = currentUser.getFullName() != null ? currentUser.getFullName() : "User";

    // Format current dynamic date as dd-MM-yyyy
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd-MM-yyyy");
    String formattedCurrentDate = sdfDate.format(new Date());

    // 2. Database Queries for Real User Data
    int vehicleCount = 0;
    int totalRequests = 0;
    int completedRequests = 0;
    int inProgressRequests = 0;
    int cancelledRequests = 0;

    // Current Active Request fields
    boolean hasActiveRequest = false;
    int activeReqId = 0;
    String activeReqCode = "";
    String activeIssue = "";
    String activeLocation = "";
    String activeDate = "";
    String activeTime = "--";
    String activeStatus = "Pending";
    String activeMechanic = "";
    String activeMechPhone = "";
    String activeVehicleNo = "";
    String activeVehicleModel = "";
    int activeTimelineStep = 1; // 1: Sent, 2: Assigned, 3: On the Way, 4: Started, 5: Completed

    // Nearby Approved Mechanics
    List<Map<String, String>> nearbyMechanics = new ArrayList<Map<String, String>>();
    Map autoCancelledBannerInfo = null;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // 0. Auto-cancel any stagnant accepted requests (15m without progression)
            try {
                ServiceRequestService.autoCancelStagnantAcceptedRequests(conn, 15);
            } catch (Exception eAuto) {
                System.err.println("Notice in dashboard autoCancel: " + eAuto.getMessage());
            }

            // Check if user has an auto-cancelled request to intimate them
            try {
                PreparedStatement psAuto = conn.prepareStatement(
                    "SELECT request_code, vehicle_number, breakdown_issue, completed_date, additional_details " +
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
                    autoCancelledBannerInfo = new HashMap();
                    autoCancelledBannerInfo.put("code", rsAuto.getString("request_code"));
                    autoCancelledBannerInfo.put("vehicle", rsAuto.getString("vehicle_number"));
                    autoCancelledBannerInfo.put("issue", rsAuto.getString("breakdown_issue"));
                    autoCancelledBannerInfo.put("date", rsAuto.getString("completed_date"));
                }
                rsAuto.close();
                psAuto.close();
            } catch (Exception ignored) {}
            // A. Real Vehicle Count for this user
            try {
                ps = conn.prepareStatement("SELECT COUNT(*) FROM user_vehicles WHERE user_id = ?");
                ps.setInt(1, userId);
                rs = ps.executeQuery();
                if (rs.next()) {
                    vehicleCount = rs.getInt(1);
                }
                rs.close();
                ps.close();
            } catch (Exception ignored) {
                vehicleCount = 0;
            }

            // B. Real Service Request Statistics
            try {
                ps = conn.prepareStatement(
                    "SELECT status, COUNT(*) FROM service_requests " +
                    "WHERE user_id = ? OR user_code = ? OR user_name = ? GROUP BY status"
                );
                ps.setInt(1, userId);
                ps.setString(2, userCode);
                ps.setString(3, userFullName);
                rs = ps.executeQuery();
                while (rs.next()) {
                    String st = rs.getString(1);
                    int count = rs.getInt(2);
                    totalRequests += count;
                    if ("Completed".equalsIgnoreCase(st)) {
                        completedRequests += count;
                    } else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) {
                        cancelledRequests += count;
                    } else if ("Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                        inProgressRequests += count;
                    }
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("User dashboard stats query notice: " + ex.getMessage());
            }

            // C. Current Active / Most Relevant Request
            try {
                String curReqSql = "SELECT sr.request_id, sr.request_code, sr.breakdown_issue, sr.location, " +
                    "sr.requested_date, sr.requested_at, sr.status, sr.mechanic_name, sr.mechanic_code, " +
                    "sr.vehicle_number, " +
                    "COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                    "COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                    "COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, " +
                    "COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, " +
                    "m.phone AS mech_phone, m.owner_name AS mech_owner, m.workshop_name AS mech_shop " +
                    "FROM service_requests sr " +
                    "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                    "LEFT JOIN mechanics m ON (sr.mechanic_code = m.mechanic_code OR sr.mechanic_name = m.workshop_name) " +
                    "WHERE sr.user_id = ? OR sr.user_code = ? OR sr.user_name = ? " +
                    "ORDER BY " +
                    "  CASE " +
                    "    WHEN sr.status IN ('In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 " +
                    "    WHEN sr.status = 'On The Way' THEN 2 " +
                    "    WHEN sr.status = 'Accepted' THEN 3 " +
                    "    WHEN sr.status = 'Pending' THEN 4 " +
                    "    ELSE 5 " +
                    "  END ASC, " +
                    "  sr.requested_at DESC " +
                    "LIMIT 1";
                ps = conn.prepareStatement(curReqSql);
                ps.setInt(1, userId);
                ps.setString(2, userCode);
                ps.setString(3, userFullName);
                rs = ps.executeQuery();
                if (rs.next()) {
                    hasActiveRequest = true;
                    activeReqId = rs.getInt("request_id");
                    activeReqCode = rs.getString("request_code");
                    activeIssue = rs.getString("breakdown_issue");
                    activeLocation = rs.getString("location");
                    activeDate = rs.getString("requested_date");
                    activeStatus = rs.getString("status");
                    activeMechanic = rs.getString("mechanic_name");
                    activeMechPhone = rs.getString("mech_phone");
                    activeVehicleNo = rs.getString("vehicle_number");
                    activeVehicleModel = rs.getString("vehicle_model");
                    if (activeVehicleModel == null || activeVehicleModel.trim().isEmpty() || "Vehicle".equalsIgnoreCase(activeVehicleModel.trim())) {
                        String vBrand = rs.getString("vehicle_brand");
                        activeVehicleModel = (vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle";
                    }

                    // Parse formatted time
                    if (activeDate != null && (activeDate.contains("•") || activeDate.contains("·"))) {
                        String delim = activeDate.contains("•") ? "•" : "·";
                        String[] parts = activeDate.split(delim);
                        if (parts.length > 1) activeTime = parts[1].trim();
                        activeDate = parts[0].trim();
                    } else if (rs.getTimestamp("requested_at") != null) {
                        SimpleDateFormat sdfTime = new SimpleDateFormat("hh:mm a");
                        SimpleDateFormat sdfD = new SimpleDateFormat("dd-MM-yyyy");
                        activeTime = sdfTime.format(new Date(rs.getTimestamp("requested_at").getTime()));
                        if (activeDate == null || activeDate.trim().isEmpty()) {
                            activeDate = sdfD.format(new Date(rs.getTimestamp("requested_at").getTime()));
                        }
                    }

                    // Ensure activeDate is dd-MM-yyyy
                    if (activeDate != null && !activeDate.trim().isEmpty() && !activeDate.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                        try {
                            Date parsed = null;
                            try { parsed = new SimpleDateFormat("MMM d, yyyy").parse(activeDate); } catch(Exception ignored1) {}
                            if (parsed == null) {
                                try { parsed = new SimpleDateFormat("yyyy-MM-dd").parse(activeDate); } catch(Exception ignored2) {}
                            }
                            if (parsed != null) {
                                activeDate = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                            }
                        } catch (Exception ignored) {}
                    }

                    if ("Completed".equalsIgnoreCase(activeStatus)) {
                        activeTimelineStep = 5;
                    } else if ("In Progress".equalsIgnoreCase(activeStatus) || "Diagnostics Done".equalsIgnoreCase(activeStatus) || "Parts Replacement".equalsIgnoreCase(activeStatus)) {
                        activeTimelineStep = 4;
                    } else if ("On The Way".equalsIgnoreCase(activeStatus)) {
                        activeTimelineStep = 3;
                    } else if ("Accepted".equalsIgnoreCase(activeStatus)) {
                        activeTimelineStep = 2;
                    } else if ("Pending".equalsIgnoreCase(activeStatus)) {
                        activeTimelineStep = 1;
                    } else {
                        activeTimelineStep = 0;
                    }
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Active request query notice: " + ex.getMessage());
            }

            // D. Real Nearby Approved Mechanics
            try {
                ps = conn.prepareStatement(
                    "SELECT mechanic_id, mechanic_code, owner_name, workshop_name, location, city, rating, reviews_count, profile_image, phone " +
                    "FROM mechanics WHERE approval_status = 'Approved' " +
                    "ORDER BY rating DESC, reviews_count DESC LIMIT 2"
                );
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, String> mech = new HashMap<String, String>();
                    mech.put("id", String.valueOf(rs.getInt("mechanic_id")));
                    mech.put("owner", rs.getString("owner_name"));
                    mech.put("workshop", rs.getString("workshop_name"));
                    String loc = rs.getString("location");
                    if (loc == null || loc.trim().isEmpty()) loc = rs.getString("city");
                    mech.put("location", loc != null ? loc : "Coimbatore");
                    mech.put("rating", rs.getString("rating") != null ? rs.getString("rating") : "4.8");
                    int revCnt = rs.getInt("reviews_count");
                    mech.put("reviews", String.valueOf(revCnt > 0 ? revCnt : 120));
                    mech.put("profile_image", rs.getString("profile_image"));
                    mech.put("phone", rs.getString("phone"));
                    nearbyMechanics.add(mech);
                }
                rs.close();
                ps.close();
            } catch (Exception ex) {
                System.err.println("Nearby mechanics query notice: " + ex.getMessage());
            }
        }
    } catch (Exception e) {
        System.err.println("User dashboard database error: " + e.getMessage());
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Dashboard — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- User Dashboard Dedicated Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css?v=2.0">
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <!-- ROW 1: Page Header: Title + Dynamic Date Card -->
            <div class="dashboard-page-header">
                <div class="header-text-group">
                    <h1>User <span class="accent-orange">Dashboard</span></h1>
                    <p>Manage your vehicles, request assistance and track your services.</p>
                </div>
                <div class="date-badge-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= formattedCurrentDate %></span>
                </div>
            </div>

            <!-- ROW 2: Welcome Hero Banner & My Vehicles Summary Card -->
            <div class="hero-row-grid">
                <!-- Welcome Hero Banner -->
                <div class="welcome-hero-banner">
                    <img src="${pageContext.request.contextPath}/images/user-welcome-banner-bg-2x.png" alt="Roadside Breakdown Assistance" class="hero-bg-photo">
                    <div class="hero-inner-content">
                        <p class="hero-subtitle-top">Welcome Back,</p>
                        <h2 class="hero-user-name"><%= userFullName %> 👋</h2>
                        <p class="hero-desc">Need help on the road? Request instant assistance and get connected with nearby mechanics.</p>
                        <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="btn-hero-action">
                            <i class="fa-solid fa-location-dot"></i> Find Mechanics & Request <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </div>
                </div>

                <!-- My Vehicles Summary Card (Exact Dark Theme with White Car) -->
                <div class="my-vehicles-card">
                    <div class="vehicles-card-inner">
                        <div class="vehicles-card-header">
                            <div class="veh-icon-box">
                                <i class="fa-solid fa-car"></i>
                            </div>
                            <span class="veh-card-title">My Vehicles</span>
                        </div>
                        <div class="vehicles-card-body">
                            <div class="veh-big-count"><%= vehicleCount %></div>
                            <div class="veh-sub-label">Registered Vehicles</div>
                        </div>
                        <a href="${pageContext.request.contextPath}/user/vehicles.jsp" class="btn-manage-vehicles">
                            Manage Vehicles <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </div>
                    <div class="veh-car-illustration-wrap">
                        <img src="${pageContext.request.contextPath}/images/user-card-white-car-blended.png" alt="Registered Vehicles" class="veh-car-illustration">
                    </div>
                </div>
            </div>

            <!-- ROW 3: Four Statistics Metric Cards -->
            <div class="stats-cards-row">
                <!-- Card 1: Total Requests (Light orange) -->
                <div class="stat-metric-card stat-card-orange" onclick="location.href='${pageContext.request.contextPath}/user/my-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View All Service Requests">
                    <div class="stat-card-top">
                        <div class="stat-icon-wrapper">
                            <i class="fa-solid fa-clipboard-list"></i>
                        </div>
                        <span class="stat-trend-badge trend-neutral">
                            <i class="fa-solid fa-list-check"></i> Total Logged
                        </span>
                    </div>
                    <div class="stat-data-block">
                        <span class="stat-data-title">Total Requests</span>
                        <span class="stat-data-value"><%= totalRequests %></span>
                    </div>
                    <svg class="stat-wave-svg" viewBox="0 0 100 24" preserveAspectRatio="none">
                        <path d="M0,18 Q25,6 50,14 T100,8 L100,24 L0,24 Z" fill="rgba(249, 115, 22, 0.18)"/>
                    </svg>
                </div>

                <!-- Card 2: Completed (Light green) -->
                <div class="stat-metric-card stat-card-green" onclick="location.href='${pageContext.request.contextPath}/user/service-history.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View Completed Services">
                    <div class="stat-card-top">
                        <div class="stat-icon-wrapper">
                            <i class="fa-solid fa-circle-check"></i>
                        </div>
                        <span class="stat-trend-badge <%= completedRequests > 0 ? "trend-up" : "trend-neutral" %>">
                            <i class="fa-solid <%= completedRequests > 0 ? "fa-arrow-up" : "fa-check" %>"></i> <%= totalRequests > 0 ? String.format(java.util.Locale.US, "%.0f%%", (completedRequests * 100.0 / totalRequests)) : "0%" %>
                        </span>
                    </div>
                    <div class="stat-data-block">
                        <span class="stat-data-title">Completed</span>
                        <span class="stat-data-value"><%= completedRequests %></span>
                    </div>
                    <svg class="stat-wave-svg" viewBox="0 0 100 24" preserveAspectRatio="none">
                        <path d="M0,16 Q30,8 60,16 T100,6 L100,24 L0,24 Z" fill="rgba(22, 163, 74, 0.18)"/>
                    </svg>
                </div>

                <!-- Card 3: In Progress (Light yellow) -->
                <div class="stat-metric-card stat-card-yellow" onclick="location.href='${pageContext.request.contextPath}/user/my-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View In-Progress Requests">
                    <div class="stat-card-top">
                        <div class="stat-icon-wrapper">
                            <i class="fa-regular fa-clock"></i>
                        </div>
                        <span class="stat-trend-badge <%= inProgressRequests > 0 ? "trend-up" : "trend-neutral" %>">
                            <i class="fa-solid <%= inProgressRequests > 0 ? "fa-bolt" : "fa-clock" %>"></i> <%= inProgressRequests %> Active
                        </span>
                    </div>
                    <div class="stat-data-block">
                        <span class="stat-data-title">In Progress</span>
                        <span class="stat-data-value"><%= inProgressRequests %></span>
                    </div>
                    <svg class="stat-wave-svg" viewBox="0 0 100 24" preserveAspectRatio="none">
                        <path d="M0,14 Q35,6 70,16 T100,10 L100,24 L0,24 Z" fill="rgba(217, 119, 6, 0.18)"/>
                    </svg>
                </div>

                <!-- Card 4: Cancelled (Light red) -->
                <div class="stat-metric-card stat-card-red" onclick="location.href='${pageContext.request.contextPath}/user/my-requests.jsp'" role="button" tabindex="0" style="cursor: pointer;" title="View Cancelled Requests">
                    <div class="stat-card-top">
                        <div class="stat-icon-wrapper">
                            <i class="fa-solid fa-circle-xmark"></i>
                        </div>
                        <span class="stat-trend-badge trend-neutral">
                            <%= totalRequests > 0 ? String.format(java.util.Locale.US, "%.0f%%", (cancelledRequests * 100.0 / totalRequests)) : "0.0%" %>
                        </span>
                    </div>
                    <div class="stat-data-block">
                        <span class="stat-data-title">Cancelled</span>
                        <span class="stat-data-value"><%= cancelledRequests %></span>
                    </div>
                    <svg class="stat-wave-svg" viewBox="0 0 100 24" preserveAspectRatio="none">
                        <path d="M0,20 Q25,12 55,18 T100,12 L100,24 L0,24 Z" fill="rgba(239, 68, 68, 0.18)"/>
                    </svg>
                </div>
            </div>

            <!-- Auto-Cancelled Re-Request Intimation Banner -->
            <% if (autoCancelledBannerInfo != null) { %>
            <div style="background: #FFF7ED; border: 1.5px solid #FDBA74; border-left: 5px solid #EA580C; border-radius: 14px; padding: 16px 20px; margin-bottom: 24px; box-shadow: 0 4px 14px rgba(234, 88, 12, 0.08); display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap;">
                <div style="display: flex; align-items: flex-start; gap: 14px;">
                    <div style="width: 40px; height: 40px; border-radius: 50%; background: #FEE2E2; color: #DC2626; display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; box-shadow: 0 2px 8px rgba(220, 38, 38, 0.2);">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                    </div>
                    <div>
                        <div style="font-weight: 800; font-size: 15px; color: #9A3412; margin-bottom: 3px;">
                            Service Request Auto-Cancelled &bull; Re-Request Intimation
                        </div>
                        <div style="font-size: 13.5px; color: #7C2D12; line-height: 1.45;">
                            Request <strong style="color: #1E293B;"><%= autoCancelledBannerInfo.get("code") %></strong> for vehicle <strong style="color: #EA580C;"><%= autoCancelledBannerInfo.get("vehicle") %></strong> was auto-cancelled because the mechanic did not advance the process to the next stage in time. Please re-request assistance to find an available mechanic.
                        </div>
                    </div>
                </div>
                <a href="${pageContext.request.contextPath}/user/request-assistance.jsp?reRequest=<%= autoCancelledBannerInfo.get("code") %>" style="display: inline-flex; align-items: center; gap: 8px; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFFFFF; font-weight: 700; font-size: 13px; padding: 10px 20px; border-radius: 10px; text-decoration: none; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.35); white-space: nowrap; transition: all 0.2s;">
                    <i class="fa-solid fa-rotate-right"></i> Re-Request Assistance Now
                </a>
            </div>
            <% } %>

            <!-- ROW 4: Workflow Tri-Grid (Current Request + Nearby Mechanics + Find Mechanics Map) -->
            <div class="workflow-tri-grid">
                
                <!-- 1. Current Request Card -->
                <div class="dashboard-box-card current-request-box">
                    <!-- Dark Title Bar -->
                    <div class="card-dark-header">
                        <div class="header-left">
                            <i class="fa-solid fa-car-burst text-orange"></i>
                            <span class="card-title-text">Current Request</span>
                        </div>
                        <a href="${pageContext.request.contextPath}/user/my-requests.jsp" class="header-view-all">View All →</a>
                    </div>

                    <!-- Inner Card Content -->
                    <div class="card-inner-body">
                        <% if (hasActiveRequest) { 
                            String activeBadgeClass = "badge-status-in-progress";
                            String activeBadgeIcon = "fa-solid fa-gear fa-spin-pulse";
                            if ("Pending".equalsIgnoreCase(activeStatus)) {
                                activeBadgeClass = "badge-status-pending";
                                activeBadgeIcon = "fa-regular fa-clock";
                            } else if ("On The Way".equalsIgnoreCase(activeStatus)) {
                                activeBadgeClass = "badge-status-on-way";
                                activeBadgeIcon = "fa-solid fa-motorcycle";
                            } else if ("Completed".equalsIgnoreCase(activeStatus)) {
                                activeBadgeClass = "badge-status-completed";
                                activeBadgeIcon = "fa-solid fa-circle-check";
                            }

                            int fillPct = 0;
                            if (activeTimelineStep == 2) fillPct = 25;
                            else if (activeTimelineStep == 3) fillPct = 50;
                            else if (activeTimelineStep == 4) fillPct = 75;
                            else if (activeTimelineStep >= 5) fillPct = 100;
                        %>
                        <!-- Sub-card with breakdown details -->
                        <div class="req-detail-subcard">
                            <div class="subcard-left">
                                <div class="subcard-icon-box">
                                    <i class="fa-solid fa-car"></i>
                                </div>
                                <div class="subcard-text">
                                    <h4 class="subcard-issue"><%= activeIssue %></h4>
                                    <div class="subcard-meta">
                                        <span><i class="fa-solid fa-location-dot"></i> <%= activeLocation %></span>
                                        <span><i class="fa-regular fa-calendar"></i> <%= activeDate %></span>
                                        <% if (activeVehicleNo != null && !activeVehicleNo.trim().isEmpty()) { %>
                                            <span style="font-weight: 600; color: #1E293B;"><i class="fa-solid fa-car-side"></i> <%= activeVehicleNo %><%= (activeVehicleModel != null && !activeVehicleModel.trim().isEmpty() && !"Vehicle".equalsIgnoreCase(activeVehicleModel)) ? " (" + activeVehicleModel + ")" : "" %></span>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                            <div class="subcard-right">
                                <span class="<%= activeBadgeClass %>">
                                    <i class="<%= activeBadgeIcon %>"></i> <%= activeStatus %>
                                </span>
                            </div>
                        </div>

                        <!-- 5-Milestone Stepper Timeline -->
                        <div class="timeline-stepper">
                            <div class="timeline-track-bar">
                                <div class="track-fill-green" style="width: <%= fillPct %>%;"></div>
                            </div>

                            <!-- Stage 1: Request Sent -->
                            <div class="stepper-node <%= activeTimelineStep >= 1 ? "completed" : "" %>">
                                <div class="node-circle">
                                    <i class="fa-solid <%= activeTimelineStep >= 1 ? "fa-check" : "fa-circle" %>"></i>
                                </div>
                                <span class="node-label">Request Sent</span>
                                <span class="node-time"><%= activeTime %></span>
                            </div>

                            <!-- Stage 2: Mechanic -->
                            <div class="stepper-node <%= activeTimelineStep >= 2 ? "completed" : (activeTimelineStep == 1 ? "upcoming" : "") %>">
                                <div class="node-circle">
                                    <i class="fa-solid <%= activeTimelineStep >= 2 ? "fa-check" : "fa-circle" %>"></i>
                                </div>
                                <span class="node-label">Mechanic</span>
                                <span class="node-time"><%= activeTimelineStep >= 2 ? (activeMechanic != null && !activeMechanic.trim().isEmpty() ? "Assigned" : "Matched") : "--" %></span>
                            </div>

                            <!-- Stage 3: On the Way -->
                            <div class="stepper-node <%= activeTimelineStep == 3 ? "active-current" : (activeTimelineStep > 3 ? "completed" : "upcoming") %>">
                                <div class="node-circle">
                                    <i class="fa-solid <%= activeTimelineStep == 3 ? "fa-motorcycle" : (activeTimelineStep > 3 ? "fa-check" : "fa-circle") %>"></i>
                                </div>
                                <span class="node-label">On the Way</span>
                                <span class="node-time"><%= activeTimelineStep == 3 ? "En Route" : (activeTimelineStep > 3 ? "Arrived" : "--") %></span>
                            </div>

                            <!-- Stage 4: Service Started -->
                            <div class="stepper-node <%= activeTimelineStep == 4 ? "active-current" : (activeTimelineStep > 4 ? "completed" : "upcoming") %>">
                                <div class="node-circle">
                                    <i class="fa-solid <%= activeTimelineStep == 4 ? "fa-wrench" : (activeTimelineStep > 4 ? "fa-check" : "fa-circle") %>"></i>
                                </div>
                                <span class="node-label">Service Started</span>
                                <span class="node-time"><%= activeTimelineStep == 4 ? "Working" : (activeTimelineStep > 4 ? "Done" : "--") %></span>
                            </div>

                            <!-- Stage 5: Completed -->
                            <div class="stepper-node <%= activeTimelineStep >= 5 ? "completed" : "upcoming" %>">
                                <div class="node-circle">
                                    <i class="fa-solid <%= activeTimelineStep >= 5 ? "fa-check" : "fa-circle" %>"></i>
                                </div>
                                <span class="node-label">Completed</span>
                                <span class="node-time"><%= activeTimelineStep >= 5 ? "Resolved" : "--" %></span>
                            </div>
                        </div>

                        <!-- 3 Action Buttons -->
                        <div class="req-action-buttons">
                            <button type="button" class="btn-outline-action" onclick="openServiceRequestModal('<%= activeReqCode %>')" style="cursor: pointer; background: transparent; border: 1.5px solid #E2E8F0;">
                                <i class="fa-regular fa-eye"></i> View Details
                            </button>
                            <% if (activeMechPhone != null && !activeMechPhone.trim().isEmpty()) { %>
                                <a href="tel:<%= activeMechPhone %>" class="btn-outline-action text-orange-icon" title="Call <%= activeMechanic != null ? activeMechanic : "Mechanic" %>">
                                    <i class="fa-solid fa-phone"></i> Call Mechanic (<%= activeMechPhone %>)
                                </a>
                            <% } else { %>
                                <span class="btn-outline-action" style="opacity: 0.55; cursor: not-allowed;" title="Mechanic has not been assigned yet">
                                    <i class="fa-solid fa-phone-slash"></i> Mechanic Not Assigned
                                </span>
                            <% } %>
                            <% if (activeTimelineStep <= 2 && activeTimelineStep >= 1) { %>
                                <a href="${pageContext.request.contextPath}/user/my-requests.jsp" class="btn-outline-action btn-cancel-action" title="Manage or cancel request in My Requests">
                                    <i class="fa-solid fa-circle-xmark"></i> Cancel Request
                                </a>
                            <% } else if (activeTimelineStep >= 3 && activeTimelineStep <= 4) { %>
                                <span class="btn-outline-action" style="opacity: 0.5; cursor: not-allowed;" title="Mechanic is already dispatched or working on the vehicle">
                                    <i class="fa-solid fa-lock"></i> In Progress (Locked)
                                </span>
                            <% } else { %>
                                <span class="btn-outline-action" style="opacity: 0.5; cursor: not-allowed;">
                                    <i class="fa-solid fa-check"></i> Resolved
                                </span>
                            <% } %>
                        </div>
                        <% } else { %>
                        <!-- Clean Empty State when user has no requests -->
                        <div style="padding: 36px 20px; text-align: center; display: flex; flex-direction: column; align-items: center; justify-content: center;">
                            <div style="width: 58px; height: 58px; border-radius: 50%; background: #F8FAFC; border: 2px dashed #E2E8F0; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #10B981; margin-bottom: 12px;">
                                <i class="fa-solid fa-shield-check"></i>
                            </div>
                            <h4 style="font-size: 15px; font-weight: 700; color: #1E293B; margin-bottom: 6px;">No Active Breakdown Requests</h4>
                            <p style="font-size: 13px; color: #64748B; margin-bottom: 18px; max-width: 320px;">You currently have no open roadside assistance requests. Safe travels on the road!</p>
                            <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="btn-hero-action" style="display: inline-flex; align-items: center; gap: 8px; padding: 10px 20px; font-size: 13px; text-decoration: none;">
                                <i class="fa-solid fa-location-dot"></i> Find Mechanics & Request <i class="fa-solid fa-arrow-right"></i>
                            </a>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- 2. Nearby Mechanics Card -->
                <div class="dashboard-box-card nearby-mechanics-box">
                    <!-- Dark Title Bar -->
                    <div class="card-dark-header">
                        <div class="header-left">
                            <i class="fa-solid fa-location-dot text-orange"></i>
                            <span class="card-title-text">Nearby Mechanics</span>
                        </div>
                        <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="header-view-all">View All →</a>
                    </div>

                    <!-- Inner Card Content -->
                    <div class="card-inner-body p-0">
                        <div class="nearby-mechanics-list">
                            <% if (nearbyMechanics.isEmpty()) { %>
                                <div style="padding: 28px 20px; text-align: center; color: #64748B; font-size: 13px;">
                                    <i class="fa-solid fa-store-slash" style="font-size: 26px; color: #CBD5E1; margin-bottom: 8px; display: block;"></i>
                                    No registered workshops available nearby.
                                </div>
                            <% } else {
                                for (int i = 0; i < nearbyMechanics.size(); i++) { 
                                    Map<String, String> mech = nearbyMechanics.get(i);
                                    String wName = mech.get("workshop");
                                    String loc = mech.get("location");
                                    String rat = mech.get("rating");
                                    String rev = mech.get("reviews");
                                    String pImg = mech.get("profile_image");
                                    String avatarSrc = (pImg != null && !pImg.trim().isEmpty())
                                        ? (request.getContextPath() + "/images/" + pImg)
                                        : (request.getContextPath() + "/images/avatar-mechanic.jpg");
                            %>
                            <div class="mech-card-item">
                                <div class="mech-item-left">
                                    <div class="mech-avatar" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 2px solid #F97316; color: #F97316; font-size: 16px; border-radius: 50%; width: 44px; height: 44px; flex-shrink: 0;">
                                        <i class="fa-solid fa-wrench"></i>
                                    </div>
                                    <div class="mech-item-details">
                                        <h4 class="mech-workshop-name"><%= wName %></h4>
                                        <div class="mech-loc"><i class="fa-solid fa-location-dot"></i> <%= loc %></div>
                                        <div class="mech-rating">
                                            <i class="fa-solid fa-star"></i> <%= rat %> <span class="rating-count">(<%= rev %> reviews)</span>
                                        </div>
                                    </div>
                                </div>
                                <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp?id=<%= mech.get("id") %>" class="btn-view-profile-pill">
                                    View Profile
                                </a>
                            </div>
                            <% } } %>
                        </div>
                    </div>
                </div>

                <!-- 3. Find Mechanics Near You Card -->
                <div class="dashboard-box-card find-mechanics-card">
                    <!-- Dark Title Bar -->
                    <div class="card-dark-header">
                        <div class="header-left">
                            <i class="fa-solid fa-location-dot text-orange"></i>
                            <span class="card-title-text">Find Mechanics Near You</span>
                        </div>
                    </div>

                    <!-- Inner Card Content -->
                    <div class="card-inner-body">
                        <div class="find-map-crop-box">
                            <img src="${pageContext.request.contextPath}/images/user-map-preview-exact-2x.png" alt="Map Preview" class="find-map-exact-img">
                        </div>
                        <p class="find-map-text">Locate and connect with trusted mechanics in your area.</p>
                        <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="btn-find-mechanics-main">
                            <i class="fa-solid fa-paper-plane"></i> Find Mechanics <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </div>
                </div>

            </div>

        </main>
    </div>

    <!-- Interactive JavaScript -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // User Profile Dropdown Toggle
            const userProfileBtn = document.getElementById('userProfileBtn');
            const userProfileWrapper = document.getElementById('userProfileWrapper');
            const userProfileDropdown = document.getElementById('userProfileDropdown');

            if (userProfileBtn && userProfileDropdown) {
                userProfileBtn.addEventListener('click', function (e) {
                    e.stopPropagation();
                    const isShown = userProfileDropdown.classList.contains('show');
                    closeAllDropdowns();
                    if (!isShown) {
                        userProfileDropdown.classList.add('show');
                        userProfileWrapper.classList.add('active');
                    }
                });
            }

            // Notifications Dropdown Toggle
            const notifBtn = document.getElementById('notifBtn');
            const notifDropdown = document.getElementById('notifDropdown');

            if (notifBtn && notifDropdown) {
                notifBtn.addEventListener('click', function (e) {
                    e.stopPropagation();
                    const isShown = notifDropdown.classList.contains('show');
                    closeAllDropdowns();
                    if (!isShown) {
                        notifDropdown.classList.add('show');
                    }
                });
            }

            function closeAllDropdowns() {
                if (userProfileDropdown) userProfileDropdown.classList.remove('show');
                if (userProfileWrapper) userProfileWrapper.classList.remove('active');
                if (notifDropdown) notifDropdown.classList.remove('show');
            }

            // Close dropdowns on outside click
            document.addEventListener('click', function () {
                closeAllDropdowns();
            });
        });
    </script>
<jsp:include page="/common/service-request-view-modal.jsp" />
</body>
</html>
