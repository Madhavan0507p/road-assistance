package com.roadassistance.controller;

import com.roadassistance.dao.AdminDAO;
import com.roadassistance.dao.MechanicDAO;
import com.roadassistance.dao.UserDAO;
import com.roadassistance.model.Admin;
import com.roadassistance.model.Mechanic;
import com.roadassistance.model.User;

import java.io.PrintWriter;
import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "AuthServlet", urlPatterns = {"/auth/login", "/auth/logout", "/AuthServlet", "/mechanic/login", "/LogoutServlet"})
public class AuthServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final MechanicDAO mechanicDAO = new MechanicDAO();
    private final AdminDAO adminDAO = new AdminDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        String role = request.getParameter("role");
        String servletPath = request.getServletPath();

        if ("logout".equalsIgnoreCase(action) || "/auth/logout".equalsIgnoreCase(servletPath) || "/LogoutServlet".equalsIgnoreCase(servletPath)) {
            handleLogout(request, response, role);
            return;
        }

        // Direct GET redirect to appropriate login page
        String contextPath = request.getContextPath();
        if ("/mechanic/login".equalsIgnoreCase(servletPath) || "mechanic".equalsIgnoreCase(role)) {
            response.sendRedirect(contextPath + "/mechanic/login.jsp");
        } else if ("admin".equalsIgnoreCase(role)) {
            response.sendRedirect(contextPath + "/admin/login.jsp");
        } else {
            response.sendRedirect(contextPath + "/user/login.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        String role = request.getParameter("role");
        String servletPath = request.getServletPath();

        if ("/mechanic/login".equalsIgnoreCase(servletPath)) {
            role = "mechanic";
        }

        if ("logout".equalsIgnoreCase(action) || "/auth/logout".equalsIgnoreCase(servletPath)) {
            handleLogout(request, response, role);
            return;
        }

        if ("admin".equalsIgnoreCase(role)) {
            handleAdminLogin(request, response);
        } else if ("mechanic".equalsIgnoreCase(role)) {
            handleMechanicLogin(request, response);
        } else {
            handleUserLogin(request, response);
        }
    }

    private void handleUserLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            email = request.getParameter("identifier");
        }
        if (email == null || email.trim().isEmpty()) {
            email = request.getParameter("emailOrPhone");
        }
        String password = request.getParameter("password");
        String contextPath = request.getContextPath();

        // Check if user account exists and is blocked by admin
        User existingUser = userDAO.findByEmail(email);
        if (existingUser != null && existingUser.isBlocked()) {
            response.sendRedirect(contextPath + "/user/login.jsp?error=blocked");
            return;
        }

        User user = userDAO.authenticate(email, password);

        if (user == null) {
            response.sendRedirect(contextPath + "/user/login.jsp?error=invalid_credentials");
            return;
        }

        if (user.isBlocked()) {
            response.sendRedirect(contextPath + "/user/login.jsp?error=blocked");
            return;
        }

        if (user.isInactive()) {
            response.sendRedirect(contextPath + "/user/login.jsp?error=account_inactive");
            return;
        }

        // Authentication successful
        HttpSession session = request.getSession(true);
        session.setAttribute("user", user);
        session.setAttribute("userRole", "user");
        session.setAttribute("userName", user.getFullName());
        session.setAttribute("userEmail", user.getEmail());

        response.sendRedirect(contextPath + "/user/dashboard.jsp");
    }

    private void handleMechanicLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String email = request.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            email = request.getParameter("identifier");
        }
        String password = request.getParameter("password");
        String contextPath = request.getContextPath();

        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"))
                || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"));

        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            sendMechanicResponse(request, response, isAjax, false, "Please enter both your registered email and password.", "invalid_credentials", null);
            return;
        }

        // Check if mechanic account exists and is blocked by admin
        Mechanic existingMech = mechanicDAO.findByEmail(email);
        if (existingMech != null && existingMech.isBlocked()) {
            String msg = "Your mechanic account has been blocked by administrator. You cannot sign in. Please contact support.";
            sendMechanicResponse(request, response, isAjax, false, msg, "blocked", existingMech.getWorkshopName());
            return;
        }

        Mechanic mech = mechanicDAO.authenticate(email, password);

        if (mech == null) {
            sendMechanicResponse(request, response, isAjax, false, "Invalid email or password.", "invalid_credentials", null);
            return;
        }

        // Status verification
        if (mech.isPending()) {
            String msg = "Your mechanic account is awaiting administrator approval.";
            sendMechanicResponse(request, response, isAjax, false, msg, "pending", mech.getWorkshopName());
            return;
        }

        if (mech.isBlocked()) {
            String msg = "Your mechanic account is currently blocked. Please contact support.";
            sendMechanicResponse(request, response, isAjax, false, msg, "blocked", mech.getWorkshopName());
            return;
        }

        if (mech.isRejected()) {
            String msg = "Your mechanic account application was not approved. Please contact support.";
            sendMechanicResponse(request, response, isAjax, false, msg, "rejected", mech.getWorkshopName());
            return;
        }

        if (mech.isApproved()) {
            // Authentication and approval verified
            HttpSession session = request.getSession(true);
            session.setAttribute("mechanic", mech);
            session.setAttribute("userRole", "mechanic");
            session.setAttribute("role", "mechanic");
            session.setAttribute("mechanicId", mech.getMechanicId());
            session.setAttribute("mechanicCode", mech.getMechanicCode());
            session.setAttribute("mechanicName", mech.getOwnerName());
            session.setAttribute("mechName", mech.getOwnerName());
            session.setAttribute("mechWorkshop", mech.getWorkshopName());
            session.setAttribute("mechanicEmail", mech.getEmail());

            String redirectUrl = contextPath + "/mechanic/dashboard.jsp";
            if (isAjax) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                out.print("{\"success\": true, \"message\": \"Login successful! Redirecting to Mechanic Dashboard...\", \"redirectUrl\": \"" + redirectUrl + "\"}");
            } else {
                response.sendRedirect(redirectUrl);
            }
        } else {
            sendMechanicResponse(request, response, isAjax, false, "Unable to sign in due to account status.", "unknown_status", null);
        }
    }

    private void sendMechanicResponse(HttpServletRequest request, HttpServletResponse response, boolean isAjax, boolean success, String message, String errorParam, String workshop)
            throws IOException {
        if (isAjax) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            String cleanMsg = message.replace("\\", "\\\\").replace("\"", "\\\"");
            out.print("{\"success\": " + success + ", \"message\": \"" + cleanMsg + "\"}");
        } else {
            String redirectUrl = request.getContextPath() + "/mechanic/login.jsp?error=" + errorParam;
            if (workshop != null && !workshop.trim().isEmpty()) {
                redirectUrl += "&workshop=" + URLEncoder.encode(workshop.trim(), "UTF-8");
            }
            response.sendRedirect(redirectUrl);
        }
    }

    private void handleAdminLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String identifier = request.getParameter("identifier");
        if (identifier == null || identifier.trim().isEmpty()) {
            identifier = request.getParameter("username");
        }
        if (identifier == null || identifier.trim().isEmpty()) {
            identifier = request.getParameter("email");
        }
        String password = request.getParameter("password");
        String contextPath = request.getContextPath();

        Admin admin = adminDAO.authenticate(identifier, password);

        if (admin == null) {
            response.sendRedirect(contextPath + "/admin/login.jsp?error=invalid_credentials");
            return;
        }

        // Authentication successful - create session
        HttpSession session = request.getSession(true);
        session.setAttribute("admin", admin);
        session.setAttribute("userRole", "admin");
        session.setAttribute("adminName", admin.getFullName());
        session.setAttribute("adminUsername", admin.getUsername());
        session.setAttribute("adminEmail", admin.getEmail());
        session.setAttribute("adminRole", admin.getRole());
        session.setAttribute("adminId", admin.getAdminId());

        response.sendRedirect(contextPath + "/admin/dashboard.jsp");
    }

    private void handleLogout(HttpServletRequest request, HttpServletResponse response, String role)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.removeAttribute("user");
            session.removeAttribute("mechanic");
            session.removeAttribute("admin");
            session.removeAttribute("userRole");
            try {
                session.invalidate();
            } catch (IllegalStateException ignored) {
            }
        }

        // Prevent browser back-button caching
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
        response.setHeader("Pragma", "no-cache"); // HTTP 1.0
        response.setDateHeader("Expires", 0); // Proxies

        String contextPath = request.getContextPath();
        // Redirect directly to the home page (index.jsp)
        response.sendRedirect(contextPath + "/index.jsp");
    }
}
