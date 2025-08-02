#!/bin/bash

# Natura Real API Scraper
# Uses the official Natura Mexico API to get real products

API_URL="${API_URL:-http://192.168.1.210:8080}"
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
    # "cuidado-corporal"  # Body care
    # "proteccion-solar"  # Sun protection
)

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

# Function to upload image directly to Cloudinary from URL
upload_to_cloudinary() {
    local image_url="$1"
    local product_id_natura="$2"
    local product_id="$3"

    if [ -z "$image_url" ] || [ "$image_url" = "null" ]; then
        echo ""
        return 1
    fi

    # Extract original filename from URL for display
    local original_filename=$(basename "$image_url" | cut -d'?' -f1)

    echo "☁️  Uploading to Cloudinary: $original_filename" >&2
    echo "   📸 Source URL: $image_url" >&2

    # For unsigned uploads, we don't need timestamp or signature
    echo "   🔓 Using unsigned upload (simpler approach)" >&2

    # Upload to Cloudinary using upload preset (unsigned)
    local response=$(curl -s -X POST \
        "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
        -F "file=$image_url" \
        -F "upload_preset=ml-default" 2>/dev/null)

    # Parse response
    local secure_url=$(echo "$response" | jq -r '.secure_url // empty')
    local error_message=$(echo "$response" | jq -r '.error.message // empty')

    if [ -n "$error_message" ]; then
        echo "   ❌ Cloudinary upload failed: $error_message" >&2
        echo ""
        return 1
    fi

    if [ -z "$secure_url" ]; then
        echo "   ❌ No secure_url in Cloudinary response" >&2
        echo ""
        return 1
    fi

    echo "   ✅ Uploaded successfully" >&2
    echo "   🔗 URL: $secure_url" >&2
    echo "$secure_url"
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
    # local category=$(map_category "$natura_category")

    local category=$natura_category

    # Upload image to Cloudinary and get Cloudinary URL
    local image_url=$(upload_to_cloudinary "$original_image_url" "$product_id_natura" "$product_id")
    if [ -z "$image_url" ]; then
        echo "⚠️  No image uploaded for: $name" >&2
        image_url=""  # Will use placeholder or no image
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
            echo "☁️  Cloudinary Image: $image_url"
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

# Main scraping function
scrape_natura_api() {
    local success_count=0
    local error_count=0
    local product_id=1
    local max_products=200
    
    echo "🚀 Starting Natura API scraping..."
    echo "📊 Target: $max_products products from ${#categories[@]} categories"
    echo ""
    
    for category in "${categories[@]}"; do
        echo "📂 Processing category: $category"
        
        # Fetch products from this category
        local start=0
        local count=24  # Natura API typical page size
        local category_products=0
        local max_per_category=50
        
        while [ $category_products -lt $max_per_category ] && [ $product_id -le $max_products ]; do
            local response=$(fetch_natura_products "$category" "$start" "$count")
            
            if [ $? -ne 0 ] || [ -z "$response" ]; then
                echo "❌ Failed to fetch from category: $category" >&2
                break
            fi
            
            # Extract products array
            local products=$(echo "$response" | jq -r '.products[]?' 2>/dev/null)
            
            if [ -z "$products" ]; then
                echo "📄 No more products in category: $category" >&2
                break
            fi
            
            # Process each product
            echo "$response" | jq -c '.products[]?' 2>/dev/null | while read -r product; do
                if [ $product_id -gt $max_products ]; then
                    break
                fi
                
                echo "📦 Processing product $product_id: $(echo "$product" | jq -r '.name // "Unknown"')"
                
                if create_product "$product" "$product_id"; then
                    ((success_count++))
                else
                    ((error_count++))
                fi
                
                ((product_id++))
                ((category_products++))
                
                sleep 0.5  # Be respectful to APIs
            done
            
            ((start += count))
            sleep 1  # Delay between pages
        done
        
        echo "✅ Completed category: $category ($category_products products)"
        echo ""
    done
    
    echo "🎉 Natura API scraping completed!"
    echo "✅ Successfully created: $success_count products"
    echo "❌ Failed to create: $error_count products"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ($success_count + $error_count)" | bc -l 2>/dev/null || echo "N/A")%"
}

# Check dependencies
check_dependencies() {
    for cmd in curl jq bc openssl; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Missing dependency: $cmd"
            if [ "$cmd" = "openssl" ]; then
                echo "💡 OpenSSL should be pre-installed on macOS"
            else
                echo "💡 Install with: brew install $cmd"
            fi
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
        echo "📄 Response: $test_response"
        exit 1
    fi
    
    echo ""
    echo "🎯 This script will fetch REAL products from Natura's official API"
    echo "   • Authentic product names, prices, and descriptions"
    echo "   • Real product images uploaded directly to Cloudinary"
    echo "   • Official product ratings and details"
    echo "   • Multiple categories: hair care, perfumes, makeup, etc."
    echo "   • Images preserved with original filenames in Cloudinary"
    echo ""
    read -p "Continue with real Natura API scraping and Cloudinary upload? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    scrape_natura_api
}

main "$@"
