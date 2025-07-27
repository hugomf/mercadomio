#!/bin/bash

# Test Placeholder Images from Unsplash

echo "🖼️ Testing Placeholder Images (Unsplash)"
echo ""

# Placeholder images we're using
declare -A images=(
    ["Perfumería"]="https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop&auto=format&q=80"
    ["Cuidado del Cabello"]="https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop&auto=format&q=80"
    ["Maquillaje"]="https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop&auto=format&q=80"
    ["Cuidado Personal"]="https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop&auto=format&q=80"
    ["Cuidado Facial"]="https://images.unsplash.com/photo-1570194065650-d99fb4bedf0a?w=400&h=400&fit=crop&auto=format&q=80"
    ["Protección Solar"]="https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop&auto=format&q=80"
    ["Hogar"]="https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400&h=400&fit=crop&auto=format&q=80"
    ["Default"]="https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&h=400&fit=crop&auto=format&q=80"
)

success_count=0
total_count=${#images[@]}

echo "🧪 Testing ${total_count} placeholder images..."
echo ""

for category in "${!images[@]}"; do
    url="${images[$category]}"
    echo "🔍 Testing: $category"
    echo "🔗 URL: $url"
    
    # Test with curl
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$url" 2>/dev/null)
    
    case "$http_code" in
        200)
            echo "   ✅ SUCCESS (HTTP $http_code)"
            ((success_count++))
            ;;
        *)
            echo "   ❌ FAILED (HTTP $http_code)"
            ;;
    esac
    
    echo ""
done

echo "📊 Results:"
echo "   ✅ Working: $success_count/$total_count"
echo "   📊 Success rate: $(echo "scale=1; $success_count * 100 / $total_count" | bc -l 2>/dev/null || echo "N/A")%"

if [ $success_count -eq $total_count ]; then
    echo ""
    echo "🎉 All placeholder images are working!"
    echo "💡 Flutter should now show category-specific images"
    echo "🔧 Hot reload Flutter to see the changes"
else
    echo ""
    echo "⚠️  Some placeholder images failed"
    echo "💡 Check internet connection or try different image sources"
fi

echo ""
echo "🎯 Next steps:"
echo "   1. Hot reload Flutter app"
echo "   2. Check that products now show category-specific images"
echo "   3. All Natura products should have appropriate placeholder images"
echo "   4. Later: Fix proxy to use real Natura images"
