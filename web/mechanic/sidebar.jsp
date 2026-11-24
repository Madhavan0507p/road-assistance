<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String activeMechPage = (String) request.getAttribute("activeMechPage");
    if (activeMechPage == null || activeMechPage.trim().isEmpty()) {
        String uri = request.getRequestURI();
        if (uri.contains("pending-requests")) activeMechPage = "pending";
        else if (uri.contains("accepted-requests")) activeMechPage = "accepted";
        else if (uri.contains("service-requests")) activeMechPage = "requests";
        else if (uri.contains("service-history")) activeMechPage = "history";
        else if (uri.contains("profile")) activeMechPage = "profile";
        else activeMechPage = "dashboard";
    }
%>

<aside class="mech-sidebar" id="mechSidebar" style="width: 260px; min-width: 260px; max-width: 260px; flex: 0 0 260px;">
    <!-- Mobile Sidebar Header with Close Button -->
    <div class="sidebar-branding mobile-drawer-header">
        <div style="display: flex; align-items: center; gap: 10px;">
            <div style="width: 34px; height: 34px; border-radius: 8px; background: #F97316; display: flex; align-items: center; justify-content: center; color: #FFF; font-size: 15px;">
                <i class="fa-solid fa-wrench"></i>
            </div>
            <span style="font-weight: 700; font-size: 13px; color: #FFF; line-height: 1.2;">Mechanic<br><span style="color: #F97316;">Portal</span></span>
        </div>
        <button type="button" class="sidebar-close-btn" id="mechSidebarCloseBtn" aria-label="Close navigation">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>

    <!-- Top 5 Navigation Items -->
    <ul class="mech-sidebar-menu">
        <!-- 1. Dashboard -->
        <li class="sidebar-item <%= "dashboard".equals(activeMechPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/mechanic/dashboard.jsp" class="sidebar-link">
                <i class="fa-solid fa-house"></i>
                <span>Dashboard</span>
            </a>
        </li>

        <!-- 2. Service Requests -->
        <li class="sidebar-item <%= "requests".equals(activeMechPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/mechanic/service-requests.jsp" class="sidebar-link">
                <i class="fa-solid fa-wrench"></i>
                <span>Service Requests</span>
            </a>
        </li>

        <!-- 3. Pending Requests -->
        <li class="sidebar-item <%= "pending".equals(activeMechPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/mechanic/pending-requests.jsp" class="sidebar-link">
                <i class="fa-solid fa-clock"></i>
                <span>Pending Requests</span>
            </a>
        </li>

        <!-- 4. Accepted Requests -->
        <li class="sidebar-item <%= "accepted".equals(activeMechPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/mechanic/accepted-requests.jsp" class="sidebar-link">
                <i class="fa-solid fa-circle-check"></i>
                <span>Accepted Requests</span>
            </a>
        </li>

        <!-- 5. Service History -->
        <li class="sidebar-item <%= "history".equals(activeMechPage) ? "active" : "" %>">
            <a href="${pageContext.request.contextPath}/mechanic/service-history.jsp" class="sidebar-link">
                <i class="fa-solid fa-clock-rotate-left"></i>
                <span>Service History</span>
            </a>
        </li>
          <li class="sidebar-item <%= "profile".equals(activeMechPage) ? "active" : "" %>" style="list-style: none;">
            <a href="${pageContext.request.contextPath}/mechanic/profile.jsp" class="sidebar-link">
                <i class="fa-solid fa-user"></i>
                <span>My Profile</span>
            </a>
        </li>
    </ul>

    <!-- Bottom Navigation Items: My Profile & Logout -->
    <div class="mech-sidebar-bottom-group">
        <!-- 6. My Profile (Placed near bottom above Logout) -->
      

        <!-- 7. Logout (Fixed at absolute bottom) -->
        <li class="sidebar-item" style="list-style: none;">
            <a href="${pageContext.request.contextPath}/mechanic/logout.jsp" class="sidebar-link" title="Logout">
                <i class="fa-solid fa-right-from-bracket"></i>
                <span>Logout</span>
            </a>
        </li>
    </div>
</aside>
<!-- Mobile Drawer Backdrop Overlay -->
<div class="mech-sidebar-backdrop" id="mechSidebarBackdrop"></div>
