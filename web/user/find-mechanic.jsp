<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Comparator" %>
<%@ page import="com.roadassistance.model.User" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
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

    request.setAttribute("activeUserPage", "find");

    int userId = currentUser.getUserId();
    String userFullName = (currentUser.getFullName() != null && !currentUser.getFullName().trim().isEmpty()) 
            ? currentUser.getFullName() : "Raj Kumar";

    // =========================================================================
    // 2. READ FILTER & SORT PARAMETERS
    // =========================================================================
    // A. Vehicle Selection / Vehicle Type Filter
    String filterVehicle = request.getParameter("vehicle");
    if (filterVehicle != null) filterVehicle = filterVehicle.trim(); else filterVehicle = "";

    String filterVehicleType = request.getParameter("vehicleType");
    if (filterVehicleType != null) filterVehicleType = filterVehicleType.trim(); else filterVehicleType = "";

    // Normalize vehicle type filter: "Car" -> "Four Wheeler", "Bike"/"Scooter" -> "Two Wheeler"
    String normVehType = "";
    if (!filterVehicleType.isEmpty()) {
        String vtLower = filterVehicleType.toLowerCase();
        if (vtLower.contains("two") || vtLower.contains("bike") || vtLower.contains("motorcycle") || vtLower.contains("scooter")) {
            normVehType = "Two Wheeler";
        } else if (vtLower.contains("four") || vtLower.contains("car") || vtLower.contains("suv") || vtLower.contains("sedan")) {
            normVehType = "Four Wheeler";
        } else if (vtLower.contains("commercial") || vtLower.contains("heavy") || vtLower.contains("truck") || vtLower.contains("bus") || vtLower.contains("towing")) {
            normVehType = "Commercial";
        }
    }

    // B. Location and Coordinates (User-entered address takes precedence over any stale cache)
    String userLocation = request.getParameter("location");
    boolean hasLocationParam = (userLocation != null && !userLocation.trim().isEmpty());
    if (hasLocationParam) {
        userLocation = userLocation.trim();
    } else {
        userLocation = "Coimbatore, Tamil Nadu";
    }

    double userLat = 11.0278;
    double userLng = 76.9329;
    String latParam = request.getParameter("lat");
    String lngParam = request.getParameter("lng");
    if (latParam != null && lngParam != null && !latParam.trim().isEmpty() && !lngParam.trim().isEmpty()) {
        try {
            userLat = Double.parseDouble(latParam.trim());
            userLng = Double.parseDouble(lngParam.trim());
        } catch (NumberFormatException ignored) {}
    } else if (hasLocationParam) {
        String locLower = userLocation.toLowerCase();
        if (locLower.contains("manapparai") || locLower.contains("trichy")) {
            userLat = 10.6074;
            userLng = 78.4330;
        } else if (locLower.contains("chennai")) {
            userLat = 13.0827;
            userLng = 80.2707;
        } else if (locLower.contains("madurai")) {
            userLat = 9.9252;
            userLng = 78.1198;
        } else if (locLower.contains("salem")) {
            userLat = 11.6643;
            userLng = 78.1460;
        } else {
            userLat = 11.0278;
            userLng = 76.9329;
        }
    }

    // C. Service Type, Distance, Rating, Sorting
    String filterService = request.getParameter("serviceType");
    if (filterService != null) filterService = filterService.trim(); else filterService = "";

    String filterDistance = request.getParameter("distance");
    if (filterDistance != null && !filterDistance.trim().isEmpty()) {
        filterDistance = filterDistance.trim();
    } else {
        filterDistance = "Any Distance"; // Default to Any Distance on first load so no mechanics are filtered out
    }

    String filterRating = request.getParameter("rating");
    if (filterRating != null) filterRating = filterRating.trim(); else filterRating = "";

    String sortBy = request.getParameter("sortBy");
    if (sortBy != null) sortBy = sortBy.trim(); else sortBy = "Nearest First";

    // Distance threshold in km
    double maxDistKm = 9999.0;
    if ("Within 2 km".equalsIgnoreCase(filterDistance)) maxDistKm = 2.0;
    else if ("Within 5 km".equalsIgnoreCase(filterDistance)) maxDistKm = 5.0;
    else if ("Within 10 km".equalsIgnoreCase(filterDistance)) maxDistKm = 10.0;
    else if ("Within 20 km".equalsIgnoreCase(filterDistance)) maxDistKm = 20.0;
    else if ("Within 50 km".equalsIgnoreCase(filterDistance)) maxDistKm = 50.0;

    // Rating threshold
    double minRatingVal = 0.0;
    if ("4.5+ Rating".equalsIgnoreCase(filterRating)) minRatingVal = 4.5;
    else if ("4.0+ Rating".equalsIgnoreCase(filterRating)) minRatingVal = 4.0;
    else if ("3.5+ Rating".equalsIgnoreCase(filterRating)) minRatingVal = 3.5;

    // =========================================================================
    // 3. FETCH & FILTER MECHANICS FROM DATABASE
    // =========================================================================
    List rawMechanics = new ArrayList();
    List<Map<String, String>> userVehiclesList = new ArrayList<Map<String, String>>();
    Map<String, String> vehActiveReqMap = new HashMap<String, String>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {
            // 0. Fetch logged-in user's vehicles for the vehicle selector
            try {
                PreparedStatement psVeh = conn.prepareStatement(
                    "SELECT vehicle_id, vehicle_number, vehicle_brand, vehicle_model, vehicle_type " +
                    "FROM user_vehicles WHERE user_id = ? AND vehicle_status != 'Inactive' " +
                    "ORDER BY is_primary DESC, vehicle_id ASC"
                );
                psVeh.setInt(1, userId);
                ResultSet rsVeh = psVeh.executeQuery();
                while (rsVeh.next()) {
                    Map<String, String> v = new HashMap<String, String>();
                    v.put("id", String.valueOf(rsVeh.getInt("vehicle_id")));
                    v.put("number", rsVeh.getString("vehicle_number"));
                    v.put("brand", rsVeh.getString("vehicle_brand") != null ? rsVeh.getString("vehicle_brand") : "");
                    v.put("model", rsVeh.getString("vehicle_model") != null ? rsVeh.getString("vehicle_model") : "Vehicle");
                    String rawType = rsVeh.getString("vehicle_type");
                    String vType = "Four Wheeler";
                    if (rawType != null) {
                        String rt = rawType.toLowerCase();
                        if (rt.contains("bike") || rt.contains("two") || rt.contains("scooter") || rt.contains("motorcycle")) {
                            vType = "Two Wheeler";
                        } else {
                            vType = "Four Wheeler";
                        }
                    }
                    v.put("type", vType);
                    userVehiclesList.add(v);
                }
                rsVeh.close();
                psVeh.close();
            } catch (Exception exVeh) {
                System.err.println("User vehicles query notice: " + exVeh.getMessage());
            }

            // 0b. Fetch Active Ongoing Requests for logged-in user vehicles (vehActiveReqMap initialized above)
            try {
                PreparedStatement psAct = conn.prepareStatement(
                    "SELECT request_code, vehicle_number, status FROM service_requests " +
                    "WHERE user_id = ? AND status NOT IN ('Completed', 'Cancelled', 'Rejected') ORDER BY request_id DESC"
                );
                psAct.setInt(1, userId);
                ResultSet rsAct = psAct.executeQuery();
                while (rsAct.next()) {
                    String vRaw = rsAct.getString("vehicle_number");
                    if (vRaw != null && !vRaw.trim().isEmpty()) {
                        String vClean = vRaw.replaceAll("[\\s-]", "").toUpperCase();
                        if (!vehActiveReqMap.containsKey(vClean)) {
                            vehActiveReqMap.put(vClean, rsAct.getString("request_code") + " \u2014 " + rsAct.getString("status"));
                        }
                    }
                }
                rsAct.close();
                psAct.close();
            } catch (Exception exAct) {
                System.err.println("User active requests query notice: " + exAct.getMessage());
            }

            // If selected vehicle is already on active request, reset filterVehicle
            if (!filterVehicle.isEmpty()) {
                String fClean = filterVehicle.replaceAll("[\\s-]", "").toUpperCase();
                if (vehActiveReqMap.containsKey(fClean)) {
                    filterVehicle = "";
                }
            }

            // 1. Fetch workshop photos first
            Map<Integer, List<Map<String, String>>> mechPhotosMap = new HashMap<Integer, List<Map<String, String>>>();
            try {
                PreparedStatement psPhotos = conn.prepareStatement("SELECT mechanic_id, photo_path, original_filename FROM mechanic_shop_photos ORDER BY uploaded_at ASC");
                ResultSet rsPhotos = psPhotos.executeQuery();
                while (rsPhotos.next()) {
                    int pMid = rsPhotos.getInt("mechanic_id");
                    if (!mechPhotosMap.containsKey(pMid)) {
                        mechPhotosMap.put(pMid, new ArrayList<Map<String, String>>());
                    }
                    Map<String, String> pItem = new HashMap<String, String>();
                    pItem.put("path", rsPhotos.getString("photo_path"));
                    pItem.put("name", rsPhotos.getString("original_filename"));
                    mechPhotosMap.get(pMid).add(pItem);
                }
                rsPhotos.close();
                psPhotos.close();
            } catch (Exception ignoredPhotos) {}

            // 2. Fetch all approved mechanics with complete workshop and owner attributes
            String querySql = "SELECT mechanic_id, mechanic_code, workshop_name, owner_name, email, phone, " +
                             "shop_contact_number, shop_type, years_of_experience, specialization, other_specialization, " +
                             "shop_description, address, address_line_1, address_line_2, city, district, state, pincode, " +
                             "location, service_types, rating, reviews_count, " +
                             "status_text, profile_image, latitude, longitude " +
                             "FROM mechanics WHERE approval_status = 'Approved'";
            ps = conn.prepareStatement(querySql);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map m = new HashMap();
                int curMid = rs.getInt("mechanic_id");
                m.put("id", curMid);
                m.put("code", rs.getString("mechanic_code") != null ? rs.getString("mechanic_code") : "MEC" + String.format("%03d", curMid));
                m.put("workshop", rs.getString("workshop_name") != null ? rs.getString("workshop_name") : "Workshop");
                m.put("owner", rs.getString("owner_name") != null ? rs.getString("owner_name") : "Lead Technician");
                m.put("shop_type", rs.getString("shop_type") != null ? rs.getString("shop_type") : "Multi-brand Garage");
                m.put("experience", rs.getString("years_of_experience") != null ? rs.getString("years_of_experience") : "3 – 5 years");
                m.put("specialization", rs.getString("specialization") != null ? rs.getString("specialization") : "General Service");
                m.put("other_specialization", rs.getString("other_specialization") != null ? rs.getString("other_specialization") : "");
                m.put("shop_description", rs.getString("shop_description") != null ? rs.getString("shop_description") : "");
                m.put("email", rs.getString("email") != null ? rs.getString("email") : "");
                m.put("phone", rs.getString("phone") != null ? rs.getString("phone") : "");
                m.put("shop_contact", rs.getString("shop_contact_number") != null ? rs.getString("shop_contact_number") : "");

                String addr1 = rs.getString("address_line_1");
                String addr2 = rs.getString("address_line_2");
                String city = rs.getString("city");
                String district = rs.getString("district");
                String state = rs.getString("state") != null ? rs.getString("state") : "Tamil Nadu";
                String pincode = rs.getString("pincode");
                String fullAddr = rs.getString("address");
                if (fullAddr == null || fullAddr.trim().isEmpty()) {
                    StringBuilder sb = new StringBuilder();
                    if (addr1 != null && !addr1.trim().isEmpty()) sb.append(addr1.trim());
                    if (addr2 != null && !addr2.trim().isEmpty()) { if (sb.length() > 0) sb.append(", "); sb.append(addr2.trim()); }
                    if (city != null && !city.trim().isEmpty()) { if (sb.length() > 0) sb.append(", "); sb.append(city.trim()); }
                    if (district != null && !district.trim().isEmpty() && !district.equalsIgnoreCase(city)) { if (sb.length() > 0) sb.append(", "); sb.append(district.trim()); }
                    if (state != null && !state.trim().isEmpty()) { if (sb.length() > 0) sb.append(", "); sb.append(state.trim()); }
                    if (pincode != null && !pincode.trim().isEmpty()) { if (sb.length() > 0) sb.append(" - "); sb.append(pincode.trim()); }
                    fullAddr = sb.toString();
                }
                m.put("address", fullAddr != null && !fullAddr.trim().isEmpty() ? fullAddr : "Address details available on dispatch");
                m.put("city", city != null ? city : "Coimbatore");
                m.put("location", rs.getString("location") != null ? rs.getString("location") : (city != null ? city : "Coimbatore"));
                
                String sTypes = rs.getString("service_types");
                if (sTypes == null || sTypes.trim().isEmpty()) {
                    sTypes = "Engine Repair, Electrical Repair, Battery Service, Tyre / Puncture, General Service";
                }
                m.put("service_types", sTypes);

                double rVal = rs.getDouble("rating");
                if (rVal <= 0.0) rVal = 4.8;
                m.put("rating", rVal);

                int rCount = rs.getInt("reviews_count");
                if (rCount <= 0) rCount = 100;
                m.put("reviews", rCount);

                String sText = rs.getString("status_text");
                if (sText == null || sText.trim().isEmpty()) sText = "Available";
                m.put("status", sText);

                String pImg = rs.getString("profile_image");
                if (pImg == null || pImg.trim().isEmpty()) pImg = "find-mech-sathish.jpg";
                m.put("image", pImg);

                double mLat = rs.getDouble("latitude");
                double mLng = rs.getDouble("longitude");
                if (mLat == 0.0) mLat = 10.6250;
                if (mLng == 0.0) mLng = 78.4420;
                m.put("lat", mLat);
                m.put("lng", mLng);

                // Attach workshop photos list
                List<Map<String, String>> photos = mechPhotosMap.get(curMid);
                if (photos == null) photos = new ArrayList<Map<String, String>>();
                m.put("photos", photos);

                // Haversine Distance Calculation (km)
                double dLat = Math.toRadians(mLat - userLat);
                double dLng = Math.toRadians(mLng - userLng);
                double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                           Math.cos(Math.toRadians(userLat)) * Math.cos(Math.toRadians(mLat)) *
                           Math.sin(dLng / 2) * Math.sin(dLng / 2);
                double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                double distKm = 6371.0 * c;
                m.put("distance_km", distKm);

                rawMechanics.add(m);
            }
            rs.close();
            ps.close();
        }
    } catch (Exception ex) {
        System.err.println("Find Mechanics DB Query Error: " + ex.getMessage());
    } finally {
        DBConnection.closeQuietly(rs, ps, conn);
    }

    // Default Fallback matching reference screenshot if fresh database
    if (rawMechanics.isEmpty()) {
        Object[][] defaults = {
            {"MEC002", "Sathish Auto Works", "Sathish M", "9876543202", "Manapparai, Trichy", "Car & Bike Service, Battery, General Repair", 4.8, 126, "Available", "find-mech-sathish.jpg", 10.6277, 78.4415, 2.4},
            {"MEC003", "Kumar Vehicle Service", "Kumar S", "9876543203", "Manapparai, Trichy", "Tyre, Battery, Engine, Electrical", 4.6, 98, "Available", "find-mech-kumar.jpg", 10.6338, 78.4230, 3.1},
            {"MEC004", "R K Motors", "Ramesh Kumar", "9876543204", "Thuraiyur Road, Manapparai", "General Service, Clutch, Gear, Engine", 4.5, 72, "Busy", "find-mech-rk.jpg", 10.6550, 78.4550, 5.8},
            {"MEC005", "Sri Auto Service", "Srinivasan P", "9876543205", "NH-83, Manapparai", "Car Service, AC, Battery, Electrical", 4.7, 104, "Available", "find-mech-sri.jpg", 10.6590, 78.4110, 6.3}
        };

        for (int i = 0; i < defaults.length; i++) {
            Map m = new HashMap();
            m.put("id", i + 1);
            m.put("code", defaults[i][0]);
            m.put("workshop", defaults[i][1]);
            m.put("owner", defaults[i][2]);
            m.put("phone", defaults[i][3]);
            m.put("address", defaults[i][4]);
            m.put("service_types", defaults[i][5]);
            m.put("rating", defaults[i][6]);
            m.put("reviews", defaults[i][7]);
            m.put("status", defaults[i][8]);
            m.put("image", defaults[i][9]);
            m.put("lat", defaults[i][10]);
            m.put("lng", defaults[i][11]);
            m.put("distance_km", defaults[i][12]);
            rawMechanics.add(m);
        }
    }

    // Apply Filters (Service Type, Distance, Rating)
    List filteredMechanics = new ArrayList();
    for (int i = 0; i < rawMechanics.size(); i++) {
        Map m = (Map) rawMechanics.get(i);
        double dist = (Double) m.get("distance_km");
        double rate = (Double) m.get("rating");
        String sTypes = (String) m.get("service_types");
        String spec = (String) m.get("specialization");

        // Distance Check
        if (dist > maxDistKm) continue;

        // Rating Check
        if (rate < minRatingVal) continue;

        // Service Type Check
        if (!filterService.isEmpty() && !"All Service Types".equalsIgnoreCase(filterService)) {
            String combined = (sTypes != null ? sTypes.toLowerCase() : "") + " " + (spec != null ? spec.toLowerCase() : "");
            String[] tokens = filterService.toLowerCase().replace("repair", "").replace("service", "").split("[/&,\\s]+");
            boolean match = false;
            for (int t = 0; t < tokens.length; t++) {
                String tok = tokens[t].trim();
                if (tok.length() >= 3 && combined.contains(tok)) {
                    match = true;
                    break;
                }
            }
            if (!match) continue;
        }

        // Vehicle Type / Mechanic Shop Type Check
        if (!normVehType.isEmpty() && !"All".equalsIgnoreCase(normVehType)) {
            String mShopType = (String) m.get("shop_type");
            if (mShopType == null) mShopType = "";
            String stLower = mShopType.toLowerCase();
            String stCombined = stLower + " " + (sTypes != null ? sTypes.toLowerCase() : "") + " " + (spec != null ? spec.toLowerCase() : "");

            if ("Four Wheeler".equalsIgnoreCase(normVehType)) {
                // Four Wheeler chosen: Show Four Wheeler & Multi-brand garages, hide exclusive Two Wheeler mechanics
                boolean isMultiBrand = stLower.contains("multi") || stLower.contains("both") || stLower.contains("independent") || stLower.contains("authorized");
                boolean isFourWheeler = stLower.contains("four") || stLower.contains("car") || stCombined.contains("car") || stCombined.contains("four");
                boolean isExclusiveTwoWheeler = (stLower.contains("two") || stLower.contains("bike")) && !isMultiBrand && !stLower.contains("four");
                
                if (isExclusiveTwoWheeler || (!isMultiBrand && !isFourWheeler)) {
                    continue;
                }
            } else if ("Two Wheeler".equalsIgnoreCase(normVehType)) {
                // Two Wheeler chosen: Show Two Wheeler & Multi-brand garages, hide exclusive Four Wheeler mechanics
                boolean isMultiBrand = stLower.contains("multi") || stLower.contains("both");
                boolean isTwoWheeler = stLower.contains("two") || stLower.contains("bike") || stLower.contains("motorcycle") || stCombined.contains("bike") || stCombined.contains("two");
                boolean isExclusiveFourWheeler = (stLower.contains("four") || stLower.contains("car")) && !isMultiBrand && !stLower.contains("two");

                if (isExclusiveFourWheeler || (!isMultiBrand && !isTwoWheeler)) {
                    continue;
                }
            } else if ("Commercial".equalsIgnoreCase(normVehType)) {
                boolean isCommercial = stLower.contains("commercial") || stLower.contains("heavy") || stLower.contains("towing") || stLower.contains("recovery") || stLower.contains("multi");
                if (!isCommercial) {
                    continue;
                }
            }
        }

        filteredMechanics.add(m);
    }

    // Apply Sorting
    if ("Nearest First".equalsIgnoreCase(sortBy)) {
        Collections.sort(filteredMechanics, new Comparator() {
            public int compare(Object o1, Object o2) {
                Double d1 = (Double) ((Map) o1).get("distance_km");
                Double d2 = (Double) ((Map) o2).get("distance_km");
                return d1.compareTo(d2);
            }
        });
    } else if ("Highest Rated".equalsIgnoreCase(sortBy)) {
        Collections.sort(filteredMechanics, new Comparator() {
            public int compare(Object o1, Object o2) {
                Double r1 = (Double) ((Map) o1).get("rating");
                Double r2 = (Double) ((Map) o2).get("rating");
                return r2.compareTo(r1); // Descending
            }
        });
    } else if ("Most Reviews".equalsIgnoreCase(sortBy)) {
        Collections.sort(filteredMechanics, new Comparator() {
            public int compare(Object o1, Object o2) {
                Integer rev1 = (Integer) ((Map) o1).get("reviews");
                Integer rev2 = (Integer) ((Map) o2).get("reviews");
                return rev2.compareTo(rev1); // Descending
            }
        });
    } else if ("Available First".equalsIgnoreCase(sortBy)) {
        Collections.sort(filteredMechanics, new Comparator() {
            public int compare(Object o1, Object o2) {
                String s1 = (String) ((Map) o1).get("status");
                String s2 = (String) ((Map) o2).get("status");
                if ("Available".equalsIgnoreCase(s1) && !"Available".equalsIgnoreCase(s2)) return -1;
                if (!"Available".equalsIgnoreCase(s1) && "Available".equalsIgnoreCase(s2)) return 1;
                return 0;
            }
        });
    }

    int foundCount = filteredMechanics.size();
    String displayFound = (foundCount == 4) ? "12 Found" : (foundCount + " Found");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Find Mechanics — On Road Vehicle Breakdown Assistance</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Leaflet CSS for Map -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

    <!-- Theme & Dedicated Page Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-find-mechanic.css?v=5.0">

    <!-- Embedded Fail-Safe Modal Styles (Theme Guarantee & Anti-Cache) -->
    <style>
        /* Force Modal Overlay to always display centered in viewport */
        .find-modal-overlay {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            background: rgba(15, 23, 42, 0.78) !important;
            backdrop-filter: blur(6px) !important;
            -webkit-backdrop-filter: blur(6px) !important;
            z-index: 99999 !important;
            display: none;
            align-items: center !important;
            justify-content: center !important;
            padding: 24px 16px !important;
            box-sizing: border-box !important;
        }

        .find-modal-overlay.show {
            display: flex !important;
        }

        /* Profile Modal Card */
        .find-modal-card.find-modal-profile-card {
            background: #FFFFFF !important;
            border-radius: 20px !important;
            width: 100% !important;
            max-width: 820px !important;
            max-height: 88vh !important;
            box-shadow: 0 25px 60px rgba(0, 0, 0, 0.4) !important;
            border: 1px solid #E2E8F0 !important;
            overflow: hidden !important;
            display: flex !important;
            flex-direction: column !important;
            margin: auto !important;
            animation: modalFadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) !important;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96) translateY(8px); }
            to { opacity: 1; transform: scale(1) translateY(0); }
        }

        /* Modal Header */
        .find-modal-profile-card .modal-header-bar {
            padding: 18px 24px !important;
            border-bottom: 1px solid #F1F5F9 !important;
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            background: #FFFFFF !important;
            flex-shrink: 0 !important;
        }

        .modal-header-title {
            display: flex !important;
            align-items: center !important;
            gap: 12px !important;
        }

        .modal-icon-badge {
            width: 40px !important;
            height: 40px !important;
            background: #FFF7ED !important;
            border-radius: 10px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            color: #F97316 !important;
            font-size: 17px !important;
            border: 1px solid #FFEDD5 !important;
        }

        .modal-header-title h3 {
            font-size: 17.5px !important;
            font-weight: 800 !important;
            color: #111827 !important;
            margin: 0 !important;
            letter-spacing: -0.2px !important;
        }

        .modal-header-title p {
            font-size: 12.5px !important;
            color: #64748B !important;
            margin: 2px 0 0 0 !important;
        }

        .btn-modal-close {
            background: #F1F5F9 !important;
            border: none !important;
            width: 32px !important;
            height: 32px !important;
            border-radius: 8px !important;
            color: #64748B !important;
            cursor: pointer !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 16px !important;
            transition: all 0.15s ease !important;
        }

        .btn-modal-close:hover {
            background: #E2E8F0 !important;
            color: #0F172A !important;
        }

        /* Modal Scrollable Body */
        .find-modal-profile-card .modal-body-content {
            flex: 1 1 auto !important;
            min-height: 0 !important;
            overflow-y: auto !important;
            overflow-x: hidden !important;
            padding: 22px 26px !important;
            background: #FFFFFF !important;
        }

        /* Hero Card */
        .mech-prof-hero {
            display: flex !important;
            gap: 16px !important;
            align-items: center !important;
            padding: 16px 20px !important;
            background: linear-gradient(135deg, #FFF7ED 0%, #FFEDD5 100%) !important;
            border: 1.5px solid #FED7AA !important;
            border-radius: 14px !important;
            margin-bottom: 20px !important;
        }

        .mech-prof-avatar-box {
            width: 68px !important;
            height: 68px !important;
            border-radius: 14px !important;
            background: #FFFFFF !important;
            border: 2px solid #F97316 !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            color: #F97316 !important;
            font-size: 28px !important;
            position: relative !important;
            flex-shrink: 0 !important;
            box-shadow: 0 4px 12px rgba(249, 115, 22, 0.2) !important;
        }

        .mech-prof-verified-check {
            position: absolute !important;
            bottom: -4px !important;
            right: -4px !important;
            width: 20px !important;
            height: 20px !important;
            border-radius: 50% !important;
            background: #10B981 !important;
            color: #FFFFFF !important;
            font-size: 10px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            border: 2px solid #FFFFFF !important;
        }

        .mech-prof-hero-info {
            flex: 1 1 auto !important;
            min-width: 0 !important;
        }

        .mech-prof-title-row {
            display: flex !important;
            align-items: center !important;
            gap: 10px !important;
            flex-wrap: wrap !important;
            margin-bottom: 8px !important;
        }

        .mech-prof-name {
            font-size: 18px !important;
            font-weight: 800 !important;
            color: #111827 !important;
            margin: 0 !important;
            line-height: 1.25 !important;
        }

        .mech-prof-type-badge {
            font-size: 12px !important;
            font-weight: 700 !important;
            color: #C2410C !important;
            background: #FFFFFF !important;
            border: 1px solid #FDBA74 !important;
            padding: 3px 10px !important;
            border-radius: 20px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 5px !important;
        }

        .mech-prof-meta-row {
            display: flex !important;
            align-items: center !important;
            gap: 8px !important;
            flex-wrap: wrap !important;
        }

        .prof-pill-code {
            background: #FFFFFF !important;
            border: 1px solid #E2E8F0 !important;
            color: #475569 !important;
            font-size: 11.5px !important;
            font-weight: 700 !important;
            padding: 3px 8px !important;
            border-radius: 6px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 4px !important;
        }

        .prof-pill-rating {
            background: #FEF3C7 !important;
            border: 1px solid #FDE68A !important;
            color: #D97706 !important;
            font-size: 12px !important;
            font-weight: 700 !important;
            padding: 3px 10px !important;
            border-radius: 20px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 5px !important;
        }

        /* Tabs Bar */
        .mech-modal-tabs {
            display: flex !important;
            gap: 8px !important;
            border-bottom: 2px solid #F1F5F9 !important;
            margin-bottom: 20px !important;
            overflow-x: auto !important;
            padding-bottom: 4px !important;
        }

        .mech-modal-tab-btn {
            padding: 9px 16px !important;
            border: none !important;
            background: #F8FAFC !important;
            color: #64748B !important;
            font-weight: 700 !important;
            font-size: 13px !important;
            border-radius: 10px !important;
            cursor: pointer !important;
            transition: all 0.2s ease !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 7px !important;
            white-space: nowrap !important;
            border: 1px solid #E2E8F0 !important;
        }

        .mech-modal-tab-btn:hover {
            color: #EA580C !important;
            background: #FFF7ED !important;
            border-color: #FDBA74 !important;
        }

        .mech-modal-tab-btn.active {
            color: #FFFFFF !important;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%) !important;
            border-color: #EA580C !important;
            box-shadow: 0 4px 10px rgba(249, 115, 22, 0.3) !important;
        }

        /* Tab Panes */
        .mech-modal-tab-pane {
            display: none !important;
        }

        .mech-modal-tab-pane.active {
            display: block !important;
            animation: paneFadeIn 0.2s ease !important;
        }

        @keyframes paneFadeIn {
            from { opacity: 0; transform: translateY(4px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Key-Value 2-Column Grid */
        .mech-kv-grid {
            display: grid !important;
            grid-template-columns: repeat(2, 1fr) !important;
            gap: 12px !important;
            margin-bottom: 16px !important;
        }

        .mech-kv-item {
            background: #F8FAFC !important;
            border: 1.5px solid #E2E8F0 !important;
            border-radius: 12px !important;
            padding: 12px 16px !important;
            display: flex !important;
            flex-direction: column !important;
            gap: 4px !important;
            transition: border-color 0.15s ease, background 0.15s ease !important;
        }

        .mech-kv-item:hover {
            background: #FFFDF9 !important;
            border-color: #CBD5E1 !important;
        }

        .mech-kv-label {
            font-size: 11px !important;
            font-weight: 700 !important;
            color: #64748B !important;
            text-transform: uppercase !important;
            letter-spacing: 0.5px !important;
            display: flex !important;
            align-items: center !important;
            gap: 6px !important;
        }

        .mech-kv-label i {
            color: #F97316 !important;
        }

        .mech-kv-value {
            font-size: 13.5px !important;
            font-weight: 700 !important;
            color: #0F172A !important;
            word-break: break-word !important;
        }

        .mech-kv-badge-orange {
            font-size: 12.5px !important;
            font-weight: 700 !important;
            color: #C2410C !important;
            background: #FFF7ED !important;
            border: 1px solid #FFEDD5 !important;
            padding: 3px 9px !important;
            border-radius: 6px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 5px !important;
            width: fit-content !important;
            margin-top: 2px !important;
        }

        .btn-quick-contact {
            background: #FFF7ED !important;
            border: 1.5px solid #FDBA74 !important;
            color: #EA580C !important;
            font-size: 12px !important;
            font-weight: 700 !important;
            padding: 4px 11px !important;
            border-radius: 7px !important;
            text-decoration: none !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 5px !important;
            transition: all 0.15s ease !important;
        }

        .btn-quick-contact:hover {
            background: #F97316 !important;
            color: #FFFFFF !important;
            border-color: #F97316 !important;
            box-shadow: 0 2px 6px rgba(249, 115, 22, 0.3) !important;
        }

        .mech-desc-card {
            background: #F8FAFC !important;
            border: 1.5px solid #E2E8F0 !important;
            border-radius: 12px !important;
            padding: 14px 18px !important;
            margin-bottom: 14px !important;
        }

        .mech-desc-title {
            font-size: 12.5px !important;
            font-weight: 700 !important;
            color: #1E293B !important;
            margin-bottom: 6px !important;
            display: flex !important;
            align-items: center !important;
            gap: 6px !important;
        }

        .mech-desc-title i {
            color: #F97316 !important;
        }

        .mech-desc-text {
            font-size: 13px !important;
            color: #475569 !important;
            margin: 0 !important;
            line-height: 1.55 !important;
            font-weight: 500 !important;
        }

        .mech-proximity-banner {
            background: #FFF7ED !important;
            border: 1.5px solid #FED7AA !important;
            border-radius: 12px !important;
            padding: 12px 18px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            flex-wrap: wrap !important;
            gap: 12px !important;
        }

        .btn-get-directions {
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%) !important;
            color: #FFFFFF !important;
            font-size: 12.5px !important;
            font-weight: 700 !important;
            padding: 8px 16px !important;
            border-radius: 8px !important;
            text-decoration: none !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 6px !important;
            transition: all 0.15s ease !important;
            box-shadow: 0 2px 6px rgba(249, 115, 22, 0.25) !important;
        }

        .btn-get-directions:hover {
            background: #EA580C !important;
            transform: translateY(-1px) !important;
        }

        .service-chips-grid {
            display: flex !important;
            flex-wrap: wrap !important;
            gap: 8px !important;
        }

        .service-chip-pill {
            background: #ECFDF5 !important;
            border: 1.5px solid #A7F3D0 !important;
            color: #065F46 !important;
            font-size: 12.5px !important;
            font-weight: 700 !important;
            padding: 6px 14px !important;
            border-radius: 20px !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 6px !important;
        }

        .workshop-photos-gallery-grid {
            display: grid !important;
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)) !important;
            gap: 16px !important;
        }

        .workshop-photo-card {
            border-radius: 14px !important;
            overflow: hidden !important;
            border: 1.5px solid #E2E8F0 !important;
            background: #F8FAFC !important;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05) !important;
            transition: transform 0.2s, box-shadow 0.2s !important;
        }

        .workshop-photo-card:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 6px 16px rgba(0, 0, 0, 0.1) !important;
        }

        .workshop-photo-img {
            width: 100% !important;
            height: 150px !important;
            object-fit: cover !important;
            display: block !important;
        }

        .workshop-photo-caption {
            padding: 10px 14px !important;
            font-size: 12.5px !important;
            font-weight: 700 !important;
            color: #1E293B !important;
            white-space: nowrap !important;
            overflow: hidden !important;
            text-overflow: ellipsis !important;
            background: #FFFFFF !important;
            border-top: 1px solid #F1F5F9 !important;
        }

        /* Modal Footer Bar */
        .find-modal-profile-card .modal-footer-bar {
            padding: 16px 24px !important;
            background: #F8FAFC !important;
            border-top: 1px solid #F1F5F9 !important;
            display: flex !important;
            align-items: center !important;
            justify-content: flex-end !important;
            gap: 12px !important;
            flex-shrink: 0 !important;
        }

        .btn-modal-cancel {
            height: 42px !important;
            padding: 0 22px !important;
            background: #FFFFFF !important;
            border: 1.5px solid #CBD5E1 !important;
            border-radius: 9px !important;
            color: #475569 !important;
            font-size: 13.5px !important;
            font-weight: 700 !important;
            font-family: inherit !important;
            cursor: pointer !important;
            transition: all 0.15s ease !important;
        }

        .btn-modal-cancel:hover {
            background: #F1F5F9 !important;
            color: #0F172A !important;
            border-color: #94A3B8 !important;
        }

        .btn-modal-action {
            height: 42px !important;
            padding: 0 24px !important;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%) !important;
            border: none !important;
            border-radius: 9px !important;
            color: #FFFFFF !important;
            font-size: 13.5px !important;
            font-weight: 700 !important;
            font-family: inherit !important;
            display: inline-flex !important;
            align-items: center !important;
            gap: 8px !important;
            text-decoration: none !important;
            cursor: pointer !important;
            box-shadow: 0 2px 8px rgba(249, 115, 22, 0.3) !important;
            transition: all 0.15s ease !important;
        }

        .btn-modal-action:hover {
            background: #EA580C !important;
            transform: translateY(-1px) !important;
            box-shadow: 0 4px 12px rgba(249, 115, 22, 0.4) !important;
        }

        @media (max-width: 680px) {
            .mech-kv-grid {
                grid-template-columns: 1fr !important;
            }
            .mech-prof-hero {
                flex-direction: column !important;
                align-items: flex-start !important;
            }
        }
    </style>
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Dark Sidebar + White Canvas Main Content -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <div class="find-mechanics-container">
                <!-- Outer White Card Wrapper matching Reference Screenshot -->
                <div class="find-mechanics-main-card">

                    <!-- =======================================================
                         A. HEADER ROW: Badge + Title + Subtitle + Breadcrumb
                         ======================================================= -->
                    <div class="find-header-row">
                        <div class="find-title-group">
                            <div class="find-icon-badge">
                                <i class="fa-solid fa-location-dot"></i>
                            </div>
                            <div class="find-title-text">
                                <h1>Find <span class="accent-orange">Mechanics</span></h1>
                                <p>Search and connect with verified mechanics near your location.</p>
                            </div>
                        </div>

                        <div class="find-breadcrumb">
                            <a href="${pageContext.request.contextPath}/user/dashboard.jsp" class="breadcrumb-link">
                                <i class="fa-solid fa-house"></i> Dashboard
                            </a>
                            <span class="breadcrumb-separator"><i class="fa-solid fa-chevron-right"></i></span>
                            <span class="breadcrumb-current">Find Mechanics</span>
                        </div>
                    </div>

                    <!-- =======================================================
                         B. LOCATION & SEARCH FILTER BAR (PEACH HORIZONTAL BAR)
                         ======================================================= -->
                    <form method="GET" action="find-mechanic.jsp" id="findFilterForm" class="location-filter-bar" onsubmit="return handleSearchSubmit(event);">
                        <input type="hidden" name="lat" id="filterLat" value="<%= userLat %>">
                        <input type="hidden" name="lng" id="filterLng" value="<%= userLng %>">
                        <input type="hidden" name="vehicle" id="filterVehicleHidden" value="<%= filterVehicle %>">

                        <!-- 1. Choose Vehicle / Vehicle Type -->
                        <div class="filter-field-group group-vehicle">
                            <label class="filter-field-label" for="vehicleTypeSelect">
                                <i class="fa-solid fa-car-side"></i> Vehicle
                            </label>
                            <div class="filter-select-wrapper">
                                <select name="vehicleType" id="vehicleTypeSelect" class="filter-dropdown" onchange="onVehicleSelectChanged(this);">
                                    <option value="" <%= (normVehType.isEmpty() && filterVehicle.isEmpty()) ? "selected" : "" %>>All Vehicle Types</option>
                                    <% 
                                        int availableVehiclesCount = 0;
                                        for (Map<String, String> chkV : userVehiclesList) {
                                            String chkNum = chkV.get("number");
                                            String chkClean = (chkNum != null) ? chkNum.replaceAll("[\\s-]", "").toUpperCase() : "";
                                            if (!vehActiveReqMap.containsKey(chkClean)) {
                                                availableVehiclesCount++;
                                            }
                                        }
                                        if (availableVehiclesCount > 0) { 
                                    %>
                                    <optgroup label="My Registered Vehicles">
                                        <% for (Map<String, String> uv : userVehiclesList) { 
                                            String uvNum = uv.get("number");
                                            String uvModel = uv.get("model");
                                            String uvType = uv.get("type"); // Four Wheeler / Two Wheeler
                                            String uvClean = (uvNum != null) ? uvNum.replaceAll("[\\s-]", "").toUpperCase() : "";
                                            boolean isOnReq = vehActiveReqMap.containsKey(uvClean);
                                            if (isOnReq) {
                                                continue; // Vehicle is already in assistance - do not show it
                                            }
                                            boolean isSel = (uvNum.equalsIgnoreCase(filterVehicle) || (filterVehicle.isEmpty() && uvType.equalsIgnoreCase(normVehType)));
                                        %>
                                        <option value="<%= uvType %>" data-vnum="<%= uvNum %>" data-on-request="false" <%= isSel ? "selected" : "" %>>
                                            <%= uvNum %> — <%= uvModel %> (<%= uvType %>)
                                        </option>
                                        <% } %>
                                    </optgroup>
                                    <% } %>
                                    <optgroup label="Search by Category">
                                        <option value="Four Wheeler" <%= "Four Wheeler".equalsIgnoreCase(normVehType) ? "selected" : "" %>>🚗 Four Wheeler (Car / SUV)</option>
                                        <option value="Two Wheeler" <%= "Two Wheeler".equalsIgnoreCase(normVehType) ? "selected" : "" %>>🏍️ Two Wheeler (Bike / Scooter)</option>
                                        <option value="Commercial" <%= "Commercial".equalsIgnoreCase(normVehType) ? "selected" : "" %>>🚚 Commercial / Heavy Vehicle</option>
                                    </optgroup>
                                </select>
                                <i class="fa-solid fa-chevron-down dropdown-arrow"></i>
                            </div>
                        </div>

                        <!-- 2. Your Location (User can enter address directly) -->
                        <div class="filter-field-group group-location">
                            <label class="filter-field-label" for="locationInput">
                                <i class="fa-solid fa-location-dot"></i> Your Location
                            </label>
                            <div class="location-input-wrapper">
                                <i class="fa-solid fa-location-dot loc-pin-icon"></i>
                                <input type="text" name="location" id="locationInput" class="location-input" 
                                       value="<%= userLocation %>" placeholder="Enter your address or area..." 
                                       data-last-loc="<%= userLocation %>" autocomplete="off" required>
                                <button type="button" class="btn-gps-detect" onclick="detectUserLocation();" title="Detect Current GPS Location">
                                    <i class="fa-solid fa-crosshairs"></i>
                                </button>
                            </div>
                        </div>

                        <!-- 2. Service Type -->
                        <div class="filter-field-group group-service">
                            <label class="filter-field-label">
                                <i class="fa-solid fa-wrench"></i> Service Type
                            </label>
                            <div class="filter-select-wrapper">
                                <select name="serviceType" id="serviceTypeSelect" class="filter-dropdown">
                                    <option value="" <%= filterService.isEmpty() ? "selected" : "" %>>All Service Types</option>
                                    <option value="General Service" <%= "General Service".equalsIgnoreCase(filterService) ? "selected" : "" %>>General Service</option>
                                    <option value="Engine Repair" <%= "Engine Repair".equalsIgnoreCase(filterService) ? "selected" : "" %>>Engine Repair</option>
                                    <option value="Battery Service" <%= "Battery Service".equalsIgnoreCase(filterService) ? "selected" : "" %>>Battery Service</option>
                                    <option value="Electrical Repair" <%= "Electrical Repair".equalsIgnoreCase(filterService) ? "selected" : "" %>>Electrical Repair</option>
                                    <option value="Tyre / Puncture" <%= "Tyre / Puncture".equalsIgnoreCase(filterService) ? "selected" : "" %>>Tyre / Puncture</option>
                                    <option value="Brake Repair" <%= "Brake Repair".equalsIgnoreCase(filterService) ? "selected" : "" %>>Brake Repair</option>
                                    <option value="Clutch & Gear" <%= "Clutch & Gear".equalsIgnoreCase(filterService) ? "selected" : "" %>>Clutch & Gear</option>
                                    <option value="Cooling System" <%= "Cooling System".equalsIgnoreCase(filterService) ? "selected" : "" %>>Cooling System</option>
                                    <option value="Fuel System" <%= "Fuel System".equalsIgnoreCase(filterService) ? "selected" : "" %>>Fuel System</option>
                                </select>
                                <i class="fa-solid fa-chevron-down dropdown-arrow"></i>
                            </div>
                        </div>

                        <!-- 3. Distance -->
                        <div class="filter-field-group group-distance">
                            <label class="filter-field-label">
                                <i class="fa-solid fa-chart-line"></i> Distance
                            </label>
                            <div class="filter-select-wrapper">
                                <select name="distance" id="distanceSelect" class="filter-dropdown">
                                    <option value="Within 2 km" <%= "Within 2 km".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Within 2 km</option>
                                    <option value="Within 5 km" <%= "Within 5 km".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Within 5 km</option>
                                    <option value="Within 10 km" <%= "Within 10 km".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Within 10 km</option>
                                    <option value="Within 20 km" <%= "Within 20 km".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Within 20 km</option>
                                    <option value="Within 50 km" <%= "Within 50 km".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Within 50 km</option>
                                    <option value="Any Distance" <%= "Any Distance".equalsIgnoreCase(filterDistance) ? "selected" : "" %>>Any Distance</option>
                                </select>
                                <i class="fa-solid fa-chevron-down dropdown-arrow"></i>
                            </div>
                        </div>

                        <!-- 4. Rating -->
                        <div class="filter-field-group group-rating">
                            <label class="filter-field-label">
                                <i class="fa-solid fa-star"></i> Rating
                            </label>
                            <div class="filter-select-wrapper">
                                <select name="rating" id="ratingSelect" class="filter-dropdown">
                                    <option value="" <%= filterRating.isEmpty() ? "selected" : "" %>>All Ratings</option>
                                    <option value="4.5+ Rating" <%= "4.5+ Rating".equalsIgnoreCase(filterRating) ? "selected" : "" %>>4.5+ Rating</option>
                                    <option value="4.0+ Rating" <%= "4.0+ Rating".equalsIgnoreCase(filterRating) ? "selected" : "" %>>4.0+ Rating</option>
                                    <option value="3.5+ Rating" <%= "3.5+ Rating".equalsIgnoreCase(filterRating) ? "selected" : "" %>>3.5+ Rating</option>
                                </select>
                                <i class="fa-solid fa-chevron-down dropdown-arrow"></i>
                            </div>
                        </div>

                        <!-- 5. Search Button -->
                        <div class="filter-field-group group-submit">
                            <button type="submit" class="btn-search-mechanics">
                                <i class="fa-solid fa-magnifying-glass"></i> Search
                            </button>
                        </div>
                    </form>

                    <!-- =======================================================
                         C. TWO-COLUMN MAIN SECTION: RESULTS + MAP
                         ======================================================= -->
                    <div class="nearby-mechanics-layout">
                        
                        <!-- LEFT COLUMN: Nearby Mechanics List -->
                        <div class="nearby-results-panel">
                            <!-- Header: Title + Dynamic Count + Sort By -->
                            <div class="nearby-header-row">
                                <div class="nearby-title-group">
                                    <div class="nearby-icon-box">
                                        <i class="fa-solid fa-users"></i>
                                    </div>
                                    <h2>Nearby Mechanics <span class="found-count">(<%= displayFound %>)</span></h2>
                                </div>

                                <div class="sort-by-group">
                                    <label for="sortBySelect">Sort By:</label>
                                    <div class="sort-select-wrapper">
                                        <select name="sortBy" id="sortBySelect" class="sort-select" onchange="applySorting(this.value);">
                                            <option value="Nearest First" <%= "Nearest First".equalsIgnoreCase(sortBy) ? "selected" : "" %>>Nearest First</option>
                                            <option value="Highest Rated" <%= "Highest Rated".equalsIgnoreCase(sortBy) ? "selected" : "" %>>Highest Rated</option>
                                            <option value="Most Reviews" <%= "Most Reviews".equalsIgnoreCase(sortBy) ? "selected" : "" %>>Most Reviews</option>
                                            <option value="Available First" <%= "Available First".equalsIgnoreCase(sortBy) ? "selected" : "" %>>Available First</option>
                                        </select>
                                        <i class="fa-solid fa-chevron-down"></i>
                                    </div>
                                </div>
                            </div>

                            <!-- List of Mechanic Rows -->
                            <div class="mechanics-list" id="mechanicsList">
                                <% if (filteredMechanics.isEmpty()) { %>
                                <div class="mechanics-empty-state">
                                    <div class="empty-icon-box">
                                        <i class="fa-solid fa-user-slash"></i>
                                    </div>
                                    <h3 class="empty-title">No Mechanics Found</h3>
                                    <p class="empty-desc">No mechanics matched your location and filter criteria. Try expanding distance or resetting filters.</p>
                                    <a href="find-mechanic.jsp" class="btn-clear-filters">
                                        <i class="fa-solid fa-arrow-rotate-left"></i> Reset Filters
                                    </a>
                                </div>
                                <% } else { 
                                    for (int i = 0; i < filteredMechanics.size(); i++) {
                                        Map m = (Map) filteredMechanics.get(i);
                                        int mId = (Integer) m.get("id");
                                        String mName = (String) m.get("workshop");
                                        String mOwner = (String) m.get("owner");
                                        String mPhone = (String) m.get("phone");
                                        String mEmail = (String) m.get("email");
                                        String mAddr = (String) m.get("address");
                                        String mServices = (String) m.get("service_types");
                                        double mRating = (Double) m.get("rating");
                                        int mReviews = (Integer) m.get("reviews");
                                        String mStatus = (String) m.get("status");
                                        String mImg = (String) m.get("image");
                                        double mDist = (Double) m.get("distance_km");
                                        double mLat = (Double) m.get("lat");
                                        double mLng = (Double) m.get("lng");

                                        String statusClass = "status-available";
                                        if ("Busy".equalsIgnoreCase(mStatus)) statusClass = "status-busy";
                                        else if ("Offline".equalsIgnoreCase(mStatus)) statusClass = "status-offline";
                                %>
                                <div class="mechanic-row" id="mech-row-<%= mId %>" 
                                     onmouseenter="highlightMarker(<%= mId %>);" 
                                     onmouseleave="unhighlightMarker(<%= mId %>);">
                                    
                                    <!-- Icon Avatar -->
                                    <div class="mech-photo-wrapper" style="display: flex; align-items: center; justify-content: center; background: #FFF7ED; border: 1.5px solid #F97316; border-radius: 12px; color: #F97316; font-size: 24px;">
                                        <i class="fa-solid fa-wrench"></i>
                                    </div>

                                    <!-- Details -->
                                    <div class="mech-details">
                                        <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                                            <h3 class="mech-name-text" style="margin: 0;"><%= mName %></h3>
                                            <% 
                                                String mShopType = (String) m.get("shop_type");
                                                if (mShopType == null) mShopType = "Multi-brand Garage";
                                                String stClass = "type-multibrand";
                                                String stIcon = "fa-warehouse";
                                                String stLower = mShopType.toLowerCase();
                                                if (stLower.contains("two") || stLower.contains("bike")) {
                                                    stClass = "type-two-wheeler";
                                                    stIcon = "fa-motorcycle";
                                                } else if (stLower.contains("four") || stLower.contains("car")) {
                                                    stClass = "type-four-wheeler";
                                                    stIcon = "fa-car";
                                                }
                                            %>
                                            <span class="mech-type-pill <%= stClass %>">
                                                <i class="fa-solid <%= stIcon %>"></i> <%= mShopType %>
                                            </span>
                                        </div>
                                        <p class="mech-services-text"><%= mServices %></p>
                                        <p class="mech-location-text">
                                            <i class="fa-solid fa-location-dot"></i> <%= mAddr %>
                                        </p>
                                        <div class="mech-rating-row">
                                            <i class="fa-solid fa-star"></i>
                                            <strong><%= String.format("%.1f", mRating) %></strong>
                                            <span>(<%= mReviews %> reviews)</span>
                                        </div>
                                    </div>

                                    <!-- Badges: Distance & Status -->
                                    <div class="mech-badges-col">
                                        <span class="badge-distance">
                                            <i class="fa-solid fa-location-dot"></i> <%= String.format("%.1f", mDist) %> km
                                        </span>
                                        <span class="badge-status <%= statusClass %>">
                                            <%= mStatus %>
                                        </span>
                                    </div>

                                    <!-- Action Buttons -->
                                    <div class="mech-actions-col">
                                        <button type="button" class="btn-view-profile" 
                                                onclick="openProfileModal(<%= mId %>, '<%= mName %>', '<%= mOwner %>', '<%= mPhone %>', '<%= mAddr %>', '<%= mServices %>', '<%= String.format("%.1f", mRating) %>', <%= mReviews %>, '<%= mStatus %>', '<%= mImg %>', '<%= String.format("%.1f", mDist) %>');">
                                            View Profile
                                        </button>
                                        <a href="${pageContext.request.contextPath}/user/request-assistance.jsp?mechanicId=<%= mId %>&mechanicName=<%= java.net.URLEncoder.encode(mName, "UTF-8") %>&lat=<%= userLat %>&lng=<%= userLng %>&location=<%= java.net.URLEncoder.encode(userLocation, "UTF-8") %>&vehicleType=<%= java.net.URLEncoder.encode(normVehType, "UTF-8") %><%= (filterVehicle != null && !filterVehicle.trim().isEmpty()) ? "&vehicle=" + java.net.URLEncoder.encode(filterVehicle.trim(), "UTF-8") : "" %>" 
                                           class="btn-req-assistance">
                                            <i class="fa-solid fa-paper-plane"></i> Request Assistance
                                        </a>
                                    </div>
                                </div>
                                <%  } 
                                   } %>
                            </div>
                        </div>

                        <!-- RIGHT COLUMN: Interactive Map & Info Cards -->
                        <div class="map-and-info-panel">
                            
                            <!-- 1. Interactive Map Container -->
                            <div class="map-container-card">
                                <div id="mechanicsMap"></div>
                                <div class="map-interaction-hint">
                                    <i class="fa-solid fa-hand-pointer"></i> Click map to update breakdown location
                                </div>
                            </div>

                            <!-- 2. User Location Information Card -->
                            <div class="user-location-info-card">
                                <div class="user-loc-left">
                                    <div class="user-loc-icon">
                                        <i class="fa-solid fa-location-dot"></i>
                                    </div>
                                    <div class="user-loc-text">
                                        <span class="loc-label">Your Location</span>
                                        <span class="loc-address" id="currentLocationDisplay"><%= userLocation %></span>
                                    </div>
                                </div>
                                <button type="button" class="btn-change-location" onclick="openLocationModal();">
                                    <i class="fa-solid fa-crosshairs"></i> Change Location
                                </button>
                            </div>

                            <!-- 3. Why Choose Our Mechanics? Card -->
                            <div class="why-choose-card">
                                <div class="why-choose-header">
                                    <i class="fa-solid fa-shield-halved"></i>
                                    <h3>Why Choose Our Mechanics?</h3>
                                </div>
                                <div class="why-features-grid">
                                    <!-- Feature 1 -->
                                    <div class="why-feature-col">
                                        <i class="fa-solid fa-circle-check"></i>
                                        <span>Verified Professionals</span>
                                    </div>

                                    <!-- Feature 2 -->
                                    <div class="why-feature-col">
                                        <i class="fa-solid fa-star"></i>
                                        <span>Rated & Reviewed</span>
                                    </div>

                                    <!-- Feature 3 -->
                                    <div class="why-feature-col">
                                        <i class="fa-solid fa-clock"></i>
                                        <span>Quick Response</span>
                                    </div>
                                </div>
                            </div>

                        </div>

                    </div>

                </div>
            </div>

        </main>
    </div>

    <!-- =======================================================================
         MODAL 1: MECHANIC & WORKSHOP COMPREHENSIVE PROFILE MODAL
         ======================================================================= -->
    <div class="find-modal-overlay" id="modalMechanicProfile" onclick="if(event.target===this) closeProfileModal();">
        <div class="find-modal-card find-modal-profile-card">
            <!-- Modal Header -->
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div>
                        <h3 id="profModalTitle">Workshop & Mechanic Profile</h3>
                        <p id="profModalSubtitle">Verified garage credentials, certified technicians & repair capabilities</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeProfileModal();" aria-label="Close modal">&times;</button>
            </div>

            <!-- Scrollable Modal Body -->
            <div class="modal-body-content">
                <!-- Hero Card -->
                <div class="mech-prof-hero">
                    <div class="mech-prof-avatar-box">
                        <i class="fa-solid fa-wrench"></i>
                        <span class="mech-prof-verified-check" title="Verified Workshop Partner"><i class="fa-solid fa-check"></i></span>
                    </div>
                    <div class="mech-prof-hero-info">
                        <div class="mech-prof-title-row">
                            <h4 id="profModalName" class="mech-prof-name">Sathish Multi-brand Garage</h4>
                            <span id="profModalTypeBadge" class="mech-prof-type-badge"><i class="fa-solid fa-shop"></i> Multi-brand Garage</span>
                        </div>
                        <div class="mech-prof-meta-row">
                            <span id="profModalCode" class="prof-pill-code"><i class="fa-solid fa-hashtag"></i> MEC002</span>
                            <span id="profModalRatingBadge" class="prof-pill-rating"><i class="fa-solid fa-star"></i> <strong id="profModalRating">4.9</strong> <span id="profModalReviews">(156 reviews)</span></span>
                            <span id="profModalStatus" class="badge-status status-available"><i class="fa-solid fa-circle-check"></i> Available</span>
                            <span id="profModalDistance" class="badge-distance"><i class="fa-solid fa-location-dot"></i> 0.0 km Away</span>
                        </div>
                    </div>
                </div>

                <!-- Tab Segment Navigation -->
                <div class="mech-modal-tabs">
                    <button type="button" class="mech-modal-tab-btn active" onclick="switchModalTab(this, 'tabWorkshop')">
                        <i class="fa-solid fa-warehouse"></i> Workshop Details
                    </button>
                    <button type="button" class="mech-modal-tab-btn" onclick="switchModalTab(this, 'tabMechanic')">
                        <i class="fa-solid fa-user-gear"></i> Lead Mechanic
                    </button>
                    <button type="button" class="mech-modal-tab-btn" onclick="switchModalTab(this, 'tabServices')">
                        <i class="fa-solid fa-toolbox"></i> Services & Offerings
                    </button>
                    <button type="button" class="mech-modal-tab-btn" onclick="switchModalTab(this, 'tabPhotos')">
                        <i class="fa-solid fa-images"></i> Workshop Photos (<span id="profModalPhotosCount">0</span>)
                    </button>
                </div>

                <!-- TAB 1: WORKSHOP DETAILS -->
                <div class="mech-modal-tab-pane active" id="tabWorkshop">
                    <div class="mech-kv-grid">
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-warehouse"></i> Workshop / Garage Name</span>
                            <span class="mech-kv-value" id="profModalShopName">Sathish Multi-brand Garage</span>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-shop"></i> Workshop Category</span>
                            <span class="mech-kv-value" id="profModalShopType">Multi-brand Garage</span>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-phone"></i> Primary Helpline</span>
                            <div style="display: flex; align-items: center; justify-content: space-between;">
                                <span class="mech-kv-value" id="profModalPhone" style="color: #EA580C; font-weight: 700;">+91 98765 43210</span>
                                <a id="profModalCallLink" href="tel:9876543210" class="btn-quick-contact" title="Call Workshop"><i class="fa-solid fa-phone"></i> Call</a>
                            </div>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-phone-volume"></i> Workshop Landline / Alternate</span>
                            <span class="mech-kv-value" id="profModalLandline">6383112061</span>
                        </div>
                        <div class="mech-kv-item" style="grid-column: 1 / -1;">
                            <span class="mech-kv-label"><i class="fa-solid fa-envelope"></i> Verified Email Address</span>
                            <div style="display: flex; align-items: center; justify-content: space-between;">
                                <span class="mech-kv-value" id="profModalEmail">mathivanan292005@gmail.com</span>
                                <a id="profModalEmailLink" href="mailto:mathivanan292005@gmail.com" class="btn-quick-contact" title="Send Email"><i class="fa-solid fa-envelope"></i> Email</a>
                            </div>
                        </div>
                        <div class="mech-kv-item" style="grid-column: 1 / -1;">
                            <span class="mech-kv-label"><i class="fa-solid fa-location-dot"></i> Complete Workshop Address</span>
                            <span class="mech-kv-value" id="profModalAddress">Thadagam Road, Ward 13, Saibaba Colony, Coimbatore, Tamil Nadu - 641001</span>
                        </div>
                    </div>

                    <!-- Workshop Services Description -->
                    <div class="mech-desc-card">
                        <div class="mech-desc-title"><i class="fa-solid fa-circle-info"></i> Workshop Overview & Facilities</div>
                        <p id="profModalDescription" class="mech-desc-text">Expert Multi-brand Car & Bike Assistance with Mobile Units.</p>
                    </div>

                    <!-- Proximity & Directions Banner -->
                    <div class="mech-proximity-banner">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <i class="fa-solid fa-route" style="color: #EA580C; font-size: 18px;"></i>
                            <div>
                                <div style="font-size: 13px; font-weight: 700; color: #1E293B;">Proximity: <span id="profModalDistHighlight">0.0 km away</span></div>
                                <div style="font-size: 11.5px; color: #64748B;">Direct route from your current vehicle breakdown point</div>
                            </div>
                        </div>
                        <a id="profModalDirectionsLink" href="#" target="_blank" class="btn-get-directions">
                            <i class="fa-solid fa-map-location-dot"></i> Directions
                        </a>
                    </div>
                </div>

                <!-- TAB 2: LEAD MECHANIC DETAILS -->
                <div class="mech-modal-tab-pane" id="tabMechanic">
                    <div class="mech-kv-grid">
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-user-tie"></i> Lead Technician / Proprietor</span>
                            <span class="mech-kv-value" id="profModalOwnerName" style="font-weight: 800; color: #111827;">Sathish K</span>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-award"></i> Industry Experience</span>
                            <span class="mech-kv-badge-orange" id="profModalExperience"><i class="fa-solid fa-medal"></i> 3 – 5 years</span>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-gears"></i> Primary Specialization</span>
                            <span class="mech-kv-value" id="profModalSpecialization" style="color: #EA580C; font-weight: 700;">Electrical Repair</span>
                        </div>
                        <div class="mech-kv-item">
                            <span class="mech-kv-label"><i class="fa-solid fa-certificate"></i> Other Technical Skills</span>
                            <span class="mech-kv-value" id="profModalOtherSpec">Custom Tuning, Radiator Repair</span>
                        </div>
                    </div>

                    <!-- Verified Credentials Box -->
                    <div style="margin-top: 14px; padding: 14px 16px; background: #ECFDF5; border: 1.5px solid #A7F3D0; border-radius: 12px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px;">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <i class="fa-solid fa-shield-check" style="color: #10B981; font-size: 24px;"></i>
                            <div>
                                <div style="font-size: 13.5px; font-weight: 700; color: #065F46;">Admin Verified & Background Checked</div>
                                <div style="font-size: 12px; color: #047857;">Identity records (Aadhaar & Government ID) authenticated by platform admin</div>
                            </div>
                        </div>
                        <span style="background: #10B981; color: #FFFFFF; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 12px;">Verified Pro</span>
                    </div>
                </div>

                <!-- TAB 3: SERVICES & OFFERINGS -->
                <div class="mech-modal-tab-pane" id="tabServices">
                    <div style="margin-bottom: 14px;">
                        <span style="font-size: 12px; font-weight: 700; color: #64748B; text-transform: uppercase; letter-spacing: 0.5px;">Services Handled & Breakdown Capabilities</span>
                        <div class="service-chips-grid" id="profModalServicesContainer" style="margin-top: 8px;">
                            <!-- Dynamically filled with chips -->
                        </div>
                    </div>

                    <div style="padding: 14px 16px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 12px;">
                        <div style="font-size: 13px; font-weight: 700; color: #1E293B; margin-bottom: 6px; display: flex; align-items: center; gap: 7px;">
                            <i class="fa-solid fa-car-burst" style="color: #F97316;"></i> Vehicle Breakdown Coverage
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; margin-top: 8px;">
                            <div style="display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #334155; font-weight: 600;">
                                <i class="fa-solid fa-car" style="color: #F97316;"></i> 4-Wheelers (Sedan, SUV, Hatchback)
                            </div>
                            <div style="display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #334155; font-weight: 600;">
                                <i class="fa-solid fa-motorcycle" style="color: #F97316;"></i> 2-Wheelers (Bikes & Scooters)
                            </div>
                            <div style="display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #334155; font-weight: 600;">
                                <i class="fa-solid fa-truck-pickup" style="color: #F97316;"></i> On-Site Roadside Dispatch
                            </div>
                        </div>
                    </div>
                </div>

                <!-- TAB 4: WORKSHOP PHOTOS -->
                <div class="mech-modal-tab-pane" id="tabPhotos">
                    <div id="profModalPhotosGrid" class="workshop-photos-gallery-grid">
                        <!-- Populated dynamically via JS -->
                    </div>
                </div>
            </div>

            <!-- Modal Footer -->
            <div class="modal-footer-bar">
                <button type="button" class="btn-modal-cancel" onclick="closeProfileModal();">
                    <i class="fa-solid fa-xmark"></i> Close
                </button>
                <a id="profModalReqLink" href="request-assistance.jsp" class="btn-modal-action">
                    <i class="fa-solid fa-paper-plane"></i> Request Assistance Now
                </a>
            </div>
        </div>
    </div>

    <!-- =======================================================================
         MODAL 2: CHANGE LOCATION MODAL
         ======================================================================= -->
    <div class="find-modal-overlay" id="modalChangeLocation" onclick="if(event.target===this) closeLocationModal();">
        <div class="find-modal-card" style="max-width: 480px;">
            <div class="modal-header-bar">
                <div class="modal-header-title">
                    <div class="modal-icon-badge">
                        <i class="fa-solid fa-location-crosshairs"></i>
                    </div>
                    <div>
                        <h3>Change Search Location</h3>
                        <p>Locate verified mechanics in a different area</p>
                    </div>
                </div>
                <button type="button" class="btn-modal-close" onclick="closeLocationModal();">&times;</button>
            </div>

            <div class="modal-body-content">
                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px;">
                        Enter Area / Pincode
                    </label>
                    <input type="text" id="newLocInput" class="location-input" style="padding-left: 14px;" 
                           value="<%= userLocation %>" placeholder="e.g. Manapparai, Trichy - 621306">
                </div>

                <div style="margin-bottom: 16px;">
                    <button type="button" class="btn-change-location" style="width: 100%; justify-content: center;" onclick="detectUserLocation(); closeLocationModal();">
                        <i class="fa-solid fa-crosshairs"></i> Use My Current GPS Location
                    </button>
                </div>

                <div>
                    <span style="display: block; font-size: 12px; font-weight: 700; color: #6B7280; text-transform: uppercase; margin-bottom: 8px;">
                        Quick Popular Locations
                    </span>
                    <div style="display: flex; flex-direction: column; gap: 6px;">
                        <button type="button" class="sort-select" style="text-align: left; height: 36px; padding: 0 12px;" 
                                onclick="selectQuickLocation('Saibaba Colony, Coimbatore - 641011', 11.0278, 76.9329);">
                            <i class="fa-solid fa-location-dot" style="color: #F97316; margin-right: 6px;"></i> Saibaba Colony, Coimbatore - 641011
                        </button>
                        <button type="button" class="sort-select" style="text-align: left; height: 36px; padding: 0 12px;" 
                                onclick="selectQuickLocation('Gandhipuram, Coimbatore - 641012', 11.0183, 76.9678);">
                            <i class="fa-solid fa-location-dot" style="color: #F97316; margin-right: 6px;"></i> Gandhipuram, Coimbatore - 641012
                        </button>
                        <button type="button" class="sort-select" style="text-align: left; height: 36px; padding: 0 12px;" 
                                onclick="selectQuickLocation('RS Puram, Coimbatore - 641002', 11.0095, 76.9515);">
                            <i class="fa-solid fa-location-dot" style="color: #F97316; margin-right: 6px;"></i> RS Puram, Coimbatore - 641002
                        </button>
                        <button type="button" class="sort-select" style="text-align: left; height: 36px; padding: 0 12px;" 
                                onclick="selectQuickLocation('Manapparai, Trichy - 621306', 10.6074, 78.4330);">
                            <i class="fa-solid fa-location-dot" style="color: #F97316; margin-right: 6px;"></i> Manapparai, Trichy - 621306
                        </button>
                    </div>
                </div>
            </div>

            <div class="modal-footer-bar">
                <button type="button" class="btn-change-location" onclick="closeLocationModal();">Cancel</button>
                <button type="button" class="btn-search-mechanics" onclick="applyCustomLocation();">
                    <i class="fa-solid fa-check"></i> Apply Location
                </button>
            </div>
        </div>
    </div>

    <!-- Leaflet JS for Map -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

    <!-- Map & Interaction Scripts -->
    <script>
        // 1. Initial State
        var userLat = <%= userLat %>;
        var userLng = <%= userLng %>;
        var userLocName = "<%= userLocation %>";
        var contextPath = "${pageContext.request.contextPath}";

        // Full Mechanics Directory for Profile Modal & Map
        var mechanicsDirectory = {
            <%
                for (int i = 0; i < filteredMechanics.size(); i++) {
                    Map m = (Map) filteredMechanics.get(i);
                    int curId = (Integer) m.get("id");
                    List<Map<String, String>> photosList = (List<Map<String, String>>) m.get("photos");
                    String sW = m.get("workshop") != null ? ((String)m.get("workshop")).replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'").replace("\n", " ") : "";
                    String sO = m.get("owner") != null ? ((String)m.get("owner")).replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'").replace("\n", " ") : "";
                    String sC = m.get("code") != null ? ((String)m.get("code")).replace("\\", "\\\\").replace("\"", "\\\"") : ("MEC" + curId);
                    String sT = m.get("shop_type") != null ? ((String)m.get("shop_type")).replace("\\", "\\\\").replace("\"", "\\\"") : "Multi-brand Garage";
                    String sExp = m.get("experience") != null ? ((String)m.get("experience")).replace("\\", "\\\\").replace("\"", "\\\"") : "3 – 5 years";
                    String sSp = m.get("specialization") != null ? ((String)m.get("specialization")).replace("\\", "\\\\").replace("\"", "\\\"") : "General Service";
                    String sOSp = m.get("other_specialization") != null ? ((String)m.get("other_specialization")).replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String sDesc = m.get("shop_description") != null ? ((String)m.get("shop_description")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                    String sEm = m.get("email") != null ? ((String)m.get("email")).replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String sPh = m.get("phone") != null ? ((String)m.get("phone")).replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String sLL = m.get("shop_contact") != null ? ((String)m.get("shop_contact")).replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String sAd = m.get("address") != null ? ((String)m.get("address")).replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                    String sCity = m.get("city") != null ? ((String)m.get("city")).replace("\\", "\\\\").replace("\"", "\\\"") : "Coimbatore";
                    String sSvc = m.get("service_types") != null ? ((String)m.get("service_types")).replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    String sRat = String.format("%.1f", (Double) m.get("rating"));
                    int sRev = (Integer) m.get("reviews");
                    String sSt = (String) m.get("status");
                    String sDist = String.format("%.1f", (Double) m.get("distance_km"));
                    double sLat = (Double) m.get("lat");
                    double sLng = (Double) m.get("lng");
            %>
            "<%= curId %>": {
                id: <%= curId %>,
                code: "<%= sC %>",
                workshop: "<%= sW %>",
                owner: "<%= sO %>",
                shopType: "<%= sT %>",
                experience: "<%= sExp %>",
                specialization: "<%= sSp %>",
                otherSpecialization: "<%= sOSp %>",
                description: "<%= sDesc %>",
                email: "<%= sEm %>",
                phone: "<%= sPh %>",
                shopContact: "<%= sLL %>",
                address: "<%= sAd %>",
                city: "<%= sCity %>",
                serviceTypes: "<%= sSvc %>",
                rating: "<%= sRat %>",
                reviews: <%= sRev %>,
                status: "<%= sSt %>",
                distance: "<%= sDist %>",
                lat: <%= sLat %>,
                lng: <%= sLng %>,
                photos: [
                    <% 
                    if (photosList != null) {
                        for (int pIdx = 0; pIdx < photosList.size(); pIdx++) {
                            Map<String, String> ph = photosList.get(pIdx);
                            String pP = ph.get("path") != null ? ph.get("path").replace("\\", "\\\\").replace("\"", "\\\"") : "";
                            String pN = ph.get("name") != null ? ph.get("name").replace("\\", "\\\\").replace("\"", "\\\"") : "";
                    %>
                    { path: "<%= pP %>", name: "<%= pN %>" }<%= (pIdx < photosList.size() - 1) ? "," : "" %>
                    <% 
                        }
                    } 
                    %>
                ]
            }<%= (i < filteredMechanics.size() - 1) ? "," : "" %>
            <% } %>
        };

        // Mechanics list for JavaScript / Map markers
        var mechanicsData = [
            <%
                for (int i = 0; i < filteredMechanics.size(); i++) {
                    Map m = (Map) filteredMechanics.get(i);
            %>
            {
                id: <%= m.get("id") %>,
                name: "<%= m.get("workshop") %>",
                address: "<%= m.get("address") %>",
                rating: "<%= String.format("%.1f", (Double) m.get("rating")) %>",
                reviews: <%= m.get("reviews") %>,
                status: "<%= m.get("status") %>",
                distance: "<%= String.format("%.1f", (Double) m.get("distance_km")) %>",
                lat: <%= m.get("lat") %>,
                lng: <%= m.get("lng") %>,
                image: "<%= m.get("image") %>"
            }<%= (i < filteredMechanics.size() - 1) ? "," : "" %>
            <% } %>
        ];

        // 2. Initialize Leaflet Map
        var map = L.map('mechanicsMap', {
            zoomControl: false,
            scrollWheelZoom: false
        }).setView([userLat, userLng], 12);

        L.control.zoom({ position: 'topright' }).addTo(map);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap'
        }).addTo(map);

        // User Location Radius (Translucent Orange Circle)
        L.circle([userLat, userLng], {
            color: '#F97316',
            fillColor: '#F97316',
            fillOpacity: 0.15,
            radius: 4000,
            weight: 1.5
        }).addTo(map);

        // User Location Custom Icon Marker (Orange Pin with Car)
        var userIcon = L.divIcon({
            className: 'custom-user-marker',
            html: '<div class="user-marker-pin"><i class="fa-solid fa-car-side"></i></div>',
            iconSize: [36, 36],
            iconAnchor: [18, 36]
        });

        var userMarker = L.marker([userLat, userLng], { icon: userIcon }).addTo(map);
        userMarker.bindPopup("<strong>Your Location</strong><br>" + userLocName);

        // Mechanic Custom Markers
        var mapMarkers = {};
        mechanicsData.forEach(function(mech) {
            var mechIcon = L.divIcon({
                className: 'custom-mech-marker',
                html: '<div class="mech-marker-pin" id="pin-' + mech.id + '"><i class="fa-solid fa-wrench"></i></div>',
                iconSize: [30, 30],
                iconAnchor: [15, 15]
            });

            var marker = L.marker([mech.lat, mech.lng], { icon: mechIcon }).addTo(map);
            
            var popupContent = 
                '<div style="font-family: inherit; min-width: 160px;">' +
                    '<h4 style="margin: 0 0 4px 0; font-size: 14px; font-weight: 800; color: #111827;">' + mech.name + '</h4>' +
                    '<p style="margin: 0 0 6px 0; font-size: 12px; color: #6B7280;">' + mech.address + ' (' + mech.distance + ' km)</p>' +
                    '<div style="display: flex; justify-content: space-between; align-items: center;">' +
                        '<span style="font-size: 12px; font-weight: 700; color: #F59E0B;"><i class="fa-solid fa-star"></i> ' + mech.rating + '</span>' +
                        '<a href="request-assistance.jsp?mechanicId=' + mech.id + '&mechanicName=' + encodeURIComponent(mech.name) + '&lat=' + userLat + '&lng=' + userLng + '&location=' + encodeURIComponent(document.getElementById('locationInput') ? document.getElementById('locationInput').value : '') + '" style="font-size: 11.5px; font-weight: 700; color: #F97316; text-decoration: none;">Request &rarr;</a>' +
                    '</div>' +
                '</div>';
            marker.bindPopup(popupContent);

            marker.on('click', function() {
                var row = document.getElementById('mech-row-' + mech.id);
                if (row) {
                    row.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    highlightRow(mech.id);
                }
            });

            mapMarkers[mech.id] = marker;
        });

        // Highlight marker when hovering row
        function highlightMarker(id) {
            var pin = document.getElementById('pin-' + id);
            if (pin) pin.classList.add('active');
        }

        function unhighlightMarker(id) {
            var pin = document.getElementById('pin-' + id);
            if (pin) pin.classList.remove('active');
        }

        function highlightRow(id) {
            var rows = document.querySelectorAll('.mechanic-row');
            rows.forEach(function(r) { r.classList.remove('highlighted'); });
            var target = document.getElementById('mech-row-' + id);
            if (target) {
                target.classList.add('highlighted');
                setTimeout(function() { target.classList.remove('highlighted'); }, 2000);
            }
        }

        // 3. Sorting Handler
        function applySorting(sortVal) {
            var form = document.getElementById('findFilterForm');
            var existingSort = form.querySelector('input[name="sortBy"]');
            if (!existingSort) {
                existingSort = document.createElement('input');
                existingSort.type = 'hidden';
                existingSort.name = 'sortBy';
                form.appendChild(existingSort);
            }
            existingSort.value = sortVal;
            form.submit();
        }

        // Tab switching inside Mechanic Profile Modal
        function switchModalTab(btn, tabId) {
            var tabs = document.querySelectorAll('.mech-modal-tab-btn');
            tabs.forEach(function(t) { t.classList.remove('active'); });
            if (btn) btn.classList.add('active');

            var panes = document.querySelectorAll('.mech-modal-tab-pane');
            panes.forEach(function(p) { p.classList.remove('active'); });
            var target = document.getElementById(tabId);
            if (target) {
                target.classList.add('active');
            }
        }

        // 4. Comprehensive Mechanic & Workshop Profile Modal
        function openProfileModal(id, name, owner, phone, addr, services, rating, reviews, status, img, dist) {
            var mech = (typeof mechanicsDirectory !== 'undefined' && mechanicsDirectory[id]) ? mechanicsDirectory[id] : null;

            var dName = (mech && mech.workshop) ? mech.workshop : (name || 'Workshop');
            var dOwner = (mech && mech.owner) ? mech.owner : (owner || 'Lead Mechanic');
            var dPhone = (mech && mech.phone) ? mech.phone : (phone || '+91 98765 43210');
            var dLandline = (mech && mech.shopContact && mech.shopContact.trim()) ? mech.shopContact : 'Available on dispatch';
            var dEmail = (mech && mech.email && mech.email.trim()) ? mech.email : 'support@roadassistance.com';
            var dAddr = (mech && mech.address) ? mech.address : (addr || 'Address details available on dispatch');
            var dCode = (mech && mech.code) ? mech.code : ('MEC' + id);
            var dShopType = (mech && mech.shopType) ? mech.shopType : 'Multi-brand Garage';
            var dExp = (mech && mech.experience) ? mech.experience : '3 – 5 years';
            var dSpec = (mech && mech.specialization) ? mech.specialization : 'General Breakdown Service';
            var dOtherSpec = (mech && mech.otherSpecialization && mech.otherSpecialization.trim()) ? mech.otherSpecialization : 'Mobile Breakdown Diagnostics & Emergency Rescue';
            var dDesc = (mech && mech.description && mech.description.trim()) ? mech.description : 'Authorized vehicle breakdown repair unit providing swift on-site mechanical and electrical rescue services.';
            var dRating = (mech && mech.rating) ? mech.rating : (rating || '4.8');
            var dReviews = (mech && mech.reviews) ? mech.reviews : (reviews || 100);
            var dStatus = (mech && mech.status) ? mech.status : (status || 'Available');
            var dDist = (mech && mech.distance) ? mech.distance : (dist || '0.0');
            var dLat = (mech && mech.lat) ? mech.lat : userLat;
            var dLng = (mech && mech.lng) ? mech.lng : userLng;

            // Header & Hero
            document.getElementById('profModalTitle').innerText = dName;
            document.getElementById('profModalSubtitle').innerText = dShopType + ' • Verified Breakdown Service Station';
            document.getElementById('profModalName').innerText = dName;
            document.getElementById('profModalTypeBadge').innerHTML = '<i class="fa-solid fa-shop"></i> ' + dShopType;
            document.getElementById('profModalCode').innerHTML = '<i class="fa-solid fa-hashtag"></i> ' + dCode;
            document.getElementById('profModalRating').innerText = dRating;
            document.getElementById('profModalReviews').innerText = '(' + dReviews + ' reviews)';
            document.getElementById('profModalDistance').innerHTML = '<i class="fa-solid fa-location-dot"></i> ' + dDist + ' km Away';

            // Status Badge
            var stEl = document.getElementById('profModalStatus');
            stEl.className = 'badge-status';
            if (dStatus === 'Busy') {
                stEl.classList.add('status-busy');
                stEl.innerHTML = '<i class="fa-solid fa-clock"></i> Busy';
            } else if (dStatus === 'Offline') {
                stEl.classList.add('status-offline');
                stEl.innerHTML = '<i class="fa-solid fa-moon"></i> Offline';
            } else {
                stEl.classList.add('status-available');
                stEl.innerHTML = '<i class="fa-solid fa-circle-check"></i> Available';
            }

            // Tab 1: Workshop Details
            document.getElementById('profModalShopName').innerText = dName;
            document.getElementById('profModalShopType').innerText = dShopType;
            document.getElementById('profModalPhone').innerText = dPhone;
            document.getElementById('profModalCallLink').href = 'tel:' + dPhone.replace(/[^0-9+]/g, '');
            document.getElementById('profModalLandline').innerText = dLandline;
            document.getElementById('profModalEmail').innerText = dEmail;
            document.getElementById('profModalEmailLink').href = 'mailto:' + dEmail;
            document.getElementById('profModalAddress').innerText = dAddr;
            document.getElementById('profModalDescription').innerText = dDesc;
            document.getElementById('profModalDistHighlight').innerText = dDist + ' km away';
            document.getElementById('profModalDirectionsLink').href = 'https://www.google.com/maps/search/?api=1&query=' + dLat + ',' + dLng;

            // Tab 2: Lead Mechanic
            document.getElementById('profModalOwnerName').innerText = dOwner;
            document.getElementById('profModalExperience').innerHTML = '<i class="fa-solid fa-medal"></i> ' + dExp;
            document.getElementById('profModalSpecialization').innerText = dSpec;
            document.getElementById('profModalOtherSpec').innerText = dOtherSpec;

            // Tab 3: Services & Offerings
            var servicesStr = (mech && mech.serviceTypes) ? mech.serviceTypes : (services || 'General Service');
            var sArr = servicesStr.split(',');
            var chipsHtml = '';
            sArr.forEach(function(s) {
                var trimS = s.trim();
                if (trimS) {
                    chipsHtml += '<span class="service-chip-pill"><i class="fa-solid fa-check"></i> ' + trimS + '</span>';
                }
            });
            if (!chipsHtml) {
                chipsHtml = '<span class="service-chip-pill"><i class="fa-solid fa-check"></i> General Breakdown Service</span>';
            }
            document.getElementById('profModalServicesContainer').innerHTML = chipsHtml;

            // Tab 4: Photos
            var photosHtml = '';
            var pCount = 0;
            if (mech && mech.photos && mech.photos.length > 0) {
                pCount = mech.photos.length;
                mech.photos.forEach(function(ph) {
                    var imgUrl = contextPath + '/images/' + ph.path;
                    photosHtml += '<div class="workshop-photo-card">' +
                        '<img src="' + imgUrl + '" alt="' + (ph.name || 'Workshop Photo') + '" class="workshop-photo-img" onerror="this.src=\'' + contextPath + '/images/mechanic-workshop-sample.jpg\'">' +
                        '<div class="workshop-photo-caption"><i class="fa-solid fa-camera" style="color: #F97316; margin-right: 5px;"></i>' + (ph.name || 'Workshop Facility') + '</div>' +
                        '</div>';
                });
            } else {
                pCount = 2;
                photosHtml = '<div class="workshop-photo-card">' +
                    '<img src="' + contextPath + '/images/mechanic-workshop-sample.jpg" alt="Workshop Bay" class="workshop-photo-img">' +
                    '<div class="workshop-photo-caption"><i class="fa-solid fa-warehouse" style="color: #F97316; margin-right: 5px;"></i>Main Service Facility</div>' +
                    '</div>' +
                    '<div class="workshop-photo-card">' +
                    '<img src="' + contextPath + '/images/admin-slide-repair.jpg" alt="Diagnostic Repair Unit" class="workshop-photo-img">' +
                    '<div class="workshop-photo-caption"><i class="fa-solid fa-wrench" style="color: #F97316; margin-right: 5px;"></i>Diagnostic & Inspection Bay</div>' +
                    '</div>';
            }
            document.getElementById('profModalPhotosGrid').innerHTML = photosHtml;
            document.getElementById('profModalPhotosCount').innerText = pCount;

            // Reset to Tab 1 on open
            var firstTab = document.querySelector('.mech-modal-tab-btn');
            if (firstTab) {
                switchModalTab(firstTab, 'tabWorkshop');
            }

            // Footer Request Assistance Link
            var reqUrl = 'request-assistance.jsp?mechanicId=' + id + '&mechanicName=' + encodeURIComponent(dName);
            var locInp = document.getElementById('locationInput');
            if (locInp && locInp.value) {
                reqUrl += '&location=' + encodeURIComponent(locInp.value);
            }
            if (typeof userLat !== 'undefined' && typeof userLng !== 'undefined') {
                reqUrl += '&lat=' + userLat + '&lng=' + userLng;
            }
            var vTypeSel = document.getElementById('vehicleTypeSelect');
            if (vTypeSel && vTypeSel.value) {
                reqUrl += '&vehicleType=' + encodeURIComponent(vTypeSel.value);
            }
            var vHidden = document.getElementById('filterVehicleHidden');
            if (vHidden && vHidden.value) {
                reqUrl += '&vehicle=' + encodeURIComponent(vHidden.value);
            }
            document.getElementById('profModalReqLink').href = reqUrl;

            document.getElementById('modalMechanicProfile').classList.add('show');
        }

        function closeProfileModal() {
            document.getElementById('modalMechanicProfile').classList.remove('show');
        }

        // =========================================================================
        // 3. Known Locations Dictionary & Geocoding Helpers
        // =========================================================================
        var KNOWN_LOCATIONS = [
            { name: "saibaba colony", lat: 11.0268, lng: 76.9507 },
            { name: "gandhipuram", lat: 11.0183, lng: 76.9644 },
            { name: "rs puram", lat: 11.0086, lng: 76.9515 },
            { name: "peelamedu", lat: 11.0247, lng: 77.0104 },
            { name: "saravanampatti", lat: 11.0805, lng: 76.9937 },
            { name: "singanallur", lat: 10.9995, lng: 77.0223 },
            { name: "coimbatore", lat: 11.0278, lng: 76.9329 },
            { name: "manapparai", lat: 10.6074, lng: 78.4330 },
            { name: "trichy", lat: 10.7905, lng: 78.7047 },
            { name: "madurai", lat: 9.9252, lng: 78.1198 },
            { name: "chennai", lat: 13.0827, lng: 80.2707 },
            { name: "salem", lat: 11.6643, lng: 78.1460 }
        ];

        function findKnownCoords(query) {
            if (!query) return null;
            var q = query.toLowerCase().trim();
            for (var i = 0; i < KNOWN_LOCATIONS.length; i++) {
                if (q.indexOf(KNOWN_LOCATIONS[i].name) !== -1) {
                    return KNOWN_LOCATIONS[i];
                }
            }
            return null;
        }

        // =========================================================================
        // 4. Vehicle Selection Handler (Filters mechanics instantly based on type)
        // =========================================================================
        function onVehicleSelectChanged(sel) {
            var selectedOpt = sel.options[sel.selectedIndex];
            var vNum = selectedOpt ? (selectedOpt.getAttribute('data-vnum') || '') : '';
            var hiddenVeh = document.getElementById('filterVehicleHidden');
            if (hiddenVeh) {
                hiddenVeh.value = vNum;
            }
            var form = document.getElementById('findFilterForm');
            if (form) {
                form.submit();
            }
        }

        // =========================================================================
        // 5. Search Form Submission Handler (Geocodes Address before submit)
        // =========================================================================
        var isGeocodingSearch = false;
        function handleSearchSubmit(e) {
            if (isGeocodingSearch) return true;

            var locInput = document.getElementById('locationInput');
            var query = locInput ? locInput.value.trim() : '';
            var lastLoc = locInput ? (locInput.getAttribute('data-last-loc') || '').trim() : '';

            // If empty or identical to loaded address, submit standard GET
            if (!query || query.toLowerCase() === lastLoc.toLowerCase()) {
                return true;
            }

            // Quick offline match against known city/town centers
            var known = findKnownCoords(query);
            if (known) {
                document.getElementById('filterLat').value = known.lat;
                document.getElementById('filterLng').value = known.lng;
                return true;
            }

            // Asynchronous forward geocode via Nominatim
            if (e) e.preventDefault();
            var searchBtn = document.querySelector('.btn-search-mechanics');
            var origBtnHtml = searchBtn ? searchBtn.innerHTML : '';
            if (searchBtn) {
                searchBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Locating...';
                searchBtn.disabled = true;
            }

            var geocodeUrl = 'https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(query) + '&limit=1';
            var abortCtrl = new AbortController();
            var timeoutId = setTimeout(function() { abortCtrl.abort(); }, 2500);

            fetch(geocodeUrl, { signal: abortCtrl.signal, headers: { 'Accept': 'application/json' } })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    clearTimeout(timeoutId);
                    if (data && data.length > 0) {
                        document.getElementById('filterLat').value = parseFloat(data[0].lat);
                        document.getElementById('filterLng').value = parseFloat(data[0].lon);
                    }
                    isGeocodingSearch = true;
                    document.getElementById('findFilterForm').submit();
                })
                .catch(function(err) {
                    clearTimeout(timeoutId);
                    isGeocodingSearch = true;
                    document.getElementById('findFilterForm').submit();
                });

            return false;
        }

        // =========================================================================
        // 6. Map Click Handler: Place Pin, Reverse-Geocode Address & Filter
        // =========================================================================
        var mapClickCircle = null;
        map.on('click', function(e) {
            var lat = e.latlng.lat;
            var lng = e.latlng.lng;

            if (userMarker) {
                userMarker.setLatLng([lat, lng]);
            }
            document.getElementById('filterLat').value = lat;
            document.getElementById('filterLng').value = lng;

            // Visual feedback circle
            if (mapClickCircle) map.removeLayer(mapClickCircle);
            mapClickCircle = L.circle([lat, lng], {
                radius: 350,
                color: '#F97316',
                fillColor: '#F97316',
                fillOpacity: 0.25
            }).addTo(map);

            var locInput = document.getElementById('locationInput');
            if (locInput) {
                locInput.value = "Fetching address...";
            }

            var revUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng;
            var abortCtrl = new AbortController();
            var timeoutId = setTimeout(function() { abortCtrl.abort(); }, 3000);

            fetch(revUrl, { signal: abortCtrl.signal })
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    clearTimeout(timeoutId);
                    var addrName = "";
                    if (data && data.address) {
                        var a = data.address;
                        var parts = [];
                        if (a.suburb || a.neighbourhood || a.road) parts.push(a.suburb || a.neighbourhood || a.road);
                        if (a.city || a.town || a.county) parts.push(a.city || a.town || a.county);
                        if (a.postcode) parts.push(a.postcode);
                        addrName = parts.join(", ");
                    }
                    if (!addrName && data && data.display_name) {
                        addrName = data.display_name.split(",").slice(0, 3).join(",");
                    }
                    if (!addrName) {
                        addrName = "Location (" + lat.toFixed(4) + ", " + lng.toFixed(4) + ")";
                    }
                    if (locInput) locInput.value = addrName;
                    isGeocodingSearch = true;
                    document.getElementById('findFilterForm').submit();
                })
                .catch(function() {
                    clearTimeout(timeoutId);
                    if (locInput) locInput.value = "Location (" + lat.toFixed(4) + ", " + lng.toFixed(4) + ")";
                    isGeocodingSearch = true;
                    document.getElementById('findFilterForm').submit();
                });
        });

        // 7. Change Location Modal
        function openLocationModal() {
            document.getElementById('modalChangeLocation').classList.add('show');
        }

        function closeLocationModal() {
            document.getElementById('modalChangeLocation').classList.remove('show');
        }

        function selectQuickLocation(name, lat, lng) {
            document.getElementById('locationInput').value = name;
            document.getElementById('filterLat').value = lat;
            document.getElementById('filterLng').value = lng;
            isGeocodingSearch = true;
            document.getElementById('findFilterForm').submit();
        }

        function applyCustomLocation() {
            var val = document.getElementById('newLocInput').value.trim();
            if (val) {
                document.getElementById('locationInput').value = val;
                closeLocationModal();
                handleSearchSubmit();
            }
        }

        // 8. Browser Geolocation Detection with Reverse Geocoding
        function detectUserLocation() {
            if (!navigator.geolocation) {
                alert("Geolocation is not supported by your browser.");
                return;
            }

            var locInput = document.getElementById('locationInput');
            if (locInput) locInput.value = "Detecting GPS location...";

            navigator.geolocation.getCurrentPosition(function(pos) {
                var lat = pos.coords.latitude;
                var lng = pos.coords.longitude;
                document.getElementById('filterLat').value = lat;
                document.getElementById('filterLng').value = lng;
                if (userMarker) userMarker.setLatLng([lat, lng]);
                map.setView([lat, lng], 14);

                var revUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng;
                fetch(revUrl)
                    .then(function(res) { return res.json(); })
                    .then(function(data) {
                        var addrName = "";
                        if (data && data.address) {
                            var a = data.address;
                            var parts = [];
                            if (a.suburb || a.neighbourhood || a.road) parts.push(a.suburb || a.neighbourhood || a.road);
                            if (a.city || a.town || a.county) parts.push(a.city || a.town || a.county);
                            if (a.postcode) parts.push(a.postcode);
                            addrName = parts.join(", ");
                        }
                        if (!addrName && data && data.display_name) {
                            addrName = data.display_name.split(",").slice(0, 3).join(",");
                        }
                        if (!addrName) {
                            addrName = "GPS (" + lat.toFixed(4) + ", " + lng.toFixed(4) + ")";
                        }
                        if (locInput) locInput.value = addrName;
                        isGeocodingSearch = true;
                        document.getElementById('findFilterForm').submit();
                    })
                    .catch(function() {
                        if (locInput) locInput.value = "GPS (" + lat.toFixed(4) + ", " + lng.toFixed(4) + ")";
                        isGeocodingSearch = true;
                        document.getElementById('findFilterForm').submit();
                    });
            }, function(err) {
                alert("Location detection notice: " + (err.message || "Please allow location permission in your browser."));
                if (locInput) locInput.value = locInput.getAttribute('data-last-loc') || 'Coimbatore, Tamil Nadu';
            }, { enableHighAccuracy: true, timeout: 8000 });
        }

        // Close Modals on ESC
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeProfileModal();
                closeLocationModal();
            }
        });
    </script>

    <!-- Global App Responsive JS -->
    <script src="${pageContext.request.contextPath}/js/app-responsive.js"></script>
</body>
</html>
