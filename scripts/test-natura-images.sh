#!/bin/bash

# Test Natura Images - Check if image URLs are accessible

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🖼️ Testing Natura Image URLs Accessibility"
echo "📡 API URL: $API_URL"
echo ""

# Get some products with images
echo "🔍 Fetching products with images..."
response=$(curl -s "$API_URL/api/products?page=1&limit=5" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    echo "✅ Got products from API"
    echo ""
    
    # Extract image URLs
    image_urls=$(echo "$response" | jq -r '.data[] | select(.imageUrl != null and .imageUrl != "") | .imageUrl' 2>/dev/null)
    
    if [ -n "$image_urls" ]; then
        echo "🖼️ Testing image URLs accessibility..."
        echo ""
        
        count=1
        echo "$image_urls" | while read -r url; do
            if [ -n "$url" ]; then
                echo "🧪 Testing image $count: $url"
                
                # Test with curl
                http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
                    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                    -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
                    -H "Referer: https://www.natura.com.mx/" \
                    "$url" 2>/dev/null)
                
                case "$http_code" in
                    200)
                        echo "   ✅ SUCCESS (HTTP $http_code) - Image is accessible"
                        
                        # Get image info
                        content_type=$(curl -s -I --max-time 5 \
                            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                            -H "Referer: https://www.natura.com.mx/" \
                            "$url" 2>/dev/null | grep -i "content-type" | cut -d: -f2 | tr -d ' \r\n')
                        
                        content_length=$(curl -s -I --max-time 5 \
                            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                            -H "Referer: https://www.natura.com.mx/" \
                            "$url" 2>/dev/null | grep -i "content-length" | cut -d: -f2 | tr -d ' \r\n')
                        
                        echo "   📄 Content-Type: $content_type"
                        echo "   📏 Content-Length: $content_length bytes"
                        ;;
                    403)
                        echo "   ❌ FORBIDDEN (HTTP $http_code) - Access denied"
                        echo "   💡 This might be a CORS or referrer policy issue"
                        ;;
                    404)
                        echo "   ❌ NOT FOUND (HTTP $http_code) - Image doesn't exist"
                        ;;
                    000)
                        echo "   ❌ CONNECTION FAILED - Network or timeout issue"
                        ;;
                    *)
                        echo "   ⚠️  UNEXPECTED (HTTP $http_code) - Unknown response"
                        ;;
                esac
                
                echo ""
                ((count++))
                
                # Limit to 3 tests
                if [ $count -gt 3 ]; then
                    break
                fi
                
                sleep 1
            fi
        done
        
        echo ""
        echo "🎯 Summary:"
        echo "   • If you see ✅ SUCCESS: Images are accessible from server"
        echo "   • If you see ❌ FORBIDDEN: CORS or referrer policy blocking"
        echo "   • If you see ❌ NOT FOUND: Image URLs are broken"
        echo "   • If you see ❌ CONNECTION FAILED: Network issues"
        
        echo ""
        echo "💡 Troubleshooting:"
        echo "   1. Check Flutter app console for image load errors"
        echo "   2. Try opening image URLs directly in browser"
        echo "   3. Check if CORS headers are needed"
        echo "   4. Consider using a proxy or different image source"
        
    else
        echo "❌ No image URLs found in products"
    fi
else
    echo "❌ Failed to fetch products from API"
fi
