<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
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

    request.setAttribute("activeUserPage", "find");

    int userId = currentUser.getUserId();
    String userFullName = currentUser.getFullName() != null ? currentUser.getFullName() : "Raj Kumar";

    // 1b. Parameters from Find Mechanics
    String reqMechanicId = request.getParameter("mechanicId");
    String reqMechanicName = request.getParameter("mechanicName");
    if (reqMechanicName != null) reqMechanicName = reqMechanicName.trim();

    String paramLocation = request.getParameter("location");
    String paramLat = request.getParameter("lat");
    String paramLng = request.getParameter("lng");

    String initLocation = (paramLocation != null && !paramLocation.trim().isEmpty()) 
            ? paramLocation.trim() : "Saibaba Colony, Coimbatore - 641011";
    double initLat = 11.0268;
    double initLng = 76.9507;
    if (paramLat != null && paramLng != null) {
        try {
            initLat = Double.parseDouble(paramLat.trim());
            initLng = Double.parseDouble(paramLng.trim());
        } catch (Exception ignored) {}
    }

    String paramVehicle = request.getParameter("vehicle");
    if (paramVehicle == null) paramVehicle = request.getParameter("vehicleNo");
    if (paramVehicle != null) paramVehicle = paramVehicle.trim();
    String paramError = request.getParameter("error");

    String reRequestCode = request.getParameter("reRequest");
    if (reRequestCode != null) reRequestCode = reRequestCode.trim();

    String prefilledVehicle = paramVehicle;
    String prefilledIssue = null;
    String prefilledLocation = null;
    String prefilledDescription = null;
    boolean isReRequestMode = false;

    // 2. Fetch User's Registered Vehicles & Active Ongoing Requests
    List userVehicles = new ArrayList();
    List approvedMechanics = new ArrayList();
    Map activeVehicleRequests = new HashMap();

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
                System.err.println("Notice in autoCancel check: " + eAuto.getMessage());
            }

            // 0b. Fetch previous request details if in reRequest mode
            if (reRequestCode != null && !reRequestCode.isEmpty()) {
                try {
                    PreparedStatement psRe = conn.prepareStatement(
                        "SELECT vehicle_number, breakdown_issue, location, latitude, longitude, additional_details " +
                        "FROM service_requests WHERE (request_code = ? OR request_id = ?) AND (user_id = ? OR user_name = ?)"
                    );
                    psRe.setString(1, reRequestCode);
                    int parsedReId = 0;
                    try { parsedReId = Integer.parseInt(reRequestCode); } catch (Exception ignored) {}
                    psRe.setInt(2, parsedReId);
                    psRe.setInt(3, userId);
                    psRe.setString(4, userFullName);
                    ResultSet rsRe = psRe.executeQuery();
                    if (rsRe.next()) {
                        isReRequestMode = true;
                        prefilledVehicle = rsRe.getString("vehicle_number");
                        prefilledIssue = rsRe.getString("breakdown_issue");
                        prefilledLocation = rsRe.getString("location");
                        prefilledDescription = rsRe.getString("additional_details");
                        if (prefilledDescription != null && prefilledDescription.contains("[Auto-cancelled")) {
                            int tagIdx = prefilledDescription.indexOf("[Auto-cancelled");
                            if (tagIdx >= 0) {
                                prefilledDescription = prefilledDescription.substring(0, tagIdx).replace("|", "").trim();
                            }
                        }
                        double reLat = rsRe.getDouble("latitude");
                        double reLng = rsRe.getDouble("longitude");
                        if (reLat > 0 && reLng > 0) {
                            initLat = reLat;
                            initLng = reLng;
                        }
                        if (prefilledLocation != null && !prefilledLocation.trim().isEmpty()) {
                            initLocation = prefilledLocation.trim();
                        }
                        if (paramVehicle == null || paramVehicle.isEmpty()) {
                            paramVehicle = prefilledVehicle;
                        }
                    }
                    rsRe.close();
                    psRe.close();
                } catch (Exception eRe) {
                    System.err.println("Notice fetching reRequest details: " + eRe.getMessage());
                }
            }

            // A. Fetch Active Service Requests for this user's vehicles (Pending, Accepted, In Progress, etc.)
            ps = conn.prepareStatement(
                "SELECT request_code, vehicle_number, status, breakdown_issue " +
                "FROM service_requests WHERE user_id = ? AND status NOT IN ('Completed', 'Cancelled', 'Rejected') " +
                "ORDER BY request_id DESC"
            );
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            while (rs.next()) {
                String vRaw = rs.getString("vehicle_number");
                if (vRaw != null && !vRaw.trim().isEmpty()) {
                    String vClean = vRaw.replaceAll("[\\s-]", "").toUpperCase();
                    if (!activeVehicleRequests.containsKey(vClean)) {
                        Map info = new HashMap();
                        info.put("code", rs.getString("request_code"));
                        info.put("status", rs.getString("status"));
                        info.put("issue", rs.getString("breakdown_issue"));
                        info.put("raw", vRaw);
                        activeVehicleRequests.put(vClean, info);
                    }
                }
            }
            rs.close();
            ps.close();

            // B. Fetch Vehicles
            ps = conn.prepareStatement(
                "SELECT vehicle_id, vehicle_number, vehicle_model, vehicle_type, fuel_type, is_primary " +
                "FROM user_vehicles WHERE user_id = ? ORDER BY is_primary DESC, vehicle_id ASC"
            );
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map v = new HashMap();
                v.put("id", rs.getInt("vehicle_id"));
                v.put("number", rs.getString("vehicle_number"));
                v.put("model", rs.getString("vehicle_model"));
                v.put("type", rs.getString("vehicle_type"));
                v.put("fuel", rs.getString("fuel_type"));
                v.put("is_primary", rs.getInt("is_primary"));
                userVehicles.add(v);
            }
            rs.close();
            ps.close();

            // C. Fetch Approved Mechanics for Selection
            ps = conn.prepareStatement(
                "SELECT mechanic_id, mechanic_code, workshop_name, owner_name, location, rating " +
                "FROM mechanics WHERE approval_status = 'Approved' ORDER BY workshop_name ASC"
            );
            rs = ps.executeQuery();
            while (rs.next()) {
                Map m = new HashMap();
                m.put("id", rs.getInt("mechanic_id"));
                m.put("code", rs.getString("mechanic_code"));
                m.put("name", rs.getString("workshop_name"));
                m.put("location", rs.getString("location"));
                m.put("rating", rs.getDouble("rating"));
                approvedMechanics.add(m);
            }
            rs.close();
            ps.close();
        }
    } catch (Exception ex) {
        System.err.println("Notice fetching request data: " + ex.getMessage());
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }

    int busyVehiclesCount = 0;
    for (int i = 0; i < userVehicles.size(); i++) {
        Map v = (Map) userVehicles.get(i);
        String vNum = (String) v.get("number");
        String vClean = (vNum != null) ? vNum.replaceAll("[\\s-]", "").toUpperCase() : "";
        if (activeVehicleRequests.containsKey(vClean)) {
            busyVehiclesCount++;
        }
    }
    boolean allVehiclesBusy = (!userVehicles.isEmpty() && busyVehiclesCount == userVehicles.size());

    boolean isSpecificTarget = (reqMechanicName != null && !reqMechanicName.isEmpty());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Request Assistance — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Leaflet CSS for Interactive Map -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />

    <!-- Core Theme & Page Specific Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/request-assistance.css?v=3.0">
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <div class="request-assistance-container">
                <!-- Outer White Card Wrapper matching Reference Screenshot -->
                <div class="request-main-card">
                    
                    <!-- Page Header: Title + Breadcrumb -->
                    <div class="request-header-row">
                        <div class="request-title-group">
                            <div class="request-icon-badge">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="request-title-text">
                                <h1>Request <span class="accent-orange">Assistance</span></h1>
                                <p>Raise a breakdown request and get help from nearby verified mechanics.</p>
                            </div>
                        </div>

                        <div class="request-breadcrumb">
                            <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="breadcrumb-link">
                                <i class="fa-solid fa-house"></i> Dashboard
                            </a>
                            <span class="breadcrumb-sep">></span>
                            <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="breadcrumb-link">
                                <i class="fa-solid fa-location-dot"></i> Find Mechanics
                            </a>
                            <span class="breadcrumb-sep">></span>
                            <span class="breadcrumb-current">Request Assistance</span>
                        </div>
                    </div>

                    <!-- 2-Column Grid: Left Form (68%) / Right Info & Emergency Cards (32%) -->
                    <div class="request-grid-layout">
                        
                        <!-- Left Column: The Request Form -->
                        <div class="request-form-col">
                            <% if (paramError != null && !paramError.trim().isEmpty()) { %>
                            <div class="alert-floating-banner" style="background: #FEF2F2; border: 1.5px solid #FCA5A5; border-left: 5px solid #DC2626; border-radius: 12px; padding: 14px 18px; margin-bottom: 20px; display: flex; align-items: center; gap: 12px; color: #991B1B; font-weight: 700; font-size: 13.5px; box-shadow: 0 4px 12px rgba(220, 38, 38, 0.08);">
                                <i class="fa-solid fa-circle-exclamation" style="font-size: 20px; color: #DC2626; flex-shrink: 0;"></i>
                                <div style="flex: 1;"><%= paramError %></div>
                            </div>
                            <% } %>

                            <% if (allVehiclesBusy) { %>
                            <div class="active-request-all-busy-banner" style="background: #FFF7ED; border: 1.5px solid #FDBA74; border-left: 5px solid #EA580C; border-radius: 14px; padding: 16px 20px; margin-bottom: 22px; box-shadow: 0 4px 12px rgba(234, 88, 12, 0.08);">
                                <div style="display: flex; align-items: flex-start; gap: 14px;">
                                    <div style="width: 44px; height: 44px; border-radius: 12px; background: #EA580C; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; box-shadow: 0 4px 10px rgba(234, 88, 12, 0.25);">
                                        <i class="fa-solid fa-ban"></i>
                                    </div>
                                    <div style="flex: 1;">
                                        <h4 style="margin: 0; font-size: 15.5px; font-weight: 800; color: #9A3412;">All Registered Vehicles Are Currently On Active Request</h4>
                                        <p style="margin: 4px 0 0 0; font-size: 13px; color: #7C2D12; line-height: 1.5;">
                                            Every vehicle registered under your account currently has an ongoing breakdown service in progress. You cannot create another request for a vehicle until its active ticket is marked as <strong>Completed</strong>.
                                        </p>
                                        <div style="margin-top: 12px; display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                                            <a href="${pageContext.request.contextPath}/user/my-requests.jsp" style="font-size: 12.5px; font-weight: 700; color: #FFFFFF; background: #EA580C; padding: 7px 16px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">
                                                <i class="fa-solid fa-clock-rotate-left"></i> Track Active Requests in My Requests
                                            </a>
                                            <a href="${pageContext.request.contextPath}/user/vehicles.jsp" style="font-size: 12.5px; font-weight: 700; color: #9A3412; background: #FFFFFF; border: 1.5px solid #FED7AA; padding: 7px 16px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">
                                                <i class="fa-solid fa-car-side"></i> Manage Vehicles
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <% } %>

                            <% if (isReRequestMode) { %>
                            <!-- Re-Request Assistance Intimation Callout Banner -->
                            <div style="background: #FFF7ED; border: 1.5px solid #FDBA74; border-left: 5px solid #F97316; border-radius: 14px; padding: 16px 20px; margin-bottom: 22px; box-shadow: 0 4px 14px rgba(249, 115, 22, 0.1);">
                                <div style="display: flex; align-items: flex-start; gap: 14px;">
                                    <div style="width: 40px; height: 40px; border-radius: 10px; background: #F97316; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; margin-top: 2px; box-shadow: 0 4px 10px rgba(249, 115, 22, 0.3);">
                                        <i class="fa-solid fa-rotate-right"></i>
                                    </div>
                                    <div style="flex: 1;">
                                        <div style="font-size: 15px; font-weight: 800; color: #9A3412;">
                                            Re-Requesting Roadside Assistance
                                        </div>
                                        <div style="font-size: 13px; color: #7C2D12; margin-top: 4px; line-height: 1.5;">
                                            Previous request <strong style="color: #1E293B;"><%= reRequestCode %></strong> was automatically cancelled because the mechanic did not advance the process in time. Your vehicle (<strong style="color: #EA580C;"><%= prefilledVehicle != null ? prefilledVehicle : "" %></strong>) and breakdown issue details have been pre-filled for immediate re-submission.
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <% } %>

                            <form id="assistanceForm" action="${pageContext.request.contextPath}/user/request-assistance-submit" method="POST" novalidate>
                                
                                <!-- Hidden inputs for Request Mode & Targeted Mechanic -->
                                <input type="hidden" name="requestMode" id="requestModeInput" value="<%= isSpecificTarget ? "Specific" : "Common" %>">
                                <input type="hidden" name="mechanicId" id="mechanicIdInput" value="<%= reqMechanicId != null ? reqMechanicId : "" %>">
                                <input type="hidden" name="mechanicName" id="mechanicNameInput" value="<%= reqMechanicName != null ? reqMechanicName : "" %>">
                                <input type="hidden" name="broadcastRadius" id="broadcastRadiusInput" value="10">

                                <!-- Hidden Inputs for Map Lat / Lng -->
                                <input type="hidden" name="latitude" id="latitudeInput" value="<%= initLat %>">
                                <input type="hidden" name="longitude" id="longitudeInput" value="<%= initLng %>">

                                <!-- STEP 0: Assistance Mode Selection (Specific vs Common Broadcast) -->
                                <div class="form-step-section" style="margin-bottom: 20px;">
                                    <div class="step-section-header">
                                        <span class="step-number-badge"><i class="fa-solid fa-route"></i></span>
                                        <h3 class="step-title">Assistance Mode</h3>
                                    </div>
                                    <p class="step-subtitle">Select whether to request assistance from a specific mechanic or broadcast to all surrounding mechanics.</p>
                                    
                                    <div class="step-content-box">
                                        <div class="request-mode-grid">
                                            <!-- Option 1: Specific Mechanic Request -->
                                            <div class="request-mode-card <%= isSpecificTarget ? "selected" : "" %>" id="modeCardSpecific" onclick="selectRequestMode('Specific');">
                                                <div class="mode-check-badge"><i class="fa-solid fa-check"></i></div>
                                                <div class="mode-icon-box">
                                                    <i class="fa-solid fa-user-gear"></i>
                                                </div>
                                                <div class="mode-text-box">
                                                    <h4 class="mode-title">Specific Mechanic</h4>
                                                    <p class="mode-desc">Direct request sent to a chosen authorized workshop</p>
                                                </div>
                                            </div>

                                            <!-- Option 2: Common Broadcast Assistance -->
                                            <div class="request-mode-card <%= !isSpecificTarget ? "selected" : "" %>" id="modeCardCommon" onclick="selectRequestMode('Common');">
                                                <div class="mode-check-badge"><i class="fa-solid fa-check"></i></div>
                                                <div class="mode-icon-box">
                                                    <i class="fa-solid fa-satellite-dish"></i>
                                                </div>
                                                <div class="mode-text-box">
                                                    <h4 class="mode-title">Common Broadcast Assistance</h4>
                                                    <p class="mode-desc">Broadcast to all nearby mechanics in your radius</p>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Specific Mode Container: Displays targeted mechanic or mechanic selector -->
                                        <div id="specificMechanicContainer" style="display: <%= isSpecificTarget ? "block" : "none" %>; margin-top: 14px;">
                                            <% if (isSpecificTarget) { %>
                                            <div class="selected-mechanic-callout" style="background: #FFF7ED; border: 1.5px solid #FDBA74; border-radius: 14px; padding: 14px 18px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                                                <div style="display: flex; align-items: center; gap: 12px;">
                                                    <div style="width: 42px; height: 42px; border-radius: 10px; background: #EA580C; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0;">
                                                        <i class="fa-solid fa-wrench"></i>
                                                    </div>
                                                    <div>
                                                        <div style="font-size: 11px; font-weight: 700; color: #C2410C; text-transform: uppercase; letter-spacing: 0.5px;">Targeted Workshop</div>
                                                        <div style="font-size: 15.5px; font-weight: 800; color: #1E293B;" id="dispMechanicName"><%= reqMechanicName %></div>
                                                    </div>
                                                </div>
                                                <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" style="font-size: 12px; font-weight: 700; color: #EA580C; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; background: #FFFFFF; border: 1px solid #FED7AA; border-radius: 8px;">
                                                    <i class="fa-solid fa-arrow-rotate-left"></i> Change Mechanic
                                                </a>
                                            </div>
                                            <% } else { %>
                                            <div style="background: #F8FAFC; border: 1.5px solid #E2E8F0; border-radius: 12px; padding: 14px 16px;">
                                                <label style="font-size: 12.5px; font-weight: 700; color: #334155; margin-bottom: 6px; display: block;">
                                                    <i class="fa-solid fa-wrench" style="color: #F97316;"></i> Select Workshop / Mechanic <span style="color: #EF4444;">*</span>
                                                </label>
                                                <div class="vehicle-dropdown-wrapper">
                                                    <i class="fa-solid fa-warehouse vehicle-dropdown-icon"></i>
                                                    <select id="specificMechanicSelect" class="vehicle-select-input" onchange="onSelectSpecificMechanic(this);">
                                                        <option value="" disabled selected>-- Select an Approved Mechanic --</option>
                                                        <% for (int i = 0; i < approvedMechanics.size(); i++) { 
                                                            Map m = (Map) approvedMechanics.get(i);
                                                            String mName = (String) m.get("name");
                                                            String mLoc = (String) m.get("location");
                                                            int mId = (Integer) m.get("id");
                                                        %>
                                                        <option value="<%= mName %>" data-id="<%= mId %>"><%= mName %> (<%= mLoc %>)</option>
                                                        <% } %>
                                                    </select>
                                                    <i class="fa-solid fa-chevron-down vehicle-dropdown-arrow"></i>
                                                </div>
                                            </div>
                                            <% } %>
                                        </div>

                                        <!-- Common Broadcast Mode Container: Radius Selector & First-Accept Notice -->
                                        <div id="commonBroadcastContainer" style="display: <%= !isSpecificTarget ? "block" : "none" %>; margin-top: 14px;">
                                            <div class="radius-selector-card">
                                                <div class="radius-label-group">
                                                    <i class="fa-solid fa-satellite-dish" style="color: #F97316;"></i>
                                                    <span>Surrounding Search Radius:</span>
                                                </div>
                                                <div class="radius-pills-row">
                                                    <button type="button" class="radius-pill" data-radius="5" onclick="setBroadcastRadius(5);">5 km</button>
                                                    <button type="button" class="radius-pill active" data-radius="10" onclick="setBroadcastRadius(10);">10 km (Default)</button>
                                                    <button type="button" class="radius-pill" data-radius="15" onclick="setBroadcastRadius(15);">15 km</button>
                                                    <button type="button" class="radius-pill" data-radius="25" onclick="setBroadcastRadius(25);">25 km</button>
                                                </div>
                                            </div>
                                            <span style="font-size: 11.5px; color: #64748B; display: flex; align-items: center; gap: 6px; margin-top: 6px;">
                                                <i class="fa-solid fa-circle-info" style="color: #3B82F6;"></i> Request is sent to all mechanics in radius. Once the first mechanic accepts, it automatically disappears for others.
                                            </span>
                                        </div>

                                    </div>
                                </div>
                                
                                <!-- STEP 1: Select Vehicle (FORCED SELECTION, NO DEFAULT) -->
                                <div class="form-step-section">
                                    <div class="step-section-header">
                                        <span class="step-number-badge">1</span>
                                        <h3 class="step-title">Select Vehicle</h3>
                                    </div>
                                    <p class="step-subtitle">Choose the vehicle that needs breakdown assistance.</p>
                                    
                                    <div class="step-content-box">
                                        <div class="vehicle-select-row">
                                            <div class="vehicle-dropdown-wrapper">
                                                <i class="fa-solid fa-car-side vehicle-dropdown-icon"></i>
                                                <select name="vehicleNo" id="vehicleSelect" class="vehicle-select-input" required>
                                                    <option value="" disabled <%= (paramVehicle == null || paramVehicle.isEmpty()) ? "selected" : "" %>>-- Select Your Vehicle --</option>
                                                    <% for (int i = 0; i < userVehicles.size(); i++) { 
                                                        Map v = (Map) userVehicles.get(i);
                                                        String vNum = (String) v.get("number");
                                                        String vMod = (String) v.get("model");
                                                        String vFuel = (String) v.get("fuel");
                                                        String vClean = (vNum != null) ? vNum.replaceAll("[\\s-]", "").toUpperCase() : "";
                                                        boolean isPreselected = (paramVehicle != null && vNum != null && vNum.replaceAll("[\\s-]", "").equalsIgnoreCase(paramVehicle.replaceAll("[\\s-]", "")));
                                                        boolean isOnRequest = activeVehicleRequests.containsKey(vClean);
                                                        if (isReRequestMode && isPreselected) {
                                                            isOnRequest = false;
                                                        }
                                                        if (isOnRequest) {
                                                            continue; // Do not show vehicle if already in active assistance
                                                        }
                                                        String dispText = vNum + " \u2014 " + vMod + " (" + vFuel + ")";
                                                    %>
                                                    <option value="<%= vNum %>"
                                                            data-is-on-request="false"
                                                            <%= isPreselected ? "selected" : "" %>>
                                                        <%= dispText %>
                                                    </option>
                                                    <% } %>
                                                </select>
                                                <i class="fa-solid fa-chevron-down vehicle-dropdown-arrow"></i>
                                            </div>

                                            <a href="${pageContext.request.contextPath}/user/vehicles.jsp" class="btn-add-vehicle">
                                                <i class="fa-solid fa-plus"></i> Add New Vehicle
                                            </a>
                                        </div>

                                        <!-- Vehicle On-Request Interactive Warning Notice -->
                                        <div id="activeVehicleWarningBox" style="display: none; background: #FFF7ED; border: 1.5px solid #FDBA74; border-left: 5px solid #EA580C; border-radius: 12px; padding: 14px 18px; margin-top: 12px;">
                                            <div style="display: flex; align-items: flex-start; gap: 12px;">
                                                <div style="width: 38px; height: 38px; border-radius: 10px; background: #EA580C; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; margin-top: 2px; box-shadow: 0 4px 10px rgba(234, 88, 12, 0.25);">
                                                    <i class="fa-solid fa-triangle-exclamation"></i>
                                                </div>
                                                <div style="flex: 1;">
                                                    <div style="font-size: 14px; font-weight: 800; color: #9A3412;">Vehicle Currently On Active Request</div>
                                                    <div style="font-size: 12.5px; color: #7C2D12; margin-top: 3px; line-height: 1.45;">
                                                        Vehicle <strong id="activeWarningVehNum">TN 45 BT 6229</strong> already has an ongoing breakdown request (<strong id="activeWarningReqCode">SR0474</strong> &bull; <span id="activeWarningReqStatus" style="font-weight: 700; color: #C2410C;">Accepted</span>). You cannot submit another request for this vehicle until the existing service is completed.
                                                    </div>
                                                    <div style="margin-top: 10px; display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                                                        <a href="${pageContext.request.contextPath}/user/my-requests.jsp" style="font-size: 12px; font-weight: 700; color: #FFFFFF; background: #EA580C; padding: 6px 14px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">
                                                            <i class="fa-solid fa-clock-rotate-left"></i> Track Existing Request
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <span class="field-error-hint" id="errVehicle" style="display: none; font-size: 11.5px; color: #EF4444; margin-top: 4px;">
                                            <i class="fa-solid fa-triangle-exclamation"></i> Please select an available vehicle from the list.
                                        </span>
                                    </div>
                                </div>

                                <!-- STEP 2: Service Issue (5x2 Grid) -->
                                <div class="form-step-section" style="margin-top: 18px;">
                                    <div class="step-section-header">
                                        <span class="step-number-badge">2</span>
                                        <h3 class="step-title">Service Issue</h3>
                                    </div>
                                    <p class="step-subtitle">Select the problem you are facing with your vehicle.</p>
                                    
                                    <div class="step-content-box">
                                        <!-- Hidden Input to store selected issue -->
                                        <input type="hidden" name="issueType" id="selectedIssueInput" value="<%= (prefilledIssue != null && !prefilledIssue.trim().isEmpty()) ? prefilledIssue.trim() : "Engine Overheating" %>">
                                        
                                        <div class="issues-grid-5x2">
                                            <!-- 1. Engine Overheating (Default Selected) -->
                                            <div class="issue-card selected" data-issue="Engine Overheating">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-car-burst"></i>
                                                </div>
                                                <p class="issue-label">Engine<br>Overheating</p>
                                            </div>

                                            <!-- 2. Tyre / Puncture -->
                                            <div class="issue-card" data-issue="Tyre / Puncture">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-compact-disc"></i>
                                                </div>
                                                <p class="issue-label">Tyre /<br>Puncture</p>
                                            </div>

                                            <!-- 3. Battery Jump Start -->
                                            <div class="issue-card" data-issue="Battery Jump Start">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-car-battery"></i>
                                                </div>
                                                <p class="issue-label">Battery<br>Jump Start</p>
                                            </div>

                                            <!-- 4. Electrical Issue -->
                                            <div class="issue-card" data-issue="Electrical Issue">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-bolt"></i>
                                                </div>
                                                <p class="issue-label">Electrical<br>Issue</p>
                                            </div>

                                            <!-- 5. Clutch & Gear Problem -->
                                            <div class="issue-card" data-issue="Clutch & Gear Problem">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-gear"></i>
                                                </div>
                                                <p class="issue-label">Clutch &<br>Gear Problem</p>
                                            </div>

                                            <!-- 6. Brake Problem -->
                                            <div class="issue-card" data-issue="Brake Problem">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-circle-exclamation"></i>
                                                </div>
                                                <p class="issue-label">Brake<br>Problem</p>
                                            </div>

                                            <!-- 7. Cooling System -->
                                            <div class="issue-card" data-issue="Cooling System">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-temperature-arrow-up"></i>
                                                </div>
                                                <p class="issue-label">Cooling<br>System</p>
                                            </div>

                                            <!-- 8. Fuel Issue -->
                                            <div class="issue-card" data-issue="Fuel Issue">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-gas-pump"></i>
                                                </div>
                                                <p class="issue-label">Fuel<br>Issue</p>
                                            </div>

                                            <!-- 9. General Service -->
                                            <div class="issue-card" data-issue="General Service">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-screwdriver-wrench"></i>
                                                </div>
                                                <p class="issue-label">General<br>Service</p>
                                            </div>

                                            <!-- 10. Other Issue -->
                                            <div class="issue-card" data-issue="Other Issue">
                                                <div class="selected-check-badge">
                                                    <i class="fa-solid fa-check"></i>
                                                </div>
                                                <div class="issue-icon-wrap">
                                                    <i class="fa-solid fa-ellipsis"></i>
                                                </div>
                                                <p class="issue-label">Other<br>Issue</p>
                                            </div>
                                        </div>

                                        <!-- Custom Issue Slide-down for Other Issue -->
                                        <div class="custom-issue-box" id="customIssueContainer">
                                            <label class="custom-issue-label">Specify Your Problem Details <span style="color:#DC2626;">*</span></label>
                                            <input type="text" name="customIssue" id="customIssueInput" class="custom-issue-input" placeholder="E.g. Broken suspension, steering lock, ignition coil failure..." maxlength="100">
                                        </div>
                                    </div>
                                </div>

                                <!-- STEP 3: Your Breakdown Location (BIG MAP + TWO-WAY ADDRESS/GPS SYNC) -->
                                <div class="form-step-section" style="margin-top: 18px;">
                                    <div class="step-section-header">
                                        <span class="step-number-badge">3</span>
                                        <h3 class="step-title">Your Breakdown Location</h3>
                                    </div>
                                    <p class="step-subtitle">Provide your breakdown spot. Use GPS, enter an address, or drag/click the pin on the map.</p>
                                    
                                    <div class="step-content-box">
                                        
                                        <!-- Location Controls Row: GPS Button & Address Input with Locate Button -->
                                        <div class="location-top-controls">
                                            <!-- GPS Button -->
                                            <button type="button" class="btn-loc-gps-action" id="btnUseGps">
                                                <i class="fa-solid fa-location-crosshairs"></i>
                                                <span>Use Current Location</span>
                                            </button>

                                            <!-- Address Search Input -->
                                            <div>
                                                <div class="address-input-wrapper">
                                                    <i class="fa-solid fa-location-dot address-pin-icon"></i>
                                                    <input type="text" name="locationAddress" id="locationAddressInput" class="address-text-field" placeholder="Enter landmark, road or area (e.g., NSR Road, Saibaba Colony)..." value="<%= initLocation %>" required autocomplete="off">
                                                    <button type="button" class="btn-search-address" id="btnGeocodeSearch" title="Locate on Map">
                                                        <i class="fa-solid fa-magnifying-glass"></i>
                                                        <span>Locate</span>
                                                    </button>
                                                </div>
                                                <span class="address-status-hint" id="addressStatusHint">
                                                    <i class="fa-solid fa-circle-info"></i> Enter an address to locate on map, or click/drag the pin to fetch the address.
                                                </span>
                                            </div>
                                        </div>

                                        <!-- Big Interactive Map Box (Height: 300px) -->
                                        <div class="interactive-map-large-box">
                                            <div id="leafletMapContainer"></div>
                                            
                                            <!-- Fullscreen Toggle -->
                                            <button type="button" class="map-action-float-btn" id="btnMapFullscreen" title="Toggle Fullscreen">
                                                <i class="fa-solid fa-expand"></i>
                                            </button>

                                            <!-- Floating Coordinates Badge -->
                                            <div class="map-floating-badge" id="mapCoordsBadge">
                                                <i class="fa-solid fa-crosshairs"></i> Lat: <span id="dispLat"><%= String.format("%.4f", initLat) %></span>, Lng: <span id="dispLng"><%= String.format("%.4f", initLng) %></span>
                                            </div>
                                        </div>

                                    </div>
                                </div>

                                <!-- STEP 4: Additional Details (Optional) -->
                                <div class="form-step-section" style="margin-top: 18px;">
                                    <div class="step-section-header">
                                        <span class="step-number-badge">4</span>
                                        <h3 class="step-title">Additional Details <span class="optional-badge">(Optional)</span></h3>
                                    </div>
                                    <p class="step-subtitle">Provide any additional information that can help the mechanic.</p>
                                    
                                    <div class="step-content-box">
                                        <div class="details-textarea-wrap">
                                            <textarea name="additionalDetails" id="additionalDetails" class="details-textarea" maxlength="250" placeholder="Eg: Vehicle stopped suddenly, engine overheating, need immediate assistance, etc."><%= (prefilledDescription != null && !prefilledDescription.trim().isEmpty()) ? prefilledDescription.trim() : "" %></textarea>
                                            <div class="char-counter-text">
                                                <span id="charCount">0</span> / 250
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Bottom Form Actions: Cancel & Submit Request -->
                                <div class="form-actions-row">
                                    <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="btn-cancel-request">
                                        <i class="fa-solid fa-arrow-left"></i> Back
                                    </a>

                                    <button type="submit" id="btnSubmitRequest" class="btn-submit-request">
                                        <i class="fa-solid fa-paper-plane"></i> Submit Request
                                    </button>
                                </div>

                            </form>
                        </div>

                    </div>
                </div>
            </div>

        </main>
    </div>

    <!-- Dynamic Toast Notification Container -->
    <div id="toastNotification" class="request-toast" style="display: none;">
        <i id="toastIcon" class="fa-solid fa-circle-check"></i>
        <span id="toastMessage">Request submitted!</span>
    </div>

    <!-- Leaflet JS -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

    <!-- Page Interactive Logic -->
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        
        // =========================================================================
        // 1. Request Mode Controller (Specific vs Common Broadcast)
        // =========================================================================
        const modeCardSpecific = document.getElementById('modeCardSpecific');
        const modeCardCommon = document.getElementById('modeCardCommon');
        const requestModeInput = document.getElementById('requestModeInput');
        const specificContainer = document.getElementById('specificMechanicContainer');
        const commonContainer = document.getElementById('commonBroadcastContainer');
        const mechanicNameInput = document.getElementById('mechanicNameInput');
        const broadcastRadiusInput = document.getElementById('broadcastRadiusInput');

        window.selectRequestMode = function(mode) {
            requestModeInput.value = mode;
            if (mode === 'Specific') {
                modeCardSpecific.classList.add('selected');
                modeCardCommon.classList.remove('selected');
                specificContainer.style.display = 'block';
                commonContainer.style.display = 'none';
                if (radiusCircle && map) {
                    map.removeLayer(radiusCircle);
                }
            } else {
                modeCardCommon.classList.add('selected');
                modeCardSpecific.classList.remove('selected');
                specificContainer.style.display = 'none';
                commonContainer.style.display = 'block';
                mechanicNameInput.value = 'Nearby Mechanics';
                drawRadiusCircle();
            }
        };

        window.onSelectSpecificMechanic = function(sel) {
            const opt = sel.options[sel.selectedIndex];
            if (opt && opt.value) {
                mechanicNameInput.value = opt.value;
                document.getElementById('mechanicIdInput').value = opt.getAttribute('data-id') || '';
            }
        };

        window.setBroadcastRadius = function(radiusKm) {
            broadcastRadiusInput.value = radiusKm;
            document.querySelectorAll('.radius-pill').forEach(function(pill) {
                if (parseInt(pill.getAttribute('data-radius')) === radiusKm) {
                    pill.classList.add('active');
                } else {
                    pill.classList.remove('active');
                }
            });
            drawRadiusCircle();
            showToast('Search radius set to ' + radiusKm + ' km', 'success');
        };

        // =========================================================================
        // 2. Issue Card Selection Logic
        // =========================================================================
        const issueCards = document.querySelectorAll('.issue-card');
        const selectedIssueInput = document.getElementById('selectedIssueInput');
        const customIssueContainer = document.getElementById('customIssueContainer');
        const customIssueInput = document.getElementById('customIssueInput');

        <% if (prefilledIssue != null && !prefilledIssue.trim().isEmpty()) { %>
        // Pre-select matching issue card for re-request
        const targetPreIssue = "<%= prefilledIssue.trim() %>";
        let matchedPreIssue = false;
        issueCards.forEach(function(card) {
            if (card.getAttribute('data-issue').toLowerCase() === targetPreIssue.toLowerCase()) {
                issueCards.forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');
                matchedPreIssue = true;
            }
        });
        if (!matchedPreIssue && targetPreIssue !== '') {
            issueCards.forEach(c => c.classList.remove('selected'));
            const otherCard = document.querySelector('.issue-card[data-issue="Other Issue"]');
            if (otherCard) otherCard.classList.add('selected');
            if (customIssueContainer) customIssueContainer.classList.add('active');
            if (customIssueInput) customIssueInput.value = targetPreIssue;
        }
        <% } %>

        issueCards.forEach(function(card) {
            card.addEventListener('click', function() {
                issueCards.forEach(c => c.classList.remove('selected'));
                this.classList.add('selected');
                const issueVal = this.getAttribute('data-issue');
                selectedIssueInput.value = issueVal;

                if (issueVal === 'Other Issue') {
                    customIssueContainer.classList.add('active');
                    customIssueInput.focus();
                } else {
                    customIssueContainer.classList.remove('active');
                }
            });
        });

        // =========================================================================
        // 3. Character Counter for Additional Details
        // =========================================================================
        const textarea = document.getElementById('additionalDetails');
        const charCount = document.getElementById('charCount');
        if (textarea && charCount) {
            charCount.textContent = textarea.value.length;
            textarea.addEventListener('input', function() {
                charCount.textContent = this.value.length;
            });
        }

        // =========================================================================
        // 4. Leaflet Map, Marker & Two-Way Location/Address Sync
        // =========================================================================
        let currentLat = <%= initLat %>;
        let currentLng = <%= initLng %>;
        let map = null;
        let marker = null;
        let radiusCircle = null;

        const latitudeInput = document.getElementById('latitudeInput');
        const longitudeInput = document.getElementById('longitudeInput');
        const dispLat = document.getElementById('dispLat');
        const dispLng = document.getElementById('dispLng');
        const locationAddressInput = document.getElementById('locationAddressInput');
        const addressStatusHint = document.getElementById('addressStatusHint');
        const btnGeocodeSearch = document.getElementById('btnGeocodeSearch');
        const btnUseGps = document.getElementById('btnUseGps');
        const mapContainer = document.getElementById('leafletMapContainer');

        function updateCoordinatesState(lat, lng) {
            currentLat = lat;
            currentLng = lng;
            latitudeInput.value = lat.toFixed(6);
            longitudeInput.value = lng.toFixed(6);
            dispLat.textContent = lat.toFixed(4);
            dispLng.textContent = lng.toFixed(4);
        }

        function drawRadiusCircle() {
            if (!map || requestModeInput.value !== 'Common') return;
            const radiusKm = parseInt(broadcastRadiusInput.value || 10);
            if (radiusCircle) {
                map.removeLayer(radiusCircle);
            }
            radiusCircle = L.circle([currentLat, currentLng], {
                radius: radiusKm * 1000,
                color: '#F97316',
                fillColor: '#F97316',
                fillOpacity: 0.12,
                weight: 1.5,
                dashArray: '4, 4'
            }).addTo(map);
        }

        // Reverse Geocode: Coordinates -> Address
        let reverseTimeout = null;
        function reverseGeocodeCoordinates(lat, lng) {
            clearTimeout(reverseTimeout);
            addressStatusHint.innerHTML = '<i class="fa-solid fa-spinner fa-spin" style="color: #F97316;"></i> Fetching address from GPS location...';
            
            reverseTimeout = setTimeout(function() {
                fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng + '&zoom=18&addressdetails=1')
                    .then(res => res.json())
                    .then(data => {
                        if (data && data.display_name) {
                            const addr = data.address || {};
                            const road = addr.road || addr.suburb || addr.neighbourhood || '';
                            const city = addr.city || addr.town || addr.county || '';
                            const state = addr.state || '';
                            const postcode = addr.postcode || '';
                            
                            let cleanAddr = '';
                            if (road && city) cleanAddr = road + ', ' + city + (postcode ? ' - ' + postcode : '');
                            else cleanAddr = data.display_name.split(',').slice(0, 3).join(', ');
                            
                            locationAddressInput.value = cleanAddr.trim();
                            addressStatusHint.innerHTML = '<span style="color: #10B981;"><i class="fa-solid fa-circle-check"></i> Address updated from map position</span>';
                        } else {
                            addressStatusHint.innerHTML = '<span style="color: #64748B;"><i class="fa-solid fa-circle-info"></i> Pin updated to: ' + lat.toFixed(4) + ', ' + lng.toFixed(4) + '</span>';
                        }
                    })
                    .catch(err => {
                        console.warn('Reverse geocode error:', err);
                        addressStatusHint.innerHTML = '<span style="color: #64748B;"><i class="fa-solid fa-location-dot"></i> Coordinates pinned: ' + lat.toFixed(4) + ', ' + lng.toFixed(4) + '</span>';
                    });
            }, 300);
        }

        // Forward Geocode: Address -> Coordinates & Map update
        let forwardTimeout = null;
        function forwardGeocodeAddress(addressStr) {
            if (!addressStr || addressStr.trim().length < 3) return;
            addressStatusHint.innerHTML = '<i class="fa-solid fa-spinner fa-spin" style="color: #F97316;"></i> Locating address on map...';
            
            fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(addressStr.trim()) + '&limit=1')
                .then(res => res.json())
                .then(data => {
                    if (data && data.length > 0) {
                        const newLat = parseFloat(data[0].lat);
                        const newLng = parseFloat(data[0].lon);
                        updateCoordinatesState(newLat, newLng);

                        if (map) {
                            map.setView([newLat, newLng], 15);
                            if (marker) {
                                marker.setLatLng([newLat, newLng]);
                            }
                            drawRadiusCircle();
                        }
                        addressStatusHint.innerHTML = '<span style="color: #10B981;"><i class="fa-solid fa-circle-check"></i> Pin updated to match entered address!</span>';
                        showToast('Map centered at entered address!', 'success');
                    } else {
                        addressStatusHint.innerHTML = '<span style="color: #EF4444;"><i class="fa-solid fa-circle-exclamation"></i> Could not find location. Try entering city name.</span>';
                    }
                })
                .catch(err => {
                    console.warn('Forward geocode error:', err);
                    addressStatusHint.innerHTML = '<span style="color: #64748B;"><i class="fa-solid fa-circle-info"></i> You can click on the map to pin your spot.</span>';
                });
        }

        // Initialize Map
        if (mapContainer && typeof L !== 'undefined') {
            try {
                map = L.map('leafletMapContainer', {
                    center: [currentLat, currentLng],
                    zoom: 14,
                    zoomControl: true,
                    attributionControl: false
                });

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    maxZoom: 19
                }).addTo(map);

                // Custom Orange Marker
                const orangeMarkerIcon = L.divIcon({
                    className: 'custom-leaflet-marker',
                    html: '<div style="background: #F97316; width: 34px; height: 34px; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.45); border: 2.5px solid #FFFFFF;"><i class="fa-solid fa-car-burst" style="color: #FFFFFF; transform: rotate(45deg); font-size: 15px;"></i></div>',
                    iconSize: [34, 34],
                    iconAnchor: [17, 34]
                });

                marker = L.marker([currentLat, currentLng], {
                    draggable: true,
                    icon: orangeMarkerIcon
                }).addTo(map);

                // Marker Dragend Event
                marker.on('dragend', function() {
                    const pos = marker.getLatLng();
                    updateCoordinatesState(pos.lat, pos.lng);
                    drawRadiusCircle();
                    reverseGeocodeCoordinates(pos.lat, pos.lng);
                });

                // Map Click Event: Move marker & fetch address
                map.on('click', function(e) {
                    const lat = e.latlng.lat;
                    const lng = e.latlng.lng;
                    marker.setLatLng([lat, lng]);
                    updateCoordinatesState(lat, lng);
                    drawRadiusCircle();
                    reverseGeocodeCoordinates(lat, lng);
                });

                if (requestModeInput.value === 'Common') {
                    drawRadiusCircle();
                }

            } catch (err) {
                console.warn('Leaflet initialization notice:', err);
            }
        }

        // Geocode Button Click & Enter Key on Address Input
        if (btnGeocodeSearch && locationAddressInput) {
            btnGeocodeSearch.addEventListener('click', function() {
                forwardGeocodeAddress(locationAddressInput.value);
            });

            locationAddressInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    forwardGeocodeAddress(locationAddressInput.value);
                }
            });

            // Debounced forward geocoding on typing
            locationAddressInput.addEventListener('input', function() {
                clearTimeout(forwardTimeout);
                const val = this.value.trim();
                if (val.length >= 4) {
                    forwardTimeout = setTimeout(function() {
                        forwardGeocodeAddress(val);
                    }, 1000);
                }
            });
        }

        // GPS Geolocation Button
        if (btnUseGps) {
            btnUseGps.addEventListener('click', function() {
                if (!navigator.geolocation) {
                    showToast('Geolocation is not supported by your browser', 'error');
                    return;
                }

                const originalHtml = btnUseGps.innerHTML;
                btnUseGps.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Locating...';
                btnUseGps.disabled = true;

                navigator.geolocation.getCurrentPosition(
                    function(position) {
                        const lat = position.coords.latitude;
                        const lng = position.coords.longitude;
                        updateCoordinatesState(lat, lng);

                        if (map) {
                            map.setView([lat, lng], 16);
                            if (marker) marker.setLatLng([lat, lng]);
                            drawRadiusCircle();
                        }

                        reverseGeocodeCoordinates(lat, lng);
                        showToast('Current GPS coordinates acquired!', 'success');

                        btnUseGps.innerHTML = originalHtml;
                        btnUseGps.disabled = false;
                    },
                    function(error) {
                        btnUseGps.innerHTML = originalHtml;
                        btnUseGps.disabled = false;
                        showToast('Unable to detect GPS: ' + error.message, 'error');
                    },
                    { enableHighAccuracy: true, timeout: 8000 }
                );
            });
        }

        // Fullscreen Toggle for Large Map
        const btnMapFullscreen = document.getElementById('btnMapFullscreen');
        const mapBox = document.querySelector('.interactive-map-large-box');
        if (btnMapFullscreen && mapBox) {
            btnMapFullscreen.addEventListener('click', function() {
                if (!document.fullscreenElement) {
                    mapBox.requestFullscreen().catch(err => {
                        console.log('Fullscreen error:', err);
                    });
                } else {
                    document.exitFullscreen();
                }
            });
        }

        // =========================================================================
        // 5. Form Submission Validation (Forced Vehicle Selection, Mode Validation)
        // =========================================================================
        const assistanceForm = document.getElementById('assistanceForm');
        const btnSubmitRequest = document.getElementById('btnSubmitRequest');
        const vehicleSelect = document.getElementById('vehicleSelect');
        const errVehicle = document.getElementById('errVehicle');
        const activeWarningBox = document.getElementById('activeVehicleWarningBox');
        const isAllVehiclesBusy = <%= allVehiclesBusy %>;

        if (isAllVehiclesBusy && btnSubmitRequest) {
            btnSubmitRequest.disabled = true;
            btnSubmitRequest.style.opacity = '0.5';
            btnSubmitRequest.style.cursor = 'not-allowed';
            btnSubmitRequest.title = 'All registered vehicles currently have active breakdown requests in progress.';
        }

        function checkSelectedVehicleActive() {
            if (!vehicleSelect) return;
            const opt = vehicleSelect.options[vehicleSelect.selectedIndex];
            if (!opt) return;

            const isOnRequest = opt.getAttribute('data-is-on-request') === 'true';
            if (isOnRequest) {
                const code = opt.getAttribute('data-request-code') || '';
                const status = opt.getAttribute('data-request-status') || 'Active';
                const vehNum = vehicleSelect.value;
                if (document.getElementById('activeWarningVehNum')) document.getElementById('activeWarningVehNum').textContent = vehNum;
                if (document.getElementById('activeWarningReqCode')) document.getElementById('activeWarningReqCode').textContent = code;
                if (document.getElementById('activeWarningReqStatus')) document.getElementById('activeWarningReqStatus').textContent = status;
                if (activeWarningBox) activeWarningBox.style.display = 'block';
                if (btnSubmitRequest) {
                    btnSubmitRequest.disabled = true;
                    btnSubmitRequest.style.opacity = '0.5';
                    btnSubmitRequest.style.cursor = 'not-allowed';
                    btnSubmitRequest.title = 'Vehicle ' + vehNum + ' is currently on active request (' + code + ')';
                }
                showToast('Vehicle ' + vehNum + ' already has an ongoing request (' + code + ')', 'error');
            } else {
                if (activeWarningBox) activeWarningBox.style.display = 'none';
                if (btnSubmitRequest && !isAllVehiclesBusy) {
                    btnSubmitRequest.disabled = false;
                    btnSubmitRequest.style.opacity = '1';
                    btnSubmitRequest.style.cursor = 'pointer';
                    btnSubmitRequest.title = '';
                }
                if (errVehicle) errVehicle.style.display = 'none';
                vehicleSelect.style.borderColor = '#CBD5E1';
            }
        }

        if (vehicleSelect) {
            vehicleSelect.addEventListener('change', checkSelectedVehicleActive);
            // Run check on initial load
            checkSelectedVehicleActive();
        }

        if (assistanceForm && btnSubmitRequest) {
            assistanceForm.addEventListener('submit', function(e) {
                e.preventDefault();

                // Validate Vehicle Selection (FORCED)
                if (!vehicleSelect.value || vehicleSelect.value.trim() === '') {
                    errVehicle.style.display = 'block';
                    vehicleSelect.style.borderColor = '#EF4444';
                    vehicleSelect.focus();
                    showToast('Please select your vehicle from the dropdown', 'error');
                    return;
                }

                // Block if vehicle is currently on an active request
                const selectedOpt = vehicleSelect.options[vehicleSelect.selectedIndex];
                if (selectedOpt && selectedOpt.getAttribute('data-is-on-request') === 'true') {
                    const code = selectedOpt.getAttribute('data-request-code') || '';
                    const status = selectedOpt.getAttribute('data-request-status') || '';
                    showToast('Vehicle ' + vehicleSelect.value + ' is already on request (' + code + '). You cannot raise another request for this vehicle.', 'error');
                    if (activeWarningBox) {
                        activeWarningBox.style.display = 'block';
                        activeWarningBox.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                    return;
                } else {
                    errVehicle.style.display = 'none';
                    vehicleSelect.style.borderColor = '#CBD5E1';
                }

                // Validate Specific Mechanic Selection
                if (requestModeInput.value === 'Specific') {
                    const mechName = mechanicNameInput.value.trim();
                    if (!mechName || mechName === 'Nearby Mechanics') {
                        showToast('Please select an authorized mechanic for specific request', 'error');
                        const specSelect = document.getElementById('specificMechanicSelect');
                        if (specSelect) specSelect.focus();
                        return;
                    }
                }

                // Validate Custom Issue
                if (selectedIssueInput.value === 'Other Issue') {
                    const customVal = customIssueInput.value.trim();
                    if (!customVal) {
                        showToast('Please specify your breakdown problem', 'error');
                        customIssueInput.focus();
                        return;
                    }
                }

                // Validate Location Address
                if (!locationAddressInput.value || locationAddressInput.value.trim() === '') {
                    showToast('Please provide your breakdown location address', 'error');
                    locationAddressInput.focus();
                    return;
                }

                btnSubmitRequest.disabled = true;
                btnSubmitRequest.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Submitting...';

                const formData = new FormData(assistanceForm);
                const params = new URLSearchParams();
                for (const pair of formData.entries()) {
                    params.append(pair[0], pair[1]);
                }

                fetch(assistanceForm.action, {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                    },
                    body: params.toString()
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        showToast('Breakdown request ' + data.requestCode + ' raised successfully!', 'success');
                        setTimeout(function() {
                            window.location.href = data.redirectUrl || ('${pageContext.request.contextPath}/user/my-requests.jsp?msg=request_submitted&code=' + data.requestCode);
                        }, 1200);
                    } else {
                        showToast(data.message || 'Submission failed. Please try again.', 'error');
                        btnSubmitRequest.disabled = false;
                        btnSubmitRequest.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Submit Request';
                    }
                })
                .catch(err => {
                    console.error('Submission error:', err);
                    assistanceForm.submit();
                });
            });
        }

        // =========================================================================
        // 6. Toast Helper
        // =========================================================================
        function showToast(message, type) {
            const toast = document.getElementById('toastNotification');
            const icon = document.getElementById('toastIcon');
            const msg = document.getElementById('toastMessage');

            toast.className = 'request-toast ' + (type === 'error' ? 'error' : 'success');
            icon.className = 'fa-solid ' + (type === 'error' ? 'fa-circle-exclamation' : 'fa-circle-check');
            msg.textContent = message;

            toast.style.display = 'flex';
            setTimeout(function() {
                toast.style.display = 'none';
            }, 3500);
        }

    });
    </script>
</body>
</html>
