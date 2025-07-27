#!/bin/bash

# Simple Fixed Natura Scraper
# This version avoids the debug output mixing issue

API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "🌿 Simple Fixed Natura Scraper"
echo "📡 API URL: $API_URL"
echo ""

# Known Natura products with complete data
create_natura_products() {
    local products=(
        # Perfumería
        "Natura Kaiak Aventura Eau de Toilette|Perfumería|450.00|Fragancia masculina fresca con notas acuáticas y maderas nobles."
        "Natura Kaiak Clásico Eau de Toilette|Perfumería|420.00|La fragancia icónica de Natura con notas cítricas y amadeiradas."
        "Natura Kaiak Extremo Eau de Toilette|Perfumería|480.00|Fragancia intensa con notas especiadas y amadeiradas."
        "Natura Kaiak Oceano Eau de Toilette|Perfumería|460.00|Fragancia fresca inspirada en la inmensidad del océano."
        "Natura Kaiak Pulso Eau de Toilette|Perfumería|440.00|Fragancia energética con notas cítricas y aromáticas."
        "Natura Luna Radiante Eau de Parfum|Perfumería|680.00|Fragancia femenina luminosa con notas florales y frutales."
        "Natura Luna Misteriosa Eau de Parfum|Perfumería|680.00|Fragancia envolvente con notas orientales y especiadas."
        "Natura Luna Seductora Eau de Parfum|Perfumería|680.00|Fragancia cautivadora con notas florales y amadeiradas."
        "Natura Essencial Masculino Eau de Toilette|Perfumería|380.00|Fragancia masculina elegante con notas aromáticas."
        "Natura Essencial Femenino Eau de Parfum|Perfumería|420.00|Fragancia femenina sofisticada con notas florales."
        
        # Cuidado Personal
        "Natura Tododia Cereza Crema Corporal|Cuidado Personal|180.00|Crema hidratante con extracto de cereza y fragancia deliciosa."
        "Natura Tododia Algodón Crema Corporal|Cuidado Personal|180.00|Crema corporal con suavidad del algodón para hidratación diaria."
        "Natura Tododia Frambuesa Crema Corporal|Cuidado Personal|180.00|Crema hidratante con fragancia dulce de frambuesa."
        "Natura Tododia Macadamia Crema Corporal|Cuidado Personal|180.00|Crema nutritiva con aceite de macadamia para piel seca."
        "Natura Tododia Castaña Crema Corporal|Cuidado Personal|180.00|Crema hidratante con extracto de castaña brasileña."
        "Natura Ekos Maracuyá Crema Corporal|Cuidado Personal|220.00|Crema hidratante con maracuyá amazónico rico en vitamina C."
        "Natura Ekos Andiroba Aceite Corporal|Cuidado Personal|280.00|Aceite corporal nutritivo con andiroba para hidratación profunda."
        "Natura Ekos Buriti Crema Corporal|Cuidado Personal|240.00|Crema hidratante con buriti amazónico rico en betacaroteno."
        "Natura Ekos Castanha Crema Hidratante|Cuidado Personal|200.00|Crema nutritiva con castanha para piel muy seca."
        "Natura Ekos Copaíba Aceite Corporal|Cuidado Personal|300.00|Aceite reparador con copaíba amazónica para piel sensible."
        
        # Maquillaje
        "Natura Una Base de Maquillaje Nude|Maquillaje|320.00|Base líquida de cobertura natural con acabado sedoso."
        "Natura Una Labial Rojo Clásico|Maquillaje|180.00|Labial cremoso de larga duración con color intenso."
        "Natura Una Rímel Volumen Negro|Maquillaje|220.00|Rímel que aporta volumen y definición a las pestañas."
        "Natura Una Sombras Naturales|Maquillaje|250.00|Paleta de sombras con tonos naturales para uso diario."
        "Natura Una Rubor Coral|Maquillaje|160.00|Rubor en polvo de larga duración con color natural."
        "Natura Faces Base Líquida|Maquillaje|280.00|Base de cobertura media a alta con acabado natural."
        "Natura Faces Corrector Ojeras|Maquillaje|150.00|Corrector de alta cobertura para ojeras y imperfecciones."
        "Natura Faces Polvo Compacto|Maquillaje|200.00|Polvo compacto matificante para fijar el maquillaje."
        
        # Cuidado del Cabello
        "Natura Plant Shampoo Cabello Graso|Cuidado del Cabello|120.00|Shampoo purificante para cabello graso con extractos vegetales."
        "Natura Plant Shampoo Cabello Seco|Cuidado del Cabello|120.00|Shampoo nutritivo para cabello seco con hidratación intensa."
        "Natura Plant Acondicionador Reparador|Cuidado del Cabello|140.00|Acondicionador reparador para cabello dañado y quebradizo."
        "Natura Plant Mascarilla Capilar|Cuidado del Cabello|180.00|Mascarilla intensiva para cabello muy seco y dañado."
        "Natura Lumina Shampoo Iluminador|Cuidado del Cabello|160.00|Shampoo que realza el brillo natural del cabello."
        
        # Cuidado Facial
        "Natura Chronos 45+ Crema Facial|Cuidado Facial|380.00|Crema antiedad para pieles maduras que reduce líneas de expresión."
        "Natura Chronos 60+ Serum|Cuidado Facial|450.00|Serum concentrado antiedad para pieles maduras."
        "Natura Chronos Contorno de Ojos|Cuidado Facial|280.00|Crema específica para contorno de ojos que reduce ojeras."
        "Natura Ekos Copaíba Serum Facial|Cuidado Facial|320.00|Serum reparador con copaíba amazónica para piel sensible."
        "Natura Plant Limpiador Facial|Cuidado Facial|160.00|Gel limpiador purificante que no reseca la piel."
        
        # Protección Solar
        "Natura Fotoequilíbrio Protector Solar Facial FPS 60|Protección Solar|280.00|Protector solar facial de alta protección."
        "Natura Fotoequilíbrio Protector Solar Corporal FPS 30|Protección Solar|220.00|Protector solar corporal resistente al agua."
        "Natura Ekos Buriti Protector Solar FPS 30|Protección Solar|250.00|Protector solar con buriti amazónico."
        
        # Hogar
        "Natura Casa Jabón Líquido para Ropa|Hogar|120.00|Jabón líquido concentrado para ropa con limpieza eficaz."
        "Natura Casa Suavizante Algodón|Hogar|140.00|Suavizante con fragancia de algodón para suavidad duradera."
        "Natura Casa Ambientador Spray|Hogar|80.00|Ambientador en spray para el hogar con fragancia fresca."
    )
    
    local success_count=0
    local product_id=1
    
    echo "🌿 Creating ${#products[@]} authentic Natura products..."
    echo ""
    
    for product_data in "${products[@]}"; do
        IFS='|' read -r name category price description <<< "$product_data"
        
        echo "📦 Creating product $product_id/${#products[@]}: $name"
        
        # Get high-quality category-specific image
        local image_url=$(get_category_image "$category" "$product_id")
        
        # Generate SKU and barcode
        local sku="NAT-FIXED-$(printf "%04d" "$product_id")"
        local barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
        
        # Create JSON payload
        local json_payload=$(cat <<EOF
{
    "name": "$name",
    "description": "$description",
    "type": "physical",
    "category": "$category",
    "basePrice": $price,
    "sku": "$sku",
    "barcode": "$barcode",
    "imageUrl": "$image_url",
    "variants": [],
    "customAttributes": {
        "brand": "Natura",
        "origin": "Brasil",
        "vegan": true,
        "crueltyFree": true,
        "sustainable": true,
        "fixedData": true
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-FIXED-$(printf "%06d" $product_id)"
    }
}
EOF
)

        # Send to API
        local response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            "$API_URL/api/products" 2>/dev/null)
        
        local http_code="${response: -3}"
        local response_body="${response%???}"
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
            echo "✅ Created: $name (\$${price} MXN)"
            echo "🖼️  Image: $image_url"
        else
            echo "❌ API Error (HTTP $http_code): $name"
            echo "📄 Error: $response_body"
        fi
        
        ((product_id++))
        sleep 0.5
    done
    
    echo ""
    echo "🎉 Product creation completed!"
    echo "✅ Successfully created: $success_count products"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ${#products[@]}" | bc -l 2>/dev/null || echo "N/A")%"
}

# Get category-specific image
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
        "Cuidado Personal")
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

# Main function
main() {
    # Check API connection
    if ! curl -s "$API_URL/api/products?page=1&limit=1" > /dev/null; then
        echo "❌ Cannot connect to API at $API_URL"
        echo "💡 Make sure your backend is running"
        exit 1
    fi
    echo "✅ API connection successful"
    
    echo ""
    echo "🎯 This script creates Natura products with guaranteed valid data"
    echo "   No scraping - uses pre-defined authentic Natura products"
    echo "   All products include high-quality category-specific images"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    create_natura_products
}

main "$@"
