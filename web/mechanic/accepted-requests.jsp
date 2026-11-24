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
<%@ page import="com.roadassistance.model.Mechanic" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%@ page import="com.roadassistance.util.EmailUtil" %>
<%@ page import="com.roadassistance.service.ServiceRequestService" %>
<%!
    // One-Way Step Rank Mapping (Steps advance forward only, cannot go back)
    public static int getStepRank(String status) {
        if (status == null) return 0;
        String s = status.trim().toLowerCase();
        if (s.equals("pending")) return 0;
        if (s.equals("accepted")) return 1;
        if (s.equals("on the way") || s.equals("on_the_way") || s.equals("en route")) return 2;
        if (s.equals("in progress") || s.equals("in_progress") || s.equals("diagnostics done") || s.equals("parts replacement")) return 3;
        if (s.equals("completed")) return 4;
        return 1;
    }
%>
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

    request.setAttribute("activeMechPage", "accepted");

    String mechCode = currentMech.getMechanicCode();
    if (mechCode == null || mechCode.trim().isEmpty()) mechCode = "MEC003";

    String workshopName = currentMech.getWorkshopName();
    if (workshopName == null || workshopName.trim().isEmpty()) {
        workshopName = currentMech.getShopName();
    }
    if (workshopName == null || workshopName.trim().isEmpty()) workshopName = "Kumar Auto Works";

    String ownerName = currentMech.getOwnerName();
    if (ownerName == null || ownerName.trim().isEmpty()) {
        ownerName = currentMech.getFirstName();
    }
    if (ownerName == null || ownerName.trim().isEmpty()) ownerName = "Kumar";

    // 2. Handle Actions: Complete & Update Status (Strict One-Way Step Enforcement)
    String action = request.getParameter("action");
    String targetReqId = request.getParameter("reqId");
    String updateStatusVal = request.getParameter("newStatus");
    String updateNotes = request.getParameter("notes");
    String isAjax = request.getParameter("ajax");

    if (action != null && targetReqId != null && !targetReqId.trim().isEmpty()) {
        targetReqId = targetReqId.trim();
        String targetStatus = null;
        if ("complete".equalsIgnoreCase(action)) {
            targetStatus = "Completed";
        } else if ("update".equalsIgnoreCase(action) && updateStatusVal != null && !updateStatusVal.trim().isEmpty()) {
            targetStatus = updateStatusVal.trim();
        }

        if (targetStatus != null) {
            Connection actionConn = null;
            PreparedStatement actionPs = null;
            ResultSet checkRs = null;
            boolean updateSuccess = false;
            String errorMessage = null;
            int newRank = getStepRank(targetStatus);
            int currentRank = 0;
            String currentDbStatus = "Accepted";

            try {
                actionConn = DBConnection.getConnection();
                if (actionConn != null) {
                    // Fetch current status from database to strictly enforce one-way progression
                    PreparedStatement checkPs = actionConn.prepareStatement("SELECT status FROM service_requests WHERE (request_code = ? OR request_id = ?)");
                    checkPs.setString(1, targetReqId);
                    int parsedId = 0;
                    try { parsedId = Integer.parseInt(targetReqId); } catch (Exception ignored) {}
                    checkPs.setInt(2, parsedId);
                    checkRs = checkPs.executeQuery();
                    if (checkRs.next()) {
                        currentDbStatus = checkRs.getString("status");
                        if (currentDbStatus != null) {
                            currentRank = getStepRank(currentDbStatus);
                        }
                    }
                    checkRs.close();
                    checkPs.close();

                    // Stagnant / Auto-cancelled check or ONE-WAY RULE
                    if ("Cancelled".equalsIgnoreCase(currentDbStatus) || "Rejected".equalsIgnoreCase(currentDbStatus)) {
                        updateSuccess = false;
                        errorMessage = "This request was auto-cancelled due to lack of progression within the required timeframe and cannot be updated. The user has been intimated to re-request.";
                    } else if (newRank <= currentRank) {
                        updateSuccess = false;
                        errorMessage = "One-Way Process Violation: Status updates can only advance forward. Cannot move back from '" + currentDbStatus + "' to '" + targetStatus + "'.";
                    } else {
                        String updateSql;
                        if ("Completed".equalsIgnoreCase(targetStatus)) {
                            if (updateNotes != null && !updateNotes.trim().isEmpty()) {
                                updateSql = "UPDATE service_requests SET status = ?, completed_at = CURRENT_TIMESTAMP(), completed_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'), in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), additional_details = CONCAT(IFNULL(additional_details,''), ' | [Update: ', ?, ']') WHERE (request_code = ? OR request_id = ?)";
                                actionPs = actionConn.prepareStatement(updateSql);
                                actionPs.setString(1, targetStatus);
                                actionPs.setString(2, updateNotes.trim());
                                actionPs.setString(3, targetReqId);
                                actionPs.setInt(4, parsedId);
                            } else {
                                updateSql = "UPDATE service_requests SET status = ?, completed_at = CURRENT_TIMESTAMP(), completed_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'), in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')) WHERE (request_code = ? OR request_id = ?)";
                                actionPs = actionConn.prepareStatement(updateSql);
                                actionPs.setString(1, targetStatus);
                                actionPs.setString(2, targetReqId);
                                actionPs.setInt(3, parsedId);
                            }
                        } else {
                            if (updateNotes != null && !updateNotes.trim().isEmpty()) {
                                updateSql = "UPDATE service_requests SET status = ?, in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), additional_details = CONCAT(IFNULL(additional_details,''), ' | [Update: ', ?, ']') WHERE (request_code = ? OR request_id = ?)";
                                actionPs = actionConn.prepareStatement(updateSql);
                                actionPs.setString(1, targetStatus);
                                actionPs.setString(2, updateNotes.trim());
                                actionPs.setString(3, targetReqId);
                                actionPs.setInt(4, parsedId);
                            } else {
                                updateSql = "UPDATE service_requests SET status = ?, in_progress_at = COALESCE(in_progress_at, CURRENT_TIMESTAMP()), in_progress_date = COALESCE(in_progress_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')), assigned_at = COALESCE(assigned_at, CURRENT_TIMESTAMP()), assigned_date = COALESCE(assigned_date, DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p')) WHERE (request_code = ? OR request_id = ?)";
                                actionPs = actionConn.prepareStatement(updateSql);
                                actionPs.setString(1, targetStatus);
                                actionPs.setString(2, targetReqId);
                                actionPs.setInt(3, parsedId);
                            }
                        }

                        int rowsUpdated = actionPs.executeUpdate();
                        updateSuccess = (rowsUpdated > 0);
                        if (updateSuccess) {
                            EmailUtil.notifyUserOfRequestStatusUpdateAsync(targetReqId, targetStatus, updateNotes);
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                errorMessage = e.getMessage();
            } finally {
                if (actionPs != null) try { actionPs.close(); } catch (Exception ignored) {}
                if (actionConn != null) try { actionConn.close(); } catch (Exception ignored) {}
            }

            if ("true".equalsIgnoreCase(isAjax)) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                String errJson = (errorMessage != null) ? "\"" + errorMessage.replace("\"", "\\\"").replace("\n", " ") + "\"" : "null";
                out.print("{\"success\": " + updateSuccess + ", \"error\": " + errJson + ", \"action\": \"" + action + "\", \"reqId\": \"" + targetReqId + "\", \"newStatus\": \"" + targetStatus + "\", \"newRank\": " + newRank + "}");
                return;
            } else {
                if (updateSuccess) {
                    response.sendRedirect("accepted-requests.jsp?msg=" + action + "&reqId=" + targetReqId);
                } else {
                    String errParam = (errorMessage != null) ? java.net.URLEncoder.encode(errorMessage, "UTF-8") : "update_failed";
                    response.sendRedirect("accepted-requests.jsp?error=" + errParam + "&reqId=" + targetReqId);
                }
                return;
            }
        }
    }

    // 3. Read Search, Filter & Pagination Parameters
    String search = request.getParameter("search");
    if (search != null) search = search.trim(); else search = "";

    String serviceIssueFilter = request.getParameter("serviceIssue");
    if (serviceIssueFilter != null) serviceIssueFilter = serviceIssueFilter.trim(); else serviceIssueFilter = "";

    String sortOrder = request.getParameter("sort");
    if (sortOrder != null) sortOrder = sortOrder.trim(); else sortOrder = "newest";

    String pageParam = request.getParameter("page");
    int currentPage = 1;
    if (pageParam != null && !pageParam.trim().isEmpty()) {
        try { currentPage = Integer.parseInt(pageParam.trim()); } catch (Exception ignored) {}
    }
    if (currentPage < 1) currentPage = 1;
    int pageSize = 10; // Exactly 10 rows per page

    String msg = request.getParameter("msg");
    String msgReqId = request.getParameter("reqId");

    // Dynamic Current Date Display
    SimpleDateFormat sdfDisplayDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDisplayDate.format(new Date());

    // 4. Database Queries: Statistics & Accepted List
    int totalRequests = 0;
    int pendingRequests = 0;
    int acceptedRequests = 0;
    int completedRequests = 0;
    int rejectedRequests = 0;

    List allAcceptedList = new ArrayList();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getConnection();
        if (conn != null) {

            // 0. Auto-cancel any stagnant accepted requests that did not advance in time
            try {
                ServiceRequestService.autoCancelStagnantAcceptedRequests(conn, 15);
            } catch (Exception eAuto) {
                System.err.println("Notice in mechanic accepted-requests autoCancel: " + eAuto.getMessage());
            }

            // A. Statistics Query (Counts all active non-completed accepted stages)
            try {
                String statsSql = "SELECT " +
                        "COUNT(*) AS total_cnt, " +
                        "SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_cnt, " +
                        "SUM(CASE WHEN status IN ('Accepted', 'On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement') THEN 1 ELSE 0 END) AS accepted_cnt, " +
                        "SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_cnt, " +
                        "SUM(CASE WHEN status = 'Rejected' OR status = 'Cancelled' THEN 1 ELSE 0 END) AS rejected_cnt " +
                        "FROM service_requests " +
                        "WHERE ((mechanic_code = ? OR mechanic_name = ? OR mechanic_name LIKE ?) " +
                        "   OR (status = 'Pending' AND (mechanic_code IS NULL OR mechanic_code = '' OR mechanic_name = 'Unassigned' OR mechanic_name IS NULL OR mechanic_name = '')))";
                ps = conn.prepareStatement(statsSql);
                ps.setString(1, mechCode);
                ps.setString(2, workshopName);
                ps.setString(3, "%" + workshopName + "%");
                rs = ps.executeQuery();
                if (rs.next()) {
                    totalRequests = rs.getInt("total_cnt");
                    pendingRequests = rs.getInt("pending_cnt");
                    acceptedRequests = rs.getInt("accepted_cnt");
                    completedRequests = rs.getInt("completed_cnt");
                    rejectedRequests = rs.getInt("rejected_cnt");
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }

            // B. Filtered Accepted Requests Query (Status in all active stages prior to Completed)
            StringBuilder querySql = new StringBuilder(
                "SELECT sr.request_id, sr.request_code, sr.user_id, sr.user_name, sr.vehicle_number, sr.breakdown_issue, sr.location, sr.requested_date, sr.status, sr.additional_details, " +
                "       COALESCE(NULLIF(sr.vehicle_brand, ''), uv.vehicle_brand, '') AS vehicle_brand, " +
                "       COALESCE(NULLIF(sr.vehicle_model, ''), uv.vehicle_model, 'Vehicle') AS vehicle_model, " +
                "       COALESCE(NULLIF(sr.vehicle_type, ''), uv.vehicle_type, 'Car') AS vehicle_type, " +
                "       COALESCE(NULLIF(sr.vehicle_image, ''), uv.vehicle_image, '') AS vehicle_image, " +
                "       (SELECT u.phone FROM users u WHERE u.user_id = sr.user_id OR u.full_name = sr.user_name LIMIT 1) AS customer_phone " +
                "FROM service_requests sr " +
                "LEFT JOIN user_vehicles uv ON REPLACE(REPLACE(UPPER(sr.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(uv.vehicle_number), ' ', ''), '-', '') " +
                "WHERE (sr.mechanic_code = ? OR sr.mechanic_name = ? OR sr.mechanic_name LIKE ?) " +
                "  AND sr.status IN ('Accepted', 'On The Way', 'In Progress', 'Diagnostics Done', 'Parts Replacement')"
            );

            List params = new ArrayList();
            params.add(mechCode);
            params.add(workshopName);
            params.add("%" + workshopName + "%");

            if (!search.isEmpty()) {
                querySql.append(" AND (sr.request_code LIKE ? OR sr.vehicle_number LIKE ? OR sr.location LIKE ? OR sr.breakdown_issue LIKE ? OR sr.user_name LIKE ?)");
                String sParam = "%" + search + "%";
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
                params.add(sParam);
            }

            if (!serviceIssueFilter.isEmpty() && !"all".equalsIgnoreCase(serviceIssueFilter)) {
                querySql.append(" AND sr.breakdown_issue LIKE ?");
                params.add("%" + serviceIssueFilter + "%");
            }

            // Ordering: Seeded rows are chronologically sorted ascending by request_id
            if ("oldest".equalsIgnoreCase(sortOrder)) {
                querySql.append(" ORDER BY sr.request_id DESC");
            } else {
                querySql.append(" ORDER BY sr.request_id ASC");
            }

            try {
                ps = conn.prepareStatement(querySql.toString());
                for (int i = 0; i < params.size(); i++) {
                    ps.setObject(i + 1, params.get(i));
                }

                rs = ps.executeQuery();
                while (rs.next()) {
                    Map row = new HashMap();
                    String reqCode = rs.getString("request_code");
                    if (reqCode == null || reqCode.trim().isEmpty()) {
                        reqCode = "REQ" + (10000 + rs.getInt("request_id"));
                    }
                    row.put("id", rs.getInt("request_id"));
                    row.put("code", reqCode);

                    String vNum = rs.getString("vehicle_number");
                    if (vNum == null || vNum.trim().isEmpty()) vNum = "TN 48 CD 5567";
                    row.put("vehicle", vNum);

                    String issue = rs.getString("breakdown_issue");
                    if (issue == null || issue.trim().isEmpty()) issue = "Battery Jump Start";
                    row.put("issue", issue);

                    String loc = rs.getString("location");
                    if (loc == null || loc.trim().isEmpty()) loc = "Thuraiyur (3.1 km)";
                    row.put("location", loc);

                                        String rDateStr = rs.getString("requested_date");
                    if (rDateStr == null || rDateStr.trim().isEmpty()) {
                        rDateStr = "13-11-2026 • 04:10 PM";
                    }
                    row.put("requested_date", rDateStr);

                    String st = rs.getString("status");
                    if (st == null || st.trim().isEmpty()) st = "In Progress";
                    row.put("status", st);

                    row.put("description", rs.getString("additional_details"));
                    row.put("customer_name", rs.getString("user_name") != null ? rs.getString("user_name") : "Madhavan P");
                    String userPhone = rs.getString("customer_phone");
                    if (userPhone == null || userPhone.trim().isEmpty()) {
                        userPhone = "+91 98765 43210";
                    }
                    row.put("customer_phone", userPhone);

                    // Determine Vehicle Model & Thumbnail Image from Database
                    String vModel = rs.getString("vehicle_model");
                    if (vModel == null || vModel.trim().isEmpty() || "Vehicle".equalsIgnoreCase(vModel.trim())) {
                        String vBrand = rs.getString("vehicle_brand");
                        vModel = (vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle";
                    }
                    String vType = rs.getString("vehicle_type");
                    String vImg = rs.getString("vehicle_image");
                    if (vImg == null || vImg.trim().isEmpty()) {
                        if (vType != null && (vType.equalsIgnoreCase("Bike") || vType.equalsIgnoreCase("Motorcycle") || vType.equalsIgnoreCase("Two Wheeler") || vType.equalsIgnoreCase("Scooter"))) {
                            vImg = (vType.equalsIgnoreCase("Scooter")) ? "vehicle-activa.png" : "vehicle-pulsar-lg.jpg";
                        } else if (vModel != null && vModel.toLowerCase().contains("nexon")) {
                            vImg = "vehicle-nexon.png";
                        } else if (vModel != null && vModel.toLowerCase().contains("brezza")) {
                            vImg = "vehicle-brezza.png";
                        } else {
                            vImg = "vehicle-i20.png";
                        }
                    }
                    row.put("model", vModel);
                    row.put("vehicle_img", vImg);
                    row.put("vehicle_type", vType != null ? vType : "Car");

                    // Determine Service Issue Icon matching reference
                    String issueIcon = "fa-solid fa-car-battery";
                    String lowIssue = issue.toLowerCase();
                    if (lowIssue.contains("battery") || lowIssue.contains("jump")) {
                        issueIcon = "fa-solid fa-car-battery";
                    } else if (lowIssue.contains("tyre") || lowIssue.contains("puncture")) {
                        issueIcon = "fa-solid fa-compact-disc";
                    } else if (lowIssue.contains("general") || lowIssue.contains("service")) {
                        issueIcon = "fa-solid fa-gear";
                    } else if (lowIssue.contains("electrical") || lowIssue.contains("repair")) {
                        issueIcon = "fa-solid fa-bolt";
                    } else if (lowIssue.contains("overheating") || lowIssue.contains("engine")) {
                        issueIcon = "fa-solid fa-cogs";
                    } else if (lowIssue.contains("fuel")) {
                        issueIcon = "fa-solid fa-gas-pump";
                    } else if (lowIssue.contains("clutch") || lowIssue.contains("gear")) {
                        issueIcon = "fa-solid fa-gears";
                    } else if (lowIssue.contains("cooling")) {
                        issueIcon = "fa-solid fa-fan";
                    } else if (lowIssue.contains("oil")) {
                        issueIcon = "fa-solid fa-oil-can";
                    }
                    row.put("issue_icon", issueIcon);

                    // Parse Location and Distance
                    String locName = loc;
                    String locDist = "";
                    if (loc.contains("(") && loc.contains(")")) {
                        int p1 = loc.indexOf("(");
                        int p2 = loc.indexOf(")");
                        locName = loc.substring(0, p1).trim();
                        locDist = loc.substring(p1, p2 + 1).trim();
                    }
                    row.put("loc_name", locName);
                    row.put("loc_dist", locDist);

                    // Parse Date and Time cleanly as dd-MM-yyyy
                    String pDate = "13-11-2026";
                    String pTime = "04:10 PM";
                    if (rDateStr != null && !rDateStr.trim().isEmpty()) {
                        java.util.regex.Matcher dm = java.util.regex.Pattern.compile("(\\d{2}-\\d{2}-\\d{4})").matcher(rDateStr);
                        if (dm.find()) {
                            pDate = dm.group(1);
                        } else {
                            java.util.regex.Matcher dm2 = java.util.regex.Pattern.compile("([A-Za-z]{3}\\s+\\d{1,2},\\s*\\d{4})").matcher(rDateStr);
                            if (dm2.find()) {
                                try {
                                    Date parsed = new SimpleDateFormat("MMM d, yyyy").parse(dm2.group(1));
                                    pDate = new SimpleDateFormat("dd-MM-yyyy").format(parsed);
                                } catch (Exception ign) {
                                    pDate = dm2.group(1);
                                }
                            }
                        }
                        java.util.regex.Matcher tm = java.util.regex.Pattern.compile("(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm))").matcher(rDateStr);
                        if (tm.find()) {
                            pTime = tm.group(1);
                        }
                    }
                    row.put("date_part", pDate);
                    row.put("time_part", pTime);

                    allAcceptedList.add(row);
                }
            } catch (Exception ex) {
                ex.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception ignored) {}
                if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    int totalFilteredAccepted = allAcceptedList.size();
    int totalPages = (totalFilteredAccepted + pageSize - 1) / pageSize;
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;

    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalFilteredAccepted);

    List pageAcceptedList = new ArrayList();
    for (int k = startIndex; k < endIndex; k++) {
        pageAcceptedList.add(allAcceptedList.get(k));
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accepted Requests — Mechanic Portal</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome Icons 6.5.1 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Mechanic Shell & Base Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">

    <!-- Dedicated Accepted Requests Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-accepted-requests.css?v=6.0">

    <!-- Interactive Status Pipeline Embedded Styles (Strict Zero-Blue Automotive Theme) -->
    <style id="ar-interactive-pipeline-styles">
        .ar-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(15, 23, 42, 0.78);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 99999;
            padding: 20px;
            opacity: 0;
            transition: opacity 0.25s ease;
        }
        .ar-modal-overlay.active {
            display: flex !important;
            opacity: 1;
        }
        .ar-modal-card-pipeline {
            background: #FFFFFF;
            width: 800px;
            max-width: 95vw;
            max-height: 92vh;
            border-radius: 24px;
            box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            animation: modalPipelinePop 0.28s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        @keyframes modalPipelinePop {
            0% { transform: scale(0.95) translateY(12px); opacity: 0; }
            100% { transform: scale(1) translateY(0); opacity: 1; }
        }
        .pipeline-modal-header {
            background: linear-gradient(135deg, #111827 0%, #1F2937 100%);
            padding: 18px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
        }
        .pipeline-header-left {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .pipeline-header-icon {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            color: #FFFFFF;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            box-shadow: 0 4px 14px rgba(249, 115, 22, 0.4);
            flex-shrink: 0;
        }
        .pipeline-header-titles h3 {
            margin: 0;
            font-size: 17.5px;
            font-weight: 800;
            color: #FFFFFF;
            letter-spacing: -0.3px;
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .pipeline-ticket-badge {
            display: inline-flex;
            align-items: center;
            padding: 3px 10px;
            border-radius: 999px;
            background: rgba(249, 115, 22, 0.2);
            border: 1px solid rgba(249, 115, 22, 0.5);
            color: #FB923C;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        .pipeline-header-subtitle {
            margin: 3px 0 0 0;
            font-size: 12px;
            color: #94A3B8;
            font-weight: 500;
        }
        .pipeline-btn-close {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.12);
            color: #CBD5E1;
            font-size: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            line-height: 1;
        }
        .pipeline-btn-close:hover {
            background: rgba(239, 68, 68, 0.2);
            color: #EF4444;
            border-color: rgba(239, 68, 68, 0.4);
            transform: rotate(90deg);
        }
        .pipeline-modal-body {
            padding: 16px 22px;
            overflow-y: auto;
            max-height: calc(92vh - 135px);
            display: flex;
            flex-direction: column;
            gap: 12px;
            background: #FAFAFA;
        }
        .pipeline-modal-body::-webkit-scrollbar {
            width: 6px;
        }
        .pipeline-modal-body::-webkit-scrollbar-track {
            background: #F1F5F9;
            border-radius: 999px;
        }
        .pipeline-modal-body::-webkit-scrollbar-thumb {
            background: #CBD5E1;
            border-radius: 999px;
        }
        .pipeline-modal-body::-webkit-scrollbar-thumb:hover {
            background: #94A3B8;
        }
        .pipeline-rule-strip {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 9px 14px;
            background: #FFF7ED;
            border: 1px solid #FED7AA;
            border-left: 4px solid #F97316;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(249, 115, 22, 0.06);
        }
        .pipeline-rule-icon {
            font-size: 16px;
            color: #EA580C;
            flex-shrink: 0;
        }
        .pipeline-rule-text {
            font-size: 11.5px;
            color: #9A3412;
            line-height: 1.4;
        }
        .pipeline-rule-text strong {
            color: #7C2D12;
            font-weight: 700;
        }
        .pipeline-progress-card {
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 14px;
            padding: 13px 18px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
        }
        .pipeline-progress-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .pipeline-progress-title {
            font-size: 11px;
            font-weight: 800;
            letter-spacing: 0.6px;
            color: #64748B;
            text-transform: uppercase;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .pipeline-progress-title i {
            color: #F97316;
        }
        .pipeline-progress-badge {
            background: #FFF7ED;
            color: #EA580C;
            border: 1px solid #FED7AA;
            font-size: 11px;
            font-weight: 700;
            padding: 2px 9px;
            border-radius: 999px;
        }
        .pipeline-progress-track {
            height: 7px;
            background: #E2E8F0;
            border-radius: 999px;
            overflow: hidden;
            position: relative;
            margin-bottom: 14px;
        }
        .pipeline-progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #10B981 0%, #F97316 100%);
            border-radius: 999px;
            transition: width 0.4s ease;
            width: 17%;
        }
        .interactive-stepper-rail {
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: relative;
            padding: 2px 4px 0 4px;
        }
        .stepper-node-wrapper {
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            position: relative;
            z-index: 2;
            cursor: pointer;
            flex: 1;
            max-width: 96px;
            transition: all 0.2s ease;
            user-select: none;
        }
        .stepper-node-circle {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12.5px;
            font-weight: 800;
            background: #FFFFFF;
            border: 2px solid #E2E8F0;
            color: #94A3B8;
            margin-bottom: 5px;
            transition: all 0.25s ease;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
        }
        .stepper-node-name {
            font-size: 10.5px;
            font-weight: 700;
            color: #475569;
            line-height: 1.25;
            margin-bottom: 2px;
        }
        .stepper-node-status {
            font-size: 9px;
            font-weight: 700;
            padding: 1px 5px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        .stepper-connector-line {
            flex: 1;
            height: 3px;
            background: #E2E8F0;
            margin-bottom: 28px;
            z-index: 1;
            transition: background-color 0.3s ease;
        }
        .stepper-connector-line.is-passed {
            background: #10B981;
        }
        .stepper-connector-line.is-active {
            background: linear-gradient(90deg, #10B981 0%, #F97316 100%);
        }
        .stepper-node-wrapper.is-passed .stepper-node-circle {
            background: #10B981;
            border-color: #10B981;
            color: #FFFFFF;
            box-shadow: 0 3px 8px rgba(16, 185, 129, 0.25);
        }
        .stepper-node-wrapper.is-passed .stepper-node-name {
            color: #065F46;
        }
        .stepper-node-wrapper.is-passed .stepper-node-status {
            background: #ECFDF5;
            color: #059669;
        }
        .stepper-node-wrapper.is-current .stepper-node-circle {
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            border: 3px solid #FFEDD5;
            color: #FFFFFF;
            box-shadow: 0 0 0 3px #F97316, 0 4px 12px rgba(249, 115, 22, 0.35);
            animation: pulseRing 2s infinite ease-in-out;
        }
        @keyframes pulseRing {
            0%, 100% { box-shadow: 0 0 0 2px rgba(249, 115, 22, 0.4), 0 4px 10px rgba(249, 115, 22, 0.25); }
            50% { box-shadow: 0 0 0 6px rgba(249, 115, 22, 0.6), 0 4px 14px rgba(249, 115, 22, 0.35); }
        }
        .stepper-node-wrapper.is-current .stepper-node-name {
            color: #EA580C;
            font-weight: 800;
        }
        .stepper-node-wrapper.is-current .stepper-node-status {
            background: #FFF7ED;
            color: #C2410C;
            border: 1px solid #FED7AA;
        }
        .stepper-node-wrapper.is-selected-target .stepper-node-circle {
            background: #FFFFFF;
            border: 3px solid #F97316;
            color: #F97316;
            box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.25);
        }
        .stepper-node-wrapper.is-selected-target .stepper-node-name {
            color: #EA580C;
            font-weight: 800;
        }
        .stepper-node-wrapper.is-selected-target .stepper-node-status {
            background: #FFEDD5;
            color: #C2410C;
            font-weight: 800;
        }
        .stepper-node-wrapper.is-forward:hover {
            transform: translateY(-2px);
        }
        .stepper-node-wrapper.is-forward:hover .stepper-node-circle {
            border-color: #F97316;
            color: #F97316;
        }
        .pipeline-fast-advance-card {
            background: linear-gradient(135deg, #FFF7ED 0%, #FFEDD5 100%);
            border: 1.5px solid #FDBA74;
            border-radius: 14px;
            padding: 11px 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            box-shadow: 0 2px 8px rgba(249, 115, 22, 0.08);
        }
        .fast-advance-left {
            display: flex;
            align-items: center;
            gap: 11px;
        }
        .fast-advance-icon {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            background: #FFFFFF;
            border: 1px solid #FED7AA;
            color: #EA580C;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            box-shadow: 0 2px 6px rgba(249, 115, 22, 0.12);
            flex-shrink: 0;
        }
        .fast-advance-caption {
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
            color: #9A3412;
            letter-spacing: 0.5px;
        }
        .fast-advance-title {
            font-size: 13.5px;
            font-weight: 800;
            color: #7C2D12;
            margin-top: 1px;
        }
        .btn-fast-advance-action {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 8px 16px;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            border: none;
            border-radius: 10px;
            color: #FFFFFF;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            box-shadow: 0 3px 10px rgba(249, 115, 22, 0.3);
            transition: all 0.2s ease;
            white-space: nowrap;
            flex-shrink: 0;
        }
        .btn-fast-advance-action:hover {
            background: linear-gradient(135deg, #EA580C 0%, #C2410C 100%);
            box-shadow: 0 5px 14px rgba(249, 115, 22, 0.4);
            transform: translateY(-1px);
        }
        .pipeline-section-title {
            font-size: 12.5px;
            font-weight: 800;
            color: #1E293B;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .pipeline-section-title span {
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .pipeline-section-hint {
            font-size: 10.5px;
            font-weight: 500;
            color: #64748B;
        }
        .interactive-stage-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
        }
        @media (max-width: 640px) {
            .interactive-stage-grid {
                grid-template-columns: 1fr;
            }
        }
        .stage-tile {
            background: #FFFFFF;
            border: 1.5px solid #E2E8F0;
            border-radius: 13px;
            padding: 11px 14px;
            display: flex;
            flex-direction: column;
            gap: 5px;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
            user-select: none;
        }
        .stage-tile.is-available:hover {
            border-color: #FDBA74;
            background: #FFFAF5;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(249, 115, 22, 0.08);
        }
        .stage-tile.is-selected {
            border: 2px solid #F97316 !important;
            background: #FFF7ED !important;
            box-shadow: 0 4px 14px rgba(249, 115, 22, 0.18) !important;
            transform: translateY(-1px);
        }
        .stage-tile.is-passed {
            background: #F8FAFC;
            border-color: #E2E8F0;
            opacity: 0.65;
            cursor: not-allowed;
        }
        .stage-tile.is-passed:hover {
            background: #F1F5F9;
        }
        .stage-tile.is-current {
            background: #FFFBEB;
            border: 1.5px solid #FDE68A;
            cursor: not-allowed;
        }
        .stage-tile-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stage-tile-badge-group {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .stage-tile-step-pill {
            font-size: 9.5px;
            font-weight: 800;
            padding: 2px 6px;
            border-radius: 5px;
            background: #F1F5F9;
            color: #475569;
            letter-spacing: 0.4px;
            text-transform: uppercase;
        }
        .stage-tile.is-selected .stage-tile-step-pill {
            background: #F97316;
            color: #FFFFFF;
        }
        .stage-tile.is-passed .stage-tile-step-pill {
            background: #DCFCE7;
            color: #166534;
        }
        .stage-tile.is-current .stage-tile-step-pill {
            background: #FEF3C7;
            color: #92400E;
        }
        .stage-tile-radio {
            font-size: 15px;
            color: #CBD5E1;
        }
        .stage-tile.is-selected .stage-tile-radio {
            color: #F97316;
        }
        .stage-tile.is-passed .stage-tile-radio {
            color: #10B981;
        }
        .stage-tile.is-current .stage-tile-radio {
            color: #F59E0B;
        }
        .stage-tile-title-row {
            display: flex;
            align-items: center;
            gap: 7px;
            margin-top: 1px;
        }
        .stage-tile-icon {
            font-size: 13px;
            color: #64748B;
            flex-shrink: 0;
        }
        .stage-tile.is-selected .stage-tile-icon {
            color: #EA580C;
        }
        .stage-tile.is-passed .stage-tile-icon {
            color: #10B981;
        }
        .stage-tile.is-current .stage-tile-icon {
            color: #D97706;
        }
        .stage-tile-title {
            font-size: 12.5px;
            font-weight: 700;
            color: #1E293B;
        }
        .stage-tile.is-selected .stage-tile-title {
            color: #C2410C;
            font-weight: 800;
        }
        .stage-tile.is-passed .stage-tile-title {
            color: #64748B;
        }
        .stage-tile-desc {
            font-size: 10.5px;
            color: #64748B;
            line-height: 1.35;
            margin-top: 1px;
        }
        .stage-tile-state-label {
            font-size: 9.5px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            margin-top: 3px;
        }
        .stage-tile.is-selected .stage-tile-state-label {
            color: #EA580C;
        }
        .stage-tile.is-passed .stage-tile-state-label {
            color: #059669;
        }
        .stage-tile.is-current .stage-tile-state-label {
            color: #D97706;
        }
        .stage-tile.is-available .stage-tile-state-label {
            color: #94A3B8;
        }
        .pipeline-notes-card {
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 13px;
            padding: 12px 16px;
        }
        .pipeline-notes-label {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 11.5px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 6px;
        }
        .pipeline-notes-label span i {
            color: #F97316;
            margin-right: 4px;
        }
        .pipeline-notes-textarea {
            width: 100%;
            border: 1.5px solid #E2E8F0;
            border-radius: 9px;
            padding: 8px 12px;
            font-size: 12.5px;
            font-family: inherit;
            color: #1E293B;
            resize: vertical;
            outline: none;
            transition: all 0.2s ease;
            background: #F8FAFC;
            box-sizing: border-box;
        }
        .pipeline-notes-textarea:focus {
            border-color: #F97316;
            background: #FFFFFF;
            box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.15);
        }
        .pipeline-modal-footer {
            padding: 14px 22px;
            background: #FFFFFF;
            border-top: 1px solid #E2E8F0;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 12px;
        }
        .btn-pipeline-cancel {
            padding: 9px 18px;
            border-radius: 10px;
            border: 1.5px solid #CBD5E1;
            background: #FFFFFF;
            color: #475569;
            font-size: 12.5px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .btn-pipeline-cancel:hover {
            background: #F1F5F9;
            border-color: #94A3B8;
            color: #1E293B;
        }
        .btn-pipeline-primary {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 22px;
            background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
            border: none;
            border-radius: 10px;
            color: #FFFFFF;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            box-shadow: 0 4px 14px rgba(249, 115, 22, 0.35);
            transition: all 0.2s ease;
        }
        .btn-pipeline-primary:hover:not(:disabled) {
            background: linear-gradient(135deg, #EA580C 0%, #C2410C 100%);
            box-shadow: 0 6px 18px rgba(249, 115, 22, 0.45);
            transform: translateY(-1px);
        }
        .btn-pipeline-primary:disabled {
            opacity: 0.55;
            cursor: not-allowed;
            box-shadow: none;
        }
    </style>
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

            <!-- Page Header: Title + Dynamic Current Date Card -->
            <div class="ar-header-row">
                <div class="ar-title-group">
                    <div class="ar-title-icon-box">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <div class="ar-title-text">
                        <h1>Accepted <span class="accent-orange">Requests</span></h1>
                        <p>Service requests that you have accepted and are in progress.</p>
                    </div>
                </div>

                <div class="ar-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <!-- Feedback Notification Banner if redirected -->
            <% if ("complete".equalsIgnoreCase(msg)) { %>
                <div class="ar-alert-banner ar-alert-success" id="statusNotification">
                    <span><i class="fa-solid fa-circle-check"></i> Request <strong><%= msgReqId != null ? msgReqId : "" %></strong> was successfully marked as Completed and moved to Service History!</span>
                    <button type="button" class="ar-alert-close" onclick="document.getElementById('statusNotification').remove()">&times;</button>
                </div>
            <% } else if ("update".equalsIgnoreCase(msg)) { %>
                <div class="ar-alert-banner ar-alert-info" id="statusNotification">
                    <span><i class="fa-solid fa-circle-info"></i> Status for request <strong><%= msgReqId != null ? msgReqId : "" %></strong> was successfully updated.</span>
                    <button type="button" class="ar-alert-close" onclick="document.getElementById('statusNotification').remove()">&times;</button>
                </div>
            <% } %>

            <!-- Dynamic Toast Container for AJAX Actions -->
            <div id="dynamicAlertContainer"></div>

            <!-- Four Summary Metric Cards -->
            <div class="ar-stats-grid">
                <!-- Card 1: Total Requests -->
                <div class="ar-stat-card ar-card-total">
                    <div class="ar-stat-icon-box">
                        <i class="fa-solid fa-clipboard-list"></i>
                    </div>
                    <div class="ar-stat-info">
                        <span class="ar-stat-label">Total Requests</span>
                        <span class="ar-stat-number" id="statTotalRequests"><%= totalRequests %></span>
                    </div>
                </div>

                <!-- Card 2: Pending Requests -->
                <div class="ar-stat-card ar-card-pending">
                    <div class="ar-stat-icon-box">
                        <i class="fa-solid fa-clock"></i>
                    </div>
                    <div class="ar-stat-info">
                        <span class="ar-stat-label">Pending</span>
                        <span class="ar-stat-number" id="statPendingRequests"><%= pendingRequests %></span>
                    </div>
                </div>

                <!-- Card 3: Accepted Requests -->
                <div class="ar-stat-card ar-card-accepted">
                    <div class="ar-stat-icon-box">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <div class="ar-stat-info">
                        <span class="ar-stat-label">Accepted</span>
                        <span class="ar-stat-number" id="statAcceptedRequests"><%= acceptedRequests %></span>
                    </div>
                </div>

                <!-- Card 4: Completed Requests -->
                <div class="ar-stat-card ar-card-completed">
                    <div class="ar-stat-icon-box">
                        <i class="fa-solid fa-screwdriver-wrench"></i>
                    </div>
                    <div class="ar-stat-info">
                        <span class="ar-stat-label">Completed</span>
                        <span class="ar-stat-number" id="statCompletedRequests"><%= completedRequests %></span>
                    </div>
                </div>
            </div>

            <!-- Search and Filter Toolbar -->
            <form action="accepted-requests.jsp" method="GET" class="ar-toolbar-form">
                <!-- 1. Search Box -->
                <div class="ar-search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" 
                           name="search" 
                           class="ar-search-input" 
                           placeholder="Search by Request ID, Vehicle No., or Customer Name..." 
                           value="<%= search %>">
                </div>

                <!-- 2. Service Issue Dropdown -->
                <div class="ar-select-box">
                    <select name="serviceIssue" class="ar-select-control" onchange="this.form.submit()">
                        <option value="" <%= serviceIssueFilter.isEmpty() ? "selected" : "" %>>Select Service Issue</option>
                        <option value="Battery Jump Start" <%= "Battery Jump Start".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Battery Jump Start</option>
                        <option value="Tyre Puncture" <%= "Tyre Puncture".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Tyre Puncture</option>
                        <option value="General Service" <%= "General Service".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>General Service</option>
                        <option value="Electrical Repair" <%= "Electrical Repair".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Electrical Repair</option>
                        <option value="Engine Overheating" <%= "Engine Overheating".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Engine Overheating</option>
                        <option value="Fuel Delivery" <%= "Fuel Delivery".equalsIgnoreCase(serviceIssueFilter) ? "selected" : "" %>>Fuel Delivery</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- 3. Sort By Dropdown -->
                <div class="ar-select-box">
                    <select name="sort" class="ar-select-control" onchange="this.form.submit()">
                        <option value="newest" <%= !"oldest".equalsIgnoreCase(sortOrder) ? "selected" : "" %>>Sort by Oldest</option>
                        <option value="oldest" <%= "oldest".equalsIgnoreCase(sortOrder) ? "selected" : "" %>>Sort by Newest</option>
                    </select>
                    <i class="fa-solid fa-chevron-down"></i>
                </div>

                <!-- 4. Orange Search Button -->
                <button type="submit" class="btn-ar-search">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <span>Search</span>
                </button>
            </form>

            <!-- Accepted Service Requests Section -->
            <div class="ar-main-card">
                <!-- Section Header with Title and Accepted Count Badge -->
                <div class="ar-card-header">
                    <div class="ar-card-title-group">
                        <i class="fa-solid fa-circle-check"></i>
                        <h2>Accepted Service Requests</h2>
                    </div>

                    <div class="ar-badge-count" id="badgeAcceptedCount">
                        <i class="fa-solid fa-check"></i>
                        <span><%= totalFilteredAccepted %> Accepted Requests</span>
                    </div>
                </div>

                <!-- Responsive Table Container -->
                <div class="ar-table-container">
                    <% if (totalFilteredAccepted == 0) { %>
                        <div class="ar-empty-state">
                            <div class="ar-empty-icon">
                                <i class="fa-solid fa-clipboard-check"></i>
                            </div>
                            <h3 class="ar-empty-title">No Accepted Requests</h3>
                            <p class="ar-empty-desc">
                                <%= (!search.isEmpty() || !serviceIssueFilter.isEmpty()) 
                                    ? "No accepted requests matched your search criteria. Try clearing filters." 
                                    : "You don't have any accepted service requests in progress." %>
                            </p>
                            <% if (!search.isEmpty() || !serviceIssueFilter.isEmpty()) { %>
                                <a href="accepted-requests.jsp" class="btn-ar-search" style="text-decoration:none; display:inline-flex; padding:8px 18px;">
                                    <i class="fa-solid fa-arrow-rotate-left"></i>
                                    <span>Reset Filters</span>
                                </a>
                            <% } %>
                        </div>
                    <% } else { %>
                        <table class="ar-data-table" id="acceptedRequestsTable">
                            <thead>
                                <tr>
                                    <th style="width: 32px; text-align: center;">S.No</th>
                                    <th style="width: 95px;">Request ID</th>
                                    <th style="width: 175px;">Vehicle</th>
                                    <th style="width: 155px;">Service Issue</th>
                                    <th style="width: 135px;">Location</th>
                                    <th style="width: 135px;">Accepted On</th>
                                    <th style="width: 105px;">Status</th>
                                    <th style="width: 240px; text-align: center;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    for (int i = 0; i < pageAcceptedList.size(); i++) {
                                        Map req = (Map) pageAcceptedList.get(i);
                                        int rowSerial = startIndex + i + 1;
                                        String rCode = (String) req.get("code");
                                        String vNum = (String) req.get("vehicle");
                                        String vModel = (String) req.get("model");
                                        String vImg = (String) req.get("vehicle_img");
                                        String issue = (String) req.get("issue");
                                        String issueIcon = (String) req.get("issue_icon");
                                        String locName = (String) req.get("loc_name");
                                        String locDist = (String) req.get("loc_dist");
                                        String dPart = (String) req.get("date_part");
                                        String tPart = (String) req.get("time_part");
                                        String st = (String) req.get("status");
                                        String cName = (String) req.get("customer_name");
                                        String cPhone = (String) req.get("customer_phone");
                                        String desc = (String) req.get("description");
                                        if (desc == null || desc.trim().isEmpty()) desc = "Customer reported " + issue.toLowerCase() + " near " + locName + ". Vehicle requires on-site roadside support.";

                                        String vImgSrc;
                                        if (vImg != null && (vImg.startsWith("http://") || vImg.startsWith("https://"))) {
                                            vImgSrc = vImg;
                                        } else if (vImg != null && vImg.startsWith("veh_")) {
                                            vImgSrc = request.getContextPath() + "/uploads/vehicles/" + vImg;
                                        } else if (vImg != null && vImg.startsWith("uploads/")) {
                                            vImgSrc = request.getContextPath() + "/" + vImg;
                                        } else {
                                            vImgSrc = request.getContextPath() + "/images/" + (vImg != null && !vImg.trim().isEmpty() ? vImg : "vehicle-i20.png");
                                        }
                                %>
                                <tr id="row-<%= rCode %>"
                                    data-req-code="<%= rCode %>"
                                    data-vehicle="<%= vNum %>"
                                    data-model="<%= vModel %>"
                                    data-issue="<%= issue %>"
                                    data-location="<%= locName %> <%= locDist %>"
                                    data-date="<%= dPart %> <%= tPart %>"
                                    data-status="<%= st %>"
                                    data-customer="<%= cName %>"
                                    data-phone="<%= cPhone %>"
                                    data-desc="<%= desc.replace("\"", "&quot;") %>">
                                    <!-- 1. Serial Number -->
                                    <td class="td-row-num"><%= rowSerial %></td>

                                    <!-- 2. Request ID Badge -->
                                    <td>
                                        <span class="badge-req-id"><%= rCode %></span>
                                    </td>

                                    <!-- 3. Vehicle with Thumbnail -->
                                    <td>
                                        <div class="vehicle-cell-box">
                                            <img src="<%= vImgSrc %>" 
                                                 alt="<%= vModel %>" 
                                                 class="vehicle-thumb-img"
                                                 onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/images/vehicle-i20.png';">
                                            <div class="vehicle-text-info">
                                                <span class="vehicle-reg-no"><%= vNum %></span>
                                                <span class="vehicle-model-desc"><%= vModel %></span>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- 4. Service Issue -->
                                    <td>
                                        <div class="issue-cell-box">
                                            <i class="<%= issueIcon %>"></i>
                                            <span class="issue-name-text"><%= issue %></span>
                                        </div>
                                    </td>

                                    <!-- 5. Location -->
                                    <td>
                                        <div class="location-cell-box">
                                            <i class="fa-solid fa-location-dot"></i>
                                            <div class="location-text-info">
                                                <span class="location-name"><%= locName %></span>
                                                <% if (!locDist.isEmpty()) { %>
                                                    <span class="location-dist"><%= locDist %></span>
                                                <% } %>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- 6. Accepted On (Date & Time) -->
                                    <td>
                                        <div class="datetime-cell-box">
                                            <div class="datetime-row">
                                                <i class="fa-regular fa-calendar"></i>
                                                <span><%= dPart %></span>
                                            </div>
                                            <% if (!tPart.isEmpty()) { %>
                                            <div class="datetime-row">
                                                <i class="fa-regular fa-clock"></i>
                                                <span><%= tPart %></span>
                                            </div>
                                            <% } %>
                                        </div>
                                    </td>

                                    <!-- 7. Status Pill with Color-Coded Sequential Styling -->
                                    <td>
                                        <%
                                            String pillClass = "status-pill-accepted";
                                            String pillIcon = "fa-solid fa-clipboard-check";
                                            String stLow = (st != null) ? st.toLowerCase() : "";
                                            if (stLow.contains("on the way") || stLow.contains("route")) {
                                                pillClass = "status-pill-ontheway";
                                                pillIcon = "fa-solid fa-motorcycle";
                                            } else if (stLow.contains("progress")) {
                                                pillClass = "status-pill-inprogress";
                                                pillIcon = "fa-solid fa-wrench";
                                            } else if (stLow.contains("diagnostics")) {
                                                pillClass = "status-pill-diagnostics";
                                                pillIcon = "fa-solid fa-list-check";
                                            } else if (stLow.contains("parts")) {
                                                pillClass = "status-pill-parts";
                                                pillIcon = "fa-solid fa-gears";
                                            } else if (stLow.contains("completed")) {
                                                pillClass = "status-pill-completed";
                                                pillIcon = "fa-solid fa-circle-check";
                                            }
                                        %>
                                        <span class="ar-status-pill <%= pillClass %>" id="status-pill-<%= rCode %>">
                                            <i class="<%= pillIcon %>"></i>
                                            <span><%= st %></span>
                                        </span>
                                    </td>

                                    <!-- 8. Actions: View, Update Status, Complete -->
                                    <td style="text-align: center;">
                                        <div class="ar-actions-group">
                                            <!-- View Button (Orange Outline) -->
                                            <button type="button" 
                                                    class="btn-ar-action btn-ar-view" 
                                                    id="btn-view-<%= rCode %>"
                                                    onclick="openViewModal('<%= rCode %>')"
                                                    title="View request details">
                                                <i class="fa-regular fa-eye"></i>
                                                <span>View</span>
                                            </button>

                                            <!-- Update Status Button (Orange Outline) -->
                                            <button type="button" 
                                                    class="btn-ar-action btn-ar-update" 
                                                    id="btn-update-<%= rCode %>"
                                                    onclick="openUpdateModal('<%= rCode %>')"
                                                    title="Update progress or status">
                                                <i class="fa-solid fa-arrows-rotate"></i>
                                                <span>Update Status</span>
                                            </button>

                                            <!-- Complete Button (Solid Green) -->
                                            <button type="button" 
                                                    class="btn-ar-action btn-ar-complete" 
                                                    id="btn-complete-<%= rCode %>"
                                                    onclick="executeCompleteAction('<%= rCode %>')"
                                                    title="Mark as Completed">
                                                <i class="fa-solid fa-check"></i>
                                                <span>Complete</span>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    <% } %>
                </div>

                <!-- Footer with Record Counter and Pagination Controls -->
                <div class="ar-footer-row">
                    <div class="ar-record-count-text" id="footerRecordCount">
                        <% if (totalFilteredAccepted > 0) { %>
                            Showing <%= startIndex + 1 %> to <%= endIndex %> of <%= totalFilteredAccepted %> requests
                        <% } else { %>
                            Showing 0 of 0 requests
                        <% } %>
                    </div>

                    <% if (totalPages > 1) { %>
                    <div class="ar-pagination-controls">
                        <!-- Previous Page Button -->
                        <% if (currentPage > 1) { %>
                            <a href="accepted-requests.jsp?page=<%= currentPage - 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                               class="ar-page-btn" 
                               aria-label="Previous Page">
                                <i class="fa-solid fa-chevron-left"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="ar-page-btn disabled" disabled>
                                <i class="fa-solid fa-chevron-left"></i>
                            </button>
                        <% } %>

                        <!-- Page Numbers -->
                        <% for (int p = 1; p <= totalPages; p++) { %>
                            <% if (p == currentPage) { %>
                                <button type="button" class="ar-page-btn active"><%= p %></button>
                            <% } else { %>
                                <a href="accepted-requests.jsp?page=<%= p %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                                   class="ar-page-btn">
                                    <%= p %>
                                </a>
                            <% } %>
                        <% } %>

                        <!-- Next Page Button -->
                        <% if (currentPage < totalPages) { %>
                            <a href="accepted-requests.jsp?page=<%= currentPage + 1 %>&search=<%= java.net.URLEncoder.encode(search, "UTF-8") %>&serviceIssue=<%= java.net.URLEncoder.encode(serviceIssueFilter, "UTF-8") %>&sort=<%= sortOrder %>" 
                               class="ar-page-btn" 
                               aria-label="Next Page">
                                <i class="fa-solid fa-chevron-right"></i>
                            </a>
                        <% } else { %>
                            <button type="button" class="ar-page-btn disabled" disabled>
                                <i class="fa-solid fa-chevron-right"></i>
                            </button>
                        <% } %>
                    </div>
                    <% } %>
                </div>

            </div>

        </main>
    </div>

    <!-- Universal Rich Service Request Details Modal -->
    <jsp:include page="/common/service-request-view-modal.jsp" />

    <!-- 4. Update Status Modal: Interactive Step-by-Step One-Way Progression -->
    <div class="ar-modal-overlay" id="updateStatusModal">
        <div class="ar-modal-card-pipeline">
            <!-- Modal Dark Charcoal Header -->
            <div class="pipeline-modal-header">
                <div class="pipeline-header-left">
                    <div class="pipeline-header-icon">
                        <i class="fa-solid fa-route"></i>
                    </div>
                    <div class="pipeline-header-titles">
                        <h3>Status Update Pipeline <span class="pipeline-ticket-badge" id="uModalReqCode"></span></h3>
                        <p class="pipeline-header-subtitle">One-way sequential service progression &bull; Fast dispatch workflow</p>
                    </div>
                </div>
                <button type="button" class="pipeline-btn-close" onclick="closeUpdateModal()" title="Close">&times;</button>
            </div>

            <form id="updateStatusForm" onsubmit="submitStatusUpdate(event)">
                <input type="hidden" id="uModalTargetReqId" name="reqId" value="">
                <input type="hidden" id="uModalStatusSelect" name="newStatus" value="">

                <div class="pipeline-modal-body">
                    <!-- One-Way Workflow Rule Notice Banner -->
                    <div class="pipeline-rule-strip">
                        <i class="fa-solid fa-shield-halved pipeline-rule-icon"></i>
                        <div class="pipeline-rule-text">
                            <strong>One-Way Progression Rule:</strong>
                            Service status advances forward step-by-step only. Once a stage is passed, it is permanently locked and cannot be reverted backwards.
                        </div>
                    </div>

                    <!-- Progress Header & Horizontal Stepper Rail -->
                    <div class="pipeline-progress-card">
                        <div class="pipeline-progress-header">
                            <span class="pipeline-progress-title">
                                <i class="fa-solid fa-timeline"></i> Service Delivery Pipeline
                            </span>
                            <span class="pipeline-progress-badge" id="uModalStepProgressBadge">Stage 1 of 4 (25% Complete)</span>
                        </div>
                        <div class="pipeline-progress-track">
                            <div class="pipeline-progress-fill" id="uModalProgressFill" style="width: 25%;"></div>
                        </div>

                        <!-- Interactive Horizontal Stepper Rail -->
                        <div class="interactive-stepper-rail" id="uModalStepperTrack">
                            <!-- Populated dynamically via renderInteractiveStepper() -->
                        </div>
                    </div>

                    <!-- Fast-Advance Hero Action Banner -->
                    <div class="pipeline-fast-advance-card" id="uModalQuickAdvanceBox">
                        <div class="fast-advance-left">
                            <div class="fast-advance-icon">
                                <i class="fa-solid fa-bolt"></i>
                            </div>
                            <div>
                                <div class="fast-advance-caption">RECOMMENDED NEXT ACTION</div>
                                <div class="fast-advance-title" id="quickNextStepTitle">Advance to Step 2: On The Way</div>
                            </div>
                        </div>
                        <button type="button" class="btn-fast-advance-action" id="btnQuickAdvanceStep" onclick="quickAdvanceNextStep()">
                            <span>Fast Advance</span>
                            <i class="fa-solid fa-arrow-right"></i>
                        </button>
                    </div>

                    <!-- Interactive Selectable Stage Tiles Grid (Click to Select Forward Stage) -->
                    <div>
                        <div class="pipeline-section-title">
                            <span><i class="fa-solid fa-hand-pointer" style="color: #F97316;"></i> Select Target Forward Stage</span>
                            <span class="pipeline-section-hint">Click any unlocked stage card to select</span>
                        </div>
                        <div class="interactive-stage-grid" id="uModalStageGrid">
                            <!-- Populated dynamically via renderInteractiveStepCards() -->
                        </div>
                    </div>

                    <!-- Mechanic Progress Notes (Optional) -->
                    <div class="pipeline-notes-card">
                        <label for="uModalNotesText" class="pipeline-notes-label">
                            <span><i class="fa-solid fa-pen-to-square"></i> Mechanic Progress Notes</span>
                            <span class="pipeline-section-hint">Optional &bull; Appended to activity log</span>
                        </label>
                        <textarea id="uModalNotesText" 
                                  name="notes" 
                                  class="pipeline-notes-textarea" 
                                  rows="2" 
                                  placeholder="Add repair details, parts replaced, or customer remarks..."></textarea>
                    </div>
                </div>

                <!-- Modal Footer -->
                <div class="pipeline-modal-footer">
                    <button type="button" class="btn-pipeline-cancel" onclick="closeUpdateModal()">Cancel</button>
                    <button type="submit" class="btn-pipeline-primary" id="btnSubmitStatusUpdate">
                        <i class="fa-solid fa-arrow-right-long"></i>
                        <span id="btnSubmitText">Advance Status to On The Way</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Client-Side JavaScript: Double-click Prevention, Modals, AJAX Actions, Dynamic Count Update -->
    <script>
        // --- 0. Step-by-Step Status Hierarchy Definition (4 Sequential Stages) ---
        const STATUS_STEPS = [
            { rank: 1, key: 'Accepted', label: 'Accepted', subtitle: 'Request accepted by shop', desc: 'Shop has accepted dispatch and assigned technician', icon: 'fa-solid fa-clipboard-check', badgeClass: 'badge-accepted' },
            { rank: 2, key: 'On The Way', label: 'On The Way', subtitle: 'Mechanic en route to motorist', desc: 'Technician dispatched and traveling to vehicle location', icon: 'fa-solid fa-motorcycle', badgeClass: 'badge-ontheway' },
            { rank: 3, key: 'In Progress', label: 'In Progress', subtitle: 'Arrived & work commenced', desc: 'Technician arrived on-site and inspection has started', icon: 'fa-solid fa-wrench', badgeClass: 'badge-inprogress' },
            { rank: 4, key: 'Completed', label: 'Completed', subtitle: 'Job successfully finished', desc: 'Vehicle tested, issue resolved and job finalized', icon: 'fa-solid fa-circle-check', badgeClass: 'badge-completed' }
        ];

        function getStepIndex(status) {
            if (!status) return 0;
            const s = status.trim().toLowerCase();
            for (let i = 0; i < STATUS_STEPS.length; i++) {
                if (STATUS_STEPS[i].key.toLowerCase() === s) return i;
            }
            if (s.includes('on the way') || s.includes('route')) return 1;
            if (s.includes('progress') || s.includes('diagnostics') || s.includes('parts')) return 2;
            if (s.includes('completed')) return 3;
            return 0;
        }

        // --- 1. View Details Modal ---
        function openViewModal(reqCode) {
            const row = document.getElementById('row-' + reqCode);
            const ds = row ? row.dataset : {};
            window.openServiceRequestModal({
                code: reqCode,
                userName: ds.customer,
                userPhone: ds.phone,
                vehicleNumber: ds.vehicle,
                brandModel: ds.model,
                issue: ds.issue,
                location: ds.location,
                status: ds.status,
                reqDate: ds.date,
                description: ds.desc
            });
        }

        function closeViewModal() {
            window.closeServiceRequestModal();
        }

        // --- 2. Interactive Stepper Rail Renderer ---
        function renderInteractiveStepper(curIdx, selectedTargetKey) {
            const track = document.getElementById('uModalStepperTrack');
            if (!track) return;

            let html = '';
            for (let i = 0; i < STATUS_STEPS.length; i++) {
                const step = STATUS_STEPS[i];
                let wrapperClass = 'stepper-node-wrapper';
                let circleContent = '';
                let statusBadgeText = '';
                let isClickable = false;

                if (i < curIdx) {
                    wrapperClass += ' is-passed';
                    circleContent = '<i class="fa-solid fa-check"></i>';
                    statusBadgeText = 'Passed';
                } else if (i === curIdx) {
                    wrapperClass += ' is-current';
                    circleContent = '<i class="' + step.icon + '"></i>';
                    statusBadgeText = 'Active';
                } else if (step.key === selectedTargetKey) {
                    wrapperClass += ' is-selected-target is-forward';
                    circleContent = '<i class="' + step.icon + '"></i>';
                    statusBadgeText = 'Target';
                    isClickable = true;
                } else {
                    wrapperClass += ' is-forward';
                    circleContent = '<span>' + (i + 1) + '</span>';
                    statusBadgeText = 'Step ' + (i + 1);
                    isClickable = true;
                }

                if (i > 0) {
                    const lineClass = (i <= curIdx) ? 'is-passed' : ((i === curIdx + 1) ? 'is-active' : '');
                    html += '<div class="stepper-connector-line ' + lineClass + '"></div>';
                }

                const clickHandler = isClickable 
                    ? 'onclick="selectTargetStep(\'' + step.key + '\')"'
                    : 'onclick="onLockedTileClick(' + i + ')"';

                html += '<div class="' + wrapperClass + '" ' + clickHandler + ' title="' + step.label + '">';
                html += '  <div class="stepper-node-circle">' + circleContent + '</div>';
                html += '  <span class="stepper-node-name">' + step.label + '</span>';
                html += '  <span class="stepper-node-status">' + statusBadgeText + '</span>';
                html += '</div>';
            }

            track.innerHTML = html;
        }

        // --- 3. Interactive Stage Grid Renderer ---
        function renderInteractiveStepCards(curIdx, selectedTargetKey) {
            const grid = document.getElementById('uModalStageGrid');
            if (!grid) return;

            let html = '';
            for (let i = 0; i < STATUS_STEPS.length; i++) {
                const step = STATUS_STEPS[i];
                let cardClass = 'stage-tile';
                let stateLabel = '';
                let radioIcon = '';
                let clickHandler = '';

                if (i < curIdx) {
                    cardClass += ' is-passed';
                    stateLabel = '<span class="stage-tile-state-label"><i class="fa-solid fa-lock"></i> Passed &amp; Locked</span>';
                    radioIcon = '<i class="fa-solid fa-lock" style="color: #94A3B8;"></i>';
                    clickHandler = 'onclick="onLockedTileClick(' + i + ')"';
                } else if (i === curIdx) {
                    cardClass += ' is-current';
                    stateLabel = '<span class="stage-tile-state-label"><i class="fa-solid fa-circle-dot"></i> Current Active Stage</span>';
                    radioIcon = '<i class="fa-solid fa-circle-dot" style="color: #D97706;"></i>';
                    clickHandler = 'onclick="onLockedTileClick(' + i + ')"';
                } else if (step.key === selectedTargetKey) {
                    cardClass += ' is-selected is-available';
                    const isImmediate = (i === curIdx + 1);
                    stateLabel = '<span class="stage-tile-state-label">' + (isImmediate ? '<i class="fa-solid fa-bolt"></i> Recommended Target' : '<i class="fa-solid fa-check"></i> Selected Target') + '</span>';
                    radioIcon = '<i class="fa-solid fa-circle-check" style="color: #F97316;"></i>';
                    clickHandler = 'onclick="selectTargetStep(\'' + step.key + '\')"';
                } else {
                    cardClass += ' is-available';
                    const isImmediate = (i === curIdx + 1);
                    stateLabel = '<span class="stage-tile-state-label">' + (isImmediate ? '<i class="fa-solid fa-star" style="color: #F59E0B;"></i> Next Recommended' : '<i class="fa-regular fa-hand-pointer"></i> Click to select') + '</span>';
                    radioIcon = '<i class="fa-regular fa-circle"></i>';
                    clickHandler = 'onclick="selectTargetStep(\'' + step.key + '\')"';
                }

                html += '<div class="' + cardClass + '" ' + clickHandler + '>';
                html += '  <div class="stage-tile-top">';
                html += '    <div class="stage-tile-badge-group">';
                html += '      <span class="stage-tile-step-pill">Step ' + (i + 1) + '</span>';
                html += '    </div>';
                html += '    <div class="stage-tile-radio">' + radioIcon + '</div>';
                html += '  </div>';
                html += '  <div class="stage-tile-title-row">';
                html += '    <i class="' + step.icon + ' stage-tile-icon"></i>';
                html += '    <span class="stage-tile-title">' + step.label + '</span>';
                html += '  </div>';
                html += '  <p class="stage-tile-desc">' + (step.desc || step.subtitle) + '</p>';
                html += '  <div>' + stateLabel + '</div>';
                html += '</div>';
            }

            grid.innerHTML = html;
        }

        // --- 4. Step Selection Handler ---
        function selectTargetStep(targetKey) {
            const hiddenInput = document.getElementById('uModalStatusSelect');
            if (!hiddenInput) return;
            hiddenInput.value = targetKey;

            const reqCode = document.getElementById('uModalTargetReqId').value;
            const row = document.getElementById('row-' + reqCode);
            const currentStatus = row ? (row.dataset.status || 'Accepted') : 'Accepted';
            const curIdx = getStepIndex(currentStatus);

            renderInteractiveStepper(curIdx, targetKey);
            renderInteractiveStepCards(curIdx, targetKey);

            const targetStepObj = STATUS_STEPS.find(s => s.key === targetKey);
            const submitText = document.getElementById('btnSubmitText');
            if (submitText && targetStepObj) {
                submitText.textContent = 'Advance Status to: ' + targetStepObj.label;
            }
        }

        // --- 5. Locked Tile Notice ---
        function onLockedTileClick(index) {
            const reqCode = document.getElementById('uModalTargetReqId').value;
            const row = document.getElementById('row-' + reqCode);
            const curStatus = row ? (row.dataset.status || 'Accepted') : 'Accepted';
            const curIdx = getStepIndex(curStatus);

            if (index < curIdx) {
                showToastNotification('<strong>One-Way Progression:</strong> Cannot revert backwards to passed stage <em>' + STATUS_STEPS[index].label + '</em>.', 'info');
            } else if (index === curIdx) {
                showToastNotification('<strong>Current Active Stage:</strong> Service is currently at <em>' + STATUS_STEPS[index].label + '</em>. Select an upcoming stage to advance.', 'info');
            }
        }

        // --- 6. Open Modal & Initialize ---
        function openUpdateModal(reqCode) {
            const row = document.getElementById('row-' + reqCode);
            if (!row) return;

            document.getElementById('uModalReqCode').textContent = reqCode;
            document.getElementById('uModalTargetReqId').value = reqCode;

            const currentStatus = row.dataset.status || 'Accepted';
            const curIdx = getStepIndex(currentStatus);

            let initialTargetKey = '';
            if (curIdx < STATUS_STEPS.length - 1) {
                initialTargetKey = STATUS_STEPS[curIdx + 1].key;
            } else {
                initialTargetKey = 'Completed';
            }
            document.getElementById('uModalStatusSelect').value = initialTargetKey;

            const progressPct = Math.round(((curIdx + 1) / STATUS_STEPS.length) * 100);
            const progressFill = document.getElementById('uModalProgressFill');
            if (progressFill) {
                progressFill.style.width = progressPct + '%';
            }
            const badgeIndicator = document.getElementById('uModalStepProgressBadge');
            if (badgeIndicator) {
                badgeIndicator.textContent = 'Stage ' + (curIdx + 1) + ' of ' + STATUS_STEPS.length + ' (' + progressPct + '% Complete)';
            }

            renderInteractiveStepper(curIdx, initialTargetKey);
            renderInteractiveStepCards(curIdx, initialTargetKey);

            const nextBox = document.getElementById('uModalQuickAdvanceBox');
            const submitBtn = document.getElementById('btnSubmitStatusUpdate');
            const submitText = document.getElementById('btnSubmitText');

            if (curIdx >= STATUS_STEPS.length - 1) {
                if (nextBox) nextBox.style.display = 'none';
                if (submitBtn) {
                    submitBtn.disabled = true;
                    submitText.textContent = 'All Stages Completed';
                }
            } else {
                const nextStepObj = STATUS_STEPS[curIdx + 1];
                if (nextBox) nextBox.style.display = 'flex';
                const quickTitle = document.getElementById('quickNextStepTitle');
                if (quickTitle) {
                    quickTitle.textContent = 'Advance to Step ' + (curIdx + 2) + ': ' + nextStepObj.label;
                }
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitText.textContent = 'Advance Status to: ' + nextStepObj.label;
                }
            }

            document.getElementById('uModalNotesText').value = '';
            document.getElementById('updateStatusModal').classList.add('active');
        }

        function closeUpdateModal() {
            document.getElementById('updateStatusModal').classList.remove('active');
        }

        function quickAdvanceNextStep() {
            const hiddenInput = document.getElementById('uModalStatusSelect');
            if (hiddenInput && hiddenInput.value) {
                const form = document.getElementById('updateStatusForm');
                form.dispatchEvent(new Event('submit', { cancelable: true, bubbles: true }));
            }
        }

        function submitStatusUpdate(e) {
            e.preventDefault();
            const reqCode = document.getElementById('uModalTargetReqId').value;
            const newStatus = document.getElementById('uModalStatusSelect').value;
            const notes = document.getElementById('uModalNotesText').value;
            const submitBtn = document.getElementById('btnSubmitStatusUpdate');

            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Updating...</span>';
            }

            const params = new URLSearchParams();
            params.append('action', 'update');
            params.append('reqId', reqCode);
            params.append('newStatus', newStatus);
            params.append('notes', notes);
            params.append('ajax', 'true');

            fetch('accepted-requests.jsp?' + params.toString(), {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            })
            .then(res => res.json())
            .then(data => {
                closeUpdateModal();
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> <span id="btnSubmitText">Save & Advance Status</span>';
                }

                if (data.success) {
                    if (newStatus === 'Completed') {
                        // Completed: animate out and move to completed history
                        executeCompleteAction(reqCode, true);
                    } else {
                        // Update status text in row dataset and UI pill
                        const row = document.getElementById('row-' + reqCode);
                        if (row) {
                            row.dataset.status = newStatus;
                        }
                        const pill = document.getElementById('status-pill-' + reqCode);
                        if (pill) {
                            const stepIdx = getStepIndex(newStatus);
                            const stepObj = STATUS_STEPS[stepIdx];
                            const pillClass = stepObj ? stepObj.badgeClass.replace('badge-', 'status-pill-') : 'status-pill-inprogress';
                            pill.className = 'ar-status-pill ' + pillClass;
                            pill.innerHTML = '<i class="' + (stepObj ? stepObj.icon : 'fa-solid fa-circle-check') + '"></i> <span>' + newStatus + '</span>';
                        }
                        showToastNotification('Status for request <strong>' + reqCode + '</strong> successfully advanced to <strong>' + newStatus + '</strong>.', 'success');
                    }
                } else {
                    const err = data.error || ('Failed to advance status for ' + reqCode + '.');
                    alert(err);
                    showToastNotification('<strong>Error:</strong> ' + err, 'danger');
                }
            })
            .catch(err => {
                console.warn('AJAX failed, reloading:', err);
                window.location.href = 'accepted-requests.jsp?action=update&reqId=' + encodeURIComponent(reqCode) + '&newStatus=' + encodeURIComponent(newStatus);
            });
        }

        // --- 3. Complete Action ---
        function executeCompleteAction(reqCode, skipConfirm) {
            if (!skipConfirm) {
                if (!confirm('Mark service request ' + reqCode + ' as Completed? This will finish the job and move it to Service History.')) {
                    return;
                }
            }

            const btnComplete = document.getElementById('btn-complete-' + reqCode);
            const btnUpdate = document.getElementById('btn-update-' + reqCode);
            const btnView = document.getElementById('btn-view-' + reqCode);
            const rowElem = document.getElementById('row-' + reqCode);

            if (btnComplete) {
                btnComplete.disabled = true;
                btnComplete.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> <span>Completing...</span>';
            }
            if (btnUpdate) btnUpdate.disabled = true;
            if (btnView) btnView.disabled = true;

            // Send AJAX completion request
            fetch('accepted-requests.jsp?action=complete&reqId=' + encodeURIComponent(reqCode) + '&ajax=true', {
                method: 'POST',
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    if (rowElem) {
                        rowElem.style.transition = 'all 0.35s ease';
                        rowElem.style.opacity = '0';
                        rowElem.style.transform = 'scale(0.96) translateY(-10px)';
                        setTimeout(() => {
                            rowElem.remove();
                            updateDynamicCountersAfterComplete();
                            renumberSerialNumbers();
                        }, 350);
                    }

                    showToastNotification('Request <strong>' + reqCode + '</strong> successfully completed and moved to Service History!', 'success');
                } else {
                    const err = data.error || ('Could not complete request ' + reqCode + '. Please try again.');
                    alert(err);
                    if (btnComplete) {
                        btnComplete.disabled = false;
                        btnComplete.innerHTML = '<i class="fa-solid fa-check"></i> <span>Complete</span>';
                    }
                    if (btnUpdate) btnUpdate.disabled = false;
                    if (btnView) btnView.disabled = false;
                }
            })
            .catch(err => {
                console.warn('AJAX failed, reloading:', err);
                window.location.href = 'accepted-requests.jsp?action=complete&reqId=' + encodeURIComponent(reqCode);
            });
        }

        function updateDynamicCountersAfterComplete() {
            // Decrement Accepted Requests Card
            const statAccepted = document.getElementById('statAcceptedRequests');
            if (statAccepted) {
                let cur = parseInt(statAccepted.textContent.trim(), 10) || 0;
                if (cur > 0) statAccepted.textContent = cur - 1;
            }

            // Increment Completed Requests Card
            const statCompleted = document.getElementById('statCompletedRequests');
            if (statCompleted) {
                let cur = parseInt(statCompleted.textContent.trim(), 10) || 0;
                statCompleted.textContent = cur + 1;
            }

            // Update badge count
            const badgeAccepted = document.getElementById('badgeAcceptedCount');
            const table = document.getElementById('acceptedRequestsTable');
            if (table) {
                const remaining = table.querySelectorAll('tbody tr').length;
                if (badgeAccepted) {
                    badgeAccepted.innerHTML = '<i class="fa-solid fa-check"></i> <span>' + remaining + ' Accepted Requests</span>';
                }
                const footerText = document.getElementById('footerRecordCount');
                if (footerText) {
                    footerText.textContent = 'Showing 1 to ' + remaining + ' of ' + remaining + ' requests';
                }
            }
        }

        function renumberSerialNumbers() {
            const table = document.getElementById('acceptedRequestsTable');
            if (!table) return;
            const rows = table.querySelectorAll('tbody tr');
            rows.forEach((r, idx) => {
                const tdNum = r.querySelector('.td-row-num');
                if (tdNum) {
                    tdNum.textContent = idx + 1;
                }
            });
        }

        function showToastNotification(msgHtml, type) {
            const container = document.getElementById('dynamicAlertContainer');
            if (!container) return;

            const toast = document.createElement('div');
            toast.className = 'ar-alert-banner ' + (type === 'success' ? 'ar-alert-success' : 'ar-alert-info');
            toast.style.margin = '14px 0';
            toast.innerHTML = 
                '<span><i class="' + (type === 'success' ? 'fa-solid fa-circle-check' : 'fa-solid fa-circle-info') + '"></i> ' + msgHtml + '</span>' +
                '<button type="button" class="ar-alert-close" onclick="this.parentElement.remove()">&times;</button>';

            container.prepend(toast);

            setTimeout(() => {
                if (toast && toast.parentElement) {
                    toast.style.transition = 'opacity 0.4s ease';
                    toast.style.opacity = '0';
                    setTimeout(() => toast.remove(), 400);
                }
            }, 6000);
        }

        // Close modals with Escape key or clicking outside
        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                closeViewModal();
                closeUpdateModal();
            }
        });

        document.querySelectorAll('.ar-modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    closeViewModal();
                    closeUpdateModal();
                }
            });
        });
    </script>

</body>
</html>
