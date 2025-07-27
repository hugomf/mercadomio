#!/bin/bash

# Natura Image Scraper - Focus on getting real product images
# This script specifically targets image extraction from Natura's website

API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TEMP_DIR="./temp_natura_images"

echo "🖼️  Natura Real Image Scraper"
echo "📡 API URL: $API_URL"
echo "🌐 Target: $NATURA_BASE_URL"
echo ""

# Setup
mkdir -p "$TEMP_DIR"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Fetch page with proper headers
fetch_page() {
    local url="$1"
    local output="$2"
    
    curl -s -L --max-time 30 \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Language: es-MX,es;q=0.8,en;q=0.5" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        --compressed \
        "$url" > "$output" 2>/dev/null
}

# Try different URL patterns to find working product pages
find_working_product_urls() {
    local search_terms=("kaiak" "luna" "tododia" "ekos" "chronos" "plant" "una" "faces" "essencial")
    local working_urls=()
    
    echo "🔍 Searching for working product URLs..."
    
    for term in "${search_terms[@]}"; do
        echo "🔎 Testing search term: $term"
        
        # Try different URL patterns
        local patterns=(
            "/search?q=$term"
            "/buscar?q=$term"
            "/productos?search=$term"
            "/c/perfumeria?q=$term"
        )
        
        for pattern in "${patterns[@]}"; do
            local search_url="$NATURA_BASE_URL$pattern"
            local temp_file="$TEMP_DIR/search_${term}_$(basename "$pattern").html"
            
            if fetch_page "$search_url" "$temp_file"; then
                # Look for product links in the search results
                local product_links=$(grep -oE 'href="[^"]*"' "$temp_file" | \
                                    sed 's/href="//g; s/"//g' | \
                                    grep -E "(producto|product|p)/" | \
                                    grep -v "#" | \
                                    head -3)
                
                while IFS= read -r link; do
                    if [ -n "$link" ]; then
                        if [[ "$link" =~ ^/ ]]; then
                            working_urls+=("$NATURA_BASE_URL$link")
                        elif [[ "$link" =~ ^https?:// ]]; then
                            working_urls+=("$link")
                        fi
                    fi
                done <<< "$product_links"
            fi
            
            sleep 1
        done
        
        # If we found some URLs, test them
        if [ ${#working_urls[@]} -gt 0 ]; then
            echo "✅ Found ${#working_urls[@]} potential product URLs"
            break
        fi
    done
    
    # Remove duplicates and return
    printf '%s\n' "${working_urls[@]}" | sort -u
}

# Extract images from a product page using multiple strategies
extract_images_from_page() {
    local url="$1"
    local temp_file="$TEMP_DIR/product_$(basename "$url" | tr '/' '_').html"
    
    echo "🔍 Extracting images from: $url"
    
    if ! fetch_page "$url" "$temp_file"; then
        echo "❌ Failed to fetch page"
        return 1
    fi
    
    local images=()
    
    # Strategy 1: Look for main product images
    echo "1️⃣  Looking for main product images..."
    local main_images=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | \
                       grep -E "(product|main|hero|imagen|foto)" | \
                       sed 's/src="//; s/".*//' | \
                       head -3)
    
    while IFS= read -r img; do
        [ -n "$img" ] && images+=("$img")
    done <<< "$main_images"
    
    # Strategy 2: Look for data-src (lazy loading)
    echo "2️⃣  Looking for lazy-loaded images..."
    local lazy_images=$(grep -oE 'data-src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | \
                       sed 's/data-src="//; s/".*//' | \
                       head -3)
    
    while IFS= read -r img; do
        [ -n "$img" ] && images+=("$img")
    done <<< "$lazy_images"
    
    # Strategy 3: Look for og:image
    echo "3️⃣  Looking for Open Graph images..."
    local og_images=$(grep -oE 'property="og:image" content="[^"]*"' "$temp_file" | \
                     sed 's/.*content="//; s/".*//')
    
    while IFS= read -r img; do
        [ -n "$img" ] && images+=("$img")
    done <<< "$og_images"
    
    # Strategy 4: Look for any large images (exclude small icons)
    echo "4️⃣  Looking for any large images..."
    local all_images=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | \
                      sed 's/src="//; s/".*//' | \
                      grep -v "icon\|logo\|thumb\|small\|mini\|16x16\|32x32" | \
                      head -5)
    
    while IFS= read -r img; do
        [ -n "$img" ] && images+=("$img")
    done <<< "$all_images"
    
    # Convert relative URLs to absolute and remove duplicates
    local final_images=()
    for img in "${images[@]}"; do
        if [[ "$img" =~ ^// ]]; then
            final_images+=("https:$img")
        elif [[ "$img" =~ ^/ ]]; then
            final_images+=("$NATURA_BASE_URL$img")
        elif [[ "$img" =~ ^https?:// ]]; then
            final_images+=("$img")
        fi
    done
    
    # Remove duplicates
    printf '%s\n' "${final_images[@]}" | sort -u
}

# Test image download
test_image_download() {
    local image_url="$1"
    local test_file="$TEMP_DIR/test_image.jpg"
    
    echo "🧪 Testing download: $image_url"
    
    if curl -s -L --max-time 10 \
        -H "User-Agent: $USER_AGENT" \
        -H "Referer: $NATURA_BASE_URL" \
        -o "$test_file" "$image_url"; then
        
        if [ -s "$test_file" ]; then
            local file_size=$(wc -c < "$test_file")
            local file_type=$(file "$test_file" 2>/dev/null | cut -d: -f2)
            echo "✅ Downloaded successfully ($file_size bytes)"
            echo "📄 File type: $file_type"
            
            # Check if it's a reasonable size (not too small)
            if [ "$file_size" -gt 1000 ]; then
                echo "✅ Image appears to be valid"
                rm -f "$test_file"
                return 0
            else
                echo "⚠️  Image too small, might be a placeholder"
            fi
        else
            echo "❌ Downloaded file is empty"
        fi
    else
        echo "❌ Failed to download"
    fi
    
    rm -f "$test_file"
    return 1
}

# Main function
main() {
    echo "🔧 Testing API connection..."
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API"
        exit 1
    fi
    echo "✅ API connection successful"
    
    echo ""
    echo "🎯 This script will find real product images from Natura's website"
    echo "   It will test different strategies to extract working image URLs"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Find working product URLs
    local product_urls=($(find_working_product_urls))
    
    if [ ${#product_urls[@]} -eq 0 ]; then
        echo "❌ No working product URLs found"
        echo "💡 The site structure may have changed or be blocking requests"
        exit 1
    fi
    
    echo "📊 Found ${#product_urls[@]} product URLs to test"
    echo ""
    
    # Test image extraction from each URL
    local total_images=0
    local working_images=0
    
    for url in "${product_urls[@]}"; do
        echo "🔍 Testing URL: $url"
        
        local images=($(extract_images_from_page "$url"))
        
        if [ ${#images[@]} -gt 0 ]; then
            echo "📸 Found ${#images[@]} images:"
            
            for img in "${images[@]}"; do
                echo "   $img"
                ((total_images++))
                
                if test_image_download "$img"; then
                    ((working_images++))
                    echo "   ✅ This image works!"
                else
                    echo "   ❌ This image failed"
                fi
                echo ""
            done
        else
            echo "❌ No images found on this page"
        fi
        
        echo "----------------------------------------"
        sleep 2
    done
    
    echo ""
    echo "🎉 Image extraction test completed!"
    echo "📊 Total images found: $total_images"
    echo "✅ Working images: $working_images"
    echo "📈 Success rate: $(echo "scale=1; $working_images * 100 / $total_images" | bc -l 2>/dev/null || echo "N/A")%"
    
    if [ "$working_images" -gt 0 ]; then
        echo ""
        echo "✅ Great! The image extraction is working."
        echo "💡 You can now use the improved scraping scripts to get real images."
    else
        echo ""
        echo "❌ No working images found."
        echo "💡 Consider using the high-quality placeholder images instead."
        echo "   Run: ./scrape-natura-with-images.sh"
    fi
}

main "$@"
