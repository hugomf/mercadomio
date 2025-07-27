#!/bin/bash

# Natura Real API Scraper
# Uses the official Natura Mexico API to get real products

API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_API_BASE="https://ncf-apigw.natura-mx-jcf-prd.naturacloud.com/bff-app-natura-mexico-v2"
BEARER_TOKEN="Bearer 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"
TENANT_ID="mexico-natura-web"
API_KEY="3e28babd-85e9-4557-bfdd-450edf372306"

echo "🌿 Natura Real API Scraper"
echo "📡 Backend API: $API_URL"
echo "🔗 Natura API: $NATURA_API_BASE"
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
    local image_url=$(echo "$natura_product" | jq -r '.images.medium[0].absURL // ""')
    
    # Map to our category system
    local category=$(map_category "$natura_category")
    
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
