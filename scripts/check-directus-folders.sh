#!/bin/bash

# Script to check Directus folders and their details
# This script helps verify folder IDs and permissions

DIRECTUS_URL="${DIRECTUS_URL:-http://192.168.1.216:8055}"
DIRECTUS_EMAIL="${DIRECTUS_EMAIL:-admin@mercadomio.mx}"
DIRECTUS_PASSWORD="${DIRECTUS_PASSWORD:-admin123}"
DIRECTUS_TOKEN=""

# Function to authenticate with Directus
authenticate_directus() {
    echo "🔐 Authenticating with Directus..."
    
    local auth_response=$(curl -s -X POST \
        "$DIRECTUS_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$DIRECTUS_EMAIL\",
            \"password\": \"$DIRECTUS_PASSWORD\"
        }" 2>/dev/null)
    
    DIRECTUS_TOKEN=$(echo "$auth_response" | jq -r '.data.access_token // empty')
    
    if [ -z "$DIRECTUS_TOKEN" ]; then
        echo "❌ Failed to authenticate with Directus"
        echo "📄 Response: $auth_response"
        return 1
    fi
    
    echo "✅ Directus authentication successful"
    return 0
}

# Function to get all folders
get_all_folders() {
    echo ""
    echo "📁 Getting all folders..."
    echo "------------------------"
    
    local response=$(curl -s -X GET \
        "$DIRECTUS_URL/folders" \
        -H "Authorization: Bearer $DIRECTUS_TOKEN" 2>/dev/null)
    
    echo "Response:"
    echo "$response" | jq '.'
    
    # Extract just the folder details for easier reading
    echo ""
    echo "📋 Folder Summary:"
    echo "$response" | jq -r '.data[] | "ID: \(.id) | Name: \(.name) | Parent: \(.parent // "None")"'
}

# Function to get specific folder by ID
get_folder_by_id() {
    local folder_id="$1"
    echo ""
    echo "🔍 Getting folder by ID: $folder_id"
    echo "----------------------------------"
    
    local response=$(curl -s -X GET \
        "$DIRECTUS_URL/folders/$folder_id" \
        -H "Authorization: Bearer $DIRECTUS_TOKEN" 2>/dev/null)
    
    echo "Response:"
    echo "$response" | jq '.'
}

# Function to get folders with basic details
get_folder_list() {
    echo ""
    echo "📝 Getting folder list (ID and Name only)..."
    echo "-------------------------------------------"
    
    local response=$(curl -s -X GET \
        "$DIRECTUS_URL/folders?fields=id,name,parent" \
        -H "Authorization: Bearer $DIRECTUS_TOKEN" 2>/dev/null)
    
    echo "Response:"
    echo "$response" | jq '.'
}

# Function to search for folders by name
search_folders() {
    local search_term="$1"
    echo ""
    echo "🔎 Searching folders containing: $search_term"
    echo "-------------------------------------------"
    
    local response=$(curl -s -X GET \
        "$DIRECTUS_URL/folders?search=$search_term&fields=id,name" \
        -H "Authorization: Bearer $DIRECTUS_TOKEN" 2>/dev/null)
    
    echo "Response:"
    echo "$response" | jq '.'
}

# Check dependencies
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ Missing dependency: $cmd"
            echo "💡 Install with: brew install $cmd"
            return 1
        fi
    done
    return 0
}

# Main function
main() {
    echo "🔍 Directus Folder Checker"
    echo "========================="
    echo "DIRECTUS_URL: $DIRECTUS_URL"
    echo ""
    
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! authenticate_directus; then
        exit 1
    fi
    
    # Menu
    echo ""
    echo "Select an option:"
    echo "1. Get all folders"
    echo "2. Get folder by ID"
    echo "3. Get folder list (ID and Name)"
    echo "4. Search folders by name"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            get_all_folders
            ;;
        2)
            read -p "Enter folder ID (e.g., 980cc6e4-9cee-4365-9848-f8bebdaee575): " folder_id
            get_folder_by_id "$folder_id"
            ;;
        3)
            get_folder_list
            ;;
        4)
            read -p "Enter search term: " search_term
            search_folders "$search_term"
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo "✅ Complete!"
}

# Allow running with arguments
if [ "$#" -gt 0 ]; then
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! authenticate_directus; then
        exit 1
    fi
    
    case "$1" in
        --all)
            get_all_folders
            ;;
        --list)
            get_folder_list
            ;;
        --get)
            if [ -z "$2" ]; then
                echo "Usage: $0 --get <folder_id>"
                exit 1
            fi
            get_folder_by_id "$2"
            ;;
        --search)
            if [ -z "$2" ]; then
                echo "Usage: $0 --search <term>"
                exit 1
            fi
            search_folders "$2"
            ;;
        *)
            echo "Usage: $0 [--all|--list|--get <id>|--search <term>]"
            echo "Or run without arguments for interactive mode"
            exit 1
            ;;
    esac
else
    main
fi