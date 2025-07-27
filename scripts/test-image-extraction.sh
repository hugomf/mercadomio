#!/bin/bash

# Test Image Extraction from Natura
# This script helps debug image extraction issues

NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TEMP_DIR="./temp_image_test"

echo "🖼️  Natura Image Extraction Tester"
echo ""

# Setup
mkdir -p "$TEMP_DIR"

# Cleanup
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Fetch page
fetch_page() {
    local url="$1"
    local output="$2"
    
    curl -s -L --max-time 30 \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        -H "Accept-Language: es-MX,es;q=0.8,en;q=0.5" \
        "$url" > "$output" 2>/dev/null
}

# Test image extraction from a URL
test_image_extraction() {
    local test_url="$1"
    local temp_file="$TEMP_DIR/test_page.html"
    
    echo "🔍 Testing URL: $test_url"
    echo ""
    
    if fetch_page "$test_url" "$temp_file"; then
        echo "✅ Page fetched successfully"
        echo "📄 Page size: $(wc -c < "$temp_file") bytes"
        echo ""
        
        echo "🖼️  Image extraction strategies:"
        echo ""
        
        # Strategy 1: Standard src attributes
        echo "1️⃣  Standard src attributes:"
        local images1=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -5)
        if [ -n "$images1" ]; then
            echo "$images1" | while read -r img; do
                echo "   $img"
            done
        else
            echo "   ❌ No images found"
        fi
        echo ""
        
        # Strategy 2: data-src attributes (lazy loading)
        echo "2️⃣  Data-src attributes (lazy loading):"
        local images2=$(grep -oE 'data-src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -5)
        if [ -n "$images2" ]; then
            echo "$images2" | while read -r img; do
                echo "   $img"
            done
        else
            echo "   ❌ No data-src images found"
        fi
        echo ""
        
        # Strategy 3: og:image meta tags
        echo "3️⃣  Open Graph images:"
        local images3=$(grep -oE 'property="og:image" content="[^"]*"' "$temp_file")
        if [ -n "$images3" ]; then
            echo "$images3" | while read -r img; do
                echo "   $img"
            done
        else
            echo "   ❌ No og:image found"
        fi
        echo ""
        
        # Strategy 4: srcset attributes
        echo "4️⃣  Srcset attributes:"
        local images4=$(grep -oE 'srcset="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -3)
        if [ -n "$images4" ]; then
            echo "$images4" | while read -r img; do
                echo "   $img"
            done
        else
            echo "   ❌ No srcset images found"
        fi
        echo ""
        
        # Strategy 5: Product-specific images
        echo "5️⃣  Product-specific images:"
        local images5=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | grep -E "(product|imagen|foto|main|hero)" | head -3)
        if [ -n "$images5" ]; then
            echo "$images5" | while read -r img; do
                echo "   $img"
            done
        else
            echo "   ❌ No product-specific images found"
        fi
        echo ""
        
        # Show some HTML context around images
        echo "6️⃣  HTML context around images:"
        local context=$(grep -B2 -A2 'src="[^"]*\.(jpg|jpeg|png|webp)' "$temp_file" | head -10)
        if [ -n "$context" ]; then
            echo "$context"
        else
            echo "   ❌ No image context found"
        fi
        echo ""
        
        # Test actual image download
        echo "7️⃣  Testing image download:"
        local test_image=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -1 | sed 's/src="//; s/".*//')
        
        if [ -n "$test_image" ]; then
            # Convert to absolute URL if needed
            if [[ "$test_image" =~ ^// ]]; then
                test_image="https:$test_image"
            elif [[ "$test_image" =~ ^/ ]]; then
                test_image="$NATURA_BASE_URL$test_image"
            fi
            
            echo "   Testing download of: $test_image"
            
            local test_file="$TEMP_DIR/test_image.jpg"
            if curl -s -L --max-time 10 \
                -H "User-Agent: $USER_AGENT" \
                -H "Referer: $test_url" \
                -o "$test_file" "$test_image"; then
                
                if [ -s "$test_file" ]; then
                    local file_size=$(wc -c < "$test_file")
                    echo "   ✅ Image downloaded successfully ($file_size bytes)"
                    
                    # Check if it's a valid image by looking at file header
                    local file_type=$(file "$test_file" 2>/dev/null | cut -d: -f2)
                    echo "   📄 File type: $file_type"
                else
                    echo "   ❌ Downloaded file is empty"
                fi
            else
                echo "   ❌ Failed to download image"
            fi
        else
            echo "   ❌ No image URL to test"
        fi
        
    else
        echo "❌ Failed to fetch page"
    fi
}

# Test with different URL patterns
test_urls() {
    local base_product="kaiak-aventura"
    
    echo "🧪 Testing different URL patterns for: $base_product"
    echo ""
    
    local patterns=(
        "/producto/$base_product"
        "/product/$base_product"
        "/p/$base_product"
        "/c/perfumeria/$base_product"
        "/$base_product"
    )
    
    for pattern in "${patterns[@]}"; do
        local test_url="$NATURA_BASE_URL$pattern"
        echo "🔗 Testing pattern: $pattern"
        
        local temp_file="$TEMP_DIR/pattern_test.html"
        if fetch_page "$test_url" "$temp_file"; then
            local page_size=$(wc -c < "$temp_file")
            if [ "$page_size" -gt 1000 ]; then
                echo "   ✅ Valid page found ($page_size bytes)"
                
                # Quick image check
                local image_count=$(grep -c 'src="[^"]*\.(jpg|jpeg|png|webp)' "$temp_file" 2>/dev/null || echo "0")
                echo "   🖼️  Images found: $image_count"
                
                if [ "$image_count" -gt 0 ]; then
                    echo "   🎯 This pattern works! Testing full extraction..."
                    test_image_extraction "$test_url"
                    return 0
                fi
            else
                echo "   ❌ Page too small or empty"
            fi
        else
            echo "   ❌ Failed to fetch"
        fi
        echo ""
    done
    
    echo "❌ No working URL pattern found for $base_product"
}

# Main function
main() {
    if [ $# -eq 1 ]; then
        # Test specific URL provided by user
        test_image_extraction "$1"
    else
        # Test different patterns
        test_urls
    fi
}

echo "Usage:"
echo "  $0                    # Test different URL patterns"
echo "  $0 <specific_url>     # Test specific URL"
echo ""

main "$@"
