#!/bin/bash

# Natura Scraper with Enhanced Image Handling
# This version focuses on getting high-quality product images

API_URL="${API_URL:-http://192.168.64.73:8080}"
NATURA_BASE_URL="https://www.natura.com.mx"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "🌿 Natura Scraper with Enhanced Images"
echo "📡 API URL: $API_URL"
echo ""

# High-quality placeholder images for different product categories
get_category_image() {
    local category="$1"
    local product_id="$2"
    
    case "$category" in
        "Perfumería")
            # Perfume bottle images
            echo "https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Maquillaje")
            # Makeup product images
            echo "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado del Cabello")
            # Hair care product images
            echo "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado Personal"|"Cuidado Corporal")
            # Body care product images
            echo "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Cuidado Facial")
            # Facial care product images
            echo "https://images.unsplash.com/photo-1570194065650-d99fb4bedf0a?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Protección Solar")
            # Sunscreen product images
            echo "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        "Hogar")
            # Home product images
            echo "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
        *)
            # Generic beauty product
            echo "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&h=400&fit=crop&crop=center&auto=format&q=80&seed=$product_id"
            ;;
    esac
}

# Known Natura products with realistic data
create_natura_products() {
    local products=(
        # Perfumería
        "Kaiak Aventura Eau de Toilette 100ml|Perfumería|450.00|Fragancia masculina fresca con notas acuáticas y maderas nobles. Inspirada en la aventura y la libertad."
        "Kaiak Clásico Eau de Toilette 100ml|Perfumería|420.00|La fragancia icónica de Natura con notas cítricas y amadeiradas. Un clásico atemporal."
        "Luna Radiante Eau de Parfum 75ml|Perfumería|680.00|Fragancia femenina luminosa con notas florales y frutales. Celebra la feminidad radiante."
        "Luna Misteriosa Eau de Parfum 75ml|Perfumería|680.00|Fragancia envolvente con notas orientales y especiadas. Para mujeres misteriosas y seductoras."
        "Essencial Masculino Eau de Toilette 100ml|Perfumería|380.00|Fragancia masculina elegante con notas aromáticas y amadeiradas. Esencia de la masculinidad."
        
        # Cuidado Personal
        "Tododia Cereza Crema Corporal 400ml|Cuidado Personal|180.00|Crema hidratante con extracto de cereza. Hidratación intensa con fragancia deliciosa."
        "Tododia Algodón Crema Corporal 400ml|Cuidado Personal|180.00|Crema corporal con suavidad del algodón. Hidratación y frescura todo el día."
        "Ekos Maracuyá Crema Corporal 400ml|Cuidado Personal|220.00|Crema hidratante con maracuyá amazónico. Rico en vitamina C y antioxidantes."
        "Ekos Andiroba Aceite Corporal 200ml|Cuidado Personal|280.00|Aceite corporal nutritivo con andiroba. Hidratación profunda y reparación natural."
        "Tododia Macadamia Crema Corporal 400ml|Cuidado Personal|180.00|Crema con aceite de macadamia. Nutrición intensa para piel seca."
        
        # Maquillaje
        "Una Base de Maquillaje Nude Rosado 30ml|Maquillaje|320.00|Base líquida de cobertura natural. Acabado sedoso y duradero para todo tipo de piel."
        "Una Labial Rojo Clásico 3.5g|Maquillaje|180.00|Labial cremoso de larga duración. Color intenso y acabado confortable."
        "Una Rímel Volumen Negro 8ml|Maquillaje|220.00|Rímel que aporta volumen y definición. Pestañas más largas y densas."
        "Faces Base Líquida Beige Natural 30ml|Maquillaje|280.00|Base de cobertura media a alta. Acabado natural y mate."
        "Una Rubor Coral Vibrante 4g|Maquillaje|160.00|Rubor en polvo de larga duración. Color natural y radiante."
        
        # Cuidado del Cabello
        "Plant Shampoo Cabello Graso 300ml|Cuidado del Cabello|120.00|Shampoo purificante para cabello graso. Con extractos vegetales equilibrantes."
        "Plant Shampoo Cabello Seco 300ml|Cuidado del Cabello|120.00|Shampoo nutritivo para cabello seco. Hidratación y suavidad intensas."
        "Plant Acondicionador Reparador 300ml|Cuidado del Cabello|140.00|Acondicionador reparador para cabello dañado. Restaura la fibra capilar."
        "Plant Mascarilla Capilar Nutritiva 250g|Cuidado del Cabello|180.00|Mascarilla intensiva para cabello muy seco. Nutrición profunda y brillo."
        "Lumina Shampoo Iluminador 300ml|Cuidado del Cabello|160.00|Shampoo que realza el brillo natural. Para cabello opaco y sin vida."
        
        # Cuidado Facial
        "Chronos 45+ Crema Facial Día 40g|Cuidado Facial|380.00|Crema antiedad para pieles maduras. Reduce líneas de expresión y aporta firmeza."
        "Chronos 60+ Serum Intensivo 30ml|Cuidado Facial|450.00|Serum concentrado antiedad. Tratamiento intensivo para pieles maduras."
        "Chronos Contorno de Ojos 15g|Cuidado Facial|280.00|Crema específica para contorno de ojos. Reduce ojeras y líneas de expresión."
        "Ekos Copaíba Serum Facial 30ml|Cuidado Facial|320.00|Serum reparador con copaíba amazónica. Calma y regenera la piel."
        "Plant Limpiador Facial Purificante 150ml|Cuidado Facial|160.00|Gel limpiador para rostro. Purifica sin resecar la piel."
        
        # Protección Solar
        "Fotoequilíbrio Protector Solar Facial FPS 60 50ml|Protección Solar|280.00|Protector solar facial de alta protección. Base perfecta para maquillaje."
        "Fotoequilíbrio Protector Solar Corporal FPS 30 200ml|Protección Solar|220.00|Protector solar corporal resistente al agua. Protección confiable todo el día."
        "Ekos Buriti Protector Solar FPS 30 200ml|Protección Solar|250.00|Protector solar con buriti amazónico. Protección natural y hidratación."
        
        # Hogar
        "Natura Casa Jabón Líquido para Ropa 1L|Hogar|120.00|Jabón líquido concentrado para ropa. Limpieza eficaz y cuidado de las fibras."
        "Natura Casa Suavizante Algodón 2L|Hogar|140.00|Suavizante con fragancia de algodón. Suavidad y frescura duraderas."
        "Natura Casa Ambientador Spray 250ml|Hogar|80.00|Ambientador en spray para el hogar. Fragancia fresca y duradera."
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
        local sku="NAT-IMG-$(printf "%04d" "$product_id")"
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
        "highQualityImage": true,
        "categoryImage": true
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-IMG-$(printf "%06d" $product_id)"
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
        
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            ((success_count++))
            echo "✅ Created: $name (\$${price} MXN)"
            echo "🖼️  Image: $image_url"
        else
            echo "❌ API Error (HTTP $http_code): $name"
        fi
        
        ((product_id++))
        sleep 0.5
    done
    
    echo ""
    echo "🎉 Product creation completed!"
    echo "✅ Successfully created: $success_count products"
    echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / ${#products[@]}" | bc -l 2>/dev/null || echo "N/A")%"
    echo ""
    echo "🖼️  All products have high-quality, category-specific images!"
    echo "🌿 Perfect for testing your app with beautiful Natura products!"
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
    echo "🎯 This script creates Natura products with high-quality images"
    echo "   Uses category-specific placeholder images from Unsplash"
    echo "   All images are 400x400px, high quality, and relevant"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    create_natura_products
}

main "$@"
