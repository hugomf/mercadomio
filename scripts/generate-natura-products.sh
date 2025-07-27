#!/bin/bash

# Configuration
API_URL="${API_URL:-http://192.168.64.73:8080}"
TOTAL_PRODUCTS=500

echo "🌿 Natura Product Generator"
echo "📡 API URL: $API_URL"
echo "🛍️  Generating $TOTAL_PRODUCTS realistic Natura products..."
echo ""

# Natura product categories and lines
natura_categories=("Perfumería" "Cuidado Personal" "Maquillaje" "Cuidado del Cabello" "Protección Solar" "Cuidado Facial" "Cuidado Corporal" "Hogar")

# Natura fragrance lines
fragrances=("Kaiak" "Luna" "Homem" "Essencial" "Tododia" "Mamãe e Bebê" "Chronos" "Plant" "Ekos" "Una")

# Natura skincare lines
skincare_lines=("Chronos" "Tododia" "Ekos" "Plant" "Una" "Mamãe e Bebê" "Faces" "Sève")

# Natura makeup lines
makeup_lines=("Una" "Faces" "Aquarela" "Colortrend")

# Natura hair care lines
haircare_lines=("Plant" "Ekos" "Tododia" "Lumina" "Chronos")

# Product types by category
perfumeria_products=("Eau de Toilette" "Eau de Parfum" "Colonia" "Desodorante" "Body Splash" "Perfume en Crema")
cuidado_personal_products=("Jabón Líquido" "Desodorante" "Crema Corporal" "Aceite Corporal" "Exfoliante" "Gel de Ducha")
maquillaje_products=("Base de Maquillaje" "Corrector" "Polvo Compacto" "Rubor" "Labial" "Gloss" "Rímel" "Delineador" "Sombras")
cabello_products=("Shampoo" "Acondicionador" "Mascarilla" "Aceite Capilar" "Crema para Peinar" "Spray Protector")
proteccion_solar_products=("Protector Solar Facial" "Protector Solar Corporal" "Bronceador" "After Sun" "Protector Labial")
cuidado_facial_products=("Limpiador Facial" "Tónico" "Serum" "Crema Hidratante" "Contorno de Ojos" "Mascarilla Facial" "Exfoliante Facial")
cuidado_corporal_products=("Crema Corporal" "Aceite Corporal" "Loción Hidratante" "Exfoliante Corporal" "Gel Reductor")
hogar_products=("Jabón Líquido para Ropa" "Suavizante" "Ambientador" "Vela Aromática" "Difusor")

# Natura ingredients (natural focus)
natura_ingredients=("Açaí" "Andiroba" "Buriti" "Castanha" "Copaíba" "Cupuaçu" "Maracuyá" "Pitanga" "Ucuuba" "Murumuru" "Pracaxi" "Patauá")

# Product sizes/presentations
sizes_ml=("30ml" "50ml" "75ml" "100ml" "150ml" "200ml" "250ml" "300ml" "400ml" "500ml")
sizes_g=("15g" "30g" "50g" "75g" "100g" "150g" "200g")

# Natura-style colors for makeup
makeup_colors=("Nude Rosado" "Coral Vibrante" "Rojo Clásico" "Rosa Suave" "Beige Natural" "Marrón Chocolate" "Dorado Brillante" "Plata Metálico")

# Realistic Natura product images (using placeholder service with Natura-style images)
image_base_url="https://picsum.photos/300/400?random="

# Real Natura product collections for more authenticity
kaiak_products=("Kaiak Aventura" "Kaiak Clásico" "Kaiak Extremo" "Kaiak Oceano" "Kaiak Pulso")
luna_products=("Luna Radiante" "Luna Misteriosa" "Luna Seductora" "Luna Encantadora")
tododia_products=("Tododia Algodón" "Tododia Cereza" "Tododia Frambuesa" "Tododia Macadamia" "Tododia Castaña")
ekos_products=("Ekos Maracuyá" "Ekos Andiroba" "Ekos Buriti" "Ekos Castanha" "Ekos Copaíba" "Ekos Açaí")
chronos_products=("Chronos 45+" "Chronos 60+" "Chronos Noche" "Chronos Día" "Chronos Contorno de Ojos")
plant_products=("Plant Cabello Graso" "Plant Cabello Seco" "Plant Cabello Rizado" "Plant Cabello Teñido")

# Function to get random element from array
get_random() {
    local arr=("$@")
    echo "${arr[$RANDOM % ${#arr[@]}]}"
}

# Function to generate authentic Natura product name
generate_natura_name() {
    local category="$1"
    local ingredient=$(get_random "${natura_ingredients[@]}")

    case "$category" in
        "Perfumería")
            local fragrances_all=("${kaiak_products[@]}" "${luna_products[@]}")
            local fragrance=$(get_random "${fragrances_all[@]}")
            local product=$(get_random "${perfumeria_products[@]}")
            echo "$fragrance $product"
            ;;
        "Cuidado Personal")
            local tododia_product=$(get_random "${tododia_products[@]}")
            local product=$(get_random "${cuidado_personal_products[@]}")
            echo "$tododia_product $product"
            ;;
        "Maquillaje")
            local makeup_line=$(get_random "${makeup_lines[@]}")
            local product=$(get_random "${maquillaje_products[@]}")
            local color=$(get_random "${makeup_colors[@]}")
            echo "Natura $makeup_line $product $color"
            ;;
        "Cuidado del Cabello")
            local plant_product=$(get_random "${plant_products[@]}")
            local product=$(get_random "${cabello_products[@]}")
            echo "$plant_product $product"
            ;;
        "Protección Solar")
            local product=$(get_random "${proteccion_solar_products[@]}")
            local fps=$((RANDOM % 40 + 15))
            echo "Natura Fotoequilíbrio $product FPS $fps"
            ;;
        "Cuidado Facial")
            local chronos_product=$(get_random "${chronos_products[@]}")
            local product=$(get_random "${cuidado_facial_products[@]}")
            echo "$chronos_product $product"
            ;;
        "Cuidado Corporal")
            local ekos_product=$(get_random "${ekos_products[@]}")
            local product=$(get_random "${cuidado_corporal_products[@]}")
            echo "$ekos_product $product"
            ;;
        "Hogar")
            local product=$(get_random "${hogar_products[@]}")
            echo "Natura Casa $product"
            ;;
        *)
            echo "Natura Producto Especial"
            ;;
    esac
}

# Function to generate realistic Natura price (Mexican Pesos)
get_natura_price() {
    local category="$1"
    case "$category" in
        "Perfumería") echo "$((RANDOM % 800 + 200)).$((RANDOM % 100))" ;;
        "Maquillaje") echo "$((RANDOM % 400 + 100)).$((RANDOM % 100))" ;;
        "Cuidado Facial") echo "$((RANDOM % 600 + 150)).$((RANDOM % 100))" ;;
        "Cuidado del Cabello") echo "$((RANDOM % 300 + 80)).$((RANDOM % 100))" ;;
        "Protección Solar") echo "$((RANDOM % 400 + 120)).$((RANDOM % 100))" ;;
        "Cuidado Personal") echo "$((RANDOM % 250 + 60)).$((RANDOM % 100))" ;;
        "Cuidado Corporal") echo "$((RANDOM % 300 + 70)).$((RANDOM % 100))" ;;
        "Hogar") echo "$((RANDOM % 200 + 40)).$((RANDOM % 100))" ;;
        *) echo "$((RANDOM % 300 + 50)).$((RANDOM % 100))" ;;
    esac
}

# Function to generate product description
generate_description() {
    local category="$1"
    local ingredient="$2"
    
    local base_descriptions=(
        "Producto Natura con ingredientes naturales de la Amazonía brasileña."
        "Fórmula enriquecida con activos vegetales que respetan tu piel y el medio ambiente."
        "Desarrollado con tecnología Natura y extractos naturales de alta calidad."
        "Producto vegano y cruelty-free, comprometido con la sostenibilidad."
        "Inspirado en la biodiversidad brasileña para cuidar tu belleza naturalmente."
    )
    
    local description=$(get_random "${base_descriptions[@]}")
    echo "$description Enriquecido con $ingredient para resultados excepcionales."
}

# Function to generate realistic image URL
generate_image_url() {
    local product_id="$1"

    # Generate unique image using picsum with seed for consistency
    echo "${image_base_url}${product_id}"
}

# Function to get product size
get_product_size() {
    local category="$1"
    case "$category" in
        "Perfumería"|"Cuidado Personal"|"Cuidado del Cabello"|"Protección Solar"|"Cuidado Facial"|"Cuidado Corporal")
            get_random "${sizes_ml[@]}"
            ;;
        "Maquillaje")
            get_random "${sizes_g[@]}"
            ;;
        "Hogar")
            get_random "500ml" "1L" "2L"
            ;;
        *)
            get_random "${sizes_ml[@]}"
            ;;
    esac
}

success_count=0
error_count=0

# Generate Natura products
for i in $(seq 1 $TOTAL_PRODUCTS); do
    # Select random Natura data
    category=$(get_random "${natura_categories[@]}")
    ingredient=$(get_random "${natura_ingredients[@]}")
    size=$(get_product_size "$category")
    
    # Generate product details
    name=$(generate_natura_name "$category")
    price=$(get_natura_price "$category")
    description=$(generate_description "$category" "$ingredient")
    image_url=$(generate_image_url "$i")
    
    # Generate Natura-style SKU
    category_code=$(echo "$category" | cut -c1-3 | tr '[:lower:]' '[:upper:]')
    sku="NAT-${category_code}-$(printf "%04d" $i)"
    barcode="789$(printf "%010d" $((RANDOM % 9999999999)))"
    
    # Create JSON payload with Natura branding
    json_payload=$(cat <<EOF
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
        "line": "$(echo $name | cut -d' ' -f1)",
        "ingredient": "$ingredient",
        "size": "$size",
        "origin": "Brasil",
        "vegan": true,
        "crueltyFree": true,
        "sustainable": true,
        "certification": "ECOCERT"
    },
    "identifiers": {
        "upc": "$barcode",
        "model": "NAT-$(printf "%06d" $i)"
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
        if [ $((success_count % 25)) -eq 0 ]; then
            echo "🌿 Successfully created $success_count Natura products"
        fi
    else
        ((error_count++))
        if [ $error_count -le 5 ]; then
            echo "❌ Error creating Natura product $i (HTTP $http_code)"
        fi
    fi
    
    # Progress indicator
    if [ $((i % 50)) -eq 0 ]; then
        echo "📦 Progress: $i/$TOTAL_PRODUCTS Natura products processed"
    fi
    
    # Small delay to be nice to the server
    sleep 0.02
done

echo ""
echo "🎉 Natura product generation completed!"
echo "✅ Successfully created: $success_count products"
echo "❌ Failed to create: $error_count products"
echo "📊 Success rate: $(echo "scale=1; $success_count * 100 / $TOTAL_PRODUCTS" | bc -l)%"
echo ""
echo "🌿 Generated realistic Natura products including:"
echo "   • Perfumería (Kaiak, Luna, Essencial)"
echo "   • Cuidado Personal (Tododia, Ekos)"
echo "   • Maquillaje (Una, Faces)"
echo "   • Cuidado del Cabello (Plant, Lumina)"
echo "   • Protección Solar (FPS 15-55)"
echo "   • Cuidado Facial (Chronos, Plant)"
echo "   • Cuidado Corporal (ingredientes amazónicos)"
echo "   • Hogar (productos sustentables)"
echo ""
echo "🇧🇷 All products feature authentic Brazilian ingredients and Natura's sustainability values!"
