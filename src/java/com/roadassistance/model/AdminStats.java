package com.roadassistance.model;

import java.io.Serializable;

public class AdminStats implements Serializable {
    private static final long serialVersionUID = 1L;

    private int totalUsers = 256;
    private int totalMechanics = 112;
    private int pendingApprovals = 18;
    private int approvedMechanics = 94;
    private int blockedMechanics = 6;
    private int totalRequests = 428;
    private int pendingRequests = 52;
    private int completedRequests = 336;
    private int rejectedRequests = 24;
    private int inProgressRequests = 16;

    public AdminStats() {
    }

    public AdminStats(int totalUsers, int totalMechanics, int pendingApprovals, int approvedMechanics,
                      int blockedMechanics, int totalRequests, int pendingRequests, int completedRequests,
                      int rejectedRequests, int inProgressRequests) {
        this.totalUsers = totalUsers;
        this.totalMechanics = totalMechanics;
        this.pendingApprovals = pendingApprovals;
        this.approvedMechanics = approvedMechanics;
        this.blockedMechanics = blockedMechanics;
        this.totalRequests = totalRequests;
        this.pendingRequests = pendingRequests;
        this.completedRequests = completedRequests;
        this.rejectedRequests = rejectedRequests;
        this.inProgressRequests = inProgressRequests;
    }

    public int getTotalUsers() { return totalUsers; }
    public void setTotalUsers(int totalUsers) { this.totalUsers = totalUsers; }

    public int getTotalMechanics() { return totalMechanics; }
    public void setTotalMechanics(int totalMechanics) { this.totalMechanics = totalMechanics; }

    public int getPendingApprovals() { return pendingApprovals; }
    public void setPendingApprovals(int pendingApprovals) { this.pendingApprovals = pendingApprovals; }

    public int getApprovedMechanics() { return approvedMechanics; }
    public void setApprovedMechanics(int approvedMechanics) { this.approvedMechanics = approvedMechanics; }

    public int getBlockedMechanics() { return blockedMechanics; }
    public void setBlockedMechanics(int blockedMechanics) { this.blockedMechanics = blockedMechanics; }

    public int getTotalRequests() { return totalRequests; }
    public void setTotalRequests(int totalRequests) { this.totalRequests = totalRequests; }

    public int getPendingRequests() { return pendingRequests; }
    public void setPendingRequests(int pendingRequests) { this.pendingRequests = pendingRequests; }

    public int getCompletedRequests() { return completedRequests; }
    public void setCompletedRequests(int completedRequests) { this.completedRequests = completedRequests; }

    public int getRejectedRequests() { return rejectedRequests; }
    public void setRejectedRequests(int rejectedRequests) { this.rejectedRequests = rejectedRequests; }

    public int getInProgressRequests() { return inProgressRequests; }
    public void setInProgressRequests(int inProgressRequests) { this.inProgressRequests = inProgressRequests; }

    public double getCompletedPercentage() {
        if (totalRequests == 0) return 0;
        return Math.round((completedRequests * 100.0 / totalRequests) * 10.0) / 10.0;
    }

    public double getPendingPercentage() {
        if (totalRequests == 0) return 0;
        return Math.round((pendingRequests * 100.0 / totalRequests) * 10.0) / 10.0;
    }

    public double getRejectedPercentage() {
        if (totalRequests == 0) return 0;
        return Math.round((rejectedRequests * 100.0 / totalRequests) * 10.0) / 10.0;
    }

    public double getInProgressPercentage() {
        if (totalRequests == 0) return 0;
        return Math.round((inProgressRequests * 100.0 / totalRequests) * 10.0) / 10.0;
    }
}
