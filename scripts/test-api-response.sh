#!/bin/bash

# Test API Response - Check if imageUrl is being returned

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing API Response for imageUrl field"
echo "📡 API URL: $API_URL"
echo ""

# Fetch first few products and check imageUrl
echo "🔍 Fetching products from API..."
response=$(curl -s "$API_URL/api/products?page=1&limit=3" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    echo "✅ API responded successfully"
    echo ""
    
    # Check if response has products
    if echo "$response" | jq -e '.data[0]' > /dev/null 2>&1; then
        echo "📦 Found products in response"
        echo ""
        
        # Show first product with imageUrl field highlighted
        echo "🔍 First product details:"
        echo "$response" | jq '.data[0] | {
            name: .name,
            category: .category,
            basePrice: .basePrice,
            imageUrl: .imageUrl,
            hasImageUrl: (.imageUrl != null and .imageUrl != "")
        }' 2>/dev/null
        
        echo ""
        echo "📊 ImageUrl status for all products:"
        echo "$response" | jq -r '.data[] | "\(.name): \(if .imageUrl and .imageUrl != "" then "✅ HAS IMAGE: " + .imageUrl else "❌ NO IMAGE" end)"' 2>/dev/null
        
    else
        echo "❌ No products found in response"
        echo "📄 Raw response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    fi
else
    echo "❌ Failed to fetch from API"
    echo "💡 Make sure backend is running at $API_URL"
fi

echo ""
echo "🎯 If you see '❌ NO IMAGE' above, the backend isn't sending imageUrl"
echo "💡 If you see '✅ HAS IMAGE', the problem might be in the frontend or CORS"
