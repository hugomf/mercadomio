#!/bin/bash

# Natura Real API Scraper
# Uses the official Natura Mexico API to get real products

API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_API_BASE="https://ncf-apigw.natura-mx-jcf-prd.naturacloud.com/bff-app-natura-mexico-v2"
BEARER_TOKEN="REDACTED"
TENANT_ID="mexico-natura-web"
API_KEY="REDACTED"

echo "🌿 Natura Real API Scraper with Local Image Download"
echo "📡 Backend API: $API_URL"
echo "🔗 Natura API: $NATURA_API_BASE"
echo ""

# Setup local image directory
IMAGES_DIR="./frontend/assets/images/products"
mkdir -p "$IMAGES_DIR"
echo "📁 Images will be saved to: $IMAGES_DIR"
echo ""

# Categories to scrape from Natura API
categories=(
    "cabello"           # Hair care
    "perfumeria"        # Perfumes
    "maquillaje"        # Makeup
    "cuidado-corporal"  # Body care
    "cuidado-facial"    # Facial care
    "proteccion-solar"  # Sun protection
    "hogar"            # Home
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

# Function to download image and return local URL
download_image() {
    local image_url="$1"
    local product_id_natura="$2"
    local product_id="$3"

    if [ -z "$image_url" ] || [ "$image_url" = "null" ]; then
        echo ""
        return 1
    fi

    # Generate filename from product ID and original extension
    local extension="${image_url##*.}"
    extension="${extension%%\?*}"  # Remove query parameters
    if [[ ! "$extension" =~ ^(jpg|jpeg|png|gif|webp)$ ]]; then
        extension="jpg"  # Default to jpg
    fi

    local filename="${product_id_natura}_${product_id}.${extension}"
    local local_path="$IMAGES_DIR/$filename"
    local local_url="/assets/images/products/$filename"

    echo "📥 Downloading image: $filename" >&2

    # Download with proper headers
    if curl -s -L --max-time 15 \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
        -H "Referer: https://www.natura.com.mx/" \
        -o "$local_path" \
        "$image_url" 2>/dev/null; then

        # Check if file was downloaded and has reasonable size
        if [ -f "$local_path" ] && [ -s "$local_path" ]; then
            local file_size=$(wc -c < "$local_path")
            if [ "$file_size" -gt 1000 ]; then  # At least 1KB
                echo "   ✅ Downloaded: $file_size bytes" >&2
                echo "$local_url"
                return 0
            else
                echo "   ❌ File too small: $file_size bytes" >&2
                rm -f "$local_path"
            fi
        else
            echo "   ❌ Download failed or empty file" >&2
        fi
    else
        echo "   ❌ Curl failed" >&2
    fi

    # Return empty string if download failed
    echo ""
    return 1
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

    # Download image locally and get local URL
    local image_url=$(download_image "$original_image_url" "$product_id_natura" "$product_id")
    if [ -z "$image_url" ]; then
        echo "⚠️  No image downloaded for: $name" >&2
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
        "sourceApi": "natura-mexico-api"
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
        echo "🖼️  Image: $image_url"
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
    for cmd in curl jq bc; do
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
    echo "   • Real product images from Natura's CDN"
    echo "   • Official product ratings and details"
    echo "   • Multiple categories: hair care, perfumes, makeup, etc."
    echo ""
    read -p "Continue with real Natura API scraping? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    scrape_natura_api
}

main "$@"
