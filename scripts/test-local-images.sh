#!/bin/bash

# Test Local Image Download and Serving

API_URL="${API_URL:-http://192.168.64.73:8080}"
IMAGES_DIR="./frontend/assets/images/products"

echo "🧪 Testing Local Image Download and Serving"
echo "📡 API URL: $API_URL"
echo "📁 Images directory: $IMAGES_DIR"
echo ""

# Check if images directory exists
if [ -d "$IMAGES_DIR" ]; then
    image_count=$(find "$IMAGES_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" | wc -l)
    echo "📊 Found $image_count images in local directory"
    
    if [ "$image_count" -gt 0 ]; then
        echo "📸 Sample images:"
        find "$IMAGES_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" | head -5 | while read -r img; do
            filename=$(basename "$img")
            size=$(wc -c < "$img")
            echo "   $filename ($size bytes)"
        done
        echo ""
        
        # Test serving through backend
        echo "🧪 Testing image serving through backend..."
        sample_image=$(find "$IMAGES_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" | head -1)
        
        if [ -n "$sample_image" ]; then
            filename=$(basename "$sample_image")
            test_url="$API_URL/assets/images/products/$filename"
            
            echo "🔗 Testing URL: $test_url"
            
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$test_url" 2>/dev/null)
            
            case "$http_code" in
                200)
                    echo "   ✅ SUCCESS (HTTP $http_code) - Backend is serving images correctly"
                    ;;
                404)
                    echo "   ❌ NOT FOUND (HTTP $http_code) - Backend static serving not working"
                    echo "   💡 Make sure backend is restarted with static file serving"
                    ;;
                000)
                    echo "   ❌ CONNECTION FAILED - Backend not reachable"
                    ;;
                *)
                    echo "   ⚠️  UNEXPECTED (HTTP $http_code)"
                    ;;
            esac
        fi
    else
        echo "❌ No images found in directory"
        echo "💡 Run the scraper first: ./scripts/scrape-natura-api.sh"
    fi
else
    echo "❌ Images directory doesn't exist"
    echo "💡 Run the scraper first: ./scripts/scrape-natura-api.sh"
fi

echo ""
echo "🎯 Next steps:"
echo "   1. If no images: Run ./scripts/scrape-natura-api.sh"
echo "   2. If images exist but serving fails: Restart backend"
echo "   3. If serving works: Images should appear in Flutter app"
echo ""
echo "🔧 Backend restart command:"
echo "   cd backend && go run main.go"
