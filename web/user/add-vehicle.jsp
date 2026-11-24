<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.roadassistance.model.User" %>
<%@ page import="java.time.Year" %>
<%
    // =========================================================================
    // 1. SESSION AUTHENTICATION & CACHE PREVENTION
    // =========================================================================
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
        return;
    }

    request.setAttribute("activeUserPage", "vehicles");

    int currentYear = Year.now().getValue();
    String errorParam = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Add New Vehicle — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts: Plus Jakarta Sans & Poppins -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Theme & Dedicated Page Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-add-vehicle.css">
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <div class="add-vehicle-container">
                <!-- Outer White Card Wrapper matching Reference Screenshot -->
                <div class="add-vehicle-main-card">
                    
                    <!-- Flash Error Banner (Server Fallback) -->
                    <% if (errorParam != null && !errorParam.trim().isEmpty()) { %>
                    <div class="alert-toast alert-danger" style="margin-bottom: 20px;">
                        <span><i class="fa-solid fa-triangle-exclamation" style="margin-right: 8px;"></i> <%= errorParam %></span>
                    </div>
                    <% } %>

                    <!-- AJAX Error / Status Banner -->
                    <div id="formAlertBanner" class="alert-toast" style="display:none; margin-bottom: 20px;">
                        <span id="formAlertText"></span>
                    </div>

                    <!-- =======================================================
                         A. PAGE HEADER ROW (Title & Breadcrumbs)
                         ======================================================= -->
                    <div class="add-vehicle-header-row">
                        <div class="add-vehicle-title-group">
                            <div class="add-vehicle-icon-badge">
                                <i class="fa-solid fa-car-side"></i>
                            </div>
                            <div class="add-vehicle-title-text">
                                <h1>Add New <span class="accent-orange">Vehicle</span></h1>
                                <p>Register your vehicle to request breakdown assistance easily.</p>
                            </div>
                        </div>

                        <div class="add-vehicle-breadcrumb">
                            <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="breadcrumb-link">
                                <i class="fa-solid fa-house"></i> Dashboard
                            </a>
                            <span class="breadcrumb-separator"><i class="fa-solid fa-chevron-right"></i></span>
                            <a href="${pageContext.request.contextPath}/user/vehicles.jsp" class="breadcrumb-link">
                                My Vehicles
                            </a>
                            <span class="breadcrumb-separator"><i class="fa-solid fa-chevron-right"></i></span>
                            <span class="breadcrumb-current">Add New Vehicle</span>
                        </div>
                    </div>

                    <!-- =======================================================
                         B. TWO-COLUMN MAIN CONTENT GRID
                         ======================================================= -->
                    <div class="add-vehicle-layout-grid">
                        
                        <!-- LEFT COLUMN: VEHICLE INFORMATION PANEL -->
                        <aside class="vehicle-info-panel">
                            <div class="info-panel-title-group">
                                <h3 class="info-panel-title">Add Your <span class="accent-orange">Vehicle</span></h3>
                                <p class="info-panel-desc">Register your vehicle details for quick roadside assistance anytime, anywhere.</p>
                            </div>

                            <!-- Sunset Road & Vehicles Hero Graphic -->
                            <div class="info-panel-image-wrapper">
                                <img src="${pageContext.request.contextPath}/images/add-vehicle-banner.jpg" 
                                     alt="Roadside Assistance Vehicles" 
                                     class="info-panel-image">
                                <div class="info-panel-image-overlay"></div>
                            </div>

                            <!-- 3 Value Proposition Bullets -->
                            <div class="info-features-list">
                                <div class="info-feature-item">
                                    <div class="info-feature-icon">
                                        <i class="fa-solid fa-shield-halved"></i>
                                    </div>
                                    <div class="info-feature-text">
                                        <h4>Faster Assistance</h4>
                                        <p>with registered vehicles</p>
                                    </div>
                                </div>

                                <div class="info-feature-item">
                                    <div class="info-feature-icon">
                                        <i class="fa-solid fa-screwdriver-wrench"></i>
                                    </div>
                                    <div class="info-feature-text">
                                        <h4>Accurate Service</h4>
                                        <p>for your vehicle type</p>
                                    </div>
                                </div>

                                <div class="info-feature-item">
                                    <div class="info-feature-icon">
                                        <i class="fa-solid fa-clock-rotate-left"></i>
                                    </div>
                                    <div class="info-feature-text">
                                        <h4>Maintain Service History</h4>
                                        <p>for each vehicle</p>
                                    </div>
                                </div>
                            </div>
                        </aside>

                        <!-- RIGHT COLUMN: VEHICLE REGISTRATION FORM -->
                        <div class="vehicle-form-card">
                            <form id="addVehicleForm" action="${pageContext.request.contextPath}/VehicleServlet" 
                                  method="POST" enctype="multipart/form-data" novalidate>
                                
                                <input type="hidden" name="action" value="add">

                                <!-- ===============================================
                                     SECTION 1: VEHICLE DETAILS
                                     =============================================== -->
                                <div class="form-section-header">
                                    <div class="section-icon-badge">
                                        <i class="fa-solid fa-car"></i>
                                    </div>
                                    <div class="section-title-text">
                                        <h2>Vehicle Details</h2>
                                        <p>Enter your vehicle basic information.</p>
                                    </div>
                                </div>

                                <!-- 3-Column Grid: Type, Reg No, Brand -->
                                <div class="form-fields-grid-3">
                                    
                                    <!-- 1. Vehicle Type -->
                                    <div class="form-group-custom">
                                        <label for="vehicleType" class="form-label-custom">
                                            <i class="fa-solid fa-car-side"></i> Vehicle Type <span class="required-star">*</span>
                                        </label>
                                        <div class="input-wrapper-custom">
                                            <select name="vehicle_type" id="vehicleType" class="select-custom" required>
                                                <option value="" disabled selected>Select Vehicle Type</option>
                                                <option value="Car">Car</option>
                                                <option value="Bike / Motorcycle">Bike / Motorcycle</option>
                                                <option value="Auto Rickshaw">Auto Rickshaw</option>
                                                <option value="Scooter">Scooter</option>
                                                <option value="Bus / Van">Bus / Van</option>
                                                <option value="Truck / Heavy Vehicle">Truck / Heavy Vehicle</option>
                                                <option value="Other">Other</option>
                                            </select>
                                        </div>
                                        <div class="other-input-container" id="customTypeContainer">
                                            <input type="text" name="custom_vehicle_type" id="customVehicleType" 
                                                   class="input-custom" placeholder="Specify vehicle type (e.g., Electric Buggy)">
                                        </div>
                                        <span class="field-error-text" id="vehicleTypeError"><i class="fa-solid fa-circle-exclamation"></i> Please select a vehicle type.</span>
                                    </div>

                                    <!-- 2. Registration Number -->
                                    <div class="form-group-custom">
                                        <label for="regNumber" class="form-label-custom">
                                            <i class="fa-solid fa-hashtag"></i> Registration Number <span class="required-star">*</span>
                                        </label>
                                        <div class="input-wrapper-custom">
                                            <input type="text" name="registration_number" id="regNumber" 
                                                   class="input-custom reg-no-input" 
                                                   placeholder="TN 45 CY 6778" 
                                                   maxlength="13" autocomplete="off" spellcheck="false" required>
                                        </div>
                                        <div class="field-hint-text" id="regFormatHint">
                                            <i class="fa-solid fa-circle-info"></i> Format: 2 Letters + 2 Digits + 2 Letters + 4 Digits (e.g. TN 45 CY 6778)
                                        </div>
                                        <span class="field-error-text" id="regNumberError"><i class="fa-solid fa-circle-exclamation"></i> Follow format: TN 45 CY 6778</span>
                                    </div>

                                    <!-- 3. Vehicle Brand (Searchable Dropdown) -->
                                    <div class="form-group-custom">
                                        <label class="form-label-custom">
                                            <i class="fa-solid fa-tag"></i> Vehicle Brand <span class="required-star">*</span>
                                        </label>
                                        
                                        <div class="searchable-dropdown" id="brandDropdown">
                                            <div class="searchable-input-trigger" id="brandTrigger" tabindex="0">
                                                <span id="brandTriggerText" style="color: #9CA3AF;">Select Brand</span>
                                                <i class="fa-solid fa-chevron-down trigger-icon"></i>
                                            </div>
                                            
                                            <div class="searchable-menu" id="brandMenu">
                                                <div class="searchable-search-box">
                                                    <i class="fa-solid fa-magnifying-glass searchable-search-icon"></i>
                                                    <input type="text" class="searchable-search-input" id="brandSearchInput" 
                                                           placeholder="Search vehicle brand..." autocomplete="off">
                                                </div>
                                                <ul class="searchable-options-list" id="brandOptionsList">
                                                    <!-- Dynamically populated based on Vehicle Type -->
                                                    <li class="searchable-option-item" data-value="Maruti Suzuki">Maruti Suzuki</li>
                                                    <li class="searchable-option-item" data-value="Hyundai">Hyundai</li>
                                                    <li class="searchable-option-item" data-value="Tata Motors">Tata Motors</li>
                                                    <li class="searchable-option-item" data-value="Mahindra">Mahindra</li>
                                                    <li class="searchable-option-item" data-value="Toyota">Toyota</li>
                                                    <li class="searchable-option-item" data-value="Honda">Honda</li>
                                                    <li class="searchable-option-item" data-value="Kia">Kia</li>
                                                    <li class="searchable-option-item" data-value="Volkswagen">Volkswagen</li>
                                                    <li class="searchable-option-item" data-value="Skoda">Skoda</li>
                                                    <li class="searchable-option-item" data-value="BMW">BMW</li>
                                                    <li class="searchable-option-item" data-value="Mercedes-Benz">Mercedes-Benz</li>
                                                    <li class="searchable-option-item" data-value="Audi">Audi</li>
                                                    <li class="searchable-option-item" data-value="MG Motor">MG Motor</li>
                                                    <li class="searchable-option-item" data-value="Renault">Renault</li>
                                                    <li class="searchable-option-item" data-value="Nissan">Nissan</li>
                                                    <li class="searchable-option-item" data-value="Other">Other (Custom Brand)</li>
                                                </ul>
                                            </div>
                                        </div>

                                        <input type="hidden" name="vehicle_brand" id="selectedBrandInput" required>

                                        <div class="other-input-container" id="customBrandContainer">
                                            <input type="text" name="custom_brand" id="customBrand" 
                                                   class="input-custom" placeholder="Enter custom vehicle brand (e.g., Tesla)">
                                        </div>
                                        <span class="field-error-text" id="brandError"><i class="fa-solid fa-circle-exclamation"></i> Please select a vehicle brand.</span>
                                    </div>

                                </div>

                                <!-- 3-Column Grid: Model, Year, Fuel -->
                                <div class="form-fields-grid-3">
                                    
                                    <!-- 4. Vehicle Model -->
                                    <div class="form-group-custom">
                                        <label for="vehicleModel" class="form-label-custom">
                                            <i class="fa-solid fa-layer-group"></i> Vehicle Model <span class="required-star">*</span>
                                        </label>
                                        <div class="input-wrapper-custom">
                                            <input type="text" name="vehicle_model" id="vehicleModel" 
                                                   class="input-custom" 
                                                   placeholder="Enter vehicle model (e.g., i20, Pulsar 150)" 
                                                   autocomplete="off" required>
                                        </div>
                                        <!-- Quick Pick Suggestions -->
                                        <div class="model-suggestions-wrapper" id="modelSuggestions">
                                            <!-- Dynamically filled with pills based on selected brand -->
                                        </div>
                                        <span class="field-error-text" id="modelError"><i class="fa-solid fa-circle-exclamation"></i> Please enter your vehicle model.</span>
                                    </div>

                                    <!-- 5. Manufacturing Year (Interactive Calendar Year Selection) -->
                                    <div class="form-group-custom">
                                        <label for="yearPickerTrigger" class="form-label-custom">
                                            <i class="fa-regular fa-calendar-days"></i> Manufacturing Year <span class="required-star">*</span>
                                        </label>
                                        <div class="calendar-year-picker" id="calendarYearPicker">
                                            <div class="calendar-year-trigger" id="yearPickerTrigger" tabindex="0">
                                                <span id="selectedYearDisplay" class="placeholder-text">Select Year</span>
                                                <i class="fa-regular fa-calendar trigger-calendar-icon"></i>
                                            </div>
                                            <input type="hidden" name="manufacturing_year" id="manufacturingYear" required>
                                            
                                            <!-- Calendar Year Popover -->
                                            <div class="calendar-year-popover" id="yearPickerPopover">
                                                <div class="year-picker-header">
                                                    <button type="button" class="year-nav-btn" id="prevDecadeBtn" title="Previous Decade">
                                                        <i class="fa-solid fa-chevron-left"></i>
                                                    </button>
                                                    <div class="year-decade-title" id="decadeTitle">2020 - 2029</div>
                                                    <button type="button" class="year-nav-btn" id="nextDecadeBtn" title="Next Decade">
                                                        <i class="fa-solid fa-chevron-right"></i>
                                                    </button>
                                                </div>
                                                <div class="year-picker-grid" id="yearGrid">
                                                    <!-- Dynamically rendered via JS -->
                                                </div>
                                                <div class="year-picker-footer">
                                                    <button type="button" class="btn-picker-current" id="selectCurrentYearBtn">This Year (<%= currentYear %>)</button>
                                                </div>
                                            </div>
                                        </div>
                                        <span class="field-error-text" id="yearError"><i class="fa-solid fa-circle-exclamation"></i> Please select manufacturing year.</span>
                                    </div>

                                    <!-- 6. Fuel Type -->
                                    <div class="form-group-custom">
                                        <label for="fuelType" class="form-label-custom">
                                            <i class="fa-solid fa-gas-pump"></i> Fuel Type <span class="required-star">*</span>
                                        </label>
                                        <div class="input-wrapper-custom">
                                            <select name="fuel_type" id="fuelType" class="select-custom" required>
                                                <option value="" disabled selected>Select Fuel Type</option>
                                                <option value="Petrol">Petrol</option>
                                                <option value="Diesel">Diesel</option>
                                                <option value="Electric (EV)">Electric (EV)</option>
                                                <option value="Hybrid">Hybrid</option>
                                                <option value="CNG">CNG</option>
                                                <option value="LPG">LPG</option>
                                                <option value="Other">Other</option>
                                            </select>
                                        </div>
                                        <div class="other-input-container" id="customFuelContainer">
                                            <input type="text" name="custom_fuel_type" id="customFuelType" 
                                                   class="input-custom" placeholder="Specify fuel type (e.g., Hydrogen)">
                                        </div>
                                        <span class="field-error-text" id="fuelError"><i class="fa-solid fa-circle-exclamation"></i> Please select a fuel type.</span>
                                    </div>

                                </div>

                                <div class="form-section-divider"></div>

                                <!-- ===============================================
                                     SECTION 2: VEHICLE PHOTOS (OPTIONAL)
                                     =============================================== -->
                                <div class="form-section-header">
                                    <div class="section-icon-badge">
                                        <i class="fa-solid fa-camera"></i>
                                    </div>
                                    <div class="section-title-text">
                                        <h2>Vehicle Photos <span style="font-size: 14px; font-weight: 500; color: #9CA3AF;">(Optional)</span></h2>
                                        <p>Upload clear photos of your vehicle (front, back or side).</p>
                                    </div>
                                </div>

                                <div class="photos-upload-container">
                                    
                                    <!-- Dropzone Click / Drag & Drop -->
                                    <div class="upload-dropzone" id="uploadDropzone">
                                        <input type="file" id="photosInput" name="photos" multiple 
                                               accept="image/png, image/jpeg, image/jpg" style="display: none;">
                                        <div class="upload-cloud-icon">
                                            <i class="fa-solid fa-cloud-arrow-up"></i>
                                        </div>
                                        <span class="upload-primary-text">Click to upload vehicle photos</span>
                                        <span class="upload-sub-text">JPG, JPEG, PNG (Max 5 MB each, up to 5 photos)</span>
                                    </div>

                                    <!-- Uploaded Thumbnails Preview Area -->
                                    <div class="photo-previews-grid" id="photoPreviewsGrid">
                                        <div class="preview-empty-hint" id="emptyPreviewHint">
                                            <i class="fa-regular fa-image" style="font-size: 20px;"></i>
                                            <span>No photos selected yet. Previews with remove options will appear here.</span>
                                        </div>
                                    </div>

                                </div>

                                <!-- ===============================================
                                     BOTTOM ACTIONS: CANCEL & SAVE VEHICLE
                                     =============================================== -->
                                <div class="form-actions-footer">
                                    <a href="${pageContext.request.contextPath}/user/vehicles.jsp" 
                                       class="btn-cancel-vehicle" id="btnCancel">
                                        <i class="fa-solid fa-arrow-left"></i> Cancel
                                    </a>

                                    <button type="submit" class="btn-save-vehicle" id="btnSaveVehicle">
                                        <i class="fa-solid fa-floppy-disk"></i> Save Vehicle
                                    </button>
                                </div>

                            </form>
                        </div>

                    </div>

                </div>
            </div>

        </main>
    </div>

    <!-- =======================================================================
         INTERACTIVE LOGIC: VALIDATION, AUTO-FORMAT, AUTOCOMPLETE, PREVIEWS
         ======================================================================= -->
    <script>
        (function() {
            // Global State
            let uploadedFiles = [];
            let isFormDirty = false;
            let regCheckTimer = null;
            let isRegDuplicate = false;

            // DOM References
            const form = document.getElementById('addVehicleForm');
            const btnSave = document.getElementById('btnSaveVehicle');
            const btnCancel = document.getElementById('btnCancel');
            const alertBanner = document.getElementById('formAlertBanner');
            const alertText = document.getElementById('formAlertText');

            // Fields
            const vehicleTypeSelect = document.getElementById('vehicleType');
            const customTypeContainer = document.getElementById('customTypeContainer');
            const customVehicleType = document.getElementById('customVehicleType');

            const regNumberInput = document.getElementById('regNumber');
            const regNumberError = document.getElementById('regNumberError');

            const brandDropdown = document.getElementById('brandDropdown');
            const brandTrigger = document.getElementById('brandTrigger');
            const brandTriggerText = document.getElementById('brandTriggerText');
            const brandMenu = document.getElementById('brandMenu');
            const brandSearchInput = document.getElementById('brandSearchInput');
            const brandOptionsList = document.getElementById('brandOptionsList');
            const selectedBrandInput = document.getElementById('selectedBrandInput');
            const customBrandContainer = document.getElementById('customBrandContainer');
            const customBrand = document.getElementById('customBrand');

            const vehicleModelInput = document.getElementById('vehicleModel');
            const modelSuggestions = document.getElementById('modelSuggestions');

            // Calendar Year Picker DOM
            const calendarYearPicker = document.getElementById('calendarYearPicker');
            const yearPickerTrigger = document.getElementById('yearPickerTrigger');
            const selectedYearDisplay = document.getElementById('selectedYearDisplay');
            const mfgYearInput = document.getElementById('manufacturingYear');
            const yearPickerPopover = document.getElementById('yearPickerPopover');
            const prevDecadeBtn = document.getElementById('prevDecadeBtn');
            const nextDecadeBtn = document.getElementById('nextDecadeBtn');
            const decadeTitle = document.getElementById('decadeTitle');
            const yearGrid = document.getElementById('yearGrid');
            const selectCurrentYearBtn = document.getElementById('selectCurrentYearBtn');

            const CURRENT_YEAR = <%= currentYear %>;
            const MIN_YEAR = 1980;
            let viewedDecadeStart = Math.floor(CURRENT_YEAR / 10) * 10;

            const fuelTypeSelect = document.getElementById('fuelType');
            const customFuelContainer = document.getElementById('customFuelContainer');
            const customFuelType = document.getElementById('customFuelType');

            const dropzone = document.getElementById('uploadDropzone');
            const photosInput = document.getElementById('photosInput');
            const previewsGrid = document.getElementById('photoPreviewsGrid');
            const emptyPreviewHint = document.getElementById('emptyPreviewHint');

            // Mark Form Dirty on Any Input
            form.addEventListener('input', () => { isFormDirty = true; });
            form.addEventListener('change', () => { isFormDirty = true; });

            // -----------------------------------------------------------------
            // 1. VEHICLE BRANDS BY TYPE & VEHICLE TYPE TOGGLE
            // -----------------------------------------------------------------
            const BRANDS_BY_TYPE = {
                'Car': [
                    'Maruti Suzuki', 'Hyundai', 'Tata Motors', 'Mahindra', 'Toyota', 
                    'Honda', 'Kia', 'Volkswagen', 'Skoda', 'BMW', 
                    'Mercedes-Benz', 'Audi', 'MG Motor', 'Renault', 'Nissan', 
                    'Ford', 'Jeep', 'Volvo', 'Other'
                ],
                'Bike / Motorcycle': [
                    'Hero MotoCorp', 'Honda', 'Bajaj', 'TVS', 'Royal Enfield', 
                    'Yamaha', 'Suzuki', 'KTM', 'Kawasaki', 'Jawa', 
                    'Harley-Davidson', 'Triumph', 'Ducati', 'BMW Motorrad', 'Yezdi', 
                    'Revolt', 'Other'
                ],
                'Scooter': [
                    'Honda', 'TVS', 'Suzuki', 'Hero MotoCorp', 'Yamaha', 
                    'Ather Energy', 'Ola Electric', 'Bajaj', 'Simple Energy', 'Vespa', 
                    'Aprilia', 'Okinawa', 'Pure EV', 'Other'
                ],
                'Auto Rickshaw': [
                    'Bajaj', 'Piaggio', 'TVS', 'Mahindra', 'Atul Auto', 
                    'Kinetic Green', 'Saarthi', 'Lohia Auto', 'Other'
                ],
                'Bus / Van': [
                    'Tata Motors', 'Ashok Leyland', 'Eicher', 'Force Motors', 'BharatBenz', 
                    'Volvo', 'Mahindra', 'SML Isuzu', 'Scania', 'Other'
                ],
                'Truck / Heavy Vehicle': [
                    'Tata Motors', 'Ashok Leyland', 'BharatBenz', 'Eicher', 'Mahindra', 
                    'Force Motors', 'SML Isuzu', 'Volvo', 'Scania', 'Other'
                ],
                'Other': [
                    'Other'
                ]
            };

            function populateBrandOptions(type) {
                brandOptionsList.innerHTML = '';
                const brands = BRANDS_BY_TYPE[type] || BRANDS_BY_TYPE['Car'];
                brands.forEach(b => {
                    const li = document.createElement('li');
                    li.className = 'searchable-option-item';
                    li.setAttribute('data-value', b);
                    li.textContent = (b === 'Other') ? 'Other (Custom Brand)' : b;
                    brandOptionsList.appendChild(li);
                });
            }

            vehicleTypeSelect.addEventListener('change', function() {
                const selectedType = this.value;

                // Toggle Custom Vehicle Type Container
                if (selectedType === 'Other') {
                    customTypeContainer.style.display = 'block';
                    customVehicleType.focus();
                } else {
                    customTypeContainer.style.display = 'none';
                    customVehicleType.value = '';
                }
                clearFieldError(vehicleTypeSelect, 'vehicleTypeError');

                // Dynamically Update Brands based on Vehicle Type
                populateBrandOptions(selectedType);

                // Reset Brand Selection
                selectedBrandInput.value = '';
                brandTriggerText.textContent = 'Select Brand';
                brandTriggerText.style.color = '#9CA3AF';
                brandTriggerText.style.fontWeight = '500';
                brandTrigger.classList.remove('is-valid', 'is-invalid');
                customBrandContainer.style.display = 'none';
                customBrand.value = '';

                // Reset Model Suggestions
                modelSuggestions.innerHTML = '';
                modelSuggestions.style.display = 'none';

                // Contextual Model Placeholder
                const placeholders = {
                    'Car': 'Enter vehicle model (e.g., i20, Swift, Nexon, Creta)',
                    'Bike / Motorcycle': 'Enter vehicle model (e.g., Pulsar 150, Classic 350, Splendor)',
                    'Scooter': 'Enter vehicle model (e.g., Activa 6G, Jupiter, 450X, Access 125)',
                    'Auto Rickshaw': 'Enter vehicle model (e.g., Compact RE, Ape City, King)',
                    'Bus / Van': 'Enter vehicle model (e.g., Traveller, Starbus, Viking)',
                    'Truck / Heavy Vehicle': 'Enter vehicle model (e.g., Signa 2823, Eicher Pro 2049, Bada Dost)'
                };
                vehicleModelInput.placeholder = placeholders[selectedType] || 'Enter vehicle model';
            });

            // -----------------------------------------------------------------
            // 2. FUEL TYPE "OTHER" TOGGLE
            // -----------------------------------------------------------------
            fuelTypeSelect.addEventListener('change', function() {
                if (this.value === 'Other') {
                    customFuelContainer.style.display = 'block';
                    customFuelType.focus();
                } else {
                    customFuelContainer.style.display = 'none';
                    customFuelType.value = '';
                }
                clearFieldError(fuelTypeSelect, 'fuelError');
            });

            // -----------------------------------------------------------------
            // 3. REGISTRATION NUMBER STRICT ENFORCEMENT & LIVE FORMATTING
            // Rule:
            //   - First 2 characters: Letters only (State Code e.g. TN)
            //   - Next 2 characters: Digits only, not character (RTO e.g. 45)
            //   - Next 2 characters: Letters only (Series e.g. CY)
            //   - Followed by: 4 digits only (e.g. 6778)
            // -----------------------------------------------------------------
            function sanitizeAndFormatRegNumber(val) {
                let raw = val.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
                let clean = '';

                for (let i = 0; i < raw.length && clean.length < 10; i++) {
                    const ch = raw[i];
                    const len = clean.length;
                    if (len < 2) {
                        if (/[A-Z]/.test(ch)) clean += ch;
                    } else if (len < 4) {
                        if (/[0-9]/.test(ch)) clean += ch;
                    } else if (len < 6) {
                        if (/[A-Z]/.test(ch)) clean += ch;
                    } else if (len < 10) {
                        if (/[0-9]/.test(ch)) clean += ch;
                    }
                }

                let formatted = '';
                if (clean.length > 0) {
                    formatted = clean.slice(0, 2);
                }
                if (clean.length > 2) {
                    formatted += ' ' + clean.slice(2, 4);
                }
                if (clean.length > 4) {
                    formatted += ' ' + clean.slice(4, 6);
                }
                if (clean.length > 6) {
                    formatted += ' ' + clean.slice(6, 10);
                }
                return { clean, formatted };
            }

            regNumberInput.addEventListener('keydown', function(e) {
                // Allow control keys
                if (e.key === 'Backspace' || e.key === 'Delete' || e.key === 'Tab' || 
                    e.key === 'ArrowLeft' || e.key === 'ArrowRight' || e.key === 'Home' || e.key === 'End' ||
                    (e.ctrlKey || e.metaKey)) {
                    return;
                }

                // If not single character key, allow
                if (e.key.length !== 1) return;

                const rawClean = this.value.replace(/[^A-Za-z0-9]/g, '');
                const currentLen = rawClean.length;

                if (currentLen >= 10 && this.selectionStart === this.selectionEnd) {
                    e.preventDefault();
                    return;
                }

                const k = e.key;
                if (currentLen < 2) {
                    // Must be letter
                    if (!/[A-Za-z]/.test(k)) {
                        e.preventDefault();
                        showFieldError(regNumberInput, 'regNumberError', 'First 2 must be letters only (e.g. TN)');
                        return;
                    }
                } else if (currentLen < 4) {
                    // Must be 2-digit number (not character)
                    if (!/[0-9]/.test(k)) {
                        e.preventDefault();
                        showFieldError(regNumberInput, 'regNumberError', 'Next 2 must be digits only (e.g. 45)');
                        return;
                    }
                } else if (currentLen < 6) {
                    // Must be letters
                    if (!/[A-Za-z]/.test(k)) {
                        e.preventDefault();
                        showFieldError(regNumberInput, 'regNumberError', 'Next 2 must be letters only (e.g. CY)');
                        return;
                    }
                } else if (currentLen < 10) {
                    // Must be 4-digit number only
                    if (!/[0-9]/.test(k)) {
                        e.preventDefault();
                        showFieldError(regNumberInput, 'regNumberError', 'Last 4 must be digits only (e.g. 6778)');
                        return;
                    }
                }
                clearFieldError(regNumberInput, 'regNumberError');
            });

            regNumberInput.addEventListener('input', function() {
                const result = sanitizeAndFormatRegNumber(this.value);
                this.value = result.formatted;

                const regPattern = /^[A-Z]{2}\s\d{2}\s[A-Z]{1,2}\s\d{4}$/;
                if (result.clean.length >= 9) {
                    if (regPattern.test(result.formatted)) {
                        clearFieldError(regNumberInput, 'regNumberError');
                        clearTimeout(regCheckTimer);
                        regCheckTimer = setTimeout(() => {
                            checkDuplicateRegistration(result.formatted);
                        }, 300);
                    } else {
                        showFieldError(regNumberInput, 'regNumberError', 'Follow format: TN 45 CY 6778');
                    }
                } else {
                    regNumberInput.classList.remove('is-valid');
                    isRegDuplicate = false;
                    if (result.clean.length > 0) {
                        clearFieldError(regNumberInput, 'regNumberError');
                    }
                }
            });

            function checkDuplicateRegistration(regNo) {
                const contextPath = '${pageContext.request.contextPath}';
                fetch(contextPath + '/VehicleServlet?action=check_duplicate&reg_no=' + encodeURIComponent(regNo))
                    .then(res => res.json())
                    .then(data => {
                        if (data.exists) {
                            isRegDuplicate = true;
                            showFieldError(regNumberInput, 'regNumberError', 'This vehicle number is already registered.');
                            regNumberInput.classList.add('is-invalid');
                            regNumberInput.classList.remove('is-valid');
                        } else {
                            isRegDuplicate = false;
                            clearFieldError(regNumberInput, 'regNumberError');
                            regNumberInput.classList.add('is-valid');
                            regNumberInput.classList.remove('is-invalid');
                        }
                    })
                    .catch(err => {
                        console.error('Duplicate check error:', err);
                    });
            }

            // -----------------------------------------------------------------
            // 4. SEARCHABLE DROPDOWN (Brand)
            // -----------------------------------------------------------------
            function setupSearchableDropdown(dropdownEl, triggerEl, triggerTextEl, menuEl, searchInputEl, listEl, hiddenInputEl, onSelectCallback) {
                triggerEl.addEventListener('click', function(e) {
                    e.stopPropagation();
                    const isOpen = dropdownEl.classList.contains('open');
                    closeAllDropdowns();
                    if (!isOpen) {
                        dropdownEl.classList.add('open');
                        searchInputEl.value = '';
                        filterList(listEl, '');
                        setTimeout(() => searchInputEl.focus(), 50);
                    }
                });

                searchInputEl.addEventListener('input', function(e) {
                    filterList(listEl, this.value.trim().toLowerCase());
                });

                listEl.addEventListener('click', function(e) {
                    const item = e.target.closest('.searchable-option-item');
                    if (!item) return;

                    const val = item.getAttribute('data-value');
                    hiddenInputEl.value = val;
                    triggerTextEl.textContent = val;
                    triggerTextEl.style.color = '#1F2937';
                    triggerTextEl.style.fontWeight = '600';

                    Array.from(listEl.querySelectorAll('.searchable-option-item')).forEach(el => el.classList.remove('selected'));
                    item.classList.add('selected');

                    dropdownEl.classList.remove('open');

                    if (onSelectCallback) onSelectCallback(val);
                });
            }

            function filterList(listEl, query) {
                const items = listEl.querySelectorAll('.searchable-option-item');
                let matches = 0;
                items.forEach(item => {
                    const text = item.textContent.toLowerCase();
                    if (text.includes(query)) {
                        item.style.display = 'flex';
                        matches++;
                    } else {
                        item.style.display = 'none';
                    }
                });
            }

            function closeAllDropdowns() {
                document.querySelectorAll('.searchable-dropdown').forEach(d => d.classList.remove('open'));
                if (calendarYearPicker) calendarYearPicker.classList.remove('open');
            }

            document.addEventListener('click', function(e) {
                if (!e.target.closest('.searchable-dropdown') && !e.target.closest('#calendarYearPicker')) {
                    closeAllDropdowns();
                }
            });

            // Initialize Brand Dropdown
            setupSearchableDropdown(
                brandDropdown, brandTrigger, brandTriggerText, brandMenu, 
                brandSearchInput, brandOptionsList, selectedBrandInput,
                function(selectedBrand) {
                    clearFieldError(brandTrigger, 'brandError');
                    if (selectedBrand === 'Other') {
                        customBrandContainer.style.display = 'block';
                        customBrand.focus();
                    } else {
                        customBrandContainer.style.display = 'none';
                        customBrand.value = '';
                    }
                    updateModelSuggestions(selectedBrand);
                }
            );

            // -----------------------------------------------------------------
            // 5. INTERACTIVE CALENDAR YEAR SELECTION PICKER
            // -----------------------------------------------------------------
            function renderYearGrid() {
                yearGrid.innerHTML = '';
                const start = viewedDecadeStart;
                const end = start + 9;
                decadeTitle.textContent = start + ' - ' + end;

                const currentSelectedVal = parseInt(mfgYearInput.value) || 0;

                for (let y = start - 1; y <= end + 1; y++) {
                    const btn = document.createElement('button');
                    btn.type = 'button';
                    btn.className = 'year-cell';
                    btn.textContent = y;

                    if (y < start || y > end) {
                        btn.classList.add('other-decade');
                    }
                    if (y === CURRENT_YEAR) {
                        btn.classList.add('current-year');
                    }
                    if (y === currentSelectedVal) {
                        btn.classList.add('selected');
                    }
                    if (y > CURRENT_YEAR || y < MIN_YEAR) {
                        btn.classList.add('disabled');
                        btn.disabled = true;
                    } else {
                        btn.addEventListener('click', function(e) {
                            e.stopPropagation();
                            selectYear(y);
                        });
                    }
                    yearGrid.appendChild(btn);
                }
            }

            function selectYear(yr) {
                mfgYearInput.value = yr;
                selectedYearDisplay.textContent = yr;
                selectedYearDisplay.classList.remove('placeholder-text');
                selectedYearDisplay.style.color = '#1F2937';
                selectedYearDisplay.style.fontWeight = '700';
                yearPickerTrigger.classList.add('is-valid');
                clearFieldError(yearPickerTrigger, 'yearError');
                calendarYearPicker.classList.remove('open');
                renderYearGrid();
            }

            yearPickerTrigger.addEventListener('click', function(e) {
                e.stopPropagation();
                const isOpen = calendarYearPicker.classList.contains('open');
                closeAllDropdowns();
                if (!isOpen) {
                    calendarYearPicker.classList.add('open');
                    renderYearGrid();
                }
            });

            prevDecadeBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                if (viewedDecadeStart - 10 >= 1970) {
                    viewedDecadeStart -= 10;
                    renderYearGrid();
                }
            });

            nextDecadeBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                if (viewedDecadeStart + 10 <= CURRENT_YEAR + 10) {
                    viewedDecadeStart += 10;
                    renderYearGrid();
                }
            });

            selectCurrentYearBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                selectYear(CURRENT_YEAR);
            });

            // -----------------------------------------------------------------
            // 6. DYNAMIC MODEL SUGGESTIONS PILLS
            // -----------------------------------------------------------------
            const BRAND_MODELS = {
                'Hyundai': ['i20', 'Creta', 'Venue', 'Verna', 'Grand i10 Nios', 'Alcazar', 'Tucson'],
                'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Dzire', 'Ertiga', 'Fronx', 'Grand Vitara', 'Wagon R'],
                'Tata Motors': ['Nexon', 'Punch', 'Harrier', 'Safari', 'Altroz', 'Tiago', 'Curvv'],
                'Honda': ['City', 'Amaze', 'Elevate', 'Activa 6G', 'Shine 125', 'SP 125', 'Hornet 2.0'],
                'Toyota': ['Innova Crysta', 'Innova Hycross', 'Fortuner', 'Urban Cruiser Taisor', 'Glanza', 'Hilux'],
                'Mahindra': ['Scorpio-N', 'Scorpio Classic', 'XUV700', 'Thar', 'XUV 3XO', 'Bolero'],
                'Kia': ['Seltos', 'Sonet', 'Carens', 'EV6'],
                'Volkswagen': ['Virtus', 'Taigun', 'Tiguan'],
                'Skoda': ['Slavia', 'Kushaq', 'Kodiaq', 'Superb'],
                'Renault': ['Kwid', 'Triber', 'Kiger'],
                'Nissan': ['Magnite', 'X-Trail'],
                'MG Motor': ['Hector', 'Astor', 'ZS EV', 'Comet EV'],
                'BMW': ['M5', '3 Series', '5 Series', 'X1', 'X5', 'M340i'],
                'Mercedes-Benz': ['C-Class', 'E-Class', 'GLC', 'GLE', 'A-Class'],
                'Audi': ['A4', 'A6', 'Q3', 'Q5', 'Q7'],
                'Bajaj': ['Pulsar 150', 'Pulsar NS200', 'Pulsar N160', 'Dominar 400', 'Platina 100', 'Chetak EV', 'Compact RE Auto'],
                'Royal Enfield': ['Classic 350', 'Hunter 350', 'Bullet 350', 'Meteor 350', 'Himalayan 450', 'Continental GT 650'],
                'TVS': ['Jupiter 110', 'Jupiter 125', 'Apache RTR 160', 'Apache RTR 200', 'Raider 125', 'Ntorq 125', 'iQube EV', 'King Auto'],
                'Hero MotoCorp': ['Splendor Plus', 'HF Deluxe', 'Glamour', 'Xtreme 125R', 'Xpulse 200 4V', 'Destini 125'],
                'Yamaha': ['YZF R15 V4', 'MT-15 V2', 'FZ-S FI', 'RayZR 125', 'Aerox 155'],
                'KTM': ['Duke 200', 'Duke 250', 'Duke 390', 'RC 200', 'RC 390', 'Adventure 390'],
                'Suzuki': ['Access 125', 'Burgman Street', 'Gixxer SF', 'V-Strom SX'],
                'Ather Energy': ['450X', '450S', 'Rizta'],
                'Ola Electric': ['S1 Pro Gen 2', 'S1 X', 'S1 Air'],
                'Ashok Leyland': ['Dost+', 'Bada Dost', 'Partner', 'Ecomet', 'Viking']
            };

            function updateModelSuggestions(brand) {
                modelSuggestions.innerHTML = '';
                const models = BRAND_MODELS[brand];
                if (models && models.length > 0) {
                    modelSuggestions.style.display = 'flex';
                    models.forEach(mod => {
                        const pill = document.createElement('span');
                        pill.className = 'model-pill';
                        pill.textContent = mod;
                        pill.addEventListener('click', function() {
                            vehicleModelInput.value = mod;
                            vehicleModelInput.focus();
                            clearFieldError(vehicleModelInput, 'modelError');
                        });
                        modelSuggestions.appendChild(pill);
                    });
                } else {
                    modelSuggestions.style.display = 'none';
                }
            }

            vehicleModelInput.addEventListener('input', function() {
                if (this.value.trim().length > 0) {
                    clearFieldError(vehicleModelInput, 'modelError');
                }
            });

            // -----------------------------------------------------------------
            // 7. MULTIPLE VEHICLE PHOTO UPLOADS WITH PREVIEWS & REMOVAL
            // -----------------------------------------------------------------
            dropzone.addEventListener('click', () => photosInput.click());

            dropzone.addEventListener('dragover', (e) => {
                e.preventDefault();
                dropzone.classList.add('dragover');
            });

            dropzone.addEventListener('dragleave', () => {
                dropzone.classList.remove('dragover');
            });

            dropzone.addEventListener('drop', (e) => {
                e.preventDefault();
                dropzone.classList.remove('dragover');
                if (e.dataTransfer && e.dataTransfer.files) {
                    handleFilesAdded(Array.from(e.dataTransfer.files));
                }
            });

            photosInput.addEventListener('change', function() {
                if (this.files && this.files.length > 0) {
                    handleFilesAdded(Array.from(this.files));
                }
            });

            function handleFilesAdded(files) {
                const maxAllowed = 5;
                const maxSizeBytes = 5 * 1024 * 1024; // 5MB

                for (let file of files) {
                    if (uploadedFiles.length >= maxAllowed) {
                        showToastAlert('You can upload a maximum of 5 photos.', 'warning');
                        break;
                    }

                    if (!file.type.match(/^image\/(jpeg|jpg|png)$/i)) {
                        showToastAlert(file.name + ' is not a valid JPG or PNG image.', 'warning');
                        continue;
                    }

                    if (file.size > maxSizeBytes) {
                        showToastAlert(file.name + ' exceeds 5 MB size limit.', 'warning');
                        continue;
                    }

                    uploadedFiles.push(file);
                }

                syncPhotosInput();
                renderPreviews();
            }

            function syncPhotosInput() {
                const dt = new DataTransfer();
                uploadedFiles.forEach(file => dt.items.add(file));
                photosInput.files = dt.files;
            }

            function renderPreviews() {
                previewsGrid.innerHTML = '';
                if (uploadedFiles.length === 0) {
                    emptyPreviewHint.style.display = 'flex';
                    previewsGrid.appendChild(emptyPreviewHint);
                    return;
                }

                emptyPreviewHint.style.display = 'none';

                uploadedFiles.forEach((file, index) => {
                    const card = document.createElement('div');
                    card.className = 'preview-card-item';

                    const img = document.createElement('img');
                    img.className = 'preview-thumbnail-img';
                    img.alt = file.name;
                    img.src = URL.createObjectURL(file);

                    const removeBtn = document.createElement('button');
                    removeBtn.type = 'button';
                    removeBtn.className = 'btn-remove-photo';
                    removeBtn.title = 'Remove photo';
                    removeBtn.innerHTML = '<i class="fa-solid fa-xmark"></i>';
                    removeBtn.addEventListener('click', (e) => {
                        e.stopPropagation();
                        URL.revokeObjectURL(img.src);
                        uploadedFiles.splice(index, 1);
                        syncPhotosInput();
                        renderPreviews();
                    });

                    card.appendChild(img);
                    card.appendChild(removeBtn);
                    previewsGrid.appendChild(card);
                });
            }

            // -----------------------------------------------------------------
            // 8. FORM VALIDATION & CLIENT-SIDE CHECKS
            // -----------------------------------------------------------------
            function showFieldError(inputEl, errorId, message) {
                if (inputEl) {
                    inputEl.classList.add('is-invalid');
                    inputEl.classList.remove('is-valid');
                }
                const errSpan = document.getElementById(errorId);
                if (errSpan) {
                    errSpan.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> ' + message;
                    errSpan.style.display = 'block';
                }
            }

            function clearFieldError(inputEl, errorId) {
                if (inputEl) {
                    inputEl.classList.remove('is-invalid');
                }
                const errSpan = document.getElementById(errorId);
                if (errSpan) {
                    errSpan.style.display = 'none';
                }
            }

            function validateForm() {
                let isValid = true;
                let firstInvalidEl = null;

                // 1. Vehicle Type
                const vTypeVal = vehicleTypeSelect.value;
                if (!vTypeVal) {
                    showFieldError(vehicleTypeSelect, 'vehicleTypeError', 'Please select a vehicle type.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = vehicleTypeSelect;
                } else if (vTypeVal === 'Other' && !customVehicleType.value.trim()) {
                    showFieldError(customVehicleType, 'vehicleTypeError', 'Please specify the custom vehicle type.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = customVehicleType;
                } else {
                    clearFieldError(vehicleTypeSelect, 'vehicleTypeError');
                }

                // 2. Registration Number
                const regVal = regNumberInput.value.trim();
                const regPattern = /^[A-Z]{2}\s\d{2}\s[A-Z]{1,2}\s\d{4}$/;
                if (!regVal) {
                    showFieldError(regNumberInput, 'regNumberError', 'Please enter your vehicle registration number.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = regNumberInput;
                } else if (!regPattern.test(regVal)) {
                    showFieldError(regNumberInput, 'regNumberError', 'Follow format: TN 45 CY 6778');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = regNumberInput;
                } else if (isRegDuplicate) {
                    showFieldError(regNumberInput, 'regNumberError', 'This vehicle number is already registered.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = regNumberInput;
                } else {
                    clearFieldError(regNumberInput, 'regNumberError');
                }

                // 3. Vehicle Brand
                const brandVal = selectedBrandInput.value.trim();
                if (!brandVal) {
                    showFieldError(brandTrigger, 'brandError', 'Please select a vehicle brand.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = brandTrigger;
                } else if (brandVal === 'Other' && !customBrand.value.trim()) {
                    showFieldError(customBrand, 'brandError', 'Please specify the custom brand name.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = customBrand;
                } else {
                    clearFieldError(brandTrigger, 'brandError');
                }

                // 4. Vehicle Model
                const modelVal = vehicleModelInput.value.trim();
                if (!modelVal) {
                    showFieldError(vehicleModelInput, 'modelError', 'Please enter your vehicle model.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = vehicleModelInput;
                } else {
                    clearFieldError(vehicleModelInput, 'modelError');
                }

                // 5. Manufacturing Year
                const yearVal = mfgYearInput.value;
                if (!yearVal) {
                    showFieldError(yearPickerTrigger, 'yearError', 'Please select a manufacturing year.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = yearPickerTrigger;
                } else {
                    clearFieldError(yearPickerTrigger, 'yearError');
                }

                // 6. Fuel Type
                const fuelVal = fuelTypeSelect.value;
                if (!fuelVal) {
                    showFieldError(fuelTypeSelect, 'fuelError', 'Please select the fuel type.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = fuelTypeSelect;
                } else if (fuelVal === 'Other' && !customFuelType.value.trim()) {
                    showFieldError(customFuelType, 'fuelError', 'Please specify the fuel type.');
                    isValid = false;
                    if (!firstInvalidEl) firstInvalidEl = customFuelType;
                } else {
                    clearFieldError(fuelTypeSelect, 'fuelError');
                }

                if (firstInvalidEl) {
                    firstInvalidEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    if (typeof firstInvalidEl.focus === 'function') firstInvalidEl.focus();
                }

                return isValid;
            }

            // -----------------------------------------------------------------
            // 9. FORM SUBMISSION VIA AJAX WITH FALLBACK
            // -----------------------------------------------------------------
            form.addEventListener('submit', function(e) {
                e.preventDefault();

                if (!validateForm()) {
                    showToastAlert('Please fill in all mandatory fields with valid values.', 'danger');
                    return;
                }

                btnSave.disabled = true;
                const originalHtml = btnSave.innerHTML;
                btnSave.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> Saving Vehicle...';

                const formData = new FormData(form);
                const postUrl = form.getAttribute('action') || ('${pageContext.request.contextPath}/VehicleServlet');

                fetch(postUrl, {
                    method: 'POST',
                    body: formData,
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Network error during vehicle registration.');
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.success) {
                        isFormDirty = false;
                        showToastAlert('Vehicle registered successfully! Redirecting...', 'success');
                        setTimeout(() => {
                            window.location.href = data.redirectUrl || ('${pageContext.request.contextPath}/user/vehicles.jsp?msg=added');
                        }, 900);
                    } else {
                        btnSave.disabled = false;
                        btnSave.innerHTML = originalHtml;
                        showToastAlert(data.message || 'Error adding vehicle. Please try again.', 'danger');
                    }
                })
                .catch(err => {
                    console.error('Submission error:', err);
                    form.submit();
                });
            });

            // -----------------------------------------------------------------
            // 10. CANCEL BUTTON WITH UNSAVED CHANGES WARNING
            // -----------------------------------------------------------------
            btnCancel.addEventListener('click', function(e) {
                if (isFormDirty) {
                    const confirmLeave = confirm('You have unsaved changes. Are you sure you want to cancel?');
                    if (!confirmLeave) {
                        e.preventDefault();
                    }
                }
            });

            // Toast Alert Helper
            function showToastAlert(msg, type) {
                alertBanner.className = 'alert-toast alert-' + type;
                alertText.innerHTML = (type === 'success' 
                    ? '<i class="fa-solid fa-circle-check"></i> ' 
                    : '<i class="fa-solid fa-triangle-exclamation"></i> ') + msg;
                alertBanner.style.display = 'flex';
                alertBanner.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }

        })();
    </script>

</body>
</html>
