#!/bin/bash

# Fix Missing Images in Existing Products
# This script updates products that don't have imageUrl field

API_URL="${API_URL:-http://192.168.64.73:8080}"

echo "🖼️  Fix Missing Images in Products"
echo "📡 API URL: $API_URL"
echo ""

# Function to get category-specific image
get_category_image() {
    local category="$1"
    local product_id="$2"
    
    case "$category" in
        "Perfumería")
            echo "https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Maquillaje")
            echo "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado del Cabello")
            echo "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado Personal"|"Cuidado Corporal")
            echo "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado Facial")
            echo "https://images.unsplash.com/photo-1570194065650-d99fb4bedf0a?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Protección Solar")
            echo "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Hogar")
            echo "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        *)
            echo "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
    esac
}

# Check API connection
check_api() {
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API at $API_URL"
        echo "💡 Make sure your backend is running"
        return 1
    fi
    echo "✅ API connection successful"
    return 0
}

# Get all products and find those without images
find_products_without_images() {
    echo "🔍 Finding products without images..."
    
    local page=1
    local products_without_images=()
    
    while true; do
        local response=$(curl -s "$API_URL/api/products?page=$page&limit=50" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "❌ Failed to fetch products page $page"
            break
        fi
        
        # Check if we have data
        local products_data=$(echo "$response" | jq -r '.data[]?' 2>/dev/null)
        
        if [ -z "$products_data" ]; then
            echo "📄 No more products found (page $page)"
            break
        fi
        
        # Process each product
        echo "$response" | jq -r '.data[] | "\(.id)|\(.name)|\(.category // "Unknown")|\(.imageUrl // "")"' 2>/dev/null | while IFS='|' read -r id name category image_url; do
            if [ -z "$image_url" ] || [ "$image_url" = "null" ]; then
                echo "$id|$name|$category" >> /tmp/products_without_images.txt
            fi
        done
        
        # Check if there are more pages
        local total_pages=$(echo "$response" | jq -r '.meta.totalPages // 1' 2>/dev/null)
        if [ "$page" -ge "$total_pages" ]; then
            break
        fi
        
        ((page++))
    done
    
    if [ -f /tmp/products_without_images.txt ]; then
        local count=$(wc -l < /tmp/products_without_images.txt)
        echo "📊 Found $count products without images"
        return 0
    else
        echo "✅ All products already have images!"
        return 1
    fi
}

# Update products with images
update_products_with_images() {
    local success_count=0
    local error_count=0
    local product_counter=1
    
    echo "🖼️  Updating products with images..."
    echo ""
    
    while IFS='|' read -r product_id name category; do
        echo "📦 Updating product $product_counter: $name"
        
        # Generate image URL
        local image_url=$(get_category_image "$category" "$product_counter")
        
        # Create update payload
        local update_payload=$(cat <<EOF
{
    "imageUrl": "$image_url"
}
EOF
)
        
        # Update product
        local response=$(curl -s -w "%{http_code}" -X PUT \
            -H "Content-Type: application/json" \
            -d "$update_payload" \
            "$API_URL/api/products/$product_id" 2>/dev/null)
        
        local http_code="${response: -3}"
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
            echo "✅ Updated: $name"
            echo "🖼️  Image: $image_url"
        else
            ((error_count++))
            echo "❌ Failed to update: $name (HTTP $http_code)"
        fi
        
        ((product_counter++))
        sleep 0.2  # Small delay to be nice to the API
        
    done < /tmp/products_without_images.txt
    
    echo ""
    echo "🎉 Update completed!"
    echo "✅ Successfully updated: $success_count products"
    echo "❌ Failed to update: $error_count products"
    
    # Cleanup
    rm -f /tmp/products_without_images.txt
}

# Main function
main() {
    if ! check_api; then
        exit 1
    fi
    
    echo ""
    echo "🎯 This script will add high-quality images to products that don't have them"
    echo "   Uses category-specific images from Unsplash (400x400px)"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    if find_products_without_images; then
        update_products_with_images
    fi
}

main "$@"
