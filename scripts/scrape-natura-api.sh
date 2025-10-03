#!/bin/bash

# Natura Real API Scraper
# Uses the official Natura Mexico API to get real products

API_URL="${API_URL:-http://localhost:8080}"
NATURA_API_BASE="https://ncf-apigw.natura-mx-jcf-prd.naturacloud.com/bff-app-natura-mexico-v2"
BEARER_TOKEN="REDACTED"
TENANT_ID="mexico-natura-web"
API_KEY="REDACTED"

echo "🌿 Natura Real API Scraper with Cloudinary Upload"
echo "📡 Backend API: $API_URL"
echo "🔗 Natura API: $NATURA_API_BASE"
echo ""

# Load Cloudinary configuration
CLOUDINARY_CONFIG_FILE="${CLOUDINARY_CONFIG_FILE:-../backend/.env}"
if [ ! -f "$CLOUDINARY_CONFIG_FILE" ]; then
    echo "❌ .env file not found at $CLOUDINARY_CONFIG_FILE"
    echo "💡 Create backend/.env with Cloudinary configuration"
    exit 1
fi

# Source the .env file
set -a
source "$CLOUDINARY_CONFIG_FILE"
set +a

if [ -z "${CLOUDINARY_CLOUD_NAME:-}" ] || [ -z "${CLOUDINARY_API_KEY:-}" ] || [ -z "${CLOUDINARY_API_SECRET:-}" ]; then
    echo "❌ Missing Cloudinary configuration in $CLOUDINARY_CONFIG_FILE"
    echo "💡 Required: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET"
    exit 1
fi

echo "☁️  Cloudinary Cloud: $CLOUDINARY_CLOUD_NAME"
echo ""
