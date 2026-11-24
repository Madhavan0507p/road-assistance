package com.roadassistance.model;

import java.io.Serializable;

public class ServiceRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    private int requestId;
    private String requestCode;
    private String userName;
    private String userPhone;
    private String vehicleNo;
    private String vehicleModel;
    private String issue;
    private String status;
    private String requestDate;
    private String locationAddress;
    private double estimatedCost;

    public ServiceRequest() {
    }

    public ServiceRequest(int requestId, String requestCode, String userName, String vehicleNo,
                          String issue, String status, String requestDate) {
        this.requestId = requestId;
        this.requestCode = requestCode;
        this.userName = userName;
        this.vehicleNo = vehicleNo;
        this.issue = issue;
        this.status = status;
        this.requestDate = requestDate;
    }

    public int getRequestId() { return requestId; }
    public void setRequestId(int requestId) { this.requestId = requestId; }

    public String getRequestCode() { return requestCode; }
    public void setRequestCode(String requestCode) { this.requestCode = requestCode; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserPhone() { return userPhone; }
    public void setUserPhone(String userPhone) { this.userPhone = userPhone; }

    public String getVehicleNo() { return vehicleNo; }
    public void setVehicleNo(String vehicleNo) { this.vehicleNo = vehicleNo; }

    public String getVehicleModel() { return vehicleModel; }
    public void setVehicleModel(String vehicleModel) { this.vehicleModel = vehicleModel; }

    public String getIssue() { return issue; }
    public void setIssue(String issue) { this.issue = issue; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRequestDate() { return requestDate; }
    public void setRequestDate(String requestDate) { this.requestDate = requestDate; }

    public String getLocationAddress() { return locationAddress; }
    public void setLocationAddress(String locationAddress) { this.locationAddress = locationAddress; }

    public double getEstimatedCost() { return estimatedCost; }
    public void setEstimatedCost(double estimatedCost) { this.estimatedCost = estimatedCost; }
}
