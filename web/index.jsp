<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>On Road Vehicle Breakdown Assistance — 24/7 Highway Emergency Support</title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Custom 3D Homepage Stylesheet (Strict Zero-Blue Palette) -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/homepage-3d.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/app-responsive.css?v=3.0">
    <script src="${pageContext.request.contextPath}/js/app-responsive.js?v=3.0" defer></script>
</head>
<body class="homepage-body">

    <!-- =====================================================================
         1. FIXED HEADER NAVIGATION (STRICT SINGLE-ROW DESKTOP BAR)
         ===================================================================== -->
    <header class="site-header" id="siteHeader">
        <div class="header-container">
            <!-- Left Side: Brand Logo and Title -->
            <a href="${pageContext.request.contextPath}/index.jsp" class="header-brand">
                <div class="header-brand-icon">
                    <i class="fa-solid fa-car-burst"></i>
                </div>
                <div class="header-brand-text">
                    <span class="header-brand-title">On Road Vehicle</span>
                    <span class="header-brand-sub">BREAKDOWN</span>
                    <span class="header-brand-sub">ASSISTANCE</span>
                </div>
            </a>

            <!-- Center: Navigation Menu (Single straight horizontal line) -->
            <ul class="header-nav" id="headerNav">
                <li><a href="#hero-track" class="header-nav-link active"><i class="fa-solid fa-binoculars"></i> <span>Home</span></a></li>
                <li><a href="#services-section" class="header-nav-link"><i class="fa-solid fa-screwdriver-wrench"></i> <span>Services</span></a></li>
                <li><a href="#dispatch-search" class="header-nav-link"><i class="fa-solid fa-magnifying-glass-location"></i> <span>Find Mechanic</span></a></li>
                <li><a href="#portals-section" class="header-nav-link"><i class="fa-solid fa-id-card"></i> <span>Portals</span></a></li>
                
            </ul>

            <!-- Right Side: Login & Emergency Buttons -->
            <div class="header-actions">
                <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-header-portal" title="Motorist User Portal">
                    <i class="fa-solid fa-user"></i> <span>User</span>
                </a>
                <a href="${pageContext.request.contextPath}/mechanic/login.jsp" class="btn-header-portal" title="Mechanic Workshop Portal">
                    <i class="fa-solid fa-wrench"></i> <span>Mechanic</span>
                </a>
               
            
                <!-- Mobile Hamburger Toggle -->
                <button type="button" class="mobile-menu-btn" id="mobileMenuBtn" aria-label="Toggle navigation menu">
                    <i class="fa-solid fa-bars"></i>
                </button>
            </div>
        </div>

        <!-- Mobile Drawer Navigation -->
        <nav class="mobile-drawer" id="mobileDrawer" aria-label="Mobile Navigation">
            <ul class="mobile-nav-list">
                <li><a href="#hero-track" class="mobile-nav-link active"><i class="fa-solid fa-binoculars"></i> Story</a></li>
                <li><a href="#services-section" class="mobile-nav-link"><i class="fa-solid fa-screwdriver-wrench"></i> Services</a></li>
                <li><a href="#dispatch-search" class="mobile-nav-link"><i class="fa-solid fa-magnifying-glass-location"></i> Find Mechanic</a></li>
                <li><a href="#portals-section" class="mobile-nav-link"><i class="fa-solid fa-id-card"></i> Portals</a></li>
              
            </ul>
            <div class="mobile-drawer-portals">
                <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-mobile-portal"><i class="fa-solid fa-user"></i> User Portal</a>
                <a href="${pageContext.request.contextPath}/mechanic/login.jsp" class="btn-mobile-portal"><i class="fa-solid fa-wrench"></i> Mechanic Portal</a>
                <a href="tel:18004257623" class="btn-header-emergency" style="width: 100%; justify-content: center; margin-top: 6px;">
                    <i class="fa-solid fa-phone-volume"></i> SOS +91 9876543210
                </a>
            </div>
        </nav>
    </header>

    <!-- =====================================================================
         2. CINEMATIC 3D BACKGROUND STAGE (FIXED BACKDROP)
         ===================================================================== -->
    <div class="cinematic-backdrop-fixed" id="hero-backdrop" aria-hidden="true">
        <!-- Three.js 3D WebGL Canvas -->
        <canvas id="three-canvas"></canvas>

        <!-- Atmospheric Sunset Glow & Vignette -->
        <div class="stage-vignette"></div>
        <div class="sun-atmospheric-glow"></div>
    </div>

    <!-- Fixed Floating Vertical Scene Progress Tracker (01 to 06) -->
    <aside class="scene-progress-tracker" id="sceneTracker" aria-label="Story Scene Progress">
        <button class="tracker-item active" data-target="#scene-1" aria-label="Scene 1: Highway Cruising">
            <span class="tracker-label">01. JOURNEY</span>
            <span class="tracker-dot"></span>
        </button>
        <button class="tracker-item" data-target="#scene-2" aria-label="Scene 2: Unexpected Trouble">
            <span class="tracker-label">02. BREAKDOWN</span>
            <span class="tracker-dot"></span>
        </button>
        <button class="tracker-item" data-target="#scene-3" aria-label="Scene 3: Find Nearby Assistance">
            <span class="tracker-label">03. FIND HELP</span>
            <span class="tracker-dot"></span>
        </button>
        <button class="tracker-item" data-target="#scene-4" aria-label="Scene 4: Mechanic on the Way">
            <span class="tracker-label">04. ARRIVAL</span>
            <span class="tracker-dot"></span>
        </button>
        <button class="tracker-item" data-target="#scene-5" aria-label="Scene 5: Roadside Repair">
            <span class="tracker-label">05. REPAIR</span>
            <span class="tracker-dot"></span>
        </button>
        <button class="tracker-item" data-target="#scene-6" aria-label="Scene 6: Journey Continues">
            <span class="tracker-label">06. BACK ON ROAD</span>
            <span class="tracker-dot"></span>
        </button>
    </aside>

    <!-- =====================================================================
         3. SEQUENTIAL 6-SCENE STORYTELLING TRACK (LEFT-RIGHT ALTERNATING ZIGZAG)
         ===================================================================== -->
    <main class="story-flow-track" id="hero-track">
        
        <!-- SCENE 1: Highway Cruising (3D Animation: LEFT | Text: RIGHT) -->
        <section class="story-scene-section scene-layout-odd scene-text-right" id="scene-1" data-scene="1">
            <div class="story-scene-container">
                <!-- Dedicated Visual Region (50% Width) - Keeps truck animation unobstructed on the LEFT -->
                <div class="scene-visual-region" aria-hidden="true"></div>

                <!-- Dedicated Text Region (50% Width) on the RIGHT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge">01</div>
                        <span class="scene-tag">Highway Cruising</span>
                    </div>
                    <h2 class="story-heading">Your Journey <span class="highlight">Matters</span></h2>
                    <p class="story-subtitle">
                        Every journey deserves a safe and reliable road. Seamless highway freight and passenger breakdown support connecting thousands of vehicles across Tamil Nadu.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-magnifying-glass"></i> Find a Mechanic
                        </a>
                        <a href="#services-section" class="btn-scene-secondary">
                            <i class="fa-solid fa-screwdriver-wrench"></i> Explore Services
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- SCENE 2: Unexpected Trouble (Text: LEFT | 3D Breakdown: RIGHT) -->
        <section class="story-scene-section scene-layout-even scene-text-left" id="scene-2" data-scene="2">
            <div class="story-scene-container">
                <!-- Dedicated Text Region (50% Width) on the LEFT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge badge-danger">02</div>
                        <span class="scene-tag tag-danger">Unexpected Trouble</span>
                    </div>
                    <h2 class="story-heading">Unexpected <span class="highlight">Breakdown?</span></h2>
                    <p class="story-subtitle">
                        Vehicle trouble can happen anytime on isolated stretches. Engine overheating, smoke under the hood, or sudden clutch failure — getting qualified help should be simple.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-location-crosshairs"></i> Find Nearby Mechanics
                        </a>
                        <a href="tel:18004257623" class="btn-scene-secondary">
                            <i class="fa-solid fa-truck-pickup"></i> Emergency Towing
                        </a>
                    </div>
                </div>

                <!-- Dedicated Visual Region (50% Width) - Keeps truck animation unobstructed on the RIGHT -->
                <div class="scene-visual-region" aria-hidden="true"></div>
            </div>
        </section>

        <!-- SCENE 3: Finding Nearby Assistance (3D Mobile Search: LEFT | Text: RIGHT) -->
        <section class="story-scene-section scene-layout-odd scene-text-right" id="scene-3" data-scene="3">
            <div class="story-scene-container">
                <!-- Dedicated Visual Region (50% Width) - Keeps driver and truck animation unobstructed on the LEFT -->
                <div class="scene-visual-region" aria-hidden="true"></div>

                <!-- Dedicated Text Region (50% Width) on the RIGHT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge">03</div>
                        <span class="scene-tag">Find Nearby Assistance</span>
                    </div>
                    <h2 class="story-heading">Help Is Just a <span class="highlight">Search Away</span></h2>
                    <p class="story-subtitle">
                        Find nearby mechanics, explore their services, and request assistance without wasting time during an unexpected breakdown.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-location-crosshairs"></i> Find Nearby Mechanics
                        </a>
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-secondary">
                            <i class="fa-solid fa-paper-plane"></i> Request Assistance
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- SCENE 4: Mechanic on the Way (Text: LEFT | 3D Service Motorcycle: RIGHT) -->
        <section class="story-scene-section scene-layout-even scene-text-left" id="scene-4" data-scene="4">
            <div class="story-scene-container">
                <!-- Dedicated Text Region (50% Width) on the LEFT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge">04</div>
                        <span class="scene-tag">Mechanic on the Way</span>
                    </div>
                    <h2 class="story-heading"><span class="highlight">Reliable Help</span> Is on the Way</h2>
                    <p class="story-subtitle">
                        Connect with a qualified mechanic who can reach your breakdown location and provide the assistance you need.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-location-arrow"></i> Track Assistance
                        </a>
                        <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="btn-scene-secondary">
                            <i class="fa-solid fa-file-lines"></i> View Service Request
                        </a>
                    </div>
                </div>

                <!-- Dedicated Visual Region (50% Width) - Keeps mechanic & truck unobstructed on the RIGHT -->
                <div class="scene-visual-region" aria-hidden="true"></div>
            </div>
        </section>

        <!-- SCENE 5: Roadside Repair (3D Repair Animation: LEFT | Text: RIGHT) -->
        <section class="story-scene-section scene-layout-odd scene-text-right" id="scene-5" data-scene="5">
            <div class="story-scene-container">
                <!-- Dedicated Visual Region (50% Width) - Keeps repair animation unobstructed on the LEFT -->
                <div class="scene-visual-region" aria-hidden="true"></div>

                <!-- Dedicated Text Region (50% Width) on the RIGHT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge">05</div>
                        <span class="scene-tag">Roadside Repair</span>
                    </div>
                    <h2 class="story-heading">Getting You Back on the <span class="highlight">Road</span></h2>
                    <p class="story-subtitle">
                        Our roadside assistance connects you with mechanics who help diagnose and repair vehicle breakdown issues so you can continue your journey safely.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-wrench"></i> View Repair Status
                        </a>
                        <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="btn-scene-secondary">
                            <i class="fa-solid fa-clock-rotate-left"></i> Service History
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- SCENE 6: Happy Journey (Text: LEFT | 3D Truck Departure: RIGHT) -->
        <section class="story-scene-section scene-layout-even scene-text-left" id="scene-6" data-scene="6">
            <div class="story-scene-container">
                <!-- Dedicated Text Region (50% Width) on the LEFT -->
                <div class="scene-text-region story-scene-content">
                    <div class="scene-badge-row">
                        <div class="scene-num-badge badge-success">06</div>
                        <span class="scene-tag tag-success">Journey Continues</span>
                    </div>
                    <h2 class="story-heading">Back on the Road, <span class="highlight">Safely</span></h2>
                    <p class="story-subtitle">
                        Your journey matters. Get reliable roadside assistance, connect with trusted mechanics, and continue your journey with confidence.
                    </p>
                    <div class="scene-cta-row">
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-primary">
                            <i class="fa-solid fa-magnifying-glass"></i> Find a Mechanic
                        </a>
                        <a href="${pageContext.request.contextPath}/user/login.jsp" class="btn-scene-secondary">
                            <i class="fa-solid fa-arrow-right"></i> Get Started
                        </a>
                    </div>
                </div>

                <!-- Dedicated Visual Region (50% Width) - Keeps truck and mechanic unobstructed on the RIGHT -->
                <div class="scene-visual-region" aria-hidden="true"></div>
            </div>
        </section>

    </main>

    <!-- =====================================================================
         3. HOMEPAGE CONTENT WRAPPER (BELOW 3D HERO WORLD)
         ===================================================================== -->
    <div class="homepage-content-wrapper">
        
        <!-- 3.1 SIX CORE BREAKDOWN SERVICES SECTION -->
        <section class="section-container" id="services-section">
            <div class="section-header-center">
                <div class="section-badge"><i class="fa-solid fa-shield-halved"></i> 24/7 Roadside Network</div>
                <h2 class="section-title">Comprehensive Breakdown Services</h2>
                <p class="section-desc">
                    From minor on-road fixes to heavy-duty flatbed towing, our network of verified mechanics is ready to dispatch anywhere across Tamil Nadu highways.
                </p>
            </div>

            <div class="services-grid-6">
                <!-- Service 1: Towing -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-truck-pickup"></i></div>
                    <h3 class="service-title">Emergency Towing</h3>
                    <p class="service-desc">
                        Flatbed and wheel-lift towing for heavy commercial trucks, SUVs, and passenger sedans to the nearest certified workshop.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Book Towing <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>

                <!-- Service 2: Battery Jumpstart -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-car-battery"></i></div>
                    <h3 class="service-title">Battery Jumpstart</h3>
                    <p class="service-desc">
                        Rapid on-site booster jumpstarts, alternator testing, and immediate battery replacement for all vehicle makes.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Request Jumpstart <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>

                <!-- Service 3: Flat Tyre Puncture -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-circle-dot"></i></div>
                    <h3 class="service-title">Flat Tyre Assistance</h3>
                    <p class="service-desc">
                        High-speed mobile tyre change, tubeless puncture patching, pressure inflation, and heavy-vehicle wheel replacement.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Fix Tyre <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>

                <!-- Service 4: On-Site Engine & AC -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-gears"></i></div>
                    <h3 class="service-title">Engine & Mechanical</h3>
                    <p class="service-desc">
                        Radiator overheating resolution, fan belt repairs, starter motor diagnosis, and emergency mechanical troubleshooting.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Diagnose Engine <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>

                <!-- Service 5: Emergency Fuel -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-gas-pump"></i></div>
                    <h3 class="service-title">Emergency Fuel Delivery</h3>
                    <p class="service-desc">
                        Stranded with an empty tank? Our mobile patrol brings 5 to 10 liters of petrol or diesel straight to your coordinates.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Deliver Fuel <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>

                <!-- Service 6: Lockout & Key Assist -->
                <div class="service-feature-card">
                    <div class="service-icon-circle"><i class="fa-solid fa-key"></i></div>
                    <h3 class="service-title">Lockout & Key Assist</h3>
                    <p class="service-desc">
                        Accidental vehicle lockouts handled with zero damage to window seals, door frames, or electronic lock sensors.
                    </p>
                    <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="service-link">
                        Unlock Car <i class="fa-solid fa-arrow-right"></i>
                    </a>
                </div>
            </div>
                        
                        
                        <div class="mt-5 mb-5">
                            
                        </div>

          
        </section>

        <!-- 3.3 TWO DEDICATED ROLE PORTALS SHOWCASE -->
        <section class="section-container" id="portals-section">
            <div class="section-header-center">
                <div class="section-badge"><i class="fa-solid fa-user-group"></i> Multi-Role Ecosystem</div>
                <h2 class="section-title">Access Your Dedicated Portal</h2>
                <p class="section-desc">
                    Whether you are a stranded driver requiring immediate rescue, a certified workshop accepting jobs, or a platform administrator.
                </p>
            </div>

            <div class="portals-showcase-grid">
                
                <!-- Portal 1: Motorist User -->
                <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="portal-gateway-card">
                    <div class="portal-icon-lg" style="background-color: rgba(22, 163, 74, 0.15); color: #16A34A;">
                        <i class="fa-solid fa-car-side"></i>
                    </div>
                    <h3 style="font-size: 20px; font-weight: 800; color: #FFF;">Motorist Portal</h3>
                    <p style="color: #9CA3AF; font-size: 14px; line-height: 1.6;">
                        Request roadside assistance in 30 seconds. Track the dispatched mechanic in real time with GPS navigation, fast roadside dispatch, and feedback ratings.
                    </p>
                    <span class="btn-scene-primary" style="width: 100%; justify-content: center; background: #16A34A; box-shadow: 0 4px 16px rgba(22, 163, 74, 0.35);">
                        Open Motorist Portal <i class="fa-solid fa-arrow-right"></i>
                    </span>
                </a>

                <!-- Portal 2: Mechanic Partner -->
                <a href="${pageContext.request.contextPath}/mechanic/dashboard.jsp" class="portal-gateway-card">
                    <div class="portal-icon-lg" style="background-color: rgba(234, 88, 12, 0.15); color: #EA580C;">
                        <i class="fa-solid fa-wrench"></i>
                    </div>
                    <h3 style="font-size: 20px; font-weight: 800; color: #FFF;">Mechanic Portal</h3>
                    <p style="color: #9CA3AF; font-size: 14px; line-height: 1.6;">
                        Receive emergency roadside service alerts within your coverage radius. Accept requests, navigate to stranded vehicles, update status, and manage earnings.
                    </p>
                    <span class="btn-scene-primary" style="width: 100%; justify-content: center; background: #EA580C; box-shadow: 0 4px 16px rgba(234, 88, 12, 0.35);">
                        Open Mechanic Portal <i class="fa-solid fa-arrow-right"></i>
                    </span>
                </a>

           

            </div>
        </section>

    </div>

    <!-- =====================================================================
         4. SITE FOOTER
         ===================================================================== -->
    <footer class="site-footer" id="contact-footer">
        <div class="footer-container">
            <div class="footer-top-grid">
                
                <!-- Col 1: About & Hotline -->
                <div>
                    <a href="${pageContext.request.contextPath}/index.jsp" class="header-brand" style="margin-bottom: 16px;">
                        <div class="header-brand-icon">
                            <i class="fa-solid fa-car-burst"></i>
                        </div>
                        <div class="header-brand-text">
                            <span class="header-brand-title">On Road Vehicle</span>
                            <span class="header-brand-sub">Breakdown Assistance</span>
                        </div>
                    </a>
                    <p style="color: #9CA3AF; font-size: 14px; line-height: 1.6; margin-bottom: 20px;">
                        Tamil Nadu’s premier continuous roadside assistance network connecting stranded drivers with verified mobile mechanics and emergency flatbed towers 24 hours a day.
                    </p>
                  
                </div>

                <!-- Col 2: Services -->
                <div>
                    <h4 class="footer-col-title">Assistance Services</h4>
                    <ul class="footer-links-list">
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Emergency Towing</a></li>
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Battery Boost & Replacement</a></li>
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Tyre Puncture & Replacement</a></li>
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Engine Overheating Diagnostic</a></li>
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Emergency Fuel Supply</a></li>
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">Vehicle Lockout Assistance</a></li>
                    </ul>
                </div>

                <!-- Col 3: Quick Navigation -->
                <div>
                    <h4 class="footer-col-title">Quick Portals</h4>
                    <ul class="footer-links-list">
                        <li><a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="footer-link">User Login</a></li>
                        <li><a href="${pageContext.request.contextPath}/mechanic/dashboard.jsp" class="footer-link">Mechanic Partner Portal</a></li>
                      
                        
                       
                    </ul>
                </div>

                <!-- Col 4: Major Coverage -->
                <div>
                    <h4 class="footer-col-title">Highway Coverage</h4>
                    <p style="color: #9CA3AF; font-size: 13px; margin-bottom: 14px;">
                        Rapid mechanic deployment across all major NH & SH corridors:
                    </p>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px;">
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Chennai</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Coimbatore</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Madurai</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Trichy</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Salem</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Vellore</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">Tirunelveli</span>
                        <span style="background: rgba(255,255,255,0.06); padding: 4px 10px; border-radius: 8px; font-size: 12px; color: #D1D5DB;">NH 44   •   NH 48  •  NH 83</span>
                    </div>
                </div>

            </div>

            <!-- Footer Bottom Row -->
            <div class="footer-bottom-row">
                <div>
    &copy; <span id="currentYear"></span>
    <strong>On Road Vehicle Breakdown Assistance</strong>. All rights reserved.
</div>

<script>
    document.getElementById("currentYear").textContent = new Date().getFullYear();
</script>
            </div>
        </div>
    </footer>

    <!-- =====================================================================
         5. SCRIPTS (THREE.JS, GSAP, SCROLLTRIGGER, CUSTOM 3D ENGINE)
         ===================================================================== -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js"></script>
    <script src="${pageContext.request.contextPath}/js/homepage-3d.js?v=3.0"></script>

</body>
</html>
