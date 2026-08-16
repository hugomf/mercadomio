#!/bin/bash

# Base API URL
API_URL="http://localhost:8080/api"

# Function to create a category
create_category() {
  local name="$1"
  local description="$2"
  local parent_id="$3"

  curl -X POST "$API_URL/categories" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"description\": \"$description\",
      \"parentId\": \"$parent_id\"
    }"
}

# Function to create a product
create_product() {
  local name="$1"
  local price="$2"
  local description="$3"
  local category_id="$4"

  curl -X POST "$API_URL/products" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"price\": $price,
      \"description\": \"$description\",
      \"categoryId\": \"$category_id\"
    }"
}

# Create root categories
echo "Creating root categories..."
electronics_id=$(create_category "Electronics" "Electronic devices" "" | jq -r '.id')
clothing_id=$(create_category "Clothing" "Apparel and accessories" "" | jq -r '.id')
home_id=$(create_category "Home & Garden" "Home improvement products" "" | jq -r '.id')

# Create subcategories
echo "Creating subcategories..."
laptops_id=$(create_category "Laptops" "Portable computers" "$electronics_id" | jq -r '.id')
phones_id=$(create_category "Phones" "Mobile devices" "$electronics_id" | jq -r '.id')
men_id=$(create_category "Men's Clothing" "Clothing for men" "$clothing_id" | jq -r '.id')
women_id=$(create_category "Women's Clothing" "Clothing for women" "$clothing_id" | jq -r '.id')

# Create products
echo "Creating sample products..."
create_product "MacBook Pro 16\" M2" 2499 "Apple laptop with M2 chip" "$laptops_id"
create_product "iPhone 15 Pro" 999 "Latest iPhone model" "$phones_id"
create_product "Men's T-Shirt" 29.99 "100% Cotton T-Shirt" "$men_id"
create_product "Women's Dress" 59.99 "Summer floral dress" "$women_id"
create_product "Garden Tools Set" 89.99 "Complete gardening tools" "$home_id"

echo "Seeding completed successfully!"