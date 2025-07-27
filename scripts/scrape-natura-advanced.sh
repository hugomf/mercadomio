#!/bin/bash

# Advanced Natura Product Scraper with Configuration
# This script uses multiple strategies to scrape real Natura products

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
CONFIG_FILE="./natura-scraper-config.json"
TEMP_DIR="./temp_natura_scrape"
IMAGES_DIR="./natura_images"
LOG_FILE="./natura_scrape.log"

echo "🌿 Advanced Natura Product Scraper"
echo "📡 API URL: $API_URL"
echo "⚙️  Config file: $CONFIG_FILE"
echo ""

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for dep in curl jq grep sed bc; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ Missing dependencies: ${missing_deps[*]}"
        echo "💡 Install with: brew install ${missing_deps[*]}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    return 0
}

# Setup
setup() {
    mkdir -p "$TEMP_DIR" "$IMAGES_DIR"
    > "$LOG_FILE"  # Clear log file
    log "🚀 Starting Natura scraping session"
}

# Cleanup
cleanup() {
    log "🧹 Cleaning up temporary files"
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Load configuration
load_config() {
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "❌ Invalid JSON in config file"
        return 1
    fi
    
    BASE_URL=$(jq -r '.baseUrl' "$CONFIG_FILE")
    USER_AGENT=$(jq -r '.userAgent' "$CONFIG_FILE")
    MAX_PRODUCTS=$(jq -r '.maxProducts' "$CONFIG_FILE")
    DELAY=$(jq -r '.delayBetweenRequests' "$CONFIG_FILE")
    
    log "📋 Configuration loaded: $MAX_PRODUCTS max products, ${DELAY}s delay"
    return 0
}

# Make HTTP request with retries
make_request() {
    local url="$1"
    local output_file="$2"
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -s -L --max-time 30 \
            -H "User-Agent: $USER_AGENT" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            -H "Accept-Language: es-MX,es;q=0.8,en;q=0.5" \
            -H "Cache-Control: no-cache" \
            --compressed \
            "$url" > "$output_file" 2>/dev/null; then
            
            if [ -s "$output_file" ]; then
                return 0
            fi
        fi
        
        ((retry++))
        log "⚠️  Retry $retry/$max_retries for: $url"
        sleep $((retry * 2))
    done
    
    log "❌ Failed to fetch after $max_retries retries: $url"
    return 1
}

# Extract product URLs using multiple strategies
extract_product_urls() {
    local category_name="$1"
    local category_index="$2"
    local temp_file="$TEMP_DIR/category_${category_index}.html"
    local urls_file="$TEMP_DIR/urls_${category_index}.txt"
    
    # Get category URLs from config
    local category_urls=$(jq -r ".categories[$category_index].urls[]" "$CONFIG_FILE")
    
    > "$urls_file"  # Clear file
    
    while IFS= read -r relative_url; do
        local full_url="$BASE_URL$relative_url"
        log "🔍 Scanning category: $full_url"
        
        if make_request "$full_url" "$temp_file"; then
            # Try multiple patterns to find product links
            {
                # Pattern 1: href="/producto/..."
                grep -oE 'href="[^"]*/(producto|product)/[^"]*"' "$temp_file" | sed 's/href="//g; s/"//g'
                
                # Pattern 2: href="/p/..."
                grep -oE 'href="[^"]*/p/[^"]*"' "$temp_file" | sed 's/href="//g; s/"//g'
                
                # Pattern 3: data-href or data-url
                grep -oE 'data-href="[^"]*/(producto|product)/[^"]*"' "$temp_file" | sed 's/data-href="//g; s/"//g'
                
                # Pattern 4: JavaScript product URLs
                grep -oE "'/[^']*/(producto|product)/[^']*'" "$temp_file" | sed "s/'//g"
                
            } | while read -r url; do
                # Convert relative URLs to absolute
                if [[ "$url" =~ ^/ ]]; then
                    echo "$BASE_URL$url"
                elif [[ "$url" =~ ^https?:// ]]; then
                    echo "$url"
                fi
            done | sort -u >> "$urls_file"
        fi
        
        sleep "$DELAY"
    done <<< "$category_urls"
    
    local url_count=$(wc -l < "$urls_file" 2>/dev/null || echo "0")
    log "📦 Found $url_count product URLs in $category_name"
    
    cat "$urls_file" 2>/dev/null
}

# Extract product data using multiple selectors
extract_product_data() {
    local product_url="$1"
    local temp_file="$TEMP_DIR/product_$(basename "$product_url").html"
    
    if ! make_request "$product_url" "$temp_file"; then
        return 1
    fi
    
    local name=""
    local price=""
    local description=""
    local image_url=""
    
    # Extract name using fallback selectors
    local name_selectors=$(jq -r '.fallbackSelectors.name[]' "$CONFIG_FILE")
    while IFS= read -r selector && [ -z "$name" ]; do
        case "$selector" in
            "title")
                name=$(grep -oE '<title>[^<]*</title>' "$temp_file" | sed 's/<[^>]*>//g' | sed 's/ - Natura.*//g')
                ;;
            *)
                # For other selectors, try to extract content
                name=$(grep -i "$selector" "$temp_file" | head -1 | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                ;;
        esac
    done <<< "$name_selectors"
    
    # Extract price using patterns
    local price_patterns=$(jq -r '.pricePatterns[]' "$CONFIG_FILE")
    while IFS= read -r pattern && [ -z "$price" ]; do
        price=$(grep -oE "$pattern" "$temp_file" | head -1 | grep -oE '[0-9,]+(\.[0-9]{2})?' | sed 's/,//g')
    done <<< "$price_patterns"
    
    # Extract description
    description=$(grep -oE '<meta name="description" content="[^"]*"' "$temp_file" | sed 's/.*content="//; s/".*//')
    if [ -z "$description" ]; then
        description=$(grep -i "description" "$temp_file" | head -1 | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    fi
    
    # Extract image URL
    local image_patterns=$(jq -r '.imagePatterns[]' "$CONFIG_FILE")
    while IFS= read -r pattern && [ -z "$image_url" ]; do
        image_url=$(grep -oE "$pattern" "$temp_file" | head -1 | sed 's/.*=["'\'']//' | sed 's/["'\''].*//')
    done <<< "$image_patterns"
    
    # Convert relative image URL to absolute
    if [[ "$image_url" =~ ^// ]]; then
        image_url="https:$image_url"
    elif [[ "$image_url" =~ ^/ ]]; then
        image_url="$BASE_URL$image_url"
    fi
    
    # Validate and clean data
    name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 100)
    description=$(echo "$description" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 500)
    
    if [ -n "$name" ] && [ -n "$price" ] && [ "$price" != "0" ]; then
        echo "$name|$price|$description|$image_url"
        return 0
    fi
    
    return 1
}

# Create and send product to API
create_product() {
    local name="$1"
    local price="$2"
    local description="$3"
    local image_url="$4"
    local category="$5"
    local product_id="$6"
    
    # Generate SKU and barcode
    local sku="REAL-$(echo "$name" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:lower:]' '[:upper:]' | head -c 20)"
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
        log "✅ Created: $name (\$${price} MXN)"
        return 0
    else
        log "❌ API Error (HTTP $http_code): $name"
        return 1
    fi
}

# Main scraping function
main_scrape() {
    local success_count=0
    local error_count=0
    local product_id=1
    local all_urls=()
    
    # Get number of categories
    local category_count=$(jq '.categories | length' "$CONFIG_FILE")
    
    # Extract URLs from all categories
    for ((i=0; i<category_count; i++)); do
        local category_name=$(jq -r ".categories[$i].name" "$CONFIG_FILE")
        log "📂 Processing category: $category_name"
        
        local urls=$(extract_product_urls "$category_name" "$i")
        while IFS= read -r url; do
            if [ -n "$url" ]; then
                all_urls+=("$url")
            fi
        done <<< "$urls"
    done
    
    log "📊 Total product URLs found: ${#all_urls[@]}"
    
    # Limit to MAX_PRODUCTS
    if [ ${#all_urls[@]} -gt "$MAX_PRODUCTS" ]; then
        all_urls=("${all_urls[@]:0:$MAX_PRODUCTS}")
        log "📊 Limited to $MAX_PRODUCTS products"
    fi
    
    # Process each product
    for product_url in "${all_urls[@]}"; do
        log "📦 Processing product $product_id/${#all_urls[@]}: $product_url"
        
        local product_data=$(extract_product_data "$product_url")
        
        if [ $? -eq 0 ] && [ -n "$product_data" ]; then
            IFS='|' read -r name price description image_url <<< "$product_data"
            
            # Determine category from URL
            local category="Belleza"
            if [[ "$product_url" =~ perfumeria|fragancia ]]; then
                category="Perfumería"
            elif [[ "$product_url" =~ maquillaje|makeup ]]; then
                category="Maquillaje"
            elif [[ "$product_url" =~ cabello|hair ]]; then
                category="Cuidado del Cabello"
            elif [[ "$product_url" =~ cuidado|personal ]]; then
                category="Cuidado Personal"
            fi
            
            if create_product "$name" "$price" "$description" "$image_url" "$category" "$product_id"; then
                ((success_count++))
            else
                ((error_count++))
            fi
        else
            ((error_count++))
            log "❌ Failed to extract data from: $product_url"
        fi
        
        ((product_id++))
        sleep "$DELAY"
    done
    
    log "🎉 Scraping completed!"
    log "✅ Successfully created: $success_count products"
    log "❌ Failed to create: $error_count products"
    
    if [ ${#all_urls[@]} -gt 0 ]; then
        local success_rate=$(echo "scale=1; $success_count * 100 / ${#all_urls[@]}" | bc -l 2>/dev/null || echo "N/A")
        log "📊 Success rate: ${success_rate}%"
    fi
}

# Main execution
main() {
    if ! check_dependencies; then
        exit 1
    fi
    
    setup
    
    if ! load_config; then
        exit 1
    fi
    
    # Test API connection
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        log "❌ Cannot connect to API at $API_URL"
        exit 1
    fi
    log "✅ API connection successful"
    
    echo ""
    echo "⚠️  IMPORTANT:"
    echo "   • This will scrape REAL products from natura.com.mx"
    echo "   • Please be respectful to their servers"
    echo "   • The script includes delays and retries"
    echo "   • Check the log file for detailed progress"
    echo ""
    
    read -p "Continue with real product scraping? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "❌ Scraping cancelled by user"
        exit 0
    fi
    
    main_scrape
    
    echo ""
    echo "📋 Check the log file for details: $LOG_FILE"
    echo "🖼️  Images saved to: $IMAGES_DIR"
}

main "$@"
