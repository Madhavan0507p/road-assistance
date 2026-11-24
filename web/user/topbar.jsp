<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent browser caching on all pages including topbar
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0
    response.setDateHeader("Expires", 0); // Proxies

    com.roadassistance.model.User sessionUser = (com.roadassistance.model.User) session.getAttribute("user");
    if (sessionUser == null) {
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
        return;
    }
    String dispName = (sessionUser.getFullName() != null && !sessionUser.getFullName().trim().isEmpty())
            ? sessionUser.getFullName() : "Madhavan P";
    String dispRole = "User";
%>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.2">
<script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.2" defer></script>
<header class="user-top-navbar">
    <!-- Left: Brand Logo & Hamburger -->
    <div class="navbar-left">
        <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="navbar-brand">
            <div class="brand-logo-icon">
                <i class="fa-solid fa-car-burst"></i>
            </div>
            <div class="brand-text-block">
                <span class="brand-main-title">On Road Vehicle</span>
                <span class="brand-sub-title">Breakdown Assistance</span>
            </div>
        </a>

        <!-- Hamburger Menu Toggle Button -->
        <button type="button" class="btn-sidebar-toggle" id="userSidebarToggle" aria-label="Toggle navigation">
            <i class="fa-solid fa-bars"></i>
        </button>
    </div>

    <!-- Right: Notifications & User Profile -->
    <div class="navbar-right">
        <!-- Notification Bell -->
        <div class="notification-wrapper" id="notifWrapper">
           
            <div class="notif-dropdown-menu" id="notifDropdown">
                
                <div class="notif-list">
                    <a href="${pageContext.request.contextPath}/user/my-requests.jsp" class="notif-item unread">
                        <div class="notif-icon-box">
                            <i class="fa-solid fa-wrench"></i>
                        </div>
                        <div class="notif-content">
                            <p class="notif-title">Mechanic</p>
                            <p class="notif-desc">Sathish Auto Works is en route to your breakdown location.</p>
                            <span class="notif-time">Just now</span>
                        </div>
                    </a>
                </div>
            </div>
        </div>

        <!-- User Profile Dropdown -->
        <div class="user-profile-wrapper" id="userProfileWrapper">
            <button type="button" class="btn-user-profile" id="userProfileBtn" aria-expanded="false">
                <div class="user-avatar-circle" style="display: flex; align-items: center; justify-content: center; background: rgba(249, 115, 22, 0.15); border: 2px solid #F97316;">
                    <i class="fa-solid fa-user" style="color: #F97316; font-size: 15px;"></i>
                </div>
                <div class="user-info-text">
                    <span class="user-display-name"><%= dispName %></span>
                    <span class="user-display-role"><%= dispRole %></span>
                </div>
                <i class="fa-solid fa-chevron-down profile-chevron"></i>
            </button>

            <!-- Dropdown Menu -->
            <div class="user-dropdown-menu" id="userProfileDropdown">
                <div class="dropdown-user-header">
                    <p class="header-name"><%= dispName %></p>
                    <p class="header-role">Motorist Account</p>
                </div>
                <div class="dropdown-divider"></div>
                <a href="${pageContext.request.contextPath}/user/profile.jsp" class="dropdown-link">
                    <i class="fa-regular fa-user"></i> My Profile
                </a>
                <a href="${pageContext.request.contextPath}/user/vehicles.jsp" class="dropdown-link">
                    <i class="fa-solid fa-car"></i> My Vehicles
                </a>
                <a href="${pageContext.request.contextPath}/user/profile.jsp#settings" class="dropdown-link">
                    <i class="fa-solid fa-gear"></i> Profile Settings
                </a>
                <div class="dropdown-divider"></div>
                <a href="${pageContext.request.contextPath}/user/logout.jsp" class="dropdown-link text-danger">
                    <i class="fa-solid fa-arrow-right-from-bracket"></i> Logout
                </a>
            </div>
        </div>
    </div>
</header>

<script>
    // Prevent back-button access after logout via browser bfcache
    window.addEventListener('pageshow', function (event) {
        if (event.persisted || (window.performance && window.performance.navigation && window.performance.navigation.type === 2)) {
            window.location.reload();
        }
    });

    (function() {
        function initTopBarControls() {
            // User Profile Dropdown Toggle
            const userProfileBtn = document.getElementById('userProfileBtn');
            const userProfileWrapper = document.getElementById('userProfileWrapper');
            const userProfileDropdown = document.getElementById('userProfileDropdown');
            const notifBtn = document.getElementById('notifBtn');
            const notifDropdown = document.getElementById('notifDropdown');

            function closeAllDropdowns() {
                if (userProfileDropdown) userProfileDropdown.classList.remove('show');
                if (userProfileWrapper) userProfileWrapper.classList.remove('active');
                if (notifDropdown) notifDropdown.classList.remove('show');
            }

            if (userProfileBtn && userProfileDropdown) {
                userProfileBtn.onclick = function (e) {
                    e.stopPropagation();
                    const isShown = userProfileDropdown.classList.contains('show');
                    closeAllDropdowns();
                    if (!isShown) {
                        userProfileDropdown.classList.add('show');
                        if (userProfileWrapper) userProfileWrapper.classList.add('active');
                    }
                };
            }

            if (notifBtn && notifDropdown) {
                notifBtn.onclick = function (e) {
                    e.stopPropagation();
                    const isShown = notifDropdown.classList.contains('show');
                    closeAllDropdowns();
                    if (!isShown) {
                        notifDropdown.classList.add('show');
                    }
                };
            }

            document.addEventListener('click', function (e) {
                if (userProfileWrapper && !userProfileWrapper.contains(e.target)) {
                    if (userProfileDropdown) userProfileDropdown.classList.remove('show');
                    userProfileWrapper.classList.remove('active');
                }
                const notifWrapper = document.getElementById('notifWrapper');
                if (notifWrapper && !notifWrapper.contains(e.target)) {
                    if (notifDropdown) notifDropdown.classList.remove('show');
                }
            });
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initTopBarControls);
        } else {
            initTopBarControls();
        }
    })();
</script>
