#!/bin/bash

# Test Image Field in API
# This script tests if the backend properly saves the imageUrl field

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing imageUrl field in API"
echo "📡 API URL: $API_URL"
echo ""

# Test product with imageUrl
test_product_with_image() {
    echo "🔬 Testing product creation with imageUrl field..."
    
    local test_image_url="https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=999"
    
    local json_payload=$(cat <<EOF
{
    "name": "TEST - Natura Product with Image",
    "description": "Test product to verify imageUrl field is saved correctly",
    "type": "physical",
    "category": "Test",
    "basePrice": 99.99,
    "sku": "TEST-IMG-001",
    "barcode": "1234567890123",
    "imageUrl": "$test_image_url",
    "variants": [],
    "customAttributes": {
        "brand": "Natura",
        "test": true
    },
    "identifiers": {
        "upc": "1234567890123",
        "model": "TEST-001"
    }
}
EOF
)

    echo "📤 Sending test product to API..."
    echo "🖼️  Image URL: $test_image_url"
    echo ""
    
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ Product created successfully (HTTP $http_code)"
        
        # Extract product ID from response
        local product_id=$(echo "$response_body" | jq -r '.id // .data.id // empty' 2>/dev/null)
        
        if [ -n "$product_id" ]; then
            echo "📦 Product ID: $product_id"
            echo ""
            
            # Fetch the product back to verify imageUrl was saved
            echo "🔍 Fetching product back to verify imageUrl field..."
            local get_response=$(curl -s "$API_URL/api/products/$product_id" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo "📄 Product data retrieved:"
                echo "$get_response" | jq '.' 2>/dev/null || echo "$get_response"
                echo ""
                
                # Check if imageUrl field exists
                local saved_image_url=$(echo "$get_response" | jq -r '.imageUrl // .data.imageUrl // empty' 2>/dev/null)
                
                if [ -n "$saved_image_url" ] && [ "$saved_image_url" != "null" ]; then
                    echo "✅ SUCCESS: imageUrl field was saved correctly!"
                    echo "🖼️  Saved imageUrl: $saved_image_url"
                    
                    if [ "$saved_image_url" = "$test_image_url" ]; then
                        echo "✅ Image URL matches exactly what we sent"
                    else
                        echo "⚠️  Image URL was modified by the backend"
                    fi
                else
                    echo "❌ PROBLEM: imageUrl field is missing or null in the saved product"
                    echo "💡 This explains why your products don't have images"
                fi
            else
                echo "❌ Failed to fetch product back"
            fi
            
            # Clean up - delete test product
            echo ""
            echo "🧹 Cleaning up test product..."
            curl -s -X DELETE "$API_URL/api/products/$product_id" > /dev/null
            echo "✅ Test product deleted"
            
        else
            echo "⚠️  Could not extract product ID from response"
            echo "📄 Response: $response_body"
        fi
    else
        echo "❌ Failed to create product (HTTP $http_code)"
        echo "📄 Response: $response_body"
    fi
}

# Check API connection
check_api() {
    echo "🔧 Checking API connection..."
    if curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "✅ API connection successful"
        return 0
    else
        echo "❌ Cannot connect to API"
        return 1
    fi
}

# Main function
main() {
    if ! check_api; then
        exit 1
    fi
    
    echo ""
    echo "🎯 This test will help us understand why imageUrl is not being saved"
    echo ""
    
    test_product_with_image
    
    echo ""
    echo "🎉 Test completed!"
    echo ""
    echo "💡 If the imageUrl field was missing, the issue is in the backend."
    echo "   Check if the backend Product model includes the imageUrl field."
    echo "   The field might need to be added to the Go struct or database schema."
}

main "$@"
