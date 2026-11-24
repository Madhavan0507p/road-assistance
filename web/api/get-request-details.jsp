<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, com.roadassistance.util.DBConnection" %>
<%!
    public static String escapeJson(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < ' ') {
                        String t = "000" + Integer.toHexString(ch);
                        sb.append("\\u").append(t.substring(t.length() - 4));
                    } else {
                        sb.append(ch);
                    }
                    break;
            }
        }
        return sb.toString();
    }
%>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String code = request.getParameter("code");
    String id = request.getParameter("id");
    if ((code == null || code.trim().isEmpty()) && (id == null || id.trim().isEmpty())) {
        out.print("{\"success\":false,\"error\":\"Missing code or id parameter\"}");
        return;
    }

    String searchTarget = (code != null && !code.trim().isEmpty()) ? code.trim() : id.trim();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    SimpleDateFormat sdfOut = new SimpleDateFormat("dd-MM-yyyy, hh:mm a");

    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            out.print("{\"success\":false,\"error\":\"Database connection failed\"}");
            return;
        }

        try {
            com.roadassistance.service.ServiceRequestService.autoCancelStagnantAcceptedRequests(conn, 15);
        } catch (Exception ignored) {}

        String numOnly = searchTarget.replaceAll("[^0-9]", "");
        int parsedNum = -1;
        try {
            if (!numOnly.isEmpty()) parsedNum = Integer.parseInt(numOnly);
        } catch (Exception ignored) {}

        String sql = "SELECT r.*, " +
                     "COALESCE(u.full_name, r.user_name) AS resolved_user, " +
                     "CONCAT('USR', LPAD(COALESCE(u.user_id, r.user_id), 3, '0')) AS resolved_user_code, " +
                     "COALESCE(u.phone, '') AS user_phone, " +
                     "COALESCE(u.email, '') AS user_email, " +
                     "COALESCE(m.owner_name, r.mechanic_name, 'Unassigned') AS resolved_mech, " +
                     "COALESCE(m.mechanic_code, r.mechanic_code, '-') AS resolved_mech_code, " +
                     "COALESCE(m.phone, '') AS mech_phone, " +
                     "COALESCE(m.workshop_name, 'Unassigned') AS mech_shop, " +
                     "COALESCE(NULLIF(r.vehicle_type, ''), v.vehicle_type, 'Car') AS veh_type, " +
                     "COALESCE(NULLIF(r.vehicle_brand, ''), v.vehicle_brand, '') AS veh_brand, " +
                     "COALESCE(NULLIF(r.vehicle_model, ''), v.vehicle_model, '') AS veh_model, " +
                     "COALESCE(NULLIF(r.vehicle_image, ''), v.vehicle_image, '') AS veh_image " +
                     "FROM service_requests r " +
                     "LEFT JOIN users u ON r.user_id = u.user_id " +
                     "LEFT JOIN mechanics m ON (r.mechanic_code = m.mechanic_code) " +
                     "LEFT JOIN user_vehicles v ON REPLACE(REPLACE(UPPER(r.vehicle_number), ' ', ''), '-', '') = REPLACE(REPLACE(UPPER(v.vehicle_number), ' ', ''), '-', '') " +
                     "WHERE r.request_code = ? OR CAST(r.request_id AS CHAR) = ? OR r.request_code = ? OR r.request_id = ? LIMIT 1";

        ps = conn.prepareStatement(sql);
        ps.setString(1, searchTarget);
        ps.setString(2, searchTarget);
        ps.setString(3, parsedNum > 0 ? String.format("SR%04d", parsedNum) : searchTarget);
        ps.setInt(4, parsedNum > 0 ? parsedNum : -1);
        rs = ps.executeQuery();

        if (rs.next()) {
            int idNum = rs.getInt("request_id");
            String rCode = rs.getString("request_code");
            if (rCode == null || rCode.trim().isEmpty()) {
                rCode = String.format("SR%04d", idNum);
            }

            String uName = rs.getString("resolved_user");
            if (uName == null || uName.trim().isEmpty()) uName = "Customer";

            String uCode = rs.getString("resolved_user_code");
            if (uCode == null || uCode.trim().isEmpty()) {
                int uid = rs.getInt("user_id");
                uCode = String.format("USR%03d", uid > 0 ? uid : idNum);
            }

            String uPhone = rs.getString("user_phone");
            if (uPhone == null) uPhone = "";
            String uEmail = rs.getString("user_email");
            if (uEmail == null) uEmail = "";

            String vNum = rs.getString("vehicle_number");
            if (vNum == null || vNum.trim().isEmpty()) vNum = "Vehicle";

            String vType = rs.getString("veh_type");
            if (vType == null || vType.trim().isEmpty()) vType = "Car";

            String vBrand = rs.getString("veh_brand");
            String vModel = rs.getString("veh_model");
            String brandModel = (vModel != null && !vModel.trim().isEmpty()) ? vModel : ((vBrand != null && !vBrand.trim().isEmpty()) ? vBrand + " Vehicle" : "Vehicle");
            if (vBrand != null && !vBrand.trim().isEmpty() && !brandModel.toLowerCase().contains(vBrand.toLowerCase())) {
                brandModel = vBrand + " " + brandModel;
            }

            String vImg = rs.getString("veh_image");
            if (vImg == null) vImg = "";

            String issue = rs.getString("breakdown_issue");
            if (issue == null || issue.trim().isEmpty()) issue = "Breakdown Assistance";

            String loc = rs.getString("location");
            if (loc == null || loc.trim().isEmpty()) loc = "-";

            double lat = 0.0;
            double lng = 0.0;
            try {
                lat = rs.getDouble("latitude");
                lng = rs.getDouble("longitude");
            } catch (Exception ignored) {}

            String mName = rs.getString("resolved_mech");
            if (mName == null || mName.trim().isEmpty()) mName = "Unassigned";

            String mCode = rs.getString("resolved_mech_code");
            if (mCode == null || mCode.trim().isEmpty()) mCode = "-";

            String mPhone = rs.getString("mech_phone");
            if (mPhone == null) mPhone = "";

            String workshop = rs.getString("mech_shop");
            if (workshop == null || workshop.trim().isEmpty()) workshop = "Unassigned";

            String status = rs.getString("status");
            if (status == null || status.trim().isEmpty()) status = "Pending";

            double ratVal = rs.getDouble("rating");
            String ratStr = (rs.wasNull() || ratVal <= 0) ? "" : String.format("%.1f", ratVal);
            String ratComm = rs.getString("rating_comments");
            if (ratComm == null) ratComm = "";

            String desc = rs.getString("additional_details");
            if (desc == null || desc.trim().isEmpty()) {
                desc = "No additional description provided.";
            }

            // Formatted Date
            String dispDate = "-";
            Timestamp ts = rs.getTimestamp("requested_at");
            if (ts != null) {
                dispDate = sdfOut.format(ts);
            } else {
                String reqDateStr = rs.getString("requested_date");
                if (reqDateStr != null && !reqDateStr.trim().isEmpty()) {
                    dispDate = reqDateStr.trim();
                }
            }

            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"success\":true,");
            json.append("\"id\":\"").append(idNum).append("\",");
            json.append("\"code\":\"").append(escapeJson(rCode)).append("\",");
            json.append("\"userName\":\"").append(escapeJson(uName)).append("\",");
            json.append("\"userCode\":\"").append(escapeJson(uCode)).append("\",");
            json.append("\"userPhone\":\"").append(escapeJson(uPhone)).append("\",");
            json.append("\"userEmail\":\"").append(escapeJson(uEmail)).append("\",");
            json.append("\"vehicleNumber\":\"").append(escapeJson(vNum)).append("\",");
            json.append("\"vehicleType\":\"").append(escapeJson(vType)).append("\",");
            json.append("\"brandModel\":\"").append(escapeJson(brandModel)).append("\",");
            json.append("\"color\":\"\",");
            json.append("\"vehicleImg\":\"").append(escapeJson(vImg)).append("\",");
            json.append("\"issue\":\"").append(escapeJson(issue)).append("\",");
            json.append("\"location\":\"").append(escapeJson(loc)).append("\",");
            json.append("\"latitude\":").append(lat).append(",");
            json.append("\"longitude\":").append(lng).append(",");
            json.append("\"mechName\":\"").append(escapeJson(mName)).append("\",");
            json.append("\"mechCode\":\"").append(escapeJson(mCode)).append("\",");
            json.append("\"mechPhone\":\"").append(escapeJson(mPhone)).append("\",");
            json.append("\"workshop\":\"").append(escapeJson(workshop)).append("\",");
            json.append("\"status\":\"").append(escapeJson(status)).append("\",");
            json.append("\"rating\":\"").append(escapeJson(ratStr)).append("\",");
            json.append("\"comments\":\"").append(escapeJson(ratComm)).append("\",");
            json.append("\"reqDate\":\"").append(escapeJson(dispDate)).append("\",");
            json.append("\"description\":\"").append(escapeJson(desc)).append("\"");
            json.append("}");

            out.print(json.toString());
        } else {
            out.print("{\"success\":false,\"error\":\"Request not found\"}");
        }
    } catch (Exception e) {
        String msg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Internal error";
        out.print("{\"success\":false,\"error\":\"" + msg + "\"}");
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (ps != null) try { ps.close(); } catch (Exception ignored) {}
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
