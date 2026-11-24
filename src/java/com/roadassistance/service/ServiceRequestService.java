package com.roadassistance.service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import com.roadassistance.util.DBConnection;
import com.roadassistance.util.EmailUtil;

/**
 * Service to manage service request lifecycles, including auto-cancelling
 * accepted requests that stagnate without moving to the next stage, and
 * intimating the user to re-request assistance.
 */
public class ServiceRequestService {

    // Default threshold for stagnant accepted requests: 15 minutes
    public static final int DEFAULT_STAGNANT_TIMEOUT_MINUTES = 15;

    private static final AtomicBoolean daemonStarted = new AtomicBoolean(false);
    private static ScheduledExecutorService scheduler;

    static {
        startBackgroundMonitor();
    }

    /**
     * Starts the background daemon timer that runs periodic checks.
     */
    public static synchronized void startBackgroundMonitor() {
        if (daemonStarted.compareAndSet(false, true)) {
            try {
                scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
                    Thread t = new Thread(r, "ServiceRequest-AutoCancel-Daemon");
                    t.setDaemon(true);
                    return t;
                });
                // Check periodically every 60 seconds (initial delay 10s)
                scheduler.scheduleWithFixedDelay(() -> {
                    try {
                        autoCancelStagnantAcceptedRequests(DEFAULT_STAGNANT_TIMEOUT_MINUTES);
                    } catch (Throwable t) {
                        System.err.println("[AutoCancelDaemon] Error in periodic check: " + t.getMessage());
                    }
                }, 10, 60, TimeUnit.SECONDS);
                System.out.println("[ServiceRequestService] Background auto-cancel daemon successfully scheduled (Interval: 60s, Timeout: " + DEFAULT_STAGNANT_TIMEOUT_MINUTES + "m).");
            } catch (Exception e) {
                System.err.println("[ServiceRequestService] Failed to start auto-cancel daemon: " + e.getMessage());
            }
        }
    }

    /**
     * Auto-cancels stagnant requests using the default timeout (15 mins).
     */
    public static int autoCancelStagnantAcceptedRequests() {
        return autoCancelStagnantAcceptedRequests(DEFAULT_STAGNANT_TIMEOUT_MINUTES);
    }

    /**
     * Auto-cancels stagnant requests with a specified timeout in minutes.
     */
    public static int autoCancelStagnantAcceptedRequests(int timeoutMinutes) {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            if (conn != null) {
                return autoCancelStagnantAcceptedRequests(conn, timeoutMinutes);
            }
        } catch (Exception e) {
            System.err.println("[ServiceRequestService] Error acquiring DB connection: " + e.getMessage());
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (Exception ignored) {}
            }
        }
        return 0;
    }

    /**
     * Auto-cancels requests in 'Accepted' status that have not progressed to
     * 'On The Way', 'In Progress', or 'Completed' within timeoutMinutes.
     * Updates status to 'Cancelled' and intimates the user via email.
     */
    public static int autoCancelStagnantAcceptedRequests(Connection conn, int timeoutMinutes) {
        if (conn == null) return 0;
        int cancelledCount = 0;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

        try {
            // Find requests in 'Accepted' status that have exceeded the timeout without advancing to next stage
            String selectSql = 
                "SELECT request_id, request_code, user_name, vehicle_number, breakdown_issue, " +
                "       location, mechanic_name, mechanic_code, additional_details, assigned_at, requested_at " +
                "FROM service_requests " +
                "WHERE status = 'Accepted' " +
                "  AND ( " +
                "    (assigned_at IS NOT NULL AND TIMESTAMPDIFF(MINUTE, assigned_at, NOW()) >= ?) " +
                "    OR (assigned_at IS NULL AND TIMESTAMPDIFF(MINUTE, requested_at, NOW()) >= ?) " +
                "  )";

            psSelect = conn.prepareStatement(selectSql);
            psSelect.setInt(1, timeoutMinutes);
            psSelect.setInt(2, timeoutMinutes);
            rs = psSelect.executeQuery();

            List<StagnantRequest> list = new ArrayList<StagnantRequest>();
            while (rs.next()) {
                StagnantRequest r = new StagnantRequest();
                r.requestId = rs.getInt("request_id");
                r.requestCode = rs.getString("request_code");
                r.userName = rs.getString("user_name");
                r.vehicleNumber = rs.getString("vehicle_number");
                r.breakdownIssue = rs.getString("breakdown_issue");
                r.location = rs.getString("location");
                r.mechanicName = rs.getString("mechanic_name");
                list.add(r);
            }
            rs.close();
            psSelect.close();

            if (!list.isEmpty()) {
                String updateSql = 
                    "UPDATE service_requests " +
                    "SET status = 'Cancelled', " +
                    "    completed_at = CURRENT_TIMESTAMP(), " +
                    "    completed_date = DATE_FORMAT(NOW(), '%d-%m-%Y · %h:%i %p'), " +
                    "    additional_details = CONCAT(IFNULL(additional_details, ''), ' | [Auto-cancelled: The mechanic did not move the process to the next stage within the required timeframe. Please re-request assistance.]') " +
                    "WHERE request_id = ? AND status = 'Accepted'";

                psUpdate = conn.prepareStatement(updateSql);

                for (StagnantRequest item : list) {
                    psUpdate.setInt(1, item.requestId);
                    int rows = psUpdate.executeUpdate();
                    if (rows > 0) {
                        cancelledCount++;
                        System.out.println("[ServiceRequestService] Auto-cancelled stagnant accepted request: " + item.requestCode + " (Vehicle: " + item.vehicleNumber + ")");
                        // Intimate the user asynchronously
                        String cancellationNote = "Your service request was automatically cancelled because the mechanic did not advance the request to the next stage within the required timeframe. Please re-request breakdown assistance.";
                        EmailUtil.notifyUserOfRequestStatusUpdateAsync(item.requestCode, "Cancelled", cancellationNote);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[ServiceRequestService] Error auto-cancelling stagnant requests: " + e.getMessage());
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignored) {}
            if (psSelect != null) try { psSelect.close(); } catch (Exception ignored) {}
            if (psUpdate != null) try { psUpdate.close(); } catch (Exception ignored) {}
        }
        return cancelledCount;
    }

    private static class StagnantRequest {
        int requestId;
        String requestCode;
        String userName;
        String vehicleNumber;
        String breakdownIssue;
        String location;
        String mechanicName;
    }
}
