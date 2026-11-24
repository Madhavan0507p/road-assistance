<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String id = request.getParameter("id");
    if (id == null || id.trim().isEmpty()) {
        id = request.getParameter("code");
    }
    if (id == null || id.trim().isEmpty()) {
        id = "SR0456";
    }
    response.sendRedirect(request.getContextPath() + "/admin/service-requests.jsp?view=" + java.net.URLEncoder.encode(id, "UTF-8"));
%>
