<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String activePage = (String) request.getAttribute("activePage");
    if (activePage == null || activePage.trim().isEmpty()) {
        String uri = request.getRequestURI();
        if (uri.contains("user-management")) activePage = "users";
        else if (uri.contains("mechanic-management")) activePage = "mechanics";
        else if (uri.contains("mechanic-approval")) activePage = "approval";
        else if (uri.contains("blocked-mechanics")) activePage = "blocked";
        else if (uri.contains("service-requests")) activePage = "requests";
        else if (uri.contains("reports")) activePage = "reports";
        else activePage = "dashboard";
    }
%>

<%
    int sidePendingApproval = 0;
    try {
        java.sql.Connection connSide = com.roadassistance.util.DBConnection.getConnection();
        if (connSide != null) {
            java.sql.Statement stSide = connSide.createStatement();
            java.sql.ResultSet rsSide = stSide.executeQuery("SELECT COUNT(*) FROM mechanics WHERE approval_status = 'Pending'");
            if (rsSide.next()) sidePendingApproval = rsSide.getInt(1);
            rsSide.close();
            stSide.close();
            connSide.close();
        }
    } catch(Exception ignored) {}
%>
<!-- Sidebar Navigation -->
<aside class="sidebar" id="adminSidebar" style="width: 260px; min-width: 260px; max-width: 260px; flex: 0 0 260px;">
    <!-- Branding -->
    <div class="sidebar-branding">
        <div class="brand-icon">
            <i class="fa-solid fa-car-burst"></i>
        </div>
        <div class="brand-details">
            <span class="brand-title">On Road Vehicle<br>Breakdown Assistance</span>
        </div>
        <button type="button" class="sidebar-close-btn" id="adminSidebarCloseBtn" aria-label="Close sidebar">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>

    <!-- Section Heading -->
    <div class="sidebar-heading">ADMIN PANEL</div>

    <!-- Navigation Menu Items -->
    <ul class="sidebar-nav">
        <!-- 1. Dashboard -->
        <li class="nav-item <%= "dashboard".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-link">
                <i class="fa-solid fa-house"></i>
                <span>Dashboard</span>
            </a>
        </li>

        <!-- 2. User Management -->
        <li class="nav-item <%= "users".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/user-management.jsp" class="nav-link">
                <i class="fa-solid fa-users"></i>
                <span>User Management</span>  
            </a>
        </li>

        <!-- 3. Mechanic Management -->
        <li class="nav-item <%= "mechanics".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/mechanic-management.jsp" class="nav-link">
                <i class="fa-solid fa-wrench"></i>
                <span>Mechanic Management</span>
            </a>
        </li>

        <!-- 4. Mechanic Approval -->
        <li class="nav-item <%= "approval".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/mechanic-approval.jsp" class="nav-link" style="justify-content: space-between;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <i class="fa-solid fa-shield-halved"></i>
                    <span>Mechanic Approval</span>
                </div>
                <% if (sidePendingApproval > 0) { %>
                <span class="sidebar-badge" style="background: #F97316; color: #FFFFFF; font-size: 11px; font-weight: 700; padding: 2px 7px; border-radius: 10px; margin-left: auto;"><%= sidePendingApproval %></span>
                <% } %>
            </a>
        </li>

        <!-- 5. Blocked Mechanics -->
        <li class="nav-item <%= "blocked".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/blocked-mechanics.jsp" class="nav-link">
                <i class="fa-solid fa-ban"></i>
                <span>Blocked Mechanics</span>
            </a>
        </li>

        <!-- 6. Service Requests -->
        <li class="nav-item <%= "requests".equals(activePage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/admin/service-requests.jsp" class="nav-link">
                <i class="fa-solid fa-clipboard-list"></i>
                <span>Service Requests</span>
            </a>
        </li>
   
    </ul>

    <!-- Sidebar Bottom Container (Tow Truck Photo & Logout Pinned to Bottom without scroll) -->
    <div class="sidebar-bottom-container">
        <!-- Roadside Breakdown Illustration matching Reference Screenshot -->
        <div class="sidebar-bottom-image-box">
            <img src="${pageContext.request.contextPath}/images/sidebar-tow-truck.jpg?v=2.0" alt="Roadside Breakdown Assistance">
        </div>

        <!-- Logout Action Button at the very bottom of Sidebar (No confirm alert, direct logout) -->
        <a href="${pageContext.request.contextPath}/admin/logout.jsp" class="sidebar-logout-btn" title="Sign out of Admin Panel">
            <i class="fa-solid fa-arrow-right-from-bracket"></i>
            <span>Logout</span>
        </a>
    </div>
</aside>

<!-- Backdrop overlay for mobile drawer -->
<div class="sidebar-backdrop" id="sidebarBackdrop"></div>
