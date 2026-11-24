<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forgot Password — Motorist Account Recovery</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-forgot-password.css?v=3.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>

    <style>
        /* Embedded critical styles to guarantee 100% styling consistency regardless of browser cache */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: #0B0F19;
            color: #111827;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 30px 20px;
            background-image: 
                radial-gradient(circle at 15% 20%, rgba(249, 115, 22, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 85% 80%, rgba(234, 88, 12, 0.10) 0%, transparent 45%),
                url('${pageContext.request.contextPath}/images/user-login-bg.jpg?v=1.0');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            position: relative;
        }
        body::before {
            content: '';
            position: absolute;
            inset: 0;
            background: rgba(11, 15, 25, 0.88);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            z-index: 1;
        }
        .top-nav {
            position: absolute;
            top: 24px;
            left: 28px;
            z-index: 10;
        }
        .btn-back-home {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 18px;
            background: rgba(31, 41, 55, 0.7);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 9999px;
            color: #F3F4F6 !important;
            font-size: 13.5px;
            font-weight: 600;
            text-decoration: none !important;
            transition: all 0.2s ease;
            backdrop-filter: blur(6px);
        }
        .btn-back-home:hover {
            background: #F97316;
            color: #FFFFFF !important;
            border-color: #F97316;
            transform: translateX(-3px);
        }
        .recovery-card {
            width: 100%;
            max-width: 480px;
            background: #FFFFFF;
            border-radius: 28px;
            padding: 38px 34px;
            box-shadow: 0 24px 60px rgba(0, 0, 0, 0.55), 0 0 0 1px rgba(255, 255, 255, 0.08);
            color: #111827;
            position: relative;
            z-index: 2;
            transition: all 0.3s ease;
        }
        .badge-icon {
            width: 68px;
            height: 68px;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px auto;
            color: #FFFFFF;
            font-size: 26px;
            box-shadow: 0 10px 25px rgba(234, 88, 12, 0.38);
        }
        h2 {
            font-size: 24px;
            font-weight: 800;
            text-align: center;
            color: #111827;
            margin-bottom: 6px;
            letter-spacing: -0.3px;
        }
        p.subtitle {
            text-align: center;
            color: #64748B;
            font-size: 13.5px;
            margin-bottom: 22px;
            line-height: 1.5;
        }
        /* 3-Step Wizard Tracker matching Mechanic portal */
        .step-tracker {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 24px;
            padding: 0 6px;
            position: relative;
        }
        .step-tracker::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 24px;
            right: 24px;
            height: 3px;
            background: #E2E8F0;
            transform: translateY(-50%);
            z-index: 0;
        }
        .step-node {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: #F1F5F9;
            border: 2px solid #CBD5E1;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 800;
            color: #64748B;
            position: relative;
            z-index: 1;
            transition: all 0.25s ease;
        }
        .step-node.active {
            background: #F97316;
            border-color: #EA580C;
            color: #FFFFFF;
            box-shadow: 0 0 0 4px rgba(249, 115, 22, 0.2);
        }
        .step-node.completed {
            background: #10B981;
            border-color: #059669;
            color: #FFFFFF;
        }
        /* OTP Horizontal Row Styling */
        .otp-container {
            display: flex !important;
            flex-direction: row !important;
            flex-wrap: nowrap !important;
            justify-content: center !important;
            align-items: center !important;
            gap: 10px !important;
            margin: 18px 0 20px 0 !important;
            width: 100% !important;
        }
        .otp-digit {
            width: 48px !important;
            min-width: 48px !important;
            max-width: 48px !important;
            height: 54px !important;
            flex: 0 0 48px !important;
            text-align: center !important;
            font-size: 22px !important;
            font-weight: 800 !important;
            color: #0F172A !important;
            background: #F8FAFC !important;
            border: 1.5px solid #CBD5E1 !important;
            border-radius: 12px !important;
            outline: none !important;
            transition: all 0.2s ease !important;
            padding: 0 !important;
        }
        .otp-digit:focus {
            border-color: #F97316 !important;
            background: #FFFFFF !important;
            box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.2) !important;
            transform: translateY(-2px);
        }
        .otp-meta-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 10px;
            font-size: 13px;
            color: #64748B;
        }
        .btn-link-action {
            background: none;
            border: none;
            color: #F97316;
            font-weight: 700;
            font-size: 13px;
            font-family: inherit;
            cursor: pointer;
            text-decoration: none;
            padding: 0;
            transition: color 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        .btn-link-action:hover:not(:disabled) {
            color: #EA580C;
            text-decoration: underline;
        }
        .btn-link-action:disabled {
            color: #94A3B8;
            cursor: not-allowed;
            text-decoration: none;
        }
        /* Password Inputs with Embedded Eye Toggle */
        .form-group {
            margin-bottom: 18px;
            text-align: left;
        }
        .form-group label {
            display: block;
            font-size: 13px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 7px;
        }
        .form-group label i {
            color: #F97316;
            margin-right: 4px;
        }
        .input-container {
            position: relative !important;
            width: 100% !important;
            display: block !important;
        }
        .input-container input {
            width: 100% !important;
            height: 50px !important;
            background: #F8FAFC !important;
            border: 1.5px solid #CBD5E1 !important;
            border-radius: 12px !important;
            padding: 0 46px 0 16px !important;
            font-size: 14.5px !important;
            font-family: inherit !important;
            color: #0F172A !important;
            outline: none !important;
            transition: all 0.2s ease !important;
        }
        .input-container input:focus {
            border-color: #F97316 !important;
            background: #FFFFFF !important;
            box-shadow: 0 0 0 3.5px rgba(249, 115, 22, 0.18) !important;
        }
        .btn-toggle-eye {
            position: absolute !important;
            right: 12px !important;
            top: 50% !important;
            transform: translateY(-50%) !important;
            background: transparent !important;
            border: none !important;
            color: #94A3B8 !important;
            cursor: pointer !important;
            font-size: 16px !important;
            padding: 8px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            transition: color 0.15s ease !important;
        }
        .btn-toggle-eye:hover {
            color: #F97316 !important;
        }
        /* Password Checklist Card matching Mechanic UI */
        .pwd-rules-card {
            background: #F8FAFC !important;
            border: 1px solid #E2E8F0 !important;
            border-radius: 14px !important;
            padding: 14px 16px !important;
            margin: 14px 0 20px 0 !important;
        }
        .rules-title {
            font-size: 12.5px !important;
            font-weight: 800 !important;
            color: #475569 !important;
            text-transform: uppercase !important;
            letter-spacing: 0.5px !important;
            margin-bottom: 10px !important;
            display: flex !important;
            align-items: center !important;
            gap: 6px !important;
        }
        .rules-grid {
            display: grid !important;
            grid-template-columns: 1fr 1fr !important;
            gap: 8px 12px !important;
        }
        .rule-item {
            display: flex !important;
            align-items: center !important;
            gap: 7px !important;
            font-size: 12.5px !important;
            color: #64748B !important;
            font-weight: 600 !important;
            transition: color 0.2s ease !important;
        }
        .rule-item i {
            font-size: 13px !important;
            color: #CBD5E1 !important;
            transition: all 0.2s ease !important;
        }
        .rule-item.valid {
            color: #059669 !important;
        }
        .rule-item.valid i {
            color: #10B981 !important;
        }
        .btn-submit {
            width: 100%;
            height: 50px;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            color: #FFFFFF;
            border: none;
            border-radius: 12px;
            font-size: 15.5px;
            font-weight: 700;
            font-family: inherit;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            cursor: pointer;
            box-shadow: 0 6px 20px rgba(234, 88, 12, 0.35);
            margin-top: 14px;
            transition: all 0.25s ease;
        }
        .btn-submit:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 8px 26px rgba(234, 88, 12, 0.48);
        }
        .btn-submit:disabled {
            opacity: 0.65;
            cursor: not-allowed;
            transform: none;
        }
        .alert-box {
            display: none;
            padding: 12px 14px;
            border-radius: 12px;
            font-size: 13.5px;
            line-height: 1.45;
            margin-bottom: 18px;
            align-items: flex-start;
            gap: 10px;
        }
        .alert-box.error {
            background: #FEF2F2;
            border: 1px solid #FECACA;
            color: #991B1B;
        }
        .alert-box.error i {
            color: #DC2626;
            font-size: 16px;
            margin-top: 2px;
            flex-shrink: 0;
        }
        .alert-box.success {
            background: #ECFDF5;
            border: 1px solid #A7F3D0;
            color: #065F46;
        }
        .alert-box.success i {
            color: #10B981;
            font-size: 16px;
            margin-top: 2px;
            flex-shrink: 0;
        }
        .back-link {
            display: block;
            text-align: center;
            margin-top: 22px;
            font-size: 13.5px;
            color: #64748B;
        }
        .back-link a {
            color: #F97316;
            font-weight: 700;
            text-decoration: none;
        }
        .back-link a:hover {
            color: #EA580C;
            text-decoration: underline;
        }
        .success-box {
            text-align: center;
            padding: 10px 0;
        }
        .success-badge {
            width: 76px;
            height: 76px;
            background: linear-gradient(135deg, #10B981, #059669);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 18px auto;
            color: #FFFFFF;
            font-size: 34px;
            box-shadow: 0 10px 25px rgba(16, 185, 129, 0.4);
        }
    </style>
</head>
<body>

    <!-- Top Navigation Header -->
    <nav class="top-nav">
        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-back-home" title="Back to User Login">
            <i class="fa-solid fa-arrow-left"></i>
            <span>Back to Login</span>
        </a>
    </nav>

    <!-- Main Recovery Card Container matching Mechanic Recovery Card -->
    <div class="recovery-card" id="recoveryCard">
        
        <!-- Animated Key Icon -->
        <div class="badge-icon" id="headerBadge">
            <i class="fa-solid fa-key"></i>
        </div>

        <h2 id="viewTitle">Reset Password</h2>
        <p class="subtitle" id="viewSubtitle">Enter your registered email address and we'll send you verification instructions to reset your password.</p>

        <!-- 3-Step Wizard Tracker matching Mechanic Portal -->
        <div class="step-tracker" id="stepTracker">
            <div class="step-node active" id="nodeStep1" title="Step 1: Motorist Email">1</div>
            <div class="step-node" id="nodeStep2" title="Step 2: Verify OTP">2</div>
            <div class="step-node" id="nodeStep3" title="Step 3: New Password">3</div>
        </div>

        <!-- =================================================================
             STEP 1: EMAIL LOOKUP & OTP DISPATCH
             ================================================================= -->
        <div class="wizard-step" id="stepEmail">
            <div class="alert-box error" id="alertEmail" style="display:none;">
                <i class="fa-solid fa-circle-exclamation"></i>
                <div class="alert-text" id="alertEmailText"></div>
            </div>

            <form id="formEmail" onsubmit="return false;">
                <div class="form-group">
                    <label for="inputEmail"><i class="fa-solid fa-envelope"></i> Registered Email Address</label>
                    <div class="input-container">
                        <input type="email" id="inputEmail" placeholder="e.g. motorist@example.com" required autocomplete="email">
                    </div>
                </div>

                <button type="button" class="btn-submit" id="btnSendOtp">
                    <i class="fa-solid fa-paper-plane"></i>
                    <span>Send Verification OTP</span>
                </button>

                <div class="back-link">
                    Remember your credentials? <a href="${pageContext.request.contextPath}/user/login.jsp">Back to Login</a>
                </div>
            </form>
        </div>

        <!-- =================================================================
             STEP 2: 6-DIGIT OTP VERIFICATION (HORIZONTAL ROW)
             ================================================================= -->
        <div class="wizard-step" id="stepOtp" style="display:none;">
            <div class="alert-box error" id="alertOtp" style="display:none;">
                <i class="fa-solid fa-circle-exclamation"></i>
                <div class="alert-text" id="alertOtpText"></div>
            </div>

            <form id="formOtp" onsubmit="return false;">
                <div style="text-align:center; font-size: 13.5px; font-weight: 700; color: #334155; margin-bottom: 4px;">
                    <i class="fa-solid fa-shield-halved" style="color: #F97316;"></i> Enter 6-Digit OTP
                </div>
                
                <!-- 6 Individual Digit Boxes in a Flex Row -->
                <div class="otp-container" id="otpBoxContainer">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*" autocomplete="one-time-code" autofocus>
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*">
                </div>

                <div class="otp-meta-row">
                    <button type="button" class="btn-link-action" id="btnChangeEmail">
                        <i class="fa-solid fa-arrow-left"></i> Change Email
                    </button>
                    <button type="button" class="btn-link-action" id="btnResendOtp" disabled>
                        Resend in <span id="resendCountdown">60</span>s
                    </button>
                </div>

                <button type="button" class="btn-submit" id="btnVerifyOtp" style="margin-top:22px;">
                    <i class="fa-solid fa-shield-check"></i>
                    <span>Verify & Continue</span>
                </button>
            </form>
        </div>

        <!-- =================================================================
             STEP 3: NEW PASSWORD & CONFIRM PASSWORD
             ================================================================= -->
        <div class="wizard-step" id="stepNewPassword" style="display:none;">
            <div class="alert-box error" id="alertPassword" style="display:none;">
                <i class="fa-solid fa-circle-exclamation"></i>
                <div class="alert-text" id="alertPasswordText"></div>
            </div>

            <form id="formPassword" onsubmit="return false;">
                <!-- New Password Field -->
                <div class="form-group">
                    <label for="inputNewPass"><i class="fa-solid fa-lock"></i> New Password</label>
                    <div class="input-container">
                        <input type="password" id="inputNewPass" placeholder="Enter new password (8-12 chars)" autocomplete="new-password">
                        <button type="button" class="btn-toggle-eye" data-target="inputNewPass" title="Show/Hide Password">
                            <i class="fa-solid fa-eye"></i>
                        </button>
                    </div>
                </div>

                <!-- Confirm Password Field -->
                <div class="form-group">
                    <label for="inputConfirmPass"><i class="fa-solid fa-circle-check"></i> Confirm New Password</label>
                    <div class="input-container">
                        <input type="password" id="inputConfirmPass" placeholder="Confirm new password" autocomplete="new-password">
                        <button type="button" class="btn-toggle-eye" data-target="inputConfirmPass" title="Show/Hide Password">
                            <i class="fa-solid fa-eye"></i>
                        </button>
                    </div>
                </div>

                <!-- Live Password Criteria Checklist -->
                <div class="pwd-rules-card">
                    <div class="rules-title">
                        <i class="fa-solid fa-list-check" style="color: #F97316;"></i> Password Requirements:
                    </div>
                    <div class="rules-grid">
                        <div class="rule-item" id="ruleLength">
                            <i class="fa-regular fa-circle"></i> <span>8 – 12 characters</span>
                        </div>
                        <div class="rule-item" id="ruleUpper">
                            <i class="fa-regular fa-circle"></i> <span>1 uppercase (A-Z)</span>
                        </div>
                        <div class="rule-item" id="ruleLower">
                            <i class="fa-regular fa-circle"></i> <span>1 lowercase (a-z)</span>
                        </div>
                        <div class="rule-item" id="ruleDigit">
                            <i class="fa-regular fa-circle"></i> <span>1 number (0-9)</span>
                        </div>
                        <div class="rule-item" id="ruleSpecial">
                            <i class="fa-regular fa-circle"></i> <span>1 symbol (!@#$...)</span>
                        </div>
                        <div class="rule-item" id="ruleMatch">
                            <i class="fa-regular fa-circle"></i> <span>Passwords match</span>
                        </div>
                    </div>
                </div>

                <button type="button" class="btn-submit" id="btnResetPassword">
                    <i class="fa-solid fa-check-double"></i>
                    <span>Set New Password</span>
                </button>
            </form>
        </div>

        <!-- =================================================================
             STEP 4: SUCCESS VIEW & REDIRECT
             ================================================================= -->
        <div class="wizard-step" id="stepSuccess" style="display:none;">
            <div class="success-box">
                <div class="success-badge">
                    <i class="fa-solid fa-check"></i>
                </div>
                <h2>Password Reset Complete!</h2>
                <p class="subtitle" style="margin-top:8px;">Your motorist account password has been updated successfully. Redirecting you to login...</p>
                <a href="${pageContext.request.contextPath}/user/login.jsp?msg=password_reset_success" class="btn-submit" style="text-decoration:none;">
                    <i class="fa-solid fa-right-to-bracket"></i>
                    <span>Proceed to Login</span>
                </a>
            </div>
        </div>

    </div>

    <!-- Client-Side Form & Multi-Step Logic -->
    <script>
        (function() {
            var contextPath = "${pageContext.request.contextPath}";
            var endpointUrl = contextPath + "/auth/forgot-password";
            var userRole = "user";
            
            var currentEmail = "";
            var resendInterval = null;
            var countdownSec = 60;

            // DOM elements
            var stepEmail = document.getElementById("stepEmail");
            var stepOtp = document.getElementById("stepOtp");
            var stepNewPassword = document.getElementById("stepNewPassword");
            var stepSuccess = document.getElementById("stepSuccess");

            var nodeStep1 = document.getElementById("nodeStep1");
            var nodeStep2 = document.getElementById("nodeStep2");
            var nodeStep3 = document.getElementById("nodeStep3");
            var stepTracker = document.getElementById("stepTracker");

            var viewTitle = document.getElementById("viewTitle");
            var viewSubtitle = document.getElementById("viewSubtitle");
            var headerBadge = document.getElementById("headerBadge");

            var inputEmail = document.getElementById("inputEmail");
            var btnSendOtp = document.getElementById("btnSendOtp");
            var alertEmail = document.getElementById("alertEmail");
            var alertEmailText = document.getElementById("alertEmailText");

            var otpDigits = document.querySelectorAll(".otp-digit");
            var btnVerifyOtp = document.getElementById("btnVerifyOtp");
            var btnResendOtp = document.getElementById("btnResendOtp");
            var resendCountdown = document.getElementById("resendCountdown");
            var btnChangeEmail = document.getElementById("btnChangeEmail");
            var alertOtp = document.getElementById("alertOtp");
            var alertOtpText = document.getElementById("alertOtpText");

            var inputNewPass = document.getElementById("inputNewPass");
            var inputConfirmPass = document.getElementById("inputConfirmPass");
            var btnResetPassword = document.getElementById("btnResetPassword");
            var alertPassword = document.getElementById("alertPassword");
            var alertPasswordText = document.getElementById("alertPasswordText");

            // Checklist DOM items
            var ruleLength = document.getElementById("ruleLength");
            var ruleUpper = document.getElementById("ruleUpper");
            var ruleLower = document.getElementById("ruleLower");
            var ruleDigit = document.getElementById("ruleDigit");
            var ruleSpecial = document.getElementById("ruleSpecial");
            var ruleMatch = document.getElementById("ruleMatch");

            function showAlert(element, textElement, msg) {
                textElement.textContent = msg;
                element.style.display = "flex";
            }

            function hideAlert(element) {
                element.style.display = "none";
            }

            // =================================================================
            // 1. STEP 1: SEND OTP
            // =================================================================
            btnSendOtp.addEventListener("click", function() {
                hideAlert(alertEmail);
                var email = (inputEmail.value || "").trim().toLowerCase();

                if (!email) {
                    showAlert(alertEmail, alertEmailText, "Please enter your registered email address.");
                    inputEmail.focus();
                    return;
                }

                var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailPattern.test(email)) {
                    showAlert(alertEmail, alertEmailText, "Please enter a valid email address (e.g. motorist@example.com).");
                    inputEmail.focus();
                    return;
                }

                btnSendOtp.disabled = true;
                btnSendOtp.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Sending OTP...</span>';

                var params = new URLSearchParams();
                params.append("action", "send_otp");
                params.append("role", userRole);
                params.append("email", email);

                fetch(endpointUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    btnSendOtp.disabled = false;
                    btnSendOtp.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Send Verification OTP</span>';

                    if (data.success) {
                        currentEmail = email;
                        goToOtpStep(email);
                    } else {
                        showAlert(alertEmail, alertEmailText, data.message || "Failed to process request. Please check your email.");
                    }
                })
                .catch(function(err) {
                    btnSendOtp.disabled = false;
                    btnSendOtp.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Send Verification OTP</span>';
                    showAlert(alertEmail, alertEmailText, "Server communication error. Please try again.");
                });
            });

            inputEmail.addEventListener("keypress", function(e) {
                if (e.key === "Enter") {
                    e.preventDefault();
                    btnSendOtp.click();
                }
            });

            function goToOtpStep(email) {
                stepEmail.style.display = "none";
                stepOtp.style.display = "block";

                nodeStep1.classList.remove("active");
                nodeStep1.classList.add("completed");
                nodeStep1.innerHTML = '<i class="fa-solid fa-check"></i>';
                nodeStep2.classList.add("active");

                viewTitle.textContent = "Enter Verification Code";
                viewSubtitle.innerHTML = 'A 6-digit OTP code has been sent to <span class="email-highlight">' + escapeHtml(email) + '</span>. Enter the code to continue.';

                otpDigits.forEach(function(d) { d.value = ""; });
                if (otpDigits[0]) otpDigits[0].focus();

                startResendTimer();
            }

            function escapeHtml(text) {
                var div = document.createElement("div");
                div.innerText = text;
                return div.innerHTML;
            }

            // =================================================================
            // 2. STEP 2: OTP AUTO-JUMP, PASTE & VERIFICATION
            // =================================================================
            otpDigits.forEach(function(digit, index) {
                digit.addEventListener("input", function(e) {
                    var val = this.value.replace(/[^0-9]/g, "");
                    this.value = val ? val.charAt(0) : "";

                    if (this.value && index < otpDigits.length - 1) {
                        otpDigits[index + 1].focus();
                    }

                    // Auto-submit if all 6 filled
                    var completeCode = getFullOtpCode();
                    if (completeCode.length === 6) {
                        btnVerifyOtp.click();
                    }
                });

                digit.addEventListener("keydown", function(e) {
                    if (e.key === "Backspace" && !this.value && index > 0) {
                        otpDigits[index - 1].focus();
                    }
                });

                digit.addEventListener("paste", function(e) {
                    e.preventDefault();
                    var pasteData = (e.clipboardData || window.clipboardData).getData("text") || "";
                    pasteData = pasteData.replace(/[^0-9]/g, "").slice(0, 6);
                    if (pasteData) {
                        for (var i = 0; i < pasteData.length && i < otpDigits.length; i++) {
                            otpDigits[i].value = pasteData.charAt(i);
                        }
                        var nextFocus = Math.min(pasteData.length, otpDigits.length - 1);
                        otpDigits[nextFocus].focus();

                        if (pasteData.length === 6) {
                            btnVerifyOtp.click();
                        }
                    }
                });
            });

            function getFullOtpCode() {
                var code = "";
                otpDigits.forEach(function(d) { code += (d.value || ""); });
                return code;
            }

            btnVerifyOtp.addEventListener("click", function() {
                hideAlert(alertOtp);
                var otp = getFullOtpCode();

                if (otp.length < 6) {
                    showAlert(alertOtp, alertOtpText, "Please enter all 6 digits of your OTP code.");
                    return;
                }

                btnVerifyOtp.disabled = true;
                btnVerifyOtp.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Verifying Code...</span>';

                var params = new URLSearchParams();
                params.append("action", "verify_otp");
                params.append("role", userRole);
                params.append("email", currentEmail);
                params.append("otp", otp);

                fetch(endpointUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    btnVerifyOtp.disabled = false;
                    btnVerifyOtp.innerHTML = '<i class="fa-solid fa-shield-check"></i> <span>Verify & Continue</span>';

                    if (data.success) {
                        goToPasswordStep();
                    } else {
                        showAlert(alertOtp, alertOtpText, data.message || "Invalid or expired OTP. Please verify and try again.");
                        otpDigits[0].focus();
                    }
                })
                .catch(function(err) {
                    btnVerifyOtp.disabled = false;
                    btnVerifyOtp.innerHTML = '<i class="fa-solid fa-shield-check"></i> <span>Verify & Continue</span>';
                    showAlert(alertOtp, alertOtpText, "Verification error. Please try again.");
                });
            });

            btnChangeEmail.addEventListener("click", function() {
                clearInterval(resendInterval);
                hideAlert(alertOtp);
                hideAlert(alertEmail);

                stepOtp.style.display = "none";
                stepEmail.style.display = "block";

                nodeStep1.classList.remove("completed");
                nodeStep1.classList.add("active");
                nodeStep1.textContent = "1";
                nodeStep2.classList.remove("active");

                viewTitle.textContent = "Reset Password";
                viewSubtitle.textContent = "Enter your registered email address to receive verification OTP instructions.";

                inputEmail.focus();
            });

            function startResendTimer() {
                clearInterval(resendInterval);
                countdownSec = 60;
                btnResendOtp.disabled = true;
                resendCountdown.textContent = countdownSec;

                resendInterval = setInterval(function() {
                    countdownSec--;
                    if (countdownSec <= 0) {
                        clearInterval(resendInterval);
                        btnResendOtp.disabled = false;
                        btnResendOtp.innerHTML = '<i class="fa-solid fa-rotate-right"></i> Resend OTP';
                    } else {
                        resendCountdown.textContent = countdownSec;
                    }
                }, 1000);
            }

            btnResendOtp.addEventListener("click", function() {
                if (btnResendOtp.disabled) return;
                hideAlert(alertOtp);

                btnResendOtp.disabled = true;
                btnResendOtp.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Resending...';

                var params = new URLSearchParams();
                params.append("action", "resend_otp");
                params.append("role", userRole);
                params.append("email", currentEmail);

                fetch(endpointUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (data.success) {
                        btnResendOtp.innerHTML = 'Resend in <span id="resendCountdown">60</span>s';
                        resendCountdown = document.getElementById("resendCountdown");
                        startResendTimer();
                        otpDigits.forEach(function(d) { d.value = ""; });
                        otpDigits[0].focus();
                    } else {
                        btnResendOtp.disabled = false;
                        btnResendOtp.innerHTML = '<i class="fa-solid fa-rotate-right"></i> Resend OTP';
                        showAlert(alertOtp, alertOtpText, data.message || "Failed to resend OTP.");
                    }
                })
                .catch(function(err) {
                    btnResendOtp.disabled = false;
                    btnResendOtp.innerHTML = '<i class="fa-solid fa-rotate-right"></i> Resend OTP';
                    showAlert(alertOtp, alertOtpText, "Network error. Please try again.");
                });
            });

            // =================================================================
            // 3. STEP 3: NEW PASSWORD & CONFIRM PASSWORD
            // =================================================================
            function goToPasswordStep() {
                stepOtp.style.display = "none";
                stepNewPassword.style.display = "block";

                nodeStep2.classList.remove("active");
                nodeStep2.classList.add("completed");
                nodeStep2.innerHTML = '<i class="fa-solid fa-check"></i>';
                nodeStep3.classList.add("active");

                viewTitle.textContent = "Create New Password";
                viewSubtitle.textContent = "Set a secure password for your motorist account adhering to our security criteria.";

                inputNewPass.focus();
                validateCriteria();
            }

            function validateCriteria() {
                var p = inputNewPass.value || "";
                var cp = inputConfirmPass.value || "";

                // 1. Length (8 - 12)
                var validLength = p.length >= 8 && p.length <= 12;
                toggleRule(ruleLength, validLength);

                // 2. Uppercase (A-Z)
                var validUpper = /[A-Z]/.test(p);
                toggleRule(ruleUpper, validUpper);

                // 3. Lowercase (a-z)
                var validLower = /[a-z]/.test(p);
                toggleRule(ruleLower, validLower);

                // 4. Number (0-9)
                var validDigit = /[0-9]/.test(p);
                toggleRule(ruleDigit, validDigit);

                // 5. Special Symbol (!@#$%...)
                var validSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(p);
                toggleRule(ruleSpecial, validSpecial);

                // 6. Match
                var validMatch = (p.length > 0 && p === cp);
                toggleRule(ruleMatch, validMatch);

                var allValid = validLength && validUpper && validLower && validDigit && validSpecial && validMatch;
                return allValid;
            }

            function toggleRule(ruleEl, isValid) {
                var icon = ruleEl.querySelector("i");
                if (isValid) {
                    ruleEl.classList.add("valid");
                    icon.className = "fa-solid fa-circle-check";
                } else {
                    ruleEl.classList.remove("valid");
                    icon.className = "fa-regular fa-circle";
                }
            }

            inputNewPass.addEventListener("input", validateCriteria);
            inputConfirmPass.addEventListener("input", validateCriteria);

            // Toggle Eye Buttons
            document.querySelectorAll(".btn-toggle-eye").forEach(function(btn) {
                btn.addEventListener("click", function() {
                    var targetId = this.getAttribute("data-target");
                    var inp = document.getElementById(targetId);
                    var icon = this.querySelector("i");
                    if (inp.type === "password") {
                        inp.type = "text";
                        icon.className = "fa-solid fa-eye-slash";
                    } else {
                        inp.type = "password";
                        icon.className = "fa-solid fa-eye";
                    }
                });
            });

            btnResetPassword.addEventListener("click", function() {
                hideAlert(alertPassword);
                var p = (inputNewPass.value || "").trim();
                var cp = (inputConfirmPass.value || "").trim();

                if (!p || !cp) {
                    showAlert(alertPassword, alertPasswordText, "Please fill in both password fields.");
                    return;
                }

                if (p !== cp) {
                    showAlert(alertPassword, alertPasswordText, "New Password and Confirm Password do not match.");
                    return;
                }

                if (p.length < 8 || p.length > 12) {
                    showAlert(alertPassword, alertPasswordText, "Password length must be between 8 and 12 characters.");
                    return;
                }

                if (!/[A-Z]/.test(p)) {
                    showAlert(alertPassword, alertPasswordText, "Password must contain at least one uppercase letter (A-Z).");
                    return;
                }

                if (!/[a-z]/.test(p)) {
                    showAlert(alertPassword, alertPasswordText, "Password must contain at least one lowercase letter (a-z).");
                    return;
                }

                if (!/[0-9]/.test(p)) {
                    showAlert(alertPassword, alertPasswordText, "Password must contain at least one numeric digit (0-9).");
                    return;
                }

                if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(p)) {
                    showAlert(alertPassword, alertPasswordText, "Password must contain at least one special symbol (!@#$%...).");
                    return;
                }

                btnResetPassword.disabled = true;
                btnResetPassword.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Updating Password...</span>';

                var params = new URLSearchParams();
                params.append("action", "reset_password");
                params.append("role", userRole);
                params.append("email", currentEmail);
                params.append("newPassword", p);
                params.append("confirmPassword", cp);

                fetch(endpointUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    btnResetPassword.disabled = false;
                    btnResetPassword.innerHTML = '<i class="fa-solid fa-check-double"></i> <span>Set New Password</span>';

                    if (data.success) {
                        goToSuccessView(data.redirect || (contextPath + "/user/login.jsp?msg=password_reset_success"));
                    } else {
                        showAlert(alertPassword, alertPasswordText, data.message || "Failed to reset password.");
                    }
                })
                .catch(function(err) {
                    btnResetPassword.disabled = false;
                    btnResetPassword.innerHTML = '<i class="fa-solid fa-check-double"></i> <span>Set New Password</span>';
                    showAlert(alertPassword, alertPasswordText, "An unexpected error occurred. Please try again.");
                });
            });

            function goToSuccessView(redirectUrl) {
                stepNewPassword.style.display = "none";
                stepTracker.style.display = "none";
                viewTitle.style.display = "none";
                viewSubtitle.style.display = "none";
                headerBadge.style.display = "none";

                stepSuccess.style.display = "block";

                setTimeout(function() {
                    window.location.href = redirectUrl;
                }, 2500);
            }

        })();
    </script>
</body>
</html>
