#!/bin/bash

# Test Backend ImageURL Support
# Quick test to verify the backend accepts imageUrl field

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🧪 Testing Backend ImageURL Support"
echo "📡 API URL: $API_URL"
echo ""

# Simple test product
test_simple_product() {
    echo "🔬 Testing simple product with imageUrl..."
    
    local json_payload='{
    "name": "TEST Product with Image",
    "description": "Test product to verify imageUrl field",
    "type": "physical",
    "category": "Test",
    "basePrice": 99.99,
    "sku": "TEST-001",
    "barcode": "1234567890",
    "imageUrl": "https://example.com/test.jpg"
}'

    echo "📤 Sending test product..."
    echo "$json_payload" | jq '.'
    echo ""
    
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    echo "📥 Response:"
    echo "   HTTP Code: $http_code"
    echo "   Body: $response_body"
    echo ""
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ SUCCESS: Backend accepts imageUrl field!"
        
        # Try to get the product ID and fetch it back
        local product_id=$(echo "$response_body" | jq -r '.id // .data.id // empty' 2>/dev/null)
        if [ -n "$product_id" ]; then
            echo "📦 Product ID: $product_id"
            echo "🔍 Fetching product back..."
            
            local get_response=$(curl -s "$API_URL/api/products/$product_id" 2>/dev/null)
            echo "📄 Retrieved product:"
            echo "$get_response" | jq '.' 2>/dev/null || echo "$get_response"
            
            # Clean up
            echo "🧹 Cleaning up..."
            curl -s -X DELETE "$API_URL/api/products/$product_id" > /dev/null
            echo "✅ Test product deleted"
        fi
        
        return 0
    else
        echo "❌ FAILED: Backend rejected the request"
        echo "💡 Possible issues:"
        echo "   - Backend not running"
        echo "   - ImageURL field not supported"
        echo "   - JSON validation error"
        echo "   - Database connection issue"
        return 1
    fi
}

# Test minimal product
test_minimal_product() {
    echo "🔬 Testing minimal product without imageUrl..."
    
    local json_payload='{
    "name": "TEST Minimal Product",
    "description": "Minimal test product",
    "type": "physical",
    "category": "Test",
    "basePrice": 50.00,
    "sku": "TEST-MIN-001",
    "barcode": "9876543210"
}'

    echo "📤 Sending minimal product..."
    
    local response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    echo "📥 Response: HTTP $http_code"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ Minimal product works"
        
        # Clean up
        local product_id=$(echo "$response_body" | jq -r '.id // .data.id // empty' 2>/dev/null)
        if [ -n "$product_id" ]; then
            curl -s -X DELETE "$API_URL/api/products/$product_id" > /dev/null
        fi
        return 0
    else
        echo "❌ Even minimal product failed: $response_body"
        return 1
    fi
}

# Check API connection
check_api() {
    echo "🔧 Checking API connection..."
    if curl -s --max-time 5 "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "✅ API is reachable"
        return 0
    else
        echo "❌ Cannot reach API"
        return 1
    fi
}

# Main function
main() {
    if ! check_api; then
        echo "💡 Make sure your backend is running:"
        echo "   cd backend && go run main.go"
        exit 1
    fi
    
    echo ""
    echo "🎯 Testing backend support for imageUrl field..."
    echo ""
    
    if test_minimal_product; then
        echo ""
        if test_simple_product; then
            echo ""
            echo "🎉 SUCCESS! Backend fully supports imageUrl field"
            echo "✅ You can now run the scraping scripts"
        else
            echo ""
            echo "⚠️  Backend works but has issues with imageUrl field"
            echo "💡 Check the backend logs for validation errors"
        fi
    else
        echo ""
        echo "❌ Backend has fundamental issues"
        echo "💡 Check if backend is running and database is connected"
    fi
}

main "$@"
