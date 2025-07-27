#!/bin/bash

# Test Unsplash Images

echo "🖼️ Testing Unsplash Placeholder Images"
echo ""

# Test a few key images
images=(
    "https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop&auto=format&q=80"
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop&auto=format&q=80"
    "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop&auto=format&q=80"
    "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop&auto=format&q=80"
)

categories=(
    "Perfumes"
    "Hair Care"
    "Makeup"
    "Personal Care"
)

success_count=0
total_count=${#images[@]}

echo "🧪 Testing ${total_count} Unsplash images..."
echo ""

for i in "${!images[@]}"; do
    url="${images[$i]}"
    category="${categories[$i]}"
    
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

if [ $success_count -eq $total_count ]; then
    echo ""
    echo "🎉 All Unsplash images are working!"
    echo "💡 Flutter should now show beautiful placeholder images"
    echo "🔧 Hot reload Flutter to see the changes"
else
    echo ""
    echo "⚠️  Some images failed - check internet connection"
fi

echo ""
echo "🎯 What this means:"
echo "   • Products will show category-specific placeholder images"
echo "   • No more broken image icons"
echo "   • Beautiful, professional-looking product images"
echo "   • Later we can fix the proxy for real Natura images"
