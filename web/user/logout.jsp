<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Prevent caching of logout response
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session != null) {
        session.removeAttribute("user");
        session.removeAttribute("userRole");
        try {
            session.invalidate();
        } catch (IllegalStateException ignored) {}
    }
    response.sendRedirect(request.getContextPath() + "/index.jsp");
%>
