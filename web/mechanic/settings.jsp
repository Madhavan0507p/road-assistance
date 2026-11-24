<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent browser back-button caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    com.roadassistance.model.Mechanic currentMech = (com.roadassistance.model.Mechanic) session.getAttribute("mechanic");
    if (currentMech == null || !currentMech.isApproved()) {
        if (session != null) {
            session.removeAttribute("mechanic");
        }
        String redirectParam = (currentMech != null && currentMech.isBlocked()) ? "error=blocked" : ((currentMech != null && currentMech.isPending()) ? "error=pending" : "msg=auth_required");
        response.sendRedirect(request.getContextPath() + "/mechanic/login.jsp?" + redirectParam);
        return;
    }

    request.setAttribute("activeMechPage", "settings");
    request.setAttribute("pageTitle", "Mechanic Settings");
    request.setAttribute("pageSubtitle", "Configure dispatch radius, sound alerts and towing availability");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mechanic Settings — Mechanic Portal</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mechanic-dashboard.css">
</head>
<body>

    <!-- 1. Top Navigation Bar -->
    <jsp:include page="topbar.jsp" />

    <!-- 2. Shell Layout: Fixed Left Sidebar + Main White Canvas -->
    <div class="mech-dashboard-shell">
        <jsp:include page="sidebar.jsp" />

        <main class="mech-main-canvas">
            <div style="max-width: 860px; margin: 0 auto; width: 100%;">
                <div style="background: #FFFFFF; border-radius: 20px; box-shadow: 0 4px 25px rgba(0,0,0,0.04); border: 1px solid #E2E8F0; padding: 28px 32px;">
                    <div style="display: flex; align-items: center; gap: 14px; margin-bottom: 24px; padding-bottom: 18px; border-bottom: 1px solid #F1F5F9;">
                        <div style="width: 44px; height: 44px; border-radius: 12px; background: rgba(249, 115, 22, 0.12); color: #F97316; display: flex; align-items: center; justify-content: center; font-size: 20px;">
                            <i class="fa-solid fa-gear"></i>
                        </div>
                        <div>
                            <h2 style="font-size: 22px; font-weight: 800; color: #1F2937; margin: 0;">Dispatch Preferences</h2>
                            <p style="color: #64748B; font-size: 13px; margin: 2px 0 0 0;">Manage your automated alerts and emergency availability</p>
                        </div>
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 18px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; padding: 14px 0; border-bottom: 1px solid #E5E7EB;">
                            <div>
                                <h4 style="font-size: 15px; font-weight: 700; color: #1F2937; margin: 0 0 4px 0;">Sound Alert for Incoming Breakdowns</h4>
                                <p style="font-size: 12.5px; color: #6B7280; margin: 0;">Play emergency chime when motorist requests help nearby</p>
                            </div>
                            <input type="checkbox" checked style="width: 20px; height: 20px; accent-color: #F97316;">
                        </div>

                        <div style="display: flex; justify-content: space-between; align-items: center; padding: 14px 0; border-bottom: 1px solid #E5E7EB;">
                            <div>
                                <h4 style="font-size: 15px; font-weight: 700; color: #1F2937; margin: 0 0 4px 0;">Towing Crane Availability</h4>
                                <p style="font-size: 12.5px; color: #6B7280; margin: 0;">Indicate whether your flatbed tow truck is ready for dispatch</p>
                            </div>
                            <input type="checkbox" checked style="width: 20px; height: 20px; accent-color: #F97316;">
                        </div>

                        <button type="button" style="align-self: flex-start; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFFFFF; font-weight: 700; padding: 11px 24px; border-radius: 12px; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; font-size: 14px;" onclick="alert('Preferences saved successfully!');">
                            <i class="fa-solid fa-floppy-disk"></i> Save Preferences
                        </button>
                    </div>
                </div>
            </div>
        </main>
    </div>

</body>
</html>
