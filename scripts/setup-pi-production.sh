#!/bin/bash

# Raspberry Pi Production Setup Script
# Sets up everything needed for production deployment

set -e

echo "🟣 Raspberry Pi Production Setup"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurable variables
DEPLOY_PATH="${DEPLOY_PATH:-/opt/mercadomio}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
CLOUDFLARE_TUNNEL_NAME="${CLOUDFLARE_TUNNEL_NAME:-mercadomio-tunnel}"
CLOUDFLARE_SUBDOMAIN="${CLOUDFLARE_SUBDOMAIN:-mercadomio-app}"

# Function to log with color
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if ! grep -q "Raspberry Pi\|raspberrypi" /proc/cpuinfo 2>/dev/null; then
        error "This script is designed for Raspberry Pi. Detected: $(uname -m)"
    fi
    log "✅ Running on Raspberry Pi"
}

# Install required packages
install_dependencies() {
    log "📦 Installing required packages..."

    # Update package list
    sudo apt update || error "Failed to update package list"

    # Install basic tools
    sudo apt install -y curl wget git htop vim || error "Failed to install basic tools"

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        log "🐳 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log "✅ Docker installed. You'll need to logout/login or run 'newgrp docker'"
    fi

    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "🐳 Installing Docker Compose..."
        sudo apt install -y docker-compose || error "Failed to install Docker Compose"
    fi

    log "✅ Dependencies installed"
}

# Create deployment user
setup_deploy_user() {
    if id "deploy" &>/dev/null; then
        log "✅ Deploy user already exists"
        return
    fi

    log "👤 Creating deployment user..."
    sudo useradd -m -s /bin/bash deploy || error "Failed to create deploy user"
    sudo usermod -aG docker deploy || warning "Failed to add deploy user to docker group"

    # Set up SSH key for GitHub Actions
    sudo mkdir -p /home/deploy/.ssh
    sudo touch /home/deploy/.ssh/authorized_keys
    sudo chown -R deploy:deploy /home/deploy/.ssh
    sudo chmod 700 /home/deploy/.ssh
    sudo chmod 600 /home/deploy/.ssh/authorized_keys

    log "✅ Deploy user created. Add GitHub Actions SSH public key to /home/deploy/.ssh/authorized_keys"
}

# Set up deployment directory
setup_deployment_directory() {
    log "📁 Setting up deployment directory: $DEPLOY_PATH"

    sudo mkdir -p "$DEPLOY_PATH"
    sudo chown deploy:deploy "$DEPLOY_PATH"

    # Create subdirectories for persistence
    sudo mkdir -p "$DEPLOY_PATH/data/mongo"
    sudo mkdir -p "$DEPLOY_PATH/data/postgres"
    sudo mkdir -p "$DEPLOY_PATH/ssl"
    sudo mkdir -p "$DEPLOY_PATH/backup"

    sudo chown -R deploy:deploy "$DEPLOY_PATH"

    log "✅ Deployment directory ready"
}

# Set up necessary environment files
setup_environment_files() {
    log "🔐 Setting up production environment files..."

    # Production environment file
    sudo -u deploy bash -c "cat > $DEPLOY_PATH/.env.production << EOF
# Database connections
MONGO_URI=mongodb://mongo:27017/mercadomio
REDIS_ADDR=redis:6379

# Application settings
NODE_ENV=production
API_URL=https://$CLOUDFLARE_SUBDOMAIN.trycloudflare.com

# Cloudinary (if using)
CLOUDINARY_CLOUD_NAME=\${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_API_KEY=\${CLOUDINARY_API_KEY}
CLOUDINARY_API_SECRET=\${CLOUDINARY_API_SECRET}

# Directus database
POSTGRES_DB=directus
POSTGRES_USER=admin
POSTGRES_PASSWORD=\${POSTGRES_PASSWORD:-changeme123}
DIRECTUS_KEY=pi4-directus-\$(date +%s)
DIRECTUS_SECRET=super-secret-\$(openssl rand -hex 32)
DIRECTUS_ADMIN_EMAIL=admin@\${DOMAIN:-localhost}
DIRECTUS_ADMIN_PASSWORD=\${DIRECTUS_ADMIN_PASSWORD:-admin123}
EOF"

    # SSH key instructions
    cat > "$DEPLOY_PATH/SSH_SETUP_README.md" << 'EOF'
# SSH Key Setup for GitHub Actions

## Generate SSH Key Pair (on your development machine):

```bash
ssh-keygen -t ed25519 -C "deploy@raspberry-pi" -f ~/.ssh/deploy_pi_key
```

## Add Public Key to Raspberry Pi:

```bash
# Copy the PUBLIC key (contains .pub extension) content to:
sudo nano /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

## Add Private Key to GitHub Secrets:

1. Copy the PRIVATE key content (the file without .pub extension)
2. Go to GitHub Repository → Settings → Secrets and variables → Actions
3. Add new secret: PI_SSH_PRIVATE_KEY
4. Paste the entire private key content

## Test SSH Connection:

```bash
ssh -i ~/.ssh/deploy_pi_key deploy@YOUR_PI_IP "docker --version"
```
EOF

    log "✅ Environment files created. See $DEPLOY_PATH/SSH_SETUP_README.md for SSH setup"
}

# Optimize Raspberry Pi for production
optimize_raspberry_pi() {
    log "🚀 Optimizing Raspberry Pi for production..."

    # Disable swap (can cause database corruption)
    sudo systemctl disable dphys-swapfile || warning "Swap already disabled"

    # Configure memory limits for services
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "log-level": "error",
    "storage-driver": "overlay2",
    "metrics-addr": "0.0.0.0:9323",
    "experimental": true,
    "default-ulimits": {
        "nofile": {
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF

    # Configure sysctl for better performance
    sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# Performance optimizations for database servers
vm.swappiness=1
vm.dirty_background_ratio=5
vm.dirty_ratio=10
fs.file-max=100000
net.core.somaxconn=65535
EOF

    # Apply sysctl changes
    sudo sysctl -p || warning "Some sysctl settings failed"

    # Configure systemd for better Docker performance
    sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
EOF

    log "✅ Raspberry Pi optimized for production"
}

# Provide Cloudflare Tunnel setup instructions
setup_cloudflare_instructions() {
    log "🌐 Creating Cloudflare Tunnel setup guide..."

    cat > "$DEPLOY_PATH/CLOUDFLARE_SETUP.md" << EOF
# Cloudflare Tunnel Setup

## Step 1: Install cloudflared
\`\`\`bash
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb
cloudflared version
\`\`\`

## Step 2: Login to Cloudflare (on Raspberry Pi)
\`\`\`bash
cloudflared tunnel login
# Follow the URL to complete authentication
\`\`\`

## Step 3: Create Tunnel
\`\`\`bash
cloudflared tunnel create $CLOUDFLARE_TUNNEL_NAME
\`\`\`

## Step 4: Set up DNS Route
\`\`\`bash
cloudflared tunnel route dns $CLOUDFLARE_TUNNEL_NAME $CLOUDFLARE_SUBDOMAIN
# This creates: https://$CLOUDFLARE_SUBDOMAIN.trycloudflare.com
\`\`\`

## Step 5: Install as Service
\`\`\`bash
sudo cloudflared service install $CLOUDFLARE_TUNNEL_NAME
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
\`\`\`

## Step 6: Test
\`\`\`bash
curl https://$CLOUDFLARE_SUBDOMAIN.trycloudflare.com
sudo systemctl status cloudflared
\`\`\`

## Troubleshooting:
- If tunnel fails: \`sudo journalctl -u cloudflared -f\`
- If DNS fails: Choose a different subdomain name
- No port forwarding needed - Cloudflare connects outbound from your Pi
EOF

    log "✅ Cloudflare setup guide created at $DEPLOY_PATH/CLOUDFLARE_SETUP.md"
}

# Create production docker-compose file
create_production_compose() {
    log "🐳 Creating production Docker Compose configuration..."

    sudo -u deploy bash -c "cat > $DEPLOY_PATH/docker-compose.prod.yml << EOF
version: '3.8'

services:
  # Load balancer and SSL termination
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - \"80:80\"
      - \"443:443\"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - app_network
    depends_on:
      - backend
      - frontend

  # Go backend API
  backend:
    image: ghcr.io/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/mercadomio/backend:latest
    restart: unless-stopped
    environment:
      - MONGO_URI=mongodb://mongo:27017/mercadomio
      - REDIS_ADDR=redis:6379
      - NODE_ENV=production
    env_file: .env.production
    networks:
      - app_network
      - db_network
    depends_on:
      - mongo
      - redis
      - postgres
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8080/api/health\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Flutter web frontend
  frontend:
    image: ghcr.io/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/mercadomio/frontend:latest
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      backend:
        condition: service_healthy

  # MongoDB database
  mongo:
    image: mongo:7-jammy
    restart: unless-stopped
    volumes:
      - ./data/mongo:/data/db:rw
    environment:
      MONGO_INITDB_DATABASE: mercadomio
    command: --storageEngine wiredTiger --smallfiles
    networks:
      - db_network
    deploy:
      resources:
        limits:
          memory: 256M

  # Redis cache
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - db_network
    deploy:
      resources:
        limits:
          memory: 64M

  # PostgreSQL for Directus
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: directus
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: \"\\\${POSTGRES_PASSWORD:-changeme123}\"
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - db_network
    deploy:
      resources:
        limits:
          memory: 128M

  # Directus CMS (optional)
  directus:
    image: directus/directus:latest
    restart: unless-stopped
    environment:
      KEY: \"\\\${DIRECTUS_KEY}\"
      SECRET: \"\\\${DIRECTUS_SECRET}\"
      DB_CLIENT: pg
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: directus
      DB_USER: admin
      DB_PASSWORD: \"\\\${POSTGRES_PASSWORD:-changeme123}\"
      ADMIN_EMAIL: \"\\\${DIRECTUS_ADMIN_EMAIL:-admin@localhost}\"
      ADMIN_PASSWORD: \"\\\${DIRECTUS_ADMIN_PASSWORD:-admin123}\"
      PUBLIC_URL: \"https://$CLOUDFLARE_SUBDOMAIN.trycloudflare.com/cms\"
    networks:
      - db_network
    depends_on:
      - postgres

networks:
  app_network:
    driver: bridge
  db_network:
    driver: bridge

volumes:
  mongo_data:
  postgres_data:
EOF"

    # Create nginx configuration
    sudo -u deploy bash -c "cat > $DEPLOY_PATH/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    # Performance
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 2048;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    upstream backend_app {
        server backend:8080;
    }

    upstream frontend_app {
        server frontend:80;
    }

    server {
        listen 80 default_server;
        server_name _;

        # API routes
        location /api/ {
            proxy_pass http://backend_app/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # CORS for API
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        }

        # Frontend routes
        location / {
            proxy_pass http://frontend_app/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # Try files for SPA
            try_files \$uri \$uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://frontend_app/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF"

    log "✅ Production Docker Compose and Nginx configurations created"
}

# Create monitoring scripts
setup_monitoring() {
    log "📊 Setting up monitoring scripts..."

    # Health check script
    sudo -u deploy bash -c "cat > $DEPLOY_PATH/health-check.sh << 'EOF'
#!/bin/bash
echo "🏥 Production Health Check - $(date)"

# Check service status
echo "🐳 Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n🌐 Application Endpoints:"
echo "Frontend: http://localhost"
echo "API: http://localhost/api/health"
echo "Directus: http://localhost:8055 (if enabled)"

# API health check
if curl -s --max-time 10 http://localhost/api/health > /dev/null; then
    echo "✅ API Health: OK"
else
    echo "❌ API Health: FAILED"
fi

# Database connections
if docker exec \$(docker ps -q -f name=mongo) mongo --eval "db.stats()" > /dev/null 2>&1; then
    echo "✅ MongoDB: OK"
else
    echo "❌ MongoDB: FAILED"
fi

if docker exec \$(docker ps -q -f name=redis) redis-cli ping | grep -q PONG; then
    echo "✅ Redis: OK"
else
    echo "❌ Redis: FAILED"
fi

# System resources
echo -e "\n💻 System Resources:"
echo "Memory: $(free -h | awk 'NR==2{printf "%.2f%% used", $3*100/$2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $5}') used"
echo "Load: $(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)"

echo -e "\n✨ Health check completed"
EOF"

    # Backup script
    sudo -u deploy bash -c "cat > $DEPLOY_PATH/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=\"./backup\"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

mkdir -p \"\$BACKUP_DIR\"

echo \"💾 Creating production backup...\"

# Database backup
docker exec \$(docker ps -q -f name=mongo) mongodump --db mercadomio --out /tmp/backup
docker cp \$(docker ps -q -f name=mongo):/tmp/backup ./backup/mongo_backup_\$TIMESTAMP
docker exec \$(docker ps -q -f name=mongo) rm -rf /tmp/backup

# Compress
cd \"\$BACKUP_DIR\" && tar -czf mongo_backup_\$TIMESTAMP.tar.gz mongo_backup_\$TIMESTAMP
rm -rf mongo_backup_\$TIMESTAMP

echo \"✅ Backup completed: \$BACKUP_DIR/mongo_backup_\$TIMESTAMP.tar.gz\"
EOF"

    # Update scripts
    sudo -u deploy bash -c "cat > $DEPLOY_PATH/update.sh << 'EOF'
#!/bin/bash
echo \"🔄 Updating production deployment...\"

# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Restart services
docker-compose -f docker-compose.prod.yml up -d

# Health check
sleep 30
if curl -s --max-time 15 http://localhost/api/health > /dev/null; then
    echo \"✅ Update successful\"
    # Cleanup old images
    docker image prune -f > /dev/null
else
    echo \"❌ Update failed - check logs\"
    exit 1
fi
EOF"

    # Make scripts executable
    sudo chmod +x "$DEPLOY_PATH/health-check.sh"
    sudo chmod +x "$DEPLOY_PATH/backup.sh"
    sudo chmod +x "$DEPLOY_PATH/update.sh"

    log "✅ Monitoring and maintenance scripts created"
}

# Final setup instructions
final_instructions() {
    # Get GitHub repository info for later
    GITHUB_REPO=""
    if git remote get-url origin >/dev/null 2>&1; then
        GITHUB_REPO=$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')
    fi

    log "🎉 Raspberry Pi production setup completed!"
    log ""
    info "Next steps:"
    echo "  1. 🔑 Set up SSH keys (see $DEPLOY_PATH/SSH_SETUP_README.md)"
    echo "  2. 🌐 Configure Cloudflare Tunnel (see $DEPLOY_PATH/CLOUDFLARE_SETUP.md)"
    echo "  3. 🚀 Deploy your application (see GitHub Actions workflow)"
    echo "  4. 📊 Monitor health: $DEPLOY_PATH/health-check.sh"
    echo ""
    info "Important reminders:"
    echo "  • Change all default passwords in .env.production"
    echo "  • Configure your GitHub repository secrets for CI/CD"
    echo "  • Set up regular backups: $DEPLOY_PATH/backup.sh"
    echo "  • Monitor logs: docker-compose logs -f"
    echo ""
    warning "Security checklist:"
    echo "  • Update Raspberry Pi OS: sudo apt update && sudo apt upgrade"
    echo "  • Enable firewall: sudo ufw enable"
    echo "  • Disable SSH password auth: /etc/ssh/sshd_config"
    echo "  • Set up automatic security updates"
}

# Main setup function
main() {
    log "🚀 Starting Raspberry Pi production setup..."

    check_raspberry_pi
    install_dependencies
    setup_deploy_user
    setup_deployment_directory
    setup_environment_files
    optimize_raspberry_pi
    setup_cloudflare_instructions
    create_production_compose
    setup_monitoring

    final_instructions

    echo -e "\n${GREEN}🎊 Setup complete! Your Raspberry Pi is ready for production.${NC}"
    echo -e "${BLUE}📖 Review the generated documentation files for next steps.${NC}"
}

# Allow script to be sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
