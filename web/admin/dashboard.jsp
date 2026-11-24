<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="com.roadassistance.model.Admin" %>
<%@ page import="com.roadassistance.model.AdminStats" %>
<%@ page import="com.roadassistance.model.ServiceRequest" %>
<%@ page import="com.roadassistance.dao.AdminDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%
    Admin currentAdmin = (Admin) session.getAttribute("admin");
    if (currentAdmin == null) {
        response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=auth_required");
        return;
    }

    AdminStats stats = (AdminStats) request.getAttribute("adminStats");
    List<ServiceRequest> recentRequests = (List<ServiceRequest>) request.getAttribute("recentRequests");

    if (stats == null || recentRequests == null) {
        AdminDAO dao = new AdminDAO();
        if (stats == null) stats = dao.getAdminStats();
        if (recentRequests == null) recentRequests = dao.getRecentRequests(5);
    }

    request.setAttribute("activePage", "dashboard");
    request.setAttribute("pageTitle", "Admin Dashboard");
    request.setAttribute("pageSubtitle", "Monitor and manage the roadside assistance platform");
    request.setAttribute("searchPlaceholder", "Search users, mechanics, requests...");
    request.setAttribute("notifCount", "3");

    // Query dashboard statistics directly from database
    int valTotalUsers = 0;
    int valActiveUsers = 0;
    int valTotalMechanics = 0;
    int valPendingApprovals = 0;
    int valApprovedMechanics = 0;
    int valBlockedMechanics = 0;
    int valTotalRequests = 0;
    int valPendingRequests = 0;
    int valCompletedRequests = 0;
    int valRejectedRequests = 0;
    int valInProgressRequests = 0;

    // Period specific counts for dynamic donut chart filter
    int mComp = 0, mPend = 0, mRej = 0, mInProg = 0, mTot = 0;
    int wComp = 0, wPend = 0, wRej = 0, wInProg = 0, wTot = 0;
    int yComp = 0, yPend = 0, yRej = 0, yInProg = 0, yTot = 0;

    try {
        java.sql.Connection connDash = com.roadassistance.util.DBConnection.getConnection();
        if (connDash != null) {
            java.sql.Statement stDash = connDash.createStatement();

            // Users count & status
            java.sql.ResultSet rsU = stDash.executeQuery("SELECT status, COUNT(*) FROM users GROUP BY status");
            while (rsU.next()) {
                String uSt = rsU.getString(1);
                int uCnt = rsU.getInt(2);
                valTotalUsers += uCnt;
                if ("Active".equalsIgnoreCase(uSt)) valActiveUsers += uCnt;
            }
            rsU.close();
            if (valTotalUsers == 0) {
                java.sql.ResultSet rsUTot = stDash.executeQuery("SELECT COUNT(*) FROM users");
                if (rsUTot.next()) { valTotalUsers = rsUTot.getInt(1); valActiveUsers = valTotalUsers; }
                rsUTot.close();
            }

            // Mechanics count & status
            java.sql.ResultSet rsM = stDash.executeQuery("SELECT approval_status, COUNT(*) FROM mechanics GROUP BY approval_status");
            while (rsM.next()) {
                String st = rsM.getString(1);
                int cnt = rsM.getInt(2);
                valTotalMechanics += cnt;
                if ("Pending".equalsIgnoreCase(st)) valPendingApprovals = cnt;
                else if ("Approved".equalsIgnoreCase(st)) valApprovedMechanics = cnt;
                else if ("Blocked".equalsIgnoreCase(st)) valBlockedMechanics = cnt;
            }
            rsM.close();

            // Overall Service requests count & status
            java.sql.ResultSet rsR = stDash.executeQuery("SELECT status, COUNT(*) FROM service_requests GROUP BY status");
            while (rsR.next()) {
                String st = rsR.getString(1);
                int cnt = rsR.getInt(2);
                valTotalRequests += cnt;
                if ("Pending".equalsIgnoreCase(st)) valPendingRequests += cnt;
                else if ("Completed".equalsIgnoreCase(st)) valCompletedRequests += cnt;
                else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) valRejectedRequests += cnt;
                else if ("Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                    valInProgressRequests += cnt;
                }
            }
            rsR.close();

            // Month breakdown
            java.sql.ResultSet rsMth = stDash.executeQuery(
                "SELECT status, COUNT(*) FROM service_requests " +
                "WHERE requested_at >= DATE_FORMAT(NOW(), '%Y-%m-01') OR requested_at IS NULL GROUP BY status"
            );
            while (rsMth.next()) {
                String st = rsMth.getString(1);
                int cnt = rsMth.getInt(2);
                mTot += cnt;
                if ("Pending".equalsIgnoreCase(st)) mPend += cnt;
                else if ("Completed".equalsIgnoreCase(st)) mComp += cnt;
                else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) mRej += cnt;
                else if ("Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                    mInProg += cnt;
                }
            }
            rsMth.close();

            // Week breakdown
            java.sql.ResultSet rsWk = stDash.executeQuery(
                "SELECT status, COUNT(*) FROM service_requests " +
                "WHERE requested_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) OR requested_at IS NULL GROUP BY status"
            );
            while (rsWk.next()) {
                String st = rsWk.getString(1);
                int cnt = rsWk.getInt(2);
                wTot += cnt;
                if ("Pending".equalsIgnoreCase(st)) wPend += cnt;
                else if ("Completed".equalsIgnoreCase(st)) wComp += cnt;
                else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) wRej += cnt;
                else if ("Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                    wInProg += cnt;
                }
            }
            rsWk.close();

            // Year breakdown
            java.sql.ResultSet rsYr = stDash.executeQuery(
                "SELECT status, COUNT(*) FROM service_requests " +
                "WHERE requested_at >= DATE_FORMAT(NOW(), '%Y-01-01') OR requested_at IS NULL GROUP BY status"
            );
            while (rsYr.next()) {
                String st = rsYr.getString(1);
                int cnt = rsYr.getInt(2);
                yTot += cnt;
                if ("Pending".equalsIgnoreCase(st)) yPend += cnt;
                else if ("Completed".equalsIgnoreCase(st)) yComp += cnt;
                else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) yRej += cnt;
                else if ("Accepted".equalsIgnoreCase(st) || "On The Way".equalsIgnoreCase(st) || "In Progress".equalsIgnoreCase(st) || "Diagnostics Done".equalsIgnoreCase(st) || "Parts Replacement".equalsIgnoreCase(st)) {
                    yInProg += cnt;
                }
            }
            rsYr.close();

            stDash.close();
            connDash.close();
        }
    } catch(Exception ignored) {}

    // Dynamic Notifications Count: Pending Approvals + Pending Requests
    request.setAttribute("notifCount", String.valueOf(valPendingApprovals + valPendingRequests));

    int chartTotal = valTotalRequests;
    double pctCompleted = chartTotal > 0 ? (valCompletedRequests * 100.0 / chartTotal) : 0.0;
    double pctPending = chartTotal > 0 ? (valPendingRequests * 100.0 / chartTotal) : 0.0;
    double pctRejected = chartTotal > 0 ? (valRejectedRequests * 100.0 / chartTotal) : 0.0;
    double pctInProgress = chartTotal > 0 ? (valInProgressRequests * 100.0 / chartTotal) : 0.0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts: Plus Jakarta Sans & Poppins -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Universal Responsive System first -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css">
    
    <!-- Custom Admin Dashboard Stylesheet second (High Priority Strict Automotive No-Blue Theme) -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-dashboard.css?v=4.0">
</head>
<body>

<div class="app-wrapper">
    <!-- Common Admin Sidebar (With Yellow Flatbed Tow Truck Image & Navigation) -->
    <jsp:include page="sidebar.jsp" />

    <!-- Main Content Area with Dark Outer Shell and White Inner Canvas -->
    <div class="main-content">
        <!-- Common Top Navigation Header (Dark Charcoal #111827) -->
        <jsp:include page="topbar.jsp" />

        <!-- Dashboard Content Body Canvas (Rounded White Card matching Screenshot) -->
        <main class="dashboard-body">

            <!-- 1. Hero Animated Carousel Banner with Attached Images -->
            <section class="hero-carousel-container" id="heroCarousel" aria-label="Roadside Assistance Highlights">
                <div class="carousel-track" id="carouselTrack">

                    <!-- Slide 1: Breakdown Assistance (Main Assistance Hero) -->
                    <div class="carousel-slide active" data-index="0" style="background-image: linear-gradient(90deg, rgba(17, 24, 39, 0.96) 0%, rgba(17, 24, 39, 0.88) 45%, rgba(17, 24, 39, 0.35) 75%, transparent 100%), url('${pageContext.request.contextPath}/images/hero-dashboard-blended.jpg');">
                        <div class="hero-slide-content">
                            <div class="hero-top-tag">
                                <i class="fa-solid fa-car-burst"></i>
                                <span>On Road Vehicle</span>
                            </div>
                            <h2 class="hero-title">
                                Breakdown <span class="highlight">Assistance</span>
                            </h2>
                            <p class="hero-subtitle">
                                Quick • Reliable • Nearby Assistance
                            </p>
                            <div class="hero-highlights">
                                <div class="highlight-item">
                                    <i class="fa-solid fa-shield-halved"></i>
                                    <span>24/7 Support</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-location-dot"></i>
                                    <span>Nearby Mechanics</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-wrench"></i>
                                    <span>On-Site Repair</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-truck-pickup"></i>
                                    <span>Towing Service</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 2: On-Site Mechanic Repair (User Image: admin-slide-repair.jpg) -->
                    <div class="carousel-slide" data-index="1" style="background-image: linear-gradient(90deg, rgba(17, 24, 39, 0.96) 0%, rgba(17, 24, 39, 0.86) 45%, rgba(17, 24, 39, 0.30) 75%, transparent 100%), url('${pageContext.request.contextPath}/images/admin-slide-repair.jpg');">
                        <div class="hero-slide-content">
                            <div class="hero-top-tag">
                                <i class="fa-solid fa-wrench"></i>
                                <span>Expert Roadside Rescue</span>
                            </div>
                            <h2 class="hero-title">
                                On-Site <span class="highlight">Mechanic Repair</span>
                            </h2>
                            <p class="hero-subtitle">
                                Fast dispatch of verified mobile mechanics directly to stranded vehicle locations.
                            </p>
                            <div class="hero-highlights">
                                <div class="highlight-item">
                                    <i class="fa-solid fa-car-battery"></i>
                                    <span>Battery Jump-Start</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-circle-notch"></i>
                                    <span>Brake Inspection</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-screwdriver-wrench"></i>
                                    <span>Engine Diagnostics</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-gauge-high"></i>
                                    <span>15-Min Response</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 3: Vehicle Towing Service (User Image: admin-slide-towing.jpg) -->
                    <div class="carousel-slide" data-index="2" style="background-image: linear-gradient(90deg, rgba(17, 24, 39, 0.96) 0%, rgba(17, 24, 39, 0.86) 45%, rgba(17, 24, 39, 0.30) 75%, transparent 100%), url('${pageContext.request.contextPath}/images/admin-slide-towing.jpg');">
                        <div class="hero-slide-content">
                            <div class="hero-top-tag">
                                <i class="fa-solid fa-truck-pickup"></i>
                                <span>Heavy Duty & Flatbed Recovery</span>
                            </div>
                            <h2 class="hero-title">
                                Vehicle <span class="highlight">Towing Service</span>
                            </h2>
                            <p class="hero-subtitle">
                                Safe, hydraulic flatbed recovery transport for cars, SUVs, and bikes 24/7.
                            </p>
                            <div class="hero-highlights">
                                <div class="highlight-item">
                                    <i class="fa-solid fa-truck-monster"></i>
                                    <span>Flatbed Towing</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-shield-cat"></i>
                                    <span>Zero Damage Secure</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-road"></i>
                                    <span>Highway Emergency</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-map-location-dot"></i>
                                    <span>Live GPS Tracking</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Slide 4: Service Completed (User Image: admin-slide-completed.jpg) -->
                    <div class="carousel-slide" data-index="3" style="background-image: linear-gradient(90deg, rgba(17, 24, 39, 0.96) 0%, rgba(17, 24, 39, 0.86) 45%, rgba(17, 24, 39, 0.30) 75%, transparent 100%), url('${pageContext.request.contextPath}/images/admin-slide-completed.jpg');">
                        <div class="hero-slide-content">
                            <div class="hero-top-tag">
                                <i class="fa-solid fa-circle-check"></i>
                                <span>Quality Verified & Resolved</span>
                            </div>
                            <h2 class="hero-title">
                                Service <span class="highlight">Completed</span>
                            </h2>
                            <p class="hero-subtitle">
                                Transparent service resolution, rating feedback, and verified satisfaction.
                            </p>
                            <div class="hero-highlights">
                                <div class="highlight-item">
                                    <i class="fa-solid fa-file-lines"></i>
                                    <span>Digital Service Summary</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-star"></i>
                                    <span>Motorist Feedback</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-award"></i>
                                    <span>Warranty Protected</span>
                                </div>
                                <div class="highlight-item">
                                    <i class="fa-solid fa-car-side"></i>
                                    <span>Safe Back On Road</span>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>

                <!-- Navigation Arrow Buttons (< and >) -->
                <button type="button" class="carousel-arrow prev" id="carouselPrevBtn" aria-label="Previous Slide">
                    <i class="fa-solid fa-chevron-left"></i>
                </button>
                <button type="button" class="carousel-arrow next" id="carouselNextBtn" aria-label="Next Slide">
                    <i class="fa-solid fa-chevron-right"></i>
                </button>

                <!-- Indicator Dots (Active elongated capsule, inactive dots) -->
                <div class="carousel-dots" id="carouselDots">
                    <span class="carousel-dot active" data-slide="0"></span>
                    <span class="carousel-dot" data-slide="1"></span>
                    <span class="carousel-dot" data-slide="2"></span>
                    <span class="carousel-dot" data-slide="3"></span>
                </div>
            </section>

            <!-- 2. Eight Statistics Cards in 2 Rows of 4 Cards -->
            <div class="stats-section-wrapper">
                <!-- Row 1: Total Users, Total Mechanics, Pending Approvals, Approved Mechanics -->
                <div class="stats-cards-row">
                    <!-- Card 1: Total Users -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/user-management.jsp'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-orange">
                                <i class="fa-solid fa-users"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Total Users</span>
                                <span class="stat-value"><%= valTotalUsers %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag tag-green">
                                <i class="fa-solid fa-check"></i> <%= valActiveUsers %> Active
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 2: Total Mechanics -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/mechanic-management.jsp'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-gray">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Total Mechanics</span>
                                <span class="stat-value"><%= valTotalMechanics %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag tag-green">
                                <i class="fa-solid fa-check"></i> <%= valApprovedMechanics %> Approved
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 3: Pending Approvals -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/mechanic-approval.jsp'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-yellow">
                                <i class="fa-solid fa-hourglass-half"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Pending Approvals</span>
                                <span class="stat-value"><%= valPendingApprovals %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag <%= valPendingApprovals > 0 ? "tag-yellow" : "tag-green" %>">
                                <i class="fa-solid <%= valPendingApprovals > 0 ? "fa-hourglass-half" : "fa-check" %>"></i> <%= valPendingApprovals > 0 ? (valPendingApprovals + " Pending") : "Up to date" %>
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 4: Approved Mechanics -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/mechanic-management.jsp?status=Approved'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-green">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Approved Mechanics</span>
                                <span class="stat-value"><%= valApprovedMechanics %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag tag-green">
                                <i class="fa-solid fa-shield-halved"></i> Active
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Blocked Mechanics, Total Service Requests, Pending Requests, Completed Requests -->
                <div class="stats-cards-row">
                    <!-- Card 5: Blocked Mechanics -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/blocked-mechanics.jsp'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-red">
                                <i class="fa-solid fa-ban"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Blocked Mechanics</span>
                                <span class="stat-value"><%= valBlockedMechanics %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag <%= valBlockedMechanics > 0 ? "tag-red" : "tag-green" %>">
                                <i class="fa-solid <%= valBlockedMechanics > 0 ? "fa-ban" : "fa-shield" %>"></i> <%= valBlockedMechanics %>
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 6: Total Service Requests -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/service-requests.jsp'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-purple">
                                <i class="fa-solid fa-clipboard-list"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Total Service Requests</span>
                                <span class="stat-value"><%= valTotalRequests %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag tag-orange">
                                <i class="fa-solid fa-bolt"></i> <%= valInProgressRequests %> Active
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 7: Pending Requests -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/service-requests.jsp?status=Pending'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-yellow">
                                <i class="fa-solid fa-hourglass-half"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Pending Requests</span>
                                <span class="stat-value"><%= valPendingRequests %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag <%= valPendingRequests > 0 ? "tag-yellow" : "tag-green" %>">
                                <i class="fa-solid <%= valPendingRequests > 0 ? "fa-clock" : "fa-check" %>"></i> <%= valPendingRequests > 0 ? (valPendingRequests + " Waiting") : "0 Waiting" %>
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>

                    <!-- Card 8: Completed Requests -->
                    <div class="stat-card" onclick="location.href='${pageContext.request.contextPath}/admin/service-requests.jsp?status=Completed'" role="button" tabindex="0">
                        <div class="stat-card-left">
                            <div class="stat-icon-bubble bubble-green">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                            <div class="stat-info-group">
                                <span class="stat-title">Completed Requests</span>
                                <span class="stat-value"><%= valCompletedRequests %></span>
                            </div>
                        </div>
                        <div class="stat-card-right">
                            <span class="stat-trend-tag tag-green">
                                <i class="fa-solid fa-circle-check"></i> <%= String.format(java.util.Locale.US, "%.0f%%", pctCompleted) %>
                            </span>
                            <i class="fa-solid fa-chevron-right stat-chevron"></i>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 3. Middle Section: Service Requests Overview (Left) & Recent Service Requests (Right) -->
            <div class="middle-overview-grid">

                <!-- Left Card: Service Requests Overview Donut Chart -->
                <div class="overview-card chart-card">
                    <div class="card-header-bar">
                        <div class="card-title-group">
                            <i class="fa-solid fa-chart-column header-icon-orange"></i>
                            <h2>Service Requests Overview</h2>
                        </div>
                        <div class="card-filter-box">
                            <select class="time-filter-dropdown" id="chartTimeFilter" aria-label="Filter period">
                                <option value="month" selected>This Month</option>
                                <option value="week">This Week</option>
                                <option value="year">This Year</option>
                            </select>
                        </div>
                    </div>

                    <div class="chart-flex-body">
                        <!-- Chart Visual Box with Center Overlay -->
                        <div class="donut-visual-container">
                            <canvas id="serviceRequestsChart"
                                    data-completed="<%= valCompletedRequests %>"
                                    data-pending="<%= valPendingRequests %>"
                                    data-rejected="<%= valRejectedRequests %>"
                                    data-in-progress="<%= valInProgressRequests %>">
                            </canvas>
                            <div class="donut-center-info">
                                <i class="fa-solid fa-car center-car-icon"></i>
                                <span class="center-count" id="centerTotalCount"><%= chartTotal %></span>
                                <span class="center-subtext">REQUESTS</span>
                            </div>
                        </div>

                        <!-- Legend List matching Reference Colors -->
                        <div class="donut-legend-stack">
                            <!-- Completed -->
                            <div class="legend-row">
                                <div class="legend-left-group">
                                    <span class="legend-bullet bullet-green"></span>
                                    <span class="legend-label">Completed</span>
                                </div>
                                <div class="legend-val-group">
                                    <strong id="legendCompletedCount"><%= valCompletedRequests %></strong>
                                    <span class="legend-pct" id="legendCompletedPct">(<%= String.format(java.util.Locale.US, "%.1f", pctCompleted) %>%)</span>
                                </div>
                            </div>

                            <!-- Pending -->
                            <div class="legend-row">
                                <div class="legend-left-group">
                                    <span class="legend-bullet bullet-yellow"></span>
                                    <span class="legend-label">Pending</span>
                                </div>
                                <div class="legend-val-group">
                                    <strong id="legendPendingCount"><%= valPendingRequests %></strong>
                                    <span class="legend-pct" id="legendPendingPct">(<%= String.format(java.util.Locale.US, "%.1f", pctPending) %>%)</span>
                                </div>
                            </div>

                            <!-- Rejected -->
                            <div class="legend-row">
                                <div class="legend-left-group">
                                    <span class="legend-bullet bullet-red"></span>
                                    <span class="legend-label">Rejected</span>
                                </div>
                                <div class="legend-val-group">
                                    <strong id="legendRejectedCount"><%= valRejectedRequests %></strong>
                                    <span class="legend-pct" id="legendRejectedPct">(<%= String.format(java.util.Locale.US, "%.1f", pctRejected) %>%)</span>
                                </div>
                            </div>

                            <!-- In Progress -->
                            <div class="legend-row">
                                <div class="legend-left-group">
                                    <span class="legend-bullet bullet-orange"></span>
                                    <span class="legend-label">In Progress</span>
                                </div>
                                <div class="legend-val-group">
                                    <strong id="legendInProgressCount"><%= valInProgressRequests %></strong>
                                    <span class="legend-pct" id="legendInProgressPct">(<%= String.format(java.util.Locale.US, "%.1f", pctInProgress) %>%)</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Card: Recent Service Requests Table -->
                <div class="overview-card table-card">
                    <div class="card-header-bar">
                        <div class="card-title-group">
                            <i class="fa-solid fa-clipboard-list header-icon-orange"></i>
                            <h2>Recent Service Requests</h2>
                        </div>
                        <a href="${pageContext.request.contextPath}/admin/service-requests.jsp" class="btn-pill-view-all">
                            <span>View All</span>
                            <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </div>

                    <div class="table-scroll-container">
                        <table class="recent-requests-table">
                            <thead>
                                <tr>
                                    <th>Request ID</th>
                                    <th>User</th>
                                    <th>Vehicle No.</th>
                                    <th>Issue</th>
                                    <th>Status</th>
                                    <th>Request Date</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody id="recentRequestsTableBody">
                                <%
                                    List<String[]> recentRequestList = new ArrayList<String[]>();
                                    Connection connRecent = null;
                                    try {
                                        connRecent = com.roadassistance.util.DBConnection.getConnection();
                                        if (connRecent != null) {
                                            PreparedStatement psR = connRecent.prepareStatement(
                                                "SELECT sr.request_code, sr.user_name, sr.vehicle_number, sr.breakdown_issue, sr.status, sr.requested_date, sr.requested_at, " +
                                                "COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                                                "COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, '') AS vehicle_model, " +
                                                "COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type " +
                                                "FROM service_requests sr " +
                                                "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                                                "ORDER BY sr.request_id DESC LIMIT 10"
                                            );
                                            ResultSet rsR = psR.executeQuery();
                                            while (rsR.next()) {
                                                String rCode = rsR.getString("request_code");
                                                String uName = rsR.getString("user_name");
                                                String vNo = rsR.getString("vehicle_number");
                                                String vModel = rsR.getString("vehicle_model");
                                                String vType = rsR.getString("vehicle_type");
                                                String issue = rsR.getString("breakdown_issue");
                                                String st = rsR.getString("status");
                                                String dt = rsR.getString("requested_date");
                                                if (dt == null || dt.trim().isEmpty()) {
                                                    Timestamp ts = rsR.getTimestamp("requested_at");
                                                    dt = (ts != null) ? new SimpleDateFormat("dd-MM-yyyy<br>hh:mm a").format(ts) : "13-11-2026<br>10:00 AM";
                                                } else {
                                                    String delim = dt.contains("•") ? "•" : (dt.contains("·") ? "·" : (dt.contains("<br>") ? "<br>" : null));
                                                    if (delim != null) {
                                                        String[] parts = dt.split(delim);
                                                        String dPart = parts[0].trim();
                                                        String tPart = parts.length > 1 ? parts[1].trim() : "";
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
                                                        dt = dPart + "<br>" + tPart;
                                                    }
                                                }
                                                String issueIcon = "fa-snowflake";
                                                if (issue != null) {
                                                    String iLower = issue.toLowerCase();
                                                    if (iLower.contains("brake")) issueIcon = "fa-circle-notch";
                                                    else if (iLower.contains("electric") || iLower.contains("battery")) issueIcon = "fa-bolt";
                                                    else if (iLower.contains("engine") || iLower.contains("overheat")) issueIcon = "fa-triangle-exclamation";
                                                    else if (iLower.contains("tyre") || iLower.contains("puncture")) issueIcon = "fa-circle-dot";
                                                }
                                                recentRequestList.add(new String[]{
                                                    rCode != null ? rCode : "REQ1001",
                                                    uName != null ? uName : "Motorist",
                                                    vNo != null ? vNo : "TN 45 AB 1234",
                                                    issue != null ? issue : "General Repair",
                                                    issueIcon,
                                                    st != null ? st : "Completed",
                                                    dt,
                                                    vModel != null ? vModel : "",
                                                    vType != null ? vType : "Car"
                                                });
                                            }
                                            rsR.close();
                                            psR.close();
                                        }
                                    } catch (Exception ignored) {
                                    } finally {
                                        if (connRecent != null) try { connRecent.close(); } catch (Exception ignored) {}
                                    }

                                    if (recentRequestList.isEmpty()) {
                                %>
                                <tr>
                                    <td colspan="7" style="text-align: center; padding: 32px; color: #6B7280;">
                                        <i class="fa-solid fa-clipboard-list" style="font-size: 28px; color: #D1D5DB; margin-bottom: 8px;"></i>
                                        <div style="font-weight: 600; font-size: 13px;">No recent service requests found</div>
                                    </td>
                                </tr>
                                <%
                                    }

                                    for (String[] row : recentRequestList) {
                                        String rCode = row[0];
                                        String uName = row[1];
                                        String vNo = row[2];
                                        String issue = row[3];
                                        String issueIcon = row[4];
                                        String st = row[5];
                                        String dt = row[6];
                                        String rowModel = row.length > 7 ? row[7] : "";
                                        String rowType = row.length > 8 ? row[8] : "Car";
                                        String vehIcon = (rowType.equalsIgnoreCase("Bike") || rowType.equalsIgnoreCase("Motorcycle") || rowType.equalsIgnoreCase("Two Wheeler") || rowType.equalsIgnoreCase("Scooter")) ? "fa-motorcycle" : "fa-car";

                                        String badgeClass = "badge-completed";
                                        String iconClass = "fa-circle-check";
                                        if ("Pending".equalsIgnoreCase(st)) {
                                            badgeClass = "badge-pending";
                                            iconClass = "fa-hourglass-half";
                                        } else if ("In Progress".equalsIgnoreCase(st)) {
                                            badgeClass = "badge-in-progress";
                                            iconClass = "fa-spinner";
                                        } else if ("Cancelled".equalsIgnoreCase(st) || "Rejected".equalsIgnoreCase(st)) {
                                            badgeClass = "badge-cancelled";
                                            iconClass = "fa-circle-xmark";
                                        }
                                %>
                                <tr>
                                    <td>
                                        <span class="req-id-pill"><%= rCode %></span>
                                    </td>
                                    <td>
                                        <div class="cell-user-group">
                                            <i class="fa-solid fa-user cell-icon-muted"></i>
                                            <span class="cell-user-name"><%= uName %></span>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="cell-vehicle-group">
                                            <i class="fa-solid <%= vehIcon %> cell-icon-muted"></i>
                                            <div>
                                                <span class="cell-vehicle-plate"><%= vNo %></span>
                                                <% if (!rowModel.isEmpty()) { %>
                                                    <div style="font-size: 11px; color: #64748B; font-weight: 500;"><%= rowModel %></div>
                                                <% } %>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="cell-issue-group">
                                            <i class="fa-solid <%= issueIcon %> cell-icon-orange"></i>
                                            <span class="cell-issue-text"><%= issue %></span>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="status-pill <%= badgeClass %>">
                                            <i class="fa-solid <%= iconClass %>"></i> <%= st %>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="cell-date-group">
                                            <i class="fa-regular fa-calendar cell-icon-orange"></i>
                                            <span class="cell-date-text"><%= dt %></span>
                                        </div>
                                    </td>
                                    <td>
                                        <button type="button" class="btn-action-eye" title="View Details" onclick="openServiceRequestModal('<%= rCode %>')" style="border: none; background: transparent; cursor: pointer;">
                                            <i class="fa-regular fa-eye"></i>
                                        </button>
                                    </td>
                                </tr>
                                <%
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>

            <!-- 4. Bottom Quick Actions Section (4 Wide Cards matching Screenshot) -->
            <section class="quick-actions-bar">
                <div class="qa-heading-row">
                    <i class="fa-solid fa-bolt qa-bolt-icon"></i>
                    <h3>Quick Actions</h3>
                </div>

                <div class="qa-buttons-grid">
                    <!-- Action 1: Manage Users (Orange Active Button) -->
                    <a href="${pageContext.request.contextPath}/admin/user-management.jsp" class="qa-card-btn qa-active-orange">
                        <div class="qa-btn-left">
                            <i class="fa-solid fa-users"></i>
                            <span>Manage Users</span>
                        </div>
                        <i class="fa-solid fa-arrow-right qa-arrow"></i>
                    </a>

                    <!-- Action 2: Manage Mechanics -->
                    <a href="${pageContext.request.contextPath}/admin/mechanic-management.jsp" class="qa-card-btn qa-btn-white">
                        <div class="qa-btn-left">
                            <i class="fa-solid fa-wrench qa-icon-orange"></i>
                            <span>Manage Mechanics</span>
                        </div>
                        <i class="fa-solid fa-arrow-right qa-arrow-orange"></i>
                    </a>

                    <!-- Action 3: View Requests -->
                    <a href="${pageContext.request.contextPath}/admin/service-requests.jsp" class="qa-card-btn qa-btn-white">
                        <div class="qa-btn-left">
                            <i class="fa-solid fa-clipboard-list qa-icon-orange"></i>
                            <span>View Requests</span>
                        </div>
                        <i class="fa-solid fa-arrow-right qa-arrow-orange"></i>
                    </a>

                    <!-- Action 4: System Reports -->
                    <a href="${pageContext.request.contextPath}/admin/service-requests.jsp" class="qa-card-btn qa-btn-white">
                        <div class="qa-btn-left">
                            <i class="fa-solid fa-chart-column qa-icon-orange"></i>
                            <span>System Reports</span>
                        </div>
                        <i class="fa-solid fa-arrow-right qa-arrow-orange"></i>
                    </a>
                </div>
            </section>

        </main>
    </div>
</div>

<!-- Dynamic Period Stats Payload for Time Filter -->
<script id="adminPeriodStats" type="application/json">
{
  "month": {"completed": <%= mComp %>, "pending": <%= mPend %>, "rejected": <%= mRej %>, "inProgress": <%= mInProg %>, "total": <%= mTot %>},
  "week": {"completed": <%= wComp %>, "pending": <%= wPend %>, "rejected": <%= wRej %>, "inProgress": <%= wInProg %>, "total": <%= wTot %>},
  "year": {"completed": <%= yComp %>, "pending": <%= yPend %>, "rejected": <%= yRej %>, "inProgress": <%= yInProg %>, "total": <%= yTot %>}
}
</script>

<!-- Chart.js 4 -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<!-- Admin Dashboard Controller JS & Universal Responsive Engine -->
<script src="${pageContext.request.contextPath}/js/admin-dashboard.js"></script>
<script src="${pageContext.request.contextPath}/js/app-responsive.js"></script>

<jsp:include page="/common/service-request-view-modal.jsp" />
</body>
</html>
