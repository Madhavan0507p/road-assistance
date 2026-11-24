<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent already logged-in admins from seeing login page again
    if (session.getAttribute("admin") != null) {
        response.sendRedirect(request.getContextPath() + "/admin/dashboard.jsp");
        return;
    }

    String error = request.getParameter("error");
    String msg = request.getParameter("msg");
    String errorMsg = null;
    String infoMsg = null;

    if ("invalid_credentials".equals(error)) {
        errorMsg = "Invalid admin credentials. Please check your Admin ID and password.";
    } else if ("auth_required".equals(msg)) {
        infoMsg = "Administrator credentials required to access the admin dashboard.";
    } else if ("logged_out".equals(msg)) {
        infoMsg = "You have been successfully signed out of the Admin Console.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-login.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
</head>
<body>

    <!-- =====================================================================
         TOP HEADER with LIVE STATUS
         ===================================================================== -->
    <header class="admin-login-topbar">
        <!-- Live Server Status Indicator -->
        <div class="topbar-status-badge">
            <span class="status-dot"></span>
            <span>Database Connected</span>
        </div>
    </header>

    <!-- =====================================================================
         MAIN LOGIN SECTION
         ===================================================================== -->
    <main class="admin-login-wrapper">
        
        <!-- 1. LEFT SECTION (55% Width) — Branding, Title & 4 Feature Items -->
        <section class="admin-intro-col">
            <!-- Top-Left Branding -->
            <a href="${pageContext.request.contextPath}/index.jsp" class="brand-header-link" title="Return to Homepage">
                <div class="brand-logo-icon">
                    <i class="fa-solid fa-car-burst"></i>
                </div>
                <div class="brand-text-block">
                    <span class="brand-name-main">On Road Vehicle</span>
                    <span class="brand-name-sub">BREAKDOWN ASSISTANCE</span>
                </div>
            </a>

            <!-- Main Heading -->
            <div class="intro-heading-group">
                <h1 class="intro-title">
                    <span class="title-admin">Admin</span>
                    <span class="title-login">Login</span>
                </h1>
                <div class="intro-underline"></div>
            </div>

            <!-- Descriptive Paragraph -->
            <p class="intro-description">
                Access the administration panel to manage users, mechanics, services, requests and platform operations.
            </p>

            <!-- 4 Feature Items with Orange Icons inside Rounded Backgrounds -->
            <div class="admin-features-list">
                <!-- Feature 1: Manage Users -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-users"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Manage Users</h3>
                        <span class="feature-desc">Users, mechanics and vehicle owners</span>
                    </div>
                </div>

                <!-- Feature 2: Service Management -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-gear"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Service Management</h3>
                        <span class="feature-desc">Services, categories and requests</span>
                    </div>
                </div>

                <!-- Feature 3: Requests & Reports -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-chart-column"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Requests & Reports</h3>
                        <span class="feature-desc">Track service requests and view reports</span>
                    </div>
                </div>

                <!-- Feature 4: System Control -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-shield-halved"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">System Control</h3>
                        <span class="feature-desc">Platform settings and access management</span>
                    </div>
                </div>
            </div>
        </section>

        <!-- 2. RIGHT SECTION (42% Width) — Interactive Admin Login Panel -->
        <section class="admin-login-card-col">
            <div class="admin-login-card">
                <!-- Top-Right Subtle Gear Watermark -->
                <i class="fa-solid fa-gear card-gear-watermark" aria-hidden="true"></i>

                <!-- Card Header -->
                <div class="card-header-center">
                    <!-- Orange Shield Icon with Crown -->
                    <div class="admin-shield-container">
                        <img src="${pageContext.request.contextPath}/images/admin-shield-badge.png" alt="Admin Shield">
                    </div>
                    
                    <!-- Heading -->
                    <h2 class="panel-heading-title">
                        <span class="panel-admin">Admin</span> <span class="panel-login">Login</span>
                    </h2>
                    
                    <!-- Subtitle -->
                    <p class="panel-heading-subtitle">On Road Vehicle Breakdown Assistance</p>
                    
                    <!-- Horizontal Divider -->
                    <div class="panel-header-divider"></div>
                </div>

                <!-- System Flash Alerts -->
                <% if (errorMsg != null) { %>
                    <div class="card-alert-box card-alert-error" id="errorAlertBox">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                        <span><%= errorMsg %></span>
                    </div>
                <% } %>

                <% if (infoMsg != null) { %>
                    <div class="card-alert-box card-alert-info" id="infoAlertBox">
                        <i class="fa-solid fa-circle-info"></i>
                        <span><%= infoMsg %></span>
                    </div>
                <% } %>

                <!-- Admin Login Form submitting strictly to AuthServlet for database validation -->
                <form action="${pageContext.request.contextPath}/AuthServlet" method="POST" class="login-form-body" id="adminLoginForm">
                    <input type="hidden" name="role" value="admin">

                    <!-- Field 1: Admin ID (NO cached/hardcoded value) -->
                    <div class="form-field-group">
                        <label class="field-label" for="adminId">
                            <i class="fa-solid fa-user"></i> Admin ID or Email
                        </label>
                        <div class="field-input-wrapper">
                            <input type="text" id="adminId" name="identifier" class="field-input" placeholder="Enter admin ID or email" required autocomplete="username" autofocus>
                        </div>
                    </div>

                    <!-- Field 2: Password (NO cached/hardcoded value) -->
                    <div class="form-field-group">
                        <label class="field-label" for="adminPass">
                            <i class="fa-solid fa-lock"></i> Password
                        </label>
                        <div class="field-input-wrapper">
                            <input type="password" id="adminPass" name="password" class="field-input" placeholder="Enter your password" required autocomplete="current-password">
                            <button type="button" class="password-toggle-btn" id="togglePasswordBtn" title="Toggle password visibility" aria-label="Toggle password visibility">
                                <i class="fa-regular fa-eye" id="togglePasswordIcon"></i>
                            </button>
                        </div>
                    </div>

                  

                    <!-- Submit Button: Interactive with Loading State -->
                    <button type="submit" class="btn-submit-admin" id="adminSubmitBtn">
                        <i class="fa-solid fa-right-to-bracket" id="submitIcon"></i>
                        <span id="submitText">Login as Admin</span>
                    </button>

                    <!-- Back to Home Button at Bottom of Login Button -->
                    <a href="${pageContext.request.contextPath}/index.jsp" class="btn-back-home-bottom" id="backToHomeBtn" title="Return to Website Homepage">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>Back to Home</span>
                    </a>
                </form>

                <!-- Subtle Bottom Highway Perspective Illustration inside Panel -->
                <div class="panel-highway-footer" aria-hidden="true">
                    <img src="${pageContext.request.contextPath}/images/admin-panel-highway.png" alt="Highway Horizon">
                </div>
            </div>
        </section>

    </main>


    <!-- Interactive Scripts for Password Toggle and Loading Animation -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // 1. Password Visibility Toggle
            const toggleBtn = document.getElementById('togglePasswordBtn');
            const passInput = document.getElementById('adminPass');
            const passIcon = document.getElementById('togglePasswordIcon');

            if (toggleBtn && passInput && passIcon) {
                toggleBtn.addEventListener('click', function () {
                    const isPassword = passInput.type === 'password';
                    passInput.type = isPassword ? 'text' : 'password';
                    passIcon.className = isPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye';
                    passInput.focus();
                });
            }

            // 2. Interactive Form Submission with Loading Spinner
            const loginForm = document.getElementById('adminLoginForm');
            const submitBtn = document.getElementById('adminSubmitBtn');
            const submitIcon = document.getElementById('submitIcon');
            const submitText = document.getElementById('submitText');

            if (loginForm && submitBtn) {
                loginForm.addEventListener('submit', function (e) {
                    const idVal = document.getElementById('adminId').value.trim();
                    const passVal = passInput.value.trim();

                    if (!idVal || !passVal) {
                        e.preventDefault();
                        return;
                    }

                    // Button loading state
                    submitBtn.disabled = true;
                    submitIcon.className = 'fa-solid fa-circle-notch fa-spin';
                    submitText.textContent = 'Verifying Credentials...';
                    submitBtn.style.opacity = '0.9';
                    submitBtn.style.pointerEvents = 'none';

                    // Allow form to submit naturally to AuthServlet
                });
            }

            // 3. Auto-dismiss alerts on input typing
            const adminIdInput = document.getElementById('adminId');
            const errorBox = document.getElementById('errorAlertBox');

            [adminIdInput, passInput].forEach(function (inp) {
                if (inp && errorBox) {
                    inp.addEventListener('input', function () {
                        errorBox.style.opacity = '0.5';
                    });
                }
            });
        });
    </script>
</body>
</html>
