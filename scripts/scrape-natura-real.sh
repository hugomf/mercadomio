#!/bin/bash

# Natura Real Product Scraper
# This script scrapes real products from natura.com.mx

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
TEMP_DIR="./temp_natura_scrape"
IMAGES_DIR="./natura_images"
MAX_PRODUCTS=200
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "🌿 Natura Real Product Scraper"
echo "📡 API URL: $API_URL"
echo "🌐 Natura URL: $NATURA_BASE_URL"
echo "📦 Max products: $MAX_PRODUCTS"
echo ""

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v grep &> /dev/null; then
        missing_deps+=("grep")
    fi
    
    if ! command -v sed &> /dev/null; then
        missing_deps+=("sed")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ Missing dependencies: ${missing_deps[*]}"
        echo "💡 Install missing tools:"
        echo "   - macOS: brew install ${missing_deps[*]}"
        echo "   - Ubuntu: sudo apt-get install ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Create directories
setup_directories() {
    mkdir -p "$TEMP_DIR"
    mkdir -p "$IMAGES_DIR"
    echo "📁 Created temporary directories"
}

# Clean up function
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Trap cleanup on exit
trap cleanup EXIT

# Function to make HTTP requests with proper headers
make_request() {
    local url="$1"
    local output_file="$2"
    
    curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Language: es-MX,es;q=0.8,en-US;q=0.5,en;q=0.3" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        --compressed \
        "$url" > "$output_file"
    
    return $?
}

# Function to extract product URLs from category pages
extract_product_urls() {
    local category_url="$1"
    local temp_file="$TEMP_DIR/category_page.html"
    
    echo "🔍 Extracting product URLs from: $category_url"
    
    if make_request "$category_url" "$temp_file"; then
        # Extract product URLs using multiple patterns
        grep -oE 'href="[^"]*/(producto|product)/[^"]*"' "$temp_file" | \
        sed 's/href="//g' | \
        sed 's/"//g' | \
        sed "s|^/|$NATURA_BASE_URL/|g" | \
        grep -E "(producto|product)" | \
        head -20
    else
        echo "❌ Failed to fetch category page: $category_url"
        return 1
    fi
}

# Function to extract product data from product page
extract_product_data() {
    local product_url="$1"
    local temp_file="$TEMP_DIR/product_page.html"
    
    if make_request "$product_url" "$temp_file"; then
        local name=""
        local price=""
        local description=""
        local image_url=""
        local category=""
        local sku=""
        
        # Extract product name (try multiple selectors)
        name=$(grep -oE '<h1[^>]*>[^<]*</h1>' "$temp_file" | sed 's/<[^>]*>//g' | head -1)
        if [ -z "$name" ]; then
            name=$(grep -oE '<title>[^<]*</title>' "$temp_file" | sed 's/<[^>]*>//g' | sed 's/ - Natura.*//g' | head -1)
        fi
        
        # Extract price (try multiple patterns)
        price=$(grep -oE '\$[0-9,]+(\.[0-9]{2})?' "$temp_file" | head -1 | sed 's/\$//g' | sed 's/,//g')
        if [ -z "$price" ]; then
            price=$(grep -oE '"price"[^0-9]*[0-9]+(\.[0-9]{2})?' "$temp_file" | grep -oE '[0-9]+(\.[0-9]{2})?' | head -1)
        fi
        
        # Extract description
        description=$(grep -oE '<meta name="description" content="[^"]*"' "$temp_file" | sed 's/.*content="//g' | sed 's/".*//g')
        if [ -z "$description" ]; then
            description=$(grep -oE '<p[^>]*class="[^"]*description[^"]*"[^>]*>[^<]*</p>' "$temp_file" | sed 's/<[^>]*>//g' | head -1)
        fi
        
        # Extract main image URL
        image_url=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -1 | sed 's/src="//g' | sed 's/"//g')
        if [[ "$image_url" =~ ^// ]]; then
            image_url="https:$image_url"
        elif [[ "$image_url" =~ ^/ ]]; then
            image_url="$NATURA_BASE_URL$image_url"
        fi
        
        # Extract category from URL or breadcrumbs
        category=$(echo "$product_url" | grep -oE '/(perfumeria|cuidado|maquillaje|cabello|proteccion|facial|corporal|hogar)/' | sed 's|/||g')
        if [ -z "$category" ]; then
            category="Belleza"
        fi
        
        # Generate SKU from URL
        sku=$(echo "$product_url" | grep -oE '[^/]+$' | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:lower:]' '[:upper:]')
        
        # Clean and validate data
        name=$(echo "$name" | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g' | head -c 100)
        description=$(echo "$description" | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g' | head -c 500)
        
        # Only return if we have minimum required data
        if [ -n "$name" ] && [ -n "$price" ]; then
            echo "$name|$price|$description|$image_url|$category|$sku"
            return 0
        fi
    fi
    
    return 1
}

# Function to download and save image
download_image() {
    local image_url="$1"
    local product_id="$2"
    
    if [ -n "$image_url" ] && [[ "$image_url" =~ ^https?:// ]]; then
        local image_extension="${image_url##*.}"
        local image_file="$IMAGES_DIR/natura_${product_id}.${image_extension}"
        
        if curl -s -L -o "$image_file" "$image_url"; then
            echo "$image_file"
            return 0
        fi
    fi
    
    return 1
}

# Function to create product JSON and send to API
create_product() {
    local name="$1"
    local price="$2"
    local description="$3"
    local image_url="$4"
    local category="$5"
    local sku="$6"
    local product_id="$7"
    
    # Download image if URL is provided
    local local_image_path=""
    if [ -n "$image_url" ]; then
        local_image_path=$(download_image "$image_url" "$product_id")
    fi
    
    # Use original image URL or placeholder
    local final_image_url="$image_url"
    if [ -z "$final_image_url" ]; then
        final_image_url="https://picsum.photos/300/400?random=$product_id"
    fi
    
    # Clean price (remove currency symbols and convert to number)
    price=$(echo "$price" | sed 's/[^0-9.]//g')
    if [ -z "$price" ] || [ "$price" = "0" ]; then
        price="99.99"
    fi
    
    # Generate barcode
    local barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
    
    # Create JSON payload
    local json_payload=$(cat <<EOF
{
    "name": "$name",
    "description": "$description",
    "type": "physical",
    "category": "$category",
    "basePrice": $price,
    "sku": "NAT-$sku",
    "barcode": "$barcode",
    "imageUrl": "$final_image_url",
    "variants": [],
    "customAttributes": {
        "brand": "Natura",
        "origin": "Brasil",
        "vegan": true,
        "crueltyFree": true,
        "sustainable": true,
        "scraped": true,
        "sourceUrl": "natura.com.mx"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-$(printf "%06d" $product_id)"
    }
}
EOF
)

    # Send to API
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        return 0
    else
        echo "❌ API Error (HTTP $http_code) for: $name"
        return 1
    fi
}

# Main scraping function
scrape_natura_products() {
    echo "🚀 Starting Natura product scraping..."
    
    # Natura category URLs (you may need to update these based on current site structure)
    local category_urls=(
        "$NATURA_BASE_URL/perfumeria"
        "$NATURA_BASE_URL/cuidado-personal"
        "$NATURA_BASE_URL/maquillaje"
        "$NATURA_BASE_URL/cabello"
        "$NATURA_BASE_URL/proteccion-solar"
        "$NATURA_BASE_URL/cuidado-facial"
        "$NATURA_BASE_URL/cuidado-corporal"
        "$NATURA_BASE_URL/hogar"
    )
    
    local all_product_urls=()
    local success_count=0
    local error_count=0
    
    # Extract product URLs from all categories
    echo "📋 Extracting product URLs from categories..."
    for category_url in "${category_urls[@]}"; do
        echo "🔍 Processing category: $category_url"
        local urls=$(extract_product_urls "$category_url")
        if [ -n "$urls" ]; then
            while IFS= read -r url; do
                all_product_urls+=("$url")
            done <<< "$urls"
        fi
        sleep 1 # Be respectful to the server
    done
    
    echo "📦 Found ${#all_product_urls[@]} product URLs"
    
    # Limit to MAX_PRODUCTS
    if [ ${#all_product_urls[@]} -gt $MAX_PRODUCTS ]; then
        all_product_urls=("${all_product_urls[@]:0:$MAX_PRODUCTS}")
        echo "📊 Limited to $MAX_PRODUCTS products"
    fi
    
    # Process each product
    echo "🌿 Processing individual products..."
    local product_id=1
    
    for product_url in "${all_product_urls[@]}"; do
        echo "📦 Processing product $product_id/${#all_product_urls[@]}: $product_url"
        
        local product_data=$(extract_product_data "$product_url")
        
        if [ $? -eq 0 ] && [ -n "$product_data" ]; then
            IFS='|' read -r name price description image_url category sku <<< "$product_data"
            
            if create_product "$name" "$price" "$description" "$image_url" "$category" "$sku" "$product_id"; then
                ((success_count++))
                echo "✅ Created: $name ($price MXN)"
            else
                ((error_count++))
            fi
        else
            ((error_count++))
            echo "❌ Failed to extract data from: $product_url"
        fi
        
        ((product_id++))
        
        # Progress update
        if [ $((success_count % 10)) -eq 0 ] && [ $success_count -gt 0 ]; then
            echo "📊 Progress: $success_count products created successfully"
        fi
        
        # Be respectful to the server
        sleep 2
    done
    
    echo ""
    echo "🎉 Natura scraping completed!"
    echo "✅ Successfully created: $success_count products"
    echo "❌ Failed to create: $error_count products"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ${#all_product_urls[@]}" | bc -l 2>/dev/null || echo "N/A")%"
    echo "🖼️  Images downloaded to: $IMAGES_DIR"
}

# Main execution
main() {
    echo "🔧 Checking dependencies..."
    if ! check_dependencies; then
        exit 1
    fi
    
    echo "📁 Setting up directories..."
    setup_directories
    
    echo "🌐 Testing API connection..."
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API at $API_URL"
        echo "💡 Make sure your backend is running"
        exit 1
    fi
    echo "✅ API connection successful"
    
    echo ""
    echo "⚠️  IMPORTANT NOTES:"
    echo "   • This script will scrape real data from natura.com.mx"
    echo "   • Please be respectful and don't run this too frequently"
    echo "   • The script includes delays to avoid overwhelming their servers"
    echo "   • Some products may fail due to site structure changes"
    echo ""
    
    read -p "Continue with scraping? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Scraping cancelled"
        exit 0
    fi
    
    scrape_natura_products
}

# Run main function
main "$@"
