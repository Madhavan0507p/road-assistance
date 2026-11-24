# =============================================================================
# Multi-stage Dockerfile for On Road Vehicle Breakdown Assistance
# Production deployment on Render.com with Apache Tomcat 9
# =============================================================================

# Stage 1: Build ROOT.war with Maven
FROM maven:3.9-eclipse-temurin-11 AS builder
WORKDIR /app

# Cache Maven dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy application source code and web resources
COPY src ./src
COPY web ./web

# Compile and package ROOT.war
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime Container with Apache Tomcat 9
FROM tomcat:9.0-jdk11-corretto

LABEL maintainer="Road Assistance Dev Team"
LABEL description="On Road Vehicle Breakdown Assistance Cloud Web Application"

# Remove default Tomcat webapps (manager, docs, default ROOT)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy packaged application to Tomcat ROOT context
COPY --from=builder /app/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

# Create and grant write permissions for upload storage directories
RUN mkdir -p /usr/local/tomcat/webapps/ROOT/uploads/mechanic_documents \
             /usr/local/tomcat/webapps/ROOT/uploads/mechanic_photos \
             /usr/local/tomcat/webapps/ROOT/uploads/vehicles && \
    chmod -R 777 /usr/local/tomcat/webapps/ROOT/uploads

# Configure default port for Render ($PORT)
ENV PORT=8080
EXPOSE 8080

# Dynamically bind Tomcat to Render's $PORT environment variable and start Tomcat
CMD ["sh", "-c", "sed -i \"s/port=\\\"8080\\\"/port=\\\"${PORT:-8080}\\\"/g\" /usr/local/tomcat/conf/server.xml && catalina.sh run"]
