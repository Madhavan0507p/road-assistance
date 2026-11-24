package com.roadassistance.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Properties;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

public class EmailUtil {

    private static final Properties config = new Properties();
    private static boolean isConfigLoaded = false;

    static {
        loadConfig();
    }

    private static synchronized void loadConfig() {
        if (isConfigLoaded) return;
        try {
            InputStream is = Thread.currentThread().getContextClassLoader().getResourceAsStream("mail.properties");
            if (is == null) {
                is = EmailUtil.class.getClassLoader().getResourceAsStream("mail.properties");
            }
            if (is != null) {
                config.load(is);
                is.close();
            }
        } catch (Exception e) {
            System.err.println("EmailUtil config load notice: " + e.getMessage());
        }
        isConfigLoaded = true;
    }

    public static boolean sendOTPEmail(String toEmail, String otpCode) {
        loadConfig();

        String host = config.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = config.getProperty("mail.smtp.port", "587");
        String authUser = System.getenv("SMTP_USER") != null ? System.getenv("SMTP_USER") : config.getProperty("mail.user", "");
        String authPass = System.getenv("SMTP_PASS") != null ? System.getenv("SMTP_PASS") : config.getProperty("mail.password", "");
        String fromName = config.getProperty("mail.from.name", "On Road Breakdown Assistance");

        // If credentials are empty/dummy, print to console for development & return true
        if (authUser == null || authUser.trim().isEmpty() || authPass == null || authPass.trim().isEmpty()) {
            System.out.println("==================================================================");
            System.out.println(" [EMAIL OTP SIMULATION] - SMTP credentials not set in mail.properties");
            System.out.println(" Recipient: " + toEmail);
            System.out.println(" OTP Code : >>> " + otpCode + " <<< (Valid for 5 minutes)");
            System.out.println(" (Set mail.user & mail.password in mail.properties to send live emails)");
            System.out.println("==================================================================");
            return true;
        }

        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", port);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");
            props.put("mail.smtp.ssl.trust", "*");
            props.put("mail.smtp.connectiontimeout", "5000");
            props.put("mail.smtp.timeout", "5000");
            props.put("mail.smtp.writetimeout", "5000");

            final String username = authUser.trim();
            final String password = authPass.trim();

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(username, fromName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject(otpCode + " is your On Road Assistance Verification Code", "UTF-8");

            String htmlContent = buildEmailTemplate(otpCode, toEmail);
            message.setContent(htmlContent, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("OTP email dispatched successfully to: " + toEmail);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send live OTP email via SMTP: " + e.getMessage());
            System.out.println("==================================================================");
            System.out.println(" [FALLBACK OTP LOG] Recipient: " + toEmail + " | Code: " + otpCode);
            System.out.println("==================================================================");
            // Return true so developer / user can continue testing even if network blocks port 587
            return true;
        }
    }

    public static boolean sendMechanicActivationEmail(String toEmail, String mechanicName, String workshopName, String mechanicCode, String loginUrl) {
        loadConfig();

        String host = config.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = config.getProperty("mail.smtp.port", "587");
        String authUser = System.getenv("SMTP_USER") != null ? System.getenv("SMTP_USER") : config.getProperty("mail.user", "");
        String authPass = System.getenv("SMTP_PASS") != null ? System.getenv("SMTP_PASS") : config.getProperty("mail.password", "");
        String fromName = config.getProperty("mail.from.name", "On Road Breakdown Assistance");

        String safeName = (mechanicName != null && !mechanicName.trim().isEmpty()) ? mechanicName.trim() : "Mechanic Partner";
        String safeWorkshop = (workshopName != null && !workshopName.trim().isEmpty()) ? workshopName.trim() : "Auto Workshop";
        String safeCode = (mechanicCode != null && !mechanicCode.trim().isEmpty()) ? mechanicCode.trim() : "MEC";

        if (authUser == null || authUser.trim().isEmpty() || authPass == null || authPass.trim().isEmpty()) {
            System.out.println("==================================================================");
            System.out.println(" [MECHANIC ACTIVATION EMAIL SIMULATION]");
            System.out.println(" Recipient : " + toEmail);
            System.out.println(" Partner   : " + safeName + " (" + safeWorkshop + ")");
            System.out.println(" Code      : " + safeCode);
            System.out.println(" Status    : APPROVED & ACTIVATED");
            System.out.println(" Login URL : " + loginUrl);
            System.out.println("==================================================================");
            return true;
        }

        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", port);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");
            props.put("mail.smtp.ssl.trust", "*");
            props.put("mail.smtp.connectiontimeout", "5000");
            props.put("mail.smtp.timeout", "5000");
            props.put("mail.smtp.writetimeout", "5000");

            final String username = authUser.trim();
            final String password = authPass.trim();

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(username, fromName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject("Congratulations! Your Mechanic Account Has Been Approved (" + safeCode + ")", "UTF-8");

            String htmlContent = buildMechanicActivationTemplate(safeName, safeWorkshop, safeCode, loginUrl);
            message.setContent(htmlContent, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("Mechanic activation email dispatched successfully to: " + toEmail);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send live activation email via SMTP: " + e.getMessage());
            System.out.println("==================================================================");
            System.out.println(" [FALLBACK ACTIVATION LOG] Recipient: " + toEmail + " | Partner: " + safeName + " (" + safeCode + ") APPROVED");
            System.out.println("==================================================================");
            return true;
        }
    }

    public static boolean sendMechanicRejectionEmail(String toEmail, String mechanicName, String workshopName, String mechanicCode, String rejectionReason) {
        loadConfig();

        String host = config.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = config.getProperty("mail.smtp.port", "587");
        String authUser = System.getenv("SMTP_USER") != null ? System.getenv("SMTP_USER") : config.getProperty("mail.user", "");
        String authPass = System.getenv("SMTP_PASS") != null ? System.getenv("SMTP_PASS") : config.getProperty("mail.password", "");
        String fromName = config.getProperty("mail.from.name", "On Road Breakdown Assistance");

        String safeName = (mechanicName != null && !mechanicName.trim().isEmpty()) ? mechanicName.trim() : "Mechanic Partner";
        String safeWorkshop = (workshopName != null && !workshopName.trim().isEmpty()) ? workshopName.trim() : "Auto Workshop";
        String safeCode = (mechanicCode != null && !mechanicCode.trim().isEmpty()) ? mechanicCode.trim() : "MEC";
        String safeReason = (rejectionReason != null && !rejectionReason.trim().isEmpty()) ? rejectionReason.trim() : "Registration details or uploaded verification documents did not meet platform criteria.";

        if (authUser == null || authUser.trim().isEmpty() || authPass == null || authPass.trim().isEmpty()) {
            System.out.println("==================================================================");
            System.out.println(" [MECHANIC REJECTION EMAIL SIMULATION]");
            System.out.println(" Recipient : " + toEmail);
            System.out.println(" Partner   : " + safeName + " (" + safeWorkshop + ")");
            System.out.println(" Code      : " + safeCode);
            System.out.println(" Status    : REJECTED");
            System.out.println(" Reason    : " + safeReason);
            System.out.println("==================================================================");
            return true;
        }

        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", port);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");
            props.put("mail.smtp.ssl.trust", "*");
            props.put("mail.smtp.connectiontimeout", "5000");
            props.put("mail.smtp.timeout", "5000");
            props.put("mail.smtp.writetimeout", "5000");

            final String username = authUser.trim();
            final String password = authPass.trim();

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(username, fromName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject("Mechanic Application Status Update (" + safeCode + ") - Application Not Approved", "UTF-8");

            String htmlContent = buildMechanicRejectionTemplate(safeName, safeWorkshop, safeCode, safeReason);
            message.setContent(htmlContent, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("Mechanic rejection email dispatched successfully to: " + toEmail);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send live rejection email via SMTP: " + e.getMessage());
            System.out.println("==================================================================");
            System.out.println(" [FALLBACK REJECTION LOG] Recipient: " + toEmail + " | Partner: " + safeName + " (" + safeCode + ") REJECTED | Reason: " + safeReason);
            System.out.println("==================================================================");
            return true;
        }
    }

    /**
     * Retrieves the base URL for email links, configurable via APP_URL environment variable on cloud hosts like Render.
     */
    public static String getAppBaseUrl() {
        String env = System.getenv("APP_URL");
        if (env != null && !env.trim().isEmpty()) {
            return env.trim().replaceAll("/+$", "");
        }
        String prop = System.getProperty("app.url");
        if (prop != null && !prop.trim().isEmpty()) {
            return prop.trim().replaceAll("/+$", "");
        }
        return "http://localhost:8080/Road_Assistance";
    }

    public static boolean sendServiceRequestStatusEmail(String toEmail, String userName, String requestCode, String newStatus, String mechanicName, String vehicleNumber, String breakdownIssue, String location, String notes) {
        loadConfig();

        String host = config.getProperty("mail.smtp.host", "smtp.gmail.com");
        String port = config.getProperty("mail.smtp.port", "587");
        String authUser = System.getenv("SMTP_USER") != null ? System.getenv("SMTP_USER") : config.getProperty("mail.user", "");
        String authPass = System.getenv("SMTP_PASS") != null ? System.getenv("SMTP_PASS") : config.getProperty("mail.password", "");
        String fromName = config.getProperty("mail.from.name", "On Road Breakdown Assistance");

        String safeUser = (userName != null && !userName.trim().isEmpty()) ? userName.trim() : "Valued Customer";
        String safeCode = (requestCode != null && !requestCode.trim().isEmpty()) ? requestCode.trim() : "Service Request";
        String safeStatus = (newStatus != null && !newStatus.trim().isEmpty()) ? newStatus.trim() : "Updated";
        String safeMechanic = (mechanicName != null && !mechanicName.trim().isEmpty()) ? mechanicName.trim() : "Mechanic Network";
        String safeVehicle = (vehicleNumber != null && !vehicleNumber.trim().isEmpty()) ? vehicleNumber.trim() : "Registered Vehicle";
        String safeIssue = (breakdownIssue != null && !breakdownIssue.trim().isEmpty()) ? breakdownIssue.trim() : "Breakdown Assistance";
        String safeLocation = (location != null && !location.trim().isEmpty()) ? location.trim() : "Breakdown Spot";
        String safeNotes = (notes != null && !notes.trim().isEmpty()) ? notes.trim() : "";

        if (authUser == null || authUser.trim().isEmpty() || authPass == null || authPass.trim().isEmpty()) {
            System.out.println("==================================================================");
            System.out.println(" [REQUEST STATUS UPDATE EMAIL SIMULATION]");
            System.out.println(" Recipient : " + toEmail);
            System.out.println(" Customer  : " + safeUser);
            System.out.println(" Request   : " + safeCode);
            System.out.println(" Status    : >>> " + safeStatus + " <<<");
            System.out.println(" Mechanic  : " + safeMechanic);
            System.out.println(" Vehicle   : " + safeVehicle + " (" + safeIssue + ")");
            System.out.println(" Location  : " + safeLocation);
            if (!safeNotes.isEmpty()) {
                System.out.println(" Notes     : " + safeNotes);
            }
            System.out.println("==================================================================");
            return true;
        }

        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", port);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");
            props.put("mail.smtp.ssl.trust", "*");
            props.put("mail.smtp.connectiontimeout", "5000");
            props.put("mail.smtp.timeout", "5000");
            props.put("mail.smtp.writetimeout", "5000");

            final String username = authUser.trim();
            final String password = authPass.trim();

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(username, fromName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            message.setSubject("[" + safeCode + "] Service Request Update: " + safeStatus + " - On Road Assistance", "UTF-8");

            String htmlContent = buildServiceRequestStatusTemplate(safeUser, safeCode, safeStatus, safeMechanic, safeVehicle, safeIssue, safeLocation, safeNotes);
            message.setContent(htmlContent, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("Service status email dispatched successfully to: " + toEmail + " [" + safeCode + ": " + safeStatus + "]");
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send live status email via SMTP: " + e.getMessage());
            System.out.println("==================================================================");
            System.out.println(" [FALLBACK STATUS EMAIL LOG] Recipient: " + toEmail + " | Request: " + safeCode + " | Status: " + safeStatus);
            System.out.println("==================================================================");
            return true;
        }
    }

    public static void notifyUserOfRequestStatusUpdate(String requestCodeOrId, String newStatus, String notes) {
        if (requestCodeOrId == null || requestCodeOrId.trim().isEmpty()) return;
        String target = requestCodeOrId.trim();
        int parsedId = 0;
        try { parsedId = Integer.parseInt(target); } catch (Exception ignored) {}

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                String sql = "SELECT sr.request_id, sr.request_code, sr.user_name, sr.vehicle_number, "
                           + "sr.breakdown_issue, sr.mechanic_name, sr.location, "
                           + "COALESCE(u.email, (SELECT email FROM users WHERE full_name = sr.user_name LIMIT 1)) AS user_email, "
                           + "COALESCE(u.full_name, sr.user_name) AS safe_user_name "
                           + "FROM service_requests sr "
                           + "LEFT JOIN users u ON u.user_id = sr.user_id "
                           + "WHERE sr.request_code = ? OR sr.request_id = ? "
                           + "LIMIT 1";
                ps = conn.prepareStatement(sql);
                ps.setString(1, target);
                ps.setInt(2, parsedId);
                rs = ps.executeQuery();
                if (rs.next()) {
                    String toEmail = rs.getString("user_email");
                    String userName = rs.getString("safe_user_name");
                    String requestCode = rs.getString("request_code");
                    if (requestCode == null || requestCode.trim().isEmpty()) {
                        requestCode = "SR#" + rs.getInt("request_id");
                    }
                    String mechanicName = rs.getString("mechanic_name");
                    String vehicleNumber = rs.getString("vehicle_number");
                    String breakdownIssue = rs.getString("breakdown_issue");
                    String location = rs.getString("location");

                    if (toEmail != null && !toEmail.trim().isEmpty()) {
                        sendServiceRequestStatusEmail(toEmail.trim(), userName, requestCode, newStatus, mechanicName, vehicleNumber, breakdownIssue, location, notes);
                    } else {
                        System.out.println("[EMAIL NOTIFICATION NOTICE] No user email found for request " + requestCode);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error in notifyUserOfRequestStatusUpdate: " + e.getMessage());
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignored) {}
            if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }

    public static void notifyUserOfRequestStatusUpdateAsync(final String requestCodeOrId, final String newStatus, final String notes) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                notifyUserOfRequestStatusUpdate(requestCodeOrId, newStatus, notes);
            }
        }).start();
    }

    private static String buildServiceRequestStatusTemplate(String userName, String requestCode, String newStatus, String mechanicName, String vehicleNumber, String breakdownIssue, String location, String notes) {
        String statusColor = "#F97316";
        String statusGradient = "linear-gradient(135deg, #F97316 0%, #EA580C 100%)";
        String statusIconText = "Service Request Updated";
        String statusDescription = "Your roadside breakdown assistance request has been updated.";

        String st = (newStatus != null) ? newStatus.trim().toLowerCase() : "";
        boolean isAutoCancelled = (notes != null && notes.toLowerCase().contains("auto-cancel")) || (st.contains("cancel") && notes != null && notes.toLowerCase().contains("next stage"));

        if (isAutoCancelled) {
            statusColor = "#EA580C";
            statusGradient = "linear-gradient(135deg, #EA580C 0%, #C2410C 100%)";
            statusIconText = "Request Auto-Cancelled — Action Required";
            statusDescription = "Your request was automatically cancelled because the mechanic did not advance to the next stage within the expected timeframe. Please re-request assistance to connect with an available mechanic.";
        } else if (st.equals("accepted")) {
            statusColor = "#F97316";
            statusGradient = "linear-gradient(135deg, #F97316 0%, #EA580C 100%)";
            statusIconText = "Request Accepted by Mechanic";
            statusDescription = "A certified mechanic workshop has accepted your request and is preparing for dispatch.";
        } else if (st.contains("way") || st.contains("route")) {
            statusColor = "#F59E0B";
            statusGradient = "linear-gradient(135deg, #F59E0B 0%, #D97706 100%)";
            statusIconText = "Mechanic Is On The Way";
            statusDescription = "The technician has been dispatched and is currently traveling to your vehicle breakdown location.";
        } else if (st.contains("progress")) {
            statusColor = "#3B82F6";
            statusGradient = "linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)";
            statusIconText = "Assistance In Progress";
            statusDescription = "The mechanic has arrived on-site and inspection or repair work has commenced on your vehicle.";
        } else if (st.contains("completed")) {
            statusColor = "#10B981";
            statusGradient = "linear-gradient(135deg, #10B981 0%, #059669 100%)";
            statusIconText = "Service Successfully Completed";
            statusDescription = "Your vehicle breakdown issue has been resolved, tested, and marked as completed. Thank you for using On Road Breakdown Assistance!";
        } else if (st.contains("rejected") || st.contains("cancelled")) {
            statusColor = "#EF4444";
            statusGradient = "linear-gradient(135deg, #EF4444 0%, #B91C1C 100%)";
            statusIconText = "Request Cancelled / Unavailable";
            statusDescription = "Your service request could not be fulfilled at this time or has been cancelled.";
        }

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html><html><head><meta charset='UTF-8'></head>");
        html.append("<body style='margin:0;padding:0;background-color:#111827;font-family:Arial,sans-serif;color:#FFFFFF;'>");
        html.append("  <table width='100%' cellpadding='0' cellspacing='0' style='background-color:#111827;padding:30px 10px;'>");
        html.append("    <tr><td align='center'>");
        html.append("      <table width='560' cellpadding='0' cellspacing='0' style='background-color:#1F2937;border-radius:18px;border:1px solid #374151;overflow:hidden;box-shadow:0 12px 30px rgba(0,0,0,0.4);'>");
        html.append("        <tr><td style='background:").append(statusGradient).append(";padding:24px 30px;text-align:center;'>");
        html.append("          <h1 style='margin:0;font-size:22px;color:#FFFFFF;letter-spacing:1px;font-weight:bold;'>ON ROAD BREAKDOWN ASSISTANCE</h1>");
        html.append("          <p style='margin:6px 0 0 0;font-size:13px;color:#FEF3C7;'>Live Service Status Progression</p>");
        html.append("        </td></tr>");
        html.append("        <tr><td style='padding:30px;color:#E5E7EB;font-size:15px;line-height:1.6;'>");
        html.append("          <h2 style='margin:0 0 10px 0;font-size:18px;color:#FFFFFF;'>Hello ").append(userName).append(",</h2>");
        html.append("          <p style='margin:0 0 16px 0;color:#9CA3AF;'>We have an important real-time update regarding your breakdown assistance request <strong>").append(requestCode).append("</strong>:</p>");
        
        html.append("          <div style='background-color:#111827;border-left:4px solid ").append(statusColor).append(";border-radius:10px;padding:16px 20px;margin:20px 0;'>");
        html.append("            <div style='font-size:12px;font-weight:bold;color:").append(statusColor).append(";text-transform:uppercase;letter-spacing:1px;margin-bottom:4px;'>CURRENT STAGE</div>");
        html.append("            <div style='font-size:18px;font-weight:bold;color:#FFFFFF;margin-bottom:6px;'>").append(statusIconText).append("</div>");
        html.append("            <div style='font-size:13.5px;color:#D1D5DB;line-height:1.4;'>").append(statusDescription).append("</div>");
        html.append("          </div>");

        html.append("          <table width='100%' cellpadding='8' cellspacing='0' style='background-color:#18181B;border-radius:10px;font-size:13.5px;color:#E5E7EB;margin:18px 0;border:1px solid #27272A;'>");
        html.append("            <tr style='border-bottom:1px solid #27272A;'><td width='40%' style='color:#9CA3AF;padding:10px 14px;'>Request Code:</td><td style='color:#F97316;font-family:monospace;font-weight:bold;padding:10px 14px;'>").append(requestCode).append("</td></tr>");
        html.append("            <tr style='border-bottom:1px solid #27272A;'><td style='color:#9CA3AF;padding:10px 14px;'>Mechanic:</td><td style='color:#FFFFFF;font-weight:600;padding:10px 14px;'>").append(mechanicName).append("</td></tr>");
        html.append("            <tr style='border-bottom:1px solid #27272A;'><td style='color:#9CA3AF;padding:10px 14px;'>Vehicle:</td><td style='color:#FFFFFF;padding:10px 14px;'>").append(vehicleNumber).append("</td></tr>");
        html.append("            <tr style='border-bottom:1px solid #27272A;'><td style='color:#9CA3AF;padding:10px 14px;'>Breakdown Issue:</td><td style='color:#FFFFFF;padding:10px 14px;'>").append(breakdownIssue).append("</td></tr>");
        html.append("            <tr><td style='color:#9CA3AF;padding:10px 14px;'>Incident Location:</td><td style='color:#FFFFFF;padding:10px 14px;'>").append(location).append("</td></tr>");
        if (notes != null && !notes.trim().isEmpty()) {
            html.append("            <tr style='border-top:1px solid #27272A;'><td style='color:#9CA3AF;padding:10px 14px;'>Mechanic Remarks:</td><td style='color:#FDE68A;font-style:italic;padding:10px 14px;'>").append(notes).append("</td></tr>");
        }
        html.append("          </table>");

        html.append("          <div style='text-align:center;margin:26px 0 10px 0;'>");
        if (isAutoCancelled) {
            html.append("            <a href='").append(getAppBaseUrl()).append("/user/request-assistance.jsp?reRequest=").append(requestCode).append("' style='display:inline-block;background-color:#F97316;color:#FFFFFF;padding:14px 30px;font-size:14.5px;font-weight:bold;text-decoration:none;border-radius:10px;box-shadow:0 4px 15px rgba(249,115,22,0.45);'>");
            html.append("              &#x21bb; Re-Request Breakdown Assistance Now");
            html.append("            </a>");
        } else {
            html.append("            <a href='").append(getAppBaseUrl()).append("/user/my-requests.jsp' style='display:inline-block;background-color:#F97316;color:#FFFFFF;padding:13px 28px;font-size:14px;font-weight:bold;text-decoration:none;border-radius:10px;box-shadow:0 4px 15px rgba(249,115,22,0.35);'>");
            html.append("              View Live Status in Motorist Portal &rarr;");
            html.append("            </a>");
        }
        html.append("          </div>");

        html.append("        </td></tr>");
        html.append("        <tr><td style='background-color:#111827;padding:16px 30px;text-align:center;border-top:1px solid #374151;font-size:12px;color:#6B7280;'>");
        html.append("          24/7 Roadside Assistance Operations Desk • Helpline: <strong>1800-ROAD-HELP</strong><br>");
        html.append("          &copy; 2026 On Road Vehicle Breakdown Assistance. All rights reserved.");
        html.append("        </td></tr>");
        html.append("      </table>");
        html.append("    </td></tr>");
        html.append("  </table></body></html>");
        return html.toString();
    }

    private static String buildMechanicRejectionTemplate(String name, String workshop, String code, String reason) {
        return "<!DOCTYPE html>"
                + "<html>"
                + "<head><meta charset='UTF-8'></head>"
                + "<body style='margin:0;padding:0;background-color:#111827;font-family:Arial,sans-serif;color:#FFFFFF;'>"
                + "  <table width='100%' cellpadding='0' cellspacing='0' style='background-color:#111827;padding:30px 10px;'>"
                + "    <tr>"
                + "      <td align='center'>"
                + "        <table width='540' cellpadding='0' cellspacing='0' style='background-color:#1F2937;border-radius:18px;border:1px solid #374151;overflow:hidden;box-shadow:0 12px 30px rgba(0,0,0,0.4);'>"
                + "          <!-- Header Banner -->"
                + "          <tr>"
                + "            <td style='background:linear-gradient(135deg, #DC2626 0%, #991B1B 100%);padding:26px 30px;text-align:center;'>"
                + "              <h1 style='margin:0;font-size:22px;color:#FFFFFF;letter-spacing:1px;font-weight:bold;'>"
                + "                ON ROAD BREAKDOWN ASSISTANCE"
                + "              </h1>"
                + "              <p style='margin:6px 0 0 0;font-size:13px;color:#FECACA;'>"
                + "                Mechanic Partner Network • Application Status Update"
                + "              </p>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Content -->"
                + "          <tr>"
                + "            <td style='padding:32px 30px;color:#E5E7EB;font-size:15px;line-height:1.6;'>"
                + "              <h2 style='margin:0 0 12px 0;font-size:19px;color:#FFFFFF;'>Dear " + name + ",</h2>"
                + "              <p style='margin:0 0 16px 0;color:#9CA3AF;'>"
                + "                Thank you for applying to join the On Road Breakdown Assistance network for <strong>" + workshop + "</strong> (Application: <span style='color:#F97316;font-weight:bold;'>" + code + "</span>)."
                + "              </p>"
                + "              <p style='margin:0 0 18px 0;color:#9CA3AF;'>"
                + "                After carefully reviewing your application and verification credentials, the platform administrator was <strong style='color:#EF4444;'>unable to approve</strong> your registration at this time."
                + "              </p>"
                + "              <!-- Rejection Reason Card -->"
                + "              <div style='background-color:#18181B;border-left:4px solid #EF4444;border-radius:8px;padding:18px;margin:22px 0;box-shadow:inset 0 1px 3px rgba(0,0,0,0.3);'>"
                + "                <p style='margin:0 0 8px 0;font-size:12px;color:#EF4444;text-transform:uppercase;letter-spacing:1px;font-weight:bold;'>SPECIFIED REASON FOR REJECTION:</p>"
                + "                <p style='margin:0;font-size:15px;color:#FFFFFF;font-weight:600;line-height:1.5;'>" + reason + "</p>"
                + "              </div>"
                + "              <p style='margin:0 0 16px 0;color:#9CA3AF;'>"
                + "                <strong>What you can do next:</strong>"
                + "              </p>"
                + "              <ul style='margin:0 0 24px 0;padding-left:20px;color:#9CA3AF;font-size:14px;line-height:1.6;'>"
                + "                <li>Review the reason stated above and ensure any required identity documents or workshop details are valid and readable.</li>"
                + "                <li>If you wish to rectify this information or have updated documents, you may submit a new partner application.</li>"
                + "                <li>If you believe this decision was made in error, you may reply to this email or contact our operations desk.</li>"
                + "              </ul>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Footer -->"
                + "          <tr>"
                + "            <td style='background-color:#111827;padding:18px 30px;text-align:center;border-top:1px solid #374151;font-size:12px;color:#6B7280;'>"
                + "              Operations & Verification Desk: <strong>partner-support@roadassistance.com</strong><br>"
                + "              &copy; 2026 On Road Vehicle Breakdown Assistance. All rights reserved."
                + "            </td>"
                + "          </tr>"
                + "        </table>"
                + "      </td>"
                + "    </tr>"
                + "  </table>"
                + "</body>"
                + "</html>";
    }

    private static String buildMechanicActivationTemplate(String name, String workshop, String code, String loginUrl) {
        return "<!DOCTYPE html>"
                + "<html>"
                + "<head><meta charset='UTF-8'></head>"
                + "<body style='margin:0;padding:0;background-color:#111827;font-family:Arial,sans-serif;color:#FFFFFF;'>"
                + "  <table width='100%' cellpadding='0' cellspacing='0' style='background-color:#111827;padding:30px 10px;'>"
                + "    <tr>"
                + "      <td align='center'>"
                + "        <table width='540' cellpadding='0' cellspacing='0' style='background-color:#1F2937;border-radius:18px;border:1px solid #374151;overflow:hidden;box-shadow:0 12px 30px rgba(0,0,0,0.4);'>"
                + "          <!-- Header Banner -->"
                + "          <tr>"
                + "            <td style='background:linear-gradient(135deg, #F97316 0%, #EA580C 100%);padding:26px 30px;text-align:center;'>"
                + "              <h1 style='margin:0;font-size:22px;color:#FFFFFF;letter-spacing:1px;font-weight:bold;'>"
                + "                ON ROAD BREAKDOWN ASSISTANCE"
                + "              </h1>"
                + "              <p style='margin:6px 0 0 0;font-size:13px;color:#FEF3C7;'>"
                + "                Mechanic Partner Network • Account Activated"
                + "              </p>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Content -->"
                + "          <tr>"
                + "            <td style='padding:32px 30px;color:#E5E7EB;font-size:15px;line-height:1.6;'>"
                + "              <h2 style='margin:0 0 12px 0;font-size:19px;color:#FFFFFF;'>Welcome, " + name + "!</h2>"
                + "              <p style='margin:0 0 16px 0;color:#9CA3AF;'>"
                + "                Great news! Your mechanic partner registration for <strong>" + workshop + "</strong> has been officially reviewed and <strong style='color:#16A34A;'>APPROVED</strong> by the platform administrator."
                + "              </p>"
                + "              <!-- Activation Card -->"
                + "              <div style='background-color:#111827;border-left:4px solid #F97316;border-radius:8px;padding:18px;margin:20px 0;'>"
                + "                <p style='margin:0 0 8px 0;font-size:13px;color:#9CA3AF;'>PARTNER DETAILS:</p>"
                + "                <p style='margin:0 0 4px 0;font-size:14px;color:#FFFFFF;'><strong>Partner Code:</strong> <span style='color:#F97316;font-family:monospace;font-size:16px;font-weight:bold;'>" + code + "</span></p>"
                + "                <p style='margin:0 0 4px 0;font-size:14px;color:#FFFFFF;'><strong>Workshop:</strong> " + workshop + "</p>"
                + "                <p style='margin:0;font-size:14px;color:#FFFFFF;'><strong>Account Status:</strong> <span style='color:#16A34A;font-weight:bold;'>Active & Ready for Dispatches</span></p>"
                + "              </div>"
                + "              <p style='margin:0 0 24px 0;color:#9CA3AF;'>"
                + "                You can now log in to your Mechanic Dashboard to receive breakdown service requests, manage your garage services, and accept emergency dispatches from nearby vehicle owners."
                + "              </p>"
                + "              <!-- Login Button -->"
                + "              <div style='text-align:center;margin:26px 0;'>"
                + "                <a href='" + loginUrl + "' style='display:inline-block;background-color:#F97316;color:#FFFFFF;padding:14px 32px;font-size:15px;font-weight:bold;text-decoration:none;border-radius:10px;box-shadow:0 4px 15px rgba(249,115,22,0.4);'>"
                + "                  Login to Mechanic Dashboard &rarr;"
                + "                </a>"
                + "              </div>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Footer -->"
                + "          <tr>"
                + "            <td style='background-color:#111827;padding:18px 30px;text-align:center;border-top:1px solid #374151;font-size:12px;color:#6B7280;'>"
                + "              Need partner support? Contact our Operations Desk: <strong>partner-support@roadassistance.com</strong><br>"
                + "              &copy; 2026 On Road Vehicle Breakdown Assistance. All rights reserved."
                + "            </td>"
                + "          </tr>"
                + "        </table>"
                + "      </td>"
                + "    </tr>"
                + "  </table>"
                + "</body>"
                + "</html>";
    }

    private static String buildEmailTemplate(String otp, String email) {
        return "<!DOCTYPE html>"
                + "<html>"
                + "<head><meta charset='UTF-8'></head>"
                + "<body style='margin:0;padding:0;background-color:#111827;font-family:Arial,sans-serif;color:#FFFFFF;'>"
                + "  <table width='100%' cellpadding='0' cellspacing='0' style='background-color:#111827;padding:30px 10px;'>"
                + "    <tr>"
                + "      <td align='center'>"
                + "        <table width='540' cellpadding='0' cellspacing='0' style='background-color:#1F2937;border-radius:18px;border:1px solid #374151;overflow:hidden;box-shadow:0 12px 30px rgba(0,0,0,0.4);'>"
                + "          <!-- Header Banner -->"
                + "          <tr>"
                + "            <td style='background:linear-gradient(135deg, #F97316 0%, #EA580C 100%);padding:26px 30px;text-align:center;'>"
                + "              <h1 style='margin:0;font-size:22px;color:#FFFFFF;letter-spacing:1px;font-weight:bold;'>"
                + "                ON ROAD BREAKDOWN ASSISTANCE"
                + "              </h1>"
                + "              <p style='margin:6px 0 0 0;font-size:13px;color:#FEF3C7;'>"
                + "                24/7 Fast & Reliable Roadside Network"
                + "              </p>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Content -->"
                + "          <tr>"
                + "            <td style='padding:32px 30px;color:#E5E7EB;font-size:15px;line-height:1.6;'>"
                + "              <h2 style='margin:0 0 12px 0;font-size:19px;color:#FFFFFF;'>Verify Your Email Address</h2>"
                + "              <p style='margin:0 0 16px 0;color:#9CA3AF;'>"
                + "                Thank you for creating an account with On Road Breakdown Assistance. Please use the verification code below to complete your registration for <strong>" + email + "</strong>."
                + "              </p>"
                + "              <!-- OTP Box -->"
                + "              <div style='background-color:#111827;border:2px dashed #F97316;border-radius:12px;padding:22px;text-align:center;margin:24px 0;'>"
                + "                <span style='font-size:12px;letter-spacing:1.5px;color:#F97316;text-transform:uppercase;font-weight:bold;'>One-Time Password (OTP)</span><br>"
                + "                <span style='display:inline-block;margin-top:10px;font-size:36px;letter-spacing:10px;font-weight:bold;color:#FFFFFF;font-family:Courier,monospace;'>"
                + otp
                + "                </span>"
                + "              </div>"
                + "              <p style='margin:0 0 8px 0;font-size:13px;color:#9CA3AF;'>"
                + "                * This code will expire in <strong>5 minutes</strong>.<br>"
                + "                * If you did not request this verification, you can safely ignore this email."
                + "              </p>"
                + "            </td>"
                + "          </tr>"
                + "          <!-- Footer -->"
                + "          <tr>"
                + "            <td style='background-color:#111827;padding:18px 30px;text-align:center;border-top:1px solid #374151;font-size:12px;color:#6B7280;'>"
                + "              Need immediate roadside assistance? Call our 24/7 Helpline: <strong>1800-ROAD-HELP</strong><br>"
                + "              &copy; 2026 On Road Vehicle Breakdown Assistance. All rights reserved."
                + "            </td>"
                + "          </tr>"
                + "        </table>"
                + "      </td>"
                + "    </tr>"
                + "  </table>"
                + "</body>"
                + "</html>";
    }
}
