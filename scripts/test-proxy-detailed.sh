#!/bin/bash

# Test Image Proxy with Detailed Debugging

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing Image Proxy with Detailed Debugging"
echo "📡 API URL: $API_URL"
echo ""

# Test the specific URL that was failing
test_url="https://production.na01.natura.com/on/demandware.static/-/Sites-nat-mex-b2b2c-catalog/default/dw95644b8d/produtos/NATMEX-148158_1.jpg"

echo "🔗 Testing URL: $test_url"
echo ""

# URL encode the test URL
encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$test_url', safe=''))" 2>/dev/null)
if [ $? -ne 0 ]; then
    # Fallback if python3 is not available
    encoded_url=$(echo "$test_url" | sed 's/:/%3A/g; s/\//%2F/g; s/?/%3F/g; s/=/%3D/g; s/&/%26/g')
fi

echo "🔗 Encoded URL: $encoded_url"
echo ""

# Test the proxy endpoint
proxy_url="$API_URL/api/image-proxy?url=$encoded_url"
echo "🧪 Testing proxy endpoint..."
echo "📡 Proxy URL: $proxy_url"
echo ""

# Make the request and capture detailed response
echo "📡 Making request..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}\nTIME:%{time_total}\nSIZE:%{size_download}\n" \
    -o /tmp/proxy_test_image.jpg \
    "$proxy_url" 2>/dev/null)

# Parse response
http_code=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
time_total=$(echo "$response" | grep "TIME:" | cut -d: -f2)
size_download=$(echo "$response" | grep "SIZE:" | cut -d: -f2)

echo "📊 Response Details:"
echo "   HTTP Code: $http_code"
echo "   Time: ${time_total}s"
echo "   Size: ${size_download} bytes"
echo ""

case "$http_code" in
    200)
        echo "✅ SUCCESS! Proxy is working"
        
        # Check the downloaded file
        if [ -f "/tmp/proxy_test_image.jpg" ] && [ -s "/tmp/proxy_test_image.jpg" ]; then
            file_size=$(wc -c < "/tmp/proxy_test_image.jpg")
            file_type=$(file /tmp/proxy_test_image.jpg 2>/dev/null | cut -d: -f2)
            echo "📄 Downloaded file: $file_size bytes"
            echo "📄 File type: $file_type"
            
            # Test if it's a valid image
            if echo "$file_type" | grep -q -i "image\|jpeg\|png\|gif"; then
                echo "✅ Valid image file downloaded"
            else
                echo "⚠️  File might not be a valid image"
                echo "📄 First few bytes:"
                head -c 100 /tmp/proxy_test_image.jpg | hexdump -C | head -3
            fi
            
            # Clean up
            rm -f /tmp/proxy_test_image.jpg
        else
            echo "❌ No file downloaded or file is empty"
        fi
        ;;
    400)
        echo "❌ BAD REQUEST (400)"
        echo "📄 Response body:"
        cat /tmp/proxy_test_image.jpg 2>/dev/null || echo "No response body"
        ;;
    404)
        echo "❌ NOT FOUND (404) - Proxy endpoint doesn't exist"
        echo "💡 Make sure backend is running with latest code"
        ;;
    500)
        echo "❌ SERVER ERROR (500)"
        echo "📄 Response body:"
        cat /tmp/proxy_test_image.jpg 2>/dev/null || echo "No response body"
        echo "💡 Check backend logs for detailed error"
        ;;
    000)
        echo "❌ CONNECTION FAILED"
        echo "💡 Backend might not be running or not reachable"
        ;;
    *)
        echo "⚠️  UNEXPECTED RESPONSE: $http_code"
        echo "📄 Response body:"
        cat /tmp/proxy_test_image.jpg 2>/dev/null || echo "No response body"
        ;;
esac

# Clean up
rm -f /tmp/proxy_test_image.jpg

echo ""
echo "🎯 Next steps:"
if [ "$http_code" = "200" ]; then
    echo "   ✅ Proxy is working! Update Flutter to use proxy URLs"
    echo "   🔧 In Flutter, change back to: getProxiedImageUrl(product.imageUrl)"
else
    echo "   ❌ Proxy needs fixing. Check backend logs and restart if needed"
    echo "   🔧 Backend restart: cd backend && go run main.go"
fi

echo ""
echo "🧪 Manual test - try this URL in your browser:"
echo "$proxy_url"
