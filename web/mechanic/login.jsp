<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.roadassistance.model.Mechanic" %>
<%
    // Redirect already authenticated approved mechanics to dashboard
    Mechanic activeM = (Mechanic) session.getAttribute("mechanic");
    if (activeM != null && activeM.isApproved()) {
        response.sendRedirect(request.getContextPath() + "/mechanic/dashboard.jsp");
        return;
    }

    String error = request.getParameter("error");
    String msg = request.getParameter("msg");
    String workshop = request.getParameter("workshop");
    if (workshop == null || workshop.trim().isEmpty()) {
        workshop = "Your workshop";
    }

    String errorMsg = null;
    String pendingMsg = null;
    String blockedMsg = null;
    String infoMsg = null;
    String successMsg = null;

    if ("pending".equals(error)) {
        pendingMsg = "Account Pending Approval: The mechanic account for '" + workshop + "' is awaiting administrator verification. You will be able to access the dashboard once approved.";
    } else if ("blocked".equals(error)) {
        blockedMsg = "Account Blocked: Access for '" + workshop + "' has been blocked by administrator. You cannot sign in. Please contact support.";
    } else if ("rejected".equals(error)) {
        blockedMsg = "Application Rejected: Your mechanic registration was not approved. Please contact customer support.";
    } else if ("invalid_credentials".equals(error)) {
        errorMsg = "Invalid email or password. Please check your credentials and try again.";
    } else if ("password_reset_success".equals(msg)) {
        successMsg = "Password reset successfully! Please log in with your new password.";
    } else if ("auth_required".equals(msg)) {
        infoMsg = "Please log in with an approved mechanic account to access the dashboard.";
    } else if ("registered_pending".equals(msg)) {
        infoMsg = "Registration Submitted: The mechanic partner profile for '" + workshop + "' is currently awaiting administrator review and approval. You will receive an email once approved.";
    } else if ("logged_out".equals(msg)) {
        infoMsg = "You have been successfully logged out of the Mechanic Portal.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mechanic Login — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-login.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
</head>
<body>

    <!-- Ambient Glow Swooshes -->
    <div class="corner-swoosh-top"></div>
    <div class="corner-swoosh-bottom"></div>

    <!-- Decorative Corner Waves -->
    <svg class="corner-wave-svg" viewBox="0 0 350 250" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M0 250C90 230 150 180 180 120C210 60 280 20 350 0V250H0Z" fill="url(#orangeGrad1)" fill-opacity="0.25"/>
        <path d="M0 250C60 240 120 200 150 150C180 90 240 40 320 10V250H0Z" fill="url(#orangeGrad2)" fill-opacity="0.35"/>
        <defs>
            <linearGradient id="orangeGrad1" x1="0" y1="250" x2="350" y2="0" gradientUnits="userSpaceOnUse">
                <stop stop-color="#EA580C"/>
                <stop offset="1" stop-color="#F97316" stop-opacity="0"/>
            </linearGradient>
            <linearGradient id="orangeGrad2" x1="0" y1="250" x2="320" y2="10" gradientUnits="userSpaceOnUse">
                <stop stop-color="#F97316"/>
                <stop offset="1" stop-color="#EA580C" stop-opacity="0"/>
            </linearGradient>
        </defs>
    </svg>

    <!-- Top Navigation Bar with Interactive Back to Home Button -->
    <header class="mechanic-login-topbar">
        <a href="${pageContext.request.contextPath}/index.jsp" class="btn-back-home-top" id="topBackHomeBtn" title="Return to Website Homepage">
            <i class="fa-solid fa-arrow-left"></i>
            <span>Back to Home</span>
        </a>
    </header>

    <!-- Main Container matching Reference Screenshot -->
    <main class="mechanic-login-container">
        
        <!-- =================================================================
             1. LEFT SECTION (55% Width) — Branding, Title & 3 Feature Items
             ================================================================= -->
        <section class="mechanic-intro-col">
            <!-- Top-Left Branding -->
            <a href="${pageContext.request.contextPath}/index.jsp" class="brand-header-link" title="Return to Homepage">
                <div class="brand-logo-icon">
                    <i class="fa-solid fa-car-burst"></i>
                </div>
                <div class="brand-text-block">
                    <span class="brand-name-main">On Road Vehicle</span>
                    <span class="brand-name-sub">Breakdown Assistance</span>
                </div>
            </a>

            <!-- Main Heading: Mechanic (White) + Login (Orange) -->
            <div class="intro-heading-group">
                <h1 class="intro-title">
                    <span class="title-mechanic">Mechanic</span>
                    <span class="title-login">Login</span>
                </h1>
                <div class="intro-underline"></div>
            </div>

            <!-- Descriptive Paragraph -->
            <p class="intro-description">
                Login to your mechanic account to receive service requests, manage bookings and grow your service.
            </p>

            <!-- 3 Feature Items matching Reference Screenshot -->
            <div class="mechanic-features-list">
                <!-- Feature 1: Get Service Requests -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-calendar-check"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Get Service Requests</h3>
                        <span class="feature-desc">Receive nearby breakdown requests instantly.</span>
                    </div>
                </div>

                <!-- Feature 2: Manage Services -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Manage Services</h3>
                        <span class="feature-desc">Update service status, progress and availability.</span>
                    </div>
                </div>

                <!-- Feature 3: Grow Your Business -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-chart-column"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Grow Your Business</h3>
                        <span class="feature-desc">Reach more customers and increase your service bookings.</span>
                    </div>
                </div>
            </div>
        </section>

        <!-- =================================================================
             2. RIGHT SECTION (45% Width) — Large White Login Form Card
             ================================================================= -->
        <section class="mechanic-login-card-col">
            <div class="mechanic-login-card">
                <!-- Top Center Orange Circular Crossed-Tools Icon -->
                <div class="card-avatar-wrapper">
                    <div class="mechanic-avatar-badge">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                </div>

                <!-- Card Header -->
                <div class="card-header-center">
                    <h2 class="card-heading-title">Mechanic Login</h2>
                    <p class="card-heading-subtitle">Access your mechanic dashboard</p>
                </div>

                <!-- Flash Alerts -->
                <% if (successMsg != null) { %>
                    <div class="card-alert-box card-alert-success" id="successAlertBox" style="background:#ECFDF5; border:1px solid #A7F3D0; color:#065F46; padding:12px 14px; border-radius:10px; margin-bottom:18px; display:flex; align-items:center; gap:10px;">
                        <i class="fa-solid fa-circle-check" style="color:#10B981; font-size:16px;"></i>
                        <span><%= successMsg %></span>
                    </div>
                <% } %>
                <% if (errorMsg != null) { %>
                    <div class="card-alert-box card-alert-error" id="errorAlertBox">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                        <span><%= errorMsg %></span>
                    </div>
                <% } %>

                <% if (pendingMsg != null) { %>
                    <div class="card-alert-box card-alert-warning" id="pendingAlertBox">
                        <i class="fa-solid fa-clock"></i>
                        <span><%= pendingMsg %></span>
                    </div>
                <% } %>

                <% if (blockedMsg != null) { %>
                    <div class="card-alert-box card-alert-error" id="blockedAlertBox">
                        <i class="fa-solid fa-ban"></i>
                        <span><%= blockedMsg %></span>
                    </div>
                <% } %>

                <% if (infoMsg != null) { %>
                    <div class="card-alert-box card-alert-info" id="infoAlertBox">
                        <i class="fa-solid fa-circle-info"></i>
                        <span><%= infoMsg %></span>
                    </div>
                <% } %>

                <!-- Client-Side Alert Box -->
                <div class="card-alert-box card-alert-error" id="clientAlertBox" style="display: none;">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                    <span id="clientAlertMsg"></span>
                </div>

                <!-- Mechanic Login Form -->
                <form action="${pageContext.request.contextPath}/AuthServlet" method="POST" id="mechanicLoginForm" novalidate>
                    <input type="hidden" name="role" value="mechanic">

                    <!-- Field 1: Email Address -->
                    <div class="form-field-group">
                        <label class="field-label" for="mechanicEmail">
                            <i class="fa-solid fa-envelope"></i> Email Address
                        </label>
                        <div class="field-input-wrapper">
                            <input type="email" id="mechanicEmail" name="email" class="field-input" placeholder="Enter your registered email" required autocomplete="email" autofocus>
                        </div>
                        <span class="field-error-msg" id="emailErrorMsg">Please enter a valid registered email address.</span>
                    </div>

                    <!-- Field 2: Password with Working Eye Toggle -->
                    <div class="form-field-group">
                        <label class="field-label" for="mechanicPassword">
                            <i class="fa-solid fa-lock"></i> Password
                        </label>
                        <div class="field-input-wrapper">
                            <input type="password" id="mechanicPassword" name="password" class="field-input has-toggle" placeholder="Enter your password" required autocomplete="current-password">
                            <button type="button" id="togglePasswordBtn" class="password-toggle-btn" title="Toggle password visibility" aria-label="Toggle password visibility">
                                <i class="fa-regular fa-eye" id="togglePasswordIcon"></i>
                            </button>
                        </div>
                        <span class="field-error-msg" id="passwordErrorMsg">Please enter your password.</span>
                    </div>

                    <!-- Options Row: Remember Me & Forgot Password -->
                    <div class="form-options-row">
                        <label class="remember-checkbox-label" for="mechanicRemember">
                            
                        </label>
                        <a href="${pageContext.request.contextPath}/mechanic/forgot-password.jsp" class="forgot-password-link">Forgot Password?</a>
                    </div>

                    <!-- Large Orange Login Button -->
                    <button type="submit" class="btn-login-submit" id="mechanicSubmitBtn">
                        <i class="fa-solid fa-right-to-bracket" id="submitIcon"></i>
                        <span id="submitText">Login</span>
                    </button>

                    <!-- Back to Home Button directly under the Login Button -->
                    <a href="${pageContext.request.contextPath}/index.jsp" class="btn-back-to-home" id="cardBackHomeBtn" title="Return to Homepage">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>Back to Home</span>
                    </a>

                    <!-- Divider: New to our platform? -->
                    <div class="auth-divider">
                        <span>New to our platform?</span>
                    </div>

                    <!-- Outlined Orange Button: Register as Mechanic -->
                    <a href="${pageContext.request.contextPath}/mechanic/register.jsp" class="btn-register-mechanic">
                        <i class="fa-solid fa-user-plus"></i>
                        <span>Register as Mechanic</span>
                    </a>
                </form>
            </div>
        </section>
    </main>

    <!-- Client-Side Form Scripts -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // 1. Password Visibility Toggle
            const toggleBtn = document.getElementById('togglePasswordBtn');
            const passInput = document.getElementById('mechanicPassword');
            const passIcon = document.getElementById('togglePasswordIcon');

            if (toggleBtn && passInput && passIcon) {
                toggleBtn.addEventListener('click', function () {
                    const isPassword = passInput.type === 'password';
                    passInput.type = isPassword ? 'text' : 'password';
                    passIcon.className = isPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye';
                    passInput.focus();
                });
            }

            // 2. Client-Side Validation & AJAX Submission
            const loginForm = document.getElementById('mechanicLoginForm');
            const emailInput = document.getElementById('mechanicEmail');
            const submitBtn = document.getElementById('mechanicSubmitBtn');
            const submitIcon = document.getElementById('submitIcon');
            const submitText = document.getElementById('submitText');
            const emailErrorMsg = document.getElementById('emailErrorMsg');
            const passwordErrorMsg = document.getElementById('passwordErrorMsg');
            const clientAlertBox = document.getElementById('clientAlertBox');
            const clientAlertMsg = document.getElementById('clientAlertMsg');

            function showClientAlert(msg) {
                clientAlertBox.style.display = 'flex';
                clientAlertMsg.textContent = msg;
            }

            function hideClientAlert() {
                clientAlertBox.style.display = 'none';
            }

            if (loginForm) {
                loginForm.addEventListener('submit', function (e) {
                    hideClientAlert();
                    let isValid = true;

                    const emailVal = emailInput.value.trim();
                    const passVal = passInput.value.trim();
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

                    // Email validation
                    if (!emailVal) {
                        emailErrorMsg.textContent = 'Please enter your registered email address.';
                        emailErrorMsg.style.display = 'block';
                        emailInput.style.borderColor = '#DC2626';
                        isValid = false;
                    } else if (!emailRegex.test(emailVal)) {
                        emailErrorMsg.textContent = 'Please enter a valid email format (e.g. workshop@domain.com).';
                        emailErrorMsg.style.display = 'block';
                        emailInput.style.borderColor = '#DC2626';
                        isValid = false;
                    } else {
                        emailErrorMsg.style.display = 'none';
                        emailInput.style.borderColor = '#D1D5DB';
                    }

                    // Password validation
                    if (!passVal) {
                        passwordErrorMsg.textContent = 'Please enter your password.';
                        passwordErrorMsg.style.display = 'block';
                        passInput.style.borderColor = '#DC2626';
                        isValid = false;
                    } else {
                        passwordErrorMsg.style.display = 'none';
                        passInput.style.borderColor = '#D1D5DB';
                    }

                    if (!isValid) {
                        e.preventDefault();
                        return;
                    }

                    // Loading State on submission
                    submitBtn.disabled = true;
                    submitIcon.className = 'fa-solid fa-circle-notch fa-spin';
                    submitText.textContent = 'Signing in...';
                });
            }

            // Auto-clear validation errors on input typing
            [emailInput, passInput].forEach(function (inp) {
                if (inp) {
                    inp.addEventListener('input', function () {
                        inp.style.borderColor = '#D1D5DB';
                        if (emailErrorMsg) emailErrorMsg.style.display = 'none';
                        if (passwordErrorMsg) passwordErrorMsg.style.display = 'none';
                        hideClientAlert();
                    });
                }
            });
        });
    </script>
</body>
</html>
