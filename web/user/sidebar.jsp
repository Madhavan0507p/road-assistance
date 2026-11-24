<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String activeUserPage = (String) request.getAttribute("activeUserPage");
    if (activeUserPage == null || activeUserPage.trim().isEmpty()) {
        String uri = request.getRequestURI();
        if (uri.contains("request-assistance") || uri.contains("find-mechanic")) activeUserPage = "find";
        else if (uri.contains("my-requests") || uri.contains("service-requests")) activeUserPage = "my-requests";
        else if (uri.contains("vehicles") || uri.contains("add-vehicle")) activeUserPage = "vehicles";
        else if (uri.contains("service-history")) activeUserPage = "history";
        else if (uri.contains("profile") || uri.contains("settings")) activeUserPage = "profile";
        else activeUserPage = "dashboard";
    } else if ("request".equals(activeUserPage)) {
        activeUserPage = "find";
    }
%>

<aside class="user-sidebar" id="userSidebar" style="width: 260px; min-width: 260px; max-width: 260px; flex: 0 0 260px;">
    <!-- Mobile Sidebar Header with Close Button -->
    <div class="sidebar-branding mobile-drawer-header">
        <div style="display: flex; align-items: center; gap: 10px;">
            <div style="width: 34px; height: 34px; border-radius: 8px; background: #F97316; display: flex; align-items: center; justify-content: center; color: #FFF; font-size: 15px;">
                <i class="fa-solid fa-car-burst"></i>
            </div>
            <span style="font-weight: 700; font-size: 13px; color: #FFF; line-height: 1.2;">Roadside<br><span style="color: #F97316;">Assistance</span></span>
        </div>
        <button type="button" class="sidebar-close-btn" id="userSidebarCloseBtn" aria-label="Close navigation">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>

    <!-- Sidebar Navigation Menu (6 Items matching reference design - Request Assistance moved into Find Mechanics flow) -->
    <ul class="user-sidebar-menu">
        <!-- 1. Dashboard -->
        <li class="sidebar-item <%= "dashboard".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="sidebar-link">
                <i class="fa-solid fa-house"></i>
                <span>Dashboard</span>
            </a>
        </li>

        <!-- 2. My Requests -->
        <li class="sidebar-item <%= "my-requests".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/my-requests.jsp" class="sidebar-link">
                <i class="fa-solid fa-clipboard-list"></i>
                <span>My Requests</span>
            </a>
        </li>

        <!-- 3. My Vehicles -->
        <li class="sidebar-item <%= "vehicles".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/vehicles.jsp" class="sidebar-link">
                <i class="fa-solid fa-car"></i>
                <span>My Vehicles</span>
            </a>
        </li>

        <!-- 4. Find Mechanics -->
        <li class="sidebar-item <%= "find".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/find-mechanic.jsp" class="sidebar-link">
                <i class="fa-solid fa-location-dot"></i>
                <span>Find Mechanics</span>
            </a>
        </li>

        <!-- 5. Service History -->
        <li class="sidebar-item <%= "history".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/service-history.jsp" class="sidebar-link">
                <i class="fa-solid fa-clock-rotate-left"></i>
                <span>Service History</span>
            </a>
        </li>

        <!-- 6. My Profile -->
        <li class="sidebar-item <%= "profile".equals(activeUserPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/user/profile.jsp" class="sidebar-link">
                <i class="fa-solid fa-user"></i>
                <span>My Profile</span>
            </a>
        </li>
    </ul>

    <!-- Bottom Container: Sunset Road Illustration & Logout Button Pinned to Bottom without scroll -->
    <div class="user-sidebar-bottom-container">
        <!-- Roadside Artwork Illustration matching Reference Image -->
        <div class="user-sidebar-bottom-image-box">
            <img src="${pageContext.request.contextPath}/images/user-sidebar-highway-v2.png" alt="Roadside Breakdown Assistance" class="highway-img" onerror="this.onerror=null;this.src='${pageContext.request.contextPath}/images/sidebar-tow-truck.jpg';">
        </div>

        <!-- Logout Action Button at the very bottom of Sidebar (No confirm alert, direct session logout) -->
        <a href="${pageContext.request.contextPath}/user/logout.jsp" class="user-sidebar-logout-btn" title="Sign out of User Account">
            <i class="fa-solid fa-arrow-right-from-bracket"></i>
            <span>Logout</span>
        </a>
    </div>
</aside>

<!-- Backdrop overlay for mobile drawer -->
<div class="user-sidebar-backdrop" id="userSidebarBackdrop"></div>
