#!/bin/bash

# Natura Real API Scraper
# Uses the official Natura Mexico API to get real products

API_URL="${API_URL:-http://localhost:8080}"
NATURA_API_BASE="https://ncf-apigw.natura-mx-jcf-prd.naturacloud.com/bff-app-natura-mexico-v2"
BEARER_TOKEN="Bearer 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"
TENANT_ID="mexico-natura-web"
API_KEY="3e28babd-85e9-4557-bfdd-450edf372306"

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

# Parse command line arguments for category search
SEARCH_CATEGORY=""
if [ $# -gt 0 ]; then
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "🌿 Natura Real API Scraper with Category Search"
        echo ""
        echo "Usage:"
        echo "  $0                      # Scrape all categories"
        echo "  $0 \"Category Name\"     # Search and scrape specific category"
        echo "  $0 \"Perfumería\"        # Example: match local categories like 'Perfumería'"
        echo "  $0 \"cuidados-diarios\"  # Example: match Natura API categories"
        echo ""
        echo "Category Search Process:"
        echo "  1. Queries /api/categories/search?name=<name>"
        echo "  2. If found, converts to Natura API format"
        echo "  3. Scrapes products from that specific category"
        echo ""
        echo "Examples:"
        echo "  $0 \"Perfumería\"           # Find 'Perfumería' in our DB, convert to Natura format"
        echo "  $0 \"cuidados-diarios\"     # Use Natura category slug directly"
        echo "  $0 \"Cabello\"              # Try to find hair care products"
        exit 0
    fi
    SEARCH_CATEGORY="$1"
fi

# Function to search for category by name in our API
search_category_by_name() {
    local search_term="$1"
    echo "🔍 Searching for category: '$search_term'" >&2

    # First try to search using our categories search API
    local search_response=$(curl -s -w "%{http_code}" \
        "$API_URL/api/categories/search?name=$search_term" 2>/dev/null)

    local search_http_code="${search_response: -3}"
    local search_body="${search_response%???}"

    echo "🔍 Search API response: HTTP $search_http_code" >&2

    if [[ "$search_http_code" =~ ^2[0-9][0-9]$ ]]; then
        # Category found! Extract name to get Natura-compatible slug
        local found_name=$(echo "$search_body" | jq -r '.name // empty' 2>/dev/null)
        if [ -n "$found_name" ] && [ "$found_name" != "null" ] && [ "$found_name" != "empty" ]; then
            echo "🎯 Found category: '$found_name'" >&2
        fi
    fi

    # If exact match failed, try partial/fuzzy search
    echo "🔄 No exact match found, trying fuzzy search..." >&2
    local fuzzy_response=$(curl -s "$API_URL/api/categories" 2>/dev/null)

    if [ -n "$fuzzy_response" ] && [ "$fuzzy_response" != "null" ]; then
        # Look for category containing search term
        local matches=$(echo "$fuzzy_response" | jq -r ".[] | select(.name | test(\"(?i)$search_term\")) | .name" 2>/dev/null | head -3)

        if [ -n "$matches" ]; then
            local first_match=$(echo "$matches" | head -1)
            echo "🎯 Fuzzy match found: '$first_match'" >&2

            # Convert fuzzy match to Natura API format
            case "$first_match" in
                *"Perfumería"*|*perfume*)
                    echo "perfumeria"
                    ;;
                *"Cabello"*|*hair*)
                    echo "cabello"
                    ;;
                *"Maquillaje"*|*makeup*)
                    echo "maquillaje"
                    ;;
                *"Rostro"*|*facial*)
                    echo "rostro"
                    ;;
                *"Cuidado"*|*body*)
                    echo "cuidados-diarios"
                    ;;
                *)
                    echo "cuidados-diarios" # fallback
                    ;;
            esac
            return 0
        fi
    fi

    # Last resort: try the search term as a Natura API slug directly
    echo "🔄 Using search term as Natura API slug directly: '$search_term'" >&2
    echo "$search_term"
    return 0
}

# Categories to scrape from Natura API
if [ -z "$SEARCH_CATEGORY" ]; then
    # Default: scrape all categories if no search specified
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
    echo "🎯 Scanning all categories"
else
    # Single category mode - search by name
    echo "🎯 Searching for category: $SEARCH_CATEGORY"

    # Search for the category and get Natura-compatible slug
    matching_category=$(search_category_by_name "$SEARCH_CATEGORY")

    if [ -n "$matching_category" ] && [ "$matching_category" != "null" ]; then
        categories=("$matching_category")
        echo "✅ Using Natura category: $matching_category"
    else
        echo "❌ Could not find suitable category for: $SEARCH_CATEGORY"
        echo "💡 Try: \"Perfumería\", \"Cabello\", \"Maquillaje\", \"Rostro\", or \"Cuidado Personal\""
        echo "💡 Or use Natura API slugs directly: \"perfumeria\", \"cabello\", \"maquillaje\", etc."
        exit 1
    fi
fi

# Global variable to track processed categories (prevents duplicate API checks)
processed_categories_list=""

# Function to check if category is already processed
category_processed() {
    local category="$1"
    [[ "$processed_categories_list" =~ (^| )"$category"( |$) ]]
}

# Function to mark category as processed
mark_category_processed() {
    local category="$1"
    if ! category_processed "$category"; then
        processed_categories_list="${processed_categories_list:+$processed_categories_list }$category"
    fi
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

    # Use Natura category directly (no mapping)
    local category=$natura_category

    # Ensure category exists immediately when first encountered
    if [ -n "$category" ] && ! category_processed "$category"; then
        echo "🏷️  Processing category: $category" >&2
        if ensure_category_exists "$category"; then
            mark_category_processed "$category"
            echo "🏷️  Category ready: $category" >&2
        else
            echo "⚠️  Failed to create category: $category (continuing with product..." >&2
        fi
    fi

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

# Function to ensure category exists in our database by searching existing categories
ensure_category_exists() {
    local category_slug="$1"

    echo "🔍 Checking category: $category_slug" >&2

    # First test if categories endpoint is working
    local test_response=$(curl -s -w "%{http_code}" "$API_URL/api/categories" 2>/dev/null)
    local test_http_code="${test_response: -3}"
    local test_body="${test_response%???}"

    echo "📡 Categories API test - HTTP $test_http_code" >&2
    if [[ ! "$test_http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "❌ Categories API not responding properly: $test_body" >&2
        return 1
    fi

    # Check if categories list is empty or malformed
    if [ -z "$test_body" ] || [ "$test_body" = "null" ]; then
        echo "📋 Categories list is empty, will create new ones" >&2
        local existing=""
    else
        local existing="$test_body"
    fi

    # First check if category already exists by slug (exact match)
    if echo "$existing" | jq -e ".[] | select(.slug == \"$category_slug\")" > /dev/null 2>&1; then
        echo "✓ Category exists by slug: $category_slug" >&2
        return 0
    fi

    # Try to find existing category by name similarity (search by name)
    local existing_category_name=""
    local existing_category_slug=""

    # Clean up category slug for search (remove dashes, decode common patterns)
    local search_term="${category_slug//-/ }"
    search_term="${search_term//_/ }"

    # Try to find category that contains similar words
    while IFS= read -r category_line; do
        if [ -n "$category_line" ]; then
            # Extract name and slug from each category
            local cat_name=$(echo "$category_line" | jq -r '.name // empty' 2>/dev/null)
            local cat_slug=$(echo "$category_line" | jq -r '.slug // empty' 2>/dev/null)

            if [ -n "$cat_name" ] && [ "$cat_name" != "empty" ] && [ -n "$cat_slug" ]; then
                # Check if the category name contains our search term (case insensitive)
                local lower_cat_name=$(echo "$cat_name" | tr '[:upper:]' '[:lower:]')
                local lower_search=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')

                if [[ "$lower_cat_name" =~ .*"$lower_search".* ]] || [[ "$lower_search" =~ .*"$lower_cat_name".* ]]; then
                    existing_category_name="$cat_name"
                    existing_category_slug="$cat_slug"
                    break
                fi
            fi
        fi
    done <<< "$(echo "$existing" | jq -c '.[]')"

    # If we found a matching category by name, use the existing one
    if [ -n "$existing_category_name" ]; then
        echo "🎯 Found existing category by name match: '$existing_category_name' (slug: $existing_category_slug) for '$category_slug'" >&2
        # Update our processed_categories tracking to use the existing category slug
        mark_category_processed "$existing_category_slug"
        return 0
    fi

    # No existing category found, create a new one
    echo "🔄 No matching category found, creating new category: $category_slug" >&2

    # Map Natura category to a more user-friendly name for display
    local display_name="$category_slug"
    case "$category_slug" in
        "cabello")
            display_name="Cuidado del Cabello"
            ;;
        "perfumeria")
            display_name="Perfumería"
            ;;
        "maquillaje")
            display_name="Maquillaje"
            ;;
        "cuidados-diarios")
            display_name="Cuidado Personal"
            ;;
        "rostro")
            display_name="Cuidado Facial"
            ;;
        "promociones")
            display_name="Promociones"
            ;;
    esac

    # Create JSON payload with user-friendly name
    local json_payload="{\"slug\":\"$category_slug\",\"name\":\"$display_name\",\"isActive\":true}"

    echo "📝 Creating category with payload: $json_payload" >&2

    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/categories" 2>/dev/null)

    local http_code="${response: -3}"
    local response_body="${response%???}"

    echo "📧 Category creation response - HTTP $http_code" >&2

    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ Created new category: $display_name"
        return 0
    else
        echo "❌ Failed to create category: $category_slug" >&2
        echo "📄 Error response: $response_body" >&2
        echo "🔗 Request URL: $API_URL/api/categories" >&2
        echo "📋 Request payload: $json_payload" >&2
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
            
            # Process each product (collect categories in a temp file to avoid subshell issues)
            temp_categories_file=$(mktemp)
            echo "$response" | jq -c '.products[]?' 2>/dev/null | while read -r product; do
                if [ $product_id -gt $max_products ]; then
                    break
                fi

                echo "📦 Processing product $product_id: $(echo "$product" | jq -r '.name // "Unknown"')"

                # Extract category and append to temp file instead of array
                local product_category=$(echo "$product" | jq -r '.categoryId // ""')
                if [ -n "$product_category" ]; then
                    echo "$product_category" >> "$temp_categories_file"
                fi

                if create_product "$product" "$product_id"; then
                    ((success_count++))
                else
                    ((error_count++))
                fi

                ((product_id++))
                ((category_products++))

                sleep 0.5  # Be respectful to APIs
            done

            # Clean up temp file
            rm -f "$temp_categories_file"
            
            ((start += count))
            sleep 1  # Delay between pages
        done

        echo "✅ Completed category: $category ($category_products products)"
        echo ""
    done

    # Count how many categories were processed
    local categories_processed=0
    if [ -n "$processed_categories_list" ]; then
        categories_processed=$(echo "$processed_categories_list" | wc -w)
    fi
    echo ""
    echo "🏷️  Categories created during scraping: $categories_processed"
    if [ $categories_processed -gt 0 ]; then
        echo "   Processed categories: $(echo "$processed_categories_list" | sed 's/ /\\n   - /g' | sed 's/^/   - /')" >&2
    fi

    echo ""
    echo "🎉 Natura API scraping completed!"
    echo "✅ Successfully created: $success_count products"
    echo "❌ Failed to create: $error_count products"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ($success_count + $error_count)" | bc -l 2>/dev/null || echo "N/A")%"
    echo "🏷️  Categories processed: $categories_processed"
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
    echo "🔥 Starting fully automated scraping (no confirmations required)..."
    echo ""
    
    scrape_natura_api
}

main "$@"
