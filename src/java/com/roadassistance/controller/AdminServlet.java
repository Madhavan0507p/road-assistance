package com.roadassistance.controller;

import com.roadassistance.dao.AdminDAO;
import com.roadassistance.model.AdminStats;
import com.roadassistance.model.ServiceRequest;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "AdminServlet", urlPatterns = {"/admin/dashboard", "/AdminServlet"})
public class AdminServlet extends HttpServlet {

    private final AdminDAO adminDAO = new AdminDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Session protection
        if (request.getSession(false) == null || request.getSession(false).getAttribute("admin") == null) {
            response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=auth_required");
            return;
        }

        AdminStats stats = adminDAO.getAdminStats();
        List<ServiceRequest> recentRequests = adminDAO.getRecentRequests(5);

        request.setAttribute("adminStats", stats);
        request.setAttribute("recentRequests", recentRequests);

        request.getRequestDispatcher("/admin/dashboard.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
