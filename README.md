# On Road Vehicle Breakdown Assistance

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/Madhavan0507p/road-assistance)

A comprehensive, production-grade roadside assistance management web application connecting motorists in distress with nearby qualified mechanics and towing services.

---

## Features

- **Multi-Role Portals**: Motorist/User Portal, Mechanic/Workshop Portal, and Administrator Command Center.
- **Location & Radius Search**: Real-time breakdown incident dispatching with interactive mapping.
- **Service Request Lifecycle**: Pending &rarr; Accepted &rarr; In Progress &rarr; Completed &rarr; Auto-Cancelled timeout protection.
- **Cloud Database Support**: Pre-configured for **Aiven for MySQL** with automatic SSL detection and connection pooling.
- **Containerized Architecture**: Multi-stage Dockerfile packaging Apache Tomcat 9 and Java 11 for instant deployment on **Render.com**.

---

## 🚀 1-Click Deployment on Render

Click the button above or follow the step-by-step guide in [DEPLOY_TO_RENDER_AND_AIVEN.md](DEPLOY_TO_RENDER_AND_AIVEN.md).

### Required Environment Variables

| Variable | Description | Example |
| :--- | :--- | :--- |
| `DB_HOST` | Aiven MySQL Host | `mysql-xxxx.aivencloud.com` |
| `DB_PORT` | Aiven MySQL Port | `25432` |
| `DB_NAME` | Aiven Database Name | `defaultdb` |
| `DB_USER` | Database Username | `avnadmin` |
| `DB_PASSWORD` | Database Password | `your_aiven_password` |
| `DB_SSL` | Enable SSL Mode (Required for Aiven) | `true` |
| `APP_URL` | Live Application URL | `https://road-assistance.onrender.com` |

---

## 🗄️ Database Setup (Aiven for MySQL)

1. Create a MySQL service on [Aiven.io](https://aiven.io).
2. Open the Aiven **Query Editor** (or connect via MySQL Workbench / DBeaver).
3. Import the complete database script: [road_assistance_aiven_dump.sql](road_assistance_aiven_dump.sql).
4. *(Self-Healing Feature)*: Even if you skip manual import, the application automatically provisions all 8 tables and default administrators on first launch!

---

## 🔑 Default Credentials

- **Admin Portal** (`/admin/login.jsp`): `admin` / `123` or `admin123`
- **User Portal** (`/user/login.jsp`): `madhavan0507p@gmail.com` / `123`
- **Mechanic Portal** (`/mechanic/login.jsp`): `madhavan0507@gmail.com` / `1234`
