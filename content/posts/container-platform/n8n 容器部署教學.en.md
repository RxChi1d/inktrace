---
title: "n8n Container Deployment Guide - Docker Compose, Redis, and Reverse Proxy Setup"
slug: "n8n-deployment"
date: 2025-11-29T21:46:47+08:00
tags: ["docker", "n8n", "redis", "nginx-proxy-manager"]
categories: ["container-platform"]
---

This guide details how to deploy the n8n workflow automation platform using Docker Compose. It covers basic configuration, integrating Redis for caching, and setting up a reverse proxy via Nginx Proxy Manager for secure HTTPS access.

<!--more-->

## Introduction

[n8n](https://n8n.io/) is an open-source workflow automation platform that provides a visual node-based interface for connecting services and automating tasks, similar to Zapier or Make (formerly Integromat). With support for over 400 integrations, n8n allows for self-hosting, giving you complete control over your data privacy and security.

Deploying n8n with Docker offers several advantages:

- **Environment Isolation**: Prevents conflicts with other system services.
- **Easy Maintenance**: Simplified updates and backups.
- **Cross-Platform Support**: Runs on any system that supports Docker.
- **Resource Management**: Allows you to limit container resource usage.

This guide covers:

1. Basic n8n container deployment and initialization.
2. Integrating Redis caching for performance.
3. Setting up a reverse proxy with Nginx Proxy Manager.
4. Troubleshooting common issues.

### Prerequisites

Before proceeding, ensure you have:

- ✅ Docker and Docker Compose installed ([Installation Guide](https://docs.docker.com/engine/install/)).
- ✅ Basic familiarity with command-line operations.
- ✅ (Optional) A domain name and a deployed instance of Nginx Proxy Manager.

> [!TIP]
> This tutorial is intended for users with basic Docker knowledge. If you are new to Docker, I recommend familiarizing yourself with basic commands like `docker compose up` and `docker compose down` first.

## Basic Deployment: n8n Container

### Directory Structure

First, create the directories to store n8n data. Data persistence ensures that workflows, credentials, and other data remain intact across container restarts.

```bash
# Create data directories
sudo mkdir -p /appdata/n8n/data
sudo mkdir -p /appdata/n8n/files

# Change owner to 1000:1000 (n8n container default user) to avoid permission errors
sudo chown -R 1000:1000 /appdata/n8n
```

Directory Details:

- `/appdata/n8n/data`: Stores core data such as the database, workflows, and credentials.
- `/appdata/n8n/files`: Stores files processed within workflows.

> [!NOTE]
> You can adjust these paths as needed, but ensure Docker has read/write permissions. If you are using a non-root user, it is recommended to place directories within your home directory (e.g., `~/appdata/n8n`).

### Creating docker-compose.yml

Create a file named `docker-compose.yml` with the following content:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - /appdata/n8n/data:/home/node/.n8n
      - /appdata/n8n/files:/files
    environment:
      - N8N_PORT=5678
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```

#### Key Environment Variables

| Variable | Description | Default |
|---------|------|--------|
| `N8N_PORT` | Port the n8n web interface listens on internally | `5678` |
| `NODE_ENV` | Node.js execution environment (`production` or `development`) | `production` |
| `GENERIC_TIMEZONE` | Timezone used internally by n8n | `America/New_York` |
| `TZ` | System timezone for the container | `UTC` |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | Enforces permission checks on the config file for better security | `false` |

> [!INFO]
> Timezone settings are critical for scheduled workflows. `GENERIC_TIMEZONE` affects time logic within workflows, while `TZ` affects the container's system time. Ideally, both should be set to the same value.

### Starting the Container

Run the following command in the directory containing your `docker-compose.yml`:

```bash
# Start n8n container in detached mode
docker compose up -d
```

Verify the container status:

```bash
# Check container status
docker compose ps
```

You should see output similar to this:

```
NAME      IMAGE            COMMAND                  SERVICE   CREATED         STATUS         PORTS
n8n       n8nio/n8n:latest "tini -- /docker-ent…"   n8n       10 seconds ago  Up 9 seconds   0.0.0.0:5678->5678/tcp
```

### Accessing the Interface

Open your browser and navigate to `http://localhost:5678`.
If deploying on a remote server, replace `localhost` with your server's IP address.

> [!WARNING]
> n8n does not enable authentication by default in this configuration. If you are deploying on a public network, you must set up a reverse proxy and enable basic authentication (detailed in later sections).

### Initial Setup

On your first visit, n8n will ask you to create an owner account:

1.  **Account Details**:
    *   Email: Your email address.
    *   Name: Your display name.
    *   Password: Use a strong password.

2.  **Finalize**:
    *   Click "Get Started" to enter the main interface.

3.  **Interface Overview**:
    *   **Workflows**: Manage and create workflows.
    *   **Credentials**: Store authentication details for third-party services.
    *   **Executions**: View workflow execution history.
    *   **Settings**: System configuration.

Congratulations! You have successfully deployed the basic version of n8n. Next, we will integrate Redis to improve performance.

## Redis Integration

### Why Use Redis?

Redis is a high-performance in-memory database. In n8n, you can utilize Redis via **Redis nodes within your workflows** for caching operations:

-   **Cache API Responses**: Prevent redundant external API calls to reduce latency and costs.
-   **Store Temporary Variables**: Share data between different workflow executions.
-   **Rate Limiting**: Track API usage counts.
-   **Cache Computation Results**: Avoid re-running resource-intensive data processing.

**Use Cases**:

-   ✅ Frequently calling the same external API.
-   ✅ Sharing state across multiple workflows.
-   ✅ Implementing custom caching logic.

> [!NOTE]
> **About Queue Mode**: n8n also supports using Redis as a message broker for **Queue Mode**, which allows for high-concurrency scaling. This requires additional configuration (including environment variables and worker containers) and is beyond the scope of this guide. For more details, refer to the [n8n Queue Mode documentation](https://docs.n8n.io/hosting/scaling/queue-mode/).

### Updating docker-compose.yml

Stop the existing container:

```bash
docker compose down
```

Edit `docker-compose.yml` to add the Redis service and network configuration:

```yaml
services:
  n8n:
    # ... other configs remain unchanged
    depends_on:
      - redis  # Added: Ensure Redis starts first
    networks:
      - n8n-network

  redis:
    image: redis:alpine
    container_name: n8n-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - /appdata/n8n/redis/data:/data
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

networks:
  n8n-network:
    # ... network configuration remains unchanged
```

#### Configuration Details

**Redis Image Choice**:
-   We use `redis:alpine` instead of `redis:<version>` (e.g., `redis:8`).
-   The Alpine version contains only the core Redis functionality, removing extras like bash and git.
-   It is ideal for a pure caching database and offers a smaller footprint (approx. 30MB vs 120MB).

**Important Parameters**:
-   `--appendonly yes`: Enables AOF (Append-Only File) persistence, ensuring data isn't lost on container restarts (requires the volume mount).
-   `healthcheck`: Periodically checks Redis health to ensure availability.

**Network Settings**:
-   `networks`: Places n8n and Redis on the same network so they can communicate.
-   `depends_on`: Ensures Redis starts before n8n.

### Create Redis Data Directory

```bash
sudo mkdir -p /appdata/n8n/redis/data
# Note: Redis container typically runs as root or redis user,
# standard docker permission handling usually works fine here,
# but check logs if issues arise.
```

### Start Services

```bash
docker compose up -d
```

### Verifying Redis Operation (Optional)

While you can test the connection directly via an n8n workflow, you can also verify Redis is running via the CLI.

**1. Check Container Logs**:

```bash
# Check Redis logs
docker compose logs redis
```

You should see output indicating the server is ready to accept connections.

**2. Test Redis Connection**:

```bash
# Test Redis connection
docker exec -it n8n-redis redis-cli ping
```

Expected response:
```
PONG
```

### Using Redis in Workflows

Your Redis container is ready! To use it within an n8n workflow:

**1. Add a Redis Node**:
Search for and add the "Redis" node in the n8n editor.

**2. Configure Connection**:
Create a new Redis Credential with the following details:
-   **Host**: `n8n-redis` (The container name in the Docker network).
-   **Port**: `6379`.
-   **Password**: Leave empty (default config has no password).
-   **Database**: `0` (Default).

**3. Choose Operation**:
The Redis node supports various operations, such as:
-   `Set`: Store data.
-   `Get`: Retrieve data.
-   `Delete`: Remove data.
-   `Incr`/`Decr`: Increment/Decrement counters.

> [!IMPORTANT]
> n8n does **not** automatically use Redis for internal caching or session management. You must **actively add Redis nodes** to your workflows and design the logic to utilize caching.

**Example Scenario**:

To cache an API response:
1.  Use a Redis `Get` node to check if the cache exists.
2.  If missing, call the API and use a Redis `Set` node to store the result (with an expiration time).
3.  If present, use the cached data directly.

## Reverse Proxy Setup (Nginx Proxy Manager)

### Prerequisites

Before starting, ensure:

1.  ✅ Nginx Proxy Manager (NPM) is deployed.
2.  ✅ You own a domain name (e.g., `n8n.example.com`).
3.  ✅ A DNS 'A' record points to your server IP.

> [!INFO]
> If you haven't deployed NPM yet, refer to the [Nginx Proxy Manager Official Guide](https://nginxproxymanager.com/guide/) or related tutorials.

### Adjusting n8n Environment Variables

Stop the containers and edit `docker-compose.yml` to update the n8n environment variables:

```yaml
services:
  n8n:
    # ... other configs remain unchanged
    environment:
      - N8N_PORT=5678
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      # Added: Reverse Proxy Configuration
      - N8N_HOST=n8n.example.com          # Replace with your domain
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.example.com
    # ... other configs remain unchanged
```

#### Key Environment Variables

| Variable | Description | Example |
|---------|------|--------|
| `N8N_HOST` | Your n8n domain name | `n8n.example.com` |
| `N8N_PROTOCOL` | Access protocol | `https` |
| `WEBHOOK_URL` | URL for Webhooks (Must be set correctly) | `https://n8n.example.com` |

> [!WARNING]
> Incorrect `WEBHOOK_URL` settings will cause Webhook nodes in your workflows to fail. Ensure this matches your external access URL.

Restart the containers to apply changes:

```bash
# Restart containers
docker compose down && docker compose up -d
```

### NPM Configuration Steps

Log in to the Nginx Proxy Manager interface and add a Proxy Host:

#### 1. Details Tab

-   **Domain Names**: `n8n.example.com`
-   **Scheme**: `http`
-   **Forward Hostname / IP**:
    -   If NPM and n8n are on the same Docker network: Use the container name `n8n`.
    -   If on different networks: Use the server IP (e.g., `192.168.1.100`).
-   **Forward Port**: `5678`
-   **Cache Assets**: ✅ Enable (Optional).
-   **Block Common Exploits**: ✅ Enable (Recommended).
-   **Websockets Support**: ✅ **Must be enabled** (n8n relies on WebSockets).

> [!IMPORTANT]
> You MUST enable **Websockets Support**. Without it, real-time features like execution status updates will not function correctly.

#### 2. Custom Locations Tab

For a standard n8n setup, **no configuration is needed** here. Leave it blank.

#### 3. SSL Tab

-   **SSL Certificate**: Select "Request a new SSL Certificate".
-   **Force SSL**: ✅ Enable.
-   **HTTP/2 Support**: ✅ Enable.
-   **HSTS Enabled**: ✅ Enable.
-   **HSTS Subdomains**: ✅ Enable.

#### 4. Advanced Tab (Recommended)

To prevent long-running workflows from timing out, add the following Nginx configuration:

```nginx
proxy_buffering off;
proxy_read_timeout 3600s;
proxy_send_timeout 3600s;
proxy_connect_timeout 3600s;
```

**Explanation**:
-   `proxy_buffering off`: Disables buffering for real-time data transfer.
-   timeouts: Sets read/send/connect timeouts to 1 hour.

> [!TIP]
> If your workflows might run longer than 1 hour, adjust the timeout values (in seconds) accordingly.

### Verifying the Reverse Proxy

**1. Access n8n**:

Open `https://n8n.example.com` in your browser. You should see the login screen with a secure lock icon in the address bar.

**2. Test Webhooks** (Optional):

1.  Create a new workflow in n8n.
2.  Add a "Webhook" node.
3.  Configure the trigger.
4.  Copy the Webhook URL (should look like `https://n8n.example.com/webhook/...`).
5.  Test it using `curl` or Postman.

```bash
# Test webhook
curl -X POST https://n8n.example.com/webhook/your-webhook-path
```

Success indicates the reverse proxy is correctly forwarding requests.

> [!NOTE]
> If the webhook fails:
> 1. Check if **Websockets Support** is enabled in NPM.
> 2. Verify `WEBHOOK_URL` is set correctly.
> 3. Ensure the SSL certificate is valid.

## Complete Configuration Example

Here is the full `docker-compose.yml` consolidating all features:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    depends_on:
      - redis
    volumes:
      - /appdata/n8n/data:/home/node/.n8n
      - /appdata/n8n/files:/files
    environment:
      # Domain and protocol configuration
      - N8N_HOST=n8n.example.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.example.com

      # Environment settings
      - NODE_ENV=production
      - GENERIC_TIMEZONE=Asia/Taipei
      - TZ=Asia/Taipei

      # Security settings
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
    networks:
      - n8n-network

  redis:
    image: redis:alpine
    container_name: n8n-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - /appdata/n8n/redis/data:/data
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

networks:
  n8n-network:
    name: n8n-network
```

### Environment Variables Summary

| Category | Variable | Description | Requirement |
|------|---------|------|--------|
| **Domain** | `N8N_HOST` | n8n Domain | Required for Reverse Proxy |
| | `N8N_PROTOCOL` | Protocol (http/https) | Required for HTTPS |
| | `WEBHOOK_URL` | Webhook URL | Required for Webhooks |
| **Basic** | `N8N_PORT` | Web Interface Port | Optional (Default 5678) |
| | `NODE_ENV` | Node Environment | Recommended: production |
| | `GENERIC_TIMEZONE` | n8n Timezone | Recommended |
| | `TZ` | System Timezone | Recommended |
| **Security** | `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | Enforce Permission Checks | Recommended |

### Recommended Directory Structure

```
/appdata/n8n/
├── data/                    # Core data
├── files/                   # Workflow files
└── redis/
    └── data/                # Redis persistence data
```

## FAQ

### Q: Unable to access the interface after starting?

**Possible Causes & Solutions**:

1.  **Firewall Blocking**:
    ```bash
    # Check firewall rules (Ubuntu/Debian)
    sudo ufw allow 5678/tcp
    ```

2.  **Port Conflict**:
    ```bash
    # Check if port 5678 is in use
    sudo lsof -i :5678
    ```
    If occupied, map to a different port in `docker-compose.yml` (e.g., `"5679:5678"`).

3.  **Container Errors**:
    ```bash
    # Check container logs
    docker compose logs n8n
    ```

### Q: Webhooks are not working?

**Checklist**:

1.  ✅ Verify `WEBHOOK_URL` is correct:
    ```bash
    docker exec n8n env | grep WEBHOOK_URL
    ```
2.  ✅ Ensure NPM **Websockets Support** is enabled.
3.  ✅ Verify SSL validity.
4.  ✅ Ensure port 443 is open on your firewall.

### Q: Redis connection failed?

**Troubleshooting**:

1.  **Check Network**:
    ```bash
    docker network inspect n8n-network
    ```
    Ensure both `n8n` and `n8n-redis` are listed.

2.  **Check Health**:
    Ensure the Redis container status is `healthy`.

3.  **Ping Test**:
    ```bash
    docker exec n8n ping n8n-redis
    ```

### Q: How do I update n8n?

**Update Steps**:

1.  **Check current version**:
    ```bash
    docker exec n8n n8n --version
    ```

2.  **Backup Data**.

3.  **Pull & Restart**:
    ```bash
    docker compose pull n8n
    docker compose up -d
    ```

> [!WARNING]
> Always backup your data before updating. Some updates may include database migrations that are irreversible. Check the [n8n Release Notes](https://github.com/n8n-io/n8n/releases) for details.

## References

-   [n8n Documentation](https://docs.n8n.io/)
-   [n8n Docker Installation Guide](https://docs.n8n.io/hosting/installation/docker/)
-   [Docker Compose Documentation](https://docs.docker.com/compose/)
-   [Nginx Proxy Manager Guide](https://nginxproxymanager.com/guide/)

---

## Conclusion

You have successfully deployed a robust, secure n8n instance with Redis caching and HTTPS access. You can now start exploring n8n's powerful capabilities to automate your workflows efficiently.

If you encounter any issues, refer to the FAQ or seek help on the [n8n Community Forum](https://community.n8n.io/).

Happy Automating!
