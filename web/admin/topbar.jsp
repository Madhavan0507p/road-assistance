<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String headerTitle = (String) request.getAttribute("pageTitle");
    if (headerTitle == null || headerTitle.trim().isEmpty()) {
        headerTitle = "Admin Dashboard";
    }
    String headerSubtitle = (String) request.getAttribute("pageSubtitle");
    if (headerSubtitle == null || headerSubtitle.trim().isEmpty()) {
        headerSubtitle = "Monitor and manage the roadside assistance platform";
    }
    String searchPlaceholder = (String) request.getAttribute("searchPlaceholder");
    if (searchPlaceholder == null || searchPlaceholder.trim().isEmpty()) {
        searchPlaceholder = "Search users, mechanics, requests...";
    }
    String notifCount = (String) request.getAttribute("notifCount");
    if (notifCount == null || notifCount.trim().isEmpty()) {
        notifCount = "3";
    }
    String pageIcon = (String) request.getAttribute("pageIcon");
%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
<script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
<header class="top-header">
    <!-- Left Side: Hamburger, Page Icon & Titles -->
    <div class="header-left" style="display: flex; align-items: center; gap: 14px;">
        <button type="button" class="hamburger-btn" id="menuToggleBtn" aria-label="Toggle Navigation">
            <i class="fa-solid fa-bars"></i>
        </button>
        <% if (pageIcon != null && !pageIcon.trim().isEmpty()) { %>
        <div class="topbar-icon-badge" style="width: 44px; height: 44px; min-width: 44px; border-radius: 12px; background: #F97316; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.3);">
            <i class="<%= pageIcon %>"></i>
        </div>
        <% } %>
        <div class="header-title-group">
            <h1><%= headerTitle %></h1>
            <p><%= headerSubtitle %></p>
        </div>
    </div>

    <!-- Right Side: Search, Notification & Profile -->
    <div class="header-right">
        <!-- Search Bar -->
        <% if (!"none".equalsIgnoreCase(searchPlaceholder)) { %>
        <div class="search-wrapper">
            <i class="fa-solid fa-magnifying-glass search-icon"></i>
            <input type="text" class="search-input" id="globalSearchInput" placeholder="<%= searchPlaceholder %>" aria-label="Search">
        </div>
        <% } %>

       
        <!-- Admin Profile -->
        <div class="admin-profile" style="cursor: pointer;" onclick="location.href='${pageContext.request.contextPath}/admin/dashboard.jsp'">
            <div class="profile-avatar" style="display: flex; align-items: center; justify-content: center; background: rgba(249, 115, 22, 0.15); border: 2px solid #F97316;">
                <i class="fa-solid fa-user-shield" style="color: #F97316; font-size: 15px;"></i>
            </div>
            <div class="profile-info">
                <span class="profile-name">Admin</span>
                <span class="profile-role">Administrator</span>
            </div>
            <i class="fa-solid fa-chevron-down profile-arrow"></i>
        </div>
    </div>
</header>
