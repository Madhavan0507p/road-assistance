<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="com.roadassistance.model.User" %>
<%@ page import="com.roadassistance.dao.UserDAO" %>
<%@ page import="com.roadassistance.util.DBConnection" %>
<%
    // Prevent browser caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 1. Session Authentication Check
    User sessionUser = (User) session.getAttribute("user");
    if (sessionUser == null) {
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?msg=auth_required");
        return;
    }

    UserDAO userDAO = new UserDAO();

    // 2. Handle POST Profile Update (Strictly Only Mobile Number is Editable)
    String updateStatus = request.getParameter("msg");
    String errorMessage = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        request.setCharacterEncoding("UTF-8");
        // Strictly preserve locked demographic & identity fields: only mobile number is editable
        String uFirstName = sessionUser.getFirstName();
        String uLastName = sessionUser.getLastName();
        String uDob = sessionUser.getDob();
        String uGender = sessionUser.getGender();
        String uAddress = sessionUser.getAddress() != null ? sessionUser.getAddress() : "";
        String uPhone = request.getParameter("phone");

        // Server-side validation for phone
        boolean valid = true;
        if (uPhone == null || !uPhone.trim().matches("^[6-9][0-9]{9}$")) {
            valid = false;
            errorMessage = "Please enter a valid 10-digit Indian mobile number starting with 6-9.";
        }

        if (valid) {
            boolean updated = userDAO.updateProfile(sessionUser.getUserId(), uFirstName, uLastName, uGender, uDob, uPhone.trim(), uAddress);
            if (updated) {
                User freshUser = userDAO.findById(sessionUser.getUserId());
                if (freshUser != null) {
                    session.setAttribute("user", freshUser);
                    session.setAttribute("userName", freshUser.getFullName());
                    sessionUser = freshUser;
                }
                response.sendRedirect(request.getContextPath() + "/user/profile.jsp?msg=updated");
                return;
            } else {
                errorMessage = "Failed to update profile details in the database. Please try again.";
            }
        }
    }

    // 3. Fetch Fresh User Profile from Database
    User user = userDAO.findById(sessionUser.getUserId());
    if (user == null) {
        user = sessionUser;
    } else {
        session.setAttribute("user", user);
    }

    request.setAttribute("activeUserPage", "profile");

    // Dynamic Current Date Display
    SimpleDateFormat sdfDisplayDate = new SimpleDateFormat("dd-MM-yyyy");
    String currentDateStr = sdfDisplayDate.format(new Date());

    // Calculate age and format DOB as dd-MM-yyyy if DOB present
    String ageDisplay = "";
    String formattedDob = "Not specified";
    if (user.getDob() != null && !user.getDob().trim().isEmpty()) {
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            Date bDate = sdf.parse(user.getDob().trim());
            Calendar c = Calendar.getInstance();
            c.setTime(bDate);
            Calendar now = Calendar.getInstance();
            int a = now.get(Calendar.YEAR) - c.get(Calendar.YEAR);
            if (now.get(Calendar.DAY_OF_YEAR) < c.get(Calendar.DAY_OF_YEAR)) a--;
            if (a >= 0) ageDisplay = " (" + a + " years old)";
            formattedDob = new SimpleDateFormat("dd-MM-yyyy").format(bDate);
        } catch (Exception ignored) {
            formattedDob = user.getDob().trim();
        }
    }
    String formattedPhone = (user.getPhone() != null && !user.getPhone().trim().isEmpty()) ? user.getPhone().trim() : "Not registered";
    String formattedGender = (user.getGender() != null && !user.getGender().trim().isEmpty()) ? user.getGender().trim() : "Prefer not to say";
    String userCode = "USR" + String.format("%03d", user.getUserId());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile — On Road Vehicle Breakdown Assistance</title>
    
    <!-- Google Fonts & Font Awesome Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- App & Profile Styles -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-dashboard.css?v=2.1">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-profile.css?v=2.1">
</head>
<body>

    <!-- 1. Dark Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Dark Sidebar + Main Canvas -->
    <div class="dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="main-dashboard-canvas">
            
            <!-- Page Header (Compact) -->
            <div class="user-profile-header">
                <div class="user-profile-title-col">
                    <h1 class="user-profile-heading">Motorist <span class="highlight">Profile</span></h1>
                    <p class="user-profile-subheading">Personal credentials and verified contact channels</p>
                </div>
                <div class="user-date-card">
                    <i class="fa-regular fa-calendar"></i>
                    <span><%= currentDateStr %></span>
                </div>
            </div>

            <!-- Flash Alert: Success / Error -->
            <% if ("updated".equals(updateStatus)) { %>
                <div class="profile-alert-success" id="alertSuccess">
                    <i class="fa-solid fa-circle-check"></i>
                    <span>Your primary mobile number has been saved and updated successfully!</span>
                </div>
            <% } %>

            <% if (errorMessage != null) { %>
                <div class="profile-alert-error" id="alertError">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                    <span><%= errorMessage %></span>
                </div>
            <% } %>

            <!-- Hero Summary Card (Compact) -->
            <div class="profile-hero-card">
                <div class="profile-hero-left">
                    <div class="profile-avatar-wrap">
                        <i class="fa-solid fa-user"></i>
                    </div>
                    <div class="profile-hero-meta">
                        <div class="profile-hero-name-row">
                            <h2 class="profile-hero-name"><%= user.getFullName() %></h2>
                            <% if (user.isActive()) { %>
                                <span class="status-badge active"><i class="fa-solid fa-shield-check"></i> Active Motorist</span>
                            <% } else if (user.isBlocked()) { %>
                                <span class="status-badge blocked"><i class="fa-solid fa-ban"></i> Account Blocked</span>
                            <% } else { %>
                                <span class="status-badge active"><i class="fa-solid fa-circle-check"></i> Registered</span>
                            <% } %>
                        </div>
                        <div class="profile-hero-tags">
                            <span><i class="fa-solid fa-id-badge"></i> #<%= userCode %></span>
                            <span><i class="fa-solid fa-phone"></i> <%= formattedPhone %></span>
                            <span><i class="fa-solid fa-envelope"></i> <%= user.getEmail() %></span>
                        </div>
                    </div>
                </div>

                <div class="profile-hero-actions">
                    <button type="button" class="btn-action-primary" id="btnToggleEdit">
                        <i class="fa-solid fa-pen-to-square"></i>
                        <span id="btnToggleEditText">Edit Profile</span>
                    </button>
                </div>
            </div>

            <!-- =============================================================
                 1. VIEW MODE (Default Compact Read-Only Display)
                 ============================================================= -->
            <div id="viewProfileSection">
                
                <!-- Section 1: Personal Credentials -->
                <div class="profile-section-card">
                    <div class="profile-section-head">
                        <div class="section-icon-badge">
                            <i class="fa-solid fa-user"></i>
                        </div>
                        <div>
                            <h3 class="section-head-title">Personal Credentials</h3>
                            <p class="section-head-subtitle">Verified motorist identity and demographic details</p>
                        </div>
                    </div>

                    <div class="profile-details-grid">
                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-user"></i> First Name</span>
                            <div class="detail-value-box highlight"><%= user.getFirstName() != null ? user.getFirstName() : "—" %></div>
                        </div>

                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-user"></i> Last Name</span>
                            <div class="detail-value-box highlight"><%= user.getLastName() != null ? user.getLastName() : "—" %></div>
                        </div>

                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-venus-mars"></i> Gender</span>
                            <div class="detail-value-box"><%= formattedGender %></div>
                        </div>

                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-cake-candles"></i> Date of Birth</span>
                            <div class="detail-value-box"><%= formattedDob %><%= ageDisplay %></div>
                        </div>
                    </div>
                </div>

                <!-- Section 2: Contact Information -->
                <div class="profile-section-card">
                    <div class="profile-section-head">
                        <div class="section-icon-badge">
                            <i class="fa-solid fa-address-book"></i>
                        </div>
                        <div>
                            <h3 class="section-head-title">Contact & Communication Channels</h3>
                            <p class="section-head-subtitle">Registered contact phone and login credentials</p>
                        </div>
                    </div>

                    <div class="profile-details-grid">
                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-envelope"></i> Registered Email</span>
                            <div class="detail-value-box">
                                <%= user.getEmail() %>
                                <span class="locked-indicator"><i class="fa-solid fa-lock"></i> Locked</span>
                            </div>
                        </div>

                        <div class="detail-item">
                            <span class="detail-label"><i class="fa-solid fa-phone"></i> Primary Mobile Number</span>
                            <div class="detail-value-box highlight">+91 <%= formattedPhone %></div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- =============================================================
                 2. EDIT MODE (Hidden by Default, Only Mobile Number Editable)
                 ============================================================= -->
            <form action="${pageContext.request.contextPath}/user/profile.jsp" method="POST" id="editProfileForm" style="display: none;" novalidate>
                
                <!-- Section 1: Personal Credentials (Permanently Locked) -->
                <div class="profile-section-card">
                    <div class="profile-section-head">
                        <div class="section-icon-badge">
                            <i class="fa-solid fa-user-lock"></i>
                        </div>
                        <div>
                            <h3 class="section-head-title">Personal Credentials</h3>
                            <p class="section-head-subtitle">Verified motorist identity and demographic details (locked)</p>
                        </div>
                    </div>

                    <div class="edit-form-grid">
                        <!-- First Name (Locked) -->
                        <div class="form-group">
                            <label class="field-label" for="inputFirstName" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-user"></i> First Name</span>
                                <span class="locked-badge"><i class="fa-solid fa-lock"></i> Locked</span>
                            </label>
                            <input type="text" id="inputFirstName" class="field-input disabled" value="<%= user.getFirstName() != null ? user.getFirstName() : "" %>" readonly title="First Name is verified and locked">
                            <span class="field-locked-hint"><i class="fa-solid fa-circle-info"></i> Legal identity name is verified and locked.</span>
                        </div>

                        <!-- Last Name (Locked) -->
                        <div class="form-group">
                            <label class="field-label" for="inputLastName" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-user"></i> Last Name</span>
                                <span class="locked-badge"><i class="fa-solid fa-lock"></i> Locked</span>
                            </label>
                            <input type="text" id="inputLastName" class="field-input disabled" value="<%= user.getLastName() != null ? user.getLastName() : "" %>" readonly title="Last Name is verified and locked">
                            <span class="field-locked-hint"><i class="fa-solid fa-circle-info"></i> Legal identity name is verified and locked.</span>
                        </div>

                        <!-- Gender (Locked) -->
                        <div class="form-group">
                            <label class="field-label" for="inputGender" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-venus-mars"></i> Gender</span>
                                <span class="locked-badge"><i class="fa-solid fa-lock"></i> Locked</span>
                            </label>
                            <input type="text" id="inputGender" class="field-input disabled" value="<%= formattedGender %>" readonly title="Gender is set at registration and locked">
                            <span class="field-locked-hint"><i class="fa-solid fa-circle-info"></i> Gender is registered and locked.</span>
                        </div>

                        <!-- Date of Birth (Locked) -->
                        <div class="form-group">
                            <label class="field-label" for="inputDob" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-cake-candles"></i> Date of Birth</span>
                                <span class="locked-badge"><i class="fa-solid fa-lock"></i> Locked</span>
                            </label>
                            <input type="text" id="inputDob" class="field-input disabled" value="<%= user.getDob() != null ? user.getDob().trim() : "" %>" readonly title="Date of Birth is verified and locked">
                            <span class="field-locked-hint"><i class="fa-solid fa-circle-info"></i> Date of birth is verified and locked.</span>
                        </div>
                    </div>
                </div>

                <!-- Section 2: Contact Credentials (Only Mobile Number Editable) -->
                <div class="profile-section-card">
                    <div class="profile-section-head">
                        <div class="section-icon-badge">
                            <i class="fa-solid fa-phone"></i>
                        </div>
                        <div>
                            <h3 class="section-head-title">Contact Credentials</h3>
                            <p class="section-head-subtitle">Update your primary mobile number for breakdown dispatch and emergency alerts</p>
                        </div>
                    </div>

                    <div class="edit-form-grid">
                        <!-- Email (Locked) -->
                        <div class="form-group">
                            <label class="field-label" for="inputEmailLocked" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-envelope"></i> Registered Email</span>
                                <span class="locked-badge"><i class="fa-solid fa-lock"></i> Locked</span>
                            </label>
                            <input type="email" id="inputEmailLocked" class="field-input disabled" value="<%= user.getEmail() %>" disabled readonly title="Registered email address is verified and permanently locked.">
                            <span class="field-locked-hint"><i class="fa-solid fa-circle-info"></i> Registered email address cannot be changed.</span>
                        </div>

                        <!-- Phone Number (Editable) -->
                        <div class="form-group">
                            <label class="field-label" for="inputPhone" style="display:flex; justify-content:space-between; align-items:center;">
                                <span><i class="fa-solid fa-phone"></i> Primary Mobile Number <span class="req">*</span></span>
                                <span class="badge-editable-tag"><i class="fa-solid fa-pen"></i> Editable</span>
                            </label>
                            <input type="tel" id="inputPhone" name="phone" class="field-input editable-active" value="<%= user.getPhone() != null ? user.getPhone().trim() : "" %>" maxlength="10" inputmode="numeric" required placeholder="Enter 10-digit mobile number">
                            <span class="field-instruction" id="errPhone">Please enter a valid 10-digit Indian mobile number starting with 6-9.</span>
                            <span class="field-locked-hint" style="color: #64748B;"><i class="fa-solid fa-circle-check" style="color: #10B981;"></i> Only the primary mobile number is editable in profile settings.</span>
                        </div>
                    </div>
                </div>

                <!-- Form Action Buttons -->
                <div class="form-footer-actions">
                    <button type="button" class="btn-action-secondary" id="btnCancelEdit">
                        <i class="fa-solid fa-xmark"></i>
                        <span>Cancel</span>
                    </button>
                    <button type="submit" class="btn-action-primary" id="btnSaveProfile">
                        <i class="fa-solid fa-floppy-disk"></i>
                        <span>Save Profile Changes</span>
                    </button>
                </div>

            </form>

        </main>
    </div>

    <!-- Client-Side Toggle & Validation Controller -->
    <script>
        (function() {
            var viewSection = document.getElementById("viewProfileSection");
            var editForm = document.getElementById("editProfileForm");
            var btnToggle = document.getElementById("btnToggleEdit");
            var btnCancel = document.getElementById("btnCancelEdit");
            var inpPhone = document.getElementById("inputPhone");
            var errPhone = document.getElementById("errPhone");
            var form = document.getElementById("editProfileForm");

            function switchToEditMode() {
                viewSection.style.display = "none";
                editForm.style.display = "block";
                btnToggle.style.display = "none";
                if (inpPhone) {
                    inpPhone.focus();
                }
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }

            function switchToViewMode() {
                editForm.style.display = "none";
                viewSection.style.display = "block";
                btnToggle.style.display = "inline-flex";
            }

            if (btnToggle) {
                btnToggle.addEventListener("click", switchToEditMode);
            }

            if (btnCancel) {
                btnCancel.addEventListener("click", switchToViewMode);
            }

            function validatePhone() {
                if (!inpPhone) return true;
                var v = (inpPhone.value || "").trim();
                var valid = /^[6-9][0-9]{9}$/.test(v);
                if (errPhone) errPhone.style.display = valid ? "none" : "flex";
                inpPhone.style.borderColor = valid ? "#CBD5E1" : "#EF4444";
                return valid;
            }

            if (inpPhone) {
                inpPhone.addEventListener("input", function() {
                    this.value = this.value.replace(/[^0-9]/g, "");
                    validatePhone();
                });
            }

            if (form) {
                form.addEventListener("submit", function(e) {
                    if (!validatePhone()) {
                        e.preventDefault();
                        if (inpPhone) inpPhone.focus();
                    }
                });
            }

        })();
    </script>
</body>
</html>
