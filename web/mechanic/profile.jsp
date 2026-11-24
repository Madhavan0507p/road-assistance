<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.io.File" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.util.Base64" %>
<%@ page import="com.roadassistance.model.Mechanic" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%
    // Prevent browser back-button caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 1. Mechanic Session Authentication & Approval Verification
    Mechanic currentMech = (Mechanic) session.getAttribute("mechanic");
    if (currentMech == null || !currentMech.isApproved()) {
        if (session != null) {
            session.removeAttribute("mechanic");
        }
        String redirectParam = (currentMech != null && currentMech.isBlocked()) ? "error=blocked" : ((currentMech != null && currentMech.isPending()) ? "error=pending" : "msg=auth_required");
        response.sendRedirect(request.getContextPath() + "/mechanic/login.jsp?" + redirectParam);
        return;
    }

    request.setAttribute("activeMechPage", "profile");

    // Dynamic Current Date Display
    SimpleDateFormat sdfDisplayDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDisplayDate.format(new Date());

    // 2. Handle POST Profile Update
    String updateStatus = request.getParameter("msg");
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String uFirstName = request.getParameter("firstName");
        String uLastName = request.getParameter("lastName");
        String uGender = request.getParameter("gender");
        String uDob = request.getParameter("dob");
        String uPhone = request.getParameter("phone");
        String uShopContact = request.getParameter("shopContactNumber");
        String uShop = request.getParameter("workshopName");
        String uShopType = request.getParameter("shopType");
        String uSpec = request.getParameter("specialization");
        String uOtherSpec = request.getParameter("otherSpecialization");
        
        // Multi-select service types
        String[] serviceTypeArr = request.getParameterValues("serviceTypes");
        String uServiceTypes = "";
        if (serviceTypeArr != null && serviceTypeArr.length > 0) {
            StringBuilder sbServices = new StringBuilder();
            for (int i = 0; i < serviceTypeArr.length; i++) {
                if (i > 0) sbServices.append(", ");
                sbServices.append(serviceTypeArr[i].trim());
            }
            uServiceTypes = sbServices.toString();
        } else {
            uServiceTypes = request.getParameter("serviceTypesString") != null ? request.getParameter("serviceTypesString") : "General Service";
        }

        String uExp = request.getParameter("yearsOfExperience");
        String uOpen = request.getParameter("openingTime");
        if (uOpen == null || uOpen.trim().isEmpty()) {
            uOpen = (currentMech.getOpeningTime() != null && !currentMech.getOpeningTime().trim().isEmpty()) ? currentMech.getOpeningTime() : "09:00 AM";
        }
        String uClose = request.getParameter("closingTime");
        if (uClose == null || uClose.trim().isEmpty()) {
            uClose = (currentMech.getClosingTime() != null && !currentMech.getClosingTime().trim().isEmpty()) ? currentMech.getClosingTime() : "07:00 PM";
        }
        String uDesc = request.getParameter("shopDescription");
        String uAddr1 = request.getParameter("addressLine1");
        String uAddr2 = request.getParameter("addressLine2");
        String uCity = request.getParameter("city");
        String uDistrict = request.getParameter("district");
        String uPincode = request.getParameter("pincode");
        String uLatStr = request.getParameter("latitude");
        String uLngStr = request.getParameter("longitude");

        double uLat = 11.0268;
        double uLng = 76.9507;
        try {
            if (uLatStr != null && !uLatStr.trim().isEmpty()) uLat = Double.parseDouble(uLatStr.trim());
            if (uLngStr != null && !uLngStr.trim().isEmpty()) uLng = Double.parseDouble(uLngStr.trim());
        } catch (Exception ignored) {}

        String uOwner = ((uFirstName != null ? uFirstName.trim() : "") + " " + (uLastName != null ? uLastName.trim() : "")).trim();
        if (uOwner.isEmpty()) uOwner = currentMech.getOwnerName() != null ? currentMech.getOwnerName() : "Sathish K";

        String uAddress = (uAddr1 != null ? uAddr1.trim() : "");
        if (uAddr2 != null && !uAddr2.trim().isEmpty()) {
            uAddress += ", " + uAddr2.trim();
        }
        if (uCity != null && !uCity.trim().isEmpty()) {
            uAddress += ", " + uCity.trim();
        }

        Connection updConn = null;
        PreparedStatement updPs = null;
        try {
            updConn = DBConnection.getConnection();
            if (updConn != null) {
                // Name, DOB, Email, Aadhaar and verification documents are locked and cannot be updated
                String sql = "UPDATE mechanics SET " +
                             "gender = ?, " +
                             "phone = ?, shop_contact_number = ?, workshop_name = ?, shop_name = ?, " +
                             "shop_type = ?, specialization = ?, other_specialization = ?, service_types = ?, " +
                             "years_of_experience = ?, opening_time = ?, closing_time = ?, shop_description = ?, " +
                             "address_line_1 = ?, address_line_2 = ?, city = ?, district = ?, state = 'Tamil Nadu', pincode = ?, " +
                             "address = ?, location = ?, latitude = ?, longitude = ? " +
                             "WHERE mechanic_id = ?";
                updPs = updConn.prepareStatement(sql);
                updPs.setString(1, uGender != null ? uGender.trim() : "Male");
                updPs.setString(2, uPhone != null ? uPhone.trim() : "");
                updPs.setString(3, uShopContact != null ? uShopContact.trim() : "");
                updPs.setString(4, uShop != null ? uShop.trim() : "");
                updPs.setString(5, uShop != null ? uShop.trim() : "");
                updPs.setString(6, uShopType != null ? uShopType.trim() : "Multi-brand Garage");
                updPs.setString(7, uSpec != null ? uSpec.trim() : "General Service");
                updPs.setString(8, uOtherSpec != null ? uOtherSpec.trim() : "");
                updPs.setString(9, uServiceTypes);
                updPs.setString(10, uExp != null ? uExp.trim() : "3-5 years");
                updPs.setString(11, uOpen != null ? uOpen.trim() : "09:00 AM");
                updPs.setString(12, uClose != null ? uClose.trim() : "07:00 PM");
                updPs.setString(13, uDesc != null ? uDesc.trim() : "");
                updPs.setString(14, uAddr1 != null ? uAddr1.trim() : "");
                updPs.setString(15, uAddr2 != null ? uAddr2.trim() : "");
                updPs.setString(16, uCity != null ? uCity.trim() : "");
                updPs.setString(17, uDistrict != null ? uDistrict.trim() : "Coimbatore");
                updPs.setString(18, uPincode != null ? uPincode.trim() : "641001");
                updPs.setString(19, uAddress);
                updPs.setString(20, uCity != null ? uCity.trim() : "Coimbatore");
                updPs.setDouble(21, uLat);
                updPs.setDouble(22, uLng);
                updPs.setInt(23, currentMech.getMechanicId());
                updPs.executeUpdate();

                // Handle Newly Uploaded Shop Photos (Base64)
                String[] photoDataArr = request.getParameterValues("newShopPhotoData");
                String[] photoNameArr = request.getParameterValues("newShopPhotoName");
                if (photoDataArr != null && photoNameArr != null) {
                    String uploadDirPath = application.getRealPath("/uploads/mechanic_photos");
                    File uploadDir = new File(uploadDirPath);
                    if (!uploadDir.exists()) uploadDir.mkdirs();

                    for (int i = 0; i < photoDataArr.length; i++) {
                        String data = photoDataArr[i];
                        String origName = (i < photoNameArr.length && photoNameArr[i] != null) ? photoNameArr[i] : "shop_photo.jpg";
                        if (data != null && data.contains("base64,")) {
                            try {
                                String base64Content = data.substring(data.indexOf("base64,") + 7);
                                byte[] bytes = Base64.getDecoder().decode(base64Content);
                                String safeFileName = "shop_" + currentMech.getMechanicId() + "_" + System.currentTimeMillis() + "_" + origName.replaceAll("[^a-zA-Z0-9.-]", "_");
                                File destFile = new File(uploadDir, safeFileName);
                                Files.write(destFile.toPath(), bytes);

                                // Save record in mechanic_shop_photos
                                PreparedStatement psInsPhoto = updConn.prepareStatement("INSERT INTO mechanic_shop_photos (mechanic_id, photo_path, original_filename) VALUES (?, ?, ?)");
                                psInsPhoto.setInt(1, currentMech.getMechanicId());
                                psInsPhoto.setString(2, "/uploads/mechanic_photos/" + safeFileName);
                                psInsPhoto.setString(3, origName);
                                psInsPhoto.executeUpdate();
                                psInsPhoto.close();
                            } catch (Exception exPhoto) {
                                System.err.println("Shop photo save warning: " + exPhoto.getMessage());
                            }
                        }
                    }
                }

                // Handle Deleted Shop Photos
                String deletedPhotosStr = request.getParameter("deletedPhotoIds");
                if (deletedPhotosStr != null && !deletedPhotosStr.trim().isEmpty()) {
                    String[] delIds = deletedPhotosStr.split(",");
                    for (String dId : delIds) {
                        try {
                            int pId = Integer.parseInt(dId.trim());
                            PreparedStatement psDelPhoto = updConn.prepareStatement("DELETE FROM mechanic_shop_photos WHERE photo_id = ? AND mechanic_id = ?");
                            psDelPhoto.setInt(1, pId);
                            psDelPhoto.setInt(2, currentMech.getMechanicId());
                            psDelPhoto.executeUpdate();
                            psDelPhoto.close();
                        } catch (Exception ignoredDel) {}
                    }
                }

                // Update session state
                currentMech.setFirstName(uFirstName);
                currentMech.setLastName(uLastName);
                currentMech.setOwnerName(uOwner);
                currentMech.setWorkshopName(uShop);
                currentMech.setShopName(uShop);
                currentMech.setPhone(uPhone);
                currentMech.setSpecialization(uSpec);
                currentMech.setAddress(uAddress);
                currentMech.setLatitude(uLat);
                currentMech.setLongitude(uLng);
                session.setAttribute("mechanic", currentMech);
                session.setAttribute("mechanicName", uOwner);
                session.setAttribute("mechName", uOwner);
                session.setAttribute("mechWorkshop", uShop);

                response.sendRedirect(request.getContextPath() + "/mechanic/profile.jsp?msg=updated");
                return;
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            if (updPs != null) try { updPs.close(); } catch (Exception ignored) {}
            if (updConn != null) try { updConn.close(); } catch (Exception ignored) {}
        }
    }

    // 3. Load Fresh Profile Data from Database
    int mechId = currentMech.getMechanicId();
    String mechCode = currentMech.getMechanicCode();
    if (mechCode == null || mechCode.trim().isEmpty()) mechCode = "MEC002";

    String firstName = currentMech.getFirstName() != null ? currentMech.getFirstName() : "Sathish";
    String lastName = currentMech.getLastName() != null ? currentMech.getLastName() : "K";
    String ownerName = "Sathish K";
    String gender = "Male";
    String dob = "1995-06-15";
    String workshopName = "Sathish Multi-brand Garage";
    String shopType = "Multi-brand Garage";
    String email = currentMech.getEmail() != null ? currentMech.getEmail() : "sathish@gmail.com";
    String phone = "9876543210";
    String shopContact = "6383112061";
    String specialization = "Electrical Repair";
    String otherSpecialization = "AC Service, Radiator Repair";
    String serviceTypes = "Engine Repair, Battery Service, Tyre / Puncture, Electrical Repair, AC Service";
    String experience = "1 - 3 years";
    String openingTime = "09:00 AM";
    String closingTime = "07:00 PM";
    String addressLine1 = "No. 12, Nsr main road,";
    String addressLine2 = "Saibaba Colony,";
    String city = "Coimbatore";
    String district = "Coimbatore";
    String state = "Tamil Nadu";
    String pincode = "641001";
    String address = "No. 12, Nsr main road,, Saibaba Colony,, Coimbatore";
    double latitude = 11.0285;
    double longitude = 76.9490;
    String description = "Expert Multi-brand Car & Bike Assistance with Mobile Units";
    String approvalStatus = "Approved";
    double ratingVal = 4.9;
    int reviewsCount = 156;
    String profileImg = "find-mech-sathish.jpg";
    String aadhaarNumber = "";
    String aadhaarCardDoc = "";
    String idProofDoc = "";

    List<Map<String, String>> shopPhotosList = new ArrayList<Map<String, String>>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DBConnection.getConnection();
        if (conn != null) {
            ps = conn.prepareStatement("SELECT * FROM mechanics WHERE mechanic_id = ?");
            ps.setInt(1, mechId);
            rs = ps.executeQuery();
            if (rs.next()) {
                if (rs.getString("mechanic_code") != null) mechCode = rs.getString("mechanic_code");
                if (rs.getString("first_name") != null) firstName = rs.getString("first_name");
                if (rs.getString("last_name") != null) lastName = rs.getString("last_name");
                if (rs.getString("owner_name") != null) ownerName = rs.getString("owner_name");
                if (rs.getString("gender") != null) gender = rs.getString("gender");
                if (rs.getString("dob") != null) dob = rs.getString("dob");
                if (rs.getString("workshop_name") != null) workshopName = rs.getString("workshop_name");
                if (rs.getString("shop_type") != null) shopType = rs.getString("shop_type");
                if (rs.getString("email") != null) email = rs.getString("email");
                if (rs.getString("phone") != null) phone = rs.getString("phone");
                if (rs.getString("shop_contact_number") != null) shopContact = rs.getString("shop_contact_number");
                if (rs.getString("aadhaar_number") != null) aadhaarNumber = rs.getString("aadhaar_number");
                if (rs.getString("aadhaar_card_doc") != null) aadhaarCardDoc = rs.getString("aadhaar_card_doc");
                if (rs.getString("id_proof_doc") != null) idProofDoc = rs.getString("id_proof_doc");
                if (rs.getString("specialization") != null) specialization = rs.getString("specialization");
                if (rs.getString("other_specialization") != null) otherSpecialization = rs.getString("other_specialization");
                if (rs.getString("service_types") != null) serviceTypes = rs.getString("service_types");
                if (rs.getString("years_of_experience") != null) experience = rs.getString("years_of_experience");
                if (rs.getString("opening_time") != null) openingTime = rs.getString("opening_time");
                if (rs.getString("closing_time") != null) closingTime = rs.getString("closing_time");
                if (rs.getString("address_line_1") != null) addressLine1 = rs.getString("address_line_1");
                if (rs.getString("address_line_2") != null) addressLine2 = rs.getString("address_line_2");
                if (rs.getString("city") != null) city = rs.getString("city");
                if (rs.getString("district") != null) district = rs.getString("district");
                if (rs.getString("state") != null) state = rs.getString("state");
                if (rs.getString("pincode") != null) pincode = rs.getString("pincode");
                if (rs.getString("address") != null) address = rs.getString("address");
                if (rs.getDouble("latitude") != 0.0) latitude = rs.getDouble("latitude");
                if (rs.getDouble("longitude") != 0.0) longitude = rs.getDouble("longitude");
                if (rs.getString("shop_description") != null) description = rs.getString("shop_description");
                if (rs.getString("approval_status") != null) approvalStatus = rs.getString("approval_status");
                if (rs.getDouble("rating") > 0) ratingVal = rs.getDouble("rating");
                if (rs.getInt("reviews_count") > 0) reviewsCount = rs.getInt("reviews_count");
                if (rs.getString("profile_image") != null && !rs.getString("profile_image").trim().isEmpty()) {
                    profileImg = rs.getString("profile_image");
                }
            }
            rs.close();
            ps.close();

            // Load Shop Photos from mechanic_shop_photos
            ps = conn.prepareStatement("SELECT photo_id, photo_path, original_filename, uploaded_at FROM mechanic_shop_photos WHERE mechanic_id = ? ORDER BY uploaded_at ASC");
            ps.setInt(1, mechId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, String> photo = new HashMap<String, String>();
                photo.put("id", String.valueOf(rs.getInt("photo_id")));
                photo.put("path", rs.getString("photo_path"));
                photo.put("name", rs.getString("original_filename"));
                shopPhotosList.add(photo);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    // Format DOB for View Mode as dd-MM-yyyy e.g. "15-06-1995"
    String formattedDob = dob;
    try {
        if (dob != null && !dob.trim().isEmpty()) {
            SimpleDateFormat dbFmt = new SimpleDateFormat("yyyy-MM-dd");
            Date d = dbFmt.parse(dob.trim());
            SimpleDateFormat outFmt = new SimpleDateFormat("dd-MM-yyyy");
            formattedDob = outFmt.format(d);
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Workshop Profile — Mechanic Portal</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Leaflet CSS for Interactive Location Map -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>

    <!-- Base Layout & Shell Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">

    <!-- Dedicated Mechanic Profile Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-profile.css?v=3.0">
</head>
<body>

    <!-- 1. Top Navigation Bar (Dark Charcoal, Logo, Hamburger, Notifications, Avatar) -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Left Sidebar + Main White Canvas -->
    <div class="mech-dashboard-shell">

        <!-- Fixed Left Sidebar with Automotive Sunset Road Background Image -->
        <jsp:include page="sidebar.jsp" />

        <!-- Main Content White Canvas -->
        <main class="mech-main-canvas">

            <!-- Page Header -->
            <div class="mech-profile-header">
                <div class="mech-profile-title-col">
                    <h1 class="mech-profile-heading">Workshop <span class="highlight">Profile</span></h1>
                    <p class="mech-profile-subheading">Garage verification details, service capabilities, contact credentials and workshop details</p>
                </div>
                <div class="mech-date-card">
                    <i class="fa-regular fa-calendar-days"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <!-- Update Success Alert -->
            <% if ("updated".equals(updateStatus)) { %>
                <div class="profile-alert-success">
                    <i class="fa-solid fa-circle-check"></i>
                    <span>Workshop profile details have been saved and updated successfully!</span>
                </div>
            <% } %>

            <!-- Hero Overview Card with View & Edit Switch -->
            <div class="profile-hero-card">
                <div class="profile-hero-left">
                    <div class="profile-avatar-wrap" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 3px solid #F97316; color: #F97316; font-size: 34px;">
                        <i class="fa-solid fa-wrench"></i>
                    </div>
                    <div class="profile-hero-info">
                        <h2 class="profile-hero-name">
                            <span><%= workshopName %></span>
                            <span class="badge-verified-partner">
                                <i class="fa-solid fa-shield-halved"></i> <%= approvalStatus %>
                            </span>
                        </h2>
                        <p class="profile-hero-sub">Proprietor: <%= ownerName %> • Primary Contact: <%= phone %></p>
                        <div class="profile-hero-meta">
                            <span class="meta-pill pill-code">
                                <i class="fa-solid fa-hashtag"></i> <%= mechCode %>
                            </span>
                            <span class="meta-pill pill-rating">
                                <i class="fa-solid fa-star"></i> <%= String.format(java.util.Locale.US, "%.1f", ratingVal) %> (<%= reviewsCount %> Reviews)
                            </span>
                            <span class="meta-pill pill-specialization">
                                <i class="fa-solid fa-toolbox"></i> <%= specialization %>
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Prominent Edit Profile Button in Hero -->
                <div class="profile-hero-actions">
                    <button type="button" id="btnEnableEdit" class="btn-hero-edit-profile" onclick="toggleEditMode(true)">
                        <i class="fa-solid fa-pen-to-square"></i>
                        <span>Edit Profile</span>
                    </button>
                </div>
            </div>

            <!-- ===================================================================
                 1. VIEW MODE (DEFAULT: READ-ONLY INFORMATION CARDS)
                 =================================================================== -->
            <div id="profileViewContainer" class="profile-view-wrapper">

                <!-- Section 1: Personal & Contact Credentials -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-solid fa-user-shield"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Personal & Contact Credentials</h3>
                                <p class="view-card-desc">Primary owner details and verified communication channels</p>
                            </div>
                        </div>
                    </div>

                    <div class="view-kv-grid">
                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-user"></i> Full Name</span>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span class="view-kv-value"><%= firstName %> <%= lastName %></span>
                                <span class="badge-verified-partner" style="font-size: 10.5px; padding: 2px 7px;"><i class="fa-solid fa-lock"></i> Locked</span>
                            </div>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-venus-mars"></i> Gender</span>
                            <span class="view-kv-value"><%= gender %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-cake-candles"></i> Date of Birth</span>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span class="view-kv-value"><%= formattedDob %></span>
                                <span class="badge-verified-partner" style="font-size: 10.5px; padding: 2px 7px;"><i class="fa-solid fa-lock"></i> Locked</span>
                            </div>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-phone"></i> Primary Mobile Number</span>
                            <span class="view-kv-value highlight"><%= phone %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-phone-volume"></i> Workshop Landline / Alternate</span>
                            <span class="view-kv-value"><%= (shopContact != null && !shopContact.trim().isEmpty()) ? shopContact : "Not provided" %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-envelope"></i> Registered Email</span>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span class="view-kv-value"><%= email %></span>
                                <span class="badge-verified-partner" style="font-size: 10.5px; padding: 2px 7px;"><i class="fa-solid fa-lock"></i> Verified (Locked)</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Section: Verification & Legal Identity Documents (View Mode) -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-solid fa-id-card"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Verification & Identity Documents</h3>
                                <p class="view-card-desc">Government identity proof and Aadhaar verification credentials</p>
                            </div>
                        </div>
                        <span class="badge-verified-partner" style="font-size: 11px; padding: 4px 10px;">
                            <i class="fa-solid fa-shield-check"></i> Government Verified
                        </span>
                    </div>

                    <div class="view-kv-grid">
                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-fingerprint"></i> Aadhaar Number</span>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span class="view-kv-value highlight" style="font-family: monospace; letter-spacing: 1.2px; font-weight: 700;">
                                    <%= (!aadhaarNumber.isEmpty()) ? aadhaarNumber.replaceAll("(\\d{4})(?=\\d)", "$1 ") : "5482 9184 7291" %>
                                </span>
                                <span class="badge-verified-partner" style="font-size: 10.5px; padding: 2px 7px;"><i class="fa-solid fa-lock"></i> Locked</span>
                            </div>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-file-shield"></i> Document Verification Status</span>
                            <span class="view-kv-badge" style="background:#ECFDF5; color:#059669; border:1px solid #A7F3D0;"><i class="fa-solid fa-circle-check"></i> Verified & Approved</span>
                        </div>

                        <div class="view-kv-item" style="grid-column: 1 / -1;">
                            <span class="view-kv-label"><i class="fa-solid fa-paperclip"></i> Uploaded Verification Documents (View-Only / Non-Editable)</span>
                            <div style="display: flex; gap: 16px; flex-wrap: wrap; margin-top: 8px;">
                                <% 
                                    String aDocPath = (!aadhaarCardDoc.isEmpty()) ? ((aadhaarCardDoc.startsWith("/") || aadhaarCardDoc.startsWith("http")) ? (request.getContextPath() + aadhaarCardDoc) : (request.getContextPath() + "/uploads/mechanic_documents/" + aadhaarCardDoc)) : (request.getContextPath() + "/uploads/mechanic_documents/sample_aadhaar_card.png");
                                    String idDocPath = (!idProofDoc.isEmpty()) ? ((idProofDoc.startsWith("/") || idProofDoc.startsWith("http")) ? (request.getContextPath() + idProofDoc) : (request.getContextPath() + "/uploads/mechanic_documents/" + idProofDoc)) : (request.getContextPath() + "/uploads/mechanic_documents/sample_id_proof.png");
                                %>
                                <!-- Aadhaar Card Document Preview -->
                                <div style="display: flex; align-items: center; gap: 12px; padding: 12px 18px; background: #F8FAFC; border: 1.5px solid #E2E8F0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" onclick="openPhotoModal('<%= aDocPath %>', 'Aadhaar Card Document')" title="Click to inspect document">
                                    <div style="width: 44px; height: 44px; border-radius: 10px; background: rgba(249,115,22,0.1); color: #F97316; display: flex; align-items: center; justify-content: center; font-size: 20px;">
                                        <i class="fa-solid fa-address-card"></i>
                                    </div>
                                    <div>
                                        <div style="font-size: 13.5px; font-weight: 700; color: #1E293B;">Aadhaar Card Document</div>
                                        <div style="font-size: 11.5px; color: #64748B;"><i class="fa-solid fa-lock"></i> Verified Document (Locked) • Click to view</div>
                                    </div>
                                    <i class="fa-solid fa-arrow-up-right-from-square" style="color: #94A3B8; margin-left: 10px; font-size: 13px;"></i>
                                </div>

                                <!-- ID Proof Document Preview -->
                                <div style="display: flex; align-items: center; gap: 12px; padding: 12px 18px; background: #F8FAFC; border: 1.5px solid #E2E8F0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" onclick="openPhotoModal('<%= idDocPath %>', 'Government ID Proof Document')" title="Click to inspect document">
                                    <div style="width: 44px; height: 44px; border-radius: 10px; background: rgba(249,115,22,0.1); color: #F97316; display: flex; align-items: center; justify-content: center; font-size: 20px;">
                                        <i class="fa-solid fa-id-badge"></i>
                                    </div>
                                    <div>
                                        <div style="font-size: 13.5px; font-weight: 700; color: #1E293B;">Government ID Proof</div>
                                        <div style="font-size: 11.5px; color: #64748B;"><i class="fa-solid fa-lock"></i> Verified Document (Locked) • Click to view</div>
                                    </div>
                                    <i class="fa-solid fa-arrow-up-right-from-square" style="color: #94A3B8; margin-left: 10px; font-size: 13px;"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Section 2: Work Specialization & Experience -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-solid fa-screwdriver-wrench"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Work Specialization & Experience</h3>
                                <p class="view-card-desc">Vehicle categories, technical service specialties and experience</p>
                            </div>
                        </div>
                    </div>

                    <div class="view-kv-grid">
                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-award"></i> Industry Experience</span>
                            <span class="view-kv-badge"><%= experience %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-gears"></i> Primary Specialization</span>
                            <span class="view-kv-value highlight"><%= specialization %></span>
                        </div>

                        <div class="view-kv-item" style="grid-column: 1 / -1;">
                            <span class="view-kv-label"><i class="fa-solid fa-toolbox"></i> Services Handled & Assistance Offerings</span>
                            <div class="service-tags-wrap">
                                <% 
                                    if (serviceTypes != null && !serviceTypes.trim().isEmpty()) {
                                        String[] sArr = serviceTypes.split(",");
                                        for (String s : sArr) {
                                            String trimmedS = s.trim();
                                            if (!trimmedS.isEmpty()) {
                                %>
                                    <span class="service-tag-chip">
                                        <i class="fa-solid fa-check"></i> <%= trimmedS %>
                                    </span>
                                <% 
                                            }
                                        }
                                    } else { 
                                %>
                                    <span class="service-tag-chip"><i class="fa-solid fa-check"></i> General Service</span>
                                <% } %>
                            </div>
                        </div>

                        <% if (otherSpecialization != null && !otherSpecialization.trim().isEmpty()) { %>
                            <div class="view-kv-item" style="grid-column: 1 / -1;">
                                <span class="view-kv-label"><i class="fa-solid fa-plus-circle"></i> Other Specializations</span>
                                <span class="view-kv-value"><%= otherSpecialization %></span>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Section 3: Workshop Details -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-solid fa-store"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Workshop Details</h3>
                                <p class="view-card-desc">Garage name, service center type and service overview</p>
                            </div>
                        </div>
                    </div>

                    <div class="view-kv-grid">
                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-warehouse"></i> Workshop Name</span>
                            <span class="view-kv-value highlight"><%= workshopName %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-shop"></i> Workshop Type</span>
                            <span class="view-kv-badge"><%= shopType %></span>
                        </div>

                        <div class="view-kv-item" style="grid-column: 1 / -1;">
                            <span class="view-kv-label"><i class="fa-solid fa-align-left"></i> Workshop Services Description</span>
                            <p style="margin: 4px 0 0 0; font-size: 14px; color: #334155; line-height: 1.5; font-weight: 500;"><%= description %></p>
                        </div>
                    </div>
                </div>

                <!-- Section 4: Workshop Photos (Shop Images) -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-regular fa-images"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Shop Images</h3>
                                <p class="view-card-desc">Uploaded workshop photos for motorist trust and verification</p>
                            </div>
                        </div>
                        <span class="meta-pill pill-code">
                            <i class="fa-solid fa-camera"></i> <%= shopPhotosList.size() %> <%= shopPhotosList.size() == 1 ? "Photo" : "Photos" %>
                        </span>
                    </div>

                    <% if (!shopPhotosList.isEmpty()) { %>
                        <div class="view-shop-photos-grid">
                            <% for (Map<String, String> photo : shopPhotosList) { 
                                String pPath = photo.get("path");
                                String pName = photo.get("name") != null ? photo.get("name") : "Workshop Photo";
                                String fullSrc = (pPath.startsWith("/") || pPath.startsWith("http")) ? (request.getContextPath() + pPath) : (request.getContextPath() + "/images/" + pPath);
                            %>
                                <div class="view-shop-photo-card" onclick="openPhotoModal('<%= fullSrc %>', '<%= pName %>')" title="Click to view full image">
                                    <img src="<%= fullSrc %>" alt="<%= pName %>" class="view-shop-photo-img" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/mechanic-workshop-sample.jpg';">
                                    <div class="view-shop-photo-overlay">
                                        <span><%= pName %></span>
                                        <i class="fa-solid fa-magnifying-glass-plus"></i>
                                    </div>
                                </div>
                            <% } %>
                        </div>
                    <% } else { %>
                        <!-- Clean Empty State if no photos uploaded -->
                        <div class="empty-shop-photos-box">
                            <div class="empty-photos-icon-wrap">
                                <i class="fa-regular fa-images"></i>
                            </div>
                            <h4 class="empty-photos-title">No Workshop Photos Uploaded</h4>
                            <p class="empty-photos-desc">No workshop photos have been uploaded for your garage yet. Click "Edit Profile" to add photos of your garage.</p>
                        </div>
                    <% } %>
                </div>

                <!-- Section 5: Workshop Address & Location (View Map) -->
                <div class="profile-view-card">
                    <div class="view-card-header">
                        <div class="view-card-header-left">
                            <div class="view-card-icon">
                                <i class="fa-solid fa-location-dot"></i>
                            </div>
                            <div>
                                <h3 class="view-card-title">Garage Location & Address</h3>
                                <p class="view-card-desc">Physical address where motorists can reach your garage</p>
                            </div>
                        </div>
                        <div class="map-coords-badge">
                            <i class="fa-solid fa-location-crosshairs"></i>
                            <span><%= String.format(java.util.Locale.US, "%.4f", latitude) %>° N, <%= String.format(java.util.Locale.US, "%.4f", longitude) %>° E</span>
                        </div>
                    </div>

                    <div class="view-kv-grid" style="margin-bottom: 20px;">
                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-road"></i> Address Line 1</span>
                            <span class="view-kv-value"><%= addressLine1 %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-signs-post"></i> Address Line 2</span>
                            <span class="view-kv-value"><%= (addressLine2 != null && !addressLine2.trim().isEmpty()) ? addressLine2 : "—" %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-city"></i> City / Town</span>
                            <span class="view-kv-value"><%= city %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-map-pin"></i> District</span>
                            <span class="view-kv-value"><%= district %></span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-map"></i> State</span>
                            <span class="view-kv-value">Tamil Nadu</span>
                        </div>

                        <div class="view-kv-item">
                            <span class="view-kv-label"><i class="fa-solid fa-envelopes-bulk"></i> Pincode</span>
                            <span class="view-kv-value highlight"><%= pincode %></span>
                        </div>
                    </div>

                    <!-- Pinned Location Leaflet Mini-Map -->
                    <div class="profile-map-wrapper">
                        <div class="profile-map-canvas-container" style="height: 320px;">
                            <div id="viewGarageMap" style="width: 100%; height: 320px;"></div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- ===================================================================
                 2. EDIT MODE (SHOWN ONLY WHEN "EDIT PROFILE" BUTTON IS CLICKED)
                 =================================================================== -->
            <div id="profileEditContainer" class="profile-edit-wrapper" style="display: none;">

                <!-- Notice Banner -->
                <div class="profile-edit-banner">
                    <div class="profile-edit-banner-left">
                        <i class="fa-solid fa-pen-to-square"></i>
                        <span>Editing Workshop Profile — update any information below with valid details and click "Save Profile Changes".</span>
                    </div>
                    <button type="button" class="btn-profile-cancel" onclick="toggleEditMode(false)" style="padding: 6px 14px; font-size: 12.5px;">
                        <i class="fa-solid fa-xmark"></i> Cancel Edit
                    </button>
                </div>

                <!-- Interactive Profile Edit Form -->
                <form action="${pageContext.request.contextPath}/mechanic/profile.jsp" method="POST" id="profileEditForm" class="profile-form-container" novalidate>

                    <!-- Section 1: Personal & Contact Credentials (Registration Matching) -->
                    <div class="profile-section-card">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-solid fa-user-shield"></i>
                            </div>
                            <div>
                                <h3 class="section-card-title">Step 1: Personal & Account Details</h3>
                                <p class="section-card-desc">Mechanic owner credentials matching registration fields</p>
                            </div>
                        </div>

                        <div class="profile-fields-grid">
                            <!-- First Name (Locked) -->
                            <div class="field-group">
                                <label class="field-label" for="editFirstName" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-user"></i> First Name</span>
                                    <span style="font-size:11px; font-weight:700; color:#64748B; background:#E2E8F0; padding:2px 8px; border-radius:12px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <input type="text" id="editFirstName" name="firstName" class="field-input" value="<%= firstName %>" readonly title="First Name is verified and locked" style="background:#F1F5F9; color:#64748B; cursor:not-allowed; border-color:#CBD5E1;">
                                <span style="font-size:11.5px; color:#64748B; margin-top:4px; display:block;"><i class="fa-solid fa-circle-info"></i> Legal identity name verified at registration.</span>
                            </div>

                            <!-- Last Name (Locked) -->
                            <div class="field-group">
                                <label class="field-label" for="editLastName" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-user"></i> Last Name</span>
                                    <span style="font-size:11px; font-weight:700; color:#64748B; background:#E2E8F0; padding:2px 8px; border-radius:12px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <input type="text" id="editLastName" name="lastName" class="field-input" value="<%= lastName %>" readonly title="Last Name is verified and locked" style="background:#F1F5F9; color:#64748B; cursor:not-allowed; border-color:#CBD5E1;">
                                <span style="font-size:11.5px; color:#64748B; margin-top:4px; display:block;"><i class="fa-solid fa-circle-info"></i> Legal identity name verified at registration.</span>
                            </div>

                            <!-- Gender -->
                            <div class="field-group">
                                <label class="field-label" for="editGender">
                                    <i class="fa-solid fa-venus-mars"></i> Gender <span style="color:#EF4444;">*</span>
                                </label>
                                <select id="editGender" name="gender" class="field-select" required>
                                    <option value="Male" <%= "Male".equalsIgnoreCase(gender) ? "selected" : "" %>>Male</option>
                                    <option value="Female" <%= "Female".equalsIgnoreCase(gender) ? "selected" : "" %>>Female</option>
                                    <option value="Other" <%= "Other".equalsIgnoreCase(gender) ? "selected" : "" %>>Other</option>
                                    <option value="Prefer not to say" <%= "Prefer not to say".equalsIgnoreCase(gender) ? "selected" : "" %>>Prefer not to say</option>
                                </select>
                                <div id="genderInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Please select your gender.</span></div>
                            </div>

                            <!-- Date of Birth (Locked) -->
                            <div class="field-group">
                                <label class="field-label" for="editDob" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-cake-candles"></i> Date of Birth</span>
                                    <span style="font-size:11px; font-weight:700; color:#64748B; background:#E2E8F0; padding:2px 8px; border-radius:12px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <input type="text" id="editDob" name="dob" class="field-input" value="<%= formattedDob %>" readonly title="Date of Birth is verified and locked" style="background:#F1F5F9; color:#64748B; cursor:not-allowed; border-color:#CBD5E1;">
                                <span style="font-size:11.5px; color:#64748B; margin-top:4px; display:block;"><i class="fa-solid fa-circle-info"></i> Date of birth is verified and cannot be edited.</span>
                            </div>

                            <!-- Primary Mobile Number -->
                            <div class="field-group">
                                <label class="field-label" for="editPhone">
                                    <i class="fa-solid fa-phone"></i> Primary Mobile Number <span style="color:#EF4444;">*</span>
                                </label>
                                <input type="tel" id="editPhone" name="phone" class="field-input" value="<%= phone %>" maxlength="10" placeholder="10-digit mobile number" required>
                                <div id="phoneInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Enter a valid 10-digit mobile number starting with 6–9.</span></div>
                            </div>

                            <!-- Registered Email (Locked) -->
                            <div class="field-group">
                                <label class="field-label" for="editEmail" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-envelope"></i> Registered Email</span>
                                    <span style="font-size:11px; font-weight:700; color:#64748B; background:#E2E8F0; padding:2px 8px; border-radius:12px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <input type="email" id="editEmail" class="field-input" value="<%= email %>" readonly title="Email is verified and cannot be edited" style="background:#F1F5F9; color:#64748B; cursor:not-allowed; border-color:#CBD5E1;">
                                <span style="font-size:11.5px; color:#64748B; margin-top:4px; display:block;"><i class="fa-solid fa-circle-info"></i> Verified email address cannot be changed.</span>
                            </div>
                        </div>
                    </div>

                    <!-- Section: Verification & Identity Documents (Locked / Non-Editable) -->
                    <div class="profile-section-card">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-solid fa-id-card"></i>
                            </div>
                            <div style="flex: 1;">
                                <h3 class="section-card-title">Government Identity & Verification Documents</h3>
                                <p class="section-card-desc">Uploaded government identity proof and Aadhaar details are permanently verified and non-editable</p>
                            </div>
                            <span style="font-size: 11px; font-weight: 700; color: #64748B; background: #E2E8F0; padding: 4px 10px; border-radius: 12px;">
                                <i class="fa-solid fa-lock"></i> Non-Editable
                            </span>
                        </div>

                        <div class="profile-fields-grid">
                            <!-- Aadhaar Number (Locked) -->
                            <div class="field-group">
                                <label class="field-label" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-fingerprint"></i> Aadhaar Number</span>
                                    <span style="font-size: 10.5px; font-weight: 700; color: #64748B; background: #E2E8F0; padding: 2px 7px; border-radius: 10px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <input type="text" class="field-input" value="<%= (!aadhaarNumber.isEmpty()) ? aadhaarNumber.replaceAll("(\\d{4})(?=\\d)", "$1 ") : "5482 9184 7291" %>" readonly style="background:#F1F5F9; color:#64748B; cursor:not-allowed; font-family: monospace; letter-spacing: 1px; font-weight: 700; border-color: #CBD5E1;">
                                <span style="font-size: 11.5px; color: #64748B; margin-top: 4px; display: block;"><i class="fa-solid fa-circle-check" style="color:#10B981;"></i> 12-digit Aadhaar verified at registration.</span>
                            </div>

                            <!-- Document Verification Status -->
                            <div class="field-group">
                                <label class="field-label">
                                    <i class="fa-solid fa-shield-check"></i> Verification Status
                                </label>
                                <div style="height: 44px; display: flex; align-items: center; padding: 0 14px; background: #ECFDF5; border: 1.5px solid #A7F3D0; border-radius: 8px; color: #065F46; font-size: 13.5px; font-weight: 700; gap: 8px;">
                                    <i class="fa-solid fa-circle-check" style="color: #10B981;"></i>
                                    <span>Aadhaar & ID Proof Approved by Admin</span>
                                </div>
                                <span style="font-size: 11.5px; color: #64748B; margin-top: 4px; display: block;"><i class="fa-solid fa-lock"></i> Documents cannot be modified by mechanic.</span>
                            </div>

                            <!-- Uploaded Documents (Readonly view) -->
                            <div class="field-col-full field-group">
                                <label class="field-label" style="display:flex; justify-content:space-between; align-items:center;">
                                    <span><i class="fa-solid fa-paperclip"></i> Verified Identity Documents</span>
                                    <span style="font-size: 10.5px; font-weight: 700; color: #64748B; background: #E2E8F0; padding: 2px 7px; border-radius: 10px;"><i class="fa-solid fa-lock"></i> Locked</span>
                                </label>
                                <div style="display: flex; gap: 14px; flex-wrap: wrap; margin-top: 4px;">
                                    <!-- Aadhaar Document Card -->
                                    <div style="display: flex; align-items: center; gap: 12px; padding: 12px 18px; background: #F1F5F9; border: 1.5px solid #CBD5E1; border-radius: 10px; cursor: pointer; transition: all 0.2s;" onclick="openPhotoModal('<%= aDocPath %>', 'Aadhaar Card Document')" title="Click to view full document">
                                        <div style="width: 40px; height: 40px; border-radius: 8px; background: #E2E8F0; color: #64748B; display: flex; align-items: center; justify-content: center; font-size: 18px;">
                                            <i class="fa-solid fa-address-card"></i>
                                        </div>
                                        <div>
                                            <div style="font-size: 13px; font-weight: 700; color: #334155;">Aadhaar Card Document</div>
                                            <div style="font-size: 11.5px; color: #64748B;"><i class="fa-solid fa-lock"></i> Non-Editable • Click to inspect</div>
                                        </div>
                                        <i class="fa-solid fa-eye" style="color: #64748B; margin-left: 8px;"></i>
                                    </div>

                                    <!-- ID Proof Document Card -->
                                    <div style="display: flex; align-items: center; gap: 12px; padding: 12px 18px; background: #F1F5F9; border: 1.5px solid #CBD5E1; border-radius: 10px; cursor: pointer; transition: all 0.2s;" onclick="openPhotoModal('<%= idDocPath %>', 'Government ID Proof Document')" title="Click to view full document">
                                        <div style="width: 40px; height: 40px; border-radius: 8px; background: #E2E8F0; color: #64748B; display: flex; align-items: center; justify-content: center; font-size: 18px;">
                                            <i class="fa-solid fa-id-badge"></i>
                                        </div>
                                        <div>
                                            <div style="font-size: 13px; font-weight: 700; color: #334155;">Government ID Proof</div>
                                            <div style="font-size: 11.5px; color: #64748B;"><i class="fa-solid fa-lock"></i> Non-Editable • Click to inspect</div>
                                        </div>
                                        <i class="fa-solid fa-eye" style="color: #64748B; margin-left: 8px;"></i>
                                    </div>
                                </div>
                                <div style="margin-top: 10px; padding: 8px 14px; background: #FFFBEB; border: 1px solid #FDE68A; border-radius: 8px; color: #92400E; font-size: 12px; display: flex; align-items: center; gap: 8px;">
                                    <i class="fa-solid fa-triangle-exclamation"></i>
                                    <span>Government identity records (Name, Date of Birth, Email, and Aadhaar documents) were authenticated during registration and cannot be modified.</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Section 2: Work Specialization & Experience (Registration Matching) -->
                    <div class="profile-section-card">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-solid fa-screwdriver-wrench"></i>
                            </div>
                            <div>
                                <h3 class="section-card-title">Step 2: Work Specialization & Experience</h3>
                                <p class="section-card-desc">Specialization, service capabilities and industry experience</p>
                            </div>
                        </div>

                        <div class="profile-fields-grid">
                            <!-- Primary Specialization -->
                            <div class="field-group">
                                <label class="field-label" for="editSpecialization">
                                    <i class="fa-solid fa-gears"></i> Primary Specialization <span style="color:#EF4444;">*</span>
                                </label>
                                <select id="editSpecialization" name="specialization" class="field-select" required>
                                    <option value="General Service" <%= "General Service".equalsIgnoreCase(specialization) ? "selected" : "" %>>General Service (Car & Bike)</option>
                                    <option value="Engine Repair" <%= specialization.contains("Engine") ? "selected" : "" %>>Engine Repair & Diagnostics</option>
                                    <option value="Electrical Repair" <%= specialization.contains("Electrical") ? "selected" : "" %>>Electrical & Battery Service</option>
                                    <option value="Tyre & Wheel" <%= specialization.contains("Tyre") || specialization.contains("Puncture") ? "selected" : "" %>>Tyre & Puncture Assistance</option>
                                    <option value="Brake & Clutch" <%= specialization.contains("Brake") || specialization.contains("Clutch") ? "selected" : "" %>>Brake & Clutch Specialist</option>
                                    <option value="AC Service" <%= specialization.contains("AC") ? "selected" : "" %>>AC Service & Cooling Repair</option>
                                </select>
                            </div>

                            <!-- Industry Experience -->
                            <div class="field-group">
                                <label class="field-label" for="editExperience">
                                    <i class="fa-solid fa-award"></i> Industry Experience <span style="color:#EF4444;">*</span>
                                </label>
                                <select id="editExperience" name="yearsOfExperience" class="field-select" required>
                                    <option value="Less than 1 year" <%= experience.contains("Less") ? "selected" : "" %>>Less than 1 year</option>
                                    <option value="1 - 3 years" <%= experience.contains("1 - 3") || experience.contains("1–2") ? "selected" : "" %>>1 - 3 years</option>
                                    <option value="3 - 5 years" <%= experience.contains("3 - 5") || experience.contains("3-5") || experience.contains("3–5") ? "selected" : "" %>>3 - 5 years</option>
                                    <option value="5 - 10 years" <%= experience.contains("5 - 10") || experience.contains("6–10") ? "selected" : "" %>>5 - 10 years</option>
                                    <option value="10+ years" <%= experience.contains("10+") || experience.contains("11–15") || experience.contains("More") ? "selected" : "" %>>10+ years</option>
                                </select>
                            </div>

                            <!-- Services Checkboxes -->
                            <div class="field-col-full field-group">
                                <label class="field-label">
                                    <i class="fa-solid fa-toolbox"></i> Services Handled (Select all that apply) <span style="color:#EF4444;">*</span>
                                </label>
                                <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; margin-top: 6px;">
                                    <% 
                                        String[] allServices = new String[] {
                                            "Engine Repair", "Battery Service", "Tyre / Puncture", "Electrical Repair", 
                                            "AC Service", "General Service", "Brake & Clutch", "Towing Assistance", 
                                            "Oil Change", "Suspension Work"
                                        };
                                        for (String sName : allServices) {
                                            boolean isChecked = (serviceTypes != null && serviceTypes.contains(sName));
                                    %>
                                        <label style="display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 600; color: #1E293B; cursor: pointer; background: #F8FAFC; border: 1px solid #CBD5E1; padding: 8px 12px; border-radius: 8px;">
                                            <input type="checkbox" name="serviceTypes" value="<%= sName %>" class="service-checkbox" <%= isChecked ? "checked" : "" %>>
                                            <span><%= sName %></span>
                                        </label>
                                    <% } %>
                                </div>
                                <div id="servicesInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Please select at least one service offering.</span></div>
                            </div>

                            <!-- Other Specialization -->
                            <div class="field-col-full field-group">
                                <label class="field-label" for="editOtherSpec">
                                    <i class="fa-solid fa-plus-circle"></i> Other Specializations (Optional)
                                </label>
                                <input type="text" id="editOtherSpec" name="otherSpecialization" class="field-input" value="<%= otherSpecialization %>" placeholder="e.g. Radiator Repair, Custom Tuning, Car Detailing">
                            </div>
                        </div>
                    </div>

                    <!-- Section 3: Workshop Details (Registration Matching) -->
                    <div class="profile-section-card">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-solid fa-store"></i>
                            </div>
                            <div>
                                <h3 class="section-card-title">Step 3: Workshop Details</h3>
                                <p class="section-card-desc">Workshop name, type, and contact landline</p>
                            </div>
                        </div>

                        <div class="profile-fields-grid">
                            <!-- Workshop Name -->
                            <div class="field-group">
                                <label class="field-label" for="editWorkshopName">
                                    <i class="fa-solid fa-warehouse"></i> Workshop / Garage Name <span style="color:#EF4444;">*</span>
                                </label>
                                <input type="text" id="editWorkshopName" name="workshopName" class="field-input" value="<%= workshopName %>" placeholder="Enter workshop name" required>
                                <div id="shopNameInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Workshop name must be at least 3 characters.</span></div>
                            </div>

                            <!-- Workshop Type -->
                            <div class="field-group">
                                <label class="field-label" for="editShopType">
                                    <i class="fa-solid fa-shop"></i> Workshop Type <span style="color:#EF4444;">*</span>
                                </label>
                                <select id="editShopType" name="shopType" class="field-select" required>
                                    <option value="Multi-brand Garage" <%= "Multi-brand Garage".equalsIgnoreCase(shopType) ? "selected" : "" %>>Multi-brand Garage</option>
                                    <option value="Independent Workshop" <%= "Independent Workshop".equalsIgnoreCase(shopType) ? "selected" : "" %>>Independent Workshop</option>
                                    <option value="Authorized Service Center" <%= "Authorized Service Center".equalsIgnoreCase(shopType) ? "selected" : "" %>>Authorized Service Center</option>
                                    <option value="Four Wheeler Service" <%= "Four Wheeler Service".equalsIgnoreCase(shopType) ? "selected" : "" %>>Four Wheeler Service</option>
                                    <option value="Two Wheeler Service" <%= "Two Wheeler Service".equalsIgnoreCase(shopType) ? "selected" : "" %>>Two Wheeler Service</option>
                                    <option value="Mobile Mechanic Service" <%= "Mobile Mechanic Service".equalsIgnoreCase(shopType) ? "selected" : "" %>>Mobile Mechanic Service</option>
                                    <option value="Other" <%= "Other".equalsIgnoreCase(shopType) ? "selected" : "" %>>Other</option>
                                </select>
                            </div>

                            <!-- Workshop Landline / Alternate Contact -->
                            <div class="field-group">
                                <label class="field-label" for="editShopContact">
                                    <i class="fa-solid fa-phone-volume"></i> Workshop Landline / Contact Number
                                </label>
                                <input type="tel" id="editShopContact" name="shopContactNumber" class="field-input" value="<%= shopContact %>" maxlength="11" placeholder="e.g. 04222456789 or mobile">
                                <div id="shopContactInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Enter a valid contact number (6–11 digits).</span></div>
                            </div>

                            <!-- Hidden Working Hours Default Inputs -->
                            <input type="hidden" id="editOpenTime" name="openingTime" value="<%= openingTime %>">
                            <input type="hidden" id="editCloseTime" name="closingTime" value="<%= closingTime %>">

                            <!-- Description -->
                            <div class="field-col-full field-group">
                                <label class="field-label" for="editDescription">
                                    <i class="fa-solid fa-align-left"></i> Workshop Services Description
                                </label>
                                <textarea id="editDescription" name="shopDescription" class="field-textarea" placeholder="Detail the services, vehicle brands and quick repair specialties..."><%= description %></textarea>
                            </div>
                        </div>
                    </div>

                    <!-- Section 4: Workshop Photos (Shop Images Upload & Management) -->
                    <div class="profile-section-card">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-regular fa-images"></i>
                            </div>
                            <div>
                                <h3 class="section-card-title">Step 4: Workshop Photos (Shop Images)</h3>
                                <p class="section-card-desc">Upload photos of your garage entrance, service bays, or work facility</p>
                            </div>
                        </div>

                        <!-- Current Photos Management -->
                        <% if (!shopPhotosList.isEmpty()) { %>
                            <div style="margin-bottom: 16px;">
                                <label class="field-label"><i class="fa-solid fa-image"></i> Current Uploaded Photos (Select to remove)</label>
                                <div style="display: flex; gap: 14px; flex-wrap: wrap; margin-top: 8px;">
                                    <% for (Map<String, String> photo : shopPhotosList) { 
                                        String pId = photo.get("id");
                                        String pPath = photo.get("path");
                                        String pName = photo.get("name") != null ? photo.get("name") : "Photo";
                                        String fullSrc = (pPath.startsWith("/") || pPath.startsWith("http")) ? (request.getContextPath() + pPath) : (request.getContextPath() + "/images/" + pPath);
                                    %>
                                        <div style="position: relative; width: 130px; height: 95px; border-radius: 10px; overflow: hidden; border: 1.5px solid #CBD5E1;">
                                            <img src="<%= fullSrc %>" alt="<%= pName %>" style="width: 100%; height: 100%; object-fit: cover;">
                                            <label style="position: absolute; bottom: 0; inset-inline: 0; background: rgba(0,0,0,0.75); color: #FFF; font-size: 11px; padding: 4px; display: flex; align-items: center; justify-content: center; gap: 4px; cursor: pointer;">
                                                <input type="checkbox" name="deletePhotoCheckbox" value="<%= pId %>" onchange="updateDeletedPhotos()">
                                                <span>Delete</span>
                                            </label>
                                        </div>
                                    <% } %>
                                </div>
                            </div>
                        <% } %>

                        <!-- Photo Upload Dropzone -->
                        <div class="photo-upload-section">
                            <label class="photo-upload-dropzone" for="shopPhotosInput">
                                <i class="fa-solid fa-cloud-arrow-up"></i>
                                <span class="dropzone-label">Click or Drag to Upload New Shop Photos</span>
                                <span class="dropzone-sub">JPG, PNG, WEBP (Max 5 MB each, up to 5 photos)</span>
                                <input type="file" id="shopPhotosInput" accept="image/jpeg,image/png,image/webp" multiple style="display: none;">
                            </label>

                            <!-- Live preview of newly chosen photos -->
                            <div class="photo-preview-grid" id="newPhotosPreviewGrid"></div>
                        </div>

                        <!-- Hidden inputs for deleted photos and newly uploaded photo data -->
                        <input type="hidden" id="deletedPhotoIds" name="deletedPhotoIds" value="">
                        <div id="newPhotosHiddenInputsContainer"></div>
                    </div>

                    <!-- Section 5: Workshop Address & Interactive Location Map -->
                    <div class="profile-section-card" id="garageMapSection">
                        <div class="section-card-header">
                            <div class="section-card-icon">
                                <i class="fa-solid fa-location-dot"></i>
                            </div>
                            <div style="flex: 1;">
                                <h3 class="section-card-title">Step 5: Garage Location & Address</h3>
                                <p class="section-card-desc">Choose exact garage coordinates on map or use your live GPS location</p>
                            </div>
                            <div class="location-top-actions">
                                <button type="button" class="btn-loc-action btn-loc-gps" id="btnUseCurrentLocation" onclick="detectCurrentLocation()">
                                    <i class="fa-solid fa-crosshairs"></i>
                                    <span>Use Current Location</span>
                                </button>
                                <button type="button" class="btn-loc-action btn-loc-map" id="btnChooseOnMap" onclick="focusOnMap()">
                                    <i class="fa-solid fa-map-pin"></i>
                                    <span>Choose on Map</span>
                                </button>
                            </div>
                        </div>

                        <!-- Interactive Map Container Wrapper -->
                        <div class="profile-map-wrapper">
                            <div class="map-toolbar-strip">
                                <div class="map-status-info">
                                    <span class="map-live-dot"></span>
                                    <span class="map-status-label">Live Workshop Pin:</span>
                                    <span class="map-status-hint">Click map or drag the orange marker to update your garage location</span>
                                </div>
                                <div class="map-coords-badge" id="coordsBadge">
                                    <i class="fa-solid fa-location-crosshairs"></i>
                                    <span id="coordsDisplayLabel"><%= String.format(java.util.Locale.US, "%.4f", latitude) %>° N, <%= String.format(java.util.Locale.US, "%.4f", longitude) %>° E</span>
                                </div>
                            </div>

                            <div class="profile-map-canvas-container">
                                <div id="editGarageMap" style="width: 100%; height: 380px;"></div>
                                
                                <!-- Floating Map Controls -->
                                <div class="map-overlay-controls">
                                    <button type="button" class="map-ctrl-btn" title="Zoom In" onclick="mapZoomIn()">
                                        <i class="fa-solid fa-plus"></i>
                                    </button>
                                    <button type="button" class="map-ctrl-btn" title="Zoom Out" onclick="mapZoomOut()">
                                        <i class="fa-solid fa-minus"></i>
                                    </button>
                                    <button type="button" class="map-ctrl-btn" title="Center on Garage" onclick="resetToShopCenter()">
                                        <i class="fa-solid fa-arrows-to-dot"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- Geocode Feedback Notification Banner -->
                            <div id="geocodeNotice" class="map-geocode-notice" style="display: none;">
                                <i class="fa-solid fa-circle-check"></i>
                                <span id="geocodeNoticeText">Location coordinates updated successfully.</span>
                            </div>
                        </div>

                        <!-- Hidden Coordinate Fields for Form Submission -->
                        <input type="hidden" id="mechLatitude" name="latitude" value="<%= latitude %>">
                        <input type="hidden" id="mechLongitude" name="longitude" value="<%= longitude %>">

                        <!-- Synced Address Text Fields Matching Registration -->
                        <div class="profile-fields-grid" style="margin-top: 18px;">
                            <div class="field-group">
                                <label class="field-label" for="editAddr1">
                                    <i class="fa-solid fa-road"></i> Address Line 1 <span style="color:#EF4444;">*</span>
                                </label>
                                <input type="text" id="editAddr1" name="addressLine1" class="field-input" value="<%= addressLine1 %>" placeholder="Door No., Street / Building Name" required>
                                <div id="addr1Instruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>Address Line 1 is required (min 5 characters).</span></div>
                            </div>

                            <div class="field-group">
                                <label class="field-label" for="editAddr2">
                                    <i class="fa-solid fa-signs-post"></i> Address Line 2 (Area / Landmark)
                                </label>
                                <input type="text" id="editAddr2" name="addressLine2" class="field-input" value="<%= addressLine2 %>" placeholder="Area, Landmark or Extension">
                            </div>

                            <div class="field-group">
                                <label class="field-label" for="editCity">
                                    <i class="fa-solid fa-city"></i> City / Town <span style="color:#EF4444;">*</span>
                                </label>
                                <input type="text" id="editCity" name="city" class="field-input" value="<%= city %>" placeholder="Enter city" required>
                                <div id="cityInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>City or Town is required (letters only).</span></div>
                            </div>

                            <div class="field-group">
                                <label class="field-label" for="editDistrict">
                                    <i class="fa-solid fa-map-pin"></i> District <span style="color:#EF4444;">*</span>
                                </label>
                                <select id="editDistrict" name="district" class="field-select" required>
                                    <% 
                                        String[] districts = new String[] {
                                            "Coimbatore", "Chennai", "Madurai", "Tiruchirappalli", "Salem", "Tiruppur", 
                                            "Erode", "Dindigul", "Thanjavur", "Vellore", "Kallakurichi", "Kanchipuram", 
                                            "Kanyakumari", "Karur", "Krishnagiri", "Namakkal", "Nilgiris", "Perambalur", 
                                            "Pudukkottai", "Ramanathapuram", "Ranipet", "Sivaganga", "Tenkasi", "Theni", 
                                            "Thoothukudi", "Tirunelveli", "Tirupathur", "Tiruvallur", "Tiruvannamalai", 
                                            "Tiruvarur", "Viluppuram", "Virudhunagar"
                                        };
                                        for (String dist : districts) {
                                    %>
                                        <option value="<%= dist %>" <%= dist.equalsIgnoreCase(district) ? "selected" : "" %>><%= dist %></option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="field-group">
                                <label class="field-label" for="editState">
                                    <i class="fa-solid fa-map"></i> State
                                </label>
                                <input type="text" id="editState" name="state" class="field-input" value="Tamil Nadu" readonly style="background:#F1F5F9; color:#64748B;">
                            </div>

                            <div class="field-group">
                                <label class="field-label" for="editPincode">
                                    <i class="fa-solid fa-envelopes-bulk"></i> Pincode <span style="color:#EF4444;">*</span>
                                </label>
                                <input type="text" id="editPincode" name="pincode" class="field-input" value="<%= pincode %>" maxlength="6" placeholder="6-digit pincode" required>
                                <div id="pincodeInstruction" class="field-instruction-msg"><i class="fa-solid fa-circle-exclamation"></i> <span>6-digit valid pincode is required.</span></div>
                            </div>
                        </div>
                    </div>

                    <!-- Form Action Buttons -->
                    <div class="profile-actions-bar">
                        <button type="button" class="btn-profile-cancel" onclick="toggleEditMode(false)">
                            <i class="fa-solid fa-xmark"></i> Cancel
                        </button>
                        <button type="submit" class="btn-profile-save">
                            <i class="fa-solid fa-floppy-disk"></i> Save Profile Changes
                        </button>
                    </div>

                </form>

            </div>

        </main>
    </div>

    <!-- Photo Lightbox Modal Preview -->
    <div id="photoLightboxModal" class="photo-lightbox-modal" onclick="closePhotoModal(event)">
        <div class="lightbox-content-wrap">
            <button type="button" class="lightbox-close-btn" onclick="closePhotoModal(null)" title="Close Preview">
                <i class="fa-solid fa-xmark"></i>
            </button>
            <img id="lightboxImg" src="" alt="Workshop Photo Preview" class="lightbox-img">
            <span id="lightboxCaption" class="lightbox-caption">Workshop Photo</span>
        </div>
    </div>

    <!-- Leaflet JS Library -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <script>
        let viewMap = null;
        let editMap = null;
        let editMarker = null;
        let currentShopLat = <%= latitude %>;
        let currentShopLng = <%= longitude %>;
        let isEditActive = false;

        // Custom Automotive Orange Wrench Pin Icon
        function createGarageIcon() {
            return L.divIcon({
                className: 'custom-garage-marker',
                html: '<div class="garage-marker-pin"><i class="fa-solid fa-wrench"></i></div>',
                iconSize: [40, 40],
                iconAnchor: [20, 38],
                popupAnchor: [0, -38]
            });
        }

        // Initialize Read-Only View Map
        function initViewMap() {
            const container = document.getElementById('viewGarageMap');
            if (!container || viewMap) return;

            viewMap = L.map('viewGarageMap', {
                center: [currentShopLat, currentShopLng],
                zoom: 14,
                zoomControl: true
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; OpenStreetMap contributors',
                maxZoom: 19
            }).addTo(viewMap);

            const vMarker = L.marker([currentShopLat, currentShopLng], {
                icon: createGarageIcon(),
                interactive: true
            }).addTo(viewMap);

            vMarker.bindPopup('<strong><%= workshopName %></strong><br><span style="font-size:12px;color:#64748B;"><%= addressLine1 %>, <%= city %></span>').openPopup();

            setTimeout(function() {
                if (viewMap) viewMap.invalidateSize();
            }, 300);
        }

        // Initialize Interactive Edit Map
        function initEditMap() {
            const container = document.getElementById('editGarageMap');
            if (!container || editMap) return;

            editMap = L.map('editGarageMap', {
                center: [currentShopLat, currentShopLng],
                zoom: 14,
                zoomControl: false
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; OpenStreetMap contributors',
                maxZoom: 19
            }).addTo(editMap);

            editMarker = L.marker([currentShopLat, currentShopLng], {
                icon: createGarageIcon(),
                draggable: true,
                title: 'Workshop Location'
            }).addTo(editMap);

            editMarker.bindPopup('<strong><%= workshopName %></strong><br><span style="font-size:12px;color:#64748B;">Drag this marker or click anywhere on the map to change location.</span>');

            // Marker Drag Event
            editMarker.on('dragend', function(e) {
                const pos = e.target.getLatLng();
                updateLocationFields(pos.lat, pos.lng);
                reverseGeocode(pos.lat, pos.lng);
            });

            // Map Click Event
            editMap.on('click', function(e) {
                const lat = e.latlng.lat;
                const lng = e.latlng.lng;
                editMarker.setLatLng([lat, lng]);
                editMap.panTo([lat, lng]);
                updateLocationFields(lat, lng);
                reverseGeocode(lat, lng);
            });

            setTimeout(function() {
                if (editMap) editMap.invalidateSize();
            }, 300);

            // Expose globally
            window.garageMap = editMap;
            window.garageMarker = editMarker;
        }

        // Switch Between View Mode and Edit Mode
        function toggleEditMode(enable) {
            isEditActive = enable;
            const viewCont = document.getElementById('profileViewContainer');
            const editCont = document.getElementById('profileEditContainer');
            const btnHero = document.getElementById('btnEnableEdit');

            if (enable) {
                if (viewCont) viewCont.style.display = 'none';
                if (editCont) editCont.style.display = 'block';
                if (btnHero) btnHero.style.display = 'none';

                initEditMap();
                setTimeout(function() {
                    if (editMap) editMap.invalidateSize();
                }, 200);

                // Smooth scroll to top of edit form
                editCont.scrollIntoView({ behavior: 'smooth', block: 'start' });
            } else {
                if (viewCont) viewCont.style.display = 'flex';
                if (editCont) editCont.style.display = 'none';
                if (btnHero) btnHero.style.display = 'inline-flex';

                if (viewMap) {
                    viewMap.invalidateSize();
                } else {
                    initViewMap();
                }

                // Smooth scroll to top
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }

        function updateLocationFields(lat, lng) {
            currentShopLat = lat;
            currentShopLng = lng;
            document.getElementById('mechLatitude').value = lat.toFixed(6);
            document.getElementById('mechLongitude').value = lng.toFixed(6);
            
            const badge = document.getElementById('coordsDisplayLabel');
            if (badge) {
                const latDir = lat >= 0 ? 'N' : 'S';
                const lngDir = lng >= 0 ? 'E' : 'W';
                badge.innerText = Math.abs(lat).toFixed(4) + '° ' + latDir + ', ' + Math.abs(lng).toFixed(4) + '° ' + lngDir;
            }
        }

        function showNotice(msg) {
            const noticeBox = document.getElementById('geocodeNotice');
            const noticeText = document.getElementById('geocodeNoticeText');
            if (noticeBox && noticeText) {
                noticeText.innerText = msg;
                noticeBox.style.display = 'flex';
                setTimeout(function() {
                    noticeBox.style.display = 'none';
                }, 5000);
            }
        }

        // Reverse Geocode using Nominatim API
        function reverseGeocode(lat, lng) {
            fetch('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=' + lat + '&lon=' + lng)
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    if (data && data.address) {
                        const addrObj = data.address;
                        const road = addrObj.road || addrObj.suburb || addrObj.neighbourhood || '';
                        const suburb = addrObj.suburb || addrObj.city_district || '';
                        const town = addrObj.city || addrObj.town || addrObj.village || addrObj.state_district || 'Coimbatore';
                        
                        let formattedAddr = '';
                        if (road) formattedAddr += road;
                        if (suburb && suburb !== road) formattedAddr += (formattedAddr ? ', ' : '') + suburb;
                        
                        if (formattedAddr && formattedAddr.length > 5) {
                            const addrInput = document.getElementById('editAddr1');
                            if (addrInput) {
                                addrInput.value = formattedAddr;
                                validateAddress1();
                            }
                        }
                        
                        const cityInput = document.getElementById('editCity');
                        if (cityInput && town) {
                            cityInput.value = town;
                            validateCity();
                        }

                        showNotice('Map location pinned! Address updated to: ' + (formattedAddr || town));
                    }
                })
                .catch(function(err) {
                    console.log('Reverse geocode note:', err);
                    showNotice('Coordinates set to ' + lat.toFixed(4) + ', ' + lng.toFixed(4));
                });
        }

        // Detect Current GPS Location
        function detectCurrentLocation() {
            const btn = document.getElementById('btnUseCurrentLocation');
            if (!navigator.geolocation) {
                alert('Geolocation is not supported by your browser. Please click directly on the map to choose your garage location.');
                return;
            }

            const origContent = btn.innerHTML;
            btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> <span>Acquiring GPS...</span>';
            btn.disabled = true;

            navigator.geolocation.getCurrentPosition(
                function(pos) {
                    btn.innerHTML = origContent;
                    btn.disabled = false;
                    const lat = pos.coords.latitude;
                    const lng = pos.coords.longitude;

                    if (editMap && editMarker) {
                        editMap.setView([lat, lng], 16);
                        editMarker.setLatLng([lat, lng]);
                        editMarker.openPopup();
                    }
                    updateLocationFields(lat, lng);
                    reverseGeocode(lat, lng);
                    showNotice('Current GPS location captured successfully!');
                },
                function(err) {
                    btn.innerHTML = origContent;
                    btn.disabled = false;
                    console.warn('GPS detection notice:', err.message);
                    alert('Unable to acquire live GPS position (' + err.message + '). You can click anywhere on the map or drag the orange pin.');
                },
                { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
            );
        }

        function focusOnMap() {
            const mapSection = document.getElementById('garageMapSection');
            if (mapSection) {
                mapSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            if (editMap && editMarker) {
                editMap.invalidateSize();
                editMarker.openPopup();
            }
            showNotice('Click anywhere on the map or drag the orange pin to set workshop location.');
        }

        function resetToShopCenter() {
            if (editMap && editMarker) {
                editMap.setView([currentShopLat, currentShopLng], 15);
                editMarker.setLatLng([currentShopLat, currentShopLng]);
                editMarker.openPopup();
            }
        }

        function mapZoomIn() {
            if (editMap) editMap.zoomIn();
        }

        function mapZoomOut() {
            if (editMap) editMap.zoomOut();
        }

        // Photo Lightbox Controls
        function openPhotoModal(src, caption) {
            const modal = document.getElementById('photoLightboxModal');
            const img = document.getElementById('lightboxImg');
            const cap = document.getElementById('lightboxCaption');
            if (modal && img) {
                img.src = src;
                if (cap) cap.innerText = caption || 'Workshop Photo';
                modal.style.display = 'flex';
            }
        }

        function closePhotoModal(e) {
            if (!e || e.target.id === 'photoLightboxModal' || e.target.closest('.lightbox-close-btn')) {
                const modal = document.getElementById('photoLightboxModal');
                if (modal) modal.style.display = 'none';
            }
        }

        // Deleted Photos Handler
        function updateDeletedPhotos() {
            const checkboxes = document.querySelectorAll('input[name="deletePhotoCheckbox"]:checked');
            const delIds = [];
            checkboxes.forEach(function(cb) {
                delIds.push(cb.value);
            });
            document.getElementById('deletedPhotoIds').value = delIds.join(',');
        }

        // New Photos Selection Preview & Base64 Assembly
        const shopPhotosInput = document.getElementById('shopPhotosInput');
        const newPhotosPreviewGrid = document.getElementById('newPhotosPreviewGrid');
        const newPhotosHiddenContainer = document.getElementById('newPhotosHiddenInputsContainer');
        let selectedNewPhotos = [];

        if (shopPhotosInput) {
            shopPhotosInput.addEventListener('change', function(e) {
                const files = Array.from(e.target.files);
                if (files.length + selectedNewPhotos.length > 5) {
                    alert('You can upload a maximum of 5 workshop photos.');
                    return;
                }

                files.forEach(function(file) {
                    if (file.size > 5 * 1024 * 1024) {
                        alert('Photo "' + file.name + '" exceeds the 5 MB limit.');
                        return;
                    }
                    const reader = new FileReader();
                    reader.onload = function(ev) {
                        const base64Data = ev.target.result;
                        const itemObj = { id: Date.now() + Math.random(), file: file, data: base64Data, name: file.name };
                        selectedNewPhotos.push(itemObj);
                        renderNewPhotosPreviews();
                    };
                    reader.readAsDataURL(file);
                });
            });
        }

        function renderNewPhotosPreviews() {
            if (!newPhotosPreviewGrid || !newPhotosHiddenContainer) return;
            newPhotosPreviewGrid.innerHTML = '';
            newPhotosHiddenContainer.innerHTML = '';

            selectedNewPhotos.forEach(function(item, index) {
                // Card preview
                const card = document.createElement('div');
                card.className = 'photo-preview-item';
                card.innerHTML = '<img src="' + item.data + '" alt="' + item.name + '">' +
                    '<button type="button" class="btn-remove-preview-photo" onclick="removeSelectedNewPhoto(' + index + ')" title="Remove Photo">' +
                    '<i class="fa-solid fa-xmark"></i></button>';
                newPhotosPreviewGrid.appendChild(card);

                // Hidden Inputs for POST submission
                const hiddenData = document.createElement('input');
                hiddenData.type = 'hidden';
                hiddenData.name = 'newShopPhotoData';
                hiddenData.value = item.data;
                newPhotosHiddenContainer.appendChild(hiddenData);

                const hiddenName = document.createElement('input');
                hiddenName.type = 'hidden';
                hiddenName.name = 'newShopPhotoName';
                hiddenName.value = item.name;
                newPhotosHiddenContainer.appendChild(hiddenName);
            });
        }

        function removeSelectedNewPhoto(idx) {
            selectedNewPhotos.splice(idx, 1);
            renderNewPhotosPreviews();
        }

        // ===================================================================
        // EXACT VALIDATIONS MATCHING REGISTER.JSP
        // ===================================================================
        function setFieldInvalid(input, errorEl, message) {
            if (!input) return;
            input.classList.remove('is-valid');
            input.classList.add('is-invalid');
            if (errorEl) {
                const span = errorEl.querySelector('span');
                if (span && message) span.textContent = message;
                errorEl.style.display = 'flex';
            }
        }

        function setFieldValid(input, errorEl) {
            if (!input) return;
            input.classList.remove('is-invalid');
            input.classList.add('is-valid');
            if (errorEl) errorEl.style.display = 'none';
        }

        const firstNameInput = document.getElementById('editFirstName');
        const lastNameInput = document.getElementById('editLastName');
        const genderSelect = document.getElementById('editGender');
        const dobInput = document.getElementById('editDob');
        const phoneInput = document.getElementById('editPhone');
        const shopNameInput = document.getElementById('editWorkshopName');
        const shopContactInput = document.getElementById('editShopContact');
        const addr1Input = document.getElementById('editAddr1');
        const cityInput = document.getElementById('editCity');
        const districtSelect = document.getElementById('editDistrict');
        const pincodeInput = document.getElementById('editPincode');

        function validateFirstName() {
            // First Name is verified and locked (non-editable)
            return true;
        }

        function validateLastName() {
            // Last Name is verified and locked (non-editable)
            return true;
        }

        function validateGender() {
            if (!genderSelect) return true;
            const errEl = document.getElementById('genderInstruction');
            if (!genderSelect.value) {
                setFieldInvalid(genderSelect, errEl, 'Please select your gender.');
                return false;
            }
            setFieldValid(genderSelect, errEl);
            return true;
        }

        function validateDob() {
            // Date of Birth is verified and locked (non-editable)
            return true;
        }

        function validateMobile() {
            if (!phoneInput) return true;
            let val = phoneInput.value.replace(/\D/g, '');
            if (val.length > 10) val = val.substring(0, 10);
            phoneInput.value = val;

            const errEl = document.getElementById('phoneInstruction');
            if (!val) {
                setFieldInvalid(phoneInput, errEl, 'Mobile number is required (10 digits).');
                return false;
            }
            if (!/^[6-9]/.test(val)) {
                setFieldInvalid(phoneInput, errEl, 'Mobile number must start with 6, 7, 8, or 9.');
                return false;
            }
            if (val.length !== 10) {
                setFieldInvalid(phoneInput, errEl, 'Mobile number must be exactly 10 digits (' + val.length + '/10 entered).');
                return false;
            }
            setFieldValid(phoneInput, errEl);
            return true;
        }

        function validateSpecializations() {
            const checkboxes = document.querySelectorAll('input[name="serviceTypes"]:checked');
            const errEl = document.getElementById('servicesInstruction');
            if (checkboxes.length === 0) {
                if (errEl) errEl.style.display = 'flex';
                return false;
            }
            if (errEl) errEl.style.display = 'none';
            return true;
        }

        function validateShopName() {
            if (!shopNameInput) return true;
            const val = shopNameInput.value.trim();
            const errEl = document.getElementById('shopNameInstruction');
            if (!val) {
                setFieldInvalid(shopNameInput, errEl, 'Workshop / garage name is required.');
                return false;
            }
            if (val.length < 3) {
                setFieldInvalid(shopNameInput, errEl, 'Workshop name must be at least 3 characters.');
                return false;
            }
            setFieldValid(shopNameInput, errEl);
            return true;
        }

        function validateShopContact() {
            if (!shopContactInput) return true;
            let val = shopContactInput.value.replace(/\D/g, '');
            if (val.length > 11) val = val.substring(0, 11);
            shopContactInput.value = val;

            const errEl = document.getElementById('shopContactInstruction');
            if (val && val.length < 6) {
                setFieldInvalid(shopContactInput, errEl, 'Contact number should be between 6 and 11 digits.');
                return false;
            }
            setFieldValid(shopContactInput, errEl);
            return true;
        }

        function validateAddress1() {
            if (!addr1Input) return true;
            const val = addr1Input.value.trim();
            const errEl = document.getElementById('addr1Instruction');
            if (!val) {
                setFieldInvalid(addr1Input, errEl, 'Address Line 1 is required.');
                return false;
            }
            if (val.length < 5) {
                setFieldInvalid(addr1Input, errEl, 'Address Line 1 should be at least 5 characters.');
                return false;
            }
            setFieldValid(addr1Input, errEl);
            return true;
        }

        function validateCity() {
            if (!cityInput) return true;
            const val = cityInput.value.trim();
            const errEl = document.getElementById('cityInstruction');
            if (!val) {
                setFieldInvalid(cityInput, errEl, 'City or Town is required.');
                return false;
            }
            if (/[0-9]/.test(val)) {
                setFieldInvalid(cityInput, errEl, 'City name cannot contain numbers.');
                return false;
            }
            setFieldValid(cityInput, errEl);
            return true;
        }

        function validateDistrict() {
            if (!districtSelect) return true;
            if (!districtSelect.value) return false;
            return true;
        }

        function validatePincode() {
            if (!pincodeInput) return true;
            let val = pincodeInput.value.replace(/\D/g, '');
            if (val.length > 6) val = val.substring(0, 6);
            pincodeInput.value = val;

            const errEl = document.getElementById('pincodeInstruction');
            if (!val) {
                setFieldInvalid(pincodeInput, errEl, '6-digit pincode is required.');
                return false;
            }
            if (val.length !== 6 || !/^[1-9][0-9]{5}$/.test(val)) {
                setFieldInvalid(pincodeInput, errEl, 'Enter a valid 6-digit Indian Postal pincode (e.g. 641001).');
                return false;
            }
            setFieldValid(pincodeInput, errEl);
            return true;
        }

        // Attach Real-time Listeners (Locked fields editFirstName, editLastName, editDob, editEmail are skipped)
        if (genderSelect) {
            genderSelect.addEventListener('change', validateGender);
        }
        if (phoneInput) {
            phoneInput.addEventListener('input', validateMobile);
            phoneInput.addEventListener('blur', validateMobile);
        }
        if (shopNameInput) {
            shopNameInput.addEventListener('input', validateShopName);
            shopNameInput.addEventListener('blur', validateShopName);
        }
        if (shopContactInput) {
            shopContactInput.addEventListener('input', validateShopContact);
            shopContactInput.addEventListener('blur', validateShopContact);
        }
        if (addr1Input) {
            addr1Input.addEventListener('input', validateAddress1);
            addr1Input.addEventListener('blur', validateAddress1);
        }
        if (cityInput) {
            cityInput.addEventListener('input', validateCity);
            cityInput.addEventListener('blur', validateCity);
        }
        if (districtSelect) {
            districtSelect.addEventListener('change', validateDistrict);
        }
        if (pincodeInput) {
            pincodeInput.addEventListener('input', validatePincode);
            pincodeInput.addEventListener('blur', validatePincode);
        }
        document.querySelectorAll('input[name="serviceTypes"]').forEach(function(cb) {
            cb.addEventListener('change', validateSpecializations);
        });

        // Form Submit Validation Handler
        const editForm = document.getElementById('profileEditForm');
        if (editForm) {
            editForm.addEventListener('submit', function(e) {
                const v1 = validateFirstName();
                const v2 = validateLastName();
                const v3 = validateGender();
                const v4 = validateDob();
                const v5 = validateMobile();
                const v6 = validateSpecializations();
                const v7 = validateShopName();
                const v8 = validateShopContact();
                const v9 = validateAddress1();
                const v10 = validateCity();
                const v11 = validateDistrict();
                const v12 = validatePincode();

                if (!v1 || !v2 || !v3 || !v4 || !v5 || !v6 || !v7 || !v8 || !v9 || !v10 || !v11 || !v12) {
                    e.preventDefault();
                    const firstInvalid = editForm.querySelector('.is-invalid, .field-instruction-msg[style*="flex"]');
                    if (firstInvalid) {
                        firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                    alert('Please correct the highlighted fields before saving your profile.');
                    return false;
                }
            });
        }

        // On DOM Load: Initialize View Mode & View Map
        document.addEventListener('DOMContentLoaded', function() {
            initViewMap();

            // If URL contains hash #edit or query param ?action=edit, open edit mode immediately
            if (window.location.hash === '#edit' || window.location.search.indexOf('action=edit') !== -1 || window.location.hash === '#garageMapSection') {
                toggleEditMode(true);
            }
        });
    </script>
</body>
</html>
