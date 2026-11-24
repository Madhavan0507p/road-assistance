# Complete Guide: Deploying Road Assistance on Render with Aiven MySQL

This guide walks you through deploying the **On Road Vehicle Breakdown Assistance** application to **Render.com** using **Aiven for MySQL** as your cloud database.

---

## Architecture Overview

```
  +-------------------------------------------------------------+
  |                        RENDER.COM                           |
  |                                                             |
  |   +-----------------------------------------------------+   |
  |   | Docker Container (Apache Tomcat 9 / Java 11)        |   |
  |   |                                                     |   |
  |   |   ROOT.war (Servlets, JSPs, CSS, JS, Media)         |   |
  |   |   DBConnection.java (Auto-SSL, Cloud Resilient)     |   |
  |   +-----------------------------------------------------+   |
  +------------------------------|------------------------------+
                                 |
                     TLS/SSL Encrypted (Port 25xxx)
                                 |
  +------------------------------v------------------------------+
  |                       AIVEN.IO                              |
  |   Cloud Managed MySQL 8.0+ Service                          |
  |   Database: defaultdb / road_assistance_db                  |
  |   8 Tables + Pre-seeded Sample Records & Default Admins     |
  +-------------------------------------------------------------+
```

---

## Step 1: Set Up Aiven for MySQL Database

### 1.1 Create MySQL Service in Aiven
1. Sign up or log in at [https://aiven.io](https://aiven.io).
2. Click **Create Service**.
3. Select **MySQL**.
4. Choose **Cloud Provider & Region** (e.g. AWS, Google Cloud, or Azure — pick a region closest to your users, e.g. Singapore, Frankfurt, or Oregon).
5. Select the **Free Tier** or **Startup Plan**.
6. Set the Service Name to `road-assistance-mysql` and click **Create Service**.

### 1.2 Copy Connection Details
Once the service status turns **Running**, go to the **Overview** tab:
You will see:
- **Host**: e.g. `mysql-3xxxx-yourname.aivencloud.com`
- **Port**: e.g. `25432`
- **User**: `avnadmin`
- **Password**: Click to reveal and copy your password
- **Database**: `defaultdb`
- **SSL Mode**: `REQUIRED` (Handled automatically by the updated `DBConnection.java`)

---

## Step 2: Import Database Schema & Seed Data to Aiven

We have generated a ready-to-run SQL setup file in your project root:
📂 `road_assistance_aiven_dump.sql`

You can import it into Aiven using any of the following methods:

### Option A: Aiven Web Console (Easiest — No local tools required)
1. In your Aiven Console, click on your MySQL service.
2. In the left menu, select **Query editor** (or **Databases**).
3. Open `road_assistance_aiven_dump.sql` from your project in a text editor (Notepad, VS Code, etc.).
4. Copy the entire contents, paste it into the Aiven Query Editor, and click **Run**.

### Option B: Using DBeaver / MySQL Workbench / HeidiSQL
1. Open DBeaver or MySQL Workbench.
2. Create a new MySQL Connection:
   - **Host**: Your Aiven Host
   - **Port**: Your Aiven Port
   - **Database**: `defaultdb`
   - **Username**: `avnadmin`
   - **Password**: Your Aiven Password
   - **SSL**: Set SSL Mode to `Required`
3. Connect, open `road_assistance_aiven_dump.sql`, and execute script.

### Option C: Using MySQL CLI (Command Line)
```bash
mysql -h <AIVEN_HOST> -P <AIVEN_PORT> -u avnadmin -p defaultdb < road_assistance_aiven_dump.sql
```

> **Note**: Even if you skip manual import, the application's `DBConnection.java` will automatically create all 8 core tables and default admin credentials upon first startup!

---

## Step 3: Push Project to GitHub

1. Open a terminal in your project directory:
   ```powershell
   cd "c:\Users\madhavan\Documents\NetBeansProjects\Road Assistance"
   ```
2. Initialize and commit your project (if not already done):
   ```bash
   git init
   git add .
   git commit -m "Configure project for Render and Aiven MySQL deployment"
   ```
3. Create a new private or public repository on GitHub (e.g. `road-assistance`).
4. Link and push to GitHub:
   ```bash
   git remote add origin https://github.com/<your-username>/road-assistance.git
   git branch -M main
   git push -u origin main
   ```

---

## Step 4: Deploy Web Service on Render.com

### 4.1 Create Web Service
1. Sign up or log in at [https://render.com](https://render.com).
2. In your Render Dashboard, click **New +** (top right) and select **Web Service**.
3. Select **Build and deploy from a Git repository** and connect your GitHub repository (`road-assistance`).

### 4.2 Configure Service Settings
Fill in the following details:
- **Name**: `road-assistance` (this becomes `https://road-assistance.onrender.com`)
- **Region**: Choose the region closest to your Aiven database (e.g. `Singapore` or `Oregon`)
- **Branch**: `main`
- **Runtime**: **Docker** (Render will automatically detect `Dockerfile`)
- **Instance Type**: **Free**

### 4.3 Add Environment Variables
Scroll down to the **Environment Variables** section and add the following:

| Key | Value | Example |
| :--- | :--- | :--- |
| `DB_HOST` | Your Aiven MySQL Host | `mysql-3xxxx-account.aivencloud.com` |
| `DB_PORT` | Your Aiven MySQL Port | `25432` |
| `DB_NAME` | Your Aiven Database Name | `defaultdb` |
| `DB_USER` | `avnadmin` | `avnadmin` |
| `DB_PASSWORD` | Your Aiven MySQL Password | `AVNS_xxxx...` |
| `DB_SSL` | `true` | `true` |
| `APP_URL` | Your Render Public URL | `https://road-assistance.onrender.com` |

*(Optional)* If you wish to send live OTP emails via Gmail SMTP:
| Key | Value |
| :--- | :--- |
| `SMTP_USER` | `your_gmail_address@gmail.com` |
| `SMTP_PASS` | Your 16-character Google App Password |

### 4.4 Deploy
Click **Create Web Service**!
Render will:
1. Pull the Docker image with Maven and Apache Tomcat 9.
2. Compile and package `ROOT.war`.
3. Launch Tomcat and expose the service on your public Render HTTPS domain.
4. Deployment typically finishes within 2-3 minutes.

---

## Step 5: Test & Verify Your Live Cloud Application

Once the deployment shows **Live** in green:
1. Open your live URL: `https://road-assistance.onrender.com`
2. **Admin Portal**:
   - Navigate to `/admin/login.jsp`
   - Login with:
     - Username: `admin`
     - Password: `123` (or `admin123`)
3. **User Portal**:
   - Navigate to `/user/login.jsp`
   - Login with sample user or click Register
4. **Mechanic Portal**:
   - Navigate to `/mechanic/login.jsp`
   - Login with sample approved mechanic (`madhavan0507@gmail.com` / `1234`)

---

## Key Files Created in Your Project

| File | Purpose |
| :--- | :--- |
| `road_assistance_aiven_dump.sql` | Complete database schema + seed data ready for Aiven import |
| `Dockerfile` | Multi-stage production container build (Maven + Tomcat 9) |
| `pom.xml` | Standard Maven descriptor mapping sources and dependencies |
| `.dockerignore` | Excludes unnecessary build artifacts to keep Docker builds fast |
| `render.yaml` | Render Blueprint configuration for automated infrastructure setup |
| `.env.example` | Template reference for all environment variables |
| `src/.../DBConnection.java` | Updated cloud-resilient DB manager with automatic SSL detection |
