#!/bin/bash

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"

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
    echo "📋 Fetching all products..."
    local all_products=()
    local page=1
    local has_more=true
    
    while [ "$has_more" = true ]; do
        response=$(curl -s "$API_URL/api/products?page=$page&limit=100" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "❌ Error fetching page $page"
            break
        fi
        
        # Extract products from response
        products=$(echo "$response" | jq -r '.data[]?.id // empty' 2>/dev/null)
        
        if [ -z "$products" ]; then
            has_more=false
        else
            # Count products in this page
            product_count=$(echo "$products" | wc -l)
            echo "📦 Fetched page $page: $product_count products"
            
            # Add to all products
            all_products+=($products)
            
            # Check if there are more pages
            total_pages=$(echo "$response" | jq -r '.meta.totalPages // 1' 2>/dev/null)
            if [ "$page" -ge "$total_pages" ]; then
                has_more=false
            fi
            
            ((page++))
        fi
    done
    
    echo "${all_products[@]}"
}

# Function to confirm deletion
confirm_deletion() {
    echo ""
    echo "⚠️  This will DELETE ALL PRODUCTS from your database."
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r answer
    
    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to delete products
delete_products() {
    local products=("$@")
    local total=${#products[@]}
    local success_count=0
    local error_count=0
    
    echo "🗑️  Starting to delete $total products..."
    echo ""
    
    for i in "${!products[@]}"; do
        local product_id="${products[$i]}"
        local current=$((i + 1))
        
        # Delete product
        response=$(curl -s -w "%{http_code}" -X DELETE \
            "$API_URL/api/products/$product_id" 2>/dev/null)
        
        http_code="${response: -3}"
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
        else
            ((error_count++))
            if [ $error_count -le 10 ]; then
                echo "❌ Error deleting product $product_id (HTTP $http_code)"
            fi
        fi
        
        # Progress indicator
        if [ $((success_count % 50)) -eq 0 ] || [ $current -eq $total ]; then
            echo "✅ Deleted $success_count/$total products..."
        fi
        
        # Small delay to be nice to the server
        sleep 0.02
    done
    
    echo ""
    echo "🎉 Cleanup completed!"
    echo "✅ Successfully deleted: $success_count products"
    echo "❌ Failed to delete: $error_count products"
    
    if [ $total -gt 0 ]; then
        success_rate=$(echo "scale=1; $success_count * 100 / $total" | bc -l 2>/dev/null || echo "N/A")
        echo "📊 Success rate: ${success_rate}%"
    fi
    
    if [ $error_count -gt 0 ]; then
        echo ""
        echo "💡 Some products may have failed to delete due to:"
        echo "   - Network timeouts"
        echo "   - Products being referenced by other entities"
        echo "   - Database constraints"
        echo "   - API rate limiting"
    fi
}

# Main execution
main() {
    # Check API connection
    if ! check_api; then
        exit 1
    fi
    
    # Get all products
    echo ""
    products=($(get_all_products))
    
    if [ ${#products[@]} -eq 0 ]; then
        echo "✨ No products found in database. Nothing to delete!"
        exit 0
    fi
    
    echo ""
    echo "📊 Found ${#products[@]} products in database"
    
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
