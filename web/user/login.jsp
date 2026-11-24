<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // If an authenticated user visits login, invalidate the session and redirect to home page
    if (session.getAttribute("user") != null) {
        session.removeAttribute("user");
        session.removeAttribute("userRole");
        try {
            session.invalidate();
        } catch (IllegalStateException ignored) {}
        response.sendRedirect(request.getContextPath() + "/index.jsp");
        return;
    }

    String error = request.getParameter("error");
    String msg = request.getParameter("msg");
    String emailParam = request.getParameter("email");
    if (emailParam == null) emailParam = "";

    String errorMsg = null;
    String infoMsg = null;
    String successMsg = null;

    if ("invalid_credentials".equals(error)) {
        errorMsg = "Invalid email, mobile number or password. Please try again.";
    } else if ("blocked".equals(error)) {
        errorMsg = "Your account has been blocked by administrator. You cannot sign in. Please contact support.";
    } else if ("account_inactive".equals(error)) {
        errorMsg = "Your account is pending administrator activation. An administrator must activate your credentials before you can sign in.";
    } else if ("password_reset_success".equals(msg)) {
        successMsg = "Password reset successfully! Please sign in with your new password.";
    } else if ("registered_pending".equals(msg)) {
        infoMsg = "Account registered successfully! Your account is currently inactive pending administrator activation. You can sign in once an administrator activates your account.";
    } else if ("registered".equals(msg) || "account_created".equals(msg)) {
        successMsg = "Account created successfully! Please sign in with your credentials.";
    } else if ("auth_required".equals(msg)) {
        infoMsg = "Please sign in to access your motorist account and services.";
    } else if ("logged_out".equals(msg)) {
        infoMsg = "You have been successfully logged out.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Login — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-login.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
</head>
<body>

    <!-- Top Navigation Header with Back to Home Button -->
    <header class="user-login-topbar">
        <a href="${pageContext.request.contextPath}/index.jsp" class="btn-back-home-top" id="topBackHomeBtn" title="Return to Homepage">
            <i class="fa-solid fa-arrow-left"></i>
            <span>Back to Home</span>
        </a>
    </header>

    <!-- Main Container matching Reference Screenshot -->
    <main class="user-login-container">
        
        <!-- =================================================================
             1. LEFT SECTION (55% Width) — Branding, Title & 3 Feature Items
             ================================================================= -->
        <section class="user-intro-col">
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

            <!-- Main Heading -->
            <div class="intro-heading-group">
                <h1 class="intro-title">
                    <span class="title-user">User</span><span class="title-login">Login</span>
                </h1>
                <div class="intro-underline"></div>
            </div>

            <!-- Descriptive Paragraph -->
            <p class="intro-description">
                Access your account, request assistance, track services and manage your vehicles.
            </p>

            <!-- 3 Feature Items matching Reference Screenshot -->
            <div class="user-features-list">
                <!-- Feature 1: Request Roadside Assistance -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-car"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Request Roadside Assistance</h3>
                        <span class="feature-desc">Get quick help for vehicle breakdowns</span>
                    </div>
                </div>

                <!-- Feature 2: Track Service Requests -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-location-dot"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Track Service Requests</h3>
                        <span class="feature-desc">Monitor real-time service updates</span>
                    </div>
                </div>

                <!-- Feature 3: Manage Your Vehicles -->
                <div class="feature-item-row">
                    <div class="feature-icon-box">
                        <i class="fa-solid fa-car-side"></i>
                    </div>
                    <div class="feature-text-block">
                        <h3 class="feature-title">Manage Your Vehicles</h3>
                        <span class="feature-desc">Add, view and update your vehicle details</span>
                    </div>
                </div>
            </div>
        </section>

        <!-- =================================================================
             2. RIGHT SECTION (40% Width) — Large White Login Form Card
             ================================================================= -->
        <section class="user-login-card-col">
            <div class="user-login-card">
                <!-- Top Center Orange Circular User Icon -->
                <div class="card-avatar-wrapper">
                    <div class="user-avatar-badge">
                        <i class="fa-solid fa-user"></i>
                    </div>
                </div>

                <!-- Card Header -->
                <div class="card-header-center">
                    <h2 class="card-heading-title">User Login</h2>
                    <p class="card-heading-subtitle">Sign in to your account</p>
                </div>

                <!-- Flash Alerts -->
                <% if (errorMsg != null) { %>
                    <div class="card-alert-box card-alert-error" id="errorAlertBox">
                        <i class="fa-solid fa-triangle-exclamation"></i>
                        <span><%= errorMsg %></span>
                    </div>
                <% } %>

                <% if (successMsg != null) { %>
                    <div class="card-alert-box card-alert-success" id="successAlertBox">
                        <i class="fa-solid fa-circle-check"></i>
                        <span><%= successMsg %></span>
                    </div>
                <% } %>

                <% if (infoMsg != null) { %>
                    <div class="card-alert-box card-alert-info" id="infoAlertBox">
                        <i class="fa-solid fa-circle-info"></i>
                        <span><%= infoMsg %></span>
                    </div>
                <% } %>

                <!-- User Login Form posting strictly to AuthServlet -->
                <form action="${pageContext.request.contextPath}/AuthServlet" method="POST" class="login-form-body" id="userLoginForm">
                    <input type="hidden" name="role" value="user">

                    <!-- Field 1: Email or Mobile Number -->
                    <div class="form-field-group">
                        <label class="field-label" for="userIdentifier">
                            <i class="fa-solid fa-envelope"></i> Email or Mobile Number
                        </label>
                        <div class="field-input-wrapper">
                            <input type="text" id="userIdentifier" name="identifier" class="field-input" placeholder="Enter your email or mobile number" value="<%= emailParam != null ? emailParam : "" %>" required autocomplete="username" autofocus>
                        </div>
                    </div>

                    <!-- Field 2: Password with Working Eye Toggle -->
                    <div class="form-field-group">
                        <label class="field-label" for="userPassword">
                            <i class="fa-solid fa-lock"></i> Password
                        </label>
                        <div class="field-input-wrapper">
                            <input type="password" id="userPassword" name="password" class="field-input" placeholder="Enter your password" required autocomplete="current-password">
                            <button type="button" class="password-toggle-btn" id="togglePasswordBtn" title="Toggle password visibility" aria-label="Toggle password visibility">
                                <i class="fa-regular fa-eye" id="togglePasswordIcon"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Options Row: Remember Me & Forgot Password -->
                    <div class="form-options-row">
                        <label class="remember-checkbox-label">
                         
                        </label>
                        <a href="${pageContext.request.contextPath}/user/forgot-password.jsp" class="forgot-password-link">
                            Forgot Password?
                        </a>
                    </div>

                    <!-- Orange Full-Width Login Button -->
                    <button type="submit" class="btn-submit-user" id="userSubmitBtn">
                        <i class="fa-solid fa-arrow-right-to-bracket" id="submitIcon"></i>
                        <span id="submitText">Login</span>
                    </button>

                    <!-- Horizontal Separator: New to our platform? -->
                    <div class="card-divider-row">
                        <div class="card-divider-line"></div>
                        <span class="card-divider-text">New to our platform?</span>
                        <div class="card-divider-line"></div>
                    </div>

                    <!-- Outlined Orange Button: Create New Account -->
                    <a href="${pageContext.request.contextPath}/user/register.jsp" class="btn-create-account">
                        <i class="fa-solid fa-user-plus"></i>
                        <span>Create New Account</span>
                    </a>

                    <!-- Back to Home Action Button inside Card -->
                    <a href="${pageContext.request.contextPath}/index.jsp" class="btn-back-to-home" id="cardBackHomeBtn" title="Return to Homepage">
                        <i class="fa-solid fa-arrow-left"></i>
                        <span>Back to Home</span>
                    </a>
                </form>
            </div>
        </section>

    </main>

    <!-- Client-side Interactive Scripts -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // 1. Password Visibility Toggle
            const toggleBtn = document.getElementById('togglePasswordBtn');
            const passInput = document.getElementById('userPassword');
            const passIcon = document.getElementById('togglePasswordIcon');

            if (toggleBtn && passInput && passIcon) {
                toggleBtn.addEventListener('click', function () {
                    const isPassword = passInput.type === 'password';
                    passInput.type = isPassword ? 'text' : 'password';
                    passIcon.className = isPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye';
                    passInput.focus();
                });
            }

            // 2. Form Submission State
            const loginForm = document.getElementById('userLoginForm');
            const submitBtn = document.getElementById('userSubmitBtn');
            const submitIcon = document.getElementById('submitIcon');
            const submitText = document.getElementById('submitText');

            if (loginForm && submitBtn) {
                loginForm.addEventListener('submit', function (e) {
                    const idVal = document.getElementById('userIdentifier').value.trim();
                    const passVal = passInput.value.trim();

                    if (!idVal || !passVal) {
                        e.preventDefault();
                        return;
                    }

                    // Loading State
                    submitBtn.disabled = true;
                    submitIcon.className = 'fa-solid fa-circle-notch fa-spin';
                    submitText.textContent = 'Signing in...';
                    submitBtn.style.opacity = '0.9';
                    submitBtn.style.pointerEvents = 'none';
                });
            }

            // 3. Auto-dismiss alerts on input typing
            const userInput = document.getElementById('userIdentifier');
            const errorBox = document.getElementById('errorAlertBox');

            [userInput, passInput].forEach(function (inp) {
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
