# HTTPS Setup for Jasper Table Service

This project has been configured to run with HTTPS support using Nginx as a reverse proxy.

## Setup Instructions

### 1. Generate SSL Certificates

For development and testing purposes, you can use the included dummy certificates:

```powershell
# Run the included PowerShell script to generate dummy certificates
.\generate-dummy-certs.ps1
```

For production, replace the dummy certificates with real ones:
- Place your SSL certificate in `nginx/ssl/dummy.crt`
- Place your SSL private key in `nginx/ssl/dummy.key`

Alternatively, you can modify the Nginx configuration to use your certificates with different names.

### 2. Run the Application with HTTPS

Start the application using Docker Compose:

```bash
docker-compose up -d
```

This will:
- Start the Jasper application on port 8080 (internal only)
- Start Nginx with:
  - HTTP on port 80 (redirects to HTTPS)
  - HTTPS on port 443

### 3. Access the Application

Once running, you can access the application at:
- `https://localhost/` or
- `https://your-domain.com/` (if configured)

## Configuration

- The Nginx configuration is located in `nginx/conf/app.conf`
- SSL certificates are stored in `nginx/ssl/`
- Docker Compose configuration is in `docker-compose.yaml`

## Notes

- For production use, ensure you replace the dummy SSL certificates with real ones
- Update the server_name in the Nginx configuration to match your actual domain
- Consider adjusting SSL parameters for security requirements 