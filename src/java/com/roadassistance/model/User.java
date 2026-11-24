package com.roadassistance.model;

import java.io.Serializable;

public class User implements Serializable {
    private static final long serialVersionUID = 1L;

    private int userId;
    private String firstName;
    private String lastName;
    private String fullName;
    private String email;
    private String phone;
    private String gender; // "Male", "Female", "Other", "Prefer not to say"
    private String dob; // "YYYY-MM-DD"
    private String password;
    private String address;
    private String status; // "Active", "Inactive", "Blocked"
    private boolean emailVerified;
    private boolean termsAccepted;
    private String createdAt;

    public User() {
        this.status = "Active";
        this.gender = "Prefer not to say";
        this.emailVerified = false;
        this.termsAccepted = true;
    }

    public User(int userId, String fullName, String email, String phone, String password, String address, String status) {
        this();
        this.userId = userId;
        this.fullName = fullName;
        if (fullName != null) {
            String[] parts = fullName.trim().split("\\s+", 2);
            this.firstName = parts[0];
            this.lastName = parts.length > 1 ? parts[1] : "";
        }
        this.email = email;
        this.phone = phone;
        this.password = password;
        this.address = address;
        this.status = status;
    }

    public User(int userId, String firstName, String lastName, String email, String phone, String gender, String password, String address, String status, boolean emailVerified) {
        this.userId = userId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.fullName = (firstName != null ? firstName : "") + (lastName != null && !lastName.isEmpty() ? " " + lastName : "");
        this.email = email;
        this.phone = phone;
        this.gender = gender;
        this.password = password;
        this.address = address;
        this.status = status;
        this.emailVerified = emailVerified;
        this.termsAccepted = true;
    }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { 
        this.firstName = firstName; 
        updateFullName();
    }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { 
        this.lastName = lastName; 
        updateFullName();
    }

    public String getFullName() { 
        if (fullName == null || fullName.trim().isEmpty()) {
            updateFullName();
        }
        return fullName; 
    }
    public void setFullName(String fullName) { 
        this.fullName = fullName; 
        if (fullName != null && (firstName == null || firstName.isEmpty())) {
            String[] parts = fullName.trim().split("\\s+", 2);
            this.firstName = parts[0];
            this.lastName = parts.length > 1 ? parts[1] : "";
        }
    }

    private void updateFullName() {
        StringBuilder sb = new StringBuilder();
        if (firstName != null && !firstName.trim().isEmpty()) {
            sb.append(firstName.trim());
        }
        if (lastName != null && !lastName.trim().isEmpty()) {
            if (sb.length() > 0) sb.append(" ");
            sb.append(lastName.trim());
        }
        this.fullName = sb.toString();
    }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public String getDob() { return dob; }
    public void setDob(String dob) { this.dob = dob; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isEmailVerified() { return emailVerified; }
    public void setEmailVerified(boolean emailVerified) { this.emailVerified = emailVerified; }

    public boolean isTermsAccepted() { return termsAccepted; }
    public void setTermsAccepted(boolean termsAccepted) { this.termsAccepted = termsAccepted; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public boolean isActive() {
        return "Active".equalsIgnoreCase(this.status);
    }

    public boolean isInactive() {
        return "Inactive".equalsIgnoreCase(this.status);
    }

    public boolean isBlocked() {
        return "Blocked".equalsIgnoreCase(this.status);
    }
}
