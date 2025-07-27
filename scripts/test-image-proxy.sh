#!/bin/bash

# Test Image Proxy Endpoint

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing Image Proxy Endpoint"
echo "📡 API URL: $API_URL"
echo ""

# Get a sample image URL from products
echo "🔍 Getting sample image URL from products..."
response=$(curl -s "$API_URL/api/products?page=1&limit=1" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    image_url=$(echo "$response" | jq -r '.data[0].imageUrl // ""' 2>/dev/null)
    
    if [ -n "$image_url" ] && [ "$image_url" != "null" ] && [ "$image_url" != "" ]; then
        echo "✅ Found sample image URL: $image_url"
        echo ""
        
        # Test the proxy endpoint
        echo "🧪 Testing proxy endpoint..."
        encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$image_url', safe=''))" 2>/dev/null || echo "$image_url")
        proxy_url="$API_URL/api/image-proxy?url=$encoded_url"
        
        echo "🔗 Proxy URL: $proxy_url"
        echo ""
        
        # Test with curl
        echo "📡 Making request to proxy..."
        http_code=$(curl -s -o /tmp/test_image.jpg -w "%{http_code}" --max-time 10 "$proxy_url" 2>/dev/null)
        
        echo "📊 Response: HTTP $http_code"
        
        case "$http_code" in
            200)
                echo "✅ SUCCESS! Proxy is working"
                
                # Check if file was created and has content
                if [ -f "/tmp/test_image.jpg" ] && [ -s "/tmp/test_image.jpg" ]; then
                    file_size=$(wc -c < "/tmp/test_image.jpg")
                    file_type=$(file /tmp/test_image.jpg 2>/dev/null | cut -d: -f2)
                    echo "📄 Downloaded file: $file_size bytes"
                    echo "📄 File type: $file_type"
                    
                    # Clean up
                    rm -f /tmp/test_image.jpg
                    
                    echo ""
                    echo "🎉 Image proxy is working correctly!"
                    echo "💡 The issue might be in Flutter's Image.network widget"
                else
                    echo "❌ File was not created or is empty"
                fi
                ;;
            400)
                echo "❌ BAD REQUEST - Check URL encoding"
                ;;
            404)
                echo "❌ NOT FOUND - Proxy endpoint doesn't exist"
                echo "💡 Make sure backend is running with the latest code"
                ;;
            500)
                echo "❌ SERVER ERROR - Check backend logs"
                ;;
            000)
                echo "❌ CONNECTION FAILED - Backend not reachable"
                ;;
            *)
                echo "⚠️  UNEXPECTED RESPONSE: $http_code"
                ;;
        esac
        
    else
        echo "❌ No image URL found in products"
    fi
else
    echo "❌ Failed to get products from API"
fi

echo ""
echo "🎯 Next steps:"
echo "   1. If proxy works: Check Flutter console for Image.network errors"
echo "   2. If proxy fails: Check backend logs and restart backend"
echo "   3. Try opening proxy URL directly in browser"
