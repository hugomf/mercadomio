#!/bin/bash

# Database Cleanup Script
# Safely removes products, categories, carts, and other test data

API_URL="${API_URL:-http://localhost:8080}"

echo "🧹 Database Cleanup Script (API Only)"
echo "📡 API URL: $API_URL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to make API requests (silent)
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local url="$API_URL/$endpoint"

    if [ "$method" = "GET" ]; then
        curl -s -X GET "$url"
    elif [ "$method" = "DELETE" ] && [ -z "$data" ]; then
        curl -s -X DELETE "$url" >/dev/null 2>&1 && echo "deleted" || echo "error"
    elif [ "$method" = "DELETE" ] && [ -n "$data" ]; then
        curl -s -X DELETE "$url" -H "Content-Type: application/json" -d "$data" >/dev/null 2>&1 && echo "deleted" || echo "error"
    fi
}

# Get current product count
get_product_count() {
    local count=$(api_request "GET" "api/products?page=1&limit=1" | jq -r '.total // 0' 2>/dev/null)
    echo "${count:-0}"
}

# Get current category count
get_category_count() {
    local count=$(api_request "GET" "api/categories" | jq length 2>/dev/null)
    echo "${count:-0}"
}

# Clean using API endpoints (safer)
clean_via_api() {
    echo -e "\n🔄 ${BLUE}Cleaning via API endpoints${NC}"

    # Get list of products to delete
    echo "📋 Getting products to delete..."
    local products=$(api_request "GET" "api/products?page=1&limit=1000" | jq -r '(.data // [])[] | .id' 2>/dev/null)

    local product_count=0
    local product_errors=0

    if [ -n "$products" ]; then
        echo "🗑️  Deleting products..."
        for product_id in $products; do
            if [ "$product_id" != "null" ] && [ -n "$product_id" ]; then
                echo "   🛍️  Deleting product $product_id"
                result=$(api_request "DELETE" "api/products/$product_id")
                if [ "$result" = "deleted" ]; then
                    ((product_count++))
                else
                    ((product_errors++))
                    echo "      ❌ Failed to delete product $product_id"
                fi
            fi
        done
    fi

    # Get list of categories to delete
    echo "📋 Getting categories to delete..."
    local categories=$(api_request "GET" "api/categories" | jq -r '.[].id' 2>/dev/null)

    local category_count=0
    local category_errors=0

    if [ -n "$categories" ]; then
        echo "🗑️  Deleting categories..."
        for category_id in $categories; do
            if [ "$category_id" != "null" ] && [ -n "$category_id" ]; then
                echo "   📁 Deleting category $category_id"
                result=$(api_request "DELETE" "api/categories/$category_id")
                if [ "$result" = "deleted" ]; then
                    ((category_count++))
                else
                    ((category_errors++))
                    echo "      ❌ Failed to delete category $category_id"
                fi
            fi
        done
    fi

    echo -e "\n${GREEN}✅ API Cleanup Summary:${NC}"
    echo "🛍️  Products deleted: $product_count"
    if [ $product_errors -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Product deletion errors: $product_errors${NC}"
    fi
    echo "📁 Categories deleted: $category_count"
    if [ $category_errors -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Category deletion errors: $category_errors${NC}"
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=""

    if ! command -v curl &> /dev/null; then
        missing_deps="$missing_deps curl"
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps="$missing_deps jq"
    fi

    if [ -n "$missing_deps" ]; then
        echo -e "${RED}❌ Missing dependencies: $missing_deps${NC}"
        echo -e "${YELLOW}💡 Install with: brew install $missing_deps${NC}"
        return 1
    fi
    return 0
}

# Show current state
show_current_state() {
    echo -e "${BLUE}� Current Database State:${NC}"

    # Get current counts
    local product_count=$(get_product_count)
    local category_count=$(get_category_count)

    echo "🛍️  Products: $product_count"
    echo "📁 Categories: $category_count"

    if [ "$product_count" = "0" ] && [ "$category_count" = "0" ]; then
        echo -e "${GREEN}✅ Database is already clean!${NC}"
        exit 0
    fi

    echo ""
}

# Main menu
main() {
    if ! check_dependencies; then
        exit 1
    fi

    show_current_state

    echo -e "${RED}⚠️  This will permanently delete ALL products and categories via API endpoints${NC}"
    read -p "Are you sure you want to clean the database? Type 'yes' to confirm: " confirm

    if [ "$confirm" = "yes" ]; then
        clean_via_api
    else
        echo "❌ Cleanup cancelled"
        exit 0
    fi

    echo -e "\n${GREEN}🎉 Database cleanup completed!${NC}"
    echo -e "${YELLOW}💡 Tip: Run the scraping script to populate fresh data${NC}"
}

# If script is run directly (not sourced), show menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
