#!/bin/bash

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
TOTAL_PRODUCTS=5000

echo "🚀 Starting to generate $TOTAL_PRODUCTS products..."
echo "📡 API URL: $API_URL"
echo ""

# Arrays of realistic product data
categories=("Electronics" "Clothing" "Home & Garden" "Sports & Outdoors" "Books" "Health & Beauty" "Toys & Games" "Automotive" "Food & Beverages" "Office Supplies")
brands=("Apple" "Samsung" "Nike" "Adidas" "Sony" "LG" "Dell" "HP" "Canon" "Microsoft" "Google" "Amazon" "Generic" "Premium" "Pro" "Elite")
adjectives=("Premium" "Professional" "Deluxe" "Ultra" "Super" "Advanced" "Smart" "Eco-Friendly" "Wireless" "Portable" "Compact" "Durable")

# Product names by category
electronics=("Smartphone" "Laptop" "Tablet" "Headphones" "Smart Watch" "Camera" "Speaker" "Monitor" "Keyboard" "Mouse")
clothing=("T-Shirt" "Jeans" "Dress" "Jacket" "Sweater" "Shoes" "Sneakers" "Boots" "Hat" "Scarf")
home_garden=("Sofa" "Chair" "Table" "Lamp" "Curtains" "Rug" "Pillow" "Plant Pot" "Garden Tools" "Watering Can")
sports=("Running Shoes" "Yoga Mat" "Dumbbell" "Bicycle" "Helmet" "Backpack" "Tent" "Water Bottle" "Basketball" "Tennis Racket")
books=("Fiction Novel" "Cookbook" "Biography" "Self-Help Book" "Children's Book" "Textbook" "Travel Guide" "History Book")
health=("Shampoo" "Face Cream" "Toothbrush" "Perfume" "Makeup" "Hair Dryer" "Moisturizer" "Vitamins" "Soap" "Deodorant")

colors=("Black" "White" "Blue" "Red" "Green" "Gray" "Silver" "Brown" "Pink" "Purple")

# Function to get random element from array
get_random() {
    local arr=("$@")
    echo "${arr[$RANDOM % ${#arr[@]}]}"
}

# Function to generate random price based on category
get_price() {
    local category="$1"
    case "$category" in
        "Electronics") echo "$((RANDOM % 2000 + 50)).$((RANDOM % 100))" ;;
        "Clothing") echo "$((RANDOM % 200 + 10)).$((RANDOM % 100))" ;;
        "Home & Garden") echo "$((RANDOM % 1000 + 20)).$((RANDOM % 100))" ;;
        "Books") echo "$((RANDOM % 50 + 5)).$((RANDOM % 100))" ;;
        "Health & Beauty") echo "$((RANDOM % 100 + 5)).$((RANDOM % 100))" ;;
        *) echo "$((RANDOM % 500 + 10)).$((RANDOM % 100))" ;;
    esac
}

# Function to get product names for category
get_product_names() {
    local category="$1"
    case "$category" in
        "Electronics") echo "${electronics[@]}" ;;
        "Clothing") echo "${clothing[@]}" ;;
        "Home & Garden") echo "${home_garden[@]}" ;;
        "Sports & Outdoors") echo "${sports[@]}" ;;
        "Books") echo "${books[@]}" ;;
        "Health & Beauty") echo "${health[@]}" ;;
        *) echo "Product Item Generic Thing Tool Supply" ;;
    esac
}

success_count=0
error_count=0

# Generate products
for i in $(seq 1 $TOTAL_PRODUCTS); do
    # Select random data
    category=$(get_random "${categories[@]}")
    brand=$(get_random "${brands[@]}")
    adjective=$(get_random "${adjectives[@]}")
    color=$(get_random "${colors[@]}")
    
    # Get product names for this category
    product_names=($(get_product_names "$category"))
    base_product=$(get_random "${product_names[@]}")
    
    # Generate product name
    if [ $((RANDOM % 2)) -eq 0 ]; then
        name="$brand $adjective $base_product"
    else
        name="$adjective $base_product"
    fi
    
    # Generate other fields
    price=$(get_price "$category")
    sku="${category:0:3}-$(printf "%06d" $i)"
    barcode="$((RANDOM % 900000000 + 100000000))$(printf "%04d" $i)"
    model="$brand-$((RANDOM % 9000 + 1000))"
    weight="$((RANDOM % 100 + 1)).$((RANDOM % 10)) lbs"
    
    # Create JSON payload
    json_payload=$(cat <<EOF
{
    "name": "$name",
    "description": "High-quality $base_product perfect for everyday use. Durable and reliable design.",
    "type": "physical",
    "category": "$category",
    "basePrice": $price,
    "sku": "$sku",
    "barcode": "$barcode",
    "variants": [],
    "customAttributes": {
        "brand": "$brand",
        "color": "$color",
        "weight": "$weight"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "$model"
    }
}
EOF
)

    # Send request
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL/api/products" 2>/dev/null)
    
    http_code="${response: -3}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        ((success_count++))
        if [ $((success_count % 100)) -eq 0 ]; then
            echo "✅ Successfully created $success_count products"
        fi
    else
        ((error_count++))
        if [ $error_count -le 10 ]; then
            echo "❌ Error creating product $i (HTTP $http_code)"
        fi
    fi
    
    # Progress indicator
    if [ $((i % 250)) -eq 0 ]; then
        echo "📦 Progress: $i/$TOTAL_PRODUCTS products processed"
    fi
    
    # Small delay to be nice to the server
    sleep 0.01
done

echo ""
echo "🎉 Product generation completed!"
echo "✅ Successfully created: $success_count products"
echo "❌ Failed to create: $error_count products"
echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / $TOTAL_PRODUCTS" | bc -l)%"
