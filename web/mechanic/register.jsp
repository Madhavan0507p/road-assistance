<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="com.roadassistance.model.Mechanic" %>

<%

    // Redirect already authenticated approved mechanics to dashboard

    Mechanic activeM = (Mechanic) session.getAttribute("mechanic");

    if (activeM != null && activeM.isApproved()) {

        response.sendRedirect(request.getContextPath() + "/mechanic/dashboard.jsp");

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

    <title>Mechanic Registration — On Road Vehicle Breakdown Assistance</title>

    

    <!-- Google Fonts & Font Awesome Icons -->

    <link rel="preconnect" href="https://fonts.googleapis.com">

    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    

    <!-- Leaflet CSS for Interactive GPS Map -->

    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>



    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-register.css?v=4.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>

    <style>
        /* Form grid robustness for long truncated file labels */
        .form-grid-row {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
            gap: 16px;
        }
        .form-grid-row .form-field-group {
            min-width: 0;
            overflow: hidden;
        }

        /* ===================================================================
           PREMIUM AUTOMOTIVE DOCUMENT UPLOAD COMPONENTS
           =================================================================== */
        .doc-upload-box {
            width: 100%;
            min-width: 0;
            margin-top: 2px;
        }

        .doc-dropzone {
            width: 100%;
            min-height: 82px;
            border: 2px dashed #CBD5E1;
            border-radius: 12px;
            background: #F8FAFC;
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            cursor: pointer;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            box-sizing: border-box;
            text-align: left;
            position: relative;
        }

        .doc-dropzone[style*="display: none"] {
            display: none !important;
        }

        .doc-dropzone:hover {
            border-color: #F97316;
            background: #FFF7ED;
            transform: translateY(-1px);
            box-shadow: 0 4px 14px rgba(249, 115, 22, 0.1);
        }

        .doc-dropzone.glow-invalid {
            border-color: #EF4444 !important;
            background: #FEF2F2 !important;
        }

        .doc-dropzone-icon {
            width: 44px;
            height: 44px;
            min-width: 44px;
            border-radius: 10px;
            background: rgba(249, 115, 22, 0.1);
            color: #F97316;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            transition: all 0.2s ease;
        }

        .doc-dropzone:hover .doc-dropzone-icon {
            background: #F97316;
            color: #FFFFFF;
        }

        .doc-dropzone-text {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
        }

        .doc-dropzone-title {
            font-size: 13px;
            font-weight: 700;
            color: #1E293B;
            line-height: 1.3;
        }

        .doc-dropzone-hint {
            font-size: 11px;
            color: #64748B;
            margin-top: 3px;
            font-weight: 500;
        }

        .doc-browse-btn {
            padding: 6px 14px;
            background: #FFFFFF;
            border: 1.5px solid #CBD5E1;
            border-radius: 8px;
            font-size: 11.5px;
            font-weight: 700;
            color: #334155;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
            white-space: nowrap;
        }

        .doc-dropzone:hover .doc-browse-btn {
            border-color: #F97316;
            color: #EA580C;
            background: #FFFFFF;
        }

        /* Uploaded / Attached File Card */
        .doc-file-badge {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            background: #F0FDF4;
            border: 1.5px solid #86EFAC;
            border-left: 4px solid #10B981;
            border-radius: 12px;
            gap: 12px;
            min-height: 82px;
            box-sizing: border-box;
            width: 100%;
            transition: all 0.2s ease;
            box-shadow: 0 2px 6px rgba(16, 185, 129, 0.08);
            overflow: hidden;
        }

        .doc-preview-wrapper {
            width: 48px;
            height: 48px;
            min-width: 48px;
            border-radius: 8px;
            overflow: hidden;
            position: relative;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #E2E8F0;
            border: 1px solid #CBD5E1;
        }

        .doc-thumb-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .doc-pdf-icon {
            width: 100%;
            height: 100%;
            background: rgba(239, 68, 68, 0.1);
            color: #EF4444;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
        }

        .doc-generic-icon {
            width: 100%;
            height: 100%;
            background: rgba(16, 185, 129, 0.1);
            color: #10B981;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
        }

        .doc-file-info {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
            justify-content: center;
            overflow: hidden;
        }

        .doc-filename {
            font-size: 13px;
            font-weight: 700;
            color: #0F172A;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            display: block;
            line-height: 1.35;
        }

        .doc-file-meta-row {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 11px;
            margin-top: 3px;
            color: #64748B;
        }

        .doc-filesize {
            font-weight: 600;
            color: #475569;
        }

        .doc-meta-dot {
            color: #94A3B8;
        }

        .doc-ready-status {
            color: #059669;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .doc-actions-group {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }

        .btn-doc-action {
            width: 34px;
            height: 34px;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            transition: all 0.2s ease;
        }

        .btn-doc-inspect {
            background: #E0F2FE;
            color: #0284C7;
        }

        .btn-doc-inspect:hover {
            background: #0284C7;
            color: #FFFFFF;
        }

        .btn-doc-remove {
            background: #FEE2E2;
            color: #DC2626;
        }

        .btn-doc-remove:hover {
            background: #DC2626;
            color: #FFFFFF;
        }

        /* Lightbox Modal */
        .doc-preview-modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 9999;
            padding: 20px;
            box-sizing: border-box;
        }

        .doc-modal-content {
            background: #FFFFFF;
            border-radius: 16px;
            max-width: 600px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
            overflow: hidden;
            animation: modalPopIn 0.2s ease-out;
        }

        @keyframes modalPopIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }

        .doc-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 20px;
            border-bottom: 1px solid #E2E8F0;
            background: #F8FAFC;
        }

        .doc-modal-header-left {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            font-weight: 700;
            color: #1E293B;
            max-width: 500px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .doc-modal-close {
            background: transparent;
            border: none;
            font-size: 24px;
            line-height: 1;
            color: #64748B;
            cursor: pointer;
            transition: color 0.15s;
        }

        .doc-modal-close:hover {
            color: #EF4444;
        }

        .doc-modal-body {
            padding: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #FFFFFF;
        }
    </style>

</head>

<body>



    <!-- Top Left Floating Back Navigation Button -->

    <a href="javascript:void(0);" onclick="handleGlobalCancel()" class="back-nav-btn" id="btnGlobalBack" title="Return to Login">

        <i class="fa-solid fa-arrow-left"></i> <span>Back</span>

    </a>



    <!-- Ambient Glow Swooshes -->

    <div class="corner-swoosh-top"></div>

    <div class="corner-swoosh-bottom"></div>



    <!-- Main Container -->

    <main class="mech-reg-container">



        <!-- =================================================================

             1. LEFT PROMOTIONAL SECTION (Consistent across all 5 steps)

             ================================================================= -->

        <section class="mech-intro-col">

            <!-- Brand Logo -->

            <a href="${pageContext.request.contextPath}/index.jsp" class="brand-header-link" title="Return to Homepage">

                <div class="brand-logo-icon">

                    <i class="fa-solid fa-car-burst"></i>

                </div>

                <div class="brand-text-block">

                    <span class="brand-name-main">On Road Vehicle</span>

                    <span class="brand-name-sub">Breakdown Assistance</span>

                </div>

            </a>



            <!-- Heading -->

            <div class="intro-heading-group">

                <h1 class="intro-title">

                    Mechanic<span class="title-highlight">Registration</span>

                </h1>

                <div class="intro-underline"></div>

            </div>



            <!-- Description -->

            <p class="intro-description">

                Join our mechanic network and get more service requests from nearby customers.

            </p>



            <!-- 3 Feature Items matching Reference Screenshot -->

            <div class="mech-features-list">

                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-users"></i>

                    </div>

                    <div class="feature-text-block">

                        <h4 class="feature-title">Get Service Requests</h4>

                        <span class="feature-desc">Requests</span>

                    </div>

                </div>



                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-chart-line"></i>

                    </div>

                    <div class="feature-text-block">

                        <h4 class="feature-title">Grow Your Business</h4>

                        <span class="feature-desc">Business</span>

                    </div>

                </div>



                <div class="feature-item-row">

                    <div class="feature-icon-box">

                        <i class="fa-solid fa-shield-halved"></i>

                    </div>

                    <div class="feature-text-block">

                        <h4 class="feature-title">Verified Profile</h4>

                        <span class="feature-desc">Profile</span>

                    </div>

                </div>

            </div>

        </section>



        <!-- =================================================================

             2. RIGHT SECTION (LARGE CRISP WHITE 5-STEP REGISTRATION CARD)

             ================================================================= -->

        <section class="mech-reg-card-col">

            <div class="mech-reg-card">

                

                <!-- Center Header Icon & Title -->

                <div class="card-top-icon-wrapper">

                    <div class="card-wrench-badge">

                        <i class="fa-solid fa-screwdriver-wrench"></i>

                    </div>

                </div>

                <div class="card-main-header">

                    <h2 class="card-main-title">Mechanic Registration</h2>

                    <p class="card-main-subtitle">Create your mechanic account in a few simple steps</p>

                </div>



                <!-- Flash Alert Messages -->

                <% if (errorMsg != null && !errorMsg.trim().isEmpty()) { %>

                    <div class="card-alert-box card-alert-error" id="serverAlert">

                        <i class="fa-solid fa-triangle-exclamation"></i>

                        <span><%= errorMsg %></span>

                    </div>

                <% } %>

                <div class="card-alert-box card-alert-error" id="jsAlertBox" style="display: none;">

                    <i class="fa-solid fa-triangle-exclamation"></i>

                    <span id="jsAlertText"></span>

                </div>



                <!-- 5-STEP HORIZONTAL PROGRESS STEPPER -->

                <nav class="stepper-nav-bar" aria-label="Registration Progress">

                    <div class="stepper-track-line"></div>

                    <div class="stepper-progress-fill" id="stepperProgressFill"></div>



                    <!-- Step 1 -->

                    <div class="stepper-step-item active" id="stepIndicator1">

                        <div class="step-circle-badge">

                            <i class="fa-solid fa-user"></i>

                        </div>

                        <span class="step-label-text">1. Personal Details</span>

                    </div>



                    <!-- Step 2 -->

                    <div class="stepper-step-item" id="stepIndicator2">

                        <div class="step-circle-badge">

                            <i class="fa-solid fa-envelope"></i>

                        </div>

                        <span class="step-label-text">2. Verify Email (OTP)</span>

                    </div>



                    <!-- Step 3 -->

                    <div class="stepper-step-item" id="stepIndicator3">

                        <div class="step-circle-badge">

                            <i class="fa-solid fa-screwdriver-wrench"></i>

                        </div>

                        <span class="step-label-text">3. Work Specialization</span>

                    </div>



                    <!-- Step 4 -->

                    <div class="stepper-step-item" id="stepIndicator4">

                        <div class="step-circle-badge">

                            <i class="fa-solid fa-store"></i>

                        </div>

                        <span class="step-label-text">4. Shop Details</span>

                    </div>



                    <!-- Step 5 -->

                    <div class="stepper-step-item" id="stepIndicator5">

                        <div class="step-circle-badge">

                            <i class="fa-solid fa-location-dot"></i>

                        </div>

                        <span class="step-label-text">5. Shop Address & Location</span>

                    </div>

                </nav>



                <!-- MAIN REGISTRATION FORM -->

                <form id="mechanicRegForm" method="POST" enctype="multipart/form-data" novalidate>



                    <!-- =========================================================

                         STEP 1: PERSONAL DETAILS

                         ========================================================= -->

                    <div class="wizard-step-pane" id="stepPane1">

                        <div class="step-banner-box">

                            <div class="step-banner-icon">

                                <i class="fa-solid fa-user"></i>

                            </div>

                            <div class="step-banner-text">

                                <h3 class="step-banner-title">Step 1: Personal Details</h3>

                                <p class="step-banner-subtitle">Enter your basic information to create your mechanic account</p>

                            </div>

                        </div>



                        <!-- Row 1: First Name & Last Name (Characters Only) -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechFirstName">

                                    <i class="fa-solid fa-user"></i> First Name <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="text" id="mechFirstName" name="firstName" class="field-input" placeholder="Enter first name" required autofocus onkeydown="if(/[0-9]/.test(event.key)) event.preventDefault();" oninput="this.value = this.value.replace(/[0-9]/g, '');">

                                </div>

                                <div id="firstNameInstruction" class="field-instruction-msg"></div>

                            </div>



                            <div class="form-field-group">

                                <label class="field-label" for="mechLastName">

                                    <i class="fa-solid fa-user"></i> Last Name <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="text" id="mechLastName" name="lastName" class="field-input" placeholder="Enter last name" required onkeydown="if(/[0-9]/.test(event.key)) event.preventDefault();" oninput="this.value = this.value.replace(/[0-9]/g, '');">

                                </div>

                                <div id="lastNameInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Row 2: Gender & Date of Birth (18+ Years Old) -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechGender">

                                    <i class="fa-solid fa-venus-mars"></i> Gender <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <select id="mechGender" name="gender" class="field-select" required>

                                        <option value="" disabled selected>Select gender</option>

                                        <option value="Male">Male</option>

                                        <option value="Female">Female</option>

                                        <option value="Other">Other</option>

                                        <option value="Prefer not to say">Prefer not to say</option>

                                    </select>

                                </div>

                                <div id="genderInstruction" class="field-instruction-msg"></div>

                            </div>



                            <div class="form-field-group">

                                <label class="field-label" for="mechDob">

                                    <i class="fa-solid fa-cake-candles"></i> Date of Birth <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="date" id="mechDob" name="dob" class="field-input" required>

                                </div>

                                <div id="dobInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Row 3: Mobile Number & Email Address -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechMobile">

                                    <i class="fa-solid fa-phone"></i> Mobile Number <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="tel" id="mechMobile" name="mobileNumber" class="field-input" placeholder="Enter 10-digit mobile number" maxlength="10" inputmode="numeric" required>

                                </div>

                                <div id="mobileInstruction" class="field-instruction-msg"></div>

                            </div>



                            <div class="form-field-group">

                                <label class="field-label" for="mechEmail">

                                    <i class="fa-solid fa-envelope"></i> Email Address <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="email" id="mechEmail" name="email" class="field-input" placeholder="Enter your email address" required autocomplete="email">

                                </div>

                                <div id="emailInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Row 4: Account Password -->

                        <div class="form-field-group">

                            <label class="field-label" for="mechPassword">

                                <i class="fa-solid fa-lock"></i> Create Password <span class="required">*</span>

                            </label>

                            <div class="password-field-wrapper">

                                <input type="password" id="mechPassword" name="password" class="field-input" placeholder="Create password (8-12 characters)" maxlength="12" required autocomplete="new-password">

                                <button type="button" id="toggleMechPassBtn" class="password-toggle-btn" title="Toggle password visibility">

                                    <i class="fa-regular fa-eye" id="toggleMechPassIcon"></i>

                                </button>

                            </div>

                            <div id="passwordInstruction" class="field-instruction-msg"></div>

                        </div>



                        <!-- Row 5: Aadhaar Number (12 Digits Only) -->

                        <div class="form-field-group">

                            <label class="field-label" for="mechAadhaar">

                                <i class="fa-solid fa-id-card"></i> Aadhaar Number <span class="required">*</span>

                            </label>

                            <div class="field-input-wrapper">

                                <input type="text" id="mechAadhaar" name="aadhaarNumber" class="field-input" placeholder="Enter 12-digit Aadhaar number" maxlength="14" inputmode="numeric" required autocomplete="off">

                            </div>

                            <div id="aadhaarInstruction" class="field-instruction-msg"></div>

                        </div>



                        <!-- Row 6: Identity Documents (Aadhaar Card & ID Proof) -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechAadhaarDoc">

                                    <i class="fa-solid fa-file-shield"></i> Aadhaar Card Document <span class="required">*</span>

                                </label>

                                <div class="doc-upload-box" id="aadhaarUploadBox">
                                    <label class="doc-dropzone" for="mechAadhaarDoc" id="aadhaarDropzone">
                                        <div class="doc-dropzone-icon">
                                            <i class="fa-solid fa-cloud-arrow-up"></i>
                                        </div>
                                        <div class="doc-dropzone-text">
                                            <span class="doc-dropzone-title">Upload Aadhaar Card</span>
                                            <span class="doc-dropzone-hint">PDF, JPG, PNG or WEBP (Max 5 MB)</span>
                                        </div>
                                        <span class="doc-browse-btn">
                                            <i class="fa-solid fa-folder-open"></i> Browse
                                        </span>
                                        <input type="file" id="mechAadhaarDoc" name="aadhaarCardDoc" accept="image/jpeg,image/png,image/jpg,image/webp,application/pdf" style="display: none;">
                                    </label>
                                    <div class="doc-file-badge" id="aadhaarFileBadge" style="display: none;">
                                        <div class="doc-preview-wrapper" id="aadhaarPreviewWrapper" title="Click to preview document">
                                            <img id="aadhaarThumbImg" src="" alt="Aadhaar Preview" class="doc-thumb-img" style="display: none;">
                                            <div id="aadhaarPdfIcon" class="doc-pdf-icon" style="display: none;">
                                                <i class="fa-solid fa-file-pdf"></i>
                                            </div>
                                            <div id="aadhaarGenericIcon" class="doc-generic-icon">
                                                <i class="fa-solid fa-file-shield"></i>
                                            </div>
                                        </div>
                                        <div class="doc-file-info">
                                            <span class="doc-filename" id="aadhaarFileName" title=""></span>
                                            <div class="doc-file-meta-row">
                                                <span class="doc-filesize" id="aadhaarFileSize"></span>
                                                <span class="doc-meta-dot">•</span>
                                                <span class="doc-ready-status"><i class="fa-solid fa-circle-check"></i> Document Attached</span>
                                            </div>
                                        </div>
                                        <div class="doc-actions-group">
                                            <button type="button" class="btn-doc-action btn-doc-inspect" id="btnInspectAadhaarDoc" title="Preview document">
                                                <i class="fa-solid fa-eye"></i>
                                            </button>
                                            <button type="button" class="btn-doc-action btn-doc-remove" id="btnClearAadhaarDoc" title="Remove document">
                                                <i class="fa-solid fa-trash-can"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <div id="aadhaarDocInstruction" class="field-instruction-msg"></div>
                            </div>

                            <div class="form-field-group">
                                <label class="field-label" for="mechIdProofDoc">
                                    <i class="fa-solid fa-address-card"></i> ID Proof Document <span class="required">*</span>
                                </label>
                                <div class="doc-upload-box" id="idProofUploadBox">
                                    <label class="doc-dropzone" for="mechIdProofDoc" id="idProofDropzone">
                                        <div class="doc-dropzone-icon">
                                            <i class="fa-solid fa-cloud-arrow-up"></i>
                                        </div>
                                        <div class="doc-dropzone-text">
                                            <span class="doc-dropzone-title">Upload ID Proof Document</span>
                                            <span class="doc-dropzone-hint">Driving License, Voter ID, PAN (Max 5 MB)</span>
                                        </div>
                                        <span class="doc-browse-btn">
                                            <i class="fa-solid fa-folder-open"></i> Browse
                                        </span>
                                        <input type="file" id="mechIdProofDoc" name="idProofDoc" accept="image/jpeg,image/png,image/jpg,image/webp,application/pdf" style="display: none;">
                                    </label>
                                    <div class="doc-file-badge" id="idProofFileBadge" style="display: none;">
                                        <div class="doc-preview-wrapper" id="idProofPreviewWrapper" title="Click to preview document">
                                            <img id="idProofThumbImg" src="" alt="ID Proof Preview" class="doc-thumb-img" style="display: none;">
                                            <div id="idProofPdfIcon" class="doc-pdf-icon" style="display: none;">
                                                <i class="fa-solid fa-file-pdf"></i>
                                            </div>
                                            <div id="idProofGenericIcon" class="doc-generic-icon">
                                                <i class="fa-solid fa-address-card"></i>
                                            </div>
                                        </div>
                                        <div class="doc-file-info">
                                            <span class="doc-filename" id="idProofFileName" title=""></span>
                                            <div class="doc-file-meta-row">
                                                <span class="doc-filesize" id="idProofFileSize"></span>
                                                <span class="doc-meta-dot">•</span>
                                                <span class="doc-ready-status"><i class="fa-solid fa-circle-check"></i> Document Attached</span>
                                            </div>
                                        </div>
                                        <div class="doc-actions-group">
                                            <button type="button" class="btn-doc-action btn-doc-inspect" id="btnInspectIdProofDoc" title="Preview document">
                                                <i class="fa-solid fa-eye"></i>
                                            </button>
                                            <button type="button" class="btn-doc-action btn-doc-remove" id="btnClearIdProofDoc" title="Remove document">
                                                <i class="fa-solid fa-trash-can"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <div id="idProofDocInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Step 1 Footer Buttons -->

                        <div class="step-footer-actions">

                            <button type="button" class="btn-wizard-back" onclick="handleGlobalCancel()">

                                <i class="fa-solid fa-arrow-left"></i> Cancel

                            </button>

                            <button type="button" class="btn-wizard-next" id="btnNextStep1">

                                <span>Next: Verify Email (OTP)</span> <i class="fa-solid fa-arrow-right"></i>

                            </button>

                        </div>

                    </div>



                    <!-- =========================================================

                         STEP 2: VERIFY EMAIL (OTP)

                         ========================================================= -->

                    <div class="wizard-step-pane" id="stepPane2" style="display: none;">

                        <div class="step-banner-box">

                            <div class="step-banner-icon">

                                <i class="fa-solid fa-envelope"></i>

                            </div>

                            <div class="step-banner-text">

                                <h3 class="step-banner-title">Step 2: Verify Email (OTP)</h3>

                                <p class="step-banner-subtitle">Confirm your email address to continue mechanic registration</p>

                            </div>

                        </div>



                        <!-- Email Display & Send OTP Box -->

                        <div class="form-field-group">

                            <label class="field-label">

                                <i class="fa-solid fa-envelope"></i> Email Address <span class="required">*</span>

                            </label>

                            <div class="email-display-card">

                                <div class="email-info-left">

                                    <i class="fa-solid fa-envelope"></i>

                                    <span id="displayUserEmail" class="email-text-label">your-email@domain.com</span>

                                    <button type="button" class="btn-change-email" id="btnChangeEmail" title="Edit email address">

                                        <i class="fa-solid fa-pen-to-square"></i> Change Email

                                    </button>

                                </div>

                                <button type="button" class="btn-send-otp-main" id="btnSendMechOtp">

                                    <i class="fa-solid fa-paper-plane" id="sendMechOtpIcon"></i>

                                    <span id="sendMechOtpText">Send OTP</span>

                                </button>

                            </div>

                        </div>



                        <!-- OTP Input Card -->

                        <div class="otp-box-card" id="otpCardSection">

                            <div class="otp-box-header">

                                <div class="otp-shield-badge">

                                    <i class="fa-solid fa-shield-halved"></i>

                                </div>

                                <div class="otp-box-titles">

                                    <h4 class="otp-title-text">Enter Verification OTP</h4>

                                    <p class="otp-sub-text">Enter the 6-digit OTP sent to <strong id="otpEmailTarget">your email</strong></p>

                                </div>

                            </div>



                            <div class="otp-inputs-row">

                                <div class="otp-digits-wrapper" id="mechOtpGroup">

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="0" inputmode="numeric" pattern="[0-9]*" placeholder="•" autofocus>

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="1" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="2" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="3" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="4" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                    <input type="text" maxlength="1" class="otp-digit-box" data-index="5" inputmode="numeric" pattern="[0-9]*" placeholder="•">

                                </div>



                                <div class="otp-timer-action">

                                    <span class="otp-timer-badge" id="mechOtpTimerWrapper">

                                        <i class="fa-regular fa-clock"></i>

                                        <span id="mechTimerCountdown">00:00</span>

                                    </span>

                                    <button type="button" class="btn-resend-pill" id="btnResendMechOtp" disabled>

                                        <i class="fa-solid fa-rotate-right"></i> Resend OTP

                                    </button>

                                </div>

                            </div>



                            <p class="otp-info-footnote">

                                <i class="fa-solid fa-circle-info"></i> OTP expires in 2 minutes. Check your spam folder if you don't receive it.

                            </p>

                            <div id="otpVerificationFeedback" class="field-instruction-msg"></div>

                        </div>



                        <!-- Step 2 Footer Buttons -->

                        <div class="step-footer-actions">

                            <button type="button" class="btn-wizard-back" id="btnBackToStep1">

                                <i class="fa-solid fa-arrow-left"></i> Back: Personal Details

                            </button>

                            <button type="button" class="btn-wizard-next" id="btnVerifyOtpContinue">

                                <span>Verify OTP & Continue</span> <i class="fa-solid fa-arrow-right"></i>

                            </button>

                        </div>

                    </div>



                    <!-- =========================================================

                         STEP 3: WORK SPECIALIZATION

                         ========================================================= -->

                    <div class="wizard-step-pane" id="stepPane3" style="display: none;">

                        <div class="step-banner-box">

                            <div class="step-banner-icon">

                                <i class="fa-solid fa-screwdriver-wrench"></i>

                            </div>

                            <div class="step-banner-text">

                                <h3 class="step-banner-title">Step 3: Work Specialization</h3>

                                <p class="step-banner-subtitle">Select the services you can provide. You can choose multiple options.</p>

                            </div>

                        </div>



                        <!-- 9 Selectable Checkbox Cards Grid -->

                        <div class="specialization-grid" id="specializationGrid">

                            <!-- 1. Engine Repair -->

                            <div class="spec-card selected" data-value="Engine Repair">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-car-burst"></i></div>

                                    <span class="spec-title-text">Engine Repair</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check"></i></div>

                                <input type="checkbox" name="specializations" value="Engine Repair" checked style="display: none;">

                            </div>



                            <!-- 2. Battery Service -->

                            <div class="spec-card" data-value="Battery Service">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-car-battery"></i></div>

                                    <span class="spec-title-text">Battery Service</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="Battery Service" style="display: none;">

                            </div>



                            <!-- 3. Tyre / Puncture -->

                            <div class="spec-card selected" data-value="Tyre / Puncture">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-circle-dot"></i></div>

                                    <span class="spec-title-text">Tyre / Puncture</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check"></i></div>

                                <input type="checkbox" name="specializations" value="Tyre / Puncture" checked style="display: none;">

                            </div>



                            <!-- 4. Clutch & Gear -->

                            <div class="spec-card" data-value="Clutch & Gear">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-gear"></i></div>

                                    <span class="spec-title-text">Clutch & Gear</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="Clutch & Gear" style="display: none;">

                            </div>



                            <!-- 5. Brake Service -->

                            <div class="spec-card" data-value="Brake Service">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-bullseye"></i></div>

                                    <span class="spec-title-text">Brake Service</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="Brake Service" style="display: none;">

                            </div>



                            <!-- 6. Electrical Repair -->

                            <div class="spec-card selected" data-value="Electrical Repair">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-bolt"></i></div>

                                    <span class="spec-title-text">Electrical Repair</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check"></i></div>

                                <input type="checkbox" name="specializations" value="Electrical Repair" checked style="display: none;">

                            </div>



                            <!-- 7. Cooling System -->

                            <div class="spec-card" data-value="Cooling System">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-temperature-half"></i></div>

                                    <span class="spec-title-text">Cooling System</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="Cooling System" style="display: none;">

                            </div>



                            <!-- 8. Fuel System -->

                            <div class="spec-card" data-value="Fuel System">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-gas-pump"></i></div>

                                    <span class="spec-title-text">Fuel System</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="Fuel System" style="display: none;">

                            </div>



                            <!-- 9. General Service -->

                            <div class="spec-card" data-value="General Service">

                                <div class="spec-card-left">

                                    <div class="spec-icon-box"><i class="fa-solid fa-screwdriver-wrench"></i></div>

                                    <span class="spec-title-text">General Service</span>

                                </div>

                                <div class="spec-checkbox-box"><i class="fa-solid fa-check" style="display: none;"></i></div>

                                <input type="checkbox" name="specializations" value="General Service" style="display: none;">

                            </div>

                        </div>



                        <!-- Other Service (Optional) -->

                        <div class="form-field-group">

                            <label class="field-label" for="otherServiceInput">

                                <i class="fa-solid fa-pen"></i> Other Service (Optional)

                            </label>

                            <div class="field-input-wrapper">

                                <input type="text" id="otherServiceInput" name="otherSpecialization" class="field-input" placeholder="Enter any other service you provide (e.g., AC Repair, Radiator, etc.)" maxlength="100">

                            </div>

                            <div id="specInstruction" class="field-instruction-msg"></div>

                        </div>



                        <!-- Step 3 Footer Buttons -->

                        <div class="step-footer-actions">

                            <button type="button" class="btn-wizard-back" id="btnBackToStep2">

                                <i class="fa-solid fa-arrow-left"></i> Back: Verify Email (OTP)

                            </button>

                            <button type="button" class="btn-wizard-next" id="btnNextStep3">

                                <span>Next: Shop Details</span> <i class="fa-solid fa-arrow-right"></i>

                            </button>

                        </div>

                    </div>



                    <!-- =========================================================

                         STEP 4: SHOP DETAILS

                         ========================================================= -->

                    <div class="wizard-step-pane" id="stepPane4" style="display: none;">

                        <div class="step-banner-box">

                            <div class="step-banner-icon">

                                <i class="fa-solid fa-store"></i>

                            </div>

                            <div class="step-banner-text">

                                <h3 class="step-banner-title">Step 4: Shop Details</h3>

                                <p class="step-banner-subtitle">Provide your workshop / garage information</p>

                            </div>

                        </div>



                        <!-- Row 1: Shop Name & Shop Type -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechShopName">

                                    <i class="fa-solid fa-store"></i> Shop Name <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="text" id="mechShopName" name="shopName" class="field-input" placeholder="Enter your shop / garage name" required>

                                </div>

                                <div id="shopNameInstruction" class="field-instruction-msg"></div>

                            </div>



                            <div class="form-field-group">

                                <label class="field-label" for="mechShopType">

                                    <i class="fa-solid fa-briefcase"></i> Shop Type <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <select id="mechShopType" name="shopType" class="field-select" required>

                                        <option value="" disabled selected>Select shop type</option>

                                        <option value="Four Wheeler Service">Four Wheeler Service</option>

                                        <option value="Two Wheeler Service">Two Wheeler Service</option>

                                        <option value="Both Two Wheeler and Four Wheeler">Both Two Wheeler and Four Wheeler</option>

                                        <option value="Commercial Vehicle Service">Commercial Vehicle Service</option>

                                        <option value="Towing & Recovery Garage">Towing & Recovery Garage</option>

                                        <option value="Other">Other</option>

                                    </select>

                                </div>

                                <div id="shopTypeInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Row 2: Shop Contact Number & Years of Experience -->

                        <div class="form-grid-row">

                            <div class="form-field-group">

                                <label class="field-label" for="mechShopContact">

                                    <i class="fa-solid fa-phone"></i> Shop Contact Number <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <input type="tel" id="mechShopContact" name="shopContactNumber" class="field-input" placeholder="Enter shop contact number" maxlength="10" inputmode="numeric" required>

                                </div>

                                <div id="shopContactInstruction" class="field-instruction-msg"></div>

                            </div>



                            <div class="form-field-group">

                                <label class="field-label" for="mechExperience">

                                    <i class="fa-solid fa-calendar-days"></i> Years of Experience <span class="required">*</span>

                                </label>

                                <div class="field-input-wrapper">

                                    <select id="mechExperience" name="yearsOfExperience" class="field-select" required>

                                        <option value="" disabled selected>Select experience</option>

                                        <option value="Less than 1 year">Less than 1 year</option>

                                        <option value="1–2 years">1–2 years</option>

                                        <option value="3–5 years">3–5 years</option>

                                        <option value="6–10 years">6–10 years</option>

                                        <option value="11–15 years">11–15 years</option>

                                        <option value="More than 15 years">More than 15 years</option>

                                    </select>

                                </div>

                                <div id="experienceInstruction" class="field-instruction-msg"></div>

                            </div>

                        </div>



                        <!-- Hidden Working Hours Default Inputs -->

                        <input type="hidden" name="openingTime" id="openingTimeSelect" value="09:00 AM">

                        <input type="hidden" name="closingTime" id="closingTimeSelect" value="07:00 PM">



                        <!-- Row 3: Shop Description with Character Counter (0/250) -->

                        <div class="form-field-group">

                            <label class="field-label" for="mechDescription">

                                <i class="fa-solid fa-store"></i> Shop Description

                            </label>

                            <textarea id="mechDescription" name="shopDescription" class="field-textarea" placeholder="Briefly describe your workshop (services, facilities, etc.)" maxlength="250" style="min-height: 85px;"></textarea>

                            <div class="char-counter-text" id="descCharCounter">0 / 250</div>

                        </div>



                        <!-- Row 4: Shop Photos Upload (Previews + Remove) -->

                        <div class="form-field-group">

                            <label class="field-label">

                                <i class="fa-regular fa-image"></i> Shop Photos (Optional)

                            </label>

                            <div class="photo-upload-section">

                                <label class="photo-upload-dropzone" for="shopPhotosInput">

                                    <i class="fa-solid fa-cloud-arrow-up"></i>

                                    <span class="dropzone-label">Click to upload shop photos</span>

                                    <span class="dropzone-sub">JPG, PNG (Max 5 MB each)</span>

                                    <input type="file" id="shopPhotosInput" name="shopPhotos" accept="image/jpeg,image/png,image/jpg,image/webp" multiple style="display: none;">

                                </label>

                                <div class="photo-preview-grid" id="photoPreviewContainer">

                                    <!-- Dynamic Previews loaded via JS -->

                                </div>

                            </div>

                        </div>



                        <!-- Step 4 Footer Buttons -->

                        <div class="step-footer-actions">

                            <button type="button" class="btn-wizard-back" id="btnBackToStep3">

                                <i class="fa-solid fa-arrow-left"></i> Back: Work Specialization

                            </button>

                            <button type="button" class="btn-wizard-next" id="btnNextStep4">

                                <span>Next: Shop Address & Location</span> <i class="fa-solid fa-arrow-right"></i>

                            </button>

                        </div>

                    </div>



                    <!-- =========================================================

                         STEP 5: SHOP ADDRESS & LOCATION (MAP + GPS)

                         ========================================================= -->

                    <div class="wizard-step-pane" id="stepPane5" style="display: none;">

                        <div class="step-banner-box">

                            <div class="step-banner-icon">

                                <i class="fa-solid fa-location-dot"></i>

                            </div>

                            <div class="step-banner-text">

                                <h3 class="step-banner-title">Step 5: Shop Address & Location</h3>

                                <p class="step-banner-subtitle">Provide your shop address and pin your location on the map</p>

                            </div>

                        </div>



                        <div class="step5-two-col">

                            <!-- Left: Address Fields -->

                            <div class="step5-left-form">

                                <div class="form-field-group">

                                    <label class="field-label" for="mechAddr1">

                                        <i class="fa-solid fa-house"></i> Address Line 1 <span class="required">*</span>

                                    </label>

                                    <div class="field-input-wrapper">

                                        <input type="text" id="mechAddr1" name="addressLine1" class="field-input" placeholder="Enter shop number, street name, etc." required>

                                    </div>

                                    <div id="addr1Instruction" class="field-instruction-msg"></div>

                                </div>



                                <div class="form-field-group">

                                    <label class="field-label" for="mechAddr2">

                                        <i class="fa-solid fa-map-pin"></i> Address Line 2 (Optional)

                                    </label>

                                    <div class="field-input-wrapper">

                                        <input type="text" id="mechAddr2" name="addressLine2" class="field-input" placeholder="Enter area, landmark, etc.">

                                    </div>

                                </div>



                                <div class="form-grid-row">

                                    <div class="form-field-group">

                                        <label class="field-label" for="mechCity">

                                            <i class="fa-solid fa-city"></i> City / Town <span class="required">*</span>

                                        </label>

                                        <div class="field-input-wrapper">

                                            <input type="text" id="mechCity" name="city" class="field-input" placeholder="Enter city or town" required>

                                        </div>

                                        <div id="cityInstruction" class="field-instruction-msg"></div>

                                    </div>



                                    <div class="form-field-group">

                                        <label class="field-label" for="mechDistrict">

                                            <i class="fa-solid fa-map-location-dot"></i> District <span class="required">*</span>

                                        </label>

                                        <div class="field-input-wrapper">

                                            <select id="mechDistrict" name="district" class="field-select" required>

                                                <option value="" disabled selected>Select district</option>

                                            </select>

                                        </div>

                                        <div id="districtInstruction" class="field-instruction-msg"></div>

                                    </div>

                                </div>



                                <div class="form-grid-row">

                                    <div class="form-field-group">

                                        <label class="field-label" for="mechState">

                                            <i class="fa-solid fa-landmark"></i> State <span class="required">*</span>

                                        </label>

                                        <div class="field-input-wrapper">

                                            <select id="mechState" name="state" class="field-select" required>

                                                <!-- Indian States & UTs dynamically loaded -->

                                            </select>

                                        </div>

                                    </div>



                                    <div class="form-field-group">

                                        <label class="field-label" for="mechPincode">

                                            <i class="fa-solid fa-envelope"></i> Pincode <span class="required">*</span>

                                        </label>

                                        <div class="field-input-wrapper">

                                            <input type="text" id="mechPincode" name="pincode" class="field-input" placeholder="Enter 6-digit pincode" maxlength="6" inputmode="numeric" required>

                                        </div>

                                        <div id="pincodeInstruction" class="field-instruction-msg"></div>

                                    </div>

                                </div>

                            </div>



                            <!-- Right: Interactive Leaflet GPS Map -->

                            <div class="step5-right-map">

                                <div class="map-wrapper-card">

                                    <div class="map-header-bar">

                                        <div class="map-title">

                                            <i class="fa-solid fa-crosshairs"></i> Shop Location (GPS)

                                        </div>

                                        <p class="map-subtitle">Pin your exact shop location on the map</p>

                                    </div>



                                    <!-- Leaflet Map Container -->

                                    <div id="mechanicMap"></div>



                                    <!-- Bottom Coordinates Bar + Use My Current Location -->

                                    <div class="map-footer-coords-bar">

                                        <div class="coords-display">

                                            <i class="fa-solid fa-location-dot"></i>

                                            <span id="coordsDisplayLabel">10.7905° N, 78.7047° E</span>

                                        </div>

                                        <button type="button" class="btn-use-location" id="btnUseCurrentLocation">

                                            <i class="fa-solid fa-crosshairs"></i> Use My Current Location

                                        </button>

                                    </div>

                                </div>

                                <div id="mapInstruction" class="field-instruction-msg"></div>



                                <!-- Hidden input fields holding coordinates for submit -->

                                <input type="hidden" id="mechLatitude" name="latitude" value="10.7905">

                                <input type="hidden" id="mechLongitude" name="longitude" value="78.7047">

                            </div>

                        </div>



                        <!-- Step 5 Footer Buttons -->

                        <div class="step-footer-actions">

                            <button type="button" class="btn-wizard-back" id="btnBackToStep4">

                                <i class="fa-solid fa-arrow-left"></i> Back: Shop Details

                            </button>

                            <button type="submit" class="btn-wizard-next" id="btnCompleteRegistration">

                                <i class="fa-solid fa-check"></i> <span id="completeRegText">Complete Registration</span>

                            </button>

                        </div>

                    </div>



                </form>

            </div>

        </section>

    </main>



    <!-- Leaflet JS Library -->

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>



    <!-- Comprehensive Client-Side Wizard Validation & Interactivity -->

    <script>

        const contextPath = '${pageContext.request.contextPath}';



        // =====================================================================

        // COMPLETE DATASET: ALL 28 INDIAN STATES & 8 UNION TERRITORIES

        // =====================================================================

        const INDIA_STATES_DISTRICTS = {

            "Tamil Nadu": ["Ariyalur", "Chengalpattu", "Chennai", "Coimbatore", "Cuddalore", "Dharmapuri", "Dindigul", "Erode", "Kallakurichi", "Kanchipuram", "Kanyakumari", "Karur", "Krishnagiri", "Madurai", "Mayiladuthurai", "Nagapattinam", "Namakkal", "Nilgiris", "Perambalur", "Pudukkottai", "Ramanathapuram", "Ranipet", "Salem", "Sivaganga", "Tenkasi", "Thanjavur", "Theni", "Thoothukudi", "Tiruchirappalli", "Tirunelveli", "Tirupattur", "Tiruppur", "Tiruvallur", "Tiruvannamalai", "Tiruvarur", "Vellore", "Viluppuram", "Virudhunagar"],

            "Andhra Pradesh": ["Ananthapuramu", "Annamayya", "Bapatla", "Chittoor", "East Godavari", "Eluru", "Guntur", "Kakinada", "Konaseema", "Krishna", "Kurnool", "Manyam", "Nandyal", "NTR", "Palnadu", "Prakasam", "Sri Potti Sriramulu Nellore", "Sri Sathya Sai", "Srikakulam", "Tirupati", "Visakhapatnam", "Vizianagaram", "West Godavari", "YSR Kadapa"],

            "Arunachal Pradesh": ["Anjaw", "Changlang", "Dibang Valley", "East Kameng", "East Siang", "Itanagar", "Kamle", "Kra Daadi", "Kurung Kumey", "Lepa Rada", "Lohit", "Longding", "Lower Dibang Valley", "Lower Siang", "Lower Subansiri", "Namsai", "Pakke Kessang", "Papum Pare", "Shi Yomi", "Siang", "Tawang", "Tirap", "Upper Siang", "Upper Subansiri", "West Kameng", "West Siang"],

            "Assam": ["Baksa", "Bajali", "Barpeta", "Biswanath", "Bongaigaon", "Cachar", "Charaideo", "Chirang", "Darrang", "Dhemaji", "Dhubri", "Dibrugarh", "Dima Hasao", "Goalpara", "Golaghat", "Hailakandi", "Hojai", "Jorhat", "Kamrup", "Kamrup Metropolitan", "Karbi Anglong", "Karimganj", "Kokrajhar", "Lakhimpur", "Majuli", "Morigaon", "Nagaon", "Nalbari", "Sivasagar", "Sonitpur", "South Salmara-Mankachar", "Tamulpur", "Tinsukia", "Udalguri", "West Karbi Anglong"],

            "Bihar": ["Araria", "Arwal", "Aurangabad", "Banka", "Begusarai", "Bhagalpur", "Bhojpur", "Buxar", "Darbhanga", "East Champaran", "Gaya", "Gopalganj", "Jamui", "Jehanabad", "Kaimur", "Katihar", "Khagaria", "Kishanganj", "Lakhisarai", "Madhepura", "Madhubani", "Munger", "Muzaffarpur", "Nalanda", "Nawada", "Patna", "Purnia", "Rohtas", "Saharsa", "Samastipur", "Saran", "Sheikhpura", "Sheohar", "Sitamarhi", "Siwan", "Supaul", "Vaishali", "West Champaran"],

            "Chhattisgarh": ["Balod", "Baloda Bazar", "Balrampur", "Bastar", "Bemetara", "Bijapur", "Bilaspur", "Dantewada", "Dhamtari", "Durg", "Gariaband", "Gaurela-Pendra-Marwahi", "Janjgir-Champa", "Jashpur", "Kabirdham", "Kanker", "Khairagarh", "Kondagaon", "Korba", "Koriya", "Mahasamund", "Manendragarh", "Mohla-Manpur", "Mungeli", "Narayanpur", "Raigarh", "Raipur", "Rajnandgaon", "Sakti", "Sarangarh", "Sukma", "Surajpur", "Surguja"],

            "Goa": ["North Goa", "South Goa"],

            "Gujarat": ["Ahmedabad", "Amreli", "Anand", "Aravalli", "Banaskantha", "Bharuch", "Bhavnagar", "Botad", "Chhota Udaipur", "Dahod", "Dang", "Devbhoomi Dwarka", "Gandhinagar", "Gir Somnath", "Jamnagar", "Junagadh", "Kheda", "Kutch", "Mahisagar", "Mehsana", "Morbi", "Narmada", "Navsari", "Panchmahal", "Patan", "Porbandar", "Rajkot", "Sabarkantha", "Surat", "Surendranagar", "Tapi", "Vadodara", "Valsad"],

            "Haryana": ["Ambala", "Bhiwani", "Charkhi Dadri", "Faridabad", "Fatehabad", "Gurugram", "Hisar", "Jhajjar", "Jind", "Kaithal", "Karnal", "Kurukshetra", "Mahendragarh", "Nuh", "Palwal", "Panchkula", "Panipat", "Rewari", "Rohtak", "Sirsa", "Sonipat", "Yamunanagar"],

            "Himachal Pradesh": ["Bilaspur", "Chamba", "Hamirpur", "Kangra", "Kinnaur", "Kullu", "Lahaul and Spiti", "Mandi", "Shimla", "Sirmaur", "Solan", "Una"],

            "Jharkhand": ["Bokaro", "Chatra", "Deoghar", "Dhanbad", "Dumka", "East Singhbhum", "Garhwa", "Giridih", "Godda", "Gumla", "Hazaribagh", "Jamtara", "Khunti", "Koderma", "Latehar", "Lohardaga", "Pakur", "Palamu", "Ramgarh", "Ranchi", "Sahibganj", "Seraikela Kharsawan", "Simdega", "West Singhbhum"],

            "Karnataka": ["Bagalkot", "Ballari", "Belagavi", "Bengaluru Rural", "Bengaluru Urban", "Bidar", "Chamarajanagar", "Chikkaballapura", "Chikkamagaluru", "Chitradurga", "Dakshina Kannada", "Davanagere", "Dharwad", "Gadag", "Hassan", "Haveri", "Kalaburagi", "Kodagu", "Kolar", "Koppal", "Mandya", "Mysuru", "Raichur", "Ramanagara", "Shivamogga", "Tumakuru", "Udupi", "Uttara Kannada", "Vijayapura", "Vijayanagara", "Yadgir"],

            "Kerala": ["Alappuzha", "Ernakulam", "Idukki", "Kannur", "Kasaragod", "Kollam", "Kottayam", "Kozhikode", "Malappuram", "Palakkad", "Pathanamthitta", "Thiruvananthapuram", "Thrissur", "Wayanad"],

            "Madhya Pradesh": ["Agar Malwa", "Alirajpur", "Anuppur", "Ashoknagar", "Balaghat", "Barwani", "Betul", "Bhind", "Bhopal", "Burhanpur", "Chhatarpur", "Chhindwara", "Damoh", "Datia", "Dewas", "Dhar", "Dindori", "Guna", "Gwalior", "Harda", "Hoshangabad", "Indore", "Jabalpur", "Jhabua", "Katni", "Khandwa", "Khargone", "Mandla", "Mandsaur", "Mauganj", "Morena", "Narsinghpur", "Neemuch", "Niwari", "Panna", "Raisen", "Rajgarh", "Ratlam", "Rewa", "Sagar", "Satna", "Sehore", "Seoni", "Shahdol", "Shajapur", "Sheopur", "Shivpuri", "Sidhi", "Singrauli", "Tikamgarh", "Ujjain", "Umaria", "Vidisha"],

            "Maharashtra": ["Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondia", "Hingoli", "Jalgaon", "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded", "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani", "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara", "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"],

            "Manipur": ["Bishnupur", "Chandel", "Churachandpur", "Imphal East", "Imphal West", "Jiribam", "Kakching", "Kamjong", "Kangpokpi", "Noney", "Pherzawl", "Senapati", "Tamenglong", "Tengnoupal", "Thoubal", "Ukhrul"],

            "Meghalaya": ["East Garo Hills", "East Jaintia Hills", "East Khasi Hills", "Eastern West Khasi Hills", "North Garo Hills", "Ri Bhoi", "South Garo Hills", "South West Garo Hills", "South West Khasi Hills", "West Garo Hills", "West Jaintia Hills", "West Khasi Hills"],

            "Mizoram": ["Aizawl", "Champhai", "Hnahthial", "Khawzawl", "Kolasib", "Lawngtlai", "Lunglei", "Mamit", "Saiha", "Saitual", "Serchhip"],

            "Nagaland": ["Chumoukedima", "Dimapur", "Kiphire", "Kohima", "Longleng", "Mokokchung", "Mon", "Niuland", "Noklak", "Peren", "Phek", "Shamator", "Tseminyu", "Tuensang", "Wokha", "Zunheboto"],

            "Odisha": ["Angul", "Balangir", "Balasore", "Bargarh", "Bhadrak", "Boudh", "Cuttack", "Deogarh", "Dhenkanal", "Gajapati", "Ganjam", "Jagatsinghpur", "Jajpur", "Jharsuguda", "Kalahandi", "Kandhamal", "Kendrapara", "Kendujhar", "Khordha", "Koraput", "Malkangiri", "Mayurbhanj", "Nabarangpur", "Nayagarh", "Nuapada", "Puri", "Rayagada", "Sambalpur", "Subarnapur", "Sundergarh"],

            "Punjab": ["Amritsar", "Barnala", "Bathinda", "Faridkot", "Fatehgarh Sahib", "Fazilka", "Ferozepur", "Gurdaspur", "Hoshiarpur", "Jalandhar", "Kaphurthala", "Ludhiana", "Malerkotla", "Mansa", "Moga", "Muktsar", "Pathankot", "Patiala", "Rupnagar", "Sahibzada Ajit Singh Nagar", "Shaheed Bhagat Singh Nagar", "Tarn Taran"],

            "Rajasthan": ["Ajmer", "Alwar", "Anupgarh", "Balotra", "Banswara", "Baran", "Barmer", "Beawar", "Bharatpur", "Bhilwara", "Bikaner", "Bundi", "Chittorgarh", "Churu", "Dausa", "Deeg", "Dholpur", "Didwana-Kuchaman", "Dudu", "Dungarpur", "Gangapur City", "Hanumangarh", "Jaipur", "Jaipur Rural", "Jaisalmer", "Jalore", "Jhalawar", "Jhunjhunu", "Jodhpur", "Jodhpur Rural", "Karauli", "Kekri", "Khairthal-Tijara", "Kota", "Kotputli-Behror", "Nagaur", "Neem Ka Thana", "Pali", "Phalodi", "Pratapgarh", "Rajsamand", "Salumbar", "Sanchore", "Sawai Madhopur", "Shahpura", "Sikar", "Sirohi", "Sri Ganganagar", "Tonk", "Udaipur"],

            "Sikkim": ["Gangtok", "Gyalshing", "Mangan", "Namchi", "Pakyong", "Soreng"],

            "Telangana": ["Adilabad", "Bhadradri Kothagudem", "Hanamkonda", "Hyderabad", "Jagtial", "Jangaon", "Jayashankar Bhupalpally", "Jogulamba Gadwal", "Kamareddy", "Karimnagar", "Khammam", "Kumuram Bheem Asifabad", "Mahabubabad", "Mahabubnagar", "Mancherial", "Medak", "Medchal-Malkajgiri", "Mulugu", "Nagarkurnool", "Nalgonda", "Narayanpet", "Nirmal", "Nizamabad", "Peddapalli", "Rajanna Sircilla", "Ranga Reddy", "Sangareddy", "Siddipet", "Suryapet", "Vikarabad", "Wanaparthy", "Warangal", "Yadadri Bhuvanagiri"],

            "Tripura": ["Dhalai", "Gomati", "Khowai", "North Tripura", "Sepahijala", "South Tripura", "Unakoti", "West Tripura"],

            "Uttar Pradesh": ["Agra", "Aligarh", "Ambedkar Nagar", "Amethi", "Amroha", "Auraiya", "Ayodhya", "Azamgarh", "Baghpat", "Bahraich", "Ballia", "Balrampur", "Banda", "Barabanki", "Bareilly", "Basti", "Bhadohi", "Bijnor", "Budaun", "Bulandshahr", "Chandauli", "Chitrakoot", "Deoria", "Etah", "Etawah", "Farrukhabad", "Fatehpur", "Firozabad", "Gautam Buddha Nagar", "Ghaziabad", "Ghazipur", "Gonda", "Gorakhpur", "Hamirpur", "Hapur", "Hardoi", "Hathras", "Jalaun", "Jaunpur", "Jhansi", "Kannauj", "Kanpur Dehat", "Kanpur Nagar", "Kasganj", "Kaushambi", "Kheri", "Kushinagar", "Lalitpur", "Lucknow", "Maharajganj", "Mahoba", "Mainpuri", "Mathura", "Mau", "Meerut", "Mirzapur", "Moradabad", "Muzaffarnagar", "Pilibhit", "Pratapgarh", "Prayagraj", "Raebareli", "Rampur", "Saharanpur", "Sambhal", "Sant Kabir Nagar", "Shahjahanpur", "Shamli", "Shravasti", "Siddharthnagar", "Sitapur", "Sonbhadra", "Sultanpur", "Unnao", "Varanasi"],

            "Uttarakhand": ["Almora", "Bageshwar", "Chamoli", "Champawat", "Dehradun", "Haridwar", "Nainital", "Pauri Garhwal", "Pithoragarh", "Rudraprayag", "Tehri Garhwal", "Udham Singh Nagar", "Uttarkashi"],

            "West Bengal": ["Alipurduar", "Bankura", "Birbhum", "Cooch Behar", "Dakshin Dinajpur", "Darjeeling", "Hooghly", "Howrah", "Jalpaiguri", "Jhargram", "Kalimpong", "Kolkata", "Malda", "Murshidabad", "Nadia", "North 24 Parganas", "Paschim Bardhaman", "Paschim Medinipur", "Purba Bardhaman", "Purba Medinipur", "Purulia", "South 24 Parganas", "Uttar Dinajpur"],

            "Andaman and Nicobar Islands": ["Nicobar", "North and Middle Andaman", "South Andaman"],

            "Chandigarh": ["Chandigarh"],

            "Dadra and Nagar Haveli and Daman and Diu": ["Dadra and Nagar Haveli", "Daman", "Diu"],

            "Delhi": ["Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North East Delhi", "North West Delhi", "Shahdara", "South Delhi", "South East Delhi", "South West Delhi", "West Delhi"],

            "Jammu and Kashmir": ["Anantnag", "Bandipora", "Baramulla", "Budgam", "Doda", "Ganderbal", "Jammu", "Kathua", "Kishtwar", "Kulgam", "Kupwara", "Poonch", "Pulwama", "Rajouri", "Ramban", "Reasi", "Samba", "Shopian", "Srinagar", "Udhampur"],

            "Ladakh": ["Kargil", "Leh"],

            "Lakshadweep": ["Lakshadweep"],

            "Puducherry": ["Karaikal", "Mahe", "Puducherry", "Yanam"]

        };



        // State Machine & Step Management

        let currentStep = 1;
        let isEmailVerified = false;
        let lastVerifiedEmail = '';

        let otpTimerInterval = null;

        let otpSecondsRemaining = 120; // 2 minutes expiry

        let uploadedPhotosList = []; // base64 or blob previews

        let leafletMap = null;

        let mapMarker = null;



        // Cancel / Back to Login Confirmation

        function handleGlobalCancel() {

            if (confirm("Are you sure you want to cancel mechanic registration? Any unsaved progress will be cleared.")) {

                window.location.href = contextPath + "/mechanic/login.jsp";

            }

        }



        // Global Error Tracking
        window._pageErrors = [];
        window.addEventListener('error', function(e) {
            window._pageErrors.push({ message: e.message, filename: e.filename, lineno: e.lineno, colno: e.colno, error: e.error ? e.error.stack : '' });
        });

        // Document Preview Lightbox Modal Functions (Global)
        function openDocPreviewModal(title, fileName, dataUrl, isPdf) {
            const modal = document.getElementById('docPreviewModal');
            const titleEl = document.getElementById('docModalTitle');
            const imgEl = document.getElementById('docModalImg');
            const pdfBox = document.getElementById('docModalPdfPlaceholder');
            const pdfName = document.getElementById('docModalPdfName');
            const noPrev = document.getElementById('docModalNoPreview');

            if (!modal) return;
            if (titleEl) titleEl.textContent = title + (fileName ? (' — ' + fileName) : '');

            if (isPdf) {
                if (imgEl) imgEl.style.display = 'none';
                if (pdfBox) {
                    pdfBox.style.display = 'block';
                    if (pdfName) pdfName.textContent = fileName || 'PDF Document';
                }
                if (noPrev) noPrev.style.display = 'none';
            } else if (dataUrl) {
                if (imgEl) {
                    imgEl.src = dataUrl;
                    imgEl.style.display = 'block';
                }
                if (pdfBox) pdfBox.style.display = 'none';
                if (noPrev) noPrev.style.display = 'none';
            } else {
                if (imgEl) imgEl.style.display = 'none';
                if (pdfBox) pdfBox.style.display = 'none';
                if (noPrev) noPrev.style.display = 'block';
            }

            modal.style.display = 'flex';
        }
        window.openDocPreviewModal = openDocPreviewModal;

        function closeDocPreviewModal(e) {
            if (!e || e.target.id === 'docPreviewModal' || e.target.closest('.doc-modal-close')) {
                const modal = document.getElementById('docPreviewModal');
                if (modal) modal.style.display = 'none';
            }
        }
        window.closeDocPreviewModal = closeDocPreviewModal;

        // DOM Loaded
        document.addEventListener('DOMContentLoaded', function () {



            // Step Elements

            const stepPanes = [

                document.getElementById('stepPane1'),

                document.getElementById('stepPane2'),

                document.getElementById('stepPane3'),

                document.getElementById('stepPane4'),

                document.getElementById('stepPane5')

            ];



            const stepIndicators = [

                document.getElementById('stepIndicator1'),

                document.getElementById('stepIndicator2'),

                document.getElementById('stepIndicator3'),

                document.getElementById('stepIndicator4'),

                document.getElementById('stepIndicator5')

            ];



            const stepperFill = document.getElementById('stepperProgressFill');

            const jsAlertBox = document.getElementById('jsAlertBox');

            const jsAlertText = document.getElementById('jsAlertText');



            // Form Inputs - Step 1

            const firstNameInput = document.getElementById('mechFirstName');

            const lastNameInput = document.getElementById('mechLastName');

            const genderSelect = document.getElementById('mechGender');

            const dobInput = document.getElementById('mechDob');

            const dobInstruction = document.getElementById('dobInstruction');

            const mobileInput = document.getElementById('mechMobile');

            const emailInput = document.getElementById('mechEmail');

            const passwordInput = document.getElementById('mechPassword');

            const togglePassBtn = document.getElementById('toggleMechPassBtn');

            const togglePassIcon = document.getElementById('toggleMechPassIcon');

            const aadhaarInput = document.getElementById('mechAadhaar');

            const aadhaarInstruction = document.getElementById('aadhaarInstruction');

            const aadhaarDocInput = document.getElementById('mechAadhaarDoc');

            const aadhaarDocInstruction = document.getElementById('aadhaarDocInstruction');

            const idProofDocInput = document.getElementById('mechIdProofDoc');

            const idProofDocInstruction = document.getElementById('idProofDocInstruction');



            // Form Inputs - Step 2 (OTP)

            const displayUserEmail = document.getElementById('displayUserEmail');

            const otpEmailTarget = document.getElementById('otpEmailTarget');

            const btnChangeEmail = document.getElementById('btnChangeEmail');

            const btnSendMechOtp = document.getElementById('btnSendMechOtp');

            const sendMechOtpIcon = document.getElementById('sendMechOtpIcon');

            const sendMechOtpText = document.getElementById('sendMechOtpText');

            const otpDigits = Array.from(document.querySelectorAll('.otp-digit-box'));

            const mechTimerCountdown = document.getElementById('mechTimerCountdown');

            const btnResendMechOtp = document.getElementById('btnResendMechOtp');

            const otpFeedback = document.getElementById('otpVerificationFeedback');



            // Form Inputs - Step 3 (Specializations)

            const specCards = Array.from(document.querySelectorAll('.spec-card'));

            const otherServiceInput = document.getElementById('otherServiceInput');



            // Form Inputs - Step 4 (Shop Details)

            const shopNameInput = document.getElementById('mechShopName');

            const shopTypeSelect = document.getElementById('mechShopType');

            const shopContactInput = document.getElementById('mechShopContact');

            const experienceSelect = document.getElementById('mechExperience');

            const openingTimeSelect = document.getElementById('openingTimeSelect');

            const closingTimeSelect = document.getElementById('closingTimeSelect');

            const shopDescTextarea = document.getElementById('mechDescription');

            const descCharCounter = document.getElementById('descCharCounter');

            const shopPhotosInput = document.getElementById('shopPhotosInput');

            const photoPreviewContainer = document.getElementById('photoPreviewContainer');



            // Form Inputs - Step 5 (Address & Location)

            const addr1Input = document.getElementById('mechAddr1');

            const addr2Input = document.getElementById('mechAddr2');

            const cityInput = document.getElementById('mechCity');

            const districtSelect = document.getElementById('mechDistrict');

            const stateSelect = document.getElementById('mechState');

            const pincodeInput = document.getElementById('mechPincode');

            const latHidden = document.getElementById('mechLatitude');

            const lngHidden = document.getElementById('mechLongitude');

            const coordsDisplayLabel = document.getElementById('coordsDisplayLabel');

            const btnUseCurrentLocation = document.getElementById('btnUseCurrentLocation');



            // Alerts helper
            function showAlert(msg, isSuccess) {
                if (!jsAlertBox) return;
                jsAlertBox.style.display = 'flex';
                if (isSuccess === true) {
                    jsAlertBox.className = 'card-alert-box card-alert-success';
                    const icon = jsAlertBox.querySelector('i');
                    if (icon) icon.className = 'fa-solid fa-circle-check';
                } else {
                    jsAlertBox.className = 'card-alert-box card-alert-error';
                    const icon = jsAlertBox.querySelector('i');
                    if (icon) icon.className = 'fa-solid fa-triangle-exclamation';
                }
                jsAlertText.textContent = msg;
                jsAlertBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }



            function hideAlert() {

                if (jsAlertBox) jsAlertBox.style.display = 'none';

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



            // =====================================================================

            // STEP 1 VALIDATION FUNCTIONS (Letters only, 10 Digits no +91, Glow)

            // =====================================================================

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



            function validateFirstName() {

                if (/[0-9]/.test(firstNameInput.value)) {

                    firstNameInput.value = firstNameInput.value.replace(/[0-9]/g, '');

                }

                const val = firstNameInput.value.trim();

                const errEl = document.getElementById('firstNameInstruction');

                if (!val) {

                    setFieldInvalid(firstNameInput, errEl, 'First name is required.');

                    return false;

                }

                if (/[^A-Za-z\s]/.test(val)) {

                    setFieldInvalid(firstNameInput, errEl, 'First name must contain letters only (no special characters).');

                    return false;

                }

                if (val.length < 2) {

                    setFieldInvalid(firstNameInput, errEl, 'First name must be at least 2 characters long.');

                    return false;

                }

                setFieldValid(firstNameInput, errEl);

                return true;

            }



            function validateLastName() {

                if (/[0-9]/.test(lastNameInput.value)) {

                    lastNameInput.value = lastNameInput.value.replace(/[0-9]/g, '');

                }

                const val = lastNameInput.value.trim();

                const errEl = document.getElementById('lastNameInstruction');

                if (!val) {

                    setFieldInvalid(lastNameInput, errEl, 'Last name is required.');

                    return false;

                }

                if (/[^A-Za-z\s]/.test(val)) {

                    setFieldInvalid(lastNameInput, errEl, 'Last name must contain letters only (no special characters).');

                    return false;

                }

                setFieldValid(lastNameInput, errEl);

                return true;

            }



            function validateGender() {

                const errEl = document.getElementById('genderInstruction');

                if (!genderSelect.value) {

                    setFieldInvalid(genderSelect, errEl, 'Please select your gender.');

                    return false;

                }

                setFieldValid(genderSelect, errEl);

                return true;

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

                const errEl = document.getElementById('dobInstruction');

                if (!val) {

                    setFieldInvalid(dobInput, errEl, 'Date of birth is required.');

                    return false;

                }



                const birthDate = new Date(val);

                if (isNaN(birthDate.getTime())) {

                    setFieldInvalid(dobInput, errEl, 'Please select a valid date of birth.');

                    return false;

                }



                const todayDate = new Date();

                if (birthDate > todayDate) {

                    setFieldInvalid(dobInput, errEl, 'Date of birth cannot be in the future.');

                    return false;

                }



                let age = todayDate.getFullYear() - birthDate.getFullYear();

                const m = todayDate.getMonth() - birthDate.getMonth();

                if (m < 0 || (m === 0 && todayDate.getDate() < birthDate.getDate())) {

                    age--;

                }



                if (age < 18) {

                    setFieldInvalid(dobInput, errEl, 'You must be at least 18 years old to create a mechanic account (age: ' + age + ').');

                    return false;

                }



                if (age > 120) {

                    setFieldInvalid(dobInput, errEl, 'Please enter a realistic date of birth.');

                    return false;

                }



                setFieldValid(dobInput, errEl, 'Eligible (Age: ' + age + ' years)');

                return true;

            }



            function validateMobile() {

                let val = mobileInput.value.replace(/\D/g, '');

                if (val.length > 10) val = val.substring(0, 10);

                mobileInput.value = val;



                const errEl = document.getElementById('mobileInstruction');

                if (!val) {

                    setFieldInvalid(mobileInput, errEl, 'Mobile number is required (10 digits).');

                    return false;

                }

                if (!/^[6-9]/.test(val)) {

                    setFieldInvalid(mobileInput, errEl, 'Mobile number must start with 6, 7, 8, or 9.');

                    return false;

                }

                if (val.length < 10) {

                    setFieldInvalid(mobileInput, errEl, 'Mobile number must be exactly 10 digits (' + val.length + '/10 entered).');

                    return false;

                }

                if (/^[6-9][0-9]{9}$/.test(val)) {

                    setFieldValid(mobileInput, errEl);

                    return true;

                }

                setFieldInvalid(mobileInput, errEl, 'Enter a valid 10-digit mobile number starting with 6–9.');

                return false;

            }



            function validateEmail() {

                const val = emailInput.value.trim().toLowerCase();

                const errEl = document.getElementById('emailInstruction');

                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

                if (!val) {

                    setFieldInvalid(emailInput, errEl, 'Email address is required.');

                    return false;

                }

                if (!emailRegex.test(val)) {

                    setFieldInvalid(emailInput, errEl, 'Please enter a valid email address (e.g. mechanic@domain.com).');

                    return false;

                }

                setFieldValid(emailInput, errEl);

                return true;

            }



            function validatePassword() {

                const val = passwordInput.value;

                const errEl = document.getElementById('passwordInstruction');

                if (!val) {

                    setFieldInvalid(passwordInput, errEl, 'Password is required (8-12 characters).');

                    return false;

                }

                if (val.length < 8 || val.length > 12) {

                    setFieldInvalid(passwordInput, errEl, 'Password must be 8 to 12 characters (currently ' + val.length + ').');

                    return false;

                }

                if (!/[A-Z]/.test(val)) {

                    setFieldInvalid(passwordInput, errEl, 'Password must include at least 1 uppercase letter (A-Z).');

                    return false;

                }

                if (!/[a-z]/.test(val)) {

                    setFieldInvalid(passwordInput, errEl, 'Password must include at least 1 lowercase letter (a-z).');

                    return false;

                }

                if (!/[0-9]/.test(val)) {

                    setFieldInvalid(passwordInput, errEl, 'Password must include at least 1 number (0-9).');

                    return false;

                }

                if (!/[!@#$%^&*(),.?":{}|<>\-_=+]/.test(val)) {

                    setFieldInvalid(passwordInput, errEl, 'Password must include at least 1 special symbol (!@#$%^&* etc.).');

                    return false;

                }

                setFieldValid(passwordInput, errEl, 'Strong password');

                return true;

            }



            // Real-time Event Listeners for Step 1

            firstNameInput.addEventListener('input', validateFirstName);

            firstNameInput.addEventListener('blur', validateFirstName);



            lastNameInput.addEventListener('input', validateLastName);

            lastNameInput.addEventListener('blur', validateLastName);



            genderSelect.addEventListener('change', validateGender);



            if (dobInput) {

                dobInput.addEventListener('change', validateDob);

                dobInput.addEventListener('input', validateDob);

                dobInput.addEventListener('blur', validateDob);

            }



            mobileInput.addEventListener('input', validateMobile);

            mobileInput.addEventListener('blur', validateMobile);



            emailInput.addEventListener('input', function () {
                validateEmail();
                if (lastVerifiedEmail && emailInput.value.trim().toLowerCase() !== lastVerifiedEmail) {
                    isEmailVerified = false;
                    otpDigits.forEach(function (d) {
                        d.classList.remove('verified');
                        d.readOnly = false;
                        d.value = '';
                    });
                }
            });

            emailInput.addEventListener('blur', validateEmail);



            passwordInput.addEventListener('input', validatePassword);

            passwordInput.addEventListener('blur', validatePassword);



            if (togglePassBtn) {

                togglePassBtn.addEventListener('click', function () {

                    const isPass = passwordInput.getAttribute('type') === 'password';

                    passwordInput.setAttribute('type', isPass ? 'text' : 'password');

                    togglePassIcon.className = isPass ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye';

                });

            }



            // Aadhaar Number 12-digit formatting & validation

            if (aadhaarInput) {

                aadhaarInput.addEventListener('input', function () {

                    let val = aadhaarInput.value.replace(/\D/g, '');

                    if (val.length > 12) val = val.substring(0, 12);

                    let formatted = '';

                    for (let i = 0; i < val.length; i++) {

                        if (i > 0 && i % 4 === 0) formatted += ' ';

                        formatted += val[i];

                    }

                    aadhaarInput.value = formatted;

                    validateAadhaar();

                });

                aadhaarInput.addEventListener('blur', validateAadhaar);

            }



            function validateAadhaar() {

                if (!aadhaarInput) return true;

                const digits = aadhaarInput.value.replace(/\D/g, '');

                if (!digits) {

                    setFieldInvalid(aadhaarInput, aadhaarInstruction, 'Aadhaar number is required (12 digits only).');

                    return false;

                }

                if (digits.length < 12) {

                    setFieldInvalid(aadhaarInput, aadhaarInstruction, 'Aadhaar number must be exactly 12 digits (' + digits.length + '/12 entered).');

                    return false;

                }

                setFieldValid(aadhaarInput, aadhaarInstruction);

                return true;

            }



            function validateAadhaarDoc() {

                if (!aadhaarDocInput) return true;

                const dropzone = document.getElementById('aadhaarDropzone');

                if (!aadhaarDocInput.files || aadhaarDocInput.files.length === 0) {

                    if (dropzone) dropzone.classList.add('glow-invalid');

                    if (aadhaarDocInstruction) {

                        aadhaarDocInstruction.textContent = 'Please upload your Aadhaar card document (JPG, PNG, or PDF).';

                        aadhaarDocInstruction.style.display = 'block';

                    }

                    return false;

                }

                const file = aadhaarDocInput.files[0];

                if (file.size > 5 * 1024 * 1024) {

                    if (dropzone) dropzone.classList.add('glow-invalid');

                    if (aadhaarDocInstruction) {

                        aadhaarDocInstruction.textContent = 'Aadhaar document size must be under 5 MB.';

                        aadhaarDocInstruction.style.display = 'block';

                    }

                    return false;

                }

                if (dropzone) dropzone.classList.remove('glow-invalid');

                if (aadhaarDocInstruction) aadhaarDocInstruction.style.display = 'none';

                return true;

            }



            function validateIdProofDoc() {

                if (!idProofDocInput) return true;

                const dropzone = document.getElementById('idProofDropzone');

                if (!idProofDocInput.files || idProofDocInput.files.length === 0) {

                    if (dropzone) dropzone.classList.add('glow-invalid');

                    if (idProofDocInstruction) {

                        idProofDocInstruction.textContent = 'Please upload your ID proof document (JPG, PNG, or PDF).';

                        idProofDocInstruction.style.display = 'block';

                    }

                    return false;

                }

                const file = idProofDocInput.files[0];

                if (file.size > 5 * 1024 * 1024) {

                    if (dropzone) dropzone.classList.add('glow-invalid');

                    if (idProofDocInstruction) {

                        idProofDocInstruction.textContent = 'ID proof document size must be under 5 MB.';

                        idProofDocInstruction.style.display = 'block';

                    }

                    return false;

                }

                if (dropzone) dropzone.classList.remove('glow-invalid');

                if (idProofDocInstruction) idProofDocInstruction.style.display = 'none';

                return true;

            }



            // Aadhaar & ID Proof preview state
            let aadhaarDocDataUrl = null;
            let aadhaarDocIsPdf = false;
            let idProofDocDataUrl = null;
            let idProofDocIsPdf = false;

            function formatDocFileSize(bytes) {
                if (!bytes || isNaN(bytes)) return '0 KB';
                if (bytes < 1024 * 1024) {
                    return (bytes / 1024).toFixed(1) + ' KB';
                }
                return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
            }

            // Aadhaar file select & clear
            if (aadhaarDocInput) {
                aadhaarDocInput.addEventListener('change', function () {
                    if (this.files && this.files[0]) {
                        const file = this.files[0];
                        const nameEl = document.getElementById('aadhaarFileName');
                        const sizeEl = document.getElementById('aadhaarFileSize');
                        const thumbImg = document.getElementById('aadhaarThumbImg');
                        const pdfIcon = document.getElementById('aadhaarPdfIcon');
                        const genericIcon = document.getElementById('aadhaarGenericIcon');

                        if (nameEl) {
                            nameEl.textContent = file.name;
                            nameEl.title = file.name;
                        }
                        if (sizeEl) {
                            sizeEl.textContent = formatDocFileSize(file.size);
                        }

                        if (file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf')) {
                            aadhaarDocIsPdf = true;
                            aadhaarDocDataUrl = null;
                            if (thumbImg) thumbImg.style.display = 'none';
                            if (pdfIcon) pdfIcon.style.display = 'flex';
                            if (genericIcon) genericIcon.style.display = 'none';
                        } else if (file.type.startsWith('image/')) {
                            aadhaarDocIsPdf = false;
                            const reader = new FileReader();
                            reader.onload = function(e) {
                                aadhaarDocDataUrl = e.target.result;
                                if (thumbImg) {
                                    thumbImg.src = e.target.result;
                                    thumbImg.style.display = 'block';
                                }
                                if (pdfIcon) pdfIcon.style.display = 'none';
                                if (genericIcon) genericIcon.style.display = 'none';
                            };
                            reader.readAsDataURL(file);
                        } else {
                            aadhaarDocIsPdf = false;
                            aadhaarDocDataUrl = null;
                            if (thumbImg) thumbImg.style.display = 'none';
                            if (pdfIcon) pdfIcon.style.display = 'none';
                            if (genericIcon) genericIcon.style.display = 'flex';
                        }

                        document.getElementById('aadhaarDropzone').style.display = 'none';
                        document.getElementById('aadhaarFileBadge').style.display = 'flex';
                        validateAadhaarDoc();
                    }
                });
            }

            const btnClearAadhaar = document.getElementById('btnClearAadhaarDoc');
            if (btnClearAadhaar) {
                btnClearAadhaar.addEventListener('click', function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    if (aadhaarDocInput) aadhaarDocInput.value = '';
                    aadhaarDocDataUrl = null;
                    aadhaarDocIsPdf = false;
                    document.getElementById('aadhaarDropzone').style.display = 'flex';
                    document.getElementById('aadhaarFileBadge').style.display = 'none';
                    validateAadhaarDoc();
                });
            }

            const btnInspectAadhaar = document.getElementById('btnInspectAadhaarDoc');
            const aadhaarPreviewWrapper = document.getElementById('aadhaarPreviewWrapper');
            function previewAadhaar() {
                const name = (aadhaarDocInput && aadhaarDocInput.files[0]) ? aadhaarDocInput.files[0].name : 'Aadhaar Card Document';
                openDocPreviewModal('Aadhaar Card Document', name, aadhaarDocDataUrl, aadhaarDocIsPdf);
            }
            if (btnInspectAadhaar) btnInspectAadhaar.addEventListener('click', previewAadhaar);
            if (aadhaarPreviewWrapper) aadhaarPreviewWrapper.addEventListener('click', previewAadhaar);

            // ID Proof file select & clear
            if (idProofDocInput) {
                idProofDocInput.addEventListener('change', function () {
                    if (this.files && this.files[0]) {
                        const file = this.files[0];
                        const nameEl = document.getElementById('idProofFileName');
                        const sizeEl = document.getElementById('idProofFileSize');
                        const thumbImg = document.getElementById('idProofThumbImg');
                        const pdfIcon = document.getElementById('idProofPdfIcon');
                        const genericIcon = document.getElementById('idProofGenericIcon');

                        if (nameEl) {
                            nameEl.textContent = file.name;
                            nameEl.title = file.name;
                        }
                        if (sizeEl) {
                            sizeEl.textContent = formatDocFileSize(file.size);
                        }

                        if (file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf')) {
                            idProofDocIsPdf = true;
                            idProofDocDataUrl = null;
                            if (thumbImg) thumbImg.style.display = 'none';
                            if (pdfIcon) pdfIcon.style.display = 'flex';
                            if (genericIcon) genericIcon.style.display = 'none';
                        } else if (file.type.startsWith('image/')) {
                            idProofDocIsPdf = false;
                            const reader = new FileReader();
                            reader.onload = function(e) {
                                idProofDocDataUrl = e.target.result;
                                if (thumbImg) {
                                    thumbImg.src = e.target.result;
                                    thumbImg.style.display = 'block';
                                }
                                if (pdfIcon) pdfIcon.style.display = 'none';
                                if (genericIcon) genericIcon.style.display = 'none';
                            };
                            reader.readAsDataURL(file);
                        } else {
                            idProofDocIsPdf = false;
                            idProofDocDataUrl = null;
                            if (thumbImg) thumbImg.style.display = 'none';
                            if (pdfIcon) pdfIcon.style.display = 'none';
                            if (genericIcon) genericIcon.style.display = 'flex';
                        }

                        document.getElementById('idProofDropzone').style.display = 'none';
                        document.getElementById('idProofFileBadge').style.display = 'flex';
                        validateIdProofDoc();
                    }
                });
            }

            const btnClearIdProof = document.getElementById('btnClearIdProofDoc');
            if (btnClearIdProof) {
                btnClearIdProof.addEventListener('click', function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    if (idProofDocInput) idProofDocInput.value = '';
                    idProofDocDataUrl = null;
                    idProofDocIsPdf = false;
                    document.getElementById('idProofDropzone').style.display = 'flex';
                    document.getElementById('idProofFileBadge').style.display = 'none';
                    validateIdProofDoc();
                });
            }

            const btnInspectIdProof = document.getElementById('btnInspectIdProofDoc');
            const idProofPreviewWrapper = document.getElementById('idProofPreviewWrapper');
            function previewIdProof() {
                const name = (idProofDocInput && idProofDocInput.files[0]) ? idProofDocInput.files[0].name : 'ID Proof Document';
                openDocPreviewModal('ID Proof Document', name, idProofDocDataUrl, idProofDocIsPdf);
            }
            if (btnInspectIdProof) btnInspectIdProof.addEventListener('click', previewIdProof);
            if (idProofPreviewWrapper) idProofPreviewWrapper.addEventListener('click', previewIdProof);

            // Step 1 Next Button

            document.getElementById('btnNextStep1').addEventListener('click', function () {

                hideAlert();

                const v1 = validateFirstName();

                const v2 = validateLastName();

                const v3 = validateGender();

                const vDob = validateDob();

                const v4 = validateMobile();

                const v5 = validateEmail();

                const v6 = validatePassword();

                const vAadhaar = validateAadhaar();

                const vAadhaarDoc = validateAadhaarDoc();

                const vIdProofDoc = validateIdProofDoc();



                if (v1 && v2 && v3 && vDob && v4 && v5 && v6 && vAadhaar && vAadhaarDoc && vIdProofDoc) {

                    // Update email display for Step 2

                    const email = emailInput.value.trim().toLowerCase();

                    displayUserEmail.textContent = email;

                    otpEmailTarget.textContent = email;







                    // If email is already verified, proceed to Step 3
                    if (isEmailVerified && lastVerifiedEmail === email) {
                        goToStep(3);
                    } else {
                        goToStep(2);
                    }

                } else {

                    showAlert('Please correct all highlighted fields before proceeding.');

                    if (!v1) firstNameInput.focus();

                    else if (!v2) lastNameInput.focus();

                    else if (!v3) genderSelect.focus();

                    else if (!vDob) dobInput.focus();

                    else if (!v4) mobileInput.focus();

                    else if (!v5) emailInput.focus();

                    else if (!v6) passwordInput.focus();

                    else if (!vAadhaar) aadhaarInput.focus();

                    else if (!vAadhaarDoc) document.getElementById('mechAadhaarDoc').focus();

                    else if (!vIdProofDoc) document.getElementById('mechIdProofDoc').focus();

                }

            });



            // =====================================================================

            // STEP 2: EMAIL OTP HANDLING

            // =====================================================================

            btnChangeEmail.addEventListener('click', function () {
                clearInterval(otpTimerInterval);
                if (mechTimerCountdown) mechTimerCountdown.textContent = '00:00';
                btnResendMechOtp.disabled = true;
                goToStep(1);
                emailInput.focus();
            });

            document.getElementById('btnBackToStep1').addEventListener('click', function () {
                clearInterval(otpTimerInterval);
                if (mechTimerCountdown) mechTimerCountdown.textContent = '00:00';
                btnResendMechOtp.disabled = true;
                goToStep(1);
            });



            function startOtpCountdown(duration) {

                duration = duration || 120;

                clearInterval(otpTimerInterval);

                otpSecondsRemaining = duration;

                btnResendMechOtp.disabled = true;



                updateTimerDisplay();



                otpTimerInterval = setInterval(function () {

                    otpSecondsRemaining--;

                    updateTimerDisplay();



                    if (otpSecondsRemaining <= 0) {

                        clearInterval(otpTimerInterval);

                        btnResendMechOtp.disabled = false;

                        mechTimerCountdown.textContent = '00:00';

                    }

                }, 1000);

            }



            function updateTimerDisplay() {

                const mins = Math.floor(otpSecondsRemaining / 60);

                const secs = otpSecondsRemaining % 60;

                mechTimerCountdown.textContent = (mins < 10 ? '0' : '') + mins + ':' + (secs < 10 ? '0' : '') + secs;

            }



            // Timer is idle until user clicks 'Send OTP'
            btnResendMechOtp.disabled = true;
            if (mechTimerCountdown) mechTimerCountdown.textContent = '00:00';



            // Send OTP AJAX

            btnSendMechOtp.addEventListener('click', function () {

                sendOtpAction(false);

            });



            btnResendMechOtp.addEventListener('click', function () {

                sendOtpAction(true);

            });



            function sendOtpAction(isResend) {

                const email = emailInput.value.trim().toLowerCase();

                if (!email) {

                    showAlert('Please provide your email address in Step 1 first.');

                    goToStep(1);

                    return;

                }



                hideAlert();

                otpFeedback.style.display = 'none';



                if (isResend) {

                    btnResendMechOtp.disabled = true;

                    btnResendMechOtp.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Sending...';

                } else {

                    btnSendMechOtp.disabled = true;

                    sendMechOtpIcon.className = 'fa-solid fa-circle-notch fa-spin';

                    sendMechOtpText.textContent = 'Sending...';

                }



                const params = new URLSearchParams();

                params.append('email', email);



                fetch(contextPath + '/auth/mechanic-send-otp', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
                    body: params.toString()
                })

                .then(function (res) { return res.json(); })

                .then(function (data) {

                    if (data.success) {

                        startOtpCountdown(120);

                        otpFeedback.className = 'field-instruction-msg show-valid';

                        otpFeedback.innerHTML = '<i class="fa-solid fa-circle-check"></i> ' + data.message;

                        otpDigits[0].focus();

                    } else {

                        showAlert(data.message);

                        otpFeedback.className = 'field-instruction-msg show-error';

                        otpFeedback.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> ' + data.message;

                    }

                })

                .catch(function (err) {

                    console.error('Send OTP error:', err);

                    showAlert('Connection error while sending OTP. Please try again.');

                })

                .finally(function () {

                    if (isResend) {

                        btnResendMechOtp.innerHTML = '<i class="fa-solid fa-rotate-right"></i> Resend OTP';

                    } else {

                        btnSendMechOtp.disabled = false;

                        sendMechOtpIcon.className = 'fa-solid fa-paper-plane';

                        sendMechOtpText.textContent = 'Send OTP';

                    }

                });

            }



            // OTP Box Auto-Advance and Paste Logic

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

                        input.classList.add('filled');

                        if (idx < otpDigits.length - 1) {

                            otpDigits[idx + 1].focus();

                        }

                    } else {

                        input.classList.remove('filled');

                    }



                    checkAllOtpEntered();

                });



                input.addEventListener('paste', function (e) {

                    e.preventDefault();

                    const pasteData = (e.clipboardData || window.clipboardData).getData('text').replace(/[^0-9]/g, '');

                    if (pasteData.length >= 6) {

                        for (let i = 0; i < 6; i++) {

                            otpDigits[i].value = pasteData.charAt(i);

                            otpDigits[i].classList.add('filled');

                        }

                        otpDigits[5].focus();

                        checkAllOtpEntered();

                    }

                });

            });



            function checkAllOtpEntered() {

                const code = otpDigits.map(function (d) { return d.value; }).join('');

                if (code.length === 6) {

                    verifyMechOtpAction(code);

                }

            }



            function verifyMechOtpAction(otpCode) {

                const email = emailInput.value.trim().toLowerCase();

                const verifyBtn = document.getElementById('btnVerifyOtpContinue');



                otpFeedback.className = 'field-instruction-msg show-valid';

                otpFeedback.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Verifying OTP code...';



                const params = new URLSearchParams();

                params.append('email', email);

                params.append('otp', otpCode);



                fetch(contextPath + '/auth/mechanic-verify-otp', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
                    body: params.toString()
                })
                .then(function (res) { return res.json(); })
                .then(function (data) {
                    if (data.success) {
                        isEmailVerified = true;
                        lastVerifiedEmail = email;
                        clearInterval(otpTimerInterval);



                        otpFeedback.className = 'field-instruction-msg show-valid';

                        otpFeedback.innerHTML = '<i class="fa-solid fa-circle-check"></i> ' + data.message;



                        otpDigits.forEach(function (d) {

                            d.classList.add('verified');

                            d.readOnly = true;

                        });



                        setTimeout(function () {

                            goToStep(3);

                        }, 700);

                    } else {

                        isEmailVerified = false;

                        otpFeedback.className = 'field-instruction-msg show-error';

                        otpFeedback.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> ' + data.message;

                        showAlert(data.message);

                    }

                })

                .catch(function (err) {

                    console.error('Verify OTP error:', err);

                    otpFeedback.className = 'field-instruction-msg show-error';

                    otpFeedback.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Verification error. Please try again.';

                });

            }



            document.getElementById('btnVerifyOtpContinue').addEventListener('click', function () {

                const code = otpDigits.map(function (d) { return d.value; }).join('');

                if (code.length !== 6) {

                    showAlert('Please enter all 6 digits of the OTP verification code.');

                    otpDigits[0].focus();

                    return;

                }

                if (isEmailVerified) {

                    goToStep(3);

                } else {

                    verifyMechOtpAction(code);

                }

            });



            // =====================================================================

            // STEP 3: WORK SPECIALIZATION (Cards Multiple Select + Other)

            // =====================================================================

            specCards.forEach(function (card) {

                card.addEventListener('click', function () {

                    const chk = card.querySelector('input[type="checkbox"]');

                    const checkIcon = card.querySelector('.spec-checkbox-box i');

                    chk.checked = !chk.checked;



                    if (chk.checked) {

                        card.classList.add('selected');

                        if (checkIcon) checkIcon.style.display = 'inline-block';

                    } else {

                        card.classList.remove('selected');

                        if (checkIcon) checkIcon.style.display = 'none';

                    }

                    validateSpecializations();

                });

            });



            function validateSpecializations() {

                const checkedCount = document.querySelectorAll('input[name="specializations"]:checked').length;

                const otherVal = otherServiceInput.value.trim();

                const errEl = document.getElementById('specInstruction');



                if (checkedCount === 0 && !otherVal) {

                    errEl.className = 'field-instruction-msg show-error';

                    errEl.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> Select at least one service or enter an other service.';

                    return false;

                }

                errEl.className = 'field-instruction-msg';

                errEl.style.display = 'none';

                errEl.innerHTML = '';

                return true;

            }



            otherServiceInput.addEventListener('input', validateSpecializations);



            document.getElementById('btnBackToStep2').addEventListener('click', function () {

                goToStep(2);

            });



            document.getElementById('btnNextStep3').addEventListener('click', function () {

                if (validateSpecializations()) {

                    goToStep(4);

                } else {

                    showAlert('Please select at least one service specialization or specify an other service.');

                }

            });



            // =====================================================================

            // STEP 4: SHOP DETAILS, WORKING HOURS & PHOTO UPLOADS

            // =====================================================================

            function validateShopName() {

                const val = shopNameInput.value.trim();

                const errEl = document.getElementById('shopNameInstruction');

                if (!val) {

                    setFieldInvalid(shopNameInput, errEl, 'Shop / garage name is required.');

                    return false;

                }

                if (val.length < 3) {

                    setFieldInvalid(shopNameInput, errEl, 'Shop name must be at least 3 characters long.');

                    return false;

                }

                setFieldValid(shopNameInput, errEl);

                return true;

            }



            function validateShopType() {

                const errEl = document.getElementById('shopTypeInstruction');

                if (!shopTypeSelect.value) {

                    setFieldInvalid(shopTypeSelect, errEl, 'Please select your shop type.');

                    return false;

                }

                setFieldValid(shopTypeSelect, errEl);

                return true;

            }



            function validateShopContact() {

                let val = shopContactInput.value.replace(/\D/g, '');

                if (val.length > 10) val = val.substring(0, 10);

                shopContactInput.value = val;



                const errEl = document.getElementById('shopContactInstruction');

                if (!val) {

                    setFieldInvalid(shopContactInput, errEl, 'Shop contact number is required.');

                    return false;

                }

                if (!/^[6-9]/.test(val)) {

                    setFieldInvalid(shopContactInput, errEl, 'Shop contact number must start with 6, 7, 8, or 9.');

                    return false;

                }

                if (val.length < 10) {

                    setFieldInvalid(shopContactInput, errEl, 'Shop contact number must be exactly 10 digits (' + val.length + '/10 entered).');

                    return false;

                }

                setFieldValid(shopContactInput, errEl);

                return true;

            }



            shopNameInput.addEventListener('input', validateShopName);

            shopNameInput.addEventListener('blur', validateShopName);



            shopTypeSelect.addEventListener('change', validateShopType);



            function validateExperience() {

                const errEl = document.getElementById('experienceInstruction');

                if (!experienceSelect.value) {

                    setFieldInvalid(experienceSelect, errEl, 'Please select your years of experience.');

                    return false;

                }

                setFieldValid(experienceSelect, errEl);

                return true;

            }



            experienceSelect.addEventListener('change', validateExperience);



            shopContactInput.addEventListener('input', validateShopContact);

            shopContactInput.addEventListener('blur', validateShopContact);



            // Description character counter (0 / 250)

            shopDescTextarea.addEventListener('input', function () {

                const len = shopDescTextarea.value.length;

                descCharCounter.textContent = len + ' / 250';

                if (len >= 250) {

                    descCharCounter.style.color = '#DC2626';

                } else {

                    descCharCounter.style.color = '#9CA3AF';

                }

            });



            // Shop Photo Upload Previews

            shopPhotosInput.addEventListener('change', function (e) {

                const files = Array.from(e.target.files);

                if (files.length + uploadedPhotosList.length > 5) {

                    alert('You can upload a maximum of 5 shop photos.');

                }



                files.slice(0, 5 - uploadedPhotosList.length).forEach(function (file) {

                    if (file.size > 5 * 1024 * 1024) {

                        alert('Photo ' + file.name + ' exceeds 5 MB size limit.');

                        return;

                    }

                    const reader = new FileReader();

                    reader.onload = function (evt) {

                        const photoObj = { file: file, src: evt.target.result, id: Date.now() + Math.random() };

                        uploadedPhotosList.push(photoObj);

                        renderPhotoPreviews();

                    };

                    reader.readAsDataURL(file);

                });

            });



            function renderPhotoPreviews() {

                photoPreviewContainer.innerHTML = '';

                uploadedPhotosList.forEach(function (p, idx) {

                    const card = document.createElement('div');

                    card.className = 'photo-preview-item';

                    card.innerHTML = '<img src="' + p.src + '" alt="Shop Photo">' +

                                     '<button type="button" class="btn-remove-photo" data-idx="' + idx + '" title="Remove photo">&times;</button>';

                    photoPreviewContainer.appendChild(card);

                });



                // Attach remove handlers

                photoPreviewContainer.querySelectorAll('.btn-remove-photo').forEach(function (btn) {

                    btn.addEventListener('click', function () {

                        const idx = parseInt(btn.getAttribute('data-idx'));

                        uploadedPhotosList.splice(idx, 1);

                        renderPhotoPreviews();

                    });

                });

            }



            document.getElementById('btnBackToStep3').addEventListener('click', function () {

                goToStep(3);

            });



            document.getElementById('btnNextStep4').addEventListener('click', function () {

                hideAlert();

                const v1 = validateShopName();

                const v2 = validateShopType();

                const v3 = validateShopContact();

                const v4 = validateExperience();



                if (v1 && v2 && v3 && v4) {

                    goToStep(5);

                    // Initialize Leaflet map on step 5 display

                    setTimeout(initLeafletMap, 150);

                } else {

                    showAlert('Please complete all required shop details before proceeding.');

                    if (!v1) shopNameInput.focus();

                    else if (!v2) shopTypeSelect.focus();

                    else if (!v3) shopContactInput.focus();

                    else if (!v4) experienceSelect.focus();

                }

            });



            // =====================================================================

            // STEP 5: SHOP ADDRESS & INTERACTIVE LEAFLET GPS MAP

            // =====================================================================

            function populateStates() {

                stateSelect.innerHTML = '';

                Object.keys(INDIA_STATES_DISTRICTS).sort().forEach(function (stateName) {

                    const opt = document.createElement('option');

                    opt.value = stateName;

                    opt.textContent = stateName;

                    if (stateName === 'Tamil Nadu') opt.selected = true;

                    stateSelect.appendChild(opt);

                });

                populateDistricts('Tamil Nadu');

            }



            function populateDistricts(selectedState) {

                districtSelect.innerHTML = '<option value="" disabled selected>Select district</option>';

                const districts = INDIA_STATES_DISTRICTS[selectedState] || [];

                districts.forEach(function (dist) {

                    const opt = document.createElement('option');

                    opt.value = dist;

                    opt.textContent = dist;

                    districtSelect.appendChild(opt);

                });

            }



            stateSelect.addEventListener('change', function () {

                populateDistricts(stateSelect.value);

                districtSelect.classList.remove('glow-valid', 'glow-invalid');

                document.getElementById('districtInstruction').style.display = 'none';

            });



            populateStates();



            function validateAddress1() {

                const val = addr1Input.value.trim();

                const errEl = document.getElementById('addr1Instruction');

                if (!val) {

                    setFieldInvalid(addr1Input, errEl, 'Address Line 1 is required.');

                    return false;

                }

                setFieldValid(addr1Input, errEl);

                return true;

            }



            function validateCity() {

                const val = cityInput.value.trim();

                const errEl = document.getElementById('cityInstruction');

                if (!val) {

                    setFieldInvalid(cityInput, errEl, 'City or Town is required.');

                    return false;

                }

                if (/[0-9]/.test(val)) {

                    setFieldInvalid(cityInput, errEl, 'City must contain letters only.');

                    return false;

                }

                setFieldValid(cityInput, errEl);

                return true;

            }



            function validateDistrict() {

                const errEl = document.getElementById('districtInstruction');

                if (!districtSelect.value) {

                    setFieldInvalid(districtSelect, errEl, 'Please select your district.');

                    return false;

                }

                setFieldValid(districtSelect, errEl);

                return true;

            }



            function validatePincode() {

                let val = pincodeInput.value.replace(/\D/g, '');

                if (val.length > 6) val = val.substring(0, 6);

                pincodeInput.value = val;



                const errEl = document.getElementById('pincodeInstruction');

                if (!val) {

                    setFieldInvalid(pincodeInput, errEl, '6-digit pincode is required.');

                    return false;

                }

                if (val.length < 6) {

                    setFieldInvalid(pincodeInput, errEl, 'Pincode must be exactly 6 digits (' + val.length + '/6 entered).');

                    return false;

                }

                setFieldValid(pincodeInput, errEl);

                return true;

            }



            addr1Input.addEventListener('input', validateAddress1);

            addr1Input.addEventListener('blur', validateAddress1);



            cityInput.addEventListener('input', validateCity);

            cityInput.addEventListener('blur', validateCity);



            districtSelect.addEventListener('change', validateDistrict);



            pincodeInput.addEventListener('input', validatePincode);

            pincodeInput.addEventListener('blur', validatePincode);



            // Leaflet Map Initialization

            function initLeafletMap() {

                if (leafletMap) {

                    leafletMap.invalidateSize();

                    return;

                }



                const initialLat = parseFloat(latHidden.value) || 10.7905;

                const initialLng = parseFloat(lngHidden.value) || 78.7047;



                leafletMap = L.map('mechanicMap', {

                    center: [initialLat, initialLng],

                    zoom: 13,

                    zoomControl: true

                });



                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {

                    attribution: '&copy; OpenStreetMap contributors',

                    maxZoom: 19

                }).addTo(leafletMap);



                // Custom Orange Marker

                const orangeMarkerIcon = L.divIcon({

                    className: 'custom-map-pin',

                    html: '<div style="background:#F97316; width:34px; height:34px; border-radius:50% 50% 50% 0; transform:rotate(-45deg); display:flex; align-items:center; justify-content:center; box-shadow:0 4px 12px rgba(0,0,0,0.35); border:3px solid #FFF;"><i class="fa-solid fa-screwdriver-wrench" style="transform:rotate(45deg); color:#FFF; font-size:14px;"></i></div>',

                    iconSize: [34, 34],

                    iconAnchor: [17, 34],

                    popupAnchor: [0, -34]

                });



                mapMarker = L.marker([initialLat, initialLng], {

                    draggable: true,

                    icon: orangeMarkerIcon

                }).addTo(leafletMap);



                mapMarker.bindPopup('<strong>Your Shop Location</strong><br>Drag pin or click map to move').openPopup();



                updateCoordsDisplay(initialLat, initialLng);



                // Marker Drag Event

                mapMarker.on('dragend', function (e) {

                    const pos = mapMarker.getLatLng();

                    updateCoordsDisplay(pos.lat, pos.lng);

                    reverseGeocodeCoords(pos.lat, pos.lng);

                });



                // Map Click Event

                leafletMap.on('click', function (e) {

                    mapMarker.setLatLng(e.latlng);

                    updateCoordsDisplay(e.latlng.lat, e.latlng.lng);

                    mapMarker.openPopup();

                    reverseGeocodeCoords(e.latlng.lat, e.latlng.lng);

                });

            }



            function updateCoordsDisplay(lat, lng) {

                const cleanLat = lat.toFixed(4);

                const cleanLng = lng.toFixed(4);

                latHidden.value = cleanLat;

                lngHidden.value = cleanLng;

                coordsDisplayLabel.textContent = cleanLat + '° N, ' + cleanLng + '° E';

            }



            // Browser Geolocation API ("Use My Current Location")

            btnUseCurrentLocation.addEventListener('click', function () {

                if (!navigator.geolocation) {

                    alert('Geolocation is not supported by your browser. You can click on the map to pin your shop location.');

                    return;

                }



                btnUseCurrentLocation.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Locating...';



                navigator.geolocation.getCurrentPosition(

                    function (position) {

                        const lat = position.coords.latitude;

                        const lng = position.coords.longitude;

                        btnUseCurrentLocation.innerHTML = '<i class="fa-solid fa-crosshairs"></i> Use My Current Location';



                        if (leafletMap && mapMarker) {

                            leafletMap.setView([lat, lng], 15);

                            mapMarker.setLatLng([lat, lng]);

                            mapMarker.openPopup();

                        }

                        updateCoordsDisplay(lat, lng);



                        // Optional Reverse Geocoding via Nominatim

                        reverseGeocodeCoords(lat, lng);

                    },

                    function (err) {

                        btnUseCurrentLocation.innerHTML = '<i class="fa-solid fa-crosshairs"></i> Use My Current Location';

                        console.warn('Geolocation notice:', err.message);

                        alert('Could not retrieve current GPS location (' + err.message + '). You can click or drag the marker anywhere on the map.');

                    },

                    { enableHighAccuracy: true, timeout: 8000 }

                );

            });



            function reverseGeocodeCoords(lat, lng) {

                fetch('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=' + lat + '&lon=' + lng)

                .then(function (res) { return res.json(); })

                .then(function (data) {

                    if (data && data.address) {

                        const addr = data.address;



                        // 1. Address Line 1 and Address Line 2

                        let line1Parts = [];

                        const spot = addr.shop || addr.amenity || addr.building || addr.house_name || addr.house_number || addr.office || '';

                        const street = addr.road || addr.street || addr.pedestrian || addr.footway || addr.highway || '';

                        if (spot) line1Parts.push(spot);

                        if (street && !line1Parts.includes(street)) line1Parts.push(street);



                        let line2Parts = [];

                        const area = addr.suburb || addr.neighbourhood || addr.residential || addr.subdivision || addr.city_district || '';

                        if (area && !line1Parts.includes(area)) line2Parts.push(area);



                        // If line1Parts is empty, fallback to area or first part of display_name

                        if (line1Parts.length === 0) {

                            if (line2Parts.length > 0) {

                                line1Parts.push(line2Parts.shift());

                            } else if (data.display_name) {

                                const parts = data.display_name.split(',').map(function (s) { return s.trim(); });

                                line1Parts.push(parts[0]);

                                if (parts.length > 1) line2Parts.push(parts[1]);

                            }

                        }



                        if (line1Parts.length > 0) {

                            addr1Input.value = line1Parts.join(', ');

                            validateAddress1();

                        }



                        if (line2Parts.length > 0) {

                            addr2Input.value = line2Parts.join(', ');

                        }



                        // 2. City / Town

                        const c = addr.city || addr.town || addr.village || addr.municipality || addr.suburb || '';

                        if (c) {

                            const cleanCity = c.replace(/[0-9]/g, '').trim();

                            if (cleanCity) {

                                cityInput.value = cleanCity;

                                validateCity();

                            }

                        }



                        // 3. State

                        const stateName = (addr.state || '').trim();

                        if (stateName) {

                            for (let i = 0; i < stateSelect.options.length; i++) {

                                const optText = stateSelect.options[i].text.toLowerCase();

                                if (optText === stateName.toLowerCase() || stateName.toLowerCase().indexOf(optText) !== -1 || optText.indexOf(stateName.toLowerCase()) !== -1) {

                                    stateSelect.selectedIndex = i;

                                    populateDistricts(stateSelect.options[i].value);

                                    break;

                                }

                            }

                        }



                        // 4. District matching

                        const candidates = [

                            addr.state_district,

                            addr.county,

                            addr.district,

                            addr.city,

                            addr.town

                        ].filter(Boolean);



                        let matched = false;

                        for (let k = 0; k < candidates.length && !matched; k++) {

                            const rawCand = candidates[k].trim();

                            const cleanCand = rawCand.replace(/\s+(District|North|South|East|West|Central|Urban|Rural)/gi, '').trim().toLowerCase();

                            const candLower = rawCand.toLowerCase();



                            for (let i = 1; i < districtSelect.options.length; i++) {

                                const optVal = districtSelect.options[i].value.toLowerCase();

                                if (optVal === candLower || optVal === cleanCand || candLower.indexOf(optVal) !== -1 || cleanCand.indexOf(optVal) !== -1) {

                                    districtSelect.selectedIndex = i;

                                    matched = true;

                                    validateDistrict();

                                    break;

                                }

                            }

                        }



                        // 5. Pincode

                        if (addr.postcode) {

                            const p = addr.postcode.replace(/\D/g, '').slice(0, 6);

                            if (p.length === 6) {

                                pincodeInput.value = p;

                                validatePincode();

                            }

                        }

                    }

                })

                .catch(function (err) {

                    console.warn('Reverse geocode error:', err);

                });

            }



            document.getElementById('btnBackToStep4').addEventListener('click', function () {

                goToStep(4);

            });



            // =====================================================================

            // STEP NAVIGATION MANAGER

            // =====================================================================

            function goToStep(stepNum) {

                currentStep = stepNum;



                // Show active step pane, hide others

                stepPanes.forEach(function (pane, idx) {

                    if (idx + 1 === stepNum) {

                        pane.style.display = 'block';

                    } else {

                        pane.style.display = 'none';

                    }

                });



                // Update Stepper Nav Bar

                stepIndicators.forEach(function (ind, idx) {

                    const s = idx + 1;

                    ind.classList.remove('active', 'completed');

                    const iconBox = ind.querySelector('.step-circle-badge');



                    if (s < stepNum) {

                        ind.classList.add('completed');

                        iconBox.innerHTML = '<i class="fa-solid fa-check"></i>';

                    } else if (s === stepNum) {

                        ind.classList.add('active');

                        // Restore original icon

                        const originalIcons = [

                            '<i class="fa-solid fa-user"></i>',

                            '<i class="fa-solid fa-envelope"></i>',

                            '<i class="fa-solid fa-screwdriver-wrench"></i>',

                            '<i class="fa-solid fa-store"></i>',

                            '<i class="fa-solid fa-location-dot"></i>'

                        ];

                        iconBox.innerHTML = originalIcons[idx];

                    } else {

                        const originalIcons = [

                            '<i class="fa-solid fa-user"></i>',

                            '<i class="fa-solid fa-envelope"></i>',

                            '<i class="fa-solid fa-screwdriver-wrench"></i>',

                            '<i class="fa-solid fa-store"></i>',

                            '<i class="fa-solid fa-location-dot"></i>'

                        ];

                        iconBox.innerHTML = originalIcons[idx];

                    }

                });



                // Update track line percentage

                const progressWidths = [0, 25, 50, 75, 100];

                stepperFill.style.width = progressWidths[stepNum - 1] + '%';



                window.scrollTo({ top: 0, behavior: 'smooth' });

            }



            // =====================================================================

            // FINAL COMPLETE REGISTRATION SUBMISSION

            // =====================================================================

            const form = document.getElementById('mechanicRegForm');

            const completeBtn = document.getElementById('btnCompleteRegistration');

            const completeText = document.getElementById('completeRegText');



            form.addEventListener('submit', function (e) {

                e.preventDefault();

                hideAlert();



                // Validate Step 5

                const v1 = validateAddress1();

                const v2 = validateCity();

                const v3 = validateDistrict();

                const v4 = validatePincode();



                if (!v1 || !v2 || !v3 || !v4) {

                    showAlert('Please complete all required address fields before submitting.');

                    if (!v1) addr1Input.focus();

                    else if (!v2) cityInput.focus();

                    else if (!v3) districtSelect.focus();

                    else if (!v4) pincodeInput.focus();

                    return;

                }



                if (!isEmailVerified) {

                    showAlert('Please verify your email address via OTP in Step 2 before completing registration.');

                    // If email is already verified, proceed to Step 3
                    if (isEmailVerified && lastVerifiedEmail === email) {
                        goToStep(3);
                    } else {
                        goToStep(2);
                    }

                    return;

                }



                // Show loading state

                completeBtn.disabled = true;

                completeBtn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Submitting Registration...';



                // Assemble Multipart FormData

                const formData = new FormData(form);



                // Append selected specializations explicitly

                const checkedSpecs = Array.from(document.querySelectorAll('input[name="specializations"]:checked')).map(function (c) { return c.value; });

                formData.delete('specializations');

                checkedSpecs.forEach(function (s) {

                    formData.append('specializations', s);

                });



                // Append uploaded photos if any

                formData.delete('shopPhotos');

                uploadedPhotosList.forEach(function (p) {

                    formData.append('shopPhotos', p.file);

                });



                fetch(contextPath + '/auth/mechanic-register', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'X-Requested-With': 'XMLHttpRequest' },
                    body: formData
                })
                .then(function (res) { return res.json(); })
                .then(function (data) {
                    if (data.success) {
                        completeBtn.innerHTML = '<i class="fa-solid fa-check"></i> Registration Submitted!';
                        showAlert(data.message, true);
                        const shopNameVal = (shopNameInput && shopNameInput.value) ? shopNameInput.value.trim() : '';
                        const targetUrl = data.redirectUrl || (contextPath + '/mechanic/login.jsp?msg=registered_pending&workshop=' + encodeURIComponent(shopNameVal));
                        setTimeout(function () {
                            window.location.href = targetUrl;
                        }, 800);
                    } else {
                        completeBtn.disabled = false;
                        completeBtn.innerHTML = '<i class="fa-solid fa-check"></i> <span>Complete Registration</span>';
                        showAlert(data.message, false);
                        if (data.step) {
                            goToStep(data.step);
                        }
                        if (data.field === 'dob') {
                            setFieldInvalid(dobInput, dobInstruction, data.message);
                            dobInput.focus();
                        }
                    }
                })

                .catch(function (err) {

                    console.error('Registration submit error:', err);

                    completeBtn.disabled = false;

                    completeBtn.innerHTML = '<i class="fa-solid fa-check"></i> <span>Complete Registration</span>';

                    showAlert('System error occurred while submitting mechanic registration. Please try again.');

                });

            });



            // Document Preview Lightbox Modal Functions
            function openDocPreviewModal(title, fileName, dataUrl, isPdf) {
                const modal = document.getElementById('docPreviewModal');
                const titleEl = document.getElementById('docModalTitle');
                const imgEl = document.getElementById('docModalImg');
                const pdfBox = document.getElementById('docModalPdfPlaceholder');
                const pdfName = document.getElementById('docModalPdfName');
                const noPrev = document.getElementById('docModalNoPreview');

                if (!modal) return;
                if (titleEl) titleEl.textContent = title + ' — ' + fileName;

                if (isPdf) {
                    if (imgEl) imgEl.style.display = 'none';
                    if (pdfBox) {
                        pdfBox.style.display = 'block';
                        if (pdfName) pdfName.textContent = fileName;
                    }
                    if (noPrev) noPrev.style.display = 'none';
                } else if (dataUrl) {
                    if (imgEl) {
                        imgEl.src = dataUrl;
                        imgEl.style.display = 'block';
                    }
                    if (pdfBox) pdfBox.style.display = 'none';
                    if (noPrev) noPrev.style.display = 'none';
                } else {
                    if (imgEl) imgEl.style.display = 'none';
                    if (pdfBox) pdfBox.style.display = 'none';
                    if (noPrev) noPrev.style.display = 'block';
                }

                modal.style.display = 'flex';
            }

            function closeDocPreviewModal(e) {
                if (!e || e.target.id === 'docPreviewModal' || e.target.closest('.doc-modal-close')) {
                    const modal = document.getElementById('docPreviewModal');
                    if (modal) modal.style.display = 'none';
                }
            }
            window.openDocPreviewModal = openDocPreviewModal;
            window.closeDocPreviewModal = closeDocPreviewModal;

            // Expose helpers globally
            window.goToStep = goToStep;
            window.reverseGeocodeCoords = reverseGeocodeCoords;

        });

    </script>

    <!-- Document Preview Lightbox Modal -->
    <div id="docPreviewModal" class="doc-preview-modal" onclick="closeDocPreviewModal(event)">
        <div class="doc-modal-content" onclick="event.stopPropagation()">
            <div class="doc-modal-header">
                <div class="doc-modal-header-left">
                    <i class="fa-solid fa-file-shield" id="docModalIcon" style="color: #F97316;"></i>
                    <span class="doc-modal-title" id="docModalTitle">Document Preview</span>
                </div>
                <button type="button" class="doc-modal-close" onclick="closeDocPreviewModal(null)" title="Close">&times;</button>
            </div>
            <div class="doc-modal-body">
                <img id="docModalImg" src="" alt="Preview" style="display: none; max-width: 100%; max-height: 70vh; border-radius: 8px; box-shadow: 0 4px 14px rgba(0,0,0,0.15);">
                <div id="docModalPdfPlaceholder" style="display: none; text-align: center; padding: 40px 20px;">
                    <i class="fa-solid fa-file-pdf" style="font-size: 56px; color: #EF4444; margin-bottom: 12px;"></i>
                    <h4 style="font-size: 15px; font-weight: 700; color: #1E293B; margin-bottom: 4px;" id="docModalPdfName">document.pdf</h4>
                    <p style="font-size: 12.5px; color: #64748B;">PDF document ready for registration submission</p>
                </div>
                <div id="docModalNoPreview" style="display: none; text-align: center; padding: 30px 20px; color: #64748B;">
                    <i class="fa-solid fa-file" style="font-size: 48px; color: #94A3B8; margin-bottom: 10px;"></i>
                    <p style="font-size: 13px;">File preview is not available for this file type.</p>
                </div>
            </div>
        </div>
    </div>

</body>

</html>

