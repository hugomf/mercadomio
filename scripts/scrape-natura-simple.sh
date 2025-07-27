#!/bin/bash

# Simple Natura Product Scraper
# This version uses a more direct approach to scraping

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
TEMP_DIR="./temp_natura_simple"
MAX_PRODUCTS=100
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "🌿 Simple Natura Product Scraper"
echo "📡 API URL: $API_URL"
echo "🎯 Target: $MAX_PRODUCTS products"
echo ""

# Check dependencies
check_deps() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Missing: $cmd"
            echo "💡 Install with: brew install $cmd"
            return 1
        fi
    done
    return 0
}

# Setup
setup() {
    mkdir -p "$TEMP_DIR"
    echo "📁 Created temp directory: $TEMP_DIR"
}

# Cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Make HTTP request
fetch_page() {
    local url="$1"
    local output="$2"
    
    curl -s -L --max-time 30 \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: es-MX,es;q=0.8,en;q=0.5" \
        "$url" > "$output" 2>/dev/null
    
    return $?
}

# Try to find product URLs using multiple strategies
find_product_urls() {
    local search_terms=("kaiak" "luna" "tododia" "ekos" "chronos" "plant" "una" "faces")
    local all_urls=()
    
    echo "🔍 Searching for products using different strategies..."
    
    # Strategy 1: Try search pages
    for term in "${search_terms[@]}"; do
        echo "🔎 Searching for: $term"
        local search_url="$NATURA_BASE_URL/search?q=$term"
        local temp_file="$TEMP_DIR/search_$term.html"
        
        if fetch_page "$search_url" "$temp_file"; then
            # Extract product URLs from search results
            local urls=$(grep -oE 'href="[^"]*"' "$temp_file" | \
                        sed 's/href="//g; s/"//g' | \
                        grep -E "(producto|product|p)/" | \
                        grep -v "#" | \
                        head -5)
            
            while IFS= read -r url; do
                if [ -n "$url" ]; then
                    if [[ "$url" =~ ^/ ]]; then
                        all_urls+=("$NATURA_BASE_URL$url")
                    elif [[ "$url" =~ ^https?:// ]]; then
                        all_urls+=("$url")
                    fi
                fi
            done <<< "$urls"
        fi
        
        sleep 1
    done
    
    # Strategy 2: Try category pages with different URL patterns
    local category_patterns=(
        "/perfumeria"
        "/cuidado-personal"
        "/maquillaje"
        "/cabello"
        "/categoria/perfumeria"
        "/categoria/cuidado-personal"
        "/c/perfumeria"
        "/c/maquillaje"
    )
    
    for pattern in "${category_patterns[@]}"; do
        echo "🔎 Trying category: $pattern"
        local cat_url="$NATURA_BASE_URL$pattern"
        local temp_file="$TEMP_DIR/cat_$(basename "$pattern").html"
        
        if fetch_page "$cat_url" "$temp_file"; then
            local urls=$(grep -oE 'href="[^"]*"' "$temp_file" | \
                        sed 's/href="//g; s/"//g' | \
                        grep -E "(producto|product|p)/" | \
                        grep -v "#" | \
                        head -10)
            
            while IFS= read -r url; do
                if [ -n "$url" ]; then
                    if [[ "$url" =~ ^/ ]]; then
                        all_urls+=("$NATURA_BASE_URL$url")
                    elif [[ "$url" =~ ^https?:// ]]; then
                        all_urls+=("$url")
                    fi
                fi
            done <<< "$urls"
        fi
        
        sleep 1
    done
    
    # Remove duplicates and return
    printf '%s\n' "${all_urls[@]}" | sort -u
}

# Extract product data from a product page
extract_product_data() {
    local url="$1"
    local temp_file="$TEMP_DIR/product_$(basename "$url" | tr '/' '_').html"
    
    if ! fetch_page "$url" "$temp_file"; then
        return 1
    fi
    
    local name=""
    local price=""
    local description=""
    local image_url=""
    
    # Extract name - try multiple selectors
    name=$(grep -oE '<title>[^<]*</title>' "$temp_file" | sed 's/<[^>]*>//g' | sed 's/ - Natura.*//g' | head -1)
    if [ -z "$name" ]; then
        name=$(grep -oE '<h1[^>]*>[^<]*</h1>' "$temp_file" | sed 's/<[^>]*>//g' | head -1)
    fi
    if [ -z "$name" ]; then
        name=$(grep -i "product.*name\|title" "$temp_file" | head -1 | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    fi
    
    # Extract price - try multiple patterns
    price=$(grep -oE '\$[0-9,]+(\.[0-9]{2})?' "$temp_file" | head -1 | sed 's/\$//; s/,//g')
    if [ -z "$price" ]; then
        price=$(grep -oE '"price"[^0-9]*([0-9,]+(\.[0-9]{2})?)' "$temp_file" | grep -oE '[0-9,]+(\.[0-9]{2})?' | sed 's/,//g' | head -1)
    fi
    if [ -z "$price" ]; then
        price=$(grep -oE '[0-9,]+(\.[0-9]{2})?[[:space:]]*MXN' "$temp_file" | grep -oE '[0-9,]+(\.[0-9]{2})?' | sed 's/,//g' | head -1)
    fi
    
    # Extract description
    description=$(grep -oE '<meta name="description" content="[^"]*"' "$temp_file" | sed 's/.*content="//; s/".*//')
    if [ -z "$description" ]; then
        description="Producto Natura de alta calidad con ingredientes naturales."
    fi
    
    # Extract image URL
    image_url=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -1 | sed 's/src="//; s/".*//')
    if [[ "$image_url" =~ ^// ]]; then
        image_url="https:$image_url"
    elif [[ "$image_url" =~ ^/ ]]; then
        image_url="$NATURA_BASE_URL$image_url"
    fi
    
    # Clean data
    name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 100)
    description=$(echo "$description" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 300)
    
    # Validate minimum data
    if [ -n "$name" ] && [ -n "$price" ] && [ "$price" != "0" ]; then
        echo "$name|$price|$description|$image_url"
        return 0
    fi
    
    return 1
}

# Create product in API
create_product() {
    local name="$1"
    local price="$2"
    local description="$3"
    local image_url="$4"
    local product_id="$5"
    
    # Determine category from name
    local category="Belleza"
    if [[ "$name" =~ [Kk]aiak|[Ll]una|[Ee]ssencial|[Ff]ragran|[Pp]erfum ]]; then
        category="Perfumería"
    elif [[ "$name" =~ [Mm]aquillaje|[Bb]ase|[Ll]abial|[Rr]ímel ]]; then
        category="Maquillaje"
    elif [[ "$name" =~ [Cc]abello|[Ss]hampoo|[Aa]condicionador ]]; then
        category="Cuidado del Cabello"
    elif [[ "$name" =~ [Tt]ododia|[Ee]kos|[Cc]rema|[Cc]orporal ]]; then
        category="Cuidado Personal"
    fi
    
    # Generate SKU and barcode
    local sku="NAT-REAL-$(printf "%04d" "$product_id")"
    local barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
    
    # Use placeholder if no image
    if [ -z "$image_url" ]; then
        image_url="https://picsum.photos/300/400?random=$product_id"
    fi
    
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
        "brand": "Natura",
        "origin": "Brasil",
        "vegan": true,
        "crueltyFree": true,
        "sustainable": true,
        "scraped": true,
        "realProduct": true,
        "sourceUrl": "natura.com.mx"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-REAL-$(printf "%06d" $product_id)"
    }
}
EOF
)

    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ Created: $name (\$${price} MXN)"
        return 0
    else
        echo "❌ API Error (HTTP $http_code): $name"
        return 1
    fi
}

# Main function
main() {
    echo "🔧 Checking dependencies..."
    if ! check_deps; then
        exit 1
    fi
    
    echo "📁 Setting up..."
    setup
    
    echo "🌐 Testing API connection..."
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API at $API_URL"
        exit 1
    fi
    echo "✅ API connection successful"
    
    echo ""
    echo "⚠️  This will attempt to scrape real products from natura.com.mx"
    echo "   The script will be respectful with delays and limits"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 0
    fi
    
    echo "🔍 Finding product URLs..."
    local product_urls=($(find_product_urls))
    
    echo "📊 Found ${#product_urls[@]} potential product URLs"
    
    if [ ${#product_urls[@]} -eq 0 ]; then
        echo "❌ No product URLs found. The site structure may have changed."
        echo "💡 Try updating the search terms or URL patterns in the script."
        exit 1
    fi
    
    # Limit to MAX_PRODUCTS
    if [ ${#product_urls[@]} -gt $MAX_PRODUCTS ]; then
        product_urls=("${product_urls[@]:0:$MAX_PRODUCTS}")
        echo "📊 Limited to $MAX_PRODUCTS products"
    fi
    
    echo "🌿 Processing products..."
    local success_count=0
    local error_count=0
    local product_id=1
    
    for url in "${product_urls[@]}"; do
        echo "📦 Processing $product_id/${#product_urls[@]}: $url"
        
        local product_data=$(extract_product_data "$url")
        
        if [ $? -eq 0 ] && [ -n "$product_data" ]; then
            IFS='|' read -r name price description image_url <<< "$product_data"
            
            if create_product "$name" "$price" "$description" "$image_url" "$product_id"; then
                ((success_count++))
            else
                ((error_count++))
            fi
        else
            ((error_count++))
            echo "❌ Failed to extract data from: $url"
        fi
        
        ((product_id++))
        sleep 2  # Be respectful
    done
    
    echo ""
    echo "🎉 Scraping completed!"
    echo "✅ Successfully created: $success_count products"
    echo "❌ Failed to create: $error_count products"
    
    if [ ${#product_urls[@]} -gt 0 ]; then
        local success_rate=$(echo "scale=1; $success_count * 100 / ${#product_urls[@]}" | bc -l 2>/dev/null || echo "N/A")
        echo "📊 Success rate: ${success_rate}%"
    fi
}

main "$@"
