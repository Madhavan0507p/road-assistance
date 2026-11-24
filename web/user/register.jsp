<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%

    // Redirect already authenticated users to dashboard

    if (session.getAttribute("user") != null) {

        response.sendRedirect(request.getContextPath() + "/user/dashboard.jsp");

        return;

    }



    String errorMsg = request.getParameter("error");

    String successMsg = request.getParameter("msg");

%>

<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>User Registration — On Road Vehicle Breakdown Assistance</title>

    

    <!-- Google Fonts & Font Awesome Icons -->

    <link rel="preconnect" href="https://fonts.googleapis.com">

    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    

    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-register.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>

</head>

<body>



    <!-- Back Navigation to Move Backward -->

    <a href="javascript:void(0);" onclick="goBack()" class="back-nav-btn" id="btnGoBack" title="Go back to previous page">

        <i class="fa-solid fa-arrow-left"></i> <span>Back</span>

    </a>



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



    <!-- Main Responsive Two-Column Container -->

    <main class="user-reg-container">

        

        <!-- =================================================================

             1. LEFT SECTION (50% Width) — Branding, Title & 3 Feature Items

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

                    Create a<br><span class="title-highlight">New Account</span>

                </h1>

                <div class="intro-underline"></div>

            </div>



            <!-- Descriptive Paragraph -->

            <p class="intro-description">

                Register as a user to request roadside assistance, track services and manage your vehicles.

            </p>



            <!-- 3 Feature Items matching Reference Screenshot -->

            <div class="user-features-list">

                <!-- Feature 1: Request Instant Assistance -->

                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-car-side"></i>

                    </div>

                    <div class="feature-text-block">

                        <h3 class="feature-title">Request Instant Assistance</h3>

                        <span class="feature-desc">Get help for vehicle breakdowns anytime, anywhere.</span>

                    </div>

                </div>



                <!-- Feature 2: Track Your Requests -->

                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-location-dot"></i>

                    </div>

                    <div class="feature-text-block">

                        <h3 class="feature-title">Track Your Requests</h3>

                        <span class="feature-desc">Monitor real-time service updates and mechanic status.</span>

                    </div>

                </div>



                <!-- Feature 3: Manage Your Vehicles -->

                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-car"></i>

                    </div>

                    <div class="feature-text-block">

                        <h3 class="feature-title">Manage Your Vehicles</h3>

                        <span class="feature-desc">Add, view and update your vehicle details.</span>

                    </div>

                </div>

            </div>

        </section>



        <!-- =================================================================

             2. RIGHT SECTION (50% Width) — Crisp White Registration Form Card

             ================================================================= -->

        <section class="user-reg-card-col">

            <div class="user-reg-card">

                <!-- Top Center Orange Circular User-Plus Icon -->

                <div class="card-avatar-wrapper">

                    <div class="user-avatar-badge">

                        <i class="fa-solid fa-user-plus"></i>

                    </div>

                </div>



                <!-- Card Header -->

                <div class="card-header-center">

                    <h2 class="card-heading-title">User Registration</h2>

                    <p class="card-heading-subtitle">Create your account to get roadside assistance</p>

                </div>



                <!-- Flash Alert Box (if redirected with error/msg) -->

                <% if (errorMsg != null && !errorMsg.trim().isEmpty()) { %>

                    <div class="card-alert-box card-alert-error" id="serverAlertBox">

                        <i class="fa-solid fa-triangle-exclamation"></i>

                        <span><%= errorMsg %></span>

                    </div>

                <% } %>

                <% if (successMsg != null && !successMsg.trim().isEmpty()) { %>

                    <div class="card-alert-box card-alert-success" id="serverAlertBox">

                        <i class="fa-solid fa-circle-check"></i>

                        <span><%= successMsg %></span>

                    </div>

                <% } %>



                <!-- JavaScript Dynamic Alert Box -->

                <div class="card-alert-box card-alert-error" id="jsAlertBox" style="display: none;">

                    <i class="fa-solid fa-triangle-exclamation"></i>

                    <span id="jsAlertMessage"></span>

                </div>



                <!-- Registration Form -->

                <form action="${pageContext.request.contextPath}/auth/register-user" method="POST" id="userRegisterForm" novalidate>

                    

                    <!-- Row 1: First Name & Last Name (Characters Only) -->

                    <div class="form-grid-row">

                        <!-- First Name -->

                        <div class="form-field-group">

                            <label class="field-label" for="regFirstName">

                                <i class="fa-solid fa-user"></i> First Name <span class="required">*</span>

                            </label>

                            <div class="field-input-wrapper">

                                <input type="text" id="regFirstName" name="firstName" class="field-input" placeholder="Raj" required autocomplete="given-name" autofocus onkeydown="if(/[0-9]/.test(event.key)) event.preventDefault();" oninput="this.value = this.value.replace(/[0-9]/g, '');">

                            </div>

                            <div id="firstNameInstruction" class="field-instruction-msg"></div>

                        </div>



                        <!-- Last Name -->

                        <div class="form-field-group">

                            <label class="field-label" for="regLastName">

                                <i class="fa-solid fa-user"></i> Last Name <span class="required">*</span>

                            </label>

                            <div class="field-input-wrapper">

                                <input type="text" id="regLastName" name="lastName" class="field-input" placeholder="Kumar" required autocomplete="family-name" onkeydown="if(/[0-9]/.test(event.key)) event.preventDefault();" oninput="this.value = this.value.replace(/[0-9]/g, '');">

                            </div>

                            <div id="lastNameInstruction" class="field-instruction-msg"></div>

                        </div>

                    </div>



                    <!-- Row 2: Gender & Date of Birth (18+ Years Old) -->

                    <div class="form-grid-row">

                        <!-- Gender -->

                        <div class="form-field-group">

                            <label class="field-label" for="regGender">

                                <i class="fa-solid fa-venus-mars"></i> Gender <span class="required">*</span>

                            </label>

                            <div class="field-input-wrapper">

                                <select id="regGender" name="gender" class="field-select" required>
                                    
                                    <option value="" disabled selected>Select</option>

                                    <option value="Male">Male</option>

                                    <option value="Female">Female</option>

                                    <option value="Other">Other</option>

                                    <option value="Prefer not to say">Prefer not to say</option>

                                </select>

                            </div>

                            <div id="genderInstruction" class="field-instruction-msg"></div>

                        </div>



                        <!-- Date of Birth (18+ Years Old) -->

                        <div class="form-field-group">

                            <label class="field-label" for="regDob">

                                <i class="fa-solid fa-cake-candles"></i> Date of Birth <span class="required">*</span>

                            </label>

                            <div class="field-input-wrapper">

                                <input type="date" id="regDob" name="dob" class="field-input" required>

                            </div>

                            <div id="dobInstruction" class="field-instruction-msg"></div>

                        </div>

                    </div>



                    <!-- Row 3: Phone Number (10 Digits starting 6-9) -->

                    <div class="form-field-group">

                        <label class="field-label" for="regPhone">

                            <i class="fa-solid fa-phone"></i> Phone Number <span class="required">*</span>

                        </label>

                        <div class="field-input-wrapper">

                            <input type="tel" id="regPhone" name="phone" class="field-input" placeholder="Enter 10-digit mobile number" maxlength="10" required autocomplete="tel" inputmode="numeric">

                        </div>

                        <div id="phoneInstruction" class="field-instruction-msg"></div>

                    </div>



                    <!-- Row 3: Email Address with Send OTP / Verified Badge -->

                    <div class="form-field-group">

                        <label class="field-label" for="regEmail">

                            <i class="fa-solid fa-envelope"></i> Email Address <span class="required">*</span>

                        </label>

                        <div class="email-field-wrapper">

                            <input type="email" id="regEmail" name="email" class="field-input" placeholder="rajkumar@gmail.com" required autocomplete="email">

                            <button type="button" id="btnSendOtp" class="btn-send-otp" title="Send 6-digit OTP to your email">

                                <i class="fa-solid fa-paper-plane" id="sendOtpIcon"></i>

                                <span id="sendOtpText">Send OTP</span>

                            </button>

                            <span id="verifiedBadge" class="verified-badge" style="display: none;">

                                <i class="fa-solid fa-check"></i> Verified

                            </span>

                        </div>

                        <div id="emailInstruction" class="field-instruction-msg"></div>

                    </div>



                    <!-- Row 4: Email Verification (OTP) Box matching Reference Screenshot -->

                    <div class="otp-verification-box" id="otpBoxSection">

                        <div class="otp-box-header">

                            <div class="otp-shield-icon">

                                <i class="fa-solid fa-shield-halved"></i>

                            </div>

                            <div class="otp-header-text">

                                <h4 class="otp-title">Email Verification (OTP)</h4>

                                <p class="otp-subtitle">Enter the 6-digit OTP sent to <span id="otpTargetEmail" class="otp-target-email">your email</span></p>

                            </div>

                        </div>



                        <div class="otp-action-row">

                            <!-- 6 Individual Digit Boxes -->

                            <div class="otp-digits-wrapper" id="otpDigitsGroup">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="0" inputmode="numeric" pattern="[0-9]*" placeholder="•" autocomplete="one-time-code">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="1" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="2" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="3" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="4" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                <input type="text" maxlength="1" class="otp-digit-input" data-index="5" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                            </div>



                            <!-- Hidden input holding combined 6-digit OTP for submit -->

                            <input type="hidden" id="fullOtpCode" name="otp" value="">



                            <!-- Timer & Resend Button -->

                            <div class="otp-timer-action">

                                <span class="otp-timer-display" id="otpTimerWrapper">

                                    <i class="fa-regular fa-clock"></i>

                                    <span id="timerCountdown">00:00</span>

                                </span>

                                <button type="button" class="btn-resend-otp" id="btnResendOtp" disabled>

                                    Resend OTP

                                </button>

                            </div>

                        </div>



                        <!-- Feedback Message -->

                        <div id="otpFeedbackMsg" class="otp-feedback-msg" style="display: none;"></div>

                    </div>



                    <!-- Row 5: Password (8-12 chars: uppercase, lowercase, number, symbol) -->

                    <div class="form-field-group">

                        <label class="field-label" for="regPassword">

                            <i class="fa-solid fa-lock"></i> Password <span class="required">*</span>

                        </label>

                        <div class="password-field-wrapper">

                            <input type="password" id="regPassword" name="password" class="field-input" placeholder="Create password (8-12 characters)" maxlength="12" required autocomplete="new-password">

                            <button type="button" id="toggleRegPasswordBtn" class="password-toggle-btn" title="Toggle password visibility">

                                <i class="fa-regular fa-eye" id="toggleRegPassIcon"></i>

                            </button>

                        </div>

                        <div id="passwordInstruction" class="field-instruction-msg"></div>

                    </div>






                    <!-- Row 6: Submit Button "Create Account" -->

                    <button type="submit" class="btn-create-account" id="btnCreateAccount">

                        <i class="fa-solid fa-user-plus" id="createAccountIcon"></i>

                        <span id="createAccountText">Create Account</span>

                    </button>



                    <!-- Row 7: Footer Login Link -->

                    <div class="card-footer-login">

                        Already have an account?

                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="login-highlight-link">Login</a>

                    </div>

                </form>

            </div>

        </section>

    </main>



    <!-- Modal: Terms & Conditions -->

    <div class="info-modal" id="termsModal">

        <div class="modal-content-card">

            <div class="modal-header">

                <h3>Terms & Conditions</h3>

                <button type="button" class="modal-close-btn" onclick="closeModal('termsModal')">&times;</button>

            </div>

            <div class="modal-body">

                <p><strong>1. Roadside Assistance Service:</strong> By registering with On Road Vehicle Breakdown Assistance, you agree to provide accurate vehicle and breakdown information when requesting assistance.</p>

                <p><strong>2. Fair Usage:</strong> The platform facilitates emergency breakdown support, towing, tyre replacement, fuel delivery, and battery jumpstarts via verified mechanics.</p>

                <p><strong>3. Service Charges:</strong> Standard rates apply based on the specific assistance type and distance, displayed transparently before confirmation.</p>

                <p><strong>4. Account Security:</strong> You are responsible for maintaining the confidentiality of your credentials and OTP verification codes.</p>

            </div>

        </div>

    </div>



    <!-- Modal: Privacy Policy -->

    <div class="info-modal" id="privacyModal">

        <div class="modal-content-card">

            <div class="modal-header">

                <h3>Privacy Policy</h3>

                <button type="button" class="modal-close-btn" onclick="closeModal('privacyModal')">&times;</button>

            </div>

            <div class="modal-body">

                <p><strong>1. Data Collection:</strong> We collect your name, phone number, email address, and breakdown location solely to dispatch verified mechanics to your assistance.</p>

                <p><strong>2. No Third-Party Selling:</strong> We never sell, rent, or trade your personal contact details to third-party advertisers.</p>

                <p><strong>3. Secure Verification:</strong> All email and phone numbers are verified via encrypted one-time passwords (OTP).</p>

            </div>

        </div>

    </div>



    <!-- Interactive Client Script -->

    <script>

        // Global Back Navigation ("put back to move backward")

        function goBack() {

            if (window.history.length > 1 && document.referrer && document.referrer.indexOf(window.location.host) !== -1) {

                window.history.back();

            } else {

                window.location.href = '${pageContext.request.contextPath}/index.jsp';

            }

        }



        document.addEventListener('DOMContentLoaded', function () {

            const contextPath = '${pageContext.request.contextPath}';



            // Form Inputs & Error Containers

            const form = document.getElementById('userRegisterForm');

            const firstNameInput = document.getElementById('regFirstName');

            const firstNameInstruction = document.getElementById('firstNameInstruction');

            const lastNameInput = document.getElementById('regLastName');

            const lastNameInstruction = document.getElementById('lastNameInstruction');

            const genderSelect = document.getElementById('regGender');

            const genderInstruction = document.getElementById('genderInstruction');

            const dobInput = document.getElementById('regDob');

            const dobInstruction = document.getElementById('dobInstruction');

            const phoneInput = document.getElementById('regPhone');

            const phoneInstruction = document.getElementById('phoneInstruction');

            const emailInput = document.getElementById('regEmail');

            const emailInstruction = document.getElementById('emailInstruction');

            const passwordInput = document.getElementById('regPassword');

            const passwordInstruction = document.getElementById('passwordInstruction');

            const toggleRegPasswordBtn = document.getElementById('toggleRegPasswordBtn');

            const toggleRegPassIcon = document.getElementById('toggleRegPassIcon');

            const termsCheckbox = document.getElementById('regTerms');

            const createBtn = document.getElementById('btnCreateAccount');

            const createIcon = document.getElementById('createAccountIcon');

            const createText = document.getElementById('createAccountText');



            // OTP Elements

            const btnSendOtp = document.getElementById('btnSendOtp');

            const sendOtpIcon = document.getElementById('sendOtpIcon');

            const sendOtpText = document.getElementById('sendOtpText');

            const verifiedBadge = document.getElementById('verifiedBadge');

            const otpBoxSection = document.getElementById('otpBoxSection');

            const otpTargetEmail = document.getElementById('otpTargetEmail');

            const otpDigits = Array.from(document.querySelectorAll('.otp-digit-input'));

            const fullOtpHidden = document.getElementById('fullOtpCode');

            const timerCountdown = document.getElementById('timerCountdown');

            const btnResendOtp = document.getElementById('btnResendOtp');

            const otpFeedback = document.getElementById('otpFeedbackMsg');

            const jsAlertBox = document.getElementById('jsAlertBox');

            const jsAlertMessage = document.getElementById('jsAlertMessage');



            let timerInterval = null;

            let secondsRemaining = 47;

            let isEmailVerified = false;



            // Show custom alert banner

            function showAlert(msg, isSuccess) {

                if (!jsAlertBox) return;

                jsAlertBox.style.display = 'flex';

                jsAlertBox.className = 'card-alert-box ' + (isSuccess ? 'card-alert-success' : 'card-alert-error');

                jsAlertBox.querySelector('i').className = isSuccess ? 'fa-solid fa-circle-check' : 'fa-solid fa-triangle-exclamation';

                jsAlertMessage.textContent = msg;

                jsAlertBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

            }



            function hideAlert() {

                if (jsAlertBox) jsAlertBox.style.display = 'none';

            }



            function showOtpFeedback(msg, isSuccess) {

                if (!otpFeedback) return;

                otpFeedback.style.display = 'flex';

                otpFeedback.className = 'otp-feedback-msg ' + (isSuccess ? 'otp-msg-success' : 'otp-msg-error');

                otpFeedback.innerHTML = (isSuccess ? '<i class="fa-solid fa-check"></i> ' : '<i class="fa-solid fa-circle-exclamation"></i> ') + msg;

            }



            function hideOtpFeedback() {

                if (otpFeedback) otpFeedback.style.display = 'none';

            }



            // Visual Glow and Instruction Helpers

            function setFieldInvalid(inputEl, msgEl, text) {

                inputEl.classList.remove('glow-valid');

                inputEl.classList.add('glow-invalid');

                if (msgEl) {

                    msgEl.className = 'field-instruction-msg show-error';

                    msgEl.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> ' + text;

                }

            }



            function setFieldValid(inputEl, msgEl, optionalSuccessText) {

                inputEl.classList.remove('glow-invalid');

                inputEl.classList.add('glow-valid');

                if (msgEl) {

                    if (optionalSuccessText) {

                        msgEl.className = 'field-instruction-msg show-valid';

                        msgEl.innerHTML = '<i class="fa-solid fa-circle-check"></i> ' + optionalSuccessText;

                    } else {

                        msgEl.className = 'field-instruction-msg';

                        msgEl.style.display = 'none';

                        msgEl.innerHTML = '';

                    }

                }

            }



            // Block numbers from being typed or pasted into name fields

            function blockNumericKey(e) {

                if (e.key && /^[0-9]$/.test(e.key)) {

                    e.preventDefault();

                    return false;

                }

            }



            function filterNumbersOnPaste(e) {

                const text = (e.clipboardData || window.clipboardData).getData('text');

                if (/[0-9]/.test(text)) {

                    e.preventDefault();

                    const filtered = text.replace(/[0-9]/g, '');

                    document.execCommand('insertText', false, filtered);

                }

            }



            firstNameInput.addEventListener('keydown', blockNumericKey);

            firstNameInput.addEventListener('paste', filterNumbersOnPaste);



            lastNameInput.addEventListener('keydown', blockNumericKey);

            lastNameInput.addEventListener('paste', filterNumbersOnPaste);



            // 1. First Name Validator (Characters only, strictly no numbers or symbols)

            function validateFirstName() {

                if (/[0-9]/.test(firstNameInput.value)) {

                    firstNameInput.value = firstNameInput.value.replace(/[0-9]/g, '');

                }

                const val = firstNameInput.value.trim();

                if (!val) {

                    setFieldInvalid(firstNameInput, firstNameInstruction, 'First name is required (letters only).');

                    return false;

                }

                if (/[^A-Za-z\s]/.test(val)) {

                    setFieldInvalid(firstNameInput, firstNameInstruction, 'First name must contain letters only (no symbols).');

                    return false;

                }

                if (val.length < 2) {

                    setFieldInvalid(firstNameInput, firstNameInstruction, 'First name must be at least 2 characters long.');

                    return false;

                }

                setFieldValid(firstNameInput, firstNameInstruction);

                return true;

            }



            // 2. Last Name Validator (Characters only, strictly no numbers or symbols)

            function validateLastName() {

                if (/[0-9]/.test(lastNameInput.value)) {

                    lastNameInput.value = lastNameInput.value.replace(/[0-9]/g, '');

                }

                const val = lastNameInput.value.trim();

                if (!val) {

                    setFieldInvalid(lastNameInput, lastNameInstruction, 'Last name is required (letters only).');

                    return false;

                }

                if (/[^A-Za-z\s]/.test(val)) {

                    setFieldInvalid(lastNameInput, lastNameInstruction, 'Last name must contain letters only (no symbols).');

                    return false;

                }

                setFieldValid(lastNameInput, lastNameInstruction);
                return true;
            }

            // Gender Validator
            function validateGender() {
                if (!genderSelect) return true;
                const val = genderSelect.value;
                if (!val || val.trim() === '' || val.toLowerCase() === 'select') {
                    setFieldInvalid(genderSelect, genderInstruction, 'Gender is required. Please select an option.');
                    return false;
                }
                setFieldValid(genderSelect, genderInstruction);
                return true;
            }

            if (genderSelect) {
                genderSelect.addEventListener('change', validateGender);
                genderSelect.addEventListener('blur', validateGender);
            }



            // Set Date of Birth constraints: must be at least 18 years old

            const today = new Date();

            const maxYear = today.getFullYear() - 18;

            const monthStr = String(today.getMonth() + 1).padStart(2, '0');

            const dayStr = String(today.getDate()).padStart(2, '0');

            const maxDobString = maxYear + '-' + monthStr + '-' + dayStr;



            if (dobInput) {

                dobInput.setAttribute('max', maxDobString);

                dobInput.setAttribute('min', '1920-01-01');

            }



            // Date of Birth Validator (Strict 18+ enforcement)

            function validateDob() {

                if (!dobInput) return true;

                const val = dobInput.value;

                if (!val) {

                    setFieldInvalid(dobInput, dobInstruction, 'Date of birth is required.');

                    return false;

                }



                const birthDate = new Date(val);

                if (isNaN(birthDate.getTime())) {

                    setFieldInvalid(dobInput, dobInstruction, 'Please select a valid date of birth.');

                    return false;

                }



                const todayDate = new Date();

                if (birthDate > todayDate) {

                    setFieldInvalid(dobInput, dobInstruction, 'Date of birth cannot be in the future.');

                    return false;

                }



                let age = todayDate.getFullYear() - birthDate.getFullYear();

                const m = todayDate.getMonth() - birthDate.getMonth();

                if (m < 0 || (m === 0 && todayDate.getDate() < birthDate.getDate())) {

                    age--;

                }



                if (age < 18) {

                    setFieldInvalid(dobInput, dobInstruction, 'You must be at least 18 years old to create an account (age: ' + age + ').');

                    return false;

                }



                if (age > 120) {

                    setFieldInvalid(dobInput, dobInstruction, 'Please enter a realistic date of birth.');

                    return false;

                }



                setFieldValid(dobInput, dobInstruction, 'Eligible (Age: ' + age + ' years)');

                return true;

            }



            // 3. Phone Number Validator (10 digits starting with 6-9, strictly NO +91)

            function validatePhone() {

                // Strip non-digits and cap at exactly 10 digits

                let val = phoneInput.value.replace(/\D/g, '');

                if (val.length > 10) val = val.substring(0, 10);

                phoneInput.value = val;



                if (!val) {

                    setFieldInvalid(phoneInput, phoneInstruction, 'Phone number is required (10 digits).');

                    return false;

                }

                if (!/^[6-9]/.test(val)) {

                    setFieldInvalid(phoneInput, phoneInstruction, 'Phone number must start with 6, 7, 8, or 9.');

                    return false;

                }

                if (val.length < 10) {

                    setFieldInvalid(phoneInput, phoneInstruction, 'Phone number must be exactly 10 digits (' + val.length + '/10 entered).');

                    return false;

                }

                if (/^[6-9][0-9]{9}$/.test(val)) {

                    setFieldValid(phoneInput, phoneInstruction);

                    return true;

                }

                setFieldInvalid(phoneInput, phoneInstruction, 'Please enter a valid 10-digit mobile number.');

                return false;

            }



            // 4. Password Validator (8-12 chars: uppercase, lowercase, number, symbol)

            function validatePassword() {

                const val = passwordInput.value;

                if (!val) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password is required (8-12 characters).');

                    return false;

                }

                if (val.length < 8 || val.length > 12) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password must be 8 to 12 characters (currently ' + val.length + ').');

                    return false;

                }

                if (!/[A-Z]/.test(val)) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password must include at least 1 uppercase letter (A-Z).');

                    return false;

                }

                if (!/[a-z]/.test(val)) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password must include at least 1 lowercase letter (a-z).');

                    return false;

                }

                if (!/[0-9]/.test(val)) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password must include at least 1 number (0-9).');

                    return false;

                }

                if (!/[!@#$%^&*(),.?":{}|<>\-_=+]/.test(val)) {

                    setFieldInvalid(passwordInput, passwordInstruction, 'Password must include at least 1 special symbol (!@#$%^&* etc.).');

                    return false;

                }

                setFieldValid(passwordInput, passwordInstruction, 'Strong password');

                return true;

            }



            // 5. Email Validator

            function validateEmail() {

                const val = emailInput.value.trim().toLowerCase();

                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

                if (!val) {

                    setFieldInvalid(emailInput, emailInstruction, 'Email address is required.');

                    return false;

                }

                if (!emailRegex.test(val)) {

                    setFieldInvalid(emailInput, emailInstruction, 'Please enter a valid email address (e.g. name@domain.com).');

                    return false;

                }

                setFieldValid(emailInput, emailInstruction);

                return true;

            }



            // Real-time Event Listeners

            firstNameInput.addEventListener('input', validateFirstName);

            firstNameInput.addEventListener('blur', validateFirstName);



            lastNameInput.addEventListener('input', validateLastName);

            lastNameInput.addEventListener('blur', validateLastName);



            if (dobInput) {

                dobInput.addEventListener('change', validateDob);

                dobInput.addEventListener('input', validateDob);

                dobInput.addEventListener('blur', validateDob);

            }



            phoneInput.addEventListener('input', validatePhone);

            phoneInput.addEventListener('blur', validatePhone);



            passwordInput.addEventListener('input', validatePassword);

            passwordInput.addEventListener('blur', validatePassword);



            emailInput.addEventListener('input', validateEmail);

            emailInput.addEventListener('blur', validateEmail);



            // Password Toggle Visibility

            if (toggleRegPasswordBtn) {

                toggleRegPasswordBtn.addEventListener('click', function () {

                    const isPassword = passwordInput.getAttribute('type') === 'password';

                    passwordInput.setAttribute('type', isPassword ? 'text' : 'password');

                    toggleRegPassIcon.className = isPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye';

                });

            }



            // Countdown Timer

            function startTimer(duration) {

                duration = duration || 60;

                clearInterval(timerInterval);

                secondsRemaining = duration;

                btnResendOtp.disabled = true;



                updateTimerDisplay();



                timerInterval = setInterval(function () {

                    secondsRemaining--;

                    updateTimerDisplay();



                    if (secondsRemaining <= 0) {

                        clearInterval(timerInterval);

                        btnResendOtp.disabled = false;

                        timerCountdown.textContent = '00:00';

                    }

                }, 1000);

            }



            function updateTimerDisplay() {

                const mins = Math.floor(secondsRemaining / 60);

                const secs = secondsRemaining % 60;

                timerCountdown.textContent = (mins < 10 ? '0' : '') + mins + ':' + (secs < 10 ? '0' : '') + secs;

            }



            // Timer is idle until user clicks 'Send OTP'
            btnResendOtp.disabled = true;



            // Send OTP handler

            btnSendOtp.addEventListener('click', function () {

                sendOtpAction(false);

            });



            btnResendOtp.addEventListener('click', function () {

                sendOtpAction(true);

            });



            function sendOtpAction(isResend) {

                if (!validateEmail()) {

                    emailInput.focus();

                    return;

                }



                const email = emailInput.value.trim().toLowerCase();

                hideAlert();

                hideOtpFeedback();



                // Button state

                if (isResend) {

                    btnResendOtp.disabled = true;

                    btnResendOtp.textContent = 'Sending...';

                } else {

                    btnSendOtp.disabled = true;

                    sendOtpIcon.className = 'fa-solid fa-circle-notch fa-spin';

                    sendOtpText.textContent = 'Sending...';

                }



                const params = new URLSearchParams();

                params.append('email', email);



                fetch(contextPath + '/auth/send-otp', {

                    method: 'POST',

                    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },

                    body: params.toString()

                })

                .then(function (res) { return res.json(); })

                .then(function (data) {

                    if (data.success) {

                        otpTargetEmail.textContent = email;

                        startTimer(60);

                        showOtpFeedback(data.message, true);

                        showAlert(data.message, true);

                        otpDigits[0].focus();

                    } else {

                        showAlert(data.message);

                        showOtpFeedback(data.message, false);

                    }

                })

                .catch(function (err) {

                    console.error('Send OTP error:', err);

                    showAlert('Connection error. Please check your network and try again.');

                })

                .finally(function () {

                    if (isResend) {

                        btnResendOtp.textContent = 'Resend OTP';

                    } else {

                        btnSendOtp.disabled = false;

                        sendOtpIcon.className = 'fa-solid fa-paper-plane';

                        sendOtpText.textContent = 'Send OTP';

                    }

                });

            }



            // OTP 6-Digit Auto Advance & Backspace Logic

            otpDigits.forEach(function (input, idx) {

                input.addEventListener('keydown', function (e) {

                    if (e.key === 'Backspace') {

                        if (input.value === '' && idx > 0) {

                            otpDigits[idx - 1].focus();

                            otpDigits[idx - 1].value = '';

                        }

                    } else if (e.key === 'ArrowLeft' && idx > 0) {

                        otpDigits[idx - 1].focus();

                    } else if (e.key === 'ArrowRight' && idx < otpDigits.length - 1) {

                        otpDigits[idx + 1].focus();

                    }

                });



                input.addEventListener('input', function (e) {

                    const val = input.value.replace(/[^0-9]/g, '');

                    input.value = val ? val.charAt(val.length - 1) : '';



                    if (input.value) {

                        input.classList.add('digit-filled');

                        if (idx < otpDigits.length - 1) {

                            otpDigits[idx + 1].focus();

                        }

                    } else {

                        input.classList.remove('digit-filled');

                    }



                    checkAllOtpFilled();

                });



                input.addEventListener('paste', function (e) {

                    e.preventDefault();

                    const pasteData = (e.clipboardData || window.clipboardData).getData('text').replace(/[^0-9]/g, '');

                    if (pasteData.length >= 6) {

                        for (let i = 0; i < 6; i++) {

                            otpDigits[i].value = pasteData.charAt(i);

                            otpDigits[i].classList.add('digit-filled');

                        }

                        otpDigits[5].focus();

                        checkAllOtpFilled();

                    }

                });

            });



            function checkAllOtpFilled() {

                const enteredDigits = otpDigits.map(function (d) { return d.value; }).join('');

                fullOtpHidden.value = enteredDigits;



                if (enteredDigits.length === 6) {

                    verifyEnteredOtp(enteredDigits);

                }

            }



            function verifyEnteredOtp(otpValue) {

                const email = emailInput.value.trim().toLowerCase();

                if (!email) {

                    showAlert('Please enter your email address to verify OTP.');

                    return;

                }



                showOtpFeedback('Verifying OTP code...', true);



                const params = new URLSearchParams();

                params.append('email', email);

                params.append('otp', otpValue);



                fetch(contextPath + '/auth/verify-otp', {

                    method: 'POST',

                    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },

                    body: params.toString()

                })

                .then(function (res) { return res.json(); })

                .then(function (data) {

                    if (data.success) {

                        isEmailVerified = true;

                        showOtpFeedback('Email verified successfully! You can now create your account.', true);

                        showAlert('Email verified successfully!', true);



                        // Update visual status

                        btnSendOtp.style.display = 'none';

                        verifiedBadge.style.display = 'inline-flex';

                        emailInput.readOnly = true;



                        otpDigits.forEach(function (d) {

                            d.classList.add('digit-verified');

                            d.readOnly = true;

                        });

                        clearInterval(timerInterval);

                        btnResendOtp.disabled = true;

                    } else {

                        isEmailVerified = false;

                        showOtpFeedback(data.message, false);

                        showAlert(data.message);

                    }

                })

                .catch(function (err) {

                    console.error('Verify OTP error:', err);

                    showOtpFeedback('Verification check error. Please try again.', false);

                });

            }



            // Form Submit Handler

            form.addEventListener('submit', function (e) {

                e.preventDefault();

                hideAlert();



                const isFirstValid = validateFirstName();
                const isLastValid = validateLastName();
                const isGenderValid = validateGender();
                const isDobValid = validateDob();
                const isPhoneValid = validatePhone();
                const isPasswordValid = validatePassword();
                const isEmailValid = validateEmail();

                if (!isFirstValid) {
                    firstNameInput.focus();
                    return;
                }
                if (!isLastValid) {
                    lastNameInput.focus();
                    return;
                }
                if (!isGenderValid) {
                    genderSelect.focus();
                    return;
                }
                if (!isDobValid) {
                    dobInput.focus();
                    return;
                }

                if (!isPhoneValid) {

                    phoneInput.focus();

                    return;

                }

                if (!isPasswordValid) {

                    passwordInput.focus();

                    return;

                }

                if (!isEmailValid) {

                    emailInput.focus();

                    return;

                }



                const terms = termsCheckbox.checked;

                if (!terms) {

                    showAlert('You must agree to the Terms & Conditions and Privacy Policy.');

                    termsCheckbox.focus();

                    return;

                }



                const otpDigitsVal = otpDigits.map(function (d) { return d.value; }).join('');



                if (!isEmailVerified && otpDigitsVal.length !== 6) {

                    showAlert('Please verify your email address using the 6-digit OTP code before proceeding.');

                    otpDigits[0].focus();

                    return;

                }



                // Show loading state

                createBtn.disabled = true;

                createIcon.className = 'fa-solid fa-circle-notch fa-spin';

                createText.textContent = 'Creating Account...';



                const formData = new URLSearchParams();

                formData.append('firstName', firstNameInput.value.trim());

                formData.append('lastName', lastNameInput.value.trim());

                formData.append('gender', genderSelect.value);

                formData.append('dob', dobInput ? dobInput.value : '');

                formData.append('phone', phoneInput.value.trim());

                formData.append('password', passwordInput.value);

                formData.append('email', emailInput.value.trim());

                formData.append('otp', otpDigitsVal);

                formData.append('terms', terms ? 'true' : 'false');



                fetch(contextPath + '/auth/register-user', {

                    method: 'POST',

                    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },

                    body: formData.toString()

                })

                .then(function (res) { return res.json(); })

                .then(function (data) {

                    if (data.success) {

                        showAlert(data.message, true);

                        createIcon.className = 'fa-solid fa-check';

                        createText.textContent = 'Account Created! Redirecting to login...';



                        setTimeout(function () {

                            window.location.href = data.redirectUrl || (contextPath + '/user/login.jsp?msg=registered');

                        }, 1200);

                    } else {

                        createBtn.disabled = false;

                        createIcon.className = 'fa-solid fa-user-plus';

                        createText.textContent = 'Create Account';

                        showAlert(data.message);



                        if (data.field === 'firstName') {

                            setFieldInvalid(firstNameInput, firstNameInstruction, data.message);

                            firstNameInput.focus();

                        } else if (data.field === 'lastName') {

                            setFieldInvalid(lastNameInput, lastNameInstruction, data.message);

                            lastNameInput.focus();

                        } else if (data.field === 'dob') {

                            setFieldInvalid(dobInput, dobInstruction, data.message);

                            dobInput.focus();

                        } else if (data.field === 'phone') {

                            setFieldInvalid(phoneInput, phoneInstruction, data.message);

                            phoneInput.focus();

                        } else if (data.field === 'password') {

                            setFieldInvalid(passwordInput, passwordInstruction, data.message);

                            passwordInput.focus();

                        } else if (data.field === 'email') {

                            setFieldInvalid(emailInput, emailInstruction, data.message);

                            emailInput.focus();

                        }

                    }

                })

                .catch(function (err) {

                    console.error('Registration error:', err);

                    createBtn.disabled = false;

                    createIcon.className = 'fa-solid fa-user-plus';

                    createText.textContent = 'Create Account';

                    showAlert('System error occurred. Please try again.');

                });

            });

        });



        // Modal open/close helpers

        function openModal(id) {

            const m = document.getElementById(id);

            if (m) m.style.display = 'flex';

        }



        function closeModal(id) {

            const m = document.getElementById(id);

            if (m) m.style.display = 'none';

        }



        window.onclick = function (e) {

            if (e.target.classList.contains('info-modal')) {

                e.target.style.display = 'none';

            }

        };



    </script>

</body>

</html>

