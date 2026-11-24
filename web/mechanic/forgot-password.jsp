<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mechanic Password Recovery — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-forgot-password.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
</head>
<body>

    <!-- Top Navigation Header -->
    <nav class="top-nav">
        <a href="${pageContext.request.contextPath}/mechanic/login.jsp" class="btn-back-home" title="Back to Mechanic Login">
            <i class="fa-solid fa-arrow-left"></i>
            <span>Back to Login</span>
        </a>
    </nav>

    <!-- Main Recovery Card Container -->
    <div class="recovery-card" id="recoveryCard">
        
        <!-- Animated Key Icon -->
        <div class="badge-icon" id="headerBadge">
            <i class="fa-solid fa-key"></i>
        </div>

        <h2 id="viewTitle">Reset Password</h2>
        <p class="subtitle" id="viewSubtitle">Enter your registered workshop email address and we'll send you verification instructions to reset your password.</p>

        <!-- 3-Step Wizard Tracker -->
        <div class="step-tracker" id="stepTracker">
            <div class="step-node active" id="nodeStep1" title="Step 1: Workshop Email">1</div>
            <div class="step-node" id="nodeStep2" title="Step 2: Verify OTP">2</div>
            <div class="step-node" id="nodeStep3" title="Step 3: New Password">3</div>
        </div>

        <!-- =================================================================
             STEP 1: WORKSHOP EMAIL LOOKUP & OTP DISPATCH
             ================================================================= -->
        <div class="wizard-step" id="stepEmail">
            <div class="alert-box error" id="alertEmail" style="display:none;">
                <i class="fa-solid fa-circle-exclamation"></i>
                <div class="alert-text" id="alertEmailText"></div>
            </div>

            <form id="formEmail" onsubmit="return false;">
                <div class="form-group">
                    <label for="inputEmail"><i class="fa-solid fa-envelope"></i> Workshop Email Address</label>
                    <div class="input-container">
                        <input type="email" id="inputEmail" placeholder="e.g. workshop@mechanic.com" required autocomplete="email">
                    </div>
                </div>

                <button type="button" class="btn-submit" id="btnSendOtp">
                    <i class="fa-solid fa-paper-plane"></i>
                    <span>Send Verification OTP</span>
                </button>

                <div class="back-link">
                    Remember your workshop credentials? <a href="${pageContext.request.contextPath}/mechanic/login.jsp">Back to Login</a>
                </div>
            </form>
        </div>

        <!-- =================================================================
             STEP 2: 6-DIGIT OTP VERIFICATION
             ================================================================= -->
        <div class="wizard-step" id="stepOtp" style="display:none;">
            <div class="alert-box error" id="alertOtp" style="display:none;">
                <i class="fa-solid fa-circle-exclamation"></i>
                <div class="alert-text" id="alertOtpText"></div>
            </div>

            <form id="formOtp" onsubmit="return false;">
                <label style="text-align:center;"><i class="fa-solid fa-shield-halved"></i> Enter 6-Digit OTP</label>
                
                <!-- 6 Individual Digit Boxes with Auto-Jump -->
                <div class="otp-container" id="otpBoxContainer">
                    <input type="text" maxlength="1" class="otp-digit" inputmode="numeric" pattern="[0-9]*" autocomplete="one-time-code">
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
                        <i class="fa-solid fa-list-check"></i> Password Requirements:
                    </div>
                    <div class="rules-grid">
                        <div class="rule-item" id="ruleLength">
                            <i class="fa-regular fa-circle"></i> 8 – 12 characters
                        </div>
                        <div class="rule-item" id="ruleUpper">
                            <i class="fa-regular fa-circle"></i> 1 uppercase (A-Z)
                        </div>
                        <div class="rule-item" id="ruleLower">
                            <i class="fa-regular fa-circle"></i> 1 lowercase (a-z)
                        </div>
                        <div class="rule-item" id="ruleDigit">
                            <i class="fa-regular fa-circle"></i> 1 number (0-9)
                        </div>
                        <div class="rule-item" id="ruleSpecial">
                            <i class="fa-regular fa-circle"></i> 1 symbol (!@#$...)
                        </div>
                        <div class="rule-item" id="ruleMatch">
                            <i class="fa-regular fa-circle"></i> Passwords match
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
                <p class="subtitle" style="margin-top:8px;">Your workshop partner password has been updated successfully. Redirecting you to login...</p>
                <a href="${pageContext.request.contextPath}/mechanic/login.jsp?msg=password_reset_success" class="btn-submit" style="text-decoration:none;">
                    <i class="fa-solid fa-right-to-bracket"></i>
                    <span>Proceed to Login</span>
                </a>
            </div>
        </div>

    </div>

    <!-- JavaScript Controller -->
    <script>
        (function() {
            var contextPath = "${pageContext.request.contextPath}";
            var endpointUrl = contextPath + "/auth/forgot-password";
            var userRole = "mechanic";
            
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
                var email = (inputEmail.value || "").trim();
                hideAlert(alertEmail);

                if (!email) {
                    showAlert(alertEmail, alertEmailText, "Please enter your registered workshop email address.");
                    inputEmail.focus();
                    return;
                }

                // Check basic email syntax
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
                    showAlert(alertEmail, alertEmailText, "Please enter a valid email address format.");
                    inputEmail.focus();
                    return;
                }

                btnSendOtp.disabled = true;
                btnSendOtp.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Verifying Workshop...</span>';

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
                        goToStep2();
                    } else {
                        showAlert(alertEmail, alertEmailText, data.message || "Workshop email could not be verified.");
                    }
                })
                .catch(function(err) {
                    btnSendOtp.disabled = false;
                    btnSendOtp.innerHTML = '<i class="fa-solid fa-paper-plane"></i> <span>Send Verification OTP</span>';
                    showAlert(alertEmail, alertEmailText, "Network error occurred. Please try again.");
                });
            });

            // Trigger submit on Enter in email field
            inputEmail.addEventListener("keypress", function(e) {
                if (e.key === "Enter") {
                    e.preventDefault();
                    btnSendOtp.click();
                }
            });

            function goToStep2() {
                stepEmail.style.display = "none";
                stepOtp.style.display = "block";
                stepNewPassword.style.display = "none";

                nodeStep1.className = "step-node completed";
                nodeStep1.innerHTML = '<i class="fa-solid fa-check"></i>';
                nodeStep2.className = "step-node active";
                nodeStep3.className = "step-node";

                viewTitle.textContent = "Verify OTP";
                viewSubtitle.innerHTML = 'Enter the 6-digit code sent to <span class="email-highlight">' + escapeHtml(currentEmail) + '</span>';

                // Clear OTP boxes
                otpDigits.forEach(function(d) { d.value = ""; });
                if (otpDigits.length > 0) otpDigits[0].focus();

                startResendTimer();
            }

            function escapeHtml(str) {
                var div = document.createElement("div");
                div.textContent = str;
                return div.innerHTML;
            }

            // =================================================================
            // 2. STEP 2: OTP DIGIT HANDLING & VERIFY
            // =================================================================
            otpDigits.forEach(function(digit, idx) {
                digit.addEventListener("input", function(e) {
                    var val = this.value.replace(/[^0-9]/g, "");
                    this.value = val ? val.charAt(val.length - 1) : "";
                    if (this.value && idx < otpDigits.length - 1) {
                        otpDigits[idx + 1].focus();
                    }
                });

                digit.addEventListener("keydown", function(e) {
                    if (e.key === "Backspace" && !this.value && idx > 0) {
                        otpDigits[idx - 1].focus();
                    } else if (e.key === "Enter") {
                        btnVerifyOtp.click();
                    }
                });

                digit.addEventListener("paste", function(e) {
                    e.preventDefault();
                    var pasteData = (e.clipboardData || window.clipboardData).getData("text").trim();
                    var cleanData = pasteData.replace(/[^0-9]/g, "");
                    if (cleanData.length > 0) {
                        for (var i = 0; i < otpDigits.length; i++) {
                            if (i < cleanData.length) {
                                otpDigits[i].value = cleanData.charAt(i);
                            }
                        }
                        var nextIdx = Math.min(cleanData.length, otpDigits.length - 1);
                        otpDigits[nextIdx].focus();
                    }
                });
            });

            function getEnteredOtp() {
                var code = "";
                otpDigits.forEach(function(d) { code += (d.value || ""); });
                return code;
            }

            btnVerifyOtp.addEventListener("click", function() {
                var otp = getEnteredOtp();
                hideAlert(alertOtp);

                if (otp.length !== 6) {
                    showAlert(alertOtp, alertOtpText, "Please enter all 6 digits of the verification code.");
                    return;
                }

                btnVerifyOtp.disabled = true;
                btnVerifyOtp.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Verifying OTP...</span>';

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
                        clearInterval(resendInterval);
                        goToStep3();
                    } else {
                        showAlert(alertOtp, alertOtpText, data.message || "Invalid or expired OTP code.");
                    }
                })
                .catch(function(err) {
                    btnVerifyOtp.disabled = false;
                    btnVerifyOtp.innerHTML = '<i class="fa-solid fa-shield-check"></i> <span>Verify & Continue</span>';
                    showAlert(alertOtp, alertOtpText, "Network error. Please check your connection.");
                });
            });

            // Resend OTP Countdown
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
                        btnResendOtp.innerHTML = 'Resend in <span id="resendCountdown">' + countdownSec + '</span>s';
                    }
                }, 1000);
            }

            btnResendOtp.addEventListener("click", function() {
                if (btnResendOtp.disabled) return;
                hideAlert(alertOtp);

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
                        startResendTimer();
                        alertOtp.className = "alert-box success";
                        showAlert(alertOtp, alertOtpText, "A new OTP code has been sent to your email.");
                        setTimeout(function() { hideAlert(alertOtp); alertOtp.className = "alert-box error"; }, 4000);
                    } else {
                        showAlert(alertOtp, alertOtpText, data.message || "Could not resend OTP. Please try again.");
                    }
                });
            });

            btnChangeEmail.addEventListener("click", function() {
                clearInterval(resendInterval);
                stepOtp.style.display = "none";
                stepEmail.style.display = "block";
                nodeStep1.className = "step-node active";
                nodeStep1.textContent = "1";
                nodeStep2.className = "step-node";
                viewTitle.textContent = "Reset Password";
                viewSubtitle.textContent = "Enter your registered workshop email address and we'll send you verification instructions to reset your password.";
                hideAlert(alertOtp);
                inputEmail.focus();
            });

            // =================================================================
            // 3. STEP 3: NEW PASSWORD & CONFIRM PASSWORD
            // =================================================================
            function goToStep3() {
                stepOtp.style.display = "none";
                stepNewPassword.style.display = "block";

                nodeStep2.className = "step-node completed";
                nodeStep2.innerHTML = '<i class="fa-solid fa-check"></i>';
                nodeStep3.className = "step-node active";

                viewTitle.textContent = "Set New Password";
                viewSubtitle.textContent = "Please create a new password adhering to security requirements.";

                inputNewPass.value = "";
                inputConfirmPass.value = "";
                validateCriteria();
                inputNewPass.focus();
            }

            // Real-time criteria validation
            function updateRule(element, isValid) {
                if (isValid) {
                    element.classList.add("valid");
                    element.querySelector("i").className = "fa-solid fa-circle-check";
                } else {
                    element.classList.remove("valid");
                    element.querySelector("i").className = "fa-regular fa-circle";
                }
            }

            function validateCriteria() {
                var p = inputNewPass.value || "";
                var cp = inputConfirmPass.value || "";

                var hasLength = p.length >= 8 && p.length <= 12;
                var hasUpper = /[A-Z]/.test(p);
                var hasLower = /[a-z]/.test(p);
                var hasDigit = /[0-9]/.test(p);
                var hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(p);
                var isMatch = p.length > 0 && p === cp;

                updateRule(ruleLength, hasLength);
                updateRule(ruleUpper, hasUpper);
                updateRule(ruleLower, hasLower);
                updateRule(ruleDigit, hasDigit);
                updateRule(ruleSpecial, hasSpecial);
                updateRule(ruleMatch, isMatch);

                return hasLength && hasUpper && hasLower && hasDigit && hasSpecial && isMatch;
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
                        goToSuccessView(data.redirect || (contextPath + "/mechanic/login.jsp?msg=password_reset_success"));
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
