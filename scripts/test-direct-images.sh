#!/bin/bash

# Test Direct Image Loading (without proxy)

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🖼️ Testing Direct Image Loading (No Proxy)"
echo "📡 API URL: $API_URL"
echo ""

# Get sample image URLs
echo "🔍 Getting sample image URLs..."
response=$(curl -s "$API_URL/api/products?page=1&limit=3" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    echo "✅ Got products from API"
    echo ""
    
    # Extract image URLs and test them
    echo "$response" | jq -r '.data[] | select(.imageUrl != null and .imageUrl != "") | "\(.name)|\(.imageUrl)"' 2>/dev/null | while IFS='|' read -r name url; do
        if [ -n "$url" ]; then
            echo "🧪 Testing: $name"
            echo "🔗 URL: $url"
            
            # Test with different approaches
            echo "   📡 Testing with curl (server-side)..."
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
                -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
                "$url" 2>/dev/null)
            
            case "$http_code" in
                200)
                    echo "   ✅ Server can access image (HTTP $http_code)"
                    ;;
                403)
                    echo "   ❌ Server forbidden (HTTP $http_code) - CORS issue"
                    ;;
                *)
                    echo "   ⚠️  Server response: HTTP $http_code"
                    ;;
            esac
            
            # Test with different headers
            echo "   📡 Testing with Natura referer..."
            http_code2=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
                -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
                -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
                -H "Referer: https://www.natura.com.mx/" \
                "$url" 2>/dev/null)
            
            case "$http_code2" in
                200)
                    echo "   ✅ With referer works (HTTP $http_code2)"
                    ;;
                403)
                    echo "   ❌ With referer forbidden (HTTP $http_code2)"
                    ;;
                *)
                    echo "   ⚠️  With referer: HTTP $http_code2"
                    ;;
            esac
            
            echo ""
        fi
    done
    
    echo "🎯 Analysis:"
    echo "   • If you see ✅ Server can access: Images work server-side"
    echo "   • If you see ❌ Server forbidden: Natura blocks external access"
    echo "   • If referer helps: Natura checks referrer header"
    echo ""
    echo "💡 Solutions:"
    echo "   1. If server access works: Use image proxy (restart backend)"
    echo "   2. If server forbidden: Images might be protected"
    echo "   3. If referer helps: Proxy needs proper headers"
    echo "   4. Try opening URLs directly in browser"
    
else
    echo "❌ Failed to get products from API"
fi

echo ""
echo "🔧 Quick test - try opening this URL in your browser:"
echo "https://production.na01.natura.com/on/demandware.static/-/Sites-nat-mex-b2b2c-catalog/default/dw73b222e2/174032_1.jpg"
