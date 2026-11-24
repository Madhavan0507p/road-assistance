<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!-- ==========================================================================
     UNIVERSAL RICH SERVICE REQUEST DETAILS MODAL
     Matches exact reference design from media_1794635951528_6fd0d4b1.jpg
     Used across Admin, Mechanic, and User modules for consistent rich inspection
     ========================================================================== -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin-service-view.css?v=3.2">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

<!-- MODAL 1: VIEW SERVICE REQUEST DETAILS MODAL (#viewRequestModal) -->
<div class="modal-backdrop service-view-backdrop" id="viewRequestModal" style="display: none;">
    <div class="service-view-modal">
        <!-- Top Header Bar -->
        <div class="service-view-header">
            <div class="sv-header-left">
                <div class="sv-header-icon-box">
                    <i class="fa-solid fa-wrench"></i>
                </div>
                <div class="sv-header-title-box">
                    <h3>Service Request Details</h3>
                    <p>Complete information about the vehicle service request</p>
                </div>
            </div>
            <div class="sv-header-right">
                <span class="sv-req-id-pill" id="svModalCode">SR0467</span>
                <span class="sv-status-pill" id="svModalStatusPill">
                    <i class="fa-solid fa-arrows-rotate" id="svModalStatusIcon"></i>
                    <span id="svModalStatusText">Pending</span>
                </span>
                <button type="button" class="sv-close-btn" data-modal-close aria-label="Close Modal" onclick="closeServiceRequestModal()">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
        </div>

        <!-- Modal Body Container -->
        <div class="service-view-body">
            <!-- Row 1: Top 2-Column Grid -->
            <div class="sv-top-grid">
                <!-- Left Column: User Information + Vehicle Information -->
                <div style="display: flex; flex-direction: column; gap: 16px;">
                    <!-- Card 1: User Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-user"></i>
                            <span>User Information</span>
                        </div>
                        <div class="sv-person-row">
                            <div class="sv-avatar-container" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 2px solid #F97316; color: #F97316; font-size: 20px;">
                                <i class="fa-solid fa-user"></i>
                            </div>
                            <div class="sv-person-name-box">
                                <div class="sv-person-name" id="svUserName">Ravi Kumar</div>
                                <div class="sv-person-code" id="svUserCode">USR012</div>
                            </div>
                            <div class="sv-divider-v"></div>
                            <div class="sv-contact-list">
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-phone"></i>
                                    <span id="svUserPhone">9875823975</span>
                                </div>
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-envelope"></i>
                                    <span id="svUserEmail">madhavan0507p@gmail.com</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Card 2: Vehicle Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-car"></i>
                            <span>Vehicle Information</span>
                        </div>
                        <div class="sv-vehicle-row">
                            <div class="sv-vehicle-img-wrap">
                                <img id="svVehicleImg" src="${pageContext.request.contextPath}/images/vehicle-swift.png" alt="Vehicle Photo" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-swift.png';">
                            </div>
                            <div class="sv-key-val-grid">
                                <span class="sv-lbl">Vehicle Number</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val-bold" id="svVehicleNumber">TN 45 CY 6778</span>

                                <span class="sv-lbl">Vehicle Type</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleType">Car</span>

                                <span class="sv-lbl">Brand & Model</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleBrandModel">BMW M5 Competition</span>

                                <span class="sv-lbl">Color</span>
                                <span class="sv-colon">:</span>
                                <span class="sv-val" id="svVehicleColor"></span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Service Request Information + Mechanic -->
                <div style="display: flex; flex-direction: column; gap: 16px;">
                    <!-- Card 3: Service Request Information -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-clipboard-list"></i>
                            <span>Service Request Information</span>
                        </div>
                        <div class="sv-sr-info-grid">
                            <span class="sv-lbl">Service Request ID</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val-bold" id="svSrId">SR0467</span>

                            <span class="sv-lbl">Breakdown Issue</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-gear" style="color: #4B5563; font-size: 13px;"></i>
                                <span id="svSrIssue">Engine Failure</span>
                            </span>

                            <span class="sv-lbl">Requested Date & Time</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-calendar-days" style="color: #F97316; font-size: 13px;"></i>
                                <span id="svSrDate">13-11-2026, 12:47 PM</span>
                            </span>

                            <span class="sv-lbl">Location</span>
                            <span class="sv-colon">:</span>
                            <span class="sv-val" style="display: inline-flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-location-dot" style="color: #F97316; font-size: 13px;"></i>
                                <span id="svSrLocation">Sri sairam Towers, NSR Road, Saibaba Colony</span>
                            </span>

                            <span class="sv-lbl">Status</span>
                            <span class="sv-colon">:</span>
                            <div>
                                <span class="sv-pill-status-inline" id="svSrStatusBadge">
                                    <i class="fa-solid fa-rotate" style="font-size: 11px;"></i>
                                    <span id="svSrStatusText">Pending</span>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Card 4: Mechanic -->
                    <div class="sv-card">
                        <div class="sv-card-header">
                            <i class="fa-solid fa-user-gear"></i>
                            <span>Mechanic</span>
                        </div>
                        <div class="sv-person-row">
                            <div class="sv-avatar-container" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 2px solid #F97316; color: #F97316; font-size: 20px;">
                                <i class="fa-solid fa-wrench"></i>
                            </div>
                            <div class="sv-person-name-box">
                                <div class="sv-person-name" id="svMechName">Unassigned</div>
                                <div class="sv-person-code" id="svMechCode">-</div>
                            </div>
                            <div class="sv-divider-v"></div>
                            <div class="sv-contact-list">
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-phone"></i>
                                    <span id="svMechPhone">-</span>
                                </div>
                                <div class="sv-contact-item">
                                    <i class="fa-solid fa-store"></i>
                                    <span id="svMechWorkshop">Unassigned</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 2: Request Description (Full Width) -->
            <div class="sv-desc-card">
                <div class="sv-card-header" style="margin-bottom: 10px;">
                    <i class="fa-solid fa-file-lines"></i>
                    <span>Request Description</span>
                </div>
                <div class="sv-desc-box" id="svDescription">
                    At the S bend i cant able to Move my car it was stuck due to engine failure
                </div>
            </div>

            <!-- Row 3: Bottom Grid (Timeline + Location Map) -->
            <div class="sv-bottom-grid">
                <!-- Card 6: Service Timeline -->
                <div class="sv-card">
                    <div class="sv-card-header" style="margin-bottom: 14px;">
                        <i class="fa-solid fa-clipboard-check"></i>
                        <span>Service Timeline</span>
                    </div>
                    <div class="sv-stepper-track">
                        <div class="sv-node-circle node-done" id="svNode1">
                            <i class="fa-solid fa-check"></i>
                        </div>
                        <div class="sv-step-line" id="svLine1"></div>
                        <div class="sv-node-circle" id="svNode2">
                            <i class="fa-solid fa-check"></i>
                        </div>
                        <div class="sv-step-line" id="svLine2"></div>
                        <div class="sv-node-circle" id="svNode3">
                            <i class="fa-solid fa-wrench"></i>
                        </div>
                        <div class="sv-step-line" id="svLine3"></div>
                        <div class="sv-node-circle" id="svNode4">
                            <i class="fa-solid fa-check"></i>
                        </div>
                    </div>
                    <div class="sv-stepper-labels">
                        <div>
                            <div class="sv-step-lbl-title">Request Received</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep1">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">Mechanic</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep2">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">In Progress</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep3">--</div>
                        </div>
                        <div>
                            <div class="sv-step-lbl-title">Completed</div>
                            <div class="sv-step-lbl-sub" id="svTimeStep4">--</div>
                        </div>
                    </div>
                </div>

                <!-- Card 7: Location Map -->
                <div class="sv-card">
                    <div class="sv-location-header">
                        <div class="sv-card-header" style="margin-bottom: 0;">
                            <i class="fa-solid fa-location-dot"></i>
                            <span>Problem Location</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <span id="svCoordsBadge" class="sv-coords-badge" title="Reported GPS Coordinates">11.0264, 76.9472</span>
                            <button type="button" class="sv-btn-expand" id="btnExpandMap" title="View Fullscreen Map" onclick="openFullscreenMapModal()">
                                <i class="fa-solid fa-expand"></i> Expand
                            </button>
                        </div>
                    </div>
                    <div class="sv-map-wrap" id="svMapWrap" onclick="openFullscreenMapModal()" title="Click to view full interactive breakdown map">
                        <div id="svMiniMap" style="width: 100%; height: 100%; border-radius: 8px; z-index: 1;"></div>
                        <div class="sv-map-overlay-badge">
                            <i class="fa-solid fa-crosshairs"></i>
                            <span id="svMapBadgeLoc">Sri sairam Towers, NSR Road, Saibaba Colony</span>
                        </div>
                        <div class="sv-map-click-hint">
                            <i class="fa-solid fa-up-right-and-down-left-from-center"></i> Expand
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modal Footer -->
        <div class="service-view-footer">
            <button type="button" class="sv-btn-close" data-modal-close onclick="closeServiceRequestModal()">
                <i class="fa-solid fa-xmark"></i> Close
            </button>
            <div id="svModalContextActions" style="display: inline-flex; align-items: center; gap: 8px;">
                <!-- Dynamically filled with role-specific actions -->
            </div>
        </div>
    </div>
</div>

<!-- FULLSCREEN INTERACTIVE BREAKDOWN LOCATION MAP MODAL (#fullscreenMapModal) -->
<div class="modal-backdrop" id="fullscreenMapModal" style="z-index: 2100; display: none;">
    <div class="modal-box" style="max-width: 900px; width: 95%;">
        <div class="modal-header" style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="width: 36px; height: 36px; border-radius: 8px; background: #FFF7ED; color: #EA580C; display: flex; align-items: center; justify-content: center; font-size: 16px;">
                    <i class="fa-solid fa-location-dot"></i>
                </div>
                <div>
                    <h3 style="margin: 0; font-size: 17px; font-weight: 800; color: #111827;">Breakdown Spot Details</h3>
                    <p style="margin: 0; font-size: 12px; color: #6B7280;">Incident location map &amp; GPS routing</p>
                </div>
            </div>
            <button type="button" class="modal-close-btn" onclick="closeFullscreenMapModal()" style="border: none; background: transparent; font-size: 20px; color: #64748B; cursor: pointer;">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
        <div class="modal-body" style="padding: 16px 0 0 0;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; background: #F8FAFC; padding: 10px 14px; border-radius: 10px; border: 1px solid #E2E8F0;">
                <div>
                    <span style="font-size: 11px; text-transform: uppercase; font-weight: 700; color: #64748B; letter-spacing: 0.5px;">Location Address</span>
                    <div id="fsLocationAddress" style="font-weight: 700; color: #1E293B; font-size: 14px;">Coimbatore, TN</div>
                </div>
                <div style="text-align: right;">
                    <span style="font-size: 11px; text-transform: uppercase; font-weight: 700; color: #64748B; letter-spacing: 0.5px;">Coordinates</span>
                    <div id="fsCoordinates" style="font-family: monospace; font-size: 13px; font-weight: 700; color: #EA580C;">11.0268, 76.9507</div>
                </div>
            </div>
            <div id="fsFullMap" style="width: 100%; height: 420px; border-radius: 12px; border: 1px solid #E2E8F0; z-index: 1;"></div>
        </div>
        <div class="modal-footer" style="display: flex; justify-content: space-between; align-items: center; margin-top: 16px; border-top: 1px solid #E5E7EB; padding-top: 12px;">
            <div style="display: flex; align-items: center; gap: 8px;">
                <span class="sr-tag-badge tag-request" id="fsMapCode">SR0467</span>
                <span class="sr-tag-badge tag-issue" id="fsIssueBadge">Engine Failure</span>
            </div>
            <div style="display: flex; gap: 8px;">
                <a href="#" target="_blank" id="fsGoogleMapsLink" class="btn-action-primary" style="background: #10B981; border-color: #10B981; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; font-size: 13px; border-radius: 8px; color: #FFFFFF; font-weight: 700;">
                    <i class="fa-solid fa-diamond-turn-right"></i> Open in Google Maps
                </a>
                <button type="button" class="btn-action-secondary" onclick="closeFullscreenMapModal()" style="padding: 8px 14px; font-size: 13px; border-radius: 8px; border: 1px solid #E2E8F0; background: #FFFFFF; color: #475569; font-weight: 700; cursor: pointer;">
                    Close
                </button>
            </div>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/js/service-request-view-modal.js?v=3.3"></script>
