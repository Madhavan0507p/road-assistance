package com.roadassistance.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Enterprise Session & Cache Security Filter.
 * 
 * 1. Disables browser caching (no-cache, no-store, must-revalidate) on all protected pages
 *    so that clicking the browser "Back" button after logout does not reveal cached content.
 * 2. Checks active session authentication for User, Mechanic, and Admin modules.
 *    If unauthenticated or session has been invalidated, immediately redirects to the login page.
 */
@WebFilter(filterName = "SessionSecurityFilter", urlPatterns = {"/user/*", "/mechanic/*", "/admin/*"})
public class SessionSecurityFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Force browser to NEVER cache protected responses (prevents back-button access after logout)
        httpResponse.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
        httpResponse.setHeader("Pragma", "no-cache"); // HTTP 1.0
        httpResponse.setDateHeader("Expires", 0); // Proxies

        String uri = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();
        String path = uri.substring(contextPath.length());

        // Allow static resources through
        String lowerPath = path.toLowerCase();
        if (lowerPath.endsWith(".css") || lowerPath.endsWith(".js") || lowerPath.endsWith(".png")
                || lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg") || lowerPath.endsWith(".gif")
                || lowerPath.endsWith(".svg") || lowerPath.endsWith(".ico") || lowerPath.endsWith(".woff")
                || lowerPath.endsWith(".woff2")) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = httpRequest.getSession(false);

        // =====================================================================
        // 1. USER MODULE SECURITY
        // =====================================================================
        if (path.startsWith("/user/")) {
            boolean isPublicUserUrl = path.endsWith("/user/login.jsp")
                    || path.endsWith("/user/register.jsp")
                    || path.endsWith("/user/forgot-password.jsp")
                    || path.endsWith("/user/logout.jsp");

            if (!isPublicUserUrl) {
                if (session == null || session.getAttribute("user") == null) {
                    httpResponse.sendRedirect(contextPath + "/user/login.jsp?msg=auth_required");
                    return;
                }
            }
        }

        // =====================================================================
        // 2. MECHANIC MODULE SECURITY
        // =====================================================================
        else if (path.startsWith("/mechanic/")) {
            boolean isPublicMechUrl = path.endsWith("/mechanic/login.jsp")
                    || path.endsWith("/mechanic/register.jsp")
                    || path.contains("register-step")
                    || path.endsWith("/mechanic/forgot-password.jsp")
                    || path.endsWith("/mechanic/logout.jsp");

            if (!isPublicMechUrl) {
                if (session == null || session.getAttribute("mechanic") == null) {
                    httpResponse.sendRedirect(contextPath + "/mechanic/login.jsp?msg=auth_required");
                    return;
                }
                com.roadassistance.model.Mechanic mechObj = (com.roadassistance.model.Mechanic) session.getAttribute("mechanic");
                if (mechObj == null || !mechObj.isApproved()) {
                    session.removeAttribute("mechanic");
                    String redirectParam = (mechObj != null && mechObj.isBlocked()) ? "error=blocked" : "error=pending";
                    httpResponse.sendRedirect(contextPath + "/mechanic/login.jsp?" + redirectParam);
                    return;
                }
            }
        }

        // =====================================================================
        // 3. ADMIN MODULE SECURITY
        // =====================================================================
        else if (path.startsWith("/admin/")) {
            boolean isPublicAdminUrl = path.endsWith("/admin/login.jsp")
                    || path.endsWith("/admin/logout.jsp");

            if (!isPublicAdminUrl) {
                if (session == null || session.getAttribute("admin") == null) {
                    httpResponse.sendRedirect(contextPath + "/admin/login.jsp?msg=auth_required");
                    return;
                }
            }
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup if needed
    }
}
