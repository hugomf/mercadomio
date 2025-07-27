#!/bin/bash

# Natura Known Products Scraper
# This version uses known Natura product URLs and patterns

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "🌿 Natura Known Products Scraper"
echo "📡 API URL: $API_URL"
echo ""

# Known Natura product URLs and patterns (these are common Natura products)
known_products=(
    # Kaiak line
    "kaiak-aventura-eau-de-toilette"
    "kaiak-clasico-eau-de-toilette"
    "kaiak-extremo-eau-de-toilette"
    "kaiak-oceano-eau-de-toilette"
    "kaiak-pulso-eau-de-toilette"
    
    # Luna line
    "luna-radiante-eau-de-parfum"
    "luna-misteriosa-eau-de-parfum"
    "luna-seductora-eau-de-parfum"
    
    # Tododia line
    "tododia-algodon-crema-corporal"
    "tododia-cereza-crema-corporal"
    "tododia-frambuesa-crema-corporal"
    "tododia-macadamia-crema-corporal"
    "tododia-castana-crema-corporal"
    
    # Ekos line
    "ekos-maracuya-crema-corporal"
    "ekos-andiroba-aceite-corporal"
    "ekos-buriti-protector-solar"
    "ekos-castanha-crema-hidratante"
    "ekos-copaiba-serum-facial"
    "ekos-acai-exfoliante-corporal"
    
    # Chronos line
    "chronos-45-crema-facial"
    "chronos-60-serum-antiedad"
    "chronos-noche-crema-reparadora"
    "chronos-contorno-ojos"
    
    # Plant line
    "plant-shampoo-cabello-graso"
    "plant-shampoo-cabello-seco"
    "plant-acondicionador-reparador"
    "plant-mascarilla-capilar"
    
    # Una makeup line
    "una-base-maquillaje-nude"
    "una-labial-rojo-clasico"
    "una-rimel-volumen"
    "una-sombras-naturales"
    "una-rubor-coral"
    
    # Faces makeup line
    "faces-base-liquida"
    "faces-corrector-ojeras"
    "faces-polvo-compacto"
    "faces-delineador-ojos"
    
    # Essencial line
    "essencial-masculino-eau-de-toilette"
    "essencial-femenino-eau-de-parfum"
    "essencial-oud-eau-de-parfum"
    
    # Mamae e Bebe line
    "mamae-bebe-shampoo-suave"
    "mamae-bebe-crema-hidratante"
    "mamae-bebe-aceite-corporal"
    
    # Home products
    "natura-casa-jabon-liquido-ropa"
    "natura-casa-suavizante"
    "natura-casa-ambientador"
)

# URL patterns to try
url_patterns=(
    "/producto/"
    "/product/"
    "/p/"
    "/item/"
    "/"
)

# Check dependencies
check_deps() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Missing: $cmd"
            return 1
        fi
    done
    return 0
}

# Make HTTP request
fetch_page() {
    local url="$1"
    local output="$2"
    
    curl -s -L --max-time 20 \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: es-MX,es;q=0.8,en;q=0.5" \
        "$url" > "$output" 2>/dev/null
    
    return $?
}

# Try to find a working URL for a product
find_working_url() {
    local product_slug="$1"
    local temp_file="/tmp/natura_test_$$.html"
    
    for pattern in "${url_patterns[@]}"; do
        local test_url="$NATURA_BASE_URL$pattern$product_slug"
        
        if fetch_page "$test_url" "$temp_file"; then
            # Check if it's a valid product page (not 404 or redirect)
            if grep -q -i "natura\|product\|precio\|price" "$temp_file" && \
               ! grep -q -i "404\|not found\|no encontrado" "$temp_file"; then
                rm -f "$temp_file"
                echo "$test_url"
                return 0
            fi
        fi
        
        sleep 0.5
    done
    
    rm -f "$temp_file"
    return 1
}

# Extract product data
extract_product_data() {
    local url="$1"
    local temp_file="/tmp/natura_product_$$.html"
    
    if ! fetch_page "$url" "$temp_file"; then
        rm -f "$temp_file"
        return 1
    fi
    
    local name=""
    local price=""
    local description=""
    local image_url=""
    
    # Extract name
    name=$(grep -oE '<title>[^<]*</title>' "$temp_file" | sed 's/<[^>]*>//g' | sed 's/ - Natura.*//g' | head -1)
    if [ -z "$name" ]; then
        name=$(grep -oE '<h1[^>]*>[^<]*</h1>' "$temp_file" | sed 's/<[^>]*>//g' | head -1)
    fi
    
    # Extract price
    price=$(grep -oE '\$[0-9,]+(\.[0-9]{2})?' "$temp_file" | head -1 | sed 's/\$//; s/,//g')
    if [ -z "$price" ]; then
        price=$(grep -oE '[0-9,]+(\.[0-9]{2})?[[:space:]]*MXN' "$temp_file" | grep -oE '[0-9,]+(\.[0-9]{2})?' | sed 's/,//g' | head -1)
    fi
    
    # Extract description
    description=$(grep -oE '<meta name="description" content="[^"]*"' "$temp_file" | sed 's/.*content="//; s/".*//')
    
    # Extract image
    image_url=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -1 | sed 's/src="//; s/".*//')
    if [[ "$image_url" =~ ^// ]]; then
        image_url="https:$image_url"
    elif [[ "$image_url" =~ ^/ ]]; then
        image_url="$NATURA_BASE_URL$image_url"
    fi
    
    # Clean data
    name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 100)
    description=$(echo "$description" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | head -c 300)
    
    rm -f "$temp_file"
    
    # Validate
    if [ -n "$name" ] && [ -n "$price" ] && [ "$price" != "0" ]; then
        echo "$name|$price|$description|$image_url"
        return 0
    fi
    
    return 1
}

# Generate realistic product data if scraping fails
generate_realistic_product() {
    local product_slug="$1"
    local product_id="$2"
    
    # Convert slug to readable name
    local name=$(echo "$product_slug" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    name="Natura $name"
    
    # Generate realistic price based on product type
    local price="99.99"
    if [[ "$product_slug" =~ eau-de-toilette|eau-de-parfum ]]; then
        price=$((RANDOM % 600 + 200))".00"
    elif [[ "$product_slug" =~ crema|aceite|locion ]]; then
        price=$((RANDOM % 300 + 80))".00"
    elif [[ "$product_slug" =~ shampoo|acondicionador ]]; then
        price=$((RANDOM % 200 + 60))".00"
    elif [[ "$product_slug" =~ maquillaje|base|labial|rimel ]]; then
        price=$((RANDOM % 400 + 100))".00"
    fi
    
    # Generate description
    local description="Producto Natura de alta calidad con ingredientes naturales de la Amazonía brasileña. Fórmula vegana y libre de crueldad animal."
    
    # Generate image URL
    local image_url="https://picsum.photos/300/400?random=$product_id"
    
    echo "$name|$price|$description|$image_url"
}

# Create product in API
create_product() {
    local name="$1"
    local price="$2"
    local description="$3"
    local image_url="$4"
    local product_id="$5"
    local is_scraped="$6"
    
    # Determine category
    local category="Belleza"
    if [[ "$name" =~ [Kk]aiak|[Ll]una|[Ee]ssencial|[Ff]ragran|[Pp]erfum|Eau ]]; then
        category="Perfumería"
    elif [[ "$name" =~ [Mm]aquillaje|[Bb]ase|[Ll]abial|[Rr]ímel|Una|Faces ]]; then
        category="Maquillaje"
    elif [[ "$name" =~ [Cc]abello|[Ss]hampoo|[Aa]condicionador|Plant ]]; then
        category="Cuidado del Cabello"
    elif [[ "$name" =~ [Tt]ododia|[Ee]kos|[Cc]rema|[Cc]orporal ]]; then
        category="Cuidado Personal"
    elif [[ "$name" =~ [Cc]hronos|[Ff]acial|[Ss]erum ]]; then
        category="Cuidado Facial"
    elif [[ "$name" =~ [Cc]asa|[Jj]abón|[Ss]uavizante|[Aa]mbientador ]]; then
        category="Hogar"
    fi
    
    local sku="NAT-KNOWN-$(printf "%04d" "$product_id")"
    local barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
    
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
        "scraped": $is_scraped,
        "knownProduct": true,
        "sourceUrl": "natura.com.mx"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-KNOWN-$(printf "%06d" $product_id)"
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
        if [ "$is_scraped" = "true" ]; then
            echo "✅ Scraped: $name (\$${price} MXN)"
        else
            echo "🔄 Generated: $name (\$${price} MXN)"
        fi
        return 0
    else
        echo "❌ API Error (HTTP $http_code): $name"
        return 1
    fi
}

# Main function
main() {
    if ! check_deps; then
        echo "💡 Install with: brew install curl jq"
        exit 1
    fi
    
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API at $API_URL"
        exit 1
    fi
    echo "✅ API connection successful"
    
    echo ""
    echo "🎯 This script will try to scrape known Natura products"
    echo "   If scraping fails, it will generate realistic product data"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    local success_count=0
    local scraped_count=0
    local generated_count=0
    local product_id=1
    
    echo "🌿 Processing ${#known_products[@]} known Natura products..."
    
    for product_slug in "${known_products[@]}"; do
        echo "📦 Processing $product_id/${#known_products[@]}: $product_slug"
        
        # Try to find working URL
        local working_url=$(find_working_url "$product_slug")
        local product_data=""
        local is_scraped="false"
        
        if [ -n "$working_url" ]; then
            echo "🔍 Found URL: $working_url"
            product_data=$(extract_product_data "$working_url")
            if [ $? -eq 0 ]; then
                is_scraped="true"
                ((scraped_count++))
            fi
        fi
        
        # If scraping failed, generate realistic data
        if [ -z "$product_data" ]; then
            echo "🔄 Generating realistic data for: $product_slug"
            product_data=$(generate_realistic_product "$product_slug" "$product_id")
            ((generated_count++))
        fi
        
        # Create product
        if [ -n "$product_data" ]; then
            IFS='|' read -r name price description image_url <<< "$product_data"
            
            if create_product "$name" "$price" "$description" "$image_url" "$product_id" "$is_scraped"; then
                ((success_count++))
            fi
        fi
        
        ((product_id++))
        sleep 1
    done
    
    echo ""
    echo "🎉 Processing completed!"
    echo "✅ Total products created: $success_count"
    echo "🔍 Successfully scraped: $scraped_count"
    echo "🔄 Generated from templates: $generated_count"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ${#known_products[@]}" | bc -l 2>/dev/null || echo "N/A")%"
}

main "$@"
