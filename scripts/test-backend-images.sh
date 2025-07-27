#!/bin/bash

# Test Backend Image Serving

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing Backend Image Serving"
echo "📡 API URL: $API_URL"
echo ""

# Test a specific image that we know exists
test_image="NATMEX-147421_3.jpg"
test_url="$API_URL/assets/images/products/$test_image"

echo "🔗 Testing URL: $test_url"
echo ""

# Test with curl
echo "📡 Making request..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}\nSIZE:%{size_download}\nTIME:%{time_total}\n" \
    -o /tmp/test_backend_image.jpg \
    "$test_url" 2>/dev/null)

# Parse response
http_code=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
size_download=$(echo "$response" | grep "SIZE:" | cut -d: -f2)
time_total=$(echo "$response" | grep "TIME:" | cut -d: -f2)

echo "📊 Response:"
echo "   HTTP Code: $http_code"
echo "   Size: $size_download bytes"
echo "   Time: ${time_total}s"
echo ""

case "$http_code" in
    200)
        echo "✅ SUCCESS! Backend is serving images correctly"
        
        if [ -f "/tmp/test_backend_image.jpg" ] && [ -s "/tmp/test_backend_image.jpg" ]; then
            file_size=$(wc -c < "/tmp/test_backend_image.jpg")
            file_type=$(file /tmp/test_backend_image.jpg 2>/dev/null | cut -d: -f2)
            echo "📄 Downloaded: $file_size bytes"
            echo "📄 File type: $file_type"
            
            if echo "$file_type" | grep -q -i "image\|jpeg"; then
                echo "✅ Valid image file"
            else
                echo "⚠️  File might not be a valid image"
            fi
            
            rm -f /tmp/test_backend_image.jpg
        fi
        
        echo ""
        echo "🎉 Images should now work in Flutter!"
        echo "🔧 Hot reload Flutter to see the changes"
        ;;
    404)
        echo "❌ NOT FOUND - Backend can't find the image file"
        echo "💡 Possible issues:"
        echo "   1. Backend not restarted with new static serving config"
        echo "   2. Image file doesn't exist in the expected location"
        echo "   3. Path configuration is wrong"
        echo ""
        echo "🔧 Solutions:"
        echo "   1. Restart backend: cd backend && go run main.go"
        echo "   2. Check if image exists: ls ../frontend/assets/images/products/$test_image"
        ;;
    000)
        echo "❌ CONNECTION FAILED - Backend not reachable"
        echo "💡 Make sure backend is running"
        ;;
    *)
        echo "⚠️  UNEXPECTED RESPONSE: $http_code"
        ;;
esac

echo ""
echo "🎯 If images still don't work in Flutter after backend restart:"
echo "   1. Check Flutter console for specific error messages"
echo "   2. Try opening the image URL directly in browser"
echo "   3. Verify the imageUrl field in API response"
