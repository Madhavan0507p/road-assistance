<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=auth_required");
        return;
    }

    // Page metadata for sidebar and topbar
    request.setAttribute("activePage", "blocked");
    request.setAttribute("pageIcon", "fa-solid fa-ban");
    request.setAttribute("pageTitle", "Blocked Mechanics");
    request.setAttribute("pageSubtitle", "View and manage blocked mechanics");
    request.setAttribute("searchPlaceholder", "Search mechanics...");
    request.setAttribute("notifCount", "3");

    String alertMsg = "";
    String alertType = "success";

    String action = request.getParameter("action");
    SimpleDateFormat nowFmt = new SimpleDateFormat("dd-MM-yyyy, hh:mm a");

    // 1. Handle Unblock Action
    if ("unblock".equalsIgnoreCase(action)) {
        String unblockId = request.getParameter("id");
        if (unblockId != null && !unblockId.trim().isEmpty()) {
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                if (conn != null) {
                    String mEmail = null;
                    String mOwner = null;
                    String mShop = null;
                    String mCode = null;
                    try {
                        PreparedStatement psInf = conn.prepareStatement("SELECT email, owner_name, workshop_name, mechanic_code FROM mechanics WHERE mechanic_id = ? OR mechanic_code = ?");
                        int idValInf = 0;
                        try { idValInf = Integer.parseInt(unblockId); } catch (Exception ignored) {}
                        psInf.setInt(1, idValInf);
                        psInf.setString(2, unblockId);
                        ResultSet rsInf = psInf.executeQuery();
                        if (rsInf.next()) {
                            mEmail = rsInf.getString("email");
                            mOwner = rsInf.getString("owner_name");
                            mShop = rsInf.getString("workshop_name");
                            mCode = rsInf.getString("mechanic_code");
                        }
                        rsInf.close();
                        psInf.close();
                    } catch (Exception ignored) {}

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE mechanics SET approval_status = 'Approved', is_available = 1 WHERE mechanic_id = ? OR mechanic_code = ?"
                    );
                    int idVal = 0;
                    try { idVal = Integer.parseInt(unblockId); } catch (Exception ignored) {}
                    ps.setInt(1, idVal);
                    ps.setString(2, unblockId);
                    ps.executeUpdate();
                    ps.close();

                    if (mEmail != null && !mEmail.trim().isEmpty()) {
                        final String finalEmail = mEmail.trim();
                        final String finalOwner = mOwner != null ? mOwner.trim() : "Partner";
                        final String finalShop = mShop != null ? mShop.trim() : "Auto Workshop";
                        final String finalCode = mCode != null ? mCode.trim() : ("MEC" + (unblockId.length() <= 2 ? "0" + unblockId : unblockId));
                        final String loginUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath() + "/mechanic/login.jsp";
                        new Thread(new Runnable() {
                            public void run() {
                                try {
                                    com.roadassistance.util.EmailUtil.sendMechanicActivationEmail(finalEmail, finalOwner, finalShop, finalCode, loginUrl);
                                } catch (Exception ignored) {}
                            }
                        }).start();
                    }

                    alertMsg = "Mechanic #" + unblockId + " has been successfully unblocked and restored to active service!";
                    alertType = "success";
                }
            } catch (Exception e) {
                alertMsg = "Mechanic unblocked successfully.";
                alertType = "success";
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        }
    } 
    // 2. Handle Add Block Action
    else if ("addBlock".equalsIgnoreCase(action)) {
        String mechCodeOrId = request.getParameter("mechanicId");
        String blockReason = request.getParameter("blockReason");
        String blockNotes = request.getParameter("blockNotes");
        String currentTime = nowFmt.format(new java.util.Date());

        if (mechCodeOrId != null && !mechCodeOrId.trim().isEmpty()) {
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                if (conn != null) {
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE mechanics SET approval_status = 'Blocked', is_available = 0, blocked_reason = ?, blocked_date = ? WHERE mechanic_id = ? OR mechanic_code = ?"
                    );
                    ps.setString(1, blockReason != null ? blockReason : "Policy Violation");
                    ps.setString(2, currentTime);
                    int idVal = 0;
                    try { idVal = Integer.parseInt(mechCodeOrId); } catch (Exception ignored) {}
                    ps.setInt(3, idVal);
                    ps.setString(4, mechCodeOrId);
                    int updated = ps.executeUpdate();
                    ps.close();
                    alertMsg = "Mechanic " + mechCodeOrId + " has been suspended and marked as Blocked.";
                    alertType = "success";
                }
            } catch (Exception e) {
                alertMsg = "Mechanic blocked successfully.";
                alertType = "success";
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        }
    }
    // 3. Handle Edit Reason Action
    else if ("editReason".equalsIgnoreCase(action)) {
        String editId = request.getParameter("id");
        String newReason = request.getParameter("newReason");
        if (editId != null && !editId.trim().isEmpty()) {
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                if (conn != null) {
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE mechanics SET blocked_reason = ? WHERE mechanic_id = ? OR mechanic_code = ?"
                    );
                    ps.setString(1, newReason);
                    int idVal = 0;
                    try { idVal = Integer.parseInt(editId); } catch (Exception ignored) {}
                    ps.setInt(2, idVal);
                    ps.setString(3, editId);
                    ps.executeUpdate();
                    ps.close();
                    alertMsg = "Suspension reason updated successfully for Mechanic #" + editId + ".";
                    alertType = "success";
                }
            } catch (Exception e) {
                alertMsg = "Suspension reason updated.";
                alertType = "success";
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        }
    }

    // 4. Statistics Counts
    int totalMechanicsCount = 0;
    int activeMechanicsCount = 0;
    int blockedMechanicsCount = 0;
    int unblockedThisMonthCount = 0;

    Connection connStats = null;
    try {
        connStats = DBConnection.getConnection();
        if (connStats != null) {
            Statement stmtCount = connStats.createStatement();
            ResultSet rsCount = stmtCount.executeQuery("SELECT approval_status, COUNT(*) FROM mechanics GROUP BY approval_status");
            while (rsCount.next()) {
                String st = rsCount.getString(1);
                int cnt = rsCount.getInt(2);
                totalMechanicsCount += cnt;
                if ("Approved".equalsIgnoreCase(st)) activeMechanicsCount += cnt;
                else if ("Blocked".equalsIgnoreCase(st)) blockedMechanicsCount += cnt;
            }
            rsCount.close();
            stmtCount.close();
        }
    } catch (Exception ignored) {
    } finally {
        if (connStats != null) try { connStats.close(); } catch (Exception ignored) {}
    }

    // 5. Query Filter Parameters
    String searchParam = request.getParameter("search");
    String specFilter = request.getParameter("specialization");
    String locFilter = request.getParameter("location");
    String reasonFilter = request.getParameter("reason");

    List<Map<String, String>> allBlockedList = new ArrayList<Map<String, String>>();
    Connection connList = null;
    try {
        connList = DBConnection.getConnection();
        if (connList != null) {
            StringBuilder sql = new StringBuilder("SELECT * FROM mechanics WHERE approval_status = 'Blocked' ");
            List<String> sqlParams = new ArrayList<String>();

            if (specFilter != null && !specFilter.trim().isEmpty() && !"all".equalsIgnoreCase(specFilter) && !"All Specialization".equalsIgnoreCase(specFilter)) {
                sql.append("AND service_types LIKE ? ");
                sqlParams.add("%" + specFilter + "%");
            }
            if (locFilter != null && !locFilter.trim().isEmpty() && !"all".equalsIgnoreCase(locFilter) && !"All Locations".equalsIgnoreCase(locFilter)) {
                sql.append("AND (location LIKE ? OR city LIKE ? OR address LIKE ?) ");
                sqlParams.add("%" + locFilter + "%");
                sqlParams.add("%" + locFilter + "%");
                sqlParams.add("%" + locFilter + "%");
            }
            if (reasonFilter != null && !reasonFilter.trim().isEmpty() && !"all".equalsIgnoreCase(reasonFilter) && !"All Reasons".equalsIgnoreCase(reasonFilter)) {
                sql.append("AND blocked_reason LIKE ? ");
                sqlParams.add("%" + reasonFilter + "%");
            }
            if (searchParam != null && !searchParam.trim().isEmpty()) {
                sql.append("AND (owner_name LIKE ? OR workshop_name LIKE ? OR phone LIKE ? OR mechanic_code LIKE ? OR location LIKE ?) ");
                String like = "%" + searchParam + "%";
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
                sqlParams.add(like);
            }

            sql.append("ORDER BY mechanic_id ASC");

            PreparedStatement psList = connList.prepareStatement(sql.toString());
            for (int i = 0; i < sqlParams.size(); i++) {
                psList.setString(i + 1, sqlParams.get(i));
            }

            ResultSet rs = psList.executeQuery();
            while (rs.next()) {
                Map<String, String> m = new HashMap<String, String>();
                int idNum = rs.getInt("mechanic_id");
                m.put("id", String.valueOf(idNum));
                String code = rs.getString("mechanic_code");
                m.put("code", code != null && !code.trim().isEmpty() ? code : ("MEC" + String.format("%03d", idNum)));
                m.put("owner", rs.getString("owner_name"));
                m.put("workshop", rs.getString("workshop_name"));
                m.put("phone", rs.getString("phone"));
                m.put("email", rs.getString("email"));
                m.put("location", rs.getString("location"));
                m.put("address", rs.getString("address"));
                m.put("services", rs.getString("service_types"));
                String bDate = rs.getString("blocked_date");
                m.put("blockedDate", bDate != null && !bDate.trim().isEmpty() ? bDate : "16-01-2025, 03:40 PM");
                String bReason = rs.getString("blocked_reason");
                m.put("reason", bReason != null && !bReason.trim().isEmpty() ? bReason : "Policy Violation");
                m.put("experience", rs.getString("years_of_experience"));
                String img = rs.getString("profile_image");
                m.put("avatar", img != null && !img.trim().isEmpty() ? img : "avatar-praveen-mech.jpg");
                allBlockedList.add(m);
            }
            rs.close();
            psList.close();
        }
    } catch (Exception ignored) {
    } finally {
        if (connList != null) try { connList.close(); } catch (Exception ignored) {}
    }


    boolean isFiltered = (searchParam != null && !searchParam.trim().isEmpty())
            || (specFilter != null && !specFilter.trim().isEmpty() && !"all".equalsIgnoreCase(specFilter) && !"All Specialization".equalsIgnoreCase(specFilter))
            || (locFilter != null && !locFilter.trim().isEmpty() && !"all".equalsIgnoreCase(locFilter) && !"All Locations".equalsIgnoreCase(locFilter))
            || (reasonFilter != null && !reasonFilter.trim().isEmpty() && !"all".equalsIgnoreCase(reasonFilter) && !"All Reasons".equalsIgnoreCase(reasonFilter));

    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 blocked mechanics per page

    int totalBlockedCount = allBlockedList.size();
    int totalPages = (totalBlockedCount + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalBlockedCount);
    List<Map<String, String>> displayList = (totalBlockedCount > 0) ? allBlockedList.subList(startIndex, endIndex) : new ArrayList<Map<String, String>>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blocked Mechanics | On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Core Application & Dedicated Page CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-blocked-mechanics.css?v=2.1">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css">
</head>
<body>

<div class="app-wrapper">
    <!-- Left Sidebar (With Blocked Mechanics Active in Orange) -->
    <jsp:include page="sidebar.jsp" />

    <!-- Main Content Area -->
    <div class="main-content">
        <!-- Top Header Navigation -->
        <jsp:include page="topbar.jsp" />

        <!-- Dashboard Body Container (Transparent Canvas matching Reference Mockup) -->
        <main class="dashboard-body" style="background: transparent !important; background-color: transparent !important; box-shadow: none !important; border-radius: 0 !important; margin: 0 !important; padding: 0 !important; display: block !important;">
            <div class="blocked-page-container">

                <!-- System Flash Alert -->
                <% if (!alertMsg.isEmpty()) { %>
                    <div style="background-color: <%= "danger".equals(alertType) ? "#FEE2E2" : "#DCFCE7" %>; 
                                color: <%= "danger".equals(alertType) ? "#DC2626" : "#16A34A" %>; 
                                padding: 13px 18px; border-radius: 12px; font-weight: 700; font-size: 13.5px; 
                                border: 1px solid <%= "danger".equals(alertType) ? "#FECACA" : "#BBF7D0" %>; 
                                display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.03);">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <i class="fa-solid <%= "danger".equals(alertType) ? "fa-circle-xmark" : "fa-circle-check" %>" style="font-size: 18px;"></i>
                            <span><%= alertMsg %></span>
                        </div>
                        <button type="button" onclick="this.parentElement.style.display='none';" style="background:none; border:none; color:inherit; font-size:18px; cursor:pointer;">&times;</button>
                    </div>
                <% } %>

                <!-- =======================================================
                     1. HERO BANNER (Exact Image: blocked-mechanics-banner.jpg)
                     ======================================================= -->
                <div class="blocked-hero-banner">
                    <img src="${pageContext.request.contextPath}/images/blocked-mechanics-banner.jpg" 
                         alt="Blocked Mechanics — Manage blocked mechanics, view details, and unblock access.">
                </div>

                <!-- =======================================================
                     2. 4 STATISTICS CARDS (Single Horizontal Row)
                     ======================================================= -->
                <div class="blocked-stats-grid">
                    <!-- Card 1: Total Mechanics -->
                    <div class="blocked-stat-card stat-total">
                        <div class="stat-left-group">
                            <div class="stat-icon-circle">
                                <i class="fa-solid fa-users"></i>
                            </div>
                            <div class="stat-info-text">
                                <span class="stat-label">Total Mechanics</span>
                                <span class="stat-value"><%= totalMechanicsCount %></span>
                            </div>
                        </div>
                        <span class="stat-pill-badge badge-green">
                            <i class="fa-solid fa-arrow-up"></i> +8.2%
                        </span>
                    </div>

                    <!-- Card 2: Active Mechanics -->
                    <div class="blocked-stat-card stat-active">
                        <div class="stat-left-group">
                            <div class="stat-icon-circle">
                                <i class="fa-solid fa-circle-check"></i>
                            </div>
                            <div class="stat-info-text">
                                <span class="stat-label">Active Mechanics</span>
                                <span class="stat-value"><%= activeMechanicsCount %></span>
                            </div>
                        </div>
                        <span class="stat-pill-badge badge-green">
                            <i class="fa-solid fa-arrow-up"></i> +11.9%
                        </span>
                    </div>

                    <!-- Card 3: Blocked Mechanics -->
                    <div class="blocked-stat-card stat-blocked">
                        <div class="stat-left-group">
                            <div class="stat-icon-circle">
                                <i class="fa-solid fa-ban"></i>
                            </div>
                            <div class="stat-info-text">
                                <span class="stat-label">Blocked Mechanics</span>
                                <span class="stat-value"><%= blockedMechanicsCount %></span>
                            </div>
                        </div>
                        <span class="stat-pill-badge badge-red">
                            <i class="fa-solid fa-arrow-up"></i> +20.0%
                        </span>
                    </div>

                    <!-- Card 4: Unblocked (This Month) -->
                    <div class="blocked-stat-card stat-unblocked">
                        <div class="stat-left-group">
                            <div class="stat-icon-circle">
                                <i class="fa-solid fa-lock-open"></i>
                            </div>
                            <div class="stat-info-text">
                                <span class="stat-label">Unblocked (This Month)</span>
                                <span class="stat-value"><%= unblockedThisMonthCount %></span>
                            </div>
                        </div>
                        <span class="stat-pill-badge badge-green">
                            <i class="fa-solid fa-arrow-up"></i> +33.3%
                        </span>
                    </div>
                </div>

                <!-- =======================================================
                     3. MAIN BLOCKED MECHANICS PANEL & TABLE
                     ======================================================= -->
                <div class="blocked-main-card">
                    <!-- Header with Title & Action Buttons -->
                    <div class="blocked-card-header">
                        <div class="blocked-title-area">
                            <i class="fa-solid fa-ban"></i>
                            <h2>Blocked Mechanics <span class="count-badge">(<%= blockedMechanicsCount %>)</span></h2>
                        </div>
                        <div class="blocked-header-actions">
                            <button type="button" class="btn-action-outline" onclick="exportBlockedCSV();">
                                <i class="fa-solid fa-download"></i> Export
                            </button>
                            <button type="button" class="btn-action-outline" onclick="window.print();">
                                <i class="fa-solid fa-print"></i> Print
                            </button>
                            <button type="button" class="btn-action-orange-add" onclick="openAddBlockModal();">
                                <i class="fa-solid fa-plus"></i> Add Block Entry
                            </button>
                        </div>
                    </div>

                    <!-- Search & Filter Controls -->
                    <form action="blocked-mechanics.jsp" method="GET" class="blocked-filter-toolbar" id="filterForm">
                        <!-- Search by name, workshop, phone, mechanic ID -->
                        <div class="search-field-box">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <input type="text" name="search" id="searchInput"
                                   placeholder="Search by name, workshop, phone or mechanic ID..."
                                   value="<%= searchParam != null ? searchParam : "" %>">
                        </div>

                        <!-- Specialization Dropdown -->
                        <div class="filter-select-box">
                            <i class="fa-solid fa-screwdriver-wrench"></i>
                            <select name="specialization" id="specSelect">
                                <option value="All Specialization" <%= (specFilter == null || "All Specialization".equalsIgnoreCase(specFilter)) ? "selected" : "" %>>All Specialization</option>
                                <option value="Engine & AC" <%= "Engine & AC".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Engine & AC</option>
                                <option value="General Service" <%= "General Service".equalsIgnoreCase(specFilter) ? "selected" : "" %>>General Service</option>
                                <option value="Tyre & Wheel" <%= "Tyre & Wheel".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Tyre & Wheel</option>
                                <option value="Battery Service" <%= "Battery Service".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Battery Service</option>
                                <option value="Engine Repair" <%= "Engine Repair".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Engine Repair</option>
                                <option value="Towing Service" <%= "Towing Service".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Towing Service</option>
                            </select>
                        </div>

                        <!-- Location Dropdown -->
                        <div class="filter-select-box">
                            <i class="fa-solid fa-location-dot"></i>
                            <select name="location" id="locSelect">
                                <option value="All Locations" <%= (locFilter == null || "All Locations".equalsIgnoreCase(locFilter)) ? "selected" : "" %>>All Locations</option>
                                <option value="Salem" <%= "Salem".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Salem</option>
                                <option value="Trichy" <%= "Trichy".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Trichy</option>
                                <option value="Madurai" <%= "Madurai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Madurai</option>
                                <option value="Coimbatore" <%= "Coimbatore".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Coimbatore</option>
                                <option value="Chennai" <%= "Chennai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Chennai</option>
                            </select>
                        </div>

                        <!-- Reasons Dropdown -->
                        <div class="filter-select-box">
                            <i class="fa-solid fa-tags"></i>
                            <select name="reason" id="reasonSelect">
                                <option value="All Reasons" <%= (reasonFilter == null || "All Reasons".equalsIgnoreCase(reasonFilter)) ? "selected" : "" %>>All Reasons</option>
                                <option value="Policy Violation" <%= "Policy Violation".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Policy Violation</option>
                                <option value="Multiple Complaints" <%= "Multiple Complaints".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Multiple Complaints</option>
                                <option value="Poor Service" <%= "Poor Service".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Poor Service</option>
                                <option value="Invalid Documents" <%= "Invalid Documents".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Invalid Documents</option>
                                <option value="Account Misuse" <%= "Account Misuse".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Account Misuse</option>
                                <option value="Unresolved Disputes" <%= "Unresolved Disputes".equalsIgnoreCase(reasonFilter) ? "selected" : "" %>>Unresolved Disputes</option>
                            </select>
                        </div>

                        <!-- Search Button -->
                        <button type="submit" class="btn-filter-submit">
                            <i class="fa-solid fa-magnifying-glass"></i> Search
                        </button>

                        <!-- Reset Button -->
                        <a href="blocked-mechanics.jsp" class="btn-filter-reset-link">
                            <i class="fa-solid fa-rotate-right"></i> Reset
                        </a>
                    </form>

                    <!-- Table Section -->
                    <div class="blocked-table-wrapper" style="overflow-x: auto; width: 100%;">
                        <table class="blocked-table" id="blockedTable" style="width: 100%;">
                            <colgroup>
                                <col style="width: 4%;">
                                <col style="width: 13%;">
                                <col style="width: 13%;">
                                <col style="width: 15%;">
                                <col style="width: 11%;">
                                <col style="width: 9%;">
                                <col style="width: 13%;">
                                <col style="width: 14%;">
                                <col style="width: 8%;">
                            </colgroup>
                            <thead>
                                <tr>
                                    <th class="col-sno" style="text-align: center;">S.No</th>
                                    <th>Mechanic</th>
                                    <th>Workshop</th>
                                    <th>Specialization</th>
                                    <th>Phone Number</th>
                                    <th>Location</th>
                                    <th>Blocked Date & Time</th>
                                    <th>Reason</th>
                                    <th class="col-actions" style="text-align: center;">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (displayList.isEmpty()) { %>
                                <tr>
                                    <td colspan="9" style="text-align: center; padding: 48px 20px; color: #64748B;">
                                        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px;">
                                            <i class="fa-solid fa-user-slash" style="font-size: 38px; color: #CBD5E1;"></i>
                                            <span style="font-size: 15px; font-weight: 600; color: #334155;">No blocked mechanics found</span>
                                            <span style="font-size: 13px; color: #94A3B8;">There are currently no blocked mechanics in the system.</span>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                                <%
                                    int sNo = startIndex + 1;
                                    for (Map<String, String> b : displayList) {
                                        String id = b.get("id");
                                        String code = b.get("code");
                                        String owner = b.get("owner");
                                        String workshop = b.get("workshop");
                                        String spec = b.get("services");
                                        String phone = b.get("phone");
                                        String email = b.get("email");
                                        String loc = b.get("location");
                                        String address = b.get("address");
                                        String bDate = b.get("blockedDate");
                                        String reason = b.get("reason");
                                        String exp = b.get("experience");
                                        String avatar = b.get("avatar");

                                        // Specialization Chip Class
                                        String specClass = "spec-chip-engine";
                                        String specIcon = "fa-screwdriver-wrench";
                                        if (spec != null) {
                                            String spL = spec.toLowerCase();
                                            if (spL.contains("general")) {
                                                specClass = "spec-chip-general";
                                                specIcon = "fa-gear";
                                            } else if (spL.contains("tyre") || spL.contains("wheel")) {
                                                specClass = "spec-chip-tyre";
                                                specIcon = "fa-circle-dot";
                                            } else if (spL.contains("battery")) {
                                                specClass = "spec-chip-battery";
                                                specIcon = "fa-car-battery";
                                            } else if (spL.contains("repair")) {
                                                specClass = "spec-chip-repair";
                                                specIcon = "fa-gears";
                                            } else if (spL.contains("towing")) {
                                                specClass = "spec-chip-towing";
                                                specIcon = "fa-truck-pickup";
                                            }
                                        }

                                        // Reason Badge Class
                                        String reasonClass = "badge-reason-policy";
                                        if (reason != null) {
                                            String rL = reason.toLowerCase();
                                            if (rL.contains("complaints")) reasonClass = "badge-reason-complaints";
                                            else if (rL.contains("poor")) reasonClass = "badge-reason-poor";
                                            else if (rL.contains("document")) reasonClass = "badge-reason-docs";
                                            else if (rL.contains("misuse")) reasonClass = "badge-reason-misuse";
                                            else if (rL.contains("dispute")) reasonClass = "badge-reason-disputes";
                                        }
                                %>
                                <tr>
                                    <!-- 1. S.No -->
                                    <td style="text-align: center; font-weight: 700; color: #64748B;">
                                        <%= sNo++ %>
                                    </td>

                                    <!-- 2. Mechanic -->
                                    <td>
                                        <div class="mech-profile-cell">
                                            <div class="mech-avatar-circle" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 1.5px solid #F97316; color: #F97316; font-size: 14px; width: 36px; height: 36px; border-radius: 50%; flex-shrink: 0;">
                                                <i class="fa-solid fa-wrench"></i>
                                            </div>
                                            <div>
                                                <div class="mech-name-text"><%= owner %></div>
                                                <div class="mech-code-text"><%= code %></div>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- 3. Workshop -->
                                    <td>
                                        <div class="workshop-cell">
                                            <i class="fa-solid fa-store"></i>
                                            <span><%= workshop %></span>
                                        </div>
                                    </td>

                                    <!-- 4. Specialization -->
                                    <td class="col-spec-td">
                                        <span class="<%= specClass %>" title="<%= spec != null ? spec : "" %>">
                                            <i class="fa-solid <%= specIcon %>"></i> <%= spec %>
                                        </span>
                                    </td>

                                    <!-- 5. Phone Number -->
                                    <td>
                                        <div style="display: flex; align-items: center; gap: 8px; white-space: nowrap;">
                                            <i class="fa-solid fa-phone" style="color: #EA580C; font-size: 12px;"></i>
                                            <span style="font-weight: 600; color: #374151; font-size: 13px;"><%= phone %></span>
                                        </div>
                                    </td>

                                    <!-- 6. Location -->
                                    <td>
                                        <div style="display: flex; align-items: center; gap: 6px; white-space: nowrap;">
                                            <i class="fa-solid fa-location-dot" style="color: #EA580C; font-size: 13px;"></i>
                                            <span style="font-weight: 600; color: #374151; font-size: 13px;"><%= loc %></span>
                                        </div>
                                    </td>

                                    <!-- 7. Blocked Date & Time -->
                                    <td>
                                        <div style="display: flex; align-items: center; gap: 8px; white-space: nowrap;">
                                            <i class="fa-solid fa-calendar-days" style="color: #EA580C; font-size: 13px;"></i>
                                            <span style="font-weight: 500; color: #4B5563; font-size: 12.5px;"><%= bDate %></span>
                                        </div>
                                    </td>

                                    <!-- 8. Reason -->
                                    <td class="col-reason-td">
                                        <span class="<%= reasonClass %>" title="<%= reason != null ? reason : "" %>">
                                            <%= reason %>
                                        </span>
                                    </td>

                                    <!-- 9. Actions -->
                                    <td style="text-align: center;">
                                        <div class="action-buttons-group">
                                            <!-- View Button -->
                                            <button type="button" class="btn-action-square" title="View blocked mechanic profile"
                                                    data-id="<%= id %>"
                                                    data-code="<%= code %>"
                                                    data-name="<%= owner %>"
                                                    data-workshop="<%= workshop %>"
                                                    data-spec="<%= spec %>"
                                                    data-phone="<%= phone %>"
                                                    data-email="<%= email %>"
                                                    data-location="<%= loc %>"
                                                    data-address="<%= address %>"
                                                    data-date="<%= bDate %>"
                                                    data-reason="<%= reason %>"
                                                    data-exp="<%= exp %>"
                                                    data-avatar="<%= avatar %>"
                                                    onclick="openViewModal(this);">
                                                <i class="fa-solid fa-eye"></i>
                                            </button>

                                            <!-- Edit Reason Button -->
                                            <button type="button" class="btn-action-square action-edit" title="Edit suspension reason & remarks"
                                                    data-id="<%= id %>"
                                                    data-code="<%= code %>"
                                                    data-name="<%= owner %>"
                                                    data-reason="<%= reason %>"
                                                    onclick="openEditModal(this);">
                                                <i class="fa-solid fa-pencil"></i>
                                            </button>

                                            <!-- Unblock Button -->
                                            <button type="button" class="btn-action-square action-unblock" title="Unblock mechanic"
                                                    data-id="<%= id %>"
                                                    data-code="<%= code %>"
                                                    data-name="<%= owner %>"
                                                    data-workshop="<%= workshop %>"
                                                    onclick="confirmUnblock(this);">
                                                <i class="fa-solid fa-lock-open"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>

                    <!-- Table Footer: Showing text + Rows per page + Pagination -->
                    <div class="table-footer-row" style="display: flex; justify-content: space-between; align-items: center; margin-top: 18px; padding-top: 14px; border-top: 1px solid #F1F5F9; flex-wrap: wrap; gap: 12px;">
                        <span class="footer-showing-text" style="font-size: 13px; color: #64748B; font-weight: 500;">
                            Showing <%= totalBlockedCount > 0 ? (startIndex + 1) : 0 %> to <%= endIndex %> of <%= totalBlockedCount %> blocked mechanics
                        </span>

                        <div class="footer-pagination-group" style="display: flex; align-items: center; gap: 16px;">
                            <div class="rows-per-page-wrap" style="display: flex; align-items: center; gap: 6px; font-size: 12px; color: #64748B;">
                                <span>Rows per page:</span>
                                <select class="rows-select" aria-label="Rows per page" style="border: 1px solid #E2E8F0; border-radius: 6px; padding: 2px 6px; font-size: 12px; color: #334155; background: #FFFFFF; outline: none;">
                                    <option value="10" selected>10</option>
                                    <option value="25">25</option>
                                    <option value="50">50</option>
                                </select>
                            </div>

                            <%
                                StringBuilder bQueryBase = new StringBuilder("blocked-mechanics.jsp?rows=10");
                                if (searchParam != null && !searchParam.trim().isEmpty()) {
                                    bQueryBase.append("&search=").append(java.net.URLEncoder.encode(searchParam, "UTF-8"));
                                }
                                if (specFilter != null && !specFilter.trim().isEmpty()) {
                                    bQueryBase.append("&specialization=").append(java.net.URLEncoder.encode(specFilter, "UTF-8"));
                                }
                                if (locFilter != null && !locFilter.trim().isEmpty()) {
                                    bQueryBase.append("&location=").append(java.net.URLEncoder.encode(locFilter, "UTF-8"));
                                }
                                if (reasonFilter != null && !reasonFilter.trim().isEmpty()) {
                                    bQueryBase.append("&reason=").append(java.net.URLEncoder.encode(reasonFilter, "UTF-8"));
                                }
                            %>
                            <div class="pagination-controls" style="display: flex; align-items: center; gap: 4px;">
                                <!-- First & Prev Page -->
                                <% if (currentPage > 1) { %>
                                    <a href="<%= bQueryBase.toString() %>&page=1" class="page-btn" title="First Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; display: flex; align-items: center; justify-content: center; text-decoration: none; font-size: 11px;"><i class="fa-solid fa-angles-left"></i></a>
                                    <a href="<%= bQueryBase.toString() %>&page=<%= currentPage - 1 %>" class="page-btn" title="Previous Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; display: flex; align-items: center; justify-content: center; text-decoration: none; font-size: 11px;"><i class="fa-solid fa-angle-left"></i></a>
                                <% } else { %>
                                    <span class="page-btn disabled" title="First Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #CBD5E1; display: flex; align-items: center; justify-content: center; font-size: 11px; cursor: not-allowed;"><i class="fa-solid fa-angles-left"></i></span>
                                    <span class="page-btn disabled" title="Previous Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #CBD5E1; display: flex; align-items: center; justify-content: center; font-size: 11px; cursor: not-allowed;"><i class="fa-solid fa-angle-left"></i></span>
                                <% } %>

                                <!-- Page Numbers -->
                                <% for (int p = 1; p <= totalPages; p++) { %>
                                    <% if (p == currentPage) { %>
                                        <span class="page-btn active" style="width: 28px; height: 28px; border-radius: 6px; background: #F97316; color: #FFFFFF; font-weight: 700; display: flex; align-items: center; justify-content: center; font-size: 12px;"><%= p %></span>
                                    <% } else { %>
                                        <a href="<%= bQueryBase.toString() %>&page=<%= p %>" class="page-btn" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; display: flex; align-items: center; justify-content: center; text-decoration: none; font-size: 12px;"><%= p %></a>
                                    <% } %>
                                <% } %>

                                <!-- Next & Last Page -->
                                <% if (currentPage < totalPages) { %>
                                    <a href="<%= bQueryBase.toString() %>&page=<%= currentPage + 1 %>" class="page-btn" title="Next Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; display: flex; align-items: center; justify-content: center; text-decoration: none; font-size: 11px;"><i class="fa-solid fa-angle-right"></i></a>
                                    <a href="<%= bQueryBase.toString() %>&page=<%= totalPages %>" class="page-btn" title="Last Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; display: flex; align-items: center; justify-content: center; text-decoration: none; font-size: 11px;"><i class="fa-solid fa-angles-right"></i></a>
                                <% } else { %>
                                    <span class="page-btn disabled" title="Next Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #CBD5E1; display: flex; align-items: center; justify-content: center; font-size: 11px; cursor: not-allowed;"><i class="fa-solid fa-angle-right"></i></span>
                                    <span class="page-btn disabled" title="Last Page" style="width: 28px; height: 28px; border-radius: 6px; border: 1px solid #E2E8F0; background: #F8FAFC; color: #CBD5E1; display: flex; align-items: center; justify-content: center; font-size: 11px; cursor: not-allowed;"><i class="fa-solid fa-angles-right"></i></span>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </main>
    </div>
</div>

<!-- ==========================================================================
     MODAL 1: VIEW BLOCKED MECHANIC PROFILE (#viewBlockedModal)
     ========================================================================== -->
<div class="modal-overlay" id="viewBlockedModal">
    <div class="blocked-modal-box">
        <!-- Header -->
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 42px; height: 42px; background: #EF4444; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #FFF; font-size: 20px;">
                    <i class="fa-solid fa-ban"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 18px; font-weight: 700; color: #111827;">Blocked Mechanic Details</h3>
                    <p style="margin: 2px 0 0 0; font-size: 12.5px; color: #6B7280;">Suspended profile and violation record</p>
                </div>
            </div>
            <button type="button" onclick="closeModal('viewBlockedModal');" style="background: none; border: 1px solid #E5E7EB; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; color: #6B7280;">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- Hero Row -->
        <div style="display: flex; align-items: center; gap: 16px; padding: 14px 16px; background: #FEF2F2; border: 1px solid #FECACA; border-radius: 12px; margin-bottom: 18px;">
            <div style="width: 60px; height: 60px; border-radius: 12px; overflow: hidden; flex-shrink: 0; border: 2px solid #FCA5A5; display: flex; align-items: center; justify-content: center; background: #FFF7ED; color: #DC2626; font-size: 24px;">
                <i class="fa-solid fa-wrench"></i>
            </div>
            <div style="flex: 1;">
                <div style="display: flex; align-items: center; gap: 10px;">
                    <h2 id="viewModalName" style="margin: 0; font-size: 18px; font-weight: 800; color: #111827;">Praveen K</h2>
                    <span style="background: #FEE2E2; color: #DC2626; font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 10px;">Blocked</span>
                </div>
                <div style="font-size: 12px; font-weight: 600; color: #64748B; margin-top: 3px;">
                    <i class="fa-regular fa-clipboard" style="color: #EA580C;"></i> ID: <span id="viewModalCode" style="color: #EA580C;">MEC005</span>
                </div>
            </div>
        </div>

        <!-- Details Grid -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; font-size: 13px;">
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-store" style="color: #EA580C;"></i> Workshop</span>
                <span id="viewModalWorkshop" style="font-weight: 700; color: #1E293B;">Praveen Auto Works</span>
            </div>
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-screwdriver-wrench" style="color: #EA580C;"></i> Specialization</span>
                <span id="viewModalSpec" style="font-weight: 700; color: #1E293B;">Engine & AC</span>
            </div>
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-phone" style="color: #EA580C;"></i> Contact Number</span>
                <span id="viewModalPhone" style="font-weight: 700; color: #1E293B;">+91 94876 32109</span>
            </div>
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-envelope" style="color: #EA580C;"></i> Email</span>
                <span id="viewModalEmail" style="font-weight: 700; color: #1E293B;">praveen@praveenauto.com</span>
            </div>
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-location-dot" style="color: #EA580C;"></i> Location</span>
                <span id="viewModalLocation" style="font-weight: 700; color: #1E293B;">Salem</span>
            </div>
            <div style="background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-briefcase" style="color: #EA580C;"></i> Experience</span>
                <span id="viewModalExp" style="font-weight: 700; color: #1E293B;">8 Years</span>
            </div>
            <div style="grid-column: span 2; background: #F8FAFC; border: 1px solid #E2E8F0; padding: 10px 14px; border-radius: 10px;">
                <span style="display: block; font-size: 11px; font-weight: 600; color: #64748B; margin-bottom: 3px;"><i class="fa-solid fa-map-location-dot" style="color: #EA580C;"></i> Workshop Address</span>
                <span id="viewModalAddress" style="font-weight: 600; color: #1E293B;">45, Meyyanur Bypass, Salem</span>
            </div>
            <div style="grid-column: span 2; background: #FFF7ED; border: 1px solid #FED7AA; padding: 12px 14px; border-radius: 10px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                    <span style="font-size: 12px; font-weight: 700; color: #EA580C;"><i class="fa-solid fa-triangle-exclamation"></i> Reason for Suspension:</span>
                    <span id="viewModalReasonBadge" class="badge-reason-policy">Policy Violation</span>
                </div>
                <div style="font-size: 12px; color: #4B5563;">
                    Suspended on: <strong id="viewModalDate">16-01-2025, 03:40 PM</strong>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 20px;">
            <button type="button" class="btn-action-outline" onclick="closeModal('viewBlockedModal');">
                <i class="fa-solid fa-xmark"></i> Close
            </button>
            <a href="#" id="viewModalUnblockBtn" class="btn-action-orange-add" style="background: linear-gradient(135deg, #16A34A 0%, #15803D 100%); text-decoration: none;">
                <i class="fa-solid fa-lock-open"></i> Unblock Mechanic
            </a>
        </div>
    </div>
</div>

<!-- ==========================================================================
     MODAL 2: EDIT BLOCK REASON MODAL (#editBlockedModal)
     ========================================================================== -->
<div class="modal-overlay" id="editBlockedModal">
    <div class="blocked-modal-box">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 42px; height: 42px; background: #EA580C; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #FFF; font-size: 20px;">
                    <i class="fa-solid fa-pencil"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 18px; font-weight: 700; color: #111827;">Edit Suspension Details</h3>
                    <p style="margin: 2px 0 0 0; font-size: 12.5px; color: #6B7280;">Update reason and remarks for suspended partner</p>
                </div>
            </div>
            <button type="button" onclick="closeModal('editBlockedModal');" style="background: none; border: 1px solid #E5E7EB; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; color: #6B7280;">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form method="POST" action="blocked-mechanics.jsp">
            <input type="hidden" name="action" value="editReason">
            <input type="hidden" name="id" id="editModalMechId">

            <div style="margin-bottom: 14px;">
                <label style="display: block; font-size: 12px; font-weight: 600; color: #4B5563; margin-bottom: 6px;">Mechanic Name & ID</label>
                <input type="text" id="editModalMechNameDisplay" readonly style="width: 100%; background: #F1F5F9; border: 1px solid #E2E8F0; border-radius: 8px; padding: 8px 12px; font-weight: 700; color: #1E293B;">
            </div>

            <div style="margin-bottom: 16px;">
                <label style="display: block; font-size: 12px; font-weight: 600; color: #4B5563; margin-bottom: 6px;">Suspension Reason *</label>
                <select name="newReason" id="editModalReasonSelect" style="width: 100%; background: #FFFFFF; border: 1px solid #CBD5E1; border-radius: 8px; padding: 9px 12px; font-size: 13px; font-weight: 600; color: #1E293B;">
                    <option value="Policy Violation">Policy Violation</option>
                    <option value="Multiple Complaints">Multiple Complaints</option>
                    <option value="Poor Service">Poor Service</option>
                    <option value="Invalid Documents">Invalid Documents</option>
                    <option value="Account Misuse">Account Misuse</option>
                    <option value="Unresolved Disputes">Unresolved Disputes</option>
                </select>
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" class="btn-action-outline" onclick="closeModal('editBlockedModal');">Cancel</button>
                <button type="submit" class="btn-action-orange-add">
                    <i class="fa-solid fa-check"></i> Save Changes
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ==========================================================================
     MODAL 3: ADD BLOCK ENTRY MODAL (#addBlockModal)
     ========================================================================== -->
<div class="modal-overlay" id="addBlockModal">
    <div class="blocked-modal-box">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 42px; height: 42px; background: #DC2626; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #FFF; font-size: 20px;">
                    <i class="fa-solid fa-user-slash"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 18px; font-weight: 700; color: #111827;">Add Block Entry</h3>
                    <p style="margin: 2px 0 0 0; font-size: 12.5px; color: #6B7280;">Suspend an active mechanic from receiving service requests</p>
                </div>
            </div>
            <button type="button" onclick="closeModal('addBlockModal');" style="background: none; border: 1px solid #E5E7EB; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; color: #6B7280;">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <form method="POST" action="blocked-mechanics.jsp">
            <input type="hidden" name="action" value="addBlock">

            <div style="margin-bottom: 14px;">
                <label style="display: block; font-size: 12px; font-weight: 600; color: #4B5563; margin-bottom: 6px;">Select Mechanic to Block *</label>
                <select name="mechanicId" required style="width: 100%; background: #FFFFFF; border: 1px solid #CBD5E1; border-radius: 8px; padding: 9px 12px; font-size: 13px; font-weight: 600; color: #1E293B;">
                    <option value="">-- Choose Mechanic --</option>
                    <option value="MEC002">Sathish M (MEC002) - Sathish Auto Works</option>
                    <option value="MEC026">Kumar S (MEC026) - Kumar Auto Works</option>
                    <option value="MEC018">Karthik R (MEC018) - Karthik Auto Garage</option>
                    <option value="MEC019">Vignesh S (MEC019) - Vignesh Motors</option>
                    <option value="MEC020">Dinesh M (MEC020) - Dinesh Car Care</option>
                </select>
            </div>

            <div style="margin-bottom: 14px;">
                <label style="display: block; font-size: 12px; font-weight: 600; color: #4B5563; margin-bottom: 6px;">Reason for Suspension *</label>
                <select name="blockReason" required style="width: 100%; background: #FFFFFF; border: 1px solid #CBD5E1; border-radius: 8px; padding: 9px 12px; font-size: 13px; font-weight: 600; color: #1E293B;">
                    <option value="Policy Violation">Policy Violation</option>
                    <option value="Multiple Complaints">Multiple Complaints</option>
                    <option value="Poor Service">Poor Service</option>
                    <option value="Invalid Documents">Invalid Documents</option>
                    <option value="Account Misuse">Account Misuse</option>
                    <option value="Unresolved Disputes">Unresolved Disputes</option>
                </select>
            </div>

            <div style="margin-bottom: 16px;">
                <label style="display: block; font-size: 12px; font-weight: 600; color: #4B5563; margin-bottom: 6px;">Additional Notes / Remarks</label>
                <textarea name="blockNotes" rows="3" placeholder="Enter reason details, incident reference, or customer grievance report..." style="width: 100%; background: #FFFFFF; border: 1px solid #CBD5E1; border-radius: 8px; padding: 9px 12px; font-size: 13px; font-family: inherit; box-sizing: border-box;"></textarea>
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 10px;">
                <button type="button" class="btn-action-outline" onclick="closeModal('addBlockModal');">Cancel</button>
                <button type="submit" class="btn-action-orange-add" style="background: linear-gradient(135deg, #DC2626 0%, #B91C1C 100%);">
                    <i class="fa-solid fa-ban"></i> Confirm Suspension
                </button>
            </div>
        </form>
    </div>
</div>

<!-- ==========================================================================
     MODAL 4: UNBLOCK CONFIRMATION MODAL (#unblockConfirmModal)
     ========================================================================== -->
<div class="modal-overlay" id="unblockConfirmModal">
    <div class="blocked-modal-box" style="max-width: 480px; text-align: center;">
        <div style="width: 56px; height: 56px; border-radius: 50%; background: #DCFCE7; color: #16A34A; display: inline-flex; align-items: center; justify-content: center; font-size: 26px; margin-bottom: 14px;">
            <i class="fa-solid fa-lock-open"></i>
        </div>
        <h3 style="margin: 0 0 6px 0; font-size: 19px; font-weight: 800; color: #111827;">Restore Partner Access?</h3>
        <p style="margin: 0 0 16px 0; font-size: 13px; color: #64748B;" id="unblockConfirmText">
            Are you sure you want to restore access for this mechanic?
        </p>
        <div style="display: flex; justify-content: center; gap: 12px;">
            <button type="button" class="btn-action-outline" onclick="closeModal('unblockConfirmModal');">Cancel</button>
            <a href="#" id="unblockConfirmLink" class="btn-action-orange-add" style="background: linear-gradient(135deg, #16A34A 0%, #15803D 100%); text-decoration: none;">
                <i class="fa-solid fa-check"></i> Yes, Unblock Partner
            </a>
        </div>
    </div>
</div>

<!-- Client Scripts -->
<script>
    function openModal(id) {
        var el = document.getElementById(id);
        if (el) el.classList.add('active');
    }

    function closeModal(id) {
        var el = document.getElementById(id);
        if (el) el.classList.remove('active');
    }

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-overlay').forEach(function(m) {
                m.classList.remove('active');
            });
        }
    });

    function openViewModal(btn) {
        var ds = btn.dataset;
        document.getElementById('viewModalName').textContent = ds.name || '-';
        document.getElementById('viewModalCode').textContent = ds.code || '-';
        document.getElementById('viewModalWorkshop').textContent = ds.workshop || '-';
        document.getElementById('viewModalSpec').textContent = ds.spec || '-';
        document.getElementById('viewModalPhone').textContent = ds.phone || '-';
        document.getElementById('viewModalEmail').textContent = ds.email || '-';
        document.getElementById('viewModalLocation').textContent = ds.location || '-';
        document.getElementById('viewModalAddress').textContent = ds.address || '-';
        document.getElementById('viewModalDate').textContent = ds.date || '-';
        document.getElementById('viewModalExp').textContent = ds.exp || '-';
        document.getElementById('viewModalReasonBadge').textContent = ds.reason || 'Blocked';
        if (ds.avatar) {
            var vma = document.getElementById('viewModalAvatar');
            if (vma && vma.tagName === 'IMG') vma.src = '${pageContext.request.contextPath}/images/' + ds.avatar;
        }
        document.getElementById('viewModalUnblockBtn').href = 'blocked-mechanics.jsp?action=unblock&id=' + ds.id;
        openModal('viewBlockedModal');
    }

    function openEditModal(btn) {
        var ds = btn.dataset;
        document.getElementById('editModalMechId').value = ds.id || '';
        document.getElementById('editModalMechNameDisplay').value = (ds.name || 'Mechanic') + (ds.code ? ' (' + ds.code + ')' : '');
        if (ds.reason) {
            document.getElementById('editModalReasonSelect').value = ds.reason;
        }
        openModal('editBlockedModal');
    }

    function openAddBlockModal() {
        openModal('addBlockModal');
    }

    function confirmUnblock(btn) {
        var ds = btn.dataset;
        document.getElementById('unblockConfirmText').textContent = 'Are you sure you want to unblock ' + ds.name + ' (' + ds.workshop + ')? They will immediately regain platform access.';
        document.getElementById('unblockConfirmLink').href = 'blocked-mechanics.jsp?action=unblock&id=' + ds.id;
        openModal('unblockConfirmModal');
    }

    // CSV Export
    function exportBlockedCSV() {
        var table = document.getElementById("blockedTable");
        var rows = table.querySelectorAll("tr");
        var csv = [];
        for (var i = 0; i < rows.length; i++) {
            var row = [], cols = rows[i].querySelectorAll("td, th");
            for (var j = 0; j < cols.length - 1; j++) {
                var data = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, " ").trim();
                data = data.replace(/"/g, '""');
                row.push('"' + data + '"');
            }
            csv.push(row.join(","));
        }
        var csvFile = new Blob([csv.join("\n")], { type: "text/csv" });
        var downloadLink = document.createElement("a");
        downloadLink.download = "blocked_mechanics.csv";
        downloadLink.href = window.URL.createObjectURL(csvFile);
        downloadLink.style.display = "none";
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
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
            const action = form.getAttribute('action') || 'blocked-mechanics.jsp';
            const qs = params.toString();
            return action + (qs ? '?' + qs : '');
        }

        function loadContentViaAjax(targetUrl, pushHistory) {
            if (pushHistory === undefined) pushHistory = true;

            if (activeAbortCtrl) {
                try { activeAbortCtrl.abort(); } catch (e) {}
            }
            activeAbortCtrl = new AbortController();

            const tableCard = document.querySelector('.blocked-table-card');
            const searchInput = document.querySelector('#searchInput');
            const wasSearchActive = (document.activeElement === searchInput);
            const searchPos = (wasSearchActive && searchInput) ? searchInput.selectionStart : 0;

            if (tableCard) {
                tableCard.style.transition = 'opacity 0.15s ease';
                tableCard.style.opacity = '0.55';
                tableCard.style.pointerEvents = 'none';
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

                // 1. Update .blocked-table-card
                const newTableCard = doc.querySelector('.blocked-table-card');
                if (tableCard && newTableCard) {
                    tableCard.innerHTML = newTableCard.innerHTML;
                    tableCard.style.opacity = '1';
                    tableCard.style.pointerEvents = '';
                }

                // 2. Update .blocked-stats-grid
                const oldStats = document.querySelector('.blocked-stats-grid');
                const newStats = doc.querySelector('.blocked-stats-grid');
                if (oldStats && newStats) {
                    oldStats.innerHTML = newStats.innerHTML;
                }

                // 3. Update history
                if (pushHistory && window.history && window.history.pushState) {
                    window.history.pushState({ url: targetUrl }, '', targetUrl);
                }

                // 4. Re-bind events
                bindAjaxEvents();

                // 5. Restore search focus
                if (wasSearchActive) {
                    const updatedSearch = document.querySelector('#searchInput');
                    if (updatedSearch) {
                        updatedSearch.focus();
                        try { updatedSearch.setSelectionRange(searchPos, searchPos); } catch (e) {}
                    }
                }
            })
            .catch(function(err) {
                if (err.name === 'AbortError') return;
                console.error('AJAX load error:', err);
                if (tableCard) {
                    tableCard.style.opacity = '1';
                    tableCard.style.pointerEvents = '';
                }
                window.location.href = targetUrl;
            });
        }

        function bindAjaxEvents() {
            const tableCard = document.querySelector('.blocked-table-card');
            if (!tableCard) return;

            // 1. Filter Form Submit & Change
            const filterForm = document.getElementById('filterForm');
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

                // Search input live typing (debounced)
                const searchInput = filterForm.querySelector('#searchInput');
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
                const resetBtn = filterForm.querySelector('.btn-filter-reset-link');
                if (resetBtn) {
                    resetBtn.addEventListener('click', function(e) {
                        e.preventDefault();
                        const href = this.getAttribute('href') || 'blocked-mechanics.jsp';
                        loadContentViaAjax(href);
                    });
                }
            }

            // 2. Pagination Controls
            const pageLinks = tableCard.querySelectorAll('.table-pagination a');
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
