package com.roadassistance.model;

import java.io.Serializable;

public class Mechanic implements Serializable {
    private static final long serialVersionUID = 1L;

    private int mechanicId;
    private String mechanicCode;
    private String workshopName;
    private String ownerName;
    private String specialization;
    private String phone;
    private String email;
    private String password;
    private String location;
    private String address;
    private double latitude;
    private double longitude;
    private String serviceTypes;
    private String approvalStatus; // "Pending", "Approved", "Blocked", "Rejected"
    private String blockedReason;
    private boolean isAvailable;
    private double rating;
    private String createdAt;

    // Detailed 5-Step Wizard Attributes
    private String firstName;
    private String lastName;
    private String gender;
    private String dob;
    private boolean emailVerified;
    private String shopName;
    private String shopType;
    private String shopContactNumber;
    private String yearsOfExperience;
    private String openingTime;
    private String closingTime;
    private String shopDescription;
    private String otherSpecialization;
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String district;
    private String state;
    private String pincode;
    private String accountStatus;
    private String aadhaarNumber;
    private String aadhaarCardDoc;
    private String idProofDoc;
    private java.util.List<String> specializations = new java.util.ArrayList<String>();
    private java.util.List<String> shopPhotos = new java.util.ArrayList<String>();

    public Mechanic() {
        this.approvalStatus = "Pending";
        this.isAvailable = false;
        this.accountStatus = "Active";
        this.rating = 4.8;
        this.openingTime = "09:00 AM";
        this.closingTime = "07:00 PM";
        this.state = "Tamil Nadu";
    }

    public Mechanic(int mechanicId, String workshopName, String ownerName, String phone, String email,
                    String password, String address, String approvalStatus) {
        this.mechanicId = mechanicId;
        this.workshopName = workshopName;
        this.ownerName = ownerName;
        this.phone = phone;
        this.email = email;
        this.password = password;
        this.address = address;
        this.approvalStatus = approvalStatus;
        this.isAvailable = true;
        this.rating = 4.8;
    }

    public int getMechanicId() { return mechanicId; }
    public void setMechanicId(int mechanicId) { this.mechanicId = mechanicId; }

    public String getMechanicCode() { return mechanicCode; }
    public void setMechanicCode(String mechanicCode) { this.mechanicCode = mechanicCode; }

    public String getWorkshopName() { return workshopName; }
    public void setWorkshopName(String workshopName) { this.workshopName = workshopName; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getSpecialization() { return specialization; }
    public void setSpecialization(String specialization) { this.specialization = specialization; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }

    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }

    public String getServiceTypes() { return serviceTypes; }
    public void setServiceTypes(String serviceTypes) { this.serviceTypes = serviceTypes; }

    public String getApprovalStatus() { return approvalStatus; }
    public void setApprovalStatus(String approvalStatus) { this.approvalStatus = approvalStatus; }

    public String getBlockedReason() { return blockedReason; }
    public void setBlockedReason(String blockedReason) { this.blockedReason = blockedReason; }

    public boolean isAvailable() { return isAvailable; }
    public void setAvailable(boolean available) { isAvailable = available; }

    public double getRating() { return rating; }
    public void setRating(double rating) { this.rating = rating; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public boolean isApproved() {
        return "Approved".equalsIgnoreCase(this.approvalStatus);
    }

    public boolean isPending() {
        return "Pending".equalsIgnoreCase(this.approvalStatus);
    }

    public boolean isBlocked() {
        return "Blocked".equalsIgnoreCase(this.approvalStatus) || "Blocked".equalsIgnoreCase(this.accountStatus);
    }

    public boolean isRejected() {
        return "Rejected".equalsIgnoreCase(this.approvalStatus);
    }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public String getDob() { return dob; }
    public void setDob(String dob) { this.dob = dob; }

    public boolean isEmailVerified() { return emailVerified; }
    public void setEmailVerified(boolean emailVerified) { this.emailVerified = emailVerified; }

    public String getShopName() { return shopName != null ? shopName : workshopName; }
    public void setShopName(String shopName) { this.shopName = shopName; if (this.workshopName == null) this.workshopName = shopName; }

    public String getShopType() { return shopType; }
    public void setShopType(String shopType) { this.shopType = shopType; }

    public String getShopContactNumber() { return shopContactNumber != null ? shopContactNumber : phone; }
    public void setShopContactNumber(String shopContactNumber) { this.shopContactNumber = shopContactNumber; }

    public String getYearsOfExperience() { return yearsOfExperience; }
    public void setYearsOfExperience(String yearsOfExperience) { this.yearsOfExperience = yearsOfExperience; }

    public String getOpeningTime() { return openingTime; }
    public void setOpeningTime(String openingTime) { this.openingTime = openingTime; }

    public String getClosingTime() { return closingTime; }
    public void setClosingTime(String closingTime) { this.closingTime = closingTime; }

    public String getShopDescription() { return shopDescription; }
    public void setShopDescription(String shopDescription) { this.shopDescription = shopDescription; }

    public String getOtherSpecialization() { return otherSpecialization; }
    public void setOtherSpecialization(String otherSpecialization) { this.otherSpecialization = otherSpecialization; }

    public String getAddressLine1() { return addressLine1; }
    public void setAddressLine1(String addressLine1) { this.addressLine1 = addressLine1; }

    public String getAddressLine2() { return addressLine2; }
    public void setAddressLine2(String addressLine2) { this.addressLine2 = addressLine2; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getDistrict() { return district; }
    public void setDistrict(String district) { this.district = district; }

    public String getState() { return state; }
    public void setState(String state) { this.state = state; }

    public String getPincode() { return pincode; }
    public void setPincode(String pincode) { this.pincode = pincode; }

    public String getAccountStatus() { return accountStatus; }
    public void setAccountStatus(String accountStatus) { this.accountStatus = accountStatus; }

    public java.util.List<String> getSpecializations() { return specializations; }
    public void setSpecializations(java.util.List<String> specializations) { this.specializations = specializations; }

    public java.util.List<String> getShopPhotos() { return shopPhotos; }
    public void setShopPhotos(java.util.List<String> shopPhotos) { this.shopPhotos = shopPhotos; }

    public String getAadhaarNumber() { return aadhaarNumber; }
    public void setAadhaarNumber(String aadhaarNumber) { this.aadhaarNumber = aadhaarNumber; }

    public String getAadhaarCardDoc() { return aadhaarCardDoc; }
    public void setAadhaarCardDoc(String aadhaarCardDoc) { this.aadhaarCardDoc = aadhaarCardDoc; }

    public String getIdProofDoc() { return idProofDoc; }
    public void setIdProofDoc(String idProofDoc) { this.idProofDoc = idProofDoc; }
}
