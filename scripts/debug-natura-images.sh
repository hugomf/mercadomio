#!/bin/bash

# Debug Natura Images - Find real image URLs
# This script specifically looks for Natura's production image URLs

NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TEMP_DIR="./temp_debug_images"

echo "🔍 Natura Image URL Debug Tool"
echo "🎯 Looking for URLs like: https://production.na01.natura.com/on/demandware.static/-/Sites-nat-mex-b2b2c-catalog/default/dw54b0c884/produtos/NATMEX-111172_2.jpg"
echo ""

# Setup
mkdir -p "$TEMP_DIR"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Fetch page
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

# Test specific product URLs
test_product_urls() {
    local test_urls=(
        "$NATURA_BASE_URL/c/perfumeria/kaiak-aventura"
        "$NATURA_BASE_URL/c/perfumeria/luna-radiante"
        "$NATURA_BASE_URL/c/perfumeria/essencial"
        "$NATURA_BASE_URL/producto/kaiak-aventura"
        "$NATURA_BASE_URL/producto/luna-radiante"
        "$NATURA_BASE_URL/p/kaiak-aventura"
        "$NATURA_BASE_URL/p/luna-radiante"
        "$NATURA_BASE_URL/kaiak-aventura"
        "$NATURA_BASE_URL/luna-radiante"
    )
    
    echo "🧪 Testing specific product URLs..."
    echo ""
    
    for url in "${test_urls[@]}"; do
        echo "🔗 Testing: $url"
        local temp_file="$TEMP_DIR/test_$(basename "$url").html"
        
        if fetch_page "$url" "$temp_file"; then
            local page_size=$(wc -c < "$temp_file")
            echo "   📄 Page size: $page_size bytes"
            
            if [ "$page_size" -gt 1000 ]; then
                echo "   ✅ Valid page found"
                
                # Look for Natura production images
                echo "   🔍 Searching for Natura production images..."
                local natura_images=$(grep -oE 'production\.na01\.natura\.com[^"]*\.(jpg|jpeg|png|webp)' "$temp_file")
                
                if [ -n "$natura_images" ]; then
                    echo "   🎉 FOUND NATURA IMAGES:"
                    echo "$natura_images" | while read -r img; do
                        echo "      📸 https://$img"
                    done
                    
                    # Test downloading the first image
                    local first_image="https://$(echo "$natura_images" | head -1)"
                    echo "   🧪 Testing download of: $first_image"
                    
                    local test_file="$TEMP_DIR/test_image.jpg"
                    if curl -s -L --max-time 10 \
                        -H "User-Agent: $USER_AGENT" \
                        -H "Referer: $url" \
                        -o "$test_file" "$first_image"; then
                        
                        if [ -s "$test_file" ]; then
                            local file_size=$(wc -c < "$test_file")
                            echo "      ✅ Downloaded successfully ($file_size bytes)"
                            
                            # Check file type
                            local file_type=$(file "$test_file" 2>/dev/null | cut -d: -f2)
                            echo "      📄 File type: $file_type"
                            
                            if [ "$file_size" -gt 5000 ]; then
                                echo "      🎯 This is a good quality image!"
                                echo ""
                                echo "🎉 SUCCESS! Found working Natura image URL pattern!"
                                echo "📸 Working URL: $first_image"
                                echo ""
                                return 0
                            fi
                        fi
                    fi
                else
                    echo "   ❌ No Natura production images found"
                    
                    # Look for any images as fallback
                    echo "   🔍 Looking for any images..."
                    local any_images=$(grep -oE 'src="[^"]*\.(jpg|jpeg|png|webp)[^"]*"' "$temp_file" | head -5)
                    if [ -n "$any_images" ]; then
                        echo "   📸 Found other images:"
                        echo "$any_images" | while read -r img; do
                            echo "      $img"
                        done
                    else
                        echo "   ❌ No images found at all"
                    fi
                fi
            else
                echo "   ❌ Page too small or empty"
            fi
        else
            echo "   ❌ Failed to fetch"
        fi
        
        echo ""
        sleep 1
    done
    
    return 1
}

# Search for Natura images in search results
search_for_images() {
    echo "🔎 Searching for products with images..."
    
    local search_terms=("kaiak" "luna" "tododia" "ekos" "chronos")
    
    for term in "${search_terms[@]}"; do
        echo "🔍 Searching for: $term"
        
        local search_urls=(
            "$NATURA_BASE_URL/search?q=$term"
            "$NATURA_BASE_URL/buscar?q=$term"
            "$NATURA_BASE_URL/productos?search=$term"
        )
        
        for search_url in "${search_urls[@]}"; do
            echo "   🔗 Trying: $search_url"
            local temp_file="$TEMP_DIR/search_${term}.html"
            
            if fetch_page "$search_url" "$temp_file"; then
                local page_size=$(wc -c < "$temp_file")
                
                if [ "$page_size" -gt 2000 ]; then
                    echo "      📄 Got search results ($page_size bytes)"
                    
                    # Look for Natura production images in search results
                    local natura_images=$(grep -oE 'production\.na01\.natura\.com[^"]*\.(jpg|jpeg|png|webp)' "$temp_file")
                    
                    if [ -n "$natura_images" ]; then
                        echo "      🎉 FOUND NATURA IMAGES IN SEARCH:"
                        echo "$natura_images" | head -3 | while read -r img; do
                            echo "         📸 https://$img"
                        done
                        
                        # Also look for product links
                        local product_links=$(grep -oE 'href="[^"]*"' "$temp_file" | grep -E "(producto|product|p)/" | head -3)
                        if [ -n "$product_links" ]; then
                            echo "      🔗 Found product links:"
                            echo "$product_links" | while read -r link; do
                                echo "         $link"
                            done
                        fi
                        
                        return 0
                    else
                        echo "      ❌ No Natura images in search results"
                    fi
                else
                    echo "      ❌ Search results too small"
                fi
            else
                echo "      ❌ Search failed"
            fi
        done
        
        sleep 1
    done
    
    return 1
}

# Analyze page structure
analyze_page_structure() {
    local url="$1"
    local temp_file="$TEMP_DIR/analyze.html"
    
    echo "🔬 Analyzing page structure: $url"
    
    if fetch_page "$url" "$temp_file"; then
        echo "📊 Page analysis:"
        echo "   📄 Total size: $(wc -c < "$temp_file") bytes"
        echo "   🏷️  Total img tags: $(grep -c '<img' "$temp_file" 2>/dev/null || echo "0")"
        echo "   🖼️  Total src attributes: $(grep -c 'src=' "$temp_file" 2>/dev/null || echo "0")"
        echo "   📱 Total data-src attributes: $(grep -c 'data-src=' "$temp_file" 2>/dev/null || echo "0")"
        echo "   🌐 Natura domain mentions: $(grep -c 'natura\.com' "$temp_file" 2>/dev/null || echo "0")"
        echo "   🏭 Production domain mentions: $(grep -c 'production\.na01\.natura\.com' "$temp_file" 2>/dev/null || echo "0")"
        
        echo ""
        echo "📸 All image-related patterns found:"
        
        # Show all image patterns
        echo "   🔍 All src= patterns:"
        grep -oE 'src="[^"]*"' "$temp_file" | head -10 | while read -r src; do
            echo "      $src"
        done
        
        echo "   🔍 All data-src= patterns:"
        grep -oE 'data-src="[^"]*"' "$temp_file" | head -10 | while read -r src; do
            echo "      $src"
        done
        
        echo "   🔍 All Natura domain references:"
        grep -oE '[^"]*natura\.com[^"]*' "$temp_file" | head -10 | while read -r ref; do
            echo "      $ref"
        done
    fi
}

# Main function
main() {
    echo "🎯 This tool will help us find the real Natura image URLs"
    echo ""
    
    # Test specific URLs first
    if test_product_urls; then
        echo "✅ Found working image URLs!"
    else
        echo "❌ No working URLs found in direct tests"
        echo ""
        
        # Try search approach
        if search_for_images; then
            echo "✅ Found images in search results!"
        else
            echo "❌ No images found in search either"
            echo ""
            
            # Analyze a page to understand structure
            echo "🔬 Let's analyze the page structure..."
            analyze_page_structure "$NATURA_BASE_URL"
        fi
    fi
    
    echo ""
    echo "💡 Tips for improving scraping:"
    echo "   1. Look for the exact URL pattern: production.na01.natura.com"
    echo "   2. Check for lazy loading (data-src attributes)"
    echo "   3. Try different product URL patterns"
    echo "   4. Consider using browser developer tools to find the real URLs"
}

main "$@"
