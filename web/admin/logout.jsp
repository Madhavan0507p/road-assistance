<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Invalidate HTTP session on the JSP layer and route to Servlet for complete session lifecycle termination
    if (session != null) {
        session.invalidate();
    }
    response.sendRedirect(request.getContextPath() + "/AuthServlet?action=logout&role=admin");
%>
