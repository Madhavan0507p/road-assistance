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
<%!
    public static String getVehicleImageUrl(String ctxPath, String imgName, String vType, String vModel) {
        if (imgName == null || imgName.trim().isEmpty()) {
            if (vType != null && (vType.toLowerCase().contains("motorcycle") || vType.toLowerCase().contains("two wheeler"))) {
                return ctxPath + "/images/vehicle-pulsar-lg.jpg";
            } else if (vType != null && vType.toLowerCase().contains("scooter")) {
                return ctxPath + "/images/vehicle-activa.png";
            } else if (vModel != null && vModel.toLowerCase().contains("brezza")) {
                return ctxPath + "/images/vehicle-brezza.png";
            } else if (vModel != null && vModel.toLowerCase().contains("nexon")) {
                return ctxPath + "/images/vehicle-nexon.png";
            }
            return ctxPath + "/images/vehicle-i20-lg.jpg";
        }
        String clean = imgName.trim();
        if (clean.startsWith("http://") || clean.startsWith("https://")) {
            return clean;
        }
        if (clean.startsWith("/")) {
            return ctxPath + clean;
        }
        if (clean.startsWith("veh_") || clean.startsWith("uploads/")) {
            if (clean.startsWith("uploads/")) {
                return ctxPath + "/" + clean;
            }
            return ctxPath + "/uploads/vehicles/" + clean;
        }
        return ctxPath + "/images/" + clean;
    }
%>
<%
    // =========================================================================
    // 1. SESSION AUTHENTICATION & CACHE PREVENTION
    // =========================================================================
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
        return;
    }

    request.setAttribute("activeUserPage", "vehicles");

    int userId = currentUser.getUserId();
    String userFullName = (currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()) 
            ? currentUser.getFullName() : "Raj Kumar";

    // =========================================================================
    // 2. HANDLE CRUD OPERATIONS (POST REQUESTS)
    // =========================================================================
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        if (action == null) action = "";

        Connection actConn = null;
        PreparedStatement actPs = null;
        try {
            actConn = DBConnection.getConnection();

            if ("add".equalsIgnoreCase(action)) {
                String vNum = request.getParameter("vehicle_number");
                String vModel = request.getParameter("vehicle_model");
                String vType = request.getParameter("vehicle_type");
                String fType = request.getParameter("fuel_type");
                String regDate = request.getParameter("registration_date");
                String insExpiry = request.getParameter("insurance_expiry");
                String vStatus = request.getParameter("vehicle_status");
                String isPrimaryStr = request.getParameter("is_primary");
                int isPrimary = "1".equals(isPrimaryStr) ? 1 : 0;

                if (vNum != null) vNum = vNum.trim().toUpperCase();
                if (vModel != null) vModel = vModel.trim();
                if (vType == null || vType.trim().isEmpty()) vType = "Car";
                if (fType == null || fType.trim().isEmpty()) fType = "Petrol";
                if (vStatus == null || vStatus.trim().isEmpty()) vStatus = "Active";

                if (regDate == null || regDate.trim().isEmpty()) {
                    regDate = new SimpleDateFormat("dd-MM-yyyy").format(new Date());
                }
                if (insExpiry == null || insExpiry.trim().isEmpty()) {
                    insExpiry = "09-05-2026";
                }

                // Determine default vehicle image
                String vImg = "vehicle-i20-lg.jpg";
                if ("Motorcycle".equalsIgnoreCase(vType) || "Two Wheeler".equalsIgnoreCase(vType)) {
                    vImg = "vehicle-pulsar-lg.jpg";
                } else if ("Scooter".equalsIgnoreCase(vType)) {
                    vImg = "vehicle-activa.png";
                } else if (vModel != null && vModel.toLowerCase().contains("brezza")) {
                    vImg = "vehicle-brezza.png";
                } else if (vModel != null && vModel.toLowerCase().contains("nexon")) {
                    vImg = "vehicle-nexon.png";
                }

                if (isPrimary == 1) {
                    actPs = actConn.prepareStatement("UPDATE user_vehicles SET is_primary = 0 WHERE user_id = ?");
                    actPs.setInt(1, userId);
                    actPs.executeUpdate();
                    actPs.close();
                }

                String insertSql = "INSERT INTO user_vehicles (user_id, vehicle_number, vehicle_model, vehicle_type, fuel_type, " +
                                  "vehicle_status, registration_date, insurance_expiry, vehicle_image, is_primary) " +
                                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                actPs = actConn.prepareStatement(insertSql);
                actPs.setInt(1, userId);
                actPs.setString(2, vNum);
                actPs.setString(3, vModel);
                actPs.setString(4, vType);
                actPs.setString(5, fType);
                actPs.setString(6, vStatus);
                actPs.setString(7, regDate);
                actPs.setString(8, insExpiry);
                actPs.setString(9, vImg);
                actPs.setInt(10, isPrimary);
                actPs.executeUpdate();

                response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=added");
                return;

            } else if ("edit".equalsIgnoreCase(action)) {
                int vehicleId = Integer.parseInt(request.getParameter("vehicle_id"));
                String vNum = request.getParameter("vehicle_number");
                if (vNum == null || vNum.trim().isEmpty()) {
                    vNum = request.getParameter("registration_number");
                }
                String vBrand = request.getParameter("vehicle_brand");
                String vModel = request.getParameter("vehicle_model");
                String mfgYearStr = request.getParameter("manufacturing_year");
                int mfgYear = 0;
                try { mfgYear = Integer.parseInt(mfgYearStr); } catch (Exception e) {}
                String vType = request.getParameter("vehicle_type");
                String fType = request.getParameter("fuel_type");
                String regDate = request.getParameter("registration_date");
                String insExpiry = request.getParameter("insurance_valid_till");
                if (insExpiry == null || insExpiry.trim().isEmpty()) {
                    insExpiry = request.getParameter("insurance_expiry");
                }
                String insProvider = request.getParameter("insurance_provider");
                String policyNum = request.getParameter("insurance_policy_number");
                String vStatus = request.getParameter("vehicle_status");
                String isPrimaryStr = request.getParameter("is_primary");
                int isPrimary = ("1".equals(isPrimaryStr) || "true".equalsIgnoreCase(isPrimaryStr)) ? 1 : 0;

                if (vNum != null) vNum = vNum.trim().toUpperCase();
                if (vModel != null) vModel = vModel.trim();
                if (vBrand != null) vBrand = vBrand.trim();

                if (isPrimary == 1) {
                    actPs = actConn.prepareStatement("UPDATE user_vehicles SET is_primary = 0 WHERE user_id = ?");
                    actPs.setInt(1, userId);
                    actPs.executeUpdate();
                    actPs.close();
                }

                String updateSql = "UPDATE user_vehicles SET vehicle_number = ?, vehicle_brand = ?, vehicle_model = ?, " +
                                  "manufacturing_year = ?, vehicle_type = ?, fuel_type = ?, registration_date = ?, " +
                                  "insurance_expiry = ?, insurance_provider = ?, insurance_policy_number = ?, " +
                                  "vehicle_status = ?, is_primary = ? WHERE vehicle_id = ? AND user_id = ?";
                actPs = actConn.prepareStatement(updateSql);
                actPs.setString(1, vNum);
                actPs.setString(2, vBrand != null ? vBrand : "");
                actPs.setString(3, vModel != null ? vModel : "");
                actPs.setInt(4, mfgYear);
                actPs.setString(5, vType != null ? vType : "Car");
                actPs.setString(6, fType != null ? fType : "Petrol");
                actPs.setString(7, regDate != null ? regDate : "");
                actPs.setString(8, insExpiry != null ? insExpiry : "");
                actPs.setString(9, insProvider != null ? insProvider : "");
                actPs.setString(10, policyNum != null ? policyNum : "");
                actPs.setString(11, vStatus != null ? vStatus : "Active");
                actPs.setInt(12, isPrimary);
                actPs.setInt(13, vehicleId);
                actPs.setInt(14, userId);
                actPs.executeUpdate();

                response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=updated");
                return;

            } else if ("remove".equalsIgnoreCase(action)) {
                int vehicleId = Integer.parseInt(request.getParameter("vehicle_id"));
                String removeSql = "DELETE FROM user_vehicles WHERE vehicle_id = ? AND user_id = ?";
                actPs = actConn.prepareStatement(removeSql);
                actPs.setInt(1, vehicleId);
                actPs.setInt(2, userId);
                actPs.executeUpdate();

                response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=removed");
                return;

            } else if ("set_primary".equalsIgnoreCase(action)) {
                int vehicleId = Integer.parseInt(request.getParameter("vehicle_id"));
                actPs = actConn.prepareStatement("UPDATE user_vehicles SET is_primary = 0 WHERE user_id = ?");
                actPs.setInt(1, userId);
                actPs.executeUpdate();
                actPs.close();

                actPs = actConn.prepareStatement("UPDATE user_vehicles SET is_primary = 1 WHERE vehicle_id = ? AND user_id = ?");
                actPs.setInt(1, vehicleId);
                actPs.setInt(2, userId);
                actPs.executeUpdate();

                response.sendRedirect(request.getContextPath() + "/user/vehicles.jsp?msg=primary_set");
                return;
            }
        } catch (Exception ex) {
            System.err.println("Vehicle Action Error: " + ex.getMessage());
        } finally {
            DBConnection.closeQuietly(null, actPs, actConn);
        }
    }

    // =========================================================================
    // 3. READ FILTERS & PAGINATION PARAMETERS
    // =========================================================================
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String filterType = request.getParameter("type");
    if (filterType != null) filterType = filterType.trim(); else filterType = "";

    String filterStatus = request.getParameter("status");
    if (filterStatus != null) filterStatus = filterStatus.trim(); else filterStatus = "";

    int currentPage = 1;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try {
            currentPage = Integer.parseInt(pageParam.trim());
            if (currentPage < 1) currentPage = 1;
        } catch (NumberFormatException ignored) {}
    }

    int pageSize = 10; // Exactly 10 vehicles per page

    // =========================================================================
    // 4. DATABASE QUERIES: COUNTS & FILTERED DATA
    // =========================================================================
    int totalCount = 0;
    int activeCount = 0;
    int inServiceCount = 0;
    int inactiveCount = 0;
    int filteredTotal = 0;
    List vehicleCards = new ArrayList();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {
            // A. Statistics Queries
            String statsSql = "SELECT " +
                    "COUNT(*) AS total, " +
                    "SUM(CASE WHEN vehicle_status = 'Active' THEN 1 ELSE 0 END) AS active_cnt, " +
                    "SUM(CASE WHEN vehicle_status = 'In Service' THEN 1 ELSE 0 END) AS service_cnt, " +
                    "SUM(CASE WHEN vehicle_status = 'Inactive' THEN 1 ELSE 0 END) AS inactive_cnt " +
                    "FROM user_vehicles WHERE user_id = ?";
            ps = conn.prepareStatement(statsSql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                totalCount = rs.getInt("total");
                activeCount = rs.getInt("active_cnt");
                inServiceCount = rs.getInt("service_cnt");
                inactiveCount = rs.getInt("inactive_cnt");
            }
            rs.close();
            ps.close();

            // A2. Fetch Active Breakdown Requests for logged-in user's vehicles
            Map activeVehicleRequests = new HashMap();
            try {
                PreparedStatement psAct = conn.prepareStatement(
                    "SELECT request_code, vehicle_number, status, breakdown_issue FROM service_requests " +
                    "WHERE user_id = ? AND status NOT IN ('Completed', 'Cancelled', 'Rejected') ORDER BY request_id DESC"
                );
                psAct.setInt(1, userId);
                ResultSet rsAct = psAct.executeQuery();
                while (rsAct.next()) {
                    String vRaw = rsAct.getString("vehicle_number");
                    if (vRaw != null && !vRaw.trim().isEmpty()) {
                        String vClean = vRaw.replaceAll("[\\s-]", "").toUpperCase();
                        if (!activeVehicleRequests.containsKey(vClean)) {
                            Map info = new HashMap();
                            info.put("code", rsAct.getString("request_code"));
                            info.put("status", rsAct.getString("status"));
                            info.put("issue", rsAct.getString("breakdown_issue"));
                            activeVehicleRequests.put(vClean, info);
                        }
                    }
                }
                rsAct.close();
                psAct.close();
            } catch (Exception ignAct) {}

            // B. Filtered Count Query
            StringBuilder whereClause = new StringBuilder(" WHERE user_id = ? ");
            List paramValues = new ArrayList();
            paramValues.add(userId);

            if (!search.isEmpty()) {
                whereClause.append(" AND (vehicle_number LIKE ? OR vehicle_model LIKE ? OR fuel_type LIKE ?) ");
                String p = "%" + search + "%";
                paramValues.add(p);
                paramValues.add(p);
                paramValues.add(p);
            }

            if (!filterType.isEmpty() && !"All".equalsIgnoreCase(filterType) && !"All Vehicle Types".equalsIgnoreCase(filterType)) {
                whereClause.append(" AND vehicle_type = ? ");
                paramValues.add(filterType);
            }

            if (!filterStatus.isEmpty() && !"All".equalsIgnoreCase(filterStatus) && !"All Status".equalsIgnoreCase(filterStatus)) {
                whereClause.append(" AND vehicle_status = ? ");
                paramValues.add(filterStatus);
            }

            String countSql = "SELECT COUNT(*) FROM user_vehicles " + whereClause.toString();
            ps = conn.prepareStatement(countSql);
            for (int i = 0; i < paramValues.size(); i++) {
                ps.setObject(i + 1, paramValues.get(i));
            }
            rs = ps.executeQuery();
            if (rs.next()) {
                filteredTotal = rs.getInt(1);
            }
            rs.close();
            ps.close();

            // C. Filtered Paginated Data Query
            int offset = (currentPage - 1) * pageSize;
            String dataSql = "SELECT vehicle_id, vehicle_number, vehicle_brand, vehicle_model, manufacturing_year, " +
                             "vehicle_type, fuel_type, vehicle_status, registration_date, insurance_expiry, " +
                             "insurance_provider, insurance_policy_number, vehicle_image, vehicle_photos, is_primary " +
                             "FROM user_vehicles " + whereClause.toString() +
                             " ORDER BY is_primary DESC, vehicle_id ASC LIMIT ? OFFSET ?";
            ps = conn.prepareStatement(dataSql);
            int pIdx = 1;
            for (int i = 0; i < paramValues.size(); i++) {
                ps.setObject(pIdx++, paramValues.get(i));
            }
            ps.setInt(pIdx++, pageSize);
            ps.setInt(pIdx++, offset);

            rs = ps.executeQuery();
            while (rs.next()) {
                Map v = new HashMap();
                v.put("id", rs.getInt("vehicle_id"));
                v.put("number", rs.getString("vehicle_number"));
                v.put("brand", rs.getString("vehicle_brand") != null ? rs.getString("vehicle_brand") : "");
                v.put("model", rs.getString("vehicle_model") != null ? rs.getString("vehicle_model") : "");
                v.put("mfg_year", rs.getObject("manufacturing_year") != null ? rs.getInt("manufacturing_year") : "");
                v.put("type", rs.getString("vehicle_type") != null ? rs.getString("vehicle_type") : "");
                v.put("fuel", rs.getString("fuel_type") != null ? rs.getString("fuel_type") : "");
                v.put("status", rs.getString("vehicle_status") != null ? rs.getString("vehicle_status") : "Active");
                String rawReg = rs.getString("registration_date");
                String rawIns = rs.getString("insurance_expiry");
                String regFormatted = rawReg != null ? rawReg.trim() : "";
                if (!regFormatted.isEmpty() && !regFormatted.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                    try {
                        Date p = null;
                        try { p = new SimpleDateFormat("yyyy-MM-dd").parse(regFormatted); } catch (Exception ign1) {}
                        if (p == null) {
                            try { p = new SimpleDateFormat("MMM d, yyyy").parse(regFormatted); } catch (Exception ign2) {}
                        }
                        if (p != null) regFormatted = new SimpleDateFormat("dd-MM-yyyy").format(p);
                    } catch (Exception ign) {}
                }
                String insFormatted = rawIns != null ? rawIns.trim() : "";
                if (!insFormatted.isEmpty() && !insFormatted.matches("^\\d{2}-\\d{2}-\\d{4}$")) {
                    try {
                        Date p = null;
                        try { p = new SimpleDateFormat("yyyy-MM-dd").parse(insFormatted); } catch (Exception ign1) {}
                        if (p == null) {
                            try { p = new SimpleDateFormat("MMM d, yyyy").parse(insFormatted); } catch (Exception ign2) {}
                        }
                        if (p != null) insFormatted = new SimpleDateFormat("dd-MM-yyyy").format(p);
                    } catch (Exception ign) {}
                }
                v.put("reg_date", regFormatted);
                v.put("ins_expiry", insFormatted);
                v.put("ins_provider", rs.getString("insurance_provider") != null ? rs.getString("insurance_provider") : "");
                v.put("policy_number", rs.getString("insurance_policy_number") != null ? rs.getString("insurance_policy_number") : "");
                v.put("image", rs.getString("vehicle_image"));
                v.put("photos", rs.getString("vehicle_photos") != null ? rs.getString("vehicle_photos") : "");
                v.put("primary", rs.getInt("is_primary") == 1);

                String vNumStr = rs.getString("vehicle_number");
                String vCleanStr = (vNumStr != null) ? vNumStr.replaceAll("[\\s-]", "").toUpperCase() : "";
                boolean isOnReq = activeVehicleRequests.containsKey(vCleanStr);
                Map actReq = isOnReq ? (Map) activeVehicleRequests.get(vCleanStr) : null;
                v.put("is_on_request", isOnReq);
                v.put("active_code", isOnReq ? actReq.get("code") : "");
                v.put("active_status", isOnReq ? actReq.get("status") : "");

                vehicleCards.add(v);
            }
            rs.close();
            ps.close();
        }
    } catch (Exception e) {
        System.err.println("Vehicles Query Notice: " + e.getMessage());
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }

    // Default Fallbacks if fresh account with 0 rows
    if (totalCount == 0 && vehicleCards.isEmpty()) {
        totalCount = 2;
        activeCount = 2;
        inServiceCount = 0;
        inactiveCount = 0;
        filteredTotal = 2;

        Map v1 = new HashMap();
        v1.put("id", 1);
        v1.put("number", "TN 45 AB 1234");
        v1.put("model", "Hyundai i20");
        v1.put("type", "Car");
        v1.put("fuel", "Petrol");
        v1.put("status", "Active");
        v1.put("reg_date", "10-05-2023");
        v1.put("ins_expiry", "09-05-2026");
        v1.put("image", "vehicle-i20-lg.jpg");
        v1.put("primary", true);
        vehicleCards.add(v1);

        Map v2 = new HashMap();
        v2.put("id", 12);
        v2.put("number", "TN 48 EF 4321");
        v2.put("model", "Bajaj Pulsar 150");
        v2.put("type", "Motorcycle");
        v2.put("fuel", "Petrol");
        v2.put("status", "Active");
        v2.put("reg_date", "21-08-2022");
        v2.put("ins_expiry", "20-08-2027");
        v2.put("image", "vehicle-pulsar-lg.jpg");
        v2.put("primary", false);
        vehicleCards.add(v2);
    }

    int totalPages = (int) Math.ceil((double) filteredTotal / pageSize);
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int showingStart = (filteredTotal > 0) ? ((currentPage - 1) * pageSize + 1) : 0;
    int showingEnd = Math.min(currentPage * pageSize, filteredTotal);

    String msgParam = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Vehicles — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Theme & Dedicated Page Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-vehicles.css">
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <div class="my-vehicles-container">
                <!-- Outer White Card Wrapper matching Reference Screenshot -->
                <div class="my-vehicles-main-card">
                    
                    <!-- Flash Messages / Notifications -->
                    <% if ("added".equals(msgParam)) { %>
                    <div class="alert-toast alert-success" id="toastNotice">
                        <span><i class="fa-solid fa-circle-check" style="margin-right: 8px;"></i> Vehicle registered successfully!</span>
                        <button type="button" class="btn-modal-close" style="width: 24px; height: 24px;" onclick="document.getElementById('toastNotice').style.display='none';">&times;</button>
                    </div>
                    <% } else if ("updated".equals(msgParam)) { %>
                    <div class="alert-toast alert-success" id="toastNotice">
                        <span><i class="fa-solid fa-circle-check" style="margin-right: 8px;"></i> Vehicle details updated successfully!</span>
                        <button type="button" class="btn-modal-close" style="width: 24px; height: 24px;" onclick="document.getElementById('toastNotice').style.display='none';">&times;</button>
                    </div>
                    <% } else if ("removed".equals(msgParam)) { %>
                    <div class="alert-toast alert-danger" id="toastNotice">
                        <span><i class="fa-solid fa-trash-can" style="margin-right: 8px;"></i> Vehicle removed from your account.</span>
                        <button type="button" class="btn-modal-close" style="width: 24px; height: 24px;" onclick="document.getElementById('toastNotice').style.display='none';">&times;</button>
                    </div>
                    <% } else if ("primary_set".equals(msgParam)) { %>
                    <div class="alert-toast alert-success" id="toastNotice">
                        <span><i class="fa-solid fa-star" style="margin-right: 8px;"></i> Primary vehicle updated successfully!</span>
                        <button type="button" class="btn-modal-close" style="width: 24px; height: 24px;" onclick="document.getElementById('toastNotice').style.display='none';">&times;</button>
                    </div>
                    <% } %>

                    <!-- =======================================================
                         A. HEADER ROW: Title + Subtitle + Breadcrumbs
                         ======================================================= -->
                    <div class="vehicles-header-row">
                        <div class="vehicles-title-group">
                            <div class="vehicles-icon-badge">
                                <i class="fa-solid fa-car"></i>
                            </div>
                            <div class="vehicles-title-text">
                                <h1>My <span class="accent-orange">Vehicles</span></h1>
                                <p>Manage your registered vehicles and keep their details up to date.</p>
                            </div>
                        </div>

                        <div class="vehicles-breadcrumb">
                            <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="breadcrumb-link">
                                <i class="fa-solid fa-house"></i> Dashboard
                            </a>
                            <span class="breadcrumb-separator"><i class="fa-solid fa-chevron-right"></i></span>
                            <span class="breadcrumb-current">My Vehicles</span>
                        </div>
                    </div>

                    <!-- =======================================================
                         B. STATISTICS CARDS (ROW OF 4)
                         ======================================================= -->
                    <div class="vehicles-stats-grid">
                        <!-- 1. Total Vehicles -->
                        <div class="stat-card stat-total">
                            <div class="stat-icon-box">
                                <i class="fa-solid fa-car"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-label">Total Vehicles</span>
                                <span class="stat-number"><%= totalCount %></span>
                            </div>
                        </div>

                        <!-- 2. Active -->
                        <div class="stat-card stat-active">
                            <div class="stat-icon-box">
                                <i class="fa-solid fa-check"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-label">Active</span>
                                <span class="stat-number"><%= activeCount %></span>
                            </div>
                        </div>

                        <!-- 3. In Service -->
                        <div class="stat-card stat-service">
                            <div class="stat-icon-box">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-label">In Service</span>
                                <span class="stat-number"><%= inServiceCount %></span>
                            </div>
                        </div>

                        <!-- 4. Inactive -->
                        <div class="stat-card stat-inactive">
                            <div class="stat-icon-box">
                                <i class="fa-solid fa-xmark"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-label">Inactive</span>
                                <span class="stat-number"><%= inactiveCount %></span>
                            </div>
                        </div>
                    </div>

                    <!-- =======================================================
                         C. SEARCH & FILTER TOOLBAR
                         ======================================================= -->
                    <form method="GET" action="vehicles.jsp" id="filterForm" class="vehicles-toolbar">
                        <!-- Search Box -->
                        <div class="search-box-wrapper">
                            <i class="fa-solid fa-magnifying-glass search-icon"></i>
                            <input type="text" name="search" id="searchInput" class="search-input"
                                   placeholder="Search by Vehicle Number, Model or Brand..."
                                   value="<%= search %>">
                        </div>

                        <!-- Vehicle Type Dropdown -->
                        <div class="filter-dropdown-wrapper">
                            <i class="fa-solid fa-car filter-icon"></i>
                            <select name="type" id="typeSelect" class="filter-select" onchange="document.getElementById('filterForm').submit();">
                                <option value="" <%= filterType.isEmpty() ? "selected" : "" %>>All Vehicle Types</option>
                                <option value="Car" <%= "Car".equalsIgnoreCase(filterType) ? "selected" : "" %>>Car</option>
                                <option value="Motorcycle" <%= "Motorcycle".equalsIgnoreCase(filterType) ? "selected" : "" %>>Motorcycle</option>
                                <option value="Scooter" <%= "Scooter".equalsIgnoreCase(filterType) ? "selected" : "" %>>Scooter</option>
                                <option value="SUV" <%= "SUV".equalsIgnoreCase(filterType) ? "selected" : "" %>>SUV</option>
                                <option value="Two Wheeler" <%= "Two Wheeler".equalsIgnoreCase(filterType) ? "selected" : "" %>>Two Wheeler</option>
                                <option value="Four Wheeler" <%= "Four Wheeler".equalsIgnoreCase(filterType) ? "selected" : "" %>>Four Wheeler</option>
                            </select>
                            <i class="fa-solid fa-chevron-down dropdown-caret"></i>
                        </div>

                        <!-- Status Dropdown -->
                        <div class="filter-dropdown-wrapper">
                            <i class="fa-solid fa-chart-line filter-icon"></i>
                            <select name="status" id="statusSelect" class="filter-select" onchange="document.getElementById('filterForm').submit();">
                                <option value="" <%= filterStatus.isEmpty() ? "selected" : "" %>>All Status</option>
                                <option value="Active" <%= "Active".equalsIgnoreCase(filterStatus) ? "selected" : "" %>>Active</option>
                                <option value="In Service" <%= "In Service".equalsIgnoreCase(filterStatus) ? "selected" : "" %>>In Service</option>
                                <option value="Inactive" <%= "Inactive".equalsIgnoreCase(filterStatus) ? "selected" : "" %>>Inactive</option>
                            </select>
                            <i class="fa-solid fa-chevron-down dropdown-caret"></i>
                        </div>

                        <!-- Add New Vehicle Button -->
                        <a href="${pageContext.request.contextPath}/user/add-vehicle.jsp" class="btn-add-vehicle" style="text-decoration: none;">
                            <i class="fa-solid fa-plus"></i> Add New Vehicle
                        </a>
                    </form>

                    <!-- =======================================================
                         D. VEHICLE CARDS GRID (2 PER ROW)
                         ======================================================= -->
                    <% if (vehicleCards.isEmpty()) { %>
                    <div class="vehicles-empty-state">
                        <div class="empty-icon-circle">
                            <i class="fa-solid fa-car-side"></i>
                        </div>
                        <h3 class="empty-title">No vehicles found</h3>
                        <p class="empty-desc">No vehicle matches your search criteria. Try clearing the filters or register a new vehicle.</p>
                        <a href="vehicles.jsp" class="btn-empty-action">
                            <i class="fa-solid fa-arrow-rotate-left"></i> Reset Filters
                        </a>
                    </div>
                    <% } else { %>
                    <div class="vehicles-grid">
                        <%
                            for (int i = 0; i < vehicleCards.size(); i++) {
                                Map card = (Map) vehicleCards.get(i);
                                int vId = (Integer) card.get("id");
                                String vNum = (String) card.get("number");
                                String vBrand = (String) card.get("brand");
                                String vModel = (String) card.get("model");
                                String vType = (String) card.get("type");
                                String fType = (String) card.get("fuel");
                                String vStatus = (String) card.get("status");
                                String regDate = (String) card.get("reg_date");
                                String insExpiry = (String) card.get("ins_expiry");
                                String vImg = (String) card.get("image");
                                boolean isPrim = (Boolean) card.get("primary");
                                boolean isOnReq = card.get("is_on_request") != null && (Boolean) card.get("is_on_request");
                                String actCode = isOnReq ? (String) card.get("active_code") : "";
                                String actStatus = isOnReq ? (String) card.get("active_status") : "";

                                String statusClass = "status-active";
                                String statusIcon = "fa-check";
                                if ("In Service".equalsIgnoreCase(vStatus)) {
                                    statusClass = "status-service";
                                    statusIcon = "fa-wrench";
                                } else if ("Inactive".equalsIgnoreCase(vStatus)) {
                                    statusClass = "status-inactive";
                                    statusIcon = "fa-xmark";
                                }

                                String typeIcon = "fa-car";
                                if ("Motorcycle".equalsIgnoreCase(vType) || "Two Wheeler".equalsIgnoreCase(vType) || "Scooter".equalsIgnoreCase(vType)) {
                                    typeIcon = "fa-motorcycle";
                                }
                        %>
                        <div class="vehicle-card" id="card-<%= vId %>">
                            <div>
                                <!-- Top: Image + Info -->
                                <div class="card-top-flex">
                                    <div class="vehicle-img-wrapper">
                                        <img src="<%= getVehicleImageUrl(request.getContextPath(), vImg, vType, vModel) %>" 
                                             alt="<%= vModel %>" 
                                             onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-i20-lg.jpg';">
                                    </div>

                                    <div class="vehicle-main-details">
                                        <div class="vehicle-reg-row">
                                            <h2 class="vehicle-number-text"><%= vNum %></h2>
                                            
                                            <!-- 3-Dot Action Menu -->
                                            <div class="action-menu-container">
                                                <button type="button" class="btn-dots-menu" onclick="toggleDotsMenu(event, 'menu-<%= vId %>');">
                                                    <i class="fa-solid fa-ellipsis-vertical"></i>
                                                </button>
                                                <div class="dots-dropdown" id="menu-<%= vId %>">
                                                    <button type="button" class="dots-dropdown-item" 
                                                            onclick="openViewModal('<%= vId %>');">
                                                        <i class="fa-solid fa-eye"></i> View Details
                                                    </button>
                                                    <button type="button" class="dots-dropdown-item" 
                                                            onclick="openEditModal('<%= vId %>');">
                                                        <i class="fa-solid fa-pencil"></i> Edit Vehicle
                                                    </button>
                                                    <% if (!isPrim) { %>
                                                    <form method="POST" action="vehicles.jsp" style="margin: 0;">
                                                        <input type="hidden" name="action" value="set_primary">
                                                        <input type="hidden" name="vehicle_id" value="<%= vId %>">
                                                        <button type="submit" class="dots-dropdown-item">
                                                            <i class="fa-solid fa-star"></i> Set as Primary
                                                        </button>
                                                    </form>
                                                    <% } %>
                                                    <button type="button" class="dots-dropdown-item item-danger" 
                                                            onclick="openRemoveModal('<%= vId %>', '<%= vNum %>');">
                                                        <i class="fa-solid fa-trash-can"></i> Remove
                                                    </button>
                                                </div>
                                            </div>
                                        </div>

                                        <p class="vehicle-model-text"><%= (vBrand != null && !vBrand.isEmpty() ? vBrand + " " : "") + vModel %></p>

                                        <div style="display: flex; align-items: center; flex-wrap: wrap; gap: 6px;">
                                            <span class="status-pill <%= statusClass %>">
                                                <i class="fa-solid <%= statusIcon %>"></i> <%= vStatus %>
                                            </span>
                                            <% if (isOnReq) { %>
                                            <a href="my-requests.jsp" class="status-pill" style="background: #FFF7ED; color: #EA580C; border: 1px solid #FDBA74; text-decoration: none; font-weight: 800;" title="Ongoing breakdown request: <%= actCode %> (<%= actStatus %>)">
                                                <i class="fa-solid fa-clock-rotate-left"></i> On Request (<%= actCode %>)
                                            </a>
                                            <% } %>
                                            <% if (isPrim) { %>
                                            <span class="primary-tag">
                                                <i class="fa-solid fa-star"></i> Primary
                                            </span>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>

                                <!-- Middle: 2-Column Specs Grid -->
                                <div class="vehicle-specs-grid">
                                    <!-- Spec 1: Vehicle Type -->
                                    <div class="spec-item">
                                        <div class="spec-icon-box">
                                            <i class="fa-solid <%= typeIcon %>"></i>
                                        </div>
                                        <div class="spec-info-text">
                                            <span class="spec-label">Vehicle Type</span>
                                            <span class="spec-val"><%= vType %></span>
                                        </div>
                                    </div>

                                    <!-- Spec 2: Fuel Type -->
                                    <div class="spec-item">
                                        <div class="spec-icon-box">
                                            <i class="fa-solid fa-gas-pump"></i>
                                        </div>
                                        <div class="spec-info-text">
                                            <span class="spec-label">Fuel Type</span>
                                            <span class="spec-val"><%= fType %></span>
                                        </div>
                                    </div>

                                    <!-- Spec 3: Brand -->
                                    <div class="spec-item">
                                        <div class="spec-icon-box">
                                            <i class="fa-solid fa-tag"></i>
                                        </div>
                                        <div class="spec-info-text">
                                            <span class="spec-label">Brand</span>
                                            <span class="spec-val"><%= vBrand != null && !vBrand.isEmpty() ? vBrand : "-" %></span>
                                        </div>
                                    </div>

                                    <!-- Spec 4: Manufacturing Year -->
                                    <div class="spec-item">
                                        <div class="spec-icon-box">
                                            <i class="fa-solid fa-calendar-days"></i>
                                        </div>
                                        <div class="spec-info-text">
                                            <span class="spec-label">Mfg Year</span>
                                            <span class="spec-val"><%= (card.get("mfg_year") != null && !card.get("mfg_year").toString().isEmpty()) ? card.get("mfg_year") : "-" %></span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Bottom: 3 Action Buttons -->
                            <div class="vehicle-card-actions">
                                <button type="button" class="btn-card-action btn-view"
                                        onclick="openViewModal('<%= vId %>');">
                                    <i class="fa-solid fa-eye"></i> View Details
                                </button>
                                <button type="button" class="btn-card-action btn-edit"
                                        onclick="openEditModal('<%= vId %>');">
                                    <i class="fa-solid fa-pencil"></i> Edit
                                </button>
                                <button type="button" class="btn-card-action btn-remove"
                                        onclick="openRemoveModal('<%= vId %>', '<%= vNum %>');">
                                    <i class="fa-solid fa-trash-can"></i> Remove
                                </button>
                            </div>
                        </div>
                        <% } %>
                    </div>
                    <% } %>

                    <!-- =======================================================
                         E. PAGINATION FOOTER
                         ======================================================= -->
                    <div class="vehicles-pagination-bar">
                        <div class="pagination-info-text">
                            Showing <%= showingStart %> to <%= showingEnd %> of <%= filteredTotal %> vehicles
                        </div>

                        <div class="pagination-controls">
                            <!-- First Page -->
                            <a href="vehicles.jsp?page=1&search=<%= search %>&type=<%= filterType %>&status=<%= filterStatus %>"
                               class="page-btn <%= (currentPage <= 1) ? "disabled" : "" %>" title="First Page">
                                <i class="fa-solid fa-angles-left"></i>
                            </a>

                            <!-- Previous Page -->
                            <a href="vehicles.jsp?page=<%= currentPage - 1 %>&search=<%= search %>&type=<%= filterType %>&status=<%= filterStatus %>"
                               class="page-btn <%= (currentPage <= 1) ? "disabled" : "" %>" title="Previous Page">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>

                            <!-- Page Numbers -->
                            <% for (int p = 1; p <= totalPages; p++) { %>
                            <a href="vehicles.jsp?page=<%= p %>&search=<%= search %>&type=<%= filterType %>&status=<%= filterStatus %>"
                               class="page-btn <%= (p == currentPage) ? "active" : "" %>">
                                <%= p %>
                            </a>
                            <% } %>

                            <!-- Next Page -->
                            <a href="vehicles.jsp?page=<%= currentPage + 1 %>&search=<%= search %>&type=<%= filterType %>&status=<%= filterStatus %>"
                               class="page-btn <%= (currentPage >= totalPages) ? "disabled" : "" %>" title="Next Page">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>

                            <!-- Last Page -->
                            <a href="vehicles.jsp?page=<%= totalPages %>&search=<%= search %>&type=<%= filterType %>&status=<%= filterStatus %>"
                               class="page-btn <%= (currentPage >= totalPages) ? "disabled" : "" %>" title="Last Page">
                                <i class="fa-solid fa-angles-right"></i>
                            </a>
                        </div>
                    </div>

                </div>
            </div>

        </main>
    </div>

    <!-- =======================================================================
         MODAL 1: ADD NEW VEHICLE
         ======================================================================= -->
    <div class="vehicle-modal-overlay" id="modalAddVehicle" onclick="if(event.target===this) closeAddModal();">
        <div class="vehicle-modal-card">
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge">
                        <i class="fa-solid fa-plus"></i>
                    </div>
                    <div>
                        <h3>Add New Vehicle</h3>
                        <p>Register your vehicle for fast roadside assistance</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeAddModal();">&times;</button>
            </div>

            <form method="POST" action="vehicles.jsp">
                <input type="hidden" name="action" value="add">
                
                <div class="modal-body-content">
                    <div class="modal-form-grid">
                        <!-- Vehicle Registration Number -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Number <span class="req">*</span></label>
                            <input type="text" name="vehicle_number" class="modal-input" placeholder="e.g. TN 45 AB 1234" required pattern="[A-Za-z0-9\s]{6,15}">
                        </div>

                        <!-- Vehicle Model -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Model <span class="req">*</span></label>
                            <input type="text" name="vehicle_model" class="modal-input" placeholder="e.g. Hyundai i20" required>
                        </div>

                        <!-- Vehicle Type -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Type <span class="req">*</span></label>
                            <select name="vehicle_type" class="modal-select" required>
                                <option value="Car">Car</option>
                                <option value="Motorcycle">Motorcycle</option>
                                <option value="Scooter">Scooter</option>
                                <option value="SUV">SUV</option>
                                <option value="Two Wheeler">Two Wheeler</option>
                                <option value="Four Wheeler">Four Wheeler</option>
                            </select>
                        </div>

                        <!-- Fuel Type -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Fuel Type <span class="req">*</span></label>
                            <select name="fuel_type" class="modal-select" required>
                                <option value="Petrol">Petrol</option>
                                <option value="Diesel">Diesel</option>
                                <option value="Electric">Electric</option>
                                <option value="CNG">CNG</option>
                                <option value="Hybrid">Hybrid</option>
                            </select>
                        </div>

                        <!-- Status -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Status</label>
                            <select name="vehicle_status" class="modal-select">
                                <option value="Active">Active</option>
                                <option value="In Service">In Service</option>
                                <option value="Inactive">Inactive</option>
                            </select>
                        </div>

                        <!-- Primary Checkbox -->
                        <div class="modal-form-group full-width" style="margin-top: 6px;">
                            <label class="modal-checkbox-row">
                                <input type="checkbox" name="is_primary" value="1">
                                <span>Set as Primary vehicle for instant emergency requests</span>
                            </label>
                        </div>
                    </div>
                </div>

                <div class="modal-footer-bar">
                    <button type="button" class="btn-modal-cancel" onclick="closeAddModal();">Cancel</button>
                    <button type="submit" class="btn-modal-submit">
                        <i class="fa-solid fa-check"></i> Save Vehicle
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- =======================================================================
         MODAL 2: EDIT VEHICLE (COMPREHENSIVE - MATCHING ADD-VEHICLE FORM)
         ======================================================================= -->
    <div class="vehicle-modal-overlay" id="modalEditVehicle" onclick="if(event.target===this) closeEditModal();">
        <div class="vehicle-modal-card modal-edit-card">
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge">
                        <i class="fa-solid fa-pencil"></i>
                    </div>
                    <div>
                        <h3>Edit Vehicle Details</h3>
                        <p id="editSubtitle">Update all specifications, insurance, and photos</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeEditModal();">&times;</button>
            </div>

            <form id="editVehicleForm" method="POST" action="${pageContext.request.contextPath}/VehicleServlet" enctype="multipart/form-data">
                <input type="hidden" name="action" value="edit">
                <input type="hidden" name="vehicle_id" id="editVehicleId">
                
                <div class="modal-body-scroll">
                    <!-- SECTION 1: VEHICLE DETAILS -->
                    <div class="modal-section-banner">
                        <div class="modal-section-icon"><i class="fa-solid fa-car"></i></div>
                        <h4 class="modal-section-title">Vehicle Details</h4>
                        <span class="modal-section-desc">Basic Information</span>
                    </div>

                    <div class="modal-form-grid-3">
                        <!-- Vehicle Type -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Type <span class="req">*</span></label>
                            <select name="vehicle_type" id="editVehicleType" class="modal-select" required>
                                <option value="Car">Car</option>
                                <option value="Bike / Motorcycle">Bike / Motorcycle</option>
                                <option value="Auto Rickshaw">Auto Rickshaw</option>
                                <option value="Scooter">Scooter</option>
                                <option value="Bus / Van">Bus / Van</option>
                                <option value="Truck / Heavy Vehicle">Truck / Heavy Vehicle</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>

                        <!-- Registration Number -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Registration Number <span class="req">*</span></label>
                            <input type="text" name="registration_number" id="editVehicleNumber" class="modal-input" 
                                   placeholder="TN 45 AB 1234" maxlength="13" required>
                        </div>

                        <!-- Vehicle Brand -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Brand <span class="req">*</span></label>
                            <select name="vehicle_brand" id="editVehicleBrand" class="modal-select" required>
                                <option value="Hyundai">Hyundai</option>
                                <option value="Maruti Suzuki">Maruti Suzuki</option>
                                <option value="Tata Motors">Tata Motors</option>
                                <option value="Honda">Honda</option>
                                <option value="Toyota">Toyota</option>
                                <option value="Mahindra">Mahindra</option>
                                <option value="Kia">Kia</option>
                                <option value="Volkswagen">Volkswagen</option>
                                <option value="Skoda">Skoda</option>
                                <option value="Renault">Renault</option>
                                <option value="Nissan">Nissan</option>
                                <option value="MG Motor">MG Motor</option>
                                <option value="BMW">BMW</option>
                                <option value="Mercedes-Benz">Mercedes-Benz</option>
                                <option value="Audi">Audi</option>
                                <option value="Bajaj">Bajaj</option>
                                <option value="Royal Enfield">Royal Enfield</option>
                                <option value="TVS">TVS</option>
                                <option value="Hero MotoCorp">Hero MotoCorp</option>
                                <option value="Yamaha">Yamaha</option>
                                <option value="KTM">KTM</option>
                                <option value="Suzuki">Suzuki</option>
                                <option value="Ather Energy">Ather Energy</option>
                                <option value="Ola Electric">Ola Electric</option>
                                <option value="Ashok Leyland">Ashok Leyland</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>

                    <div class="modal-form-grid-3">
                        <!-- Vehicle Model -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Model <span class="req">*</span></label>
                            <input type="text" name="vehicle_model" id="editVehicleModel" class="modal-input" placeholder="e.g. i20, Polo, Swift" required>
                        </div>

                        <!-- Manufacturing Year -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Manufacturing Year <span class="req">*</span></label>
                            <select name="manufacturing_year" id="editMfgYear" class="modal-select" required>
                                <% 
                                    int currYr = java.time.Year.now().getValue();
                                    for (int y = currYr; y >= 1980; y--) { 
                                %>
                                <option value="<%= y %>"><%= y %></option>
                                <% } %>
                            </select>
                        </div>

                        <!-- Fuel Type -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Fuel Type <span class="req">*</span></label>
                            <select name="fuel_type" id="editFuelType" class="modal-select" required>
                                <option value="Petrol">Petrol</option>
                                <option value="Diesel">Diesel</option>
                                <option value="Electric (EV)">Electric (EV)</option>
                                <option value="CNG">CNG</option>
                                <option value="Hybrid">Hybrid</option>
                                <option value="LPG">LPG</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>

                    <div class="modal-form-grid" style="grid-template-columns: 1fr; margin-bottom: 12px;">
                        <!-- Status -->
                        <div class="modal-form-group">
                            <label class="modal-form-label">Vehicle Status</label>
                            <select name="vehicle_status" id="editStatus" class="modal-select">
                                <option value="Active">Active</option>
                                <option value="In Service">In Service</option>
                                <option value="Inactive">Inactive</option>
                            </select>
                        </div>
                    </div>

                    <!-- SECTION 2: VEHICLE PHOTOS -->
                    <div class="modal-section-banner">
                        <div class="modal-section-icon"><i class="fa-solid fa-camera"></i></div>
                        <h4 class="modal-section-title">Vehicle Photos</h4>
                        <span class="modal-section-desc">Manage images</span>
                    </div>

                    <div class="edit-photos-section">
                        <div class="edit-current-photos-label">Current Photos</div>
                        <div class="edit-photos-gallery" id="editExistingPhotosGallery">
                            <!-- Populated dynamically by openEditModal -->
                        </div>

                        <!-- Upload New Photos Dropzone -->
                        <div class="edit-upload-box" onclick="document.getElementById('editPhotosInput').click();">
                            <input type="file" id="editPhotosInput" name="photos" multiple accept="image/png, image/jpeg, image/jpg" style="display: none;">
                            <div class="edit-upload-icon"><i class="fa-solid fa-cloud-arrow-up"></i></div>
                            <div class="edit-upload-text">Upload new photos</div>
                            <span class="edit-upload-subtext">JPG, JPEG, PNG (Max 5 MB each, up to 5 photos) - Replaces current photos if uploaded</span>
                        </div>

                        <div class="edit-new-previews-grid" id="editNewPhotosPreviews">
                            <!-- Populated when user picks new files -->
                        </div>
                    </div>

                    <!-- SECTION 4: PREFERENCES -->
                    <div class="modal-form-group full-width" style="margin-top: 16px;">
                        <label class="modal-checkbox-row">
                            <input type="checkbox" name="is_primary" id="editIsPrimary" value="1">
                            <span style="font-weight: 600; color: #1F2937;">Set as Primary vehicle for instant emergency requests</span>
                        </label>
                    </div>
                </div>

                <div class="modal-footer-bar">
                    <button type="button" class="btn-modal-cancel" onclick="closeEditModal();">Cancel</button>
                    <button type="submit" class="btn-modal-submit" id="btnEditSubmit">
                        <i class="fa-solid fa-check"></i> Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- =======================================================================
         MODAL 3: VIEW VEHICLE DETAILS (COMPREHENSIVE WITH MULTI-PHOTO GALLERY)
         ======================================================================= -->
    <div class="vehicle-modal-overlay" id="modalViewDetails" onclick="if(event.target===this) closeViewModal();">
        <div class="vehicle-modal-card modal-edit-card" style="max-width: 680px;">
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge">
                        <i class="fa-solid fa-eye"></i>
                    </div>
                    <div>
                        <h3 id="viewVehicleTitle">TN 45 AB 1234</h3>
                        <p id="viewVehicleSubtitle">Vehicle Specifications & History</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeViewModal();">&times;</button>
            </div>

            <div class="modal-body-scroll">
                <!-- Vehicle Hero Image & Header -->
                <div style="display: flex; gap: 20px; align-items: flex-start; margin-bottom: 14px;">
                    <div style="width: 160px; height: 110px; border-radius: 12px; overflow: hidden; border: 1.5px solid #E2E8F0; flex-shrink: 0; background: #F8FAFC;">
                        <img id="viewVehicleImg" src="" alt="Vehicle" style="width: 100%; height: 100%; object-fit: cover; transition: opacity 0.2s;">
                    </div>
                    <div style="flex: 1;">
                        <h4 id="viewVehicleBrandModel" style="font-size: 19px; font-weight: 800; color: #111827; margin: 0 0 6px 0;">Hyundai i20</h4>
                        <p id="viewVehicleMfgBadge" style="font-size: 13px; color: #6B7280; margin: 0 0 10px 0;">Mfg Year: 2024</p>
                        <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                            <span id="viewVehicleStatusPill" class="status-pill status-active">
                                <i class="fa-solid fa-check"></i> Active
                            </span>
                            <span id="viewVehiclePrimaryPill" class="primary-tag" style="display: none;">
                                <i class="fa-solid fa-star"></i> Primary
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Multi-photo gallery thumbnails strip (if multiple photos exist) -->
                <div id="viewPhotosGalleryContainer" style="display: none; margin-bottom: 16px;">
                    <div style="font-size: 12px; font-weight: 600; color: #6B7280; margin-bottom: 4px;">Vehicle Photos (Click to view):</div>
                    <div class="view-photos-gallery-strip" id="viewPhotosGallery"></div>
                </div>

                <!-- Comprehensive Specifications Grid -->
                <div class="vehicle-specs-grid" style="margin: 0; padding-top: 14px; grid-template-columns: repeat(2, 1fr); gap: 14px 20px;">
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-car"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Vehicle Type</span>
                            <span class="spec-val" id="viewSpecType">Car</span>
                        </div>
                    </div>
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-tag"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Brand</span>
                            <span class="spec-val" id="viewSpecBrand">Hyundai</span>
                        </div>
                    </div>
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-layer-group"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Model</span>
                            <span class="spec-val" id="viewSpecModel">i20</span>
                        </div>
                    </div>
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-calendar-days"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Manufacturing Year</span>
                            <span class="spec-val" id="viewSpecMfg">2024</span>
                        </div>
                    </div>
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-gas-pump"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Fuel Type</span>
                            <span class="spec-val" id="viewSpecFuel">Petrol</span>
                        </div>
                    </div>
                    <div class="spec-item">
                        <div class="spec-icon-box"><i class="fa-solid fa-shield-heart"></i></div>
                        <div class="spec-info-text">
                            <span class="spec-label">Status</span>
                            <span class="spec-val" id="viewSpecStatus">Active</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="modal-footer-bar">
                <button type="button" class="btn-modal-cancel" id="viewBtnEdit" style="color: #F97316; border-color: #FED7AA; background: #FFF7ED;">
                    <i class="fa-solid fa-pencil"></i> Edit Details
                </button>
                <a id="viewSosLink" href="request-assistance.jsp" class="btn-modal-submit" style="text-decoration: none;">
                    <i class="fa-solid fa-bolt"></i> Request SOS for this vehicle
                </a>
                <button type="button" class="btn-modal-cancel" onclick="closeViewModal();">Close</button>
            </div>
        </div>
    </div>

    <!-- =======================================================================
         MODAL 4: REMOVE VEHICLE CONFIRMATION
         ======================================================================= -->
    <div class="vehicle-modal-overlay" id="modalRemoveVehicle" onclick="if(event.target===this) closeRemoveModal();">
        <div class="vehicle-modal-card" style="max-width: 460px;">
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge" style="background: #FEE2E2; color: #DC2626;">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                    </div>
                    <div>
                        <h3 style="color: #DC2626;">Remove Vehicle</h3>
                        <p>This action cannot be undone</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeRemoveModal();">&times;</button>
            </div>

            <form method="POST" action="vehicles.jsp">
                <input type="hidden" name="action" value="remove">
                <input type="hidden" name="vehicle_id" id="removeVehicleId">

                <div class="modal-body-content">
                    <p style="font-size: 14px; color: #374151; line-height: 1.5; margin: 0;">
                        Are you sure you want to remove vehicle <strong id="removeVehicleNumber" style="color: #111827;"></strong> from your account? 
                        It will no longer appear in your active vehicles list or be available for quick breakdown requests.
                    </p>
                </div>

                <div class="modal-footer-bar">
                    <button type="button" class="btn-modal-cancel" onclick="closeRemoveModal();">Cancel</button>
                    <button type="submit" class="btn-modal-submit btn-modal-danger">
                        <i class="fa-solid fa-trash-can"></i> Yes, Remove
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- JavaScript Interactions & Store -->
    <script>
        // Vehicle Data Store populated from server
        var vehiclesData = {};
        <% 
            for (int i = 0; i < vehicleCards.size(); i++) {
                Map card = (Map) vehicleCards.get(i);
                int cvId = (Integer) card.get("id");
                String cvNum = card.get("number") != null ? card.get("number").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvBrand = card.get("brand") != null ? card.get("brand").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvModel = card.get("model") != null ? card.get("model").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvMfg = card.get("mfg_year") != null ? card.get("mfg_year").toString() : "";
                String cvType = card.get("type") != null ? card.get("type").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvFuel = card.get("fuel") != null ? card.get("fuel").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvStatus = card.get("status") != null ? card.get("status").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "Active";
                String cvReg = card.get("reg_date") != null ? card.get("reg_date").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvInsExp = card.get("ins_expiry") != null ? card.get("ins_expiry").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvProvider = card.get("ins_provider") != null ? card.get("ins_provider").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvPolicy = card.get("policy_number") != null ? card.get("policy_number").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvImg = card.get("image") != null ? card.get("image").toString().replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"") : "";
                String cvPhotos = (card.get("photos") != null && !card.get("photos").toString().trim().isEmpty() && card.get("photos").toString().trim().startsWith("["))
                        ? card.get("photos").toString() : "[]";
                boolean cvPrim = (Boolean) card.get("primary");
        %>
        vehiclesData['<%= cvId %>'] = {
            id: '<%= cvId %>',
            number: '<%= cvNum %>',
            brand: '<%= cvBrand %>',
            model: '<%= cvModel %>',
            mfgYear: '<%= cvMfg %>',
            type: '<%= cvType %>',
            fuel: '<%= cvFuel %>',
            status: '<%= cvStatus %>',
            regDate: '<%= cvReg %>',
            insExpiry: '<%= cvInsExp %>',
            insProvider: '<%= cvProvider %>',
            policyNumber: '<%= cvPolicy %>',
            image: '<%= cvImg %>',
            photos: <%= cvPhotos %>,
            isPrimary: <%= cvPrim %>,
            isOnRequest: <%= card.get("is_on_request") != null && (Boolean) card.get("is_on_request") %>,
            activeCode: '<%= card.get("active_code") != null ? card.get("active_code") : "" %>',
            activeStatus: '<%= card.get("active_status") != null ? card.get("active_status") : "" %>'
        };
        <% } %>

        // Helper to resolve vehicle images
        function resolveVehicleImageUrl(ctx, img, vType, vModel) {
            if (!img || img === 'null' || img.trim() === '') {
                if (vType && (vType.toLowerCase().indexOf('motorcycle') !== -1 || vType.toLowerCase().indexOf('two wheeler') !== -1)) {
                    return ctx + '/images/vehicle-pulsar-lg.jpg';
                }
                if (vType && vType.toLowerCase().indexOf('scooter') !== -1) {
                    return ctx + '/images/vehicle-activa.png';
                }
                if (vModel && vModel.toLowerCase().indexOf('brezza') !== -1) {
                    return ctx + '/images/vehicle-brezza.png';
                }
                if (vModel && vModel.toLowerCase().indexOf('nexon') !== -1) {
                    return ctx + '/images/vehicle-nexon.png';
                }
                return ctx + '/images/vehicle-i20-lg.jpg';
            }
            img = img.trim();
            if (img.indexOf('http://') === 0 || img.indexOf('https://') === 0) return img;
            if (img.indexOf('/') === 0) return ctx + img;
            if (img.indexOf('veh_') === 0 || img.indexOf('uploads/') === 0) {
                if (img.indexOf('uploads/') === 0) return ctx + '/' + img;
                return ctx + '/uploads/vehicles/' + img;
            }
            return ctx + '/images/' + img;
        }

        // Helper: Format date string to YYYY-MM-DD for date inputs
        function formatDateForInput(dateStr) {
            if (!dateStr || dateStr.trim() === '' || dateStr === 'null') return '';
            var s = dateStr.trim();
            if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
            var ddmmyyyy = /^(\d{2})-(\d{2})-(\d{4})$/.exec(s);
            if (ddmmyyyy) {
                return ddmmyyyy[3] + '-' + ddmmyyyy[2] + '-' + ddmmyyyy[1];
            }
            var d = new Date(s);
            if (!isNaN(d.getTime())) {
                var m = '' + (d.getMonth() + 1);
                var day = '' + d.getDate();
                var y = d.getFullYear();
                if (m.length < 2) m = '0' + m;
                if (day.length < 2) day = '0' + day;
                return [y, m, day].join('-');
            }
            return '';
        }

        // Helper: Set select element by value (or add if custom)
        function setSelectValue(selectEl, val) {
            if (!selectEl) return;
            if (!val || val === 'null') {
                selectEl.selectedIndex = 0;
                return;
            }
            var cleanVal = String(val).trim().toLowerCase();
            for (var i = 0; i < selectEl.options.length; i++) {
                if (selectEl.options[i].value.toLowerCase() === cleanVal) {
                    selectEl.selectedIndex = i;
                    return;
                }
            }
            // If not found in default options, append it
            var opt = new Option(val, val, true, true);
            selectEl.add(opt);
        }

        // 1. Dropdown 3-dot Menu Handling
        function toggleDotsMenu(e, menuId) {
            e.stopPropagation();
            var menu = document.getElementById(menuId);
            var isShown = menu.classList.contains('show');
            
            var allMenus = document.querySelectorAll('.dots-dropdown');
            for (var i = 0; i < allMenus.length; i++) {
                allMenus[i].classList.remove('show');
            }

            if (!isShown) {
                menu.classList.add('show');
            }
        }

        document.addEventListener('click', function(e) {
            var allMenus = document.querySelectorAll('.dots-dropdown');
            for (var i = 0; i < allMenus.length; i++) {
                allMenus[i].classList.remove('show');
            }
        });

        // 2. Add Modal
        function openAddModal() {
            document.getElementById('modalAddVehicle').classList.add('show');
        }
        function closeAddModal() {
            document.getElementById('modalAddVehicle').classList.remove('show');
        }

        // Vehicle Brands Mapping by Vehicle Type
        var BRANDS_BY_TYPE = {
            'Car': [
                'Maruti Suzuki', 'Hyundai', 'Tata Motors', 'Mahindra', 'Toyota', 
                'Honda', 'Kia', 'Volkswagen', 'Skoda', 'BMW', 
                'Mercedes-Benz', 'Audi', 'MG Motor', 'Renault', 'Nissan', 
                'Ford', 'Jeep', 'Volvo', 'Other'
            ],
            'Bike / Motorcycle': [
                'Hero MotoCorp', 'Honda', 'Bajaj', 'TVS', 'Royal Enfield', 
                'Yamaha', 'Suzuki', 'KTM', 'Kawasaki', 'Jawa', 
                'Harley-Davidson', 'Triumph', 'Ducati', 'BMW Motorrad', 'Yezdi', 
                'Revolt', 'Other'
            ],
            'Scooter': [
                'Honda', 'TVS', 'Suzuki', 'Hero MotoCorp', 'Yamaha', 
                'Ather Energy', 'Ola Electric', 'Bajaj', 'Simple Energy', 'Vespa', 
                'Aprilia', 'Okinawa', 'Pure EV', 'Other'
            ],
            'Auto Rickshaw': [
                'Bajaj', 'Piaggio', 'TVS', 'Mahindra', 'Atul Auto', 
                'Kinetic Green', 'Saarthi', 'Lohia Auto', 'Other'
            ],
            'Bus / Van': [
                'Tata Motors', 'Ashok Leyland', 'Eicher', 'Force Motors', 'BharatBenz', 
                'Volvo', 'Mahindra', 'SML Isuzu', 'Scania', 'Other'
            ],
            'Truck / Heavy Vehicle': [
                'Tata Motors', 'Ashok Leyland', 'BharatBenz', 'Eicher', 'Mahindra', 
                'Force Motors', 'SML Isuzu', 'Volvo', 'Scania', 'Other'
            ],
            'Other': ['Other']
        };

        function updateEditBrandSelect(vType, currentBrand) {
            var brandSelect = document.getElementById('editVehicleBrand');
            if (!brandSelect) return;
            brandSelect.innerHTML = '';
            var brands = BRANDS_BY_TYPE[vType] || BRANDS_BY_TYPE['Car'];
            brands.forEach(function(b) {
                var opt = new Option(b, b);
                brandSelect.add(opt);
            });
            if (currentBrand) {
                setSelectValue(brandSelect, currentBrand);
            }
        }

        var editTypeSelect = document.getElementById('editVehicleType');
        if (editTypeSelect) {
            editTypeSelect.addEventListener('change', function() {
                updateEditBrandSelect(this.value, null);
            });
        }

        // Format Registration Number on keystrokes: XX 00 XX 0000
        function formatRegInput(inputEl) {
            if (!inputEl) return;
            inputEl.addEventListener('input', function() {
                var raw = this.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
                var clean = '';
                for (var i = 0; i < raw.length && clean.length < 10; i++) {
                    var ch = raw[i];
                    var len = clean.length;
                    if (len < 2) {
                        if (/[A-Z]/.test(ch)) clean += ch;
                    } else if (len < 4) {
                        if (/[0-9]/.test(ch)) clean += ch;
                    } else if (len < 6) {
                        if (/[A-Z]/.test(ch)) clean += ch;
                    } else if (len < 10) {
                        if (/[0-9]/.test(ch)) clean += ch;
                    }
                }
                var formatted = '';
                if (clean.length > 0) formatted = clean.slice(0, 2);
                if (clean.length > 2) formatted += ' ' + clean.slice(2, 4);
                if (clean.length > 4) formatted += ' ' + clean.slice(4, 6);
                if (clean.length > 6) formatted += ' ' + clean.slice(6, 10);
                this.value = formatted;
            });
        }
        formatRegInput(document.getElementById('editVehicleNumber'));

        // 3. Edit Modal
        function openEditModal(vId) {
            var v = vehiclesData[vId];
            if (!v) return;

            var ctx = '${pageContext.request.contextPath}';
            document.getElementById('editVehicleId').value = v.id;
            document.getElementById('editVehicleNumber').value = v.number;
            document.getElementById('editVehicleModel').value = v.model;

            setSelectValue(document.getElementById('editVehicleType'), v.type);
            updateEditBrandSelect(v.type, v.brand);
            setSelectValue(document.getElementById('editMfgYear'), v.mfgYear);
            setSelectValue(document.getElementById('editFuelType'), v.fuel);

            setSelectValue(document.getElementById('editStatus'), v.status || 'Active');
            document.getElementById('editIsPrimary').checked = !!v.isPrimary;

            document.getElementById('editSubtitle').innerText = 'Editing ' + v.number + ' (' + v.model + ')';

            // Existing Photos Preview
            var existingGallery = document.getElementById('editExistingPhotosGallery');
            existingGallery.innerHTML = '';
            var existingPhotos = (v.photos && Array.isArray(v.photos) && v.photos.length > 0) ? v.photos : (v.image ? [v.image] : []);
            if (existingPhotos.length > 0) {
                existingPhotos.forEach(function(pName) {
                    var wrap = document.createElement('div');
                    wrap.className = 'edit-photo-thumb-wrap';
                    var img = document.createElement('img');
                    img.src = resolveVehicleImageUrl(ctx, pName, v.type, v.model);
                    wrap.appendChild(img);
                    existingGallery.appendChild(wrap);
                });
            } else {
                existingGallery.innerHTML = '<span style="font-size:12.5px;color:#9CA3AF;font-style:italic;">No photos uploaded yet.</span>';
            }

            document.getElementById('editPhotosInput').value = '';
            document.getElementById('editNewPhotosPreviews').innerHTML = '';

            document.getElementById('modalEditVehicle').classList.add('show');
        }

        function closeEditModal() {
            document.getElementById('modalEditVehicle').classList.remove('show');
        }

        // Live Preview for New Photo Selections in Edit Modal
        var editPhotosInput = document.getElementById('editPhotosInput');
        if (editPhotosInput) {
            editPhotosInput.addEventListener('change', function() {
                var previews = document.getElementById('editNewPhotosPreviews');
                previews.innerHTML = '';
                if (this.files && this.files.length > 0) {
                    for (var i = 0; i < this.files.length && i < 5; i++) {
                        var file = this.files[i];
                        var thumb = document.createElement('div');
                        thumb.className = 'edit-new-thumb';
                        var img = document.createElement('img');
                        img.src = URL.createObjectURL(file);
                        thumb.appendChild(img);
                        previews.appendChild(thumb);
                    }
                }
            });
        }

        // Submit Edit Form with AJAX + Fallback
        var editForm = document.getElementById('editVehicleForm');
        if (editForm) {
            editForm.addEventListener('submit', function(e) {
                e.preventDefault();
                var btn = document.getElementById('btnEditSubmit');
                btn.disabled = true;
                var oldHtml = btn.innerHTML;
                btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Saving Changes...';

                var formData = new FormData(editForm);
                var postUrl = editForm.getAttribute('action') || ('${pageContext.request.contextPath}/VehicleServlet');
                fetch(postUrl, {
                    method: 'POST',
                    body: formData,
                    headers: { 'X-Requested-With': 'XMLHttpRequest' }
                })
                .then(function(res) {
                    if (!res.ok) throw new Error('Save failed');
                    return res.json();
                })
                .then(function(data) {
                    if (data.success) {
                        window.location.href = data.redirectUrl || ('vehicles.jsp?msg=updated');
                    } else {
                        btn.disabled = false;
                        btn.innerHTML = oldHtml;
                        alert(data.message || 'Error updating vehicle');
                    }
                })
                .catch(function(err) {
                    console.warn('AJAX fallback to standard submit:', err);
                    editForm.submit();
                });
            });
        }

        // 4. View Modal
        function openViewModal(vId) {
            var v = vehiclesData[vId];
            if (!v) return;

            var ctx = '${pageContext.request.contextPath}';
            document.getElementById('viewVehicleTitle').innerText = v.number;
            document.getElementById('viewVehicleBrandModel').innerText = (v.brand ? (v.brand + ' ') : '') + v.model;
            document.getElementById('viewVehicleMfgBadge').innerText = v.mfgYear ? ('Manufacturing Year: ' + v.mfgYear) : '';
            document.getElementById('viewSpecType').innerText = v.type || 'Car';
            document.getElementById('viewSpecBrand').innerText = v.brand || '-';
            document.getElementById('viewSpecModel').innerText = v.model || '-';
            document.getElementById('viewSpecMfg').innerText = v.mfgYear || '-';
            document.getElementById('viewSpecFuel').innerText = v.fuel || 'Petrol';
            document.getElementById('viewSpecStatus').innerText = v.status || 'Active';

            var mainImgUrl = resolveVehicleImageUrl(ctx, v.image, v.type, v.model);
            document.getElementById('viewVehicleImg').src = mainImgUrl;

            var viewSosLink = document.getElementById('viewSosLink');
            if (viewSosLink) {
                if (v.isOnRequest) {
                    viewSosLink.href = 'my-requests.jsp';
                    viewSosLink.innerHTML = '<i class="fa-solid fa-clock-rotate-left"></i> On Request (' + v.activeCode + ') \u2014 Track';
                    viewSosLink.style.background = '#FFF7ED';
                    viewSosLink.style.color = '#EA580C';
                    viewSosLink.style.borderColor = '#FDBA74';
                    viewSosLink.title = 'Vehicle has an ongoing breakdown service (' + v.activeCode + ' \u2014 ' + v.activeStatus + ')';
                } else {
                    viewSosLink.href = 'request-assistance.jsp?vehicle=' + encodeURIComponent(v.number);
                    viewSosLink.innerHTML = '<i class="fa-solid fa-bolt"></i> Request SOS for this vehicle';
                    viewSosLink.style.background = '';
                    viewSosLink.style.color = '';
                    viewSosLink.style.borderColor = '';
                    viewSosLink.title = '';
                }
            }

            document.getElementById('viewBtnEdit').onclick = function() {
                closeViewModal();
                openEditModal(vId);
            };

            var statusPill = document.getElementById('viewVehicleStatusPill');
            statusPill.className = 'status-pill';
            if (v.status === 'In Service') {
                statusPill.classList.add('status-service');
                statusPill.innerHTML = '<i class="fa-solid fa-wrench"></i> In Service';
            } else if (v.status === 'Inactive') {
                statusPill.classList.add('status-inactive');
                statusPill.innerHTML = '<i class="fa-solid fa-xmark"></i> Inactive';
            } else {
                statusPill.classList.add('status-active');
                statusPill.innerHTML = '<i class="fa-solid fa-check"></i> Active';
            }

            var primTag = document.getElementById('viewVehiclePrimaryPill');
            primTag.style.display = v.isPrimary ? 'inline-flex' : 'none';

            // Gallery thumbnails
            var galleryContainer = document.getElementById('viewPhotosGalleryContainer');
            var galleryEl = document.getElementById('viewPhotosGallery');
            galleryEl.innerHTML = '';
            var allPhotos = [];
            if (v.photos && Array.isArray(v.photos) && v.photos.length > 0) {
                allPhotos = v.photos;
            } else if (v.image) {
                allPhotos = [v.image];
            }

            if (allPhotos.length > 1) {
                galleryContainer.style.display = 'block';
                allPhotos.forEach(function(photoName, idx) {
                    var thumbBtn = document.createElement('button');
                    thumbBtn.type = 'button';
                    thumbBtn.className = 'view-thumb-btn' + (idx === 0 ? ' active' : '');
                    var thumbImg = document.createElement('img');
                    thumbImg.src = resolveVehicleImageUrl(ctx, photoName, v.type, v.model);
                    thumbImg.alt = 'Thumbnail ' + (idx + 1);
                    thumbBtn.appendChild(thumbImg);
                    thumbBtn.onclick = function() {
                        document.querySelectorAll('.view-thumb-btn').forEach(function(b) { b.classList.remove('active'); });
                        thumbBtn.classList.add('active');
                        document.getElementById('viewVehicleImg').src = resolveVehicleImageUrl(ctx, photoName, v.type, v.model);
                    };
                    galleryEl.appendChild(thumbBtn);
                });
            } else {
                galleryContainer.style.display = 'none';
            }

            document.getElementById('modalViewDetails').classList.add('show');
        }

        function closeViewModal() {
            document.getElementById('modalViewDetails').classList.remove('show');
        }

        // 5. Remove Modal
        function openRemoveModal(vId, vNum) {
            document.getElementById('removeVehicleId').value = vId;
            document.getElementById('removeVehicleNumber').innerText = vNum;
            document.getElementById('modalRemoveVehicle').classList.add('show');
        }
        function closeRemoveModal() {
            document.getElementById('modalRemoveVehicle').classList.remove('show');
        }

        // Close Modals on ESC key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeAddModal();
                closeEditModal();
                closeViewModal();
                closeRemoveModal();
            }
        });
    </script>

    <!-- Global App Responsive JS -->
    <script src="${pageContext.request.contextPath}/js/app-responsive.js"></script>
</body>
</html>
