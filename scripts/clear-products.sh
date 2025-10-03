#!/bin/bash

# Configuration
API_URL="${API_URL:-http://localhost:8080}"

echo "🧹 Product Cleanup Tool"
echo "📡 API URL: $API_URL"
echo ""

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "❌ Error: 'jq' is required but not installed."
    echo "💡 Install jq:"
    echo "   - macOS: brew install jq"
    echo "   - Ubuntu/Debian: sudo apt-get install jq"
    echo "   - CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Function to check API connection
check_api() {
    echo "🔍 Checking API connection..."
    response=$(curl -s -w "%{http_code}" "$API_URL/api/products?page=1&limit=1" 2>/dev/null)
    http_code="${response: -3}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ API connection successful"
        return 0
    else
        echo "❌ Cannot connect to API (HTTP $http_code)"
        echo "💡 Make sure your backend is running and accessible"
        return 1
    fi
}

# Function to get all product IDs
get_all_products() {
    >&2 echo "📋 Fetching all products..."
    local all_products=()
    local page=1

    # Get the total count first
    response=$(curl -s "$API_URL/api/products?page=1&limit=1" 2>/dev/null)

    if ! echo "$response" | jq -e . > /dev/null 2>&1; then
        >&2 echo "❌ Invalid JSON response"
        >&2 echo "Raw response: $response"
        return 1
    fi

    total=$(echo "$response" | jq -r '.total // 0')

    if [ "$total" -eq 0 ]; then
        # Output nothing to stdout
        return 0
    fi

    >&2 echo "📊 Found $total total products"

    # Calculate pages needed
    local pages_needed=$(( (total + 99) / 100 ))

    for page in $(seq 1 $pages_needed); do
        response=$(curl -s "$API_URL/api/products?page=$page&limit=100" 2>/dev/null)

        if [ $? -ne 0 ]; then
            >&2 echo "❌ Error fetching page $page"
            continue
        fi

        # Extract product IDs from data array
        products=$(echo "$response" | jq -r '.data[]?._id // .data[]?.id // empty' 2>/dev/null)

        if [ -n "$products" ]; then
            while IFS= read -r product_id; do
                if [ -n "$product_id" ]; then
                    all_products+=("$product_id")
                fi
            done <<< "$products"
            >&2 echo "📦 Fetched page $page: $(echo "$products" | wc -l) products"
        fi
    done

    # Output only the product IDs to stdout
    printf '%s\n' "${all_products[@]}"
}

# Function to confirm deletion
confirm_deletion() {
    echo ""
    echo "⚠️  This will DELETE ALL PRODUCTS from your database."
    read -p "re you sure you want to continue? (y/N):" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

}

# Function to delete products
delete_products() {
    local products=("$@")
    local total=${#products[@]}
    local success_count=0
    local error_count=0
    
    if [ $total -eq 0 ]; then
        echo "✨ No products to delete"
        return 0
    fi
    
    echo "🗑️  Starting to delete $total products..."
    echo ""
    
    for i in "${!products[@]}"; do
        product_id="${products[$i]}"
        current=$((i + 1))
        
        # Validate product ID format
        if [[ ! "$product_id" =~ ^[a-fA-F0-9]{24}$ ]] && [[ ! "$product_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "⚠️  Skipping invalid ID: $product_id"
            continue
        fi
        
        # Delete product
        response=$(curl -s -w "%{http_code}" -X DELETE \
            "$API_URL/api/products/$product_id" 2>/dev/null)
        
        http_code="${response: -3}"
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
            echo "✅ Deleted: $product_id ($success_count/$total)"
        else
            ((error_count++))
            echo "❌ Failed: $product_id (HTTP $http_code)"
        fi
        
        sleep 0.1  # Small delay
    done
    
    echo ""
    echo "🎉 Cleanup completed!"
    echo "✅ Successfully deleted: $success_count products"
    
    if [ $total -gt 0 ]; then
        success_rate=$(echo "scale=1; $success_count * 100 / $total" | bc -l 2>/dev/null || echo "N/A")
        echo "📊 Success rate: ${success_rate}%"
    fi
}

# Main execution
main() {
    # Check API connection
    if ! check_api; then
        exit 1
    fi

    
    # Convert to array safely
    IFS=$'\n' read -rd '' -a products < <(get_all_products && printf '\0')
    products=($(printf "%s\n" "${products[@]}" | grep -v '^$'))
    
    if [ ${#products[@]} -eq 0 ]; then
        echo "✨ No products found in database. Nothing to delete!"
        exit 0
    fi
    
    echo ""
    echo "📊 Found ${#products[@]} products in database"
    
    # Show first few IDs for verification
    if [ ${#products[@]} -gt 0 ]; then
        echo "🔍 Sample product IDs:"
        printf '%s\n' "${products[@]:0:3}" | sed 's/^/   /'
    fi
    
    # Confirm deletion
    if ! confirm_deletion; then
        echo "❌ Deletion cancelled by user"
        exit 0
    fi
    
    echo ""
    echo "🚀 Starting deletion process..."
    
    # Delete all products
    delete_products "${products[@]}"
}

# Check for required tools
if ! command -v bc &> /dev/null; then
    echo "⚠️  Warning: 'bc' not found. Success rate calculation will be disabled."
fi

# Run main function
main
