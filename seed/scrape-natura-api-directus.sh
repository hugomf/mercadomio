#!/bin/bash

# Natura Real API Scraper with Directus File Upload
# Uses the official Natura Mexico API to get real products and uploads images to Directus

API_URL="${API_URL:-http://192.168.1.216:8080}"
NATURA_API_BASE="https://ncf-apigw.natura-mx-jcf-prd.naturacloud.com/bff-app-natura-mexico-v2"
BEARER_TOKEN="REDACTED"
TENANT_ID="mexico-natura-web"
API_KEY="REDACTED"

# Directus Configuration
DIRECTUS_URL="${DIRECTUS_URL:-http://192.168.1.216:8055}"
DIRECTUS_EMAIL="${DIRECTUS_EMAIL:-admin@mercadomio.mx}"
DIRECTUS_PASSWORD="${DIRECTUS_PASSWORD:-admin123}"
DIRECTUS_TOKEN=""

echo "🌿 Natura Real API Scraper with Directus Upload"
echo "📡 Backend API: $API_URL"
echo "🔗 Natura API: $NATURA_API_BASE"
echo "📁 Directus CMS: $DIRECTUS_URL"
echo ""

# Categories to scrape from Natura API
categories=(
    "promociones"
    "perfumeria"        # Perfumes
    "cuidados-diarios"
    "cabello"           # Hair care
    "rostro"            # Rostro    
    "maquillaje"        # Makeup
    "hombre"
    "infantil"
    "regalos"
    "repuestos"
    "marcas"
)

# Function to authenticate with Directus and get access token
authenticate_directus() {
    echo "🔐 Authenticating with Directus..."
    
    local auth_response=$(curl -s -X POST \
        "$DIRECTUS_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$DIRECTUS_EMAIL\",
            \"password\": \"$DIRECTUS_PASSWORD\"
        }" 2>/dev/null)
    
    DIRECTUS_TOKEN=$(echo "$auth_response" | jq -r '.data.access_token // empty')
    
    if [ -z "$DIRECTUS_TOKEN" ]; then
        echo "❌ Failed to authenticate with Directus"
        echo "📄 Response: $auth_response"
        return 1
    fi
    
    echo "✅ Directus authentication successful"
    return 0
}

# Function to fetch products from Natura API
fetch_natura_products() {
    local category="$1"
    local start="$2"
    local count="$3"
    
    local url="${NATURA_API_BASE}/search?count=${count}&q=&expand=prices%2Cavailability%2Cimages%2Cvariations&sort=top-sellers&start=${start}&refine_1=cgid%3D${category}"
    
    echo "🔍 Fetching from: $category (start: $start, count: $count)" >&2
    
    curl -s -X GET \
        -H "Authorization: $BEARER_TOKEN" \
        -H "tenant_id: $TENANT_ID" \
        -H "X-Api-Key: $API_KEY" \
        -H "Accept: application/json" \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$url" 2>/dev/null
}

# Function to upload image to Directus from URL
upload_to_directus() {
    local image_url="$1"
    local original_filename="$2"
    local folder_id="980cc6e4-9cee-4365-9848-f8bebdaee575"

    if [ -z "$image_url" ] || [ "$image_url" = "null" ]; then
        echo ""
        return 1
    fi

    echo "📁 Uploading to Directus: $original_filename" >&2
    echo "   📸 Source URL: $image_url" >&2

    # Download image to temporary file first (Directus requires file upload)
    local temp_file="/tmp/natura_image_$(date +%s)_$(basename "$original_filename")"
    
    if ! curl -s -L --max-time 15 \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
        -H "Referer: https://www.natura.com.mx/" \
        -o "$temp_file" \
        "$image_url" 2>/dev/null; then
        echo "   ❌ Failed to download image" >&2
        return 1
    fi

    # Check if file was downloaded and has reasonable size
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        echo "   ❌ Download failed or empty file" >&2
        rm -f "$temp_file"
        return 1
    fi

    local file_size=$(wc -c < "$temp_file")
    if [ "$file_size" -lt 1000 ]; then
        echo "   ❌ File too small: $file_size bytes" >&2
        rm -f "$temp_file"
        return 1
    fi

    # Upload to Directus
    echo "   📤 Uploading to Directus..." >&2
    local response=$(curl -s -X POST \
        "$DIRECTUS_URL/files" \
        -H "Authorization: Bearer $DIRECTUS_TOKEN" \
        -F "folder=980cc6e4-9cee-4365-9848-f8bebdaee575" \
        -F "file=@$temp_file" \
        -F "title=$original_filename" \
        -F "filename_download=$original_filename" \
        -F "storage=local" \
        -F "type=image/jpeg" 2>/dev/null)

    
    # Print the full response for debugging
    echo "📄 Directus response: $response" >&2
    
    # Check if response is valid JSON
    if ! echo "$response" | jq -e . > /dev/null 2>&1; then
        echo "   ❌ Invalid JSON response from Directus" >&2
        return 1
    fi

    # Clean up temp file
    rm -f "$temp_file"

    # Parse response
    local file_id=$(echo "$response" | jq -r '.data.id // empty')
    local error_message=$(echo "$response" | jq -r '.errors[0].message // empty')

    if [ -n "$error_message" ]; then
        echo "   ❌ Directus upload failed: $error_message" >&2
        return 1
    fi

    if [ -z "$file_id" ]; then
        echo "   ❌ No file ID in Directus response" >&2
        echo "   📄 Response: $response" >&2
        return 1
    fi

    # Construct URL through backend proxy to avoid CORS/auth issues
    # local directus_url="$API_URL/api/directus/assets/$file_id/$original_filename"
    local directus_url="$DIRECTUS_URL/assets/$file_id/$original_filename"


    echo "   ✅ Upload successful" >&2
    echo "   🔗 Directus URL: $directus_url" >&2
    echo "$directus_url"
    return 0
}

# Function to map Natura category to our category
map_category() {
    local natura_category="$1"
    
    case "$natura_category" in
        "cabello"|"shampoo"|"cabello-shampoo"|"mascarilla-tratamiento"|"finalizado")
            echo "Cuidado del Cabello"
            ;;
        "perfumeria"|"fragancias")
            echo "Perfumería"
            ;;
        "maquillaje"|"rostro"|"labios"|"ojos")
            echo "Maquillaje"
            ;;
        "cuidado-corporal"|"corporal")
            echo "Cuidado Personal"
            ;;
        "cuidado-facial"|"facial")
            echo "Cuidado Facial"
            ;;
        "proteccion-solar"|"solar")
            echo "Protección Solar"
            ;;
        "hogar"|"casa")
            echo "Hogar"
            ;;
        *)
            echo "Cuidado Personal"
            ;;
    esac
}

# Function to create product in our API
create_product() {
    local natura_product="$1"
    local product_id="$2"
    
    # Extract data from Natura product JSON
    local product_id_natura=$(echo "$natura_product" | jq -r '.productId // ""')
    local name=$(echo "$natura_product" | jq -r '.friendlyName // .name // ""')
    local price=$(echo "$natura_product" | jq -r '.price.sales.value // 0')
    local description=$(echo "$natura_product" | jq -r '.shortDescription // ""' | sed 's/<[^>]*>//g')
    local brand=$(echo "$natura_product" | jq -r '.brand // "Natura"')
    local rating=$(echo "$natura_product" | jq -r '.rating // 0')
    local line=$(echo "$natura_product" | jq -r '.line // ""')
    local natura_category=$(echo "$natura_product" | jq -r '.categoryId // ""')
    local original_image_url=$(echo "$natura_product" | jq -r '.images.medium[0].absURL // ""')

    # Map to our category system
    local category=$(map_category "$natura_category")

    # Upload image to Directus and get Directus URL
    local image_url=""
    if [ -n "$original_image_url" ] && [ "$original_image_url" != "null" ]; then
        local original_filename=$(basename "$original_image_url" | cut -d'?' -f1)
        image_url=$(upload_to_directus "$original_image_url" "$original_filename")
        if [ -z "$image_url" ]; then
            echo "⚠️  No image uploaded for: $name" >&2
            image_url=""  # Will use placeholder or no image
        else
            echo "✅ Image uploaded successfully: $image_url" >&2
        fi
    else
        echo "⚠️  No image URL found for: $name" >&2
    fi
    
    # Clean and validate data
    name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/"/\\"/g')
    description=$(echo "$description" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/"/\\"/g')
    
    # Use default description if empty
    if [ -z "$description" ] || [ "$description" = "null" ]; then
        description="Producto Natura de alta calidad con ingredientes naturales."
    fi
    
    # Validate required fields
    if [ -z "$name" ] || [ "$name" = "null" ] || [ -z "$price" ] || [ "$price" = "0" ] || [ "$price" = "null" ]; then
        echo "❌ Invalid product data: $product_id_natura" >&2
        return 1
    fi
    
    # Generate our SKU and barcode
    local sku="NAT-API-$(printf "%04d" "$product_id")"
    local barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
    
    # Create JSON payload
    local json_payload=$(cat <<EOF
{
    "name": "$name",
    "description": "$description",
    "type": "physical",
    "category": "$category",
    "basePrice": $price,
    "sku": "$sku",
    "barcode": "$barcode",
    "imageUrl": "$image_url",
    "variants": [],
    "customAttributes": {
        "brand": "$brand",
        "origin": "Brasil",
        "vegan": true,
        "crueltyFree": true,
        "sustainable": true,
        "naturaProductId": "$product_id_natura",
        "naturaLine": "$line",
        "rating": $rating,
        "realNaturaProduct": true,
        "sourceApi": "natura-mexico-api",
        "naturaImageUrl": "$original_image_url"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-API-$(printf "%06d" $product_id)",
        "naturaId": "$product_id_natura"
    }
}
EOF
)

    # Send to our API
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ Created: $name (\$${price} MXN)"
        if [ -n "$image_url" ]; then
            echo "📁 Directus Image: $image_url"
        else
            echo "🖼️  No image uploaded"
        fi
        echo "🏷️  Category: $category | Brand: $brand"
        return 0
    else
        echo "❌ API Error (HTTP $http_code): $name"
        echo "📄 Error: $response_body" >&2
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Missing dependency: $cmd"
            echo "💡 Install with: brew install $cmd"
            return 1
        fi
    done
    return 0
}

# Main function
main() {
    if ! check_dependencies; then
        exit 1
    fi
    
    # Authenticate with Directus
    if ! authenticate_directus; then
        exit 1
    fi
    
    # Check our API connection
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to backend API at $API_URL"
        echo "💡 Make sure your backend is running"
        exit 1
    fi
    echo "✅ Backend API connection successful"
    
    # Test Natura API connection
    echo "🧪 Testing Natura API connection..."
    local test_response=$(fetch_natura_products "cabello" 0 1)
    if [ $? -eq 0 ] && echo "$test_response" | jq -e '.products[0]' > /dev/null 2>&1; then
        echo "✅ Natura API connection successful"
    else
        echo "❌ Cannot connect to Natura API"
        echo "💡 The token might have expired or API might be down"
        exit 1
    fi
    
    echo ""
    echo "🎯 This script will fetch REAL products from Natura's official API"
    echo "   • Authentic product names, prices, and descriptions"
    echo "   • Real product images uploaded to Directus CMS"
    echo "   • Official product ratings and details"
    echo "   • Multiple categories: hair care, perfumes, makeup, etc."
    echo "   • Images stored in Directus with original filenames"
    echo ""
    read -p "Continue with real Natura API scraping and Directus upload? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Start scraping (simplified for demo - just one category)
    echo "🚀 Starting scraping with Directus upload..."
    local response=$(fetch_natura_products "cabello" 0 5)
    echo "$response" | jq -c '.products[]?' 2>/dev/null | head -3 | while read -r product; do
        local product_id=$((RANDOM % 1000))
        echo "📦 Processing product: $(echo "$product" | jq -r '.name // "Unknown"')"
        create_product "$product" "$product_id"
        echo ""
        sleep 1
    done
    
    echo "🎉 Demo completed! Check your Directus CMS for uploaded images."
}

main "$@"
