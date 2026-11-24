<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent browser caching on all mechanic pages
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    com.roadassistance.model.Mechanic sessionMech = (com.roadassistance.model.Mechanic) session.getAttribute("mechanic");
    String dispWorkshop = "Kumar Auto Works";
    String dispOwner = "Kumar";
    String dispRole = "Mechanic";

    if (sessionMech != null) {
        if (sessionMech.getWorkshopName() != null && !sessionMech.getWorkshopName().trim().isEmpty()) {
            dispWorkshop = sessionMech.getWorkshopName();
        } else if (sessionMech.getShopName() != null && !sessionMech.getShopName().trim().isEmpty()) {
            dispWorkshop = sessionMech.getShopName();
        }
        if (sessionMech.getFirstName() != null && !sessionMech.getFirstName().trim().isEmpty()) {
            dispOwner = sessionMech.getFirstName();
        } else if (sessionMech.getOwnerName() != null && !sessionMech.getOwnerName().trim().isEmpty()) {
            dispOwner = sessionMech.getOwnerName();
        }
    }
%>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.2">
<script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.2" defer></script>
<header class="mech-top-navbar">
    <!-- Left: Brand Logo & Hamburger -->
    <div class="navbar-left">
        <a href="${pageContext.request.contextPath}/mechanic/dashboard.jsp" class="navbar-brand">
            <div class="brand-logo-icon">
                <i class="fa-solid fa-car-burst"></i>
            </div>
            <div class="brand-text-block">
                <span class="brand-main-title">On Road Vehicle</span>
                <span class="brand-sub-title">Breakdown Assistance</span>
            </div>
        </a>

        <!-- Hamburger Menu Toggle Button -->
        <button type="button" class="btn-sidebar-toggle" id="mechSidebarToggle" aria-label="Toggle navigation">
            <i class="fa-solid fa-bars"></i>
        </button>
    </div>

    <!-- Right: Notifications & Mechanic Profile -->
    <div class="navbar-right">
     

        <!-- Mechanic Profile Header -->
        <div class="mech-profile-wrapper" id="mechProfileWrapper">
            <button type="button" class="btn-mech-profile" id="mechProfileBtn" aria-expanded="false">
                <div class="mech-avatar-circle" style="display: flex; align-items: center; justify-content: center; background: rgba(249, 115, 22, 0.15); border: 2px solid #F97316;">
                    <i class="fa-solid fa-wrench" style="color: #F97316; font-size: 16px;"></i>
                </div>
                <div class="mech-info-text">
                    <span class="mech-display-name"><%= dispWorkshop %></span>
                    <span class="mech-display-role"><%= dispRole %></span>
                </div>
                <i class="fa-solid fa-chevron-down profile-chevron"></i>
            </button>

            <!-- Dropdown Menu -->
            <div class="mech-dropdown-menu" id="mechProfileDropdown">
                <a href="${pageContext.request.contextPath}/mechanic/profile.jsp" class="dropdown-link">
                    <i class="fa-solid fa-user"></i>
                    <span>My Profile</span>
                </a>
                <a href="${pageContext.request.contextPath}/mechanic/service-requests.jsp" class="dropdown-link">
                    <i class="fa-solid fa-wrench"></i>
                    <span>Service Requests</span>
                </a>
                <div style="height: 1px; background: rgba(255, 255, 255, 0.08); margin: 6px 0;"></div>
                <a href="${pageContext.request.contextPath}/mechanic/logout.jsp" class="dropdown-link text-danger">
                    <i class="fa-solid fa-right-from-bracket"></i>
                    <span>Logout</span>
                </a>
            </div>
        </div>
    </div>
</header>

<script>
    (function() {
        function initMechTopBar() {
            // Profile Dropdown Toggle
            var profileBtn = document.getElementById('mechProfileBtn');
            var profileWrapper = document.getElementById('mechProfileWrapper');
            var profileDropdown = document.getElementById('mechProfileDropdown');

            if (profileBtn && profileWrapper && profileDropdown) {
                profileBtn.onclick = function (e) {
                    e.stopPropagation();
                    var isShowing = profileDropdown.classList.contains('show');
                    if (isShowing) {
                        profileDropdown.classList.remove('show');
                        profileWrapper.classList.remove('active');
                        profileBtn.setAttribute('aria-expanded', 'false');
                    } else {
                        profileDropdown.classList.add('show');
                        profileWrapper.classList.add('active');
                        profileBtn.setAttribute('aria-expanded', 'true');
                    }
                };

                document.addEventListener('click', function (e) {
                    if (!profileWrapper.contains(e.target)) {
                        profileDropdown.classList.remove('show');
                        profileWrapper.classList.remove('active');
                        profileBtn.setAttribute('aria-expanded', 'false');
                    }
                });
            }
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMechTopBar);
        } else {
            initMechTopBar();
        }
    })();
</script>
