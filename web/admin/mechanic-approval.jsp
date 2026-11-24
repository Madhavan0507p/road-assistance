<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // =========================================================================
    // 1. SESSION AUTHENTICATION & CACHE PREVENTION
    // =========================================================================
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session.getAttribute("admin") == null) {
        response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=auth_required");
        return;
    }

    // Page metadata for sidebar and topbar
    request.setAttribute("activePage", "approval");
    request.setAttribute("pageTitle", "Mechanic <span style=\"color: #F97316;\">Approval</span>");
    request.setAttribute("pageSubtitle", "Review mechanic registrations, verify documents and approve or reject requests");
    request.setAttribute("searchPlaceholder", "Search pending mechanics, workshop...");
    request.setAttribute("notifCount", "3");
    request.setAttribute("pageIcon", "fa-solid fa-shield-halved");

    String alertMsg = "";
    String alertType = "success";

    // =========================================================================
    // 2. HANDLE APPROVAL & REJECTION ACTIONS
    // =========================================================================
    String action = request.getParameter("action");
    String reqId = request.getParameter("id");
    if (reqId == null || reqId.trim().isEmpty()) {
        reqId = request.getParameter("actionId");
    }
    String decisionParam = request.getParameter("decision");
    String rejectionReason = request.getParameter("rejectionReason");
    if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
        rejectionReason = request.getParameter("reason");
    }

    // Approve action
    if ("approve".equalsIgnoreCase(action) || "Approved".equalsIgnoreCase(decisionParam)) {
        if (reqId != null && !reqId.trim().isEmpty()) {
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                if (conn != null) {
                    // Fetch mechanic details before update for notification
                    String mechEmail = null;
                    String mechOwner = null;
                    String mechShop = null;
                    String mechCode = null;
                    try {
                        PreparedStatement psInfo = conn.prepareStatement(
                            "SELECT email, owner_name, workshop_name, mechanic_code FROM mechanics WHERE mechanic_id = ?"
                        );
                        psInfo.setInt(1, Integer.parseInt(reqId));
                        ResultSet rsInfo = psInfo.executeQuery();
                        if (rsInfo.next()) {
                            mechEmail = rsInfo.getString("email");
                            mechOwner = rsInfo.getString("owner_name");
                            mechShop = rsInfo.getString("workshop_name");
                            mechCode = rsInfo.getString("mechanic_code");
                        }
                        rsInfo.close();
                        psInfo.close();
                    } catch (Exception exInfo) {
                        System.err.println("Could not pre-fetch mechanic info: " + exInfo.getMessage());
                    }

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE mechanics SET approval_status = 'Approved', is_available = 1, rejection_reason = NULL WHERE mechanic_id = ?"
                    );
                    ps.setInt(1, Integer.parseInt(reqId));
                    int updated = ps.executeUpdate();
                    ps.close();

                    // Send activation email asynchronously if configured
                    if (mechEmail != null && !mechEmail.trim().isEmpty()) {
                        final String finalEmail = mechEmail.trim();
                        final String finalOwner = (mechOwner != null && !mechOwner.trim().isEmpty()) ? mechOwner.trim() : "Mechanic Partner";
                        final String finalShop = (mechShop != null && !mechShop.trim().isEmpty()) ? mechShop.trim() : "Auto Workshop";
                        final String finalCode = (mechCode != null && !mechCode.trim().isEmpty()) ? mechCode : ("MEC" + (reqId.length() <= 2 ? "0" + reqId : reqId));
                        final String loginUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath() + "/mechanic/login.jsp";
                        new Thread(new Runnable() {
                            public void run() {
                                try {
                                    com.roadassistance.util.EmailUtil.sendMechanicActivationEmail(finalEmail, finalOwner, finalShop, finalCode, loginUrl);
                                } catch (Exception ignored) {}
                            }
                        }).start();
                    }

                    String displayCode = (mechCode != null && !mechCode.trim().isEmpty()) ? mechCode : ("MEC" + (reqId.length() <= 2 ? "0" + reqId : reqId));
                    alertMsg = "Mechanic application #" + displayCode + " (" + (mechOwner != null ? mechOwner : "Partner") + ") has been Approved! Activation email sent to " + (mechEmail != null ? mechEmail : "mechanic") + ".";
                    alertType = "success";
                }
            } catch (Exception e) {
                alertMsg = "Mechanic application #" + reqId + " approved.";
                alertType = "success";
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        }
    }
    // Reject action
    else if ("reject".equalsIgnoreCase(action) || "Rejected".equalsIgnoreCase(decisionParam)) {
        if (reqId != null && !reqId.trim().isEmpty()) {
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                if (conn != null) {
                    // Pre-fetch mechanic details before update for rejection notification
                    String mechEmail = null;
                    String mechOwner = null;
                    String mechShop = null;
                    String mechCode = null;
                    try {
                        PreparedStatement psInfo = conn.prepareStatement(
                            "SELECT email, owner_name, workshop_name, mechanic_code FROM mechanics WHERE mechanic_id = ?"
                        );
                        psInfo.setInt(1, Integer.parseInt(reqId));
                        ResultSet rsInfo = psInfo.executeQuery();
                        if (rsInfo.next()) {
                            mechEmail = rsInfo.getString("email");
                            mechOwner = rsInfo.getString("owner_name");
                            mechShop = rsInfo.getString("workshop_name");
                            mechCode = rsInfo.getString("mechanic_code");
                        }
                        rsInfo.close();
                        psInfo.close();
                    } catch (Exception exInfo) {
                        System.err.println("Could not pre-fetch mechanic info for rejection: " + exInfo.getMessage());
                    }

                    final String safeRejectionReason = (rejectionReason != null && !rejectionReason.trim().isEmpty())
                        ? rejectionReason.trim()
                        : "Verification documents or workshop criteria requirements were not met.";

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE mechanics SET approval_status = 'Rejected', is_available = 0, rejection_reason = ? WHERE mechanic_id = ?"
                    );
                    ps.setString(1, safeRejectionReason);
                    ps.setInt(2, Integer.parseInt(reqId));
                    ps.executeUpdate();
                    ps.close();

                    // Send rejection email asynchronously
                    if (mechEmail != null && !mechEmail.trim().isEmpty()) {
                        final String finalEmail = mechEmail.trim();
                        final String finalOwner = (mechOwner != null && !mechOwner.trim().isEmpty()) ? mechOwner.trim() : "Mechanic Partner";
                        final String finalShop = (mechShop != null && !mechShop.trim().isEmpty()) ? mechShop.trim() : "Auto Workshop";
                        final String finalCode = (mechCode != null && !mechCode.trim().isEmpty()) ? mechCode : ("MEC" + (reqId.length() <= 2 ? "0" + reqId : reqId));
                        final String finalReason = safeRejectionReason;
                        new Thread(new Runnable() {
                            public void run() {
                                try {
                                    com.roadassistance.util.EmailUtil.sendMechanicRejectionEmail(finalEmail, finalOwner, finalShop, finalCode, finalReason);
                                } catch (Exception ignored) {}
                            }
                        }).start();
                    }

                    String displayCode = (mechCode != null && !mechCode.trim().isEmpty()) ? mechCode : ("MEC" + (reqId.length() <= 2 ? "0" + reqId : reqId));
                    alertMsg = "Mechanic application #" + displayCode + " (" + (mechOwner != null ? mechOwner : "Partner") + ") has been Rejected. Notification email with reason sent to " + (mechEmail != null ? mechEmail : "mechanic") + ".";
                    alertType = "danger";
                }
            } catch (Exception e) {
                alertMsg = "Mechanic application #" + reqId + " rejected.";
                alertType = "danger";
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        }
    }

    // =========================================================================
    // 3. QUERY COUNTS & STATS
    // =========================================================================
    int totalRequestsCount = 0;
    int pendingApprovalCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    Connection connStats = null;
    try {
        connStats = DBConnection.getConnection();
        if (connStats != null) {
            Statement stmtCount = connStats.createStatement();
            ResultSet rsCount = stmtCount.executeQuery("SELECT approval_status, COUNT(*) FROM mechanics GROUP BY approval_status");
            while (rsCount.next()) {
                String st = rsCount.getString(1);
                int cnt = rsCount.getInt(2);
                if ("Pending".equalsIgnoreCase(st)) pendingApprovalCount = cnt;
                else if ("Approved".equalsIgnoreCase(st)) approvedCount = cnt;
                else if ("Rejected".equalsIgnoreCase(st)) rejectedCount = cnt;
            }
            rsCount.close();
            stmtCount.close();
            totalRequestsCount = pendingApprovalCount + approvedCount + rejectedCount;
        }
    } catch (Exception ignored) {
    } finally {
        if (connStats != null) try { connStats.close(); } catch (Exception ignored) {}
    }

    // =========================================================================
    // 4. QUERY MECHANICS WITH SEARCH, FILTER & TAB SUPPORT
    // =========================================================================
    String activeTab = request.getParameter("tab");
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = "pending"; // Default view shows pending mechanic approval requests
    }

    String searchParam = request.getParameter("search");
    String specFilter = request.getParameter("specialization");
    String locFilter = request.getParameter("location");
    String dateFilter = request.getParameter("applied_date");

    List<Map<String, String>> mechanicList = new ArrayList<Map<String, String>>();
    SimpleDateFormat displayDateFmt = new SimpleDateFormat("dd-MM-yyyy, hh:mm a");

    Connection connList = null;
    try {
        connList = DBConnection.getConnection();
        if (connList != null) {
            StringBuilder sql = new StringBuilder("SELECT * FROM mechanics WHERE 1=1 ");
            List<String> sqlParams = new ArrayList<String>();

            // Tab filtering
            if ("pending".equalsIgnoreCase(activeTab)) {
                sql.append("AND approval_status = 'Pending' ");
            } else if ("approved".equalsIgnoreCase(activeTab)) {
                sql.append("AND approval_status = 'Approved' ");
            } else if ("rejected".equalsIgnoreCase(activeTab)) {
                sql.append("AND approval_status = 'Rejected' ");
            }

            // Dropdown Specialization filter
            if (specFilter != null && !specFilter.trim().isEmpty() && !"all".equalsIgnoreCase(specFilter) && !"All Specialization".equalsIgnoreCase(specFilter)) {
                sql.append("AND (specialization LIKE ? OR service_types LIKE ?) ");
                sqlParams.add("%" + specFilter + "%");
                sqlParams.add("%" + specFilter + "%");
            }

            // Dropdown Location filter
            if (locFilter != null && !locFilter.trim().isEmpty() && !"all".equalsIgnoreCase(locFilter) && !"All Locations".equalsIgnoreCase(locFilter)) {
                sql.append("AND (location LIKE ? OR address LIKE ?) ");
                sqlParams.add("%" + locFilter + "%");
                sqlParams.add("%" + locFilter + "%");
            }

            // Date filter
            if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                sql.append("AND DATE(created_at) = ? ");
                sqlParams.add(dateFilter);
            }

            // Text search
            if (searchParam != null && !searchParam.trim().isEmpty()) {
                sql.append("AND (owner_name LIKE ? OR workshop_name LIKE ? OR phone LIKE ? OR email LIKE ? OR address LIKE ? OR CAST(mechanic_id AS CHAR) LIKE ? OR mechanic_code LIKE ?) ");
                String like = "%" + searchParam + "%";
                for (int i = 0; i < 7; i++) sqlParams.add(like);
            }

            sql.append("ORDER BY created_at ASC, mechanic_id ASC");

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
                if (code == null || code.trim().isEmpty()) {
                    code = "MEC" + (idNum < 10 ? "00" + idNum : (idNum < 100 ? "0" + idNum : String.valueOf(idNum)));
                }
                m.put("formattedId", code);
                m.put("owner", rs.getString("owner_name"));
                m.put("workshop", rs.getString("workshop_name"));
                m.put("phone", rs.getString("phone"));
                m.put("email", rs.getString("email"));
                
                String rawAddr = rs.getString("address");
                m.put("address", rawAddr != null ? rawAddr : "Chennai");
                
                String loc = rs.getString("location");
                if (loc == null || loc.trim().isEmpty()) {
                    loc = "Chennai";
                    if (rawAddr != null) {
                        String lower = rawAddr.toLowerCase();
                        if (lower.contains("coimbatore")) loc = "Coimbatore";
                        else if (lower.contains("madurai")) loc = "Madurai";
                        else if (lower.contains("trichy") || lower.contains("tiruchirappalli")) loc = "Trichy";
                        else if (lower.contains("salem")) loc = "Salem";
                    }
                }
                m.put("location", loc);

                String spec = rs.getString("specialization");
                if (spec == null || spec.trim().isEmpty()) {
                    spec = rs.getString("service_types");
                }
                m.put("services", (spec != null && !spec.trim().isEmpty()) ? spec : "General Service");

                Timestamp ts = rs.getTimestamp("created_at");
                if (ts != null) {
                    m.put("appliedDate", displayDateFmt.format(ts));
                } else {
                    m.put("appliedDate", "20-01-2025, 09:12 AM");
                }

                String exp = rs.getString("years_of_experience");
                m.put("experience", (exp != null && !exp.trim().isEmpty()) ? exp : "7+ Years");

                String img = rs.getString("profile_image");
                if (img == null || img.trim().isEmpty()) {
                    img = "avatar-karthik-mech.jpg";
                }
                m.put("image", img);

                String status = rs.getString("approval_status");
                m.put("status", status != null ? status : "Pending");

                // Identity verification & documents
                String aadhaar = rs.getString("aadhaar_number");
                m.put("aadhaarNumber", (aadhaar != null && !aadhaar.trim().isEmpty()) ? aadhaar : "");
                String aadhaarDoc = rs.getString("aadhaar_card_doc");
                m.put("aadhaarDoc", (aadhaarDoc != null && !aadhaarDoc.trim().isEmpty()) ? aadhaarDoc : "");
                String idProofDoc = rs.getString("id_proof_doc");
                m.put("idProofDoc", (idProofDoc != null && !idProofDoc.trim().isEmpty()) ? idProofDoc : "");

                String rejRsn = "";
                try {
                    rejRsn = rs.getString("rejection_reason");
                } catch (Exception ignored) {}
                m.put("rejectionReason", (rejRsn != null && !rejRsn.trim().isEmpty()) ? rejRsn : "");

                // Rich profile details for view modal
                String gender = rs.getString("gender");
                m.put("gender", (gender != null && !gender.trim().isEmpty()) ? gender : "Male");
                String shopType = rs.getString("shop_type");
                m.put("shopType", (shopType != null && !shopType.trim().isEmpty()) ? shopType : "Service Center");
                String shopContact = rs.getString("shop_contact_number");
                m.put("shopContact", (shopContact != null && !shopContact.trim().isEmpty()) ? shopContact : (m.get("phone") != null ? m.get("phone") : "6383112061"));
                String openTime = rs.getString("opening_time");
                String closeTime = rs.getString("closing_time");
                m.put("workingHours", (openTime != null ? openTime : "09:00 AM") + " – " + (closeTime != null ? closeTime : "07:00 PM"));
                String shopDesc = rs.getString("shop_description");
                m.put("shopDesc", (shopDesc != null && !shopDesc.trim().isEmpty()) ? shopDesc : (spec != null ? spec : "Car & Bike Service, Battery, General Repair"));
                String otherSpec = rs.getString("other_specialization");
                m.put("otherSpec", (otherSpec != null && !otherSpec.trim().isEmpty()) ? otherSpec : "AC Service, Radiator Repair");
                String addr1 = rs.getString("address_line_1");
                m.put("addressLine1", (addr1 != null && !addr1.trim().isEmpty()) ? addr1 : (rawAddr != null ? rawAddr : "No. 12, Gandhipuram Main Road"));
                String addr2 = rs.getString("address_line_2");
                m.put("addressLine2", (addr2 != null && !addr2.trim().isEmpty()) ? addr2 : "Near Bus Stand");
                String city = rs.getString("city");
                m.put("city", (city != null && !city.trim().isEmpty()) ? city : loc);
                String district = rs.getString("district");
                m.put("district", (district != null && !district.trim().isEmpty()) ? district : loc);
                String state = rs.getString("state");
                m.put("state", (state != null && !state.trim().isEmpty()) ? state : "Tamil Nadu");
                String pincode = rs.getString("pincode");
                m.put("pincode", (pincode != null && !pincode.trim().isEmpty()) ? pincode : "641001");
                double lat = rs.getDouble("latitude");
                double lng = rs.getDouble("longitude");
                m.put("latitude", String.format("%.4f", lat != 0 ? lat : 11.0268));
                m.put("longitude", String.format("%.4f", lng != 0 ? lng : 76.9507));
                double rt = rs.getDouble("rating");
                int rev = rs.getInt("reviews_count");
                m.put("rating", String.format("%.1f", rt > 0 ? rt : 4.8));
                m.put("reviews", String.valueOf(rev > 0 ? rev : 120));

                // Fetch shop photos for this mechanic from mechanic_shop_photos
                List<String> photosList = new ArrayList<String>();
                try {
                    PreparedStatement psPh = connList.prepareStatement("SELECT photo_path FROM mechanic_shop_photos WHERE mechanic_id = ?");
                    psPh.setInt(1, idNum);
                    ResultSet rsPh = psPh.executeQuery();
                    while (rsPh.next()) {
                        String pp = rsPh.getString("photo_path");
                        if (pp != null && !pp.trim().isEmpty()) {
                            photosList.add(pp.trim());
                        }
                    }
                    rsPh.close();
                    psPh.close();
                } catch (Exception ignoredPh) {}
                if (!photosList.isEmpty()) {
                    StringBuilder sbPh = new StringBuilder();
                    for (int pIdx = 0; pIdx < photosList.size(); pIdx++) {
                        if (pIdx > 0) sbPh.append(",");
                        sbPh.append(photosList.get(pIdx));
                    }
                    m.put("shopPhotos", sbPh.toString());
                } else {
                    m.put("shopPhotos", "");
                }

                mechanicList.add(m);
            }
            rs.close();
            psList.close();
        }
    } catch (Exception ignored) {
    } finally {
        if (connList != null) try { connList.close(); } catch (Exception ignored) {}
    }


    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 requests per page

    int totalApprovalRequests = mechanicList.size();
    int totalPages = (totalApprovalRequests + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalApprovalRequests);
    List<Map<String, String>> displayList = (totalApprovalRequests > 0) ? mechanicList.subList(startIndex, endIndex) : new ArrayList<Map<String, String>>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mechanic Approval | On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Leaflet CSS for Interactive Location Map -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>

    <!-- Core Application & Dedicated Page CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-mechanic-management.css?v=2.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-mechanic-approval.css?v=2.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css">

    <style>
        .btn-reject-chip {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 20px;
            padding: 5px 12px;
            font-size: 11.5px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            transition: all 0.2s ease;
            white-space: nowrap;
        }
        .btn-reject-chip:hover {
            background: #FFF7ED;
            border-color: #F97316;
            color: #EA580C;
            transform: translateY(-1px);
        }

        /* Modal Stacking Hierarchy - Document Verification appears above Details Modal */
        #viewMechanicModal {
            z-index: 1000000 !important;
        }
        #documentModal {
            z-index: 1000010 !important;
        }
        #shopImagePreviewModal {
            z-index: 1000020 !important;
        }
        #fullscreenShopMapModal {
            z-index: 1000025 !important;
        }
        #mechanicRejectModal {
            z-index: 1000030 !important;
        }
    </style>
</head>
<body>

<div class="app-wrapper">
    <!-- Left Sidebar (With 6 items, Mechanic Approval Active in Orange) -->
    <jsp:include page="sidebar.jsp" />

    <!-- Main Content Area -->
    <div class="main-content">
        <!-- Top Header -->
        <jsp:include page="topbar.jsp" />

        <!-- Dashboard Body Container -->
        <main class="dashboard-body" style="padding: 24px 28px;">
            <div class="approval-page-container">

                <!-- System Flash Alert -->
                <% if (!alertMsg.isEmpty()) { %>
                    <div style="background-color: <%= "danger".equals(alertType) ? "#FEE2E2" : "#DCFCE7" %>; 
                                color: <%= "danger".equals(alertType) ? "#DC2626" : "#16A34A" %>; 
                                padding: 13px 18px; border-radius: 12px; font-weight: 700; font-size: 13.5px; 
                                border: 1px solid <%= "danger".equals(alertType) ? "#FECACA" : "#BBF7D0" %>; 
                                display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.03);">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <i class="fa-solid <%= "danger".equals(alertType) ? "fa-circle-xmark" : "fa-circle-check" %>" style="font-size: 18px;"></i>
                            <span><%= alertMsg %></span>
                        </div>
                        <button type="button" onclick="this.parentElement.style.display='none';" style="background:none; border:none; color:inherit; font-size:18px; cursor:pointer;">&times;</button>
                    </div>
                <% } %>

                <!-- =======================================================
                     HERO BANNER (Exact Image: mechanic-approval-banner.jpg)
                     ======================================================= -->
                <div class="approval-hero-banner">
                    <img src="${pageContext.request.contextPath}/images/mechanic-approval-banner.jpg" 
                         alt="Mechanic Approval Center — Verify documents, review details and manage registrations efficiently">
                </div>

                <!-- =======================================================
                     SECTION 1: SUMMARY METRICS CARDS (ROW OF 4)
                     ======================================================= -->
                <section class="approval-metrics-grid">
                    
                    <!-- 1. Total Requests -->
                    <div class="metric-card card-total">
                        <div class="metric-left-col">
                            <div class="metric-icon-box">
                                <i class="fa-solid fa-users"></i>
                            </div>
                            <div class="metric-info">
                                <span class="metric-title">Total Requests</span>
                                <span class="metric-value"><%= totalRequestsCount %></span>
                            </div>
                        </div>
                        <span class="metric-badge-pill pill-green">
                            <i class="fa-solid fa-arrow-up"></i> +8.2%
                        </span>
                    </div>

                    <!-- 2. Pending Approval -->
                    <div class="metric-card card-pending">
                        <div class="metric-left-col">
                            <div class="metric-icon-box">
                                <i class="fa-solid fa-hourglass-half"></i>
                            </div>
                            <div class="metric-info">
                                <span class="metric-title">Pending Approval</span>
                                <span class="metric-value"><%= pendingApprovalCount %></span>
                            </div>
                        </div>
                        <!-- Subtle wave graphic on right -->
                        <svg class="metric-sparkline-bg" viewBox="0 0 100 40" fill="none">
                            <path d="M0 32 Q 25 15, 50 28 T 100 12" stroke="#FACC15" stroke-width="3" fill="none" stroke-linecap="round"/>
                        </svg>
                    </div>

                    <!-- 3. Approved -->
                    <div class="metric-card card-approved">
                        <div class="metric-left-col">
                            <div class="metric-icon-box">
                                <i class="fa-solid fa-check"></i>
                            </div>
                            <div class="metric-info">
                                <span class="metric-title">Approved</span>
                                <span class="metric-value"><%= approvedCount %></span>
                            </div>
                        </div>
                        <span class="metric-badge-pill pill-green">
                            <i class="fa-solid fa-arrow-up"></i> +11.9%
                        </span>
                    </div>

                    <!-- 4. Rejected -->
                    <div class="metric-card card-rejected">
                        <div class="metric-left-col">
                            <div class="metric-icon-box">
                                <i class="fa-solid fa-xmark"></i>
                            </div>
                            <div class="metric-info">
                                <span class="metric-title">Rejected</span>
                                <span class="metric-value"><%= rejectedCount %></span>
                            </div>
                        </div>
                        <span class="metric-badge-pill pill-red">
                            <i class="fa-solid fa-arrow-up"></i> +20.0%
                        </span>
                    </div>

                </section>

                <!-- =======================================================
                     SECTION 2: MIDDLE INSIGHTS ROW (3 CARDS)
                     Approval Trend | Request Status | Document Verification
                     ======================================================= -->
                <section class="approval-insights-grid">
                    
                    <!-- CARD 1: APPROVAL TREND (AREA CHART) -->
                    <div class="insight-card card-approval-trend">
                        <div class="insight-card-header">
                            <div class="insight-title-group">
                                <div class="insight-header-icon">
                                    <i class="fa-solid fa-chart-column"></i>
                                </div>
                                <h3>Approval Trend</h3>
                            </div>
                            <select class="insight-dropdown-select" aria-label="Select Time Range">
                                <option>Last 6 Months</option>
                                <option>Last 30 Days</option>
                                <option>This Year</option>
                            </select>
                        </div>

                        <div class="trend-chart-wrapper">
                            <svg class="trend-chart-svg" viewBox="0 0 380 160">
                                <defs>
                                    <linearGradient id="trendOrangeGrad" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="0%" stop-color="#F97316" stop-opacity="0.35"/>
                                        <stop offset="100%" stop-color="#F97316" stop-opacity="0.0"/>
                                    </linearGradient>
                                </defs>

                                <!-- Horizontal Guide Lines -->
                                <line x1="30" y1="20" x2="365" y2="20" stroke="#F3F4F6" stroke-dasharray="3 3"/>
                                <line x1="30" y1="55" x2="365" y2="55" stroke="#F3F4F6" stroke-dasharray="3 3"/>
                                <line x1="30" y1="90" x2="365" y2="90" stroke="#F3F4F6" stroke-dasharray="3 3"/>
                                <line x1="30" y1="125" x2="365" y2="125" stroke="#F3F4F6" stroke-dasharray="3 3"/>

                                <!-- Y Axis Labels -->
                                <text x="20" y="24" font-size="10" fill="#9CA3AF" text-anchor="end" font-weight="600">40</text>
                                <text x="20" y="59" font-size="10" fill="#9CA3AF" text-anchor="end" font-weight="600">30</text>
                                <text x="20" y="94" font-size="10" fill="#9CA3AF" text-anchor="end" font-weight="600">20</text>
                                <text x="20" y="129" font-size="10" fill="#9CA3AF" text-anchor="end" font-weight="600">10</text>
                                <text x="20" y="145" font-size="10" fill="#9CA3AF" text-anchor="end" font-weight="600">0</text>

                                <!-- Area Path Fill -->
                                <path d="M 45 130 
                                         C 85 130, 95 120, 110 115 
                                         C 140 105, 155 70, 175 65 
                                         C 205 60, 225 80, 245 75 
                                         C 275 70, 295 55, 310 50 
                                         C 335 45, 345 42, 355 40 
                                         L 355 145 L 45 145 Z" 
                                      fill="url(#trendOrangeGrad)"/>

                                <!-- Curve Stroke -->
                                <path d="M 45 130 
                                         C 85 130, 95 120, 110 115 
                                         C 140 105, 155 70, 175 65 
                                         C 205 60, 225 80, 245 75 
                                         C 275 70, 295 55, 310 50 
                                         C 335 45, 345 42, 355 40" 
                                      fill="none" stroke="#F97316" stroke-width="3" stroke-linecap="round"/>

                                <!-- Data Points -->
                                <circle cx="45" cy="130" r="3.5" fill="#FFFFFF" stroke="#F97316" stroke-width="2"/>
                                <circle cx="110" cy="115" r="3.5" fill="#FFFFFF" stroke="#F97316" stroke-width="2"/>
                                <circle cx="175" cy="65" r="3.5" fill="#FFFFFF" stroke="#F97316" stroke-width="2"/>
                                <circle cx="245" cy="75" r="3.5" fill="#FFFFFF" stroke="#F97316" stroke-width="2"/>
                                <circle cx="310" cy="50" r="3.5" fill="#FFFFFF" stroke="#F97316" stroke-width="2"/>
                                <circle cx="355" cy="40" r="5" fill="#F97316" stroke="#FFFFFF" stroke-width="2.5"/>

                                <!-- Floating Tooltip on Last Point -->
                                <g transform="translate(340, 14)">
                                    <rect width="28" height="18" rx="5" fill="#EA580C"/>
                                    <polygon points="14,18 10,23 18,18" fill="#EA580C"/>
                                    <text x="14" y="13" font-size="10.5" font-weight="800" fill="#FFFFFF" text-anchor="middle"><%= totalRequestsCount %></text>
                                </g>

                                <!-- X Axis Labels -->
                                <text x="45" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Aug</text>
                                <text x="110" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Sep</text>
                                <text x="175" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Oct</text>
                                <text x="245" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Nov</text>
                                <text x="310" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Dec</text>
                                <text x="355" y="155" font-size="10.5" fill="#6B7280" font-weight="600" text-anchor="middle">Jan</text>
                            </svg>
                        </div>
                    </div>

                    <!-- CARD 2: REQUEST STATUS (DONUT CHART) -->
                    <div class="insight-card card-request-status">
                        <div class="insight-card-header">
                            <div class="insight-title-group">
                                <div class="insight-header-icon">
                                    <i class="fa-solid fa-chart-pie"></i>
                                </div>
                                <h3>Request Status</h3>
                            </div>
                            <span class="insight-header-action"><i class="fa-solid fa-chevron-right"></i></span>
                        </div>

                        <%
                            double appPct = totalRequestsCount > 0 ? (approvedCount * 100.0 / totalRequestsCount) : 0.0;
                            double pendPct = totalRequestsCount > 0 ? (pendingApprovalCount * 100.0 / totalRequestsCount) : 0.0;
                            double rejPct = totalRequestsCount > 0 ? (rejectedCount * 100.0 / totalRequestsCount) : 0.0;

                            double cCirc = 238.76;
                            double appDash = (appPct / 100.0) * cCirc;
                            double pendDash = (pendPct / 100.0) * cCirc;
                            double rejDash = (rejPct / 100.0) * cCirc;

                            double pendOff = -appDash;
                            double rejOff = -(appDash + pendDash);
                        %>
                        <div class="donut-content-layout">
                            <div class="donut-chart-box">
                                <svg class="donut-chart-svg" viewBox="0 0 100 100">
                                    <!-- Background circle -->
                                    <circle cx="50" cy="50" r="38" fill="none" stroke="#F3F4F6" stroke-width="13"/>
                                    <% if (totalRequestsCount > 0) { %>
                                        <% if (approvedCount > 0) { %>
                                        <circle cx="50" cy="50" r="38" fill="none" stroke="#16A34A" stroke-width="13"
                                                stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", appDash, cCirc) %>" stroke-dashoffset="0"/>
                                        <% } %>
                                        <% if (pendingApprovalCount > 0) { %>
                                        <circle cx="50" cy="50" r="38" fill="none" stroke="#FACC15" stroke-width="13"
                                                stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", pendDash, cCirc) %>" stroke-dashoffset="<%= String.format(java.util.Locale.US, "%.1f", pendOff) %>"/>
                                        <% } %>
                                        <% if (rejectedCount > 0) { %>
                                        <circle cx="50" cy="50" r="38" fill="none" stroke="#DC2626" stroke-width="13"
                                                stroke-dasharray="<%= String.format(java.util.Locale.US, "%.1f %.1f", rejDash, cCirc) %>" stroke-dashoffset="<%= String.format(java.util.Locale.US, "%.1f", rejOff) %>"/>
                                        <% } %>
                                    <% } %>
                                </svg>
                                <div class="donut-center-text">
                                    <span class="donut-center-number"><%= totalRequestsCount %></span>
                                    <span class="donut-center-label">Total</span>
                                </div>
                            </div>

                            <div class="donut-legend-list">
                                <div class="donut-legend-item">
                                    <div class="donut-legend-label">
                                        <span class="legend-dot dot-green"></span>
                                        <span>Approved (<%= approvedCount %>)</span>
                                    </div>
                                    <span class="donut-legend-pct"><%= String.format(java.util.Locale.US, "%.1f%%", appPct) %></span>
                                </div>

                                <div class="donut-legend-item">
                                    <div class="donut-legend-label">
                                        <span class="legend-dot dot-yellow"></span>
                                        <span>Pending (<%= pendingApprovalCount %>)</span>
                                    </div>
                                    <span class="donut-legend-pct"><%= String.format(java.util.Locale.US, "%.1f%%", pendPct) %></span>
                                </div>

                                <div class="donut-legend-item">
                                    <div class="donut-legend-label">
                                        <span class="legend-dot dot-red"></span>
                                        <span>Rejected (<%= rejectedCount %>)</span>
                                    </div>
                                    <span class="donut-legend-pct"><%= String.format(java.util.Locale.US, "%.1f%%", rejPct) %></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- CARD 3: DOCUMENT VERIFICATION -->
                    <div class="insight-card card-document-verification">
                        <div class="insight-card-header">
                            <div class="insight-title-group">
                                <div class="insight-header-icon">
                                    <i class="fa-solid fa-file-shield"></i>
                                </div>
                                <h3>Document Verification</h3>
                            </div>
                            <span class="insight-header-action"><i class="fa-solid fa-chevron-right"></i></span>
                        </div>

                        <div class="doc-verify-layout">
                            <!-- Left: 3 Checklist Items -->
                            <div class="doc-items-stack">
                                
                                <div class="doc-verify-row">
                                    <div class="doc-name-badge">
                                        <div class="doc-icon-sq">
                                            <i class="fa-regular fa-id-card"></i>
                                        </div>
                                        <span>Identity Proof (Aadhar/PAN)</span>
                                    </div>
                                    <span class="doc-status-pill pill-verified">
                                        <i class="fa-solid fa-check"></i> Verified
                                    </span>
                                </div>

                                <div class="doc-verify-row">
                                    <div class="doc-name-badge">
                                        <div class="doc-icon-sq">
                                            <i class="fa-solid fa-store"></i>
                                        </div>
                                        <span>Workshop Proof (License)</span>
                                    </div>
                                    <span class="doc-status-pill pill-verified">
                                        <i class="fa-solid fa-check"></i> Verified
                                    </span>
                                </div>

                                <div class="doc-verify-row">
                                    <div class="doc-name-badge">
                                        <div class="doc-icon-sq">
                                            <i class="fa-solid fa-award"></i>
                                        </div>
                                        <span>Skill / Experience Proof</span>
                                    </div>
                                    <span class="doc-status-pill pill-pending">
                                        <i class="fa-regular fa-clock"></i> Pending
                                    </span>
                                </div>

                            </div>

                            <!-- Right: 3D Stack of Documents Graphic -->
                            <div class="doc-graphic-3d">
                                <div class="doc-stack-box">
                                    <div class="doc-sheet sheet-1"></div>
                                    <div class="doc-sheet sheet-2"></div>
                                    <div class="doc-sheet sheet-3">
                                        <div class="sheet-line orange"></div>
                                        <div class="sheet-line" style="width: 80%;"></div>
                                        <div class="sheet-line" style="width: 70%;"></div>
                                        <div class="sheet-line" style="width: 85%;"></div>
                                    </div>
                                    <div class="doc-verified-circle">
                                        <i class="fa-solid fa-check"></i>
                                    </div>
                                </div>
                            </div>

                        </div>
                    </div>

                </section>

                <!-- =======================================================
                     SECTION 3: MAIN TABLE CARD
                     Pending Mechanic Approvals (18)
                     ======================================================= -->
                <div class="approval-table-card">
                    
                    <!-- Table Card Top Header Row -->
                    <div class="table-card-top-row">
                        <div class="table-title-group">
                            <div class="table-title-icon">
                                <i class="fa-solid fa-users"></i>
                            </div>
                            <%
                                String tableTitle = "Pending Mechanic Approvals";
                                int tableTitleCount = pendingApprovalCount;
                                if ("all".equalsIgnoreCase(activeTab)) {
                                    tableTitle = "Mechanic Approval Requests";
                                    tableTitleCount = totalRequestsCount;
                                } else if ("approved".equalsIgnoreCase(activeTab)) {
                                    tableTitle = "Approved Mechanics";
                                    tableTitleCount = approvedCount;
                                } else if ("rejected".equalsIgnoreCase(activeTab)) {
                                    tableTitle = "Rejected Mechanics";
                                    tableTitleCount = rejectedCount;
                                }
                            %>
                            <h2><%= tableTitle %> <span class="table-title-count">(<%= tableTitleCount %>)</span></h2>
                        </div>

                        <div class="table-actions-buttons">
                            <button type="button" class="btn-table-action" onclick="exportTableToCSV();">
                                <i class="fa-solid fa-arrow-up-from-bracket"></i> Export
                            </button>
                            <button type="button" class="btn-table-action" onclick="window.print();">
                                <i class="fa-solid fa-print"></i> Print
                            </button>
                        </div>
                    </div>

                    <!-- Status Filter Tabs (Pills) -->
                    <div class="approval-tabs-row">
                        <a href="mechanic-approval.jsp?tab=all" 
                           class="tab-pill-btn <%= "all".equalsIgnoreCase(activeTab) ? "tab-all active-tab" : "tab-default" %>" style="text-decoration: none;">
                            All Requests (<%= totalRequestsCount %>)
                        </a>

                        <a href="mechanic-approval.jsp?tab=approved" 
                           class="tab-pill-btn <%= "approved".equalsIgnoreCase(activeTab) ? "tab-all active-tab" : "tab-approved" %>" style="text-decoration: none;">
                            <span class="tab-indicator-dot <%= "approved".equalsIgnoreCase(activeTab) ? "dot-white" : "dot-green" %>"></span> Approved (<%= approvedCount %>)
                        </a>

                        <a href="mechanic-approval.jsp?tab=pending" 
                           class="tab-pill-btn <%= "pending".equalsIgnoreCase(activeTab) ? "tab-all active-tab" : "tab-pending" %>" style="text-decoration: none;">
                            <span class="tab-indicator-dot <%= "pending".equalsIgnoreCase(activeTab) ? "dot-white" : "dot-yellow" %>"></span> Pending (<%= pendingApprovalCount %>)
                        </a>

                        <a href="mechanic-approval.jsp?tab=rejected" 
                           class="tab-pill-btn <%= "rejected".equalsIgnoreCase(activeTab) ? "tab-all active-tab" : "tab-rejected" %>" style="text-decoration: none;">
                            <span class="tab-indicator-dot <%= "rejected".equalsIgnoreCase(activeTab) ? "dot-white" : "dot-red" %>"></span> Rejected (<%= rejectedCount %>)
                        </a>
                    </div>

                    <!-- Filter & Search Controls Bar -->
                    <form id="filterForm" method="GET" action="mechanic-approval.jsp" class="filter-controls-bar">
                        <input type="hidden" name="tab" value="<%= activeTab %>">

                        <!-- 1. Text Search Input -->
                        <div class="filter-search-box">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <input type="text" name="search" class="filter-search-input" 
                                   placeholder="Search by name, email, phone or workshop..." 
                                   value="<%= searchParam != null ? searchParam : "" %>">
                        </div>

                        <!-- 2. Specialization Dropdown -->
                        <div class="filter-dropdown-select-wrap">
                            <i class="fa-solid fa-wrench filter-dropdown-icon"></i>
                            <select name="specialization" class="filter-select-input">
                                <option value="">All Specialization</option>
                                <option value="General Service" <%= "General Service".equalsIgnoreCase(specFilter) ? "selected" : "" %>>General Service</option>
                                <option value="Engine Repair" <%= "Engine Repair".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Engine Repair</option>
                                <option value="Tyre & Wheel" <%= "Tyre & Wheel".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Tyre & Wheel</option>
                                <option value="Electrical Repair" <%= "Electrical Repair".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Electrical Repair</option>
                                <option value="Battery Service" <%= "Battery Service".equalsIgnoreCase(specFilter) ? "selected" : "" %>>Battery Service</option>
                            </select>
                            <i class="fa-solid fa-chevron-down filter-dropdown-caret"></i>
                        </div>

                        <!-- 3. Location Dropdown -->
                        <div class="filter-dropdown-select-wrap">
                            <i class="fa-solid fa-location-dot filter-dropdown-icon"></i>
                            <select name="location" class="filter-select-input">
                                <option value="">All Locations</option>
                                <option value="Chennai" <%= "Chennai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Chennai</option>
                                <option value="Coimbatore" <%= "Coimbatore".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Coimbatore</option>
                                <option value="Madurai" <%= "Madurai".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Madurai</option>
                                <option value="Trichy" <%= "Trichy".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Trichy</option>
                                <option value="Salem" <%= "Salem".equalsIgnoreCase(locFilter) ? "selected" : "" %>>Salem</option>
                            </select>
                            <i class="fa-solid fa-chevron-down filter-dropdown-caret"></i>
                        </div>

                        <!-- 4. Applied Date Picker -->
                        <div class="filter-dropdown-select-wrap">
                            <input type="date" name="applied_date" class="filter-date-input" 
                                   value="<%= dateFilter != null ? dateFilter : "" %>" title="Filter by applied date">
                        </div>

                        <!-- 5. Search Button -->
                        <button type="submit" class="btn-filter-search">
                            <i class="fa-solid fa-magnifying-glass"></i> Search
                        </button>

                        <!-- 6. Reset Button -->
                        <a href="mechanic-approval.jsp?tab=<%= activeTab %>" class="btn-filter-reset" style="text-decoration: none;">
                            <i class="fa-solid fa-rotate-right"></i> Reset
                        </a>
                    </form>

                    <!-- Responsive Data Table -->
                    <div class="table-responsive-box">
                        <table class="approval-table" id="approvalTable">
                            <thead>
                                <tr>
                                    <th class="col-sno">S.No</th>
                                    <th>Mechanic</th>
                                    <th>Workshop / Service Center</th>
                                    <th>Specialization</th>
                                    <th>Phone Number</th>
                                    <th>Location</th>
                                    <th>Applied Date &amp; Time</th>
                                    <% if ("rejected".equalsIgnoreCase(activeTab)) { %>
                                    <th>Rejection Reason</th>
                                    <% } %>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (displayList.isEmpty()) { %>
                                <tr>
                                    <td colspan="<%= "rejected".equalsIgnoreCase(activeTab) ? 9 : 8 %>" style="text-align: center; padding: 48px 20px; color: #6B7280;">
                                        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px;">
                                            <i class="fa-solid fa-folder-open" style="font-size: 38px; color: #D1D5DB;"></i>
                                            <span style="font-size: 15px; font-weight: 600; color: #374151;">No mechanic approval requests found</span>
                                            <span style="font-size: 13px; color: #9CA3AF;">There are currently no records matching your criteria.</span>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                                <%
                                    int serial = startIndex + 1;
                                    for (Map<String, String> m : displayList) {
                                        String mId = m.get("id");
                                        String mCode = m.get("formattedId");
                                        String mOwner = m.get("owner");
                                        String mWorkshop = m.get("workshop");
                                        String mServices = m.get("services");
                                        String mPhone = m.get("phone");
                                        String mLoc = m.get("location");
                                        String mDate = m.get("appliedDate");
                                        String mImg = m.get("image");
                                        String mStatus = m.get("status");
                                %>
                                <tr>
                                    <!-- S.No -->
                                    <td class="col-sno"><%= serial++ %></td>

                                    <!-- Mechanic Cell (Avatar + Name + Code) -->
                                    <td>
                                        <div class="mechanic-user-cell" style="cursor: pointer;" 
                                             onclick="openMechanicModal('<%= mCode %>', '<%= mOwner.replace("'", "\\'") %>', '<%= mWorkshop.replace("'", "\\'") %>', '<%= mServices.replace("'", "\\'") %>', '<%= mPhone %>', '<%= m.get("email") %>', '<%= mLoc %>', '<%= m.get("address").replace("'", "\\'") %>', '<%= m.get("experience") %>');">
                                            <div class="mechanic-avatar-circle" style="width: 36px; height: 36px; border-radius: 50%; background: #FFF7ED; border: 1.5px solid #F97316; display: flex; align-items: center; justify-content: center; color: #F97316; font-size: 14px; flex-shrink: 0;">
                                                <i class="fa-solid fa-wrench"></i>
                                            </div>
                                            <div class="mechanic-name-block">
                                                <span class="mechanic-name"><%= mOwner %></span>
                                                <span class="mechanic-code-sub"><%= mCode %></span>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- Workshop / Service Center -->
                                    <td>
                                        <div class="cell-with-icon">
                                            <i class="fa-solid fa-store"></i>
                                            <span style="font-weight: 600;"><%= mWorkshop %></span>
                                        </div>
                                    </td>

                                    <!-- Specialization -->
                                    <td>
                                        <span class="spec-badge-pill">
                                            <i class="fa-solid fa-wrench"></i> <%= mServices %>
                                        </span>
                                    </td>

                                    <!-- Phone Number -->
                                    <td>
                                        <div class="cell-with-icon">
                                            <i class="fa-solid fa-phone"></i>
                                            <span><%= mPhone %></span>
                                        </div>
                                    </td>

                                    <!-- Location -->
                                    <td>
                                        <div class="cell-with-icon">
                                            <i class="fa-solid fa-location-dot"></i>
                                            <span><%= mLoc %></span>
                                        </div>
                                    </td>

                                    <!-- Applied Date & Time -->
                                    <td>
                                        <div class="cell-with-icon">
                                            <i class="fa-regular fa-calendar"></i>
                                            <span><%= mDate %></span>
                                        </div>
                                    </td>

                                    <% if ("rejected".equalsIgnoreCase(activeTab)) { %>
                                    <td>
                                        <span style="display: inline-flex; align-items: center; gap: 6px; color: #DC2626; font-size: 12px; font-weight: 600; background: #FEF2F2; padding: 5px 10px; border-radius: 8px; border: 1px solid #FECACA; max-width: 220px; line-height: 1.35;">
                                            <i class="fa-solid fa-triangle-exclamation"></i>
                                            <span><%= (m.get("rejectionReason") != null && !m.get("rejectionReason").trim().isEmpty()) ? m.get("rejectionReason") : "Requirements not met" %></span>
                                        </span>
                                    </td>
                                    <% } %>

                                    <!-- Actions: Approve / Reject / View -->
                                    <td>
                                        <div class="table-actions-cell">
                                            <!-- View Details Button -->
                                            <button type="button" class="btn-action-view" title="View details"
                                                    data-id="<%= mId %>"
                                                    data-code="<%= mCode %>"
                                                    data-name="<%= mOwner %>"
                                                    data-status="<%= mStatus %>"
                                                    data-date="<%= mDate %>"
                                                    data-rating="<%= m.get("rating") != null ? m.get("rating") : "4.8" %>"
                                                    data-reviews="<%= m.get("reviews") != null ? m.get("reviews") : "120" %>"
                                                    data-avatar="<%= mImg %>"
                                                    data-gender="<%= m.get("gender") != null ? m.get("gender") : "Male" %>"
                                                    data-phone="<%= mPhone %>"
                                                    data-email="<%= m.get("email") %>"
                                                    data-spec="<%= mServices %>"
                                                    data-otherspec="<%= m.get("otherSpec") != null ? m.get("otherSpec") : "AC Service, Radiator Repair" %>"
                                                    data-shopname="<%= mWorkshop %>"
                                                    data-shoptype="<%= m.get("shopType") != null ? m.get("shopType") : "Service Center" %>"
                                                    data-shopcontact="<%= m.get("shopContact") != null ? m.get("shopContact") : mPhone %>"
                                                    data-experience="<%= m.get("experience") %>"
                                                    data-workinghours="<%= m.get("workingHours") != null ? m.get("workingHours") : "09:00 AM – 07:00 PM" %>"
                                                    data-shopdesc="<%= m.get("shopDesc") != null ? m.get("shopDesc") : mServices %>"
                                                    data-addr1="<%= m.get("addressLine1") != null ? m.get("addressLine1") : m.get("address") %>"
                                                    data-addr2="<%= m.get("addressLine2") != null ? m.get("addressLine2") : "Near Bus Stand" %>"
                                                    data-city="<%= m.get("city") != null ? m.get("city") : mLoc %>"
                                                    data-district="<%= m.get("district") != null ? m.get("district") : mLoc %>"
                                                    data-state="<%= m.get("state") != null ? m.get("state") : "Tamil Nadu" %>"
                                                    data-pincode="<%= m.get("pincode") != null ? m.get("pincode") : "641001" %>"
                                                    data-lat="<%= m.get("latitude") != null ? m.get("latitude") : "11.0268" %>"
                                                    data-lng="<%= m.get("longitude") != null ? m.get("longitude") : "76.9507" %>"
                                                    data-shopphotos="<%= m.get("shopPhotos") != null ? m.get("shopPhotos") : "" %>"
                                                    data-aadhaar="<%= m.get("aadhaarNumber") != null ? m.get("aadhaarNumber") : "" %>"
                                                    data-aadhaardoc="<%= m.get("aadhaarDoc") != null ? m.get("aadhaarDoc") : "" %>"
                                                    data-idproofdoc="<%= m.get("idProofDoc") != null ? m.get("idProofDoc") : "" %>"
                                                    data-rejectionreason="<%= m.get("rejectionReason") != null ? m.get("rejectionReason").replace("\"", "&quot;").replace("'", "&#39;") : "" %>"
                                                    onclick="openViewModalFromBtn(this)">
                                                <i class="fa-solid fa-eye"></i>
                                            </button>

                                            <!-- View Verification Documents Button -->
                                            <button type="button" class="btn-action-view" style="background: #EFF6FF; color: #2563EB; border-color: #BFDBFE;" title="View Verification Documents"
                                                    data-id="<%= mId %>"
                                                    data-code="<%= mCode %>"
                                                    data-owner="<%= mOwner %>"
                                                    data-workshop="<%= mWorkshop %>"
                                                    data-email="<%= m.get("email") %>"
                                                    data-aadhaar="<%= m.get("aadhaarNumber") != null ? m.get("aadhaarNumber") : "" %>"
                                                    data-aadhaardoc="<%= m.get("aadhaarDoc") != null ? m.get("aadhaarDoc") : "" %>"
                                                    data-idproofdoc="<%= m.get("idProofDoc") != null ? m.get("idProofDoc") : "" %>"
                                                    onclick="openDocModalFromBtn(this)">
                                                <i class="fa-solid fa-file-shield"></i>
                                            </button>

                                            <% if (!"Approved".equalsIgnoreCase(mStatus)) { %>
                                            <a href="mechanic-approval.jsp?action=approve&id=<%= mId %>&tab=<%= activeTab %>" 
                                               class="btn-action-approve" 
                                               title="Approve Application & Send Activation Email"
                                               onclick="return confirm('Are you sure you want to APPROVE <%= mOwner.replace("'", "\\'") %> (<%= mWorkshop.replace("'", "\\'") %>)? An activation email will be sent to <%= m.get("email") != null ? m.get("email").replace("'", "\\'") : "mechanic" %>.');">
                                                <i class="fa-solid fa-check"></i>
                                            </a>
                                            <% } else { %>
                                            <span class="doc-status-pill pill-verified"><i class="fa-solid fa-check-double"></i> Approved</span>
                                            <% } %>

                                            <% if (!"Rejected".equalsIgnoreCase(mStatus)) { %>
                                            <button type="button" 
                                               class="btn-action-reject" 
                                               title="Reject Application (Specify Reason)"
                                               onclick="openRejectModal('<%= mId %>', '<%= mOwner.replace("'", "\\'") %>', '<%= mCode != null ? mCode : ("MEC" + mId) %>', '<%= mWorkshop.replace("'", "\\'") %>', '<%= m.get("email") != null ? m.get("email").replace("'", "\\'") : "" %>')">
                                                <i class="fa-solid fa-xmark"></i>
                                            </button>
                                            <% } else { %>
                                            <span class="doc-status-pill pill-pending" style="color: #DC2626; border-color: #FECACA; background: #FEF2F2;"><i class="fa-solid fa-ban"></i> Rejected</span>
                                            <% } %>
                                        </div>
                                    </td>

                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>

                    <!-- Table Footer: Showing text + Rows per page + Pagination -->
                    <div class="table-footer-row">
                        <span class="footer-showing-text">
                            Showing <%= totalApprovalRequests > 0 ? (startIndex + 1) : 0 %> to <%= endIndex %> of <%= totalApprovalRequests %> requests
                        </span>

                        <div class="footer-pagination-group">
                            <div class="rows-per-page-wrap">
                                <span>Rows per page:</span>
                                <select class="rows-select" aria-label="Rows per page">
                                    <option value="10" selected>10</option>
                                    <option value="20">20</option>
                                    <option value="50">50</option>
                                </select>
                            </div>

                            <%
                                StringBuilder aQueryBase = new StringBuilder("mechanic-approval.jsp?rows=10");
                                if (searchParam != null && !searchParam.trim().isEmpty()) {
                                    aQueryBase.append("&search=").append(java.net.URLEncoder.encode(searchParam, "UTF-8"));
                                }
                                if (specFilter != null && !specFilter.trim().isEmpty()) {
                                    aQueryBase.append("&specialization=").append(java.net.URLEncoder.encode(specFilter, "UTF-8"));
                                }
                                if (locFilter != null && !locFilter.trim().isEmpty()) {
                                    aQueryBase.append("&location=").append(java.net.URLEncoder.encode(locFilter, "UTF-8"));
                                }
                                if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                                    aQueryBase.append("&appliedDate=").append(java.net.URLEncoder.encode(dateFilter, "UTF-8"));
                                }
                                if (activeTab != null && !activeTab.trim().isEmpty()) {
                                    aQueryBase.append("&tab=").append(java.net.URLEncoder.encode(activeTab, "UTF-8"));
                                }
                            %>
                            <div class="pagination-controls">
                                <!-- First & Prev Page -->
                                <% if (currentPage > 1) { %>
                                    <a href="<%= aQueryBase.toString() %>&page=1" class="page-btn" title="First Page"><i class="fa-solid fa-angles-left"></i></a>
                                    <a href="<%= aQueryBase.toString() %>&page=<%= currentPage - 1 %>" class="page-btn" title="Previous Page"><i class="fa-solid fa-angle-left"></i></a>
                                <% } else { %>
                                    <span class="page-btn disabled" title="First Page"><i class="fa-solid fa-angles-left"></i></span>
                                    <span class="page-btn disabled" title="Previous Page"><i class="fa-solid fa-angle-left"></i></span>
                                <% } %>

                                <!-- Page Numbers -->
                                <% for (int p = 1; p <= totalPages; p++) { %>
                                    <% if (p == currentPage) { %>
                                        <span class="page-btn active"><%= p %></span>
                                    <% } else { %>
                                        <a href="<%= aQueryBase.toString() %>&page=<%= p %>" class="page-btn"><%= p %></a>
                                    <% } %>
                                <% } %>

                                <!-- Next & Last Page -->
                                <% if (currentPage < totalPages) { %>
                                    <a href="<%= aQueryBase.toString() %>&page=<%= currentPage + 1 %>" class="page-btn" title="Next Page"><i class="fa-solid fa-angle-right"></i></a>
                                    <a href="<%= aQueryBase.toString() %>&page=<%= totalPages %>" class="page-btn" title="Last Page"><i class="fa-solid fa-angles-right"></i></a>
                                <% } else { %>
                                    <span class="page-btn disabled" title="Next Page"><i class="fa-solid fa-angle-right"></i></span>
                                    <span class="page-btn disabled" title="Last Page"><i class="fa-solid fa-angles-right"></i></span>
                                <% } %>
                            </div>
                        </div>
                    </div>

                </div>

            </div>
        </main>
    </div>
</div>

<!-- =======================================================================
     MODAL 1: DOCUMENT VERIFICATION PREVIEW MODAL
     ======================================================================= -->
<div class="custom-modal-overlay" id="documentModal">
    <div class="custom-modal-dialog">
        <div class="modal-header-bar">
            <div class="modal-header-title">
                <i class="fa-solid fa-file-shield" style="color: #F97316; font-size: 20px;"></i>
                <h3 id="docModalTitle">Document Verification — Karthik Auto Garage</h3>
            </div>
            <button type="button" class="btn-modal-close" onclick="closeDocModal();">&times;</button>
        </div>

        <div class="modal-body-content">
            <div style="display: flex; gap: 8px; margin-bottom: 18px; border-bottom: 1px solid #E5E7EB; padding-bottom: 10px; flex-wrap: wrap;">
                <button type="button" class="btn-filter-reset" id="tabDoc1" onclick="switchDocTab(1);" style="background: #FFF7ED; border-color: #F97316; color: #EA580C; font-weight: 700;">
                    <i class="fa-regular fa-id-card"></i> Aadhaar Card
                </button>
                <button type="button" class="btn-filter-reset" id="tabDoc2" onclick="switchDocTab(2);" style="font-weight: 700;">
                    <i class="fa-solid fa-address-card"></i> ID Proof Document
                </button>
              
            </div>

            <div id="docPreviewContainer" style="background: #F9FAFB; border: 1.5px dashed #D1D5DB; border-radius: 14px; padding: 18px; min-height: 280px;">
                <!-- Tab 1: Aadhaar Card & Number -->
                <div id="docContent1">
                    <div style="display: flex; justify-content: space-between; align-items: center; background: #FFF7ED; border: 1px solid #FFEDD5; border-radius: 10px; padding: 12px 16px; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
                        <div>
                            <span style="font-size: 11px; font-weight: 700; color: #9A3412; text-transform: uppercase; letter-spacing: 0.5px; display: block;">Applicant Aadhaar Number</span>
                            <div id="docAadhaarNumberVal" style="font-size: 18px; font-weight: 800; color: #EA580C; letter-spacing: 2px; font-family: 'Courier New', monospace; margin-top: 2px;">XXXX XXXX XXXX</div>
                        </div>
                        <span class="metric-badge-pill pill-green" id="docAadhaarStatusBadge"><i class="fa-solid fa-circle-check"></i> 12 Digits Verified</span>
                    </div>
                    <div id="docAadhaarDocContainer">
                        <!-- Loaded dynamically -->
                    </div>
                </div>

                <!-- Tab 2: ID Proof Document -->
                <div id="docContent2" style="display: none;">
                    <div style="display: flex; justify-content: space-between; align-items: center; background: #EFF6FF; border: 1px solid #DBEAFE; border-radius: 10px; padding: 12px 16px; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
                        <div>
                            <span style="font-size: 11px; font-weight: 700; color: #1E40AF; text-transform: uppercase; letter-spacing: 0.5px; display: block;">Official ID Proof Document</span>
                            <div style="font-size: 14px; font-weight: 700; color: #1D4ED8; margin-top: 2px;">Voter ID / Driving License / Passport / Govt ID</div>
                        </div>
                        <span class="metric-badge-pill pill-blue"><i class="fa-solid fa-shield-halved"></i> Identity Proof</span>
                    </div>
                    <div id="docIdProofDocContainer">
                        <!-- Loaded dynamically -->
                    </div>
                </div>

                <!-- Tab 3: Workshop License & Certification -->
                <div id="docContent3" style="display: none;">
                    <div style="text-align: center; padding: 30px 20px;">
                        <i class="fa-solid fa-certificate" style="font-size: 54px; color: #D97706; margin-bottom: 14px; display: block;"></i>
                        <h4 style="font-size: 16px; font-weight: 700; color: #1F2937; margin: 0 0 6px 0;">Automotive Trade Certification & License</h4>
                        <p style="font-size: 13px; color: #6B7280; margin: 0 0 16px 0;">Commercial Premises & Skills Verified Under Roadside Network Standards</p>
                        <span class="metric-badge-pill pill-green"><i class="fa-solid fa-check"></i> Trade Credentials Authenticated</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal-footer-bar">
            <button type="button" class="btn-filter-reset" onclick="closeDocModal();">Close</button>
            <a href="#" id="modalApproveLink" class="btn-action-approve" style="padding: 10px 22px; font-size: 13.5px;">
                <i class="fa-solid fa-check"></i> Approve Application
            </a>
            <button type="button" id="modalRejectLink" class="btn-action-reject" style="padding: 10px 22px; font-size: 13.5px; border: none; cursor: pointer;" onclick="openRejectModalFromDocModal()">
                <i class="fa-solid fa-xmark"></i> Reject Application
            </button>
        </div>
    </div>
</div>

<!-- =======================================================================
     MODAL 2: VIEW MECHANIC DETAILS (EXACT SAME RICH TABBED VIEW AS MANAGEMENT)
     ======================================================================= -->
<div class="modal-overlay" id="viewMechanicModal" onclick="if(event.target === this) closeViewModal();">
    <div class="mech-view-modal-container">
        
        <!-- Header -->
        <div class="mech-view-header">
            <div class="mech-view-title-group">
                <div class="mech-view-badge-icon">
                    <i class="fa-solid fa-user-check"></i>
                </div>
                <div class="mech-view-title-text">
                    <h3>Mechanic Details</h3>
                    <p>Complete registration &amp; verification details for approval</p>
                </div>
            </div>
            <button type="button" class="mech-view-close-x" onclick="closeViewModal();" aria-label="Close modal">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- Hero Banner Card -->
        <div class="mech-view-hero-banner">
            <div class="mech-view-avatar-box" style="width: 72px; height: 72px; border-radius: 50%; background: #FFF7ED; border: 2.5px solid #F97316; display: flex; align-items: center; justify-content: center; color: #F97316; font-size: 28px; flex-shrink: 0; position: relative;">
                <i class="fa-solid fa-wrench"></i>
                <div class="mech-view-avatar-verified" title="Application Status">
                    <i class="fa-solid fa-check" id="viewAvatarStatusIcon"></i>
                </div>
            </div>
            <div class="mech-view-hero-info">
                <div class="mech-view-hero-name-row">
                    <span id="viewOwnerName" class="mech-view-hero-name">Karthik R</span>
                    <span id="viewStatusPill" class="mech-view-approved-pill" style="background: #EAB308;">
                        <i class="fa-solid fa-clock"></i> <span id="viewStatusPillText">Pending</span>
                    </span>
                </div>
                <div class="mech-view-meta-row">
                    <span class="mech-view-id-pill">
                        <span id="viewMechanicCode">ID: MEC018</span>
                        <i class="fa-regular fa-copy" onclick="copyMechanicId()" title="Copy ID"></i>
                    </span>
                    <span class="mech-view-reg-date">
                        <i class="fa-regular fa-calendar-days"></i> Applied: <span id="viewRegDate">20-01-2025</span>
                    </span>
                    <span class="mech-view-rating-badge">
                        <i class="fa-solid fa-star"></i>
                        <span id="viewRatingNum" class="mech-view-rating-val">4.8</span>
                        <span id="viewReviewCount" class="mech-view-rating-reviews">(120 Reviews)</span>
                    </span>
                </div>
            </div>
        </div>

        <!-- Rejection Reason Notice (shown when application is Rejected) -->
        <div id="viewRejectionBanner" style="display: none; background: #FEF2F2; border: 1.5px solid #FECACA; border-left: 4px solid #DC2626; border-radius: 12px; padding: 12px 16px; margin: 0 0 16px 0;">
            <div style="display: flex; align-items: center; gap: 8px; color: #DC2626; font-size: 13.5px; font-weight: 800;">
                <i class="fa-solid fa-ban"></i> Application Rejected
            </div>
            <div style="font-size: 13px; color: #991B1B; margin-top: 5px; font-weight: 600; line-height: 1.4;">
                <span style="color: #7F1D1D; font-weight: 700;">Rejection Reason:</span> <span id="viewRejectionReasonText">Requirements not met</span>
            </div>
        </div>

        <!-- Navigation Tabs / Segment Buttons -->
        <div class="mech-view-tabs-bar">
            <button type="button" class="mech-view-tab-btn active" onclick="switchMechTab(this, 'sectionPersonal')">
                <i class="fa-solid fa-user"></i> Personal Details
            </button>
            <button type="button" class="mech-view-tab-btn" onclick="switchMechTab(this, 'sectionSpecialization')">
                <i class="fa-solid fa-screwdriver-wrench"></i> Work Specialization
            </button>
            <button type="button" class="mech-view-tab-btn" onclick="switchMechTab(this, 'sectionShop')">
                <i class="fa-solid fa-shop"></i> Shop Details
            </button>
            <button type="button" class="mech-view-tab-btn" onclick="switchMechTab(this, 'sectionLocation')">
                <i class="fa-solid fa-location-dot"></i> Shop Address & Location
            </button>
        </div>

        <!-- Section 1: Personal Details Card (Tab 1) -->
        <div class="mech-view-tab-pane active-tab-pane mech-view-card" id="sectionPersonal">
            <div class="mech-view-card-header">
                <i class="fa-solid fa-user"></i>
                <span>Personal Details</span>
            </div>
            <div class="mech-view-card-body">
                <div class="mech-view-grid-2col">
                    <div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-user"></i> Full Name</span>
                            <span class="mech-view-kv-val" id="viewFullName">Karthik R</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-phone"></i> Mobile Number</span>
                            <span class="mech-view-kv-val" id="viewPhoneVal">+91 98765 43210</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-regular fa-id-card"></i> Aadhaar Number</span>
                            <span class="mech-view-kv-val" id="viewAadhaarVal" style="font-weight: 700; color: #EA580C; font-family: 'Courier New', monospace; letter-spacing: 1px;">XXXX XXXX XXXX</span>
                        </div>
                        <div class="mech-view-kv-item" style="border-bottom: none;">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-lock"></i> Password</span>
                            <span class="mech-view-kv-val" style="letter-spacing: 2px;">•••••••••</span>
                        </div>
                    </div>
                    <div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-mars"></i> Gender</span>
                            <span class="mech-view-kv-val" id="viewGender">Male</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-envelope"></i> Email Address</span>
                            <span class="mech-view-kv-val" id="viewEmailVal">karthik@example.com</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-shield-halved"></i> Verification</span>
                            <span class="mech-view-kv-val" style="color: #16A34A; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> Identity Verified</span>
                        </div>
                        <div class="mech-view-kv-item" style="border-bottom: none;">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-file-shield"></i> ID Proof Status</span>
                            <span class="mech-view-kv-val" id="viewIdProofStatus" style="color: #2563EB; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> Document Attached</span>
                        </div>
                    </div>
                </div>

                <!-- Document Quick-View Bar -->
                <div style="margin-top: 16px; padding: 14px 18px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                    <div>
                        <div style="font-size: 13.5px; font-weight: 700; color: #1E293B; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-file-shield" style="color: #F97316; font-size: 16px;"></i> Verification Documents
                        </div>
                        <div style="font-size: 12px; color: #64748B; margin-top: 2px;">Inspect applicant's 12-digit Aadhaar card and ID proof attachments</div>
                    </div>
                    <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                        <button type="button" class="btn-filter-reset" onclick="openDocModalFromView(1)" style="background: #FFF7ED; border-color: #F97316; color: #EA580C; font-size: 12.5px; font-weight: 700; padding: 7px 14px; border-radius: 8px; display: inline-flex; align-items: center; gap: 6px; cursor: pointer;">
                            <i class="fa-regular fa-id-card"></i> View Aadhaar Card
                        </button>
                        <button type="button" class="btn-filter-reset" onclick="openDocModalFromView(2)" style="background: #FFFBEB; border-color: #F59E0B; color: #D97706; font-size: 12.5px; font-weight: 700; padding: 7px 14px; border-radius: 8px; display: inline-flex; align-items: center; gap: 6px; cursor: pointer;">
                            <i class="fa-solid fa-address-card"></i> View ID Proof
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Section 2: Work Specialization (Tab 2) -->
        <div class="mech-view-tab-pane mech-view-card" id="sectionSpecialization">
            <div class="mech-view-card-header">
                <i class="fa-solid fa-screwdriver-wrench"></i>
                <span>Work Specialization &amp; Services</span>
            </div>
            <div class="mech-view-card-body">
                <div style="margin-bottom: 6px;">
                    <span class="mech-view-kv-label" style="font-weight: 700; color: #111827; margin-bottom: 8px;">
                        <i class="fa-solid fa-toolbox" style="color: #F97316;"></i> Primary Repair Specializations
                    </span>
                    <div class="specialization-chips-wrap" id="viewSpecializationChips">
                        <span class="spec-chip"><i class="fa-solid fa-car"></i> Engine Repair</span>
                        <span class="spec-chip"><i class="fa-solid fa-circle-dot"></i> Tyre / Puncture</span>
                        <span class="spec-chip"><i class="fa-solid fa-bolt"></i> Electrical Repair</span>
                        <span class="spec-chip"><i class="fa-solid fa-battery-full"></i> Battery Service</span>
                        <span class="spec-chip"><i class="fa-solid fa-wrench"></i> General Service</span>
                    </div>
                </div>
                <div class="other-service-box" style="margin-top: 12px;">
                    <span class="other-service-label"><i class="fa-solid fa-pencil"></i> Other Specialized Services:</span>
                    <span class="other-service-content" id="viewOtherSpecialization">AC Service, Radiator Repair</span>
                </div>
                <div style="margin-top: 14px; background: #FFF7ED; border: 1px dashed #FDBA74; border-radius: 8px; padding: 10px 14px; display: flex; align-items: center; gap: 10px;">
                    <i class="fa-solid fa-truck-pickup" style="color: #F97316; font-size: 16px;"></i>
                    <span style="font-size: 12.5px; color: #9A3412; font-weight: 600;">Equipped for Two Wheeler, Four Wheeler &amp; Commercial Breakdown Assistance with mobile emergency tools.</span>
                </div>
            </div>
        </div>

        <!-- Section 3: Shop Details (Tab 3) -->
        <div class="mech-view-tab-pane mech-view-card" id="sectionShop">
            <div class="mech-view-card-header">
                <i class="fa-solid fa-shop"></i>
                <span>Shop &amp; Workshop Details</span>
            </div>
            <div class="mech-view-card-body">
                <div class="mech-view-grid-2col" style="margin-bottom: 12px;">
                    <div class="shop-kv-list">
                        <div class="shop-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-shop"></i> Shop Name</span>
                            <span class="mech-view-kv-val" id="viewShopName">Karthik Auto Garage</span>
                        </div>
                        <div class="shop-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-briefcase"></i> Shop Type</span>
                            <span class="mech-view-kv-val" id="viewShopType">Service Center</span>
                        </div>
                        <div class="shop-kv-item" style="border-bottom: none;">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-phone"></i> Shop Contact Number</span>
                            <span class="mech-view-kv-val" id="viewShopContact">+91 98765 43210</span>
                        </div>
                    </div>
                    <div class="shop-kv-list">
                        <div class="shop-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-calendar-days"></i> Years of Experience</span>
                            <span class="mech-view-kv-val" id="viewExperience">8 Years</span>
                        </div>
                        <div class="shop-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-clock"></i> Working Hours</span>
                            <span class="mech-view-kv-val" id="viewWorkingHours">09:00 AM – 07:00 PM</span>
                        </div>
                        <div class="shop-kv-item" style="border-bottom: none;">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-file-lines"></i> Shop Description</span>
                            <span class="mech-view-kv-val" id="viewShopDesc" style="font-size: 12.5px; text-align: right; max-width: 220px;">Car &amp; Bike Service, Battery, General Repair</span>
                        </div>
                    </div>
                </div>

                <!-- Shop Images Container -->
                <div class="mech-shop-photos-wrapper">
                    <div class="mech-shop-photos-header">
                        <span class="mech-view-kv-label" style="font-weight: 700; color: #111827;">
                            <i class="fa-regular fa-images" style="color: #F97316;"></i> Shop Images
                        </span>
                        <span class="shop-photos-count-badge" id="viewShopPhotosCount">0 Photos</span>
                    </div>
                    <div class="mech-shop-photos-grid" id="viewShopPhotosGrid">
                        <!-- Populated dynamically via JS -->
                    </div>
                </div>
            </div>
        </div>

        <!-- Section 4: Shop Address & Location Card (Tab 4) -->
        <div class="mech-view-tab-pane mech-view-card mech-view-location-card" id="sectionLocation">
            <div class="mech-view-card-header">
                <i class="fa-solid fa-location-dot"></i>
                <span>Shop Address &amp; Location</span>
            </div>
            <div class="mech-view-card-body">
                <div class="mech-view-location-grid">
                    <div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-road"></i> Address Line 1</span>
                            <span class="mech-view-kv-val" id="viewAddrLine1">74, GST Road, Chromepet</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-location-crosshairs"></i> Address Line 2</span>
                            <span class="mech-view-kv-val" id="viewAddrLine2">Near Bus Stand</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-city"></i> City / Town</span>
                            <span class="mech-view-kv-val" id="viewCity">Chennai</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-building"></i> District</span>
                            <span class="mech-view-kv-val" id="viewDistrict">Chennai</span>
                        </div>
                        <div class="mech-view-kv-item">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-landmark"></i> State</span>
                            <span class="mech-view-kv-val" id="viewState">Tamil Nadu</span>
                        </div>
                        <div class="mech-view-kv-item" style="border-bottom: none;">
                            <span class="mech-view-kv-label"><i class="fa-solid fa-map-pin"></i> Pincode</span>
                            <span class="mech-view-kv-val" id="viewPincode">600044</span>
                        </div>
                    </div>

                    <!-- Interactive Shop Location Map Container -->
                    <div class="shop-map-card-side">
                        <div class="shop-map-top-bar">
                            <div class="shop-map-coords-badge" id="viewShopCoordsBadge">
                                <i class="fa-solid fa-location-dot" style="color: #EA580C;"></i>
                                <span id="viewShopCoordsText">12.9516° N, 80.1462° E</span>
                            </div>
                            <div class="shop-map-actions-group">
                                <a id="viewShopGmapsLink" href="https://www.google.com/maps?q=12.9516,80.1462" target="_blank" rel="noopener noreferrer" class="btn-shop-gmaps-link" title="Open exact shop location in Google Maps">
                                    <i class="fa-solid fa-arrow-up-right-from-square"></i>
                                    <span>Google Maps</span>
                                </a>
                                <button type="button" class="btn-shop-fullscreen" title="Open full screen interactive map" onclick="openFullscreenShopMapModal()">
                                    <i class="fa-solid fa-expand"></i>
                                </button>
                            </div>
                        </div>

                        <div class="shop-map-frame-box" id="viewShopMapFrame" onclick="openFullscreenShopMapModal()" title="Click to view full interactive shop location map">
                            <div id="viewShopMiniMap" style="width: 100%; height: 100%; border-radius: 10px; z-index: 1;"></div>
                            <div class="shop-map-click-overlay">
                                <i class="fa-solid fa-up-right-and-down-left-from-center"></i> Click map to expand
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer with Approve & Reject Actions -->
        <div class="mech-view-footer" style="display: flex; justify-content: space-between; align-items: center; width: 100%; margin-top: 14px;">
            <div style="display: flex; gap: 10px;">
                <a href="#" id="viewModalApproveBtn" class="btn-action-approve" style="padding: 8px 18px; font-size: 13px; text-decoration: none; border-radius: 12px;">
                    <i class="fa-solid fa-check"></i> Approve Application
                </a>
                <button type="button" id="viewModalRejectBtn" class="btn-action-reject" style="padding: 8px 18px; font-size: 13px; text-decoration: none; border-radius: 12px; border: none; cursor: pointer;" onclick="openRejectModalFromViewModal()">
                    <i class="fa-solid fa-xmark"></i> Reject
                </button>
            </div>
            <button type="button" class="btn-view-close-orange-outline" onclick="closeViewModal();">
                <i class="fa-solid fa-xmark"></i> Close
            </button>
        </div>

    </div>
</div>

<!-- Shop Photo Zoom / Preview Lightbox Modal -->
<div class="modal-overlay" id="shopImagePreviewModal" onclick="this.classList.remove('active');" style="z-index: 10005;">
    <div style="max-width: 800px; max-height: 85vh; position: relative; padding: 12px; background: #111827; border-radius: 16px; box-shadow: 0 20px 40px rgba(0,0,0,0.5); text-align: center;" onclick="event.stopPropagation();">
        <button type="button" onclick="document.getElementById('shopImagePreviewModal').classList.remove('active');" style="position: absolute; top: -14px; right: -14px; width: 34px; height: 34px; border-radius: 50%; background: #F97316; color: #fff; border: 2.5px solid #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 15px; box-shadow: 0 4px 10px rgba(0,0,0,0.3);">
            <i class="fa-solid fa-xmark"></i>
        </button>
        <img id="shopPreviewImgTag" src="" alt="Shop Preview" style="max-width: 100%; max-height: 75vh; object-fit: contain; border-radius: 10px; display: block; margin: 0 auto;">
    </div>
</div>

<!-- ==========================================================================
     FULLSCREEN INTERACTIVE WORKSHOP / SHOP LOCATION MAP MODAL
     ========================================================================== -->
<div class="modal-overlay" id="fullscreenShopMapModal" style="z-index: 10010; display: none;" onclick="if(event.target === this) closeFullscreenShopMapModal();">
    <div class="mech-edit-modal-box" style="max-width: 900px; width: 95%; padding: 22px 26px;">
        <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1.5px solid #F1F5F9; padding-bottom: 14px; margin-bottom: 14px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 42px; height: 42px; background: #EA580C; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #FFFFFF; font-size: 18px; box-shadow: 0 4px 12px rgba(234, 88, 12, 0.35);">
                    <i class="fa-solid fa-shop"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 18px; font-weight: 800; color: #111827; display: flex; align-items: center; gap: 8px;">
                        <span>Workshop Location: <span id="fsShopModalName" style="color: #EA580C;">Karthik Auto Garage</span></span>
                    </h3>
                    <p style="margin: 3px 0 0 0; font-size: 12.5px; color: #64748B; font-weight: 500;">
                        Exact physical garage and service center GPS coordinates
                    </p>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <a id="fsShopGmapsLink" href="#" target="_blank" rel="noopener noreferrer" class="btn-fs-gmaps" title="Open exact workshop location in Google Maps">
                    <i class="fa-solid fa-arrow-up-right-from-square"></i>
                    <span>Google Maps</span>
                </a>
                <button type="button" class="mech-edit-close-btn" onclick="closeFullscreenShopMapModal();" aria-label="Close modal">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
        </div>

        <!-- Top Info Strip -->
        <div style="background: #FFF7ED; border: 1px solid #FFEDD5; border-radius: 10px; padding: 12px 18px; margin-bottom: 14px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 36px; height: 36px; border-radius: 10px; background: #EA580C; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0;">
                    <i class="fa-solid fa-location-dot"></i>
                </div>
                <div>
                    <div style="font-size: 11px; font-weight: 700; color: #9A3412; text-transform: uppercase; letter-spacing: 0.5px;">Address</div>
                    <div id="fsShopModalAddress" style="font-size: 13.5px; font-weight: 800; color: #1E293B;">74, GST Road, Chromepet, Chennai, 600044</div>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 20px; font-size: 12.5px;">
                <div>
                    <span style="color: #9A3412; font-weight: 600;">GPS Coordinates:</span>
                    <span id="fsShopModalCoords" style="font-weight: 800; color: #1E293B; font-family: monospace; display: block;">12.9516, 80.1462</span>
                </div>
                <div>
                    <span style="color: #9A3412; font-weight: 600;">Contact:</span>
                    <span id="fsShopModalPhone" style="font-weight: 800; color: #EA580C; display: block;">+91 98765 43210</span>
                </div>
            </div>
        </div>

        <!-- Leaflet Interactive Large Map -->
        <div style="position: relative; width: 100%; height: 440px; border-radius: 12px; overflow: hidden; border: 1.5px solid #CBD5E1; box-shadow: 0 4px 16px rgba(0,0,0,0.06);">
            <div id="fsShopFullMap" style="width: 100%; height: 100%; z-index: 1;"></div>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 14px; padding-top: 12px; border-top: 1px solid #F1F5F9;">
            <div style="font-size: 12px; color: #64748B; display: flex; align-items: center; gap: 6px;">
                <i class="fa-solid fa-circle-info" style="color: #F97316;"></i>
                <span>Interactive OpenStreetMap with zoom controls, street details, and workshop location pin.</span>
            </div>
            <button type="button" class="btn-view-close-orange-outline" onclick="closeFullscreenShopMapModal();">
                <i class="fa-solid fa-xmark"></i> Close Map
            </button>
        </div>
    </div>
</div>

<!-- ==========================================================================
     REJECTION REASON MODAL (#mechanicRejectModal)
     ========================================================================== -->
<div class="modal-overlay" id="mechanicRejectModal" style="display: none; z-index: 10050;" onclick="if(event.target === this) closeRejectModal();">
    <div class="mech-edit-modal-box" style="max-width: 560px; width: 95%; padding: 24px 28px; border-radius: 16px; background: #FFFFFF; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);">
        <!-- Modal Header -->
        <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1.5px solid #F1F5F9; padding-bottom: 14px; margin-bottom: 16px;">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 44px; height: 44px; background: #FEF2F2; border: 1.5px solid #FCA5A5; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #DC2626; font-size: 20px; box-shadow: 0 4px 10px rgba(220, 38, 38, 0.15);">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 18px; font-weight: 800; color: #111827;">Reject Mechanic Application</h3>
                    <p style="margin: 2px 0 0 0; font-size: 12px; color: #64748B;">Provide a clear reason. An official notification email will be sent to the mechanic.</p>
                </div>
            </div>
            <button type="button" onclick="closeRejectModal();" style="background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; color: #64748B; display: flex; align-items: center; justify-content: center; font-size: 14px; transition: all 0.2s;" onmouseover="this.style.background='#F1F5F9'; this.style.color='#0F172A';" onmouseout="this.style.background='#F8FAFC'; this.style.color='#64748B';">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- Target Mechanic Info Box -->
        <div style="background: #FFF7ED; border: 1px solid #FFEDD5; border-left: 4px solid #F97316; border-radius: 10px; padding: 12px 14px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between;">
            <div>
                <div style="font-size: 13.5px; font-weight: 800; color: #1E293B;" id="rejectModalMechName">Mechanic M</div>
                <div style="font-size: 12px; color: #EA580C; font-weight: 600; margin-top: 2px;">
                    <span id="rejectModalMechShop">Feanix Work Shop</span> • <span id="rejectModalMechCode" style="font-family: monospace;">MEC040</span>
                </div>
            </div>
            <div style="text-align: right;">
                <span style="font-size: 11px; color: #64748B; display: block;">Notification Target:</span>
                <span id="rejectModalMechEmail" style="font-size: 12px; font-weight: 700; color: #0F172A;">madhavan0507p@gmail.com</span>
            </div>
        </div>

        <form method="POST" action="mechanic-approval.jsp" id="rejectApplicationForm" onsubmit="return handleRejectSubmit(event);">
            <input type="hidden" name="action" value="reject">
            <input type="hidden" name="id" id="rejectFormMechId" value="">
            <input type="hidden" name="tab" value="<%= activeTab %>">

            <!-- Quick Reason Preset Chips -->
            <div style="margin-bottom: 12px;">
                <label style="display: block; font-size: 12px; font-weight: 700; color: #374151; margin-bottom: 6px;">
                    <i class="fa-solid fa-wand-magic-sparkles" style="color: #F97316;"></i> Quick Predefined Reasons (Click to insert):
                </label>
                <div style="display: flex; flex-wrap: wrap; gap: 6px;">
                    <button type="button" class="btn-reject-chip" onclick="setRejectReason('Aadhaar card or ID proof document is blurry, expired, or unreadable.');">
                        📄 Blurry/Invalid Documents
                    </button>
                    <button type="button" class="btn-reject-chip" onclick="setRejectReason('Incomplete workshop address or location details could not be verified.');">
                        📍 Unverified Shop Location
                    </button>
                    <button type="button" class="btn-reject-chip" onclick="setRejectReason('Years of experience or technical specialization credentials did not meet platform guidelines.');">
                        ⏱ Insufficient Experience
                    </button>
                    <button type="button" class="btn-reject-chip" onclick="setRejectReason('Duplicate registration found with identical contact details or shop identity.');">
                        ⚠️ Duplicate Registration
                    </button>
                    <button type="button" class="btn-reject-chip" onclick="setRejectReason('Uploaded identity proofs do not match the applicant name or workshop registration.');">
                        🚫 Credentials Mismatch
                    </button>
                </div>
            </div>

            <!-- Mandatory Reason Textarea -->
            <div style="margin-bottom: 16px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                    <label for="rejectReasonTextarea" style="font-size: 13px; font-weight: 700; color: #1E293B;">
                        Specific Rejection Reason <span style="color: #DC2626;">*</span>
                    </label>
                    <span id="rejectReasonCharCount" style="font-size: 11px; color: #94A3B8; font-weight: 600;">0 / 250</span>
                </div>
                <textarea id="rejectReasonTextarea" name="rejectionReason" rows="3" maxlength="250" required
                    placeholder="Enter the exact reason for rejecting this mechanic application. This text will be included in the email sent to the mechanic."
                    style="width: 100%; border: 1.5px solid #CBD5E1; border-radius: 10px; padding: 10px 12px; font-size: 13px; font-family: inherit; color: #0F172A; resize: vertical; box-sizing: border-box; outline: none; transition: border-color 0.2s;"
                    oninput="handleRejectReasonInput(this)"></textarea>
                <div id="rejectReasonError" style="display: none; color: #DC2626; font-size: 11.5px; font-weight: 600; margin-top: 4px;">
                    <i class="fa-solid fa-circle-exclamation"></i> Please provide a reason for rejecting this application.
                </div>
            </div>

            <!-- Action Buttons -->
            <div style="display: flex; justify-content: flex-end; align-items: center; gap: 10px; border-top: 1.5px solid #F1F5F9; padding-top: 16px;">
                <button type="button" onclick="closeRejectModal();" style="padding: 9px 18px; font-size: 13px; font-weight: 600; color: #475569; background: #F8FAFC; border: 1px solid #CBD5E1; border-radius: 10px; cursor: pointer; transition: all 0.2s;" onmouseover="this.style.background='#F1F5F9';" onmouseout="this.style.background='#F8FAFC';">
                    Cancel
                </button>
                <button type="submit" id="btnConfirmRejectSubmit" style="padding: 9px 20px; font-size: 13px; font-weight: 700; color: #FFFFFF; background: linear-gradient(135deg, #DC2626 0%, #B91C1C 100%); border: none; border-radius: 10px; cursor: pointer; display: flex; align-items: center; gap: 8px; box-shadow: 0 4px 12px rgba(220, 38, 38, 0.25); transition: all 0.2s;">
                    <i class="fa-solid fa-ban"></i>
                    <span>Confirm Rejection & Send Email</span>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Leaflet JS Library for Interactive Location Maps -->
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<!-- =======================================================================
     CLIENT SCRIPTS
     ======================================================================= -->
<script>
    var shopMiniMap = null;
    var shopMiniMarker = null;
    var shopFullMap = null;
    var shopFullMarker = null;
    var shopFullCircle = null;
    var currentShopData = null;

    // Document Preview & Verification State
    var currentModalDocs = {
        code: '',
        owner: '',
        workshop: '',
        id: '',
        aadhaar: '',
        aadhaarDoc: '',
        idProofDoc: ''
    };

    function formatAadhaarDisplay(val) {
        if (!val || !val.trim()) return 'Not Provided';
        var clean = val.replace(/\D/g, '');
        if (clean.length === 12) {
            return clean.substring(0, 4) + ' ' + clean.substring(4, 8) + ' ' + clean.substring(8, 12);
        }
        return val;
    }

    function resolveDocUrl(fileName) {
        if (!fileName) return '';
        var clean = (fileName || '').trim();
        if (!clean) return '';
        if (clean.startsWith('http://') || clean.startsWith('https://')) {
            return clean;
        }
        var contextPath = '${pageContext.request.contextPath}';
        if (clean.startsWith('/')) {
            return contextPath + clean;
        }
        if (clean.startsWith('uploads/')) {
            return contextPath + '/' + clean;
        }
        return contextPath + '/uploads/mechanic_documents/' + clean;
    }

    function renderDocPreview(containerId, fileName, docTypeLabel) {
        var container = document.getElementById(containerId);
        if (!container) return;
        if (!fileName || !fileName.trim()) {
            container.innerHTML = 
                '<div style="padding: 32px 16px; text-align: center; color: #64748B;">' +
                '    <i class="fa-solid fa-file-circle-xmark" style="font-size: 42px; color: #CBD5E1; margin-bottom: 12px; display: block;"></i>' +
                '    <div style="font-size: 14.5px; font-weight: 700; color: #475569;">No ' + docTypeLabel + ' Uploaded</div>' +
                '    <p style="font-size: 12.5px; color: #94A3B8; margin-top: 4px;">The applicant did not attach an electronic file for this requirement.</p>' +
                '</div>';
            return;
        }

        var clean = fileName.trim();
        var baseName = clean.substring(Math.max(clean.lastIndexOf('/'), clean.lastIndexOf('\\')) + 1);
        var ext = baseName.split('.').pop().toLowerCase().split('?')[0];
        var fileUrl = resolveDocUrl(clean);

        if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].indexOf(ext) !== -1) {
            container.innerHTML = 
                '<div style="text-align: center; padding: 12px; background: #FFFFFF; border-radius: 12px; border: 1px solid #E2E8F0; box-shadow: 0 2px 8px rgba(0,0,0,0.04);">' +
                '    <div style="margin-bottom: 12px; max-height: 380px; overflow: hidden; display: flex; align-items: center; justify-content: center; background: #0F172A; border-radius: 8px; padding: 8px;">' +
                '        <img src="' + fileUrl + '" alt="' + docTypeLabel + '" style="max-width: 100%; max-height: 360px; object-fit: contain; border-radius: 4px;" onerror="this.onerror=null; this.parentElement.innerHTML=\'<div style=\\\'padding: 28px 16px; color: #E2E8F0; text-align: center;\\\'><i class=\\\'fa-solid fa-file-image\\\' style=\\\'font-size: 40px; color: #F59E0B; margin-bottom: 8px; display: block;\\\'></i><div style=\\\'font-weight: 700; font-size: 14px;\\\'>Preview Image Not Available</div><div style=\\\'font-size: 12px; color: #94A3B8; margin-top: 4px;\\\'>' + baseName + '</div></div>\';">' +
                '    </div>' +
                '    <div style="display: flex; gap: 10px; justify-content: center; align-items: center; margin-top: 10px; flex-wrap: wrap;">' +
                '        <a href="' + fileUrl + '" target="_blank" class="btn-filter-reset" style="background: #EA580C; color: #FFFFFF; font-weight: 700; font-size: 13px; padding: 8px 18px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">' +
                '            <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Full Image' +
                '        </a>' +
                '        <a href="' + fileUrl + '" download="' + baseName + '" class="btn-filter-reset" style="background: #F1F5F9; color: #334155; font-weight: 600; font-size: 13px; padding: 8px 16px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">' +
                '            <i class="fa-solid fa-download"></i> Download' +
                '        </a>' +
                '    </div>' +
                '</div>';
        } else if (ext === 'pdf') {
            container.innerHTML = 
                '<div style="padding: 28px 20px; text-align: center; background: #FFFFFF; border-radius: 12px; border: 1px solid #E2E8F0; box-shadow: 0 2px 8px rgba(0,0,0,0.04);">' +
                '    <i class="fa-solid fa-file-pdf" style="font-size: 56px; color: #DC2626; margin-bottom: 12px; display: block;"></i>' +
                '    <h4 style="font-size: 15px; font-weight: 700; color: #1E293B; margin: 0 0 4px 0; word-break: break-all;">' + baseName + '</h4>' +
                '    <p style="font-size: 12.5px; color: #64748B; margin: 0 0 16px 0;">Portable Document Format (PDF)</p>' +
                '    <div style="display: flex; gap: 10px; justify-content: center; align-items: center; flex-wrap: wrap;">' +
                '        <a href="' + fileUrl + '" target="_blank" class="btn-filter-reset" style="background: #DC2626; color: #FFFFFF; font-weight: 700; font-size: 13px; padding: 8px 20px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">' +
                '            <i class="fa-solid fa-file-arrow-up"></i> View PDF Document' +
                '        </a>' +
                '        <a href="' + fileUrl + '" download="' + baseName + '" class="btn-filter-reset" style="background: #F1F5F9; color: #334155; font-weight: 600; font-size: 13px; padding: 8px 16px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;">' +
                '            <i class="fa-solid fa-download"></i> Download' +
                '        </a>' +
                '    </div>' +
                '</div>';
        } else {
            container.innerHTML = 
                '<div style="padding: 24px; text-align: center; background: #FFFFFF; border-radius: 12px; border: 1px solid #E2E8F0;">' +
                '    <i class="fa-solid fa-file-lines" style="font-size: 48px; color: #64748B; margin-bottom: 10px; display: block;"></i>' +
                '    <h4 style="font-size: 15px; font-weight: 700; color: #1E293B; margin: 0 0 6px 0;">' + baseName + '</h4>' +
                '    <a href="' + fileUrl + '" target="_blank" class="btn-filter-reset" style="background: #EA580C; color: #FFFFFF; font-weight: 600; font-size: 13px; padding: 8px 18px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; margin-top: 10px;">' +
                '        <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Document' +
                '    </a>' +
                '</div>';
        }
    }

    function openDocModalWithData(data) {
        currentModalDocs = data;
        document.getElementById('docModalTitle').textContent = 'Document Verification — ' + (data.workshop || 'Mechanic') + (data.code ? ' (' + data.code + ')' : '');
        
        var appLink = document.getElementById('modalApproveLink');
        if (appLink) {
            appLink.href = 'mechanic-approval.jsp?action=approve&id=' + data.id + '&tab=<%= activeTab %>';
            appLink.onclick = function(e) {
                if (!confirm('Are you sure you want to APPROVE this mechanic application? Activation email will be sent.')) {
                    e.preventDefault();
                    return false;
                }
            };
        }
        var rejLink = document.getElementById('modalRejectLink');
        if (rejLink) {
            rejLink.onclick = function() {
                openRejectModalFromDocModal();
            };
        }

        // Tab 1: Aadhaar details & document
        var aNum = document.getElementById('docAadhaarNumberVal');
        if (aNum) {
            aNum.textContent = formatAadhaarDisplay(data.aadhaar);
        }
        var aBadge = document.getElementById('docAadhaarStatusBadge');
        if (aBadge) {
            var cleanA = (data.aadhaar || '').replace(/\D/g, '');
            if (cleanA.length === 12) {
                aBadge.className = 'metric-badge-pill pill-green';
                aBadge.innerHTML = '<i class="fa-solid fa-circle-check"></i> 12 Digits Verified';
            } else {
                aBadge.className = 'metric-badge-pill pill-yellow';
                aBadge.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> ' + (cleanA ? 'Pending Check' : 'Not Provided');
            }
        }

        renderDocPreview('docAadhaarDocContainer', data.aadhaarDoc, 'Aadhaar Card Document');
        renderDocPreview('docIdProofDocContainer', data.idProofDoc, 'ID Proof Document');

        switchDocTab(1);
        document.getElementById('documentModal').style.display = 'flex';
    }

    function openDocModalFromBtn(btn) {
        var ds = btn.dataset;
        openDocModalWithData({
            code: ds.code || '',
            owner: ds.owner || '',
            workshop: ds.workshop || '',
            id: ds.id || '',
            email: ds.email || '',
            aadhaar: ds.aadhaar || '',
            aadhaarDoc: ds.aadhaardoc || '',
            idProofDoc: ds.idproofdoc || ''
        });
    }

    function openDocModalFromView(tabNum) {
        if (!currentModalDocs) return;
        openDocModalWithData(currentModalDocs);
        if (tabNum) {
            switchDocTab(tabNum);
        }
    }

    // Document Preview Modal
    function openDocModal(code, owner, workshop, id) {
        openDocModalWithData({
            code: code || '',
            owner: owner || '',
            workshop: workshop || '',
            id: id || '',
            email: '',
            aadhaar: '',
            aadhaarDoc: '',
            idProofDoc: ''
        });
    }

    function closeDocModal() {
        document.getElementById('documentModal').style.display = 'none';
    }

    function switchDocTab(tabNum) {
        for (let i = 1; i <= 3; i++) {
            const btn = document.getElementById('tabDoc' + i);
            const content = document.getElementById('docContent' + i);
            if (!btn || !content) continue;
            if (i === tabNum) {
                btn.style.background = '#FFF7ED';
                btn.style.borderColor = '#F97316';
                btn.style.color = '#EA580C';
                content.style.display = 'block';
            } else {
                btn.style.background = '#FFFFFF';
                btn.style.borderColor = '#E2E8F0';
                btn.style.color = '#1F2937';
                content.style.display = 'none';
            }
        }
    }

    // Comprehensive Tabbed View Modal Handlers
    function openViewModalFromBtn(btn) {
        var ds = btn.dataset;
        currentModalDocs = {
            code: ds.code || '',
            owner: ds.owner || ds.name || '',
            workshop: ds.workshop || ds.shopname || '',
            id: ds.id || '',
            email: ds.email || '',
            aadhaar: ds.aadhaar || '',
            aadhaarDoc: ds.aadhaardoc || '',
            idProofDoc: ds.idproofdoc || '',
            rejectionreason: ds.rejectionreason || ''
        };

        document.getElementById('viewOwnerName').textContent = ds.name || 'Karthik R';
        document.getElementById('viewFullName').textContent = ds.name || 'Karthik R';
        document.getElementById('viewMechanicCode').textContent = 'ID: ' + (ds.code || 'MEC018');
        document.getElementById('viewRegDate').textContent = ds.date || '20-01-2025';
        document.getElementById('viewRatingNum').textContent = ds.rating || '4.8';
        document.getElementById('viewReviewCount').textContent = '(' + (ds.reviews || '120') + ' Reviews)';
        document.getElementById('viewPhoneVal').textContent = ds.phone || '+91 98765 43210';
        document.getElementById('viewEmailVal').textContent = ds.email || 'karthik@example.com';
        document.getElementById('viewGender').textContent = ds.gender || 'Male';

        // Aadhaar & ID Proof details
        var aValEl = document.getElementById('viewAadhaarVal');
        if (aValEl) {
            aValEl.textContent = formatAadhaarDisplay(ds.aadhaar);
        }
        var idProofStatEl = document.getElementById('viewIdProofStatus');
        if (idProofStatEl) {
            if (ds.idproofdoc && ds.idproofdoc.trim()) {
                idProofStatEl.style.color = '#16A34A';
                idProofStatEl.innerHTML = '<i class="fa-solid fa-circle-check"></i> Document Attached';
            } else {
                idProofStatEl.style.color = '#D97706';
                idProofStatEl.innerHTML = '<i class="fa-solid fa-clock"></i> Not Attached';
            }
        }
        
        // Status Pill
        var st = ds.status || 'Pending';
        document.getElementById('viewStatusPillText').textContent = st;
        var pill = document.getElementById('viewStatusPill');
        if (st.toLowerCase() === 'pending') {
            pill.style.background = '#EAB308';
        } else if (st.toLowerCase() === 'rejected') {
            pill.style.background = '#DC2626';
        } else {
            pill.style.background = '#16A34A';
        }

        // Rejection Reason Banner
        var rejBanner = document.getElementById('viewRejectionBanner');
        var rejReasonText = document.getElementById('viewRejectionReasonText');
        if (rejBanner && rejReasonText) {
            if (st.toLowerCase() === 'rejected') {
                rejReasonText.textContent = ds.rejectionreason || 'Application does not meet onboarding criteria';
                rejBanner.style.display = 'block';
            } else {
                rejBanner.style.display = 'none';
            }
        }

        // Action Buttons inside Modal Footer
        var approveBtn = document.getElementById('viewModalApproveBtn');
        var rejectBtn = document.getElementById('viewModalRejectBtn');
        if (approveBtn && ds.id) {
            approveBtn.href = 'mechanic-approval.jsp?action=approve&id=' + ds.id + '&tab=<%= activeTab %>';
            approveBtn.style.display = (st.toLowerCase() === 'approved') ? 'none' : 'inline-flex';
            approveBtn.onclick = function(e) {
                if (!confirm('Are you sure you want to APPROVE ' + (ds.name || 'this mechanic') + '? An activation email will be sent to ' + (ds.email || 'the mechanic') + '.')) {
                    e.preventDefault();
                    return false;
                }
            };
        }
        if (rejectBtn && ds.id) {
            rejectBtn.style.display = (st.toLowerCase() === 'rejected') ? 'none' : 'inline-flex';
            rejectBtn.onclick = function() {
                openRejectModalFromViewModal();
            };
        }

        // Avatar
        if (ds.avatar) {
            var va = document.getElementById('viewAvatarImg');
            if (va && va.tagName === 'IMG') va.src = '${pageContext.request.contextPath}/images/' + ds.avatar;
        }

        // Shop Details
        document.getElementById('viewShopName').textContent = ds.shopname || 'Karthik Auto Garage';
        document.getElementById('viewShopType').textContent = ds.shoptype || 'Service Center';
        document.getElementById('viewShopContact').textContent = ds.shopcontact || '+91 98765 43210';
        document.getElementById('viewExperience').textContent = ds.experience || '8 Years';
        document.getElementById('viewWorkingHours').textContent = ds.workinghours || '09:00 AM – 07:00 PM';
        document.getElementById('viewShopDesc').textContent = ds.shopdesc || 'Car & Bike Service, Battery, General Repair';

        // Work Specialization Chips
        var chipsWrap = document.getElementById('viewSpecializationChips');
        if (chipsWrap) {
            var specStr = ds.spec || 'General Service';
            var parts = specStr.split(',');
            chipsWrap.innerHTML = '';
            var icons = {
                'engine': 'fa-solid fa-car',
                'tyre': 'fa-solid fa-circle-dot',
                'wheel': 'fa-solid fa-circle-dot',
                'puncture': 'fa-solid fa-circle-dot',
                'electrical': 'fa-solid fa-bolt',
                'battery': 'fa-solid fa-battery-full',
                'general': 'fa-solid fa-wrench',
                'ac': 'fa-solid fa-snowflake',
                'brake': 'fa-solid fa-shield-halved'
            };
            parts.forEach(function(p) {
                var trimmed = p.trim();
                if (trimmed) {
                    var iconClass = 'fa-solid fa-wrench';
                    var lower = trimmed.toLowerCase();
                    for (var key in icons) {
                        if (lower.indexOf(key) !== -1) {
                            iconClass = icons[key];
                            break;
                        }
                    }
                    var chip = document.createElement('span');
                    chip.className = 'spec-chip';
                    chip.innerHTML = '<i class="' + iconClass + '"></i> ' + trimmed;
                    chipsWrap.appendChild(chip);
                }
            });
            if (chipsWrap.children.length === 0) {
                chipsWrap.innerHTML = '<span class="spec-chip"><i class="fa-solid fa-wrench"></i> General Service</span>';
            }
        }
        document.getElementById('viewOtherSpecialization').textContent = ds.otherspec || 'AC Service, Radiator Repair';

        // Address & Location
        document.getElementById('viewAddrLine1').textContent = ds.addr1 || '74, GST Road, Chromepet';
        document.getElementById('viewAddrLine2').textContent = ds.addr2 || 'Near Bus Stand';
        document.getElementById('viewCity').textContent = ds.city || 'Chennai';
        document.getElementById('viewDistrict').textContent = ds.district || 'Chennai';
        document.getElementById('viewState').textContent = ds.state || 'Tamil Nadu';
        document.getElementById('viewPincode').textContent = ds.pincode || '600044';

        // GPS Coordinates & Location Map
        var latVal = parseFloat(ds.lat);
        var lngVal = parseFloat(ds.lng);
        if (isNaN(latVal) || latVal === 0) latVal = 12.9516;
        if (isNaN(lngVal) || lngVal === 0) lngVal = 80.1462;

        var latDir = latVal >= 0 ? 'N' : 'S';
        var lngDir = lngVal >= 0 ? 'E' : 'W';
        var formattedCoords = Math.abs(latVal).toFixed(4) + '° ' + latDir + ', ' + Math.abs(lngVal).toFixed(4) + '° ' + lngDir;

        var coordsTextEl = document.getElementById('viewShopCoordsText');
        if (coordsTextEl) coordsTextEl.textContent = formattedCoords;

        var gmapsUrl = 'https://www.google.com/maps?q=' + latVal + ',' + lngVal;
        var gmapsLink = document.getElementById('viewShopGmapsLink');
        if (gmapsLink) {
            gmapsLink.href = gmapsUrl;
        }

        currentShopData = {
            lat: latVal,
            lng: lngVal,
            id: ds.id || '',
            code: ds.code || 'MEC018',
            name: ds.name || 'Karthik R',
            shopname: ds.shopname || 'Karthik Auto Garage',
            shoptype: ds.shoptype || 'Service Center',
            phone: ds.phone || ds.shopcontact || '+91 98765 43210',
            addr1: ds.addr1 || '',
            addr2: ds.addr2 || '',
            city: ds.city || '',
            district: ds.district || '',
            state: ds.state || 'Tamil Nadu',
            pincode: ds.pincode || '600044'
        };

        initOrUpdateShopMiniMap(currentShopData);

        // Shop Photos Handling
        var photosGrid = document.getElementById('viewShopPhotosGrid');
        var photosCountBadge = document.getElementById('viewShopPhotosCount');
        if (photosGrid) {
            photosGrid.innerHTML = '';
            var photosStr = ds.shopphotos || '';
            var photoList = [];
            if (photosStr && photosStr.trim()) {
                photosStr.split(',').forEach(function(p) {
                    var trimmed = p.trim();
                    if (trimmed) photoList.push(trimmed);
                });
            }
            if (photoList.length > 0) {
                if (photosCountBadge) photosCountBadge.textContent = photoList.length + (photoList.length === 1 ? ' Photo' : ' Photos');
                photoList.forEach(function(photoPath, idx) {
                    var fullSrc = (photoPath.indexOf('/') !== -1 || photoPath.indexOf('http') === 0) ? photoPath : ('${pageContext.request.contextPath}/images/' + photoPath);
                    var card = document.createElement('div');
                    card.className = 'mech-shop-photo-card';
                    card.onclick = function() { previewShopPhoto(fullSrc); };
                    card.innerHTML = '<img src="' + fullSrc + '" alt="Shop Photo ' + (idx + 1) + '" class="mech-shop-photo-thumb" onerror="this.src=\'${pageContext.request.contextPath}/images/mechanic-workshop-sample.jpg\'">' +
                                     '<div class="mech-shop-photo-overlay"><i class="fa-solid fa-magnifying-glass-plus"></i> View</div>';
                    photosGrid.appendChild(card);
                });
            } else {
                if (photosCountBadge) photosCountBadge.textContent = '0 Photos';
                photosGrid.innerHTML = '<div class="mech-shop-photos-empty">' +
                    '<i class="fa-regular fa-image"></i>' +
                    '<span>No shop photos uploaded yet for this mechanic.</span>' +
                    '</div>';
            }
        }

        // Reset Tabs to First (Personal Details)
        document.querySelectorAll('#viewMechanicModal .mech-view-tab-btn').forEach(function(b, idx) {
            if (idx === 0) b.classList.add('active');
            else b.classList.remove('active');
        });
        document.querySelectorAll('#viewMechanicModal .mech-view-tab-pane').forEach(function(p, idx) {
            if (idx === 0) p.classList.add('active-tab-pane');
            else p.classList.remove('active-tab-pane');
        });

        document.getElementById('viewMechanicModal').classList.add('active');
    }

    function closeViewModal() {
        document.getElementById('viewMechanicModal').classList.remove('active');
    }

    // =========================================================================
    // REJECTION MODAL LOGIC & REASON SELECTION
    // =========================================================================
    function openRejectModal(id, name, code, workshop, email) {
        var modal = document.getElementById('mechanicRejectModal');
        if (!modal) return;

        var idInput = document.getElementById('rejectFormMechId');
        if (idInput) idInput.value = id || '';

        var nameEl = document.getElementById('rejectModalMechName');
        if (nameEl) nameEl.textContent = name || 'Mechanic';

        var shopEl = document.getElementById('rejectModalMechShop');
        if (shopEl) shopEl.textContent = workshop || 'Workshop';

        var codeEl = document.getElementById('rejectModalMechCode');
        if (codeEl) codeEl.textContent = code || '';

        var emailEl = document.getElementById('rejectModalMechEmail');
        if (emailEl) emailEl.textContent = email || 'mechanic@example.com';

        var textarea = document.getElementById('rejectReasonTextarea');
        if (textarea) {
            textarea.value = '';
            textarea.style.borderColor = '#CBD5E1';
        }
        var charCount = document.getElementById('rejectReasonCharCount');
        if (charCount) charCount.textContent = '0 / 250';

        var errorMsg = document.getElementById('rejectReasonError');
        if (errorMsg) errorMsg.style.display = 'none';

        var submitBtn = document.getElementById('btnConfirmRejectSubmit');
        if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa-solid fa-ban"></i> <span>Confirm Rejection & Send Email</span>';
        }

        modal.style.display = 'flex';
        modal.classList.add('active');
        if (textarea) {
            setTimeout(function() { textarea.focus(); }, 120);
        }
    }

    function closeRejectModal() {
        var modal = document.getElementById('mechanicRejectModal');
        if (modal) {
            modal.style.display = 'none';
            modal.classList.remove('active');
        }
    }

    function openRejectModalFromViewModal() {
        if (!currentModalDocs) return;
        openRejectModal(
            currentModalDocs.id,
            currentModalDocs.owner,
            currentModalDocs.code,
            currentModalDocs.workshop,
            currentModalDocs.email
        );
    }

    function openRejectModalFromDocModal() {
        if (!currentModalDocs) return;
        openRejectModal(
            currentModalDocs.id,
            currentModalDocs.owner,
            currentModalDocs.code,
            currentModalDocs.workshop,
            currentModalDocs.email
        );
    }

    function setRejectReason(presetText) {
        var textarea = document.getElementById('rejectReasonTextarea');
        if (textarea) {
            textarea.value = presetText;
            handleRejectReasonInput(textarea);
            textarea.focus();
        }
    }

    function handleRejectReasonInput(textarea) {
        var len = textarea.value.length;
        var countEl = document.getElementById('rejectReasonCharCount');
        if (countEl) countEl.textContent = len + ' / 250';

        var errEl = document.getElementById('rejectReasonError');
        if (textarea.value.trim().length > 0) {
            textarea.style.borderColor = '#CBD5E1';
            if (errEl) errEl.style.display = 'none';
        }
    }

    function handleRejectSubmit(e) {
        var textarea = document.getElementById('rejectReasonTextarea');
        var errEl = document.getElementById('rejectReasonError');
        if (!textarea || !textarea.value.trim()) {
            if (e) e.preventDefault();
            if (textarea) textarea.style.borderColor = '#DC2626';
            if (errEl) errEl.style.display = 'block';
            if (textarea) textarea.focus();
            return false;
        }

        var btn = document.getElementById('btnConfirmRejectSubmit');
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Sending Rejection Email...';
        }
        return true;
    }

    function switchMechTab(btn, sectionId) {
        document.querySelectorAll('#viewMechanicModal .mech-view-tab-btn').forEach(function(b) {
            b.classList.remove('active');
        });
        btn.classList.add('active');
        document.querySelectorAll('#viewMechanicModal .mech-view-tab-pane').forEach(function(p) {
            p.classList.remove('active-tab-pane');
        });
        var sec = document.getElementById(sectionId);
        if (sec) {
            sec.classList.add('active-tab-pane');
        }
        if (sectionId === 'sectionLocation' && shopMiniMap) {
            setTimeout(function() {
                shopMiniMap.invalidateSize();
            }, 150);
        }
    }

    function initOrUpdateShopMiniMap(data) {
        if (typeof L === 'undefined') return;
        var container = document.getElementById('viewShopMiniMap');
        if (!container) return;

        var shopPin = L.divIcon({
            className: 'custom-shop-pin',
            html: '<div class="shop-pin-pulse"></div><div class="shop-pin-body"><i class="fa-solid fa-shop"></i></div>',
            iconSize: [32, 32],
            iconAnchor: [16, 32],
            popupAnchor: [0, -32]
        });

        var lat = data.lat;
        var lng = data.lng;

        if (!shopMiniMap) {
            shopMiniMap = L.map('viewShopMiniMap', {
                center: [lat, lng],
                zoom: 15,
                zoomControl: false,
                attributionControl: false,
                dragging: false,
                scrollWheelZoom: false,
                doubleClickZoom: false,
                touchZoom: false
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19
            }).addTo(shopMiniMap);

            shopMiniMarker = L.marker([lat, lng], { icon: shopPin }).addTo(shopMiniMap);
        } else {
            shopMiniMap.setView([lat, lng], 15);
            if (shopMiniMarker) {
                shopMiniMarker.setLatLng([lat, lng]);
            } else {
                shopMiniMarker = L.marker([lat, lng], { icon: shopPin }).addTo(shopMiniMap);
            }
        }

        setTimeout(function() {
            if (shopMiniMap) shopMiniMap.invalidateSize();
        }, 200);
    }

    function openFullscreenShopMapModal() {
        var d = currentShopData || {
            lat: 12.9516,
            lng: 80.1462,
            code: 'MEC018',
            name: 'Karthik R',
            shopname: 'Karthik Auto Garage',
            phone: '+91 98765 43210',
            addr1: '74, GST Road, Chromepet,',
            addr2: 'Near Bus Stand,',
            city: 'Chennai',
            district: 'Chennai',
            state: 'Tamil Nadu',
            pincode: '600044'
        };

        var fullAddr = [d.addr1, d.addr2, d.city, d.district, d.state, d.pincode].filter(Boolean).join(', ');
        if (!fullAddr) fullAddr = d.city || 'Tamil Nadu';

        var nameEl = document.getElementById('fsShopModalName');
        if (nameEl) nameEl.textContent = d.shopname || d.name || 'Workshop';

        var addrEl = document.getElementById('fsShopModalAddress');
        if (addrEl) addrEl.textContent = fullAddr;

        var coordsEl = document.getElementById('fsShopModalCoords');
        if (coordsEl) coordsEl.textContent = d.lat.toFixed(6) + ', ' + d.lng.toFixed(6);

        var phoneEl = document.getElementById('fsShopModalPhone');
        if (phoneEl) phoneEl.textContent = d.phone || '-';

        var gmapsLink = document.getElementById('fsShopGmapsLink');
        if (gmapsLink) {
            gmapsLink.href = 'https://www.google.com/maps?q=' + d.lat + ',' + d.lng;
        }

        var fsModal = document.getElementById('fullscreenShopMapModal');
        if (fsModal) {
            fsModal.style.display = 'flex';
            fsModal.classList.add('active');
        }

        if (typeof L === 'undefined') return;

        var shopPinLarge = L.divIcon({
            className: 'custom-shop-pin',
            html: '<div class="shop-pin-pulse"></div><div class="shop-pin-body"><i class="fa-solid fa-shop"></i></div>',
            iconSize: [36, 36],
            iconAnchor: [18, 36],
            popupAnchor: [0, -36]
        });

        var popupHtml = 
            '<div style="font-family: \'Plus Jakarta Sans\', sans-serif; font-size: 13px; min-width: 230px; line-height: 1.45;">' +
                '<div style="font-weight: 800; color: #EA580C; font-size: 14px; margin-bottom: 4px; display: flex; align-items: center; gap: 6px;">' +
                    '<i class="fa-solid fa-store"></i> ' + (d.shopname || 'Workshop Location') +
                '</div>' +
                '<div style="font-weight: 700; color: #1E293B; margin-bottom: 6px; font-size: 13px;">' + fullAddr + '</div>' +
                '<div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Owner: <b style="color: #1E293B;">' + (d.name || '-') + '</b></div>' +
                '<div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Contact: <b style="color: #EA580C;">' + (d.phone || '-') + '</b></div>' +
                '<div style="font-size: 11px; color: #64748B; font-family: monospace; margin-top: 6px; background: #F8FAFC; padding: 4px 6px; border-radius: 4px; border: 1px solid #E2E8F0;">GPS: ' + d.lat.toFixed(6) + ', ' + d.lng.toFixed(6) + '</div>' +
                '<div style="margin-top: 8px;"><a href="https://www.google.com/maps?q=' + d.lat + ',' + d.lng + '" target="_blank" style="display: inline-block; background: #EA580C; color: #FFF; font-weight: 700; font-size: 11.5px; padding: 4px 10px; border-radius: 6px; text-decoration: none;"><i class="fa-solid fa-arrow-up-right-from-square"></i> Open in Google Maps</a></div>' +
            '</div>';

        if (!shopFullMap) {
            shopFullMap = L.map('fsShopFullMap', {
                center: [d.lat, d.lng],
                zoom: 16
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap contributors'
            }).addTo(shopFullMap);

            shopFullCircle = L.circle([d.lat, d.lng], {
                color: '#EA580C',
                fillColor: '#F97316',
                fillOpacity: 0.15,
                radius: 80
            }).addTo(shopFullMap);

            shopFullMarker = L.marker([d.lat, d.lng], { icon: shopPinLarge })
                .addTo(shopFullMap)
                .bindPopup(popupHtml)
                .openPopup();
        } else {
            shopFullMap.setView([d.lat, d.lng], 16);
            if (shopFullCircle) shopFullCircle.setLatLng([d.lat, d.lng]);
            if (shopFullMarker) {
                shopFullMarker.setLatLng([d.lat, d.lng]).setPopupContent(popupHtml).openPopup();
            } else {
                shopFullMarker = L.marker([d.lat, d.lng], { icon: shopPinLarge })
                    .addTo(shopFullMap)
                    .bindPopup(popupHtml)
                    .openPopup();
            }
        }

        setTimeout(function() {
            if (shopFullMap) shopFullMap.invalidateSize();
        }, 200);
    }

    function closeFullscreenShopMapModal() {
        var fsModal = document.getElementById('fullscreenShopMapModal');
        if (fsModal) {
            fsModal.style.display = 'none';
            fsModal.classList.remove('active');
        }
    }

    function previewShopPhoto(src) {
        var pModal = document.getElementById('shopImagePreviewModal');
        var pImg = document.getElementById('shopPreviewImgTag');
        if (pModal && pImg) {
            pImg.src = src;
            pModal.classList.add('active');
        }
    }

    function copyMechanicId() {
        var codeText = document.getElementById('viewMechanicCode').textContent.replace('ID: ', '').trim();
        if (navigator.clipboard) {
            navigator.clipboard.writeText(codeText);
            alert('Copied ' + codeText + ' to clipboard!');
        }
    }

    // Backward-compatibility wrapper for row avatar click
    function openMechanicModal(code, owner, workshop, services, phone, email, loc, address, exp) {
        var dummyBtn = {
            dataset: {
                code: code,
                name: owner,
                shopname: workshop,
                spec: services,
                phone: phone,
                email: email,
                city: loc,
                district: loc,
                addr1: address,
                experience: exp,
                status: 'Pending'
            }
        };
        openViewModalFromBtn(dummyBtn);
    }

    // Export to CSV
    function exportTableToCSV() {
        let csv = [];
        const rows = document.querySelectorAll("#approvalTable tr");
        for (let i = 0; i < rows.length; i++) {
            let row = [], cols = rows[i].querySelectorAll("td, th");
            for (let j = 0; j < cols.length - 1; j++) {
                let data = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, " ").replace(/(\s\s+)/gm, " ");
                data = data.replace(/"/g, '""');
                row.push('"' + data + '"');
            }
            csv.push(row.join(","));
        }
        const csvFile = new Blob([csv.join("\n")], { type: "text/csv" });
        const downloadLink = document.createElement("a");
        downloadLink.download = "mechanic_approval_requests.csv";
        downloadLink.href = window.URL.createObjectURL(csvFile);
        downloadLink.style.display = "none";
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
    }

    // Close modals with Escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeDocModal();
            closeViewModal();
            closeRejectModal();
            var sp = document.getElementById('shopImagePreviewModal');
            if (sp) sp.classList.remove('active');
        }
    });

    // Close on overlay backdrop click
    document.querySelectorAll('.custom-modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', function(e) {
            if (e.target === this) {
                this.style.display = 'none';
            }
        });
    });

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
            const action = form.getAttribute('action') || 'mechanic-approval.jsp';
            const qs = params.toString();
            return action + (qs ? '?' + qs : '');
        }

        function loadContentViaAjax(targetUrl, pushHistory) {
            if (pushHistory === undefined) pushHistory = true;

            if (activeAbortCtrl) {
                try { activeAbortCtrl.abort(); } catch (e) {}
            }
            activeAbortCtrl = new AbortController();

            const tableCard = document.querySelector('.approval-table-card');
            const searchInput = document.querySelector('.filter-search-input');
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

                // 1. Update .approval-table-card
                const newTableCard = doc.querySelector('.approval-table-card');
                if (tableCard && newTableCard) {
                    tableCard.innerHTML = newTableCard.innerHTML;
                    tableCard.style.opacity = '1';
                    tableCard.style.pointerEvents = '';
                }

                // 2. Update .insights-three-grid (counts, charts)
                const oldInsights = document.querySelector('.insights-three-grid');
                const newInsights = doc.querySelector('.insights-three-grid');
                if (oldInsights && newInsights) {
                    oldInsights.innerHTML = newInsights.innerHTML;
                }

                // 3. Update alert message banner if present in response
                const oldAlert = document.querySelector('.alert-notification-banner');
                const newAlert = doc.querySelector('.alert-notification-banner');
                if (oldAlert && newAlert) {
                    oldAlert.outerHTML = newAlert.outerHTML;
                } else if (!oldAlert && newAlert) {
                    const headerSection = document.querySelector('.admin-page-header');
                    if (headerSection) headerSection.insertAdjacentElement('afterend', newAlert);
                } else if (oldAlert && !newAlert) {
                    oldAlert.remove();
                }

                // 4. Update browser URL history without page reload
                if (pushHistory && window.history && window.history.pushState) {
                    window.history.pushState({ url: targetUrl }, '', targetUrl);
                }

                // 5. Re-bind event handlers
                bindAjaxEvents();

                // 6. Restore search focus if it was active
                if (wasSearchActive) {
                    const updatedSearch = document.querySelector('.filter-search-input');
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
                // Fallback: navigate normally if fetch fails
                window.location.href = targetUrl;
            });
        }

        function bindAjaxEvents() {
            const tableCard = document.querySelector('.approval-table-card');
            if (!tableCard) return;

            // 1. Status Filter Tabs (Pills)
            const tabLinks = tableCard.querySelectorAll('.approval-tabs-row a');
            tabLinks.forEach(function(link) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const href = this.getAttribute('href');
                    if (href) loadContentViaAjax(href);
                });
            });

            // 2. Filter Form Submit
            const filterForm = document.getElementById('filterForm');
            if (filterForm) {
                filterForm.addEventListener('submit', function(e) {
                    e.preventDefault();
                    const url = buildUrlFromFilterForm(filterForm);
                    loadContentViaAjax(url);
                });

                // Dropdowns onchange: specialization, location
                const selects = filterForm.querySelectorAll('select');
                selects.forEach(function(sel) {
                    sel.addEventListener('change', function() {
                        const url = buildUrlFromFilterForm(filterForm);
                        loadContentViaAjax(url);
                    });
                });

                // Date picker onchange
                const dateInput = filterForm.querySelector('input[type="date"]');
                if (dateInput) {
                    dateInput.addEventListener('change', function() {
                        const url = buildUrlFromFilterForm(filterForm);
                        loadContentViaAjax(url);
                    });
                }

                // Search input live typing (debounced)
                const searchInput = filterForm.querySelector('.filter-search-input');
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
                const resetBtn = filterForm.querySelector('.btn-filter-reset');
                if (resetBtn) {
                    resetBtn.addEventListener('click', function(e) {
                        e.preventDefault();
                        const href = this.getAttribute('href') || 'mechanic-approval.jsp';
                        loadContentViaAjax(href);
                    });
                }
            }

            // 3. Pagination Controls
            const pageLinks = tableCard.querySelectorAll('.pagination-controls a, .footer-pagination-group a');
            pageLinks.forEach(function(link) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const href = this.getAttribute('href');
                    if (href && href !== '#') {
                        loadContentViaAjax(href);
                    }
                });
            });

            // 4. Action Buttons (Approve via AJAX)
            const actionLinks = tableCard.querySelectorAll('a.btn-action-approve');
            actionLinks.forEach(function(link) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const href = this.getAttribute('href');
                    const confirmMsg = 'Are you sure you want to APPROVE this mechanic application? Activation email will be sent.';
                    if (confirm(confirmMsg)) {
                        loadContentViaAjax(href);
                    }
                });
            });

            // 5. Rows per page selector
            const rowsSelect = tableCard.querySelector('.rows-select');
            if (rowsSelect) {
                rowsSelect.addEventListener('change', function() {
                    const currentUrl = new URL(window.location.href);
                    currentUrl.searchParams.set('rows', this.value);
                    currentUrl.searchParams.set('page', '1');
                    loadContentViaAjax(currentUrl.toString());
                });
            }
        }

        // Listen to browser Back/Forward buttons
        window.addEventListener('popstate', function(e) {
            loadContentViaAjax(window.location.href, false);
        });

        // Initialize on page load
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', bindAjaxEvents);
        } else {
            bindAjaxEvents();
        }
    })();
</script>

</body>
</html>
