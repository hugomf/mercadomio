#!/bin/bash

# Seafood grocery catalog for Mercadomio.
#
# The live API expects the service shape, not the legacy one:
#   * categories: { name, description, parentId (omit/null for roots) }
#   * products:   { name, description, type, basePrice, category, categories,
#                   sku, imageUrl, customAttributes }
#
# IMPORTANT: category filtering on the backend runs a regex over the product
# `category` STRING (the category name), so every product must carry both the
# `category` name and the `categories` array of ObjectIDs.
#
# Usage: ./seed_grocery.sh [api_url]   (default http://localhost:8080/api)

API_URL="${1:-http://localhost:8080/api}"

create_category() {
  local name="$1"
  local description="$2"

  local json
  json=$(jq -nc --arg name "$name" --arg description "$description" \
    '{name: $name, description: $description, parentId: null}')

  curl -s -X POST "$API_URL/categories" \
    -H "Content-Type: application/json" \
    -d "$json"
}

create_product() {
  local name="$1"
  local base_price="$2"
  local unit="$3"
  local sku="$4"
  local description="$5"
  local category_id="$6"
  local category_name="$7"

  local json
  json=$(jq -nc \
    --arg name "$name" \
    --arg description "$description" \
    --arg type "physical" \
    --arg category "$category_name" \
    --arg categoryId "$category_id" \
    --argjson basePrice "$base_price" \
    --arg sku "$sku" \
    --arg unit "$unit" \
    '{name: $name, description: $description, type: $type,
      category: $category, categories: [$categoryId],
      basePrice: $basePrice, sku: $sku,
      customAttributes: {unit: $unit}}')

  curl -s -X POST "$API_URL/products" \
    -H "Content-Type: application/json" \
    -d "$json"
}

echo "Creating categories..."

fyv=$(create_category "Frutas y Verduras" "Frutas y verduras frescas de temporada" | jq -r '.id')
car=$(create_category "Carniceria" "Carnes frescas de res, pollo y cerdo" | jq -r '.id')
pan=$(create_category "Panaderia" "Pan artesanal y de caja" | jq -r '.id')
lac=$(create_category "Lacteos y Huevos" "Lacteos, quesos y huevos" | jq -r '.id')
aba=$(create_category "Abarrotes" "Despensa y abarrotes" | jq -r '.id')
beb=$(create_category "Bebidas" "Aguas, jugos, refrescos y cervezas" | jq -r '.id')
lim=$(create_category "Limpieza y Hogar" "Limpieza y cuidado del hogar" | jq -r '.id')

echo "categories: $fyv, $car, $pan, $lac, $aba, $beb, $lim"

# Category display names (the `category` string shown in the app / used in filters)
FYV="Frutas y Verduras"
CAR="Carniceria"
PAN="Panaderia"
LAC="Lacteos y Huevos"
ABA="Abarrotes"
BEB="Bebidas"
LIM="Limpieza y Hogar"

echo "Creating products..."

# Frutas y Verduras
create_product "Manzana Roja Delicios"     39.90  "kg"  "P-FV-001" "Manzana roja jugosa, ideal para postres y ensaladas"       "$fyv" "$FYV"
create_product "Platano Tabasco"            24.50  "kg"  "P-FV-002" "Platano tabasco maduro, dulce y cremoso"                    "$fyv" "$FYV"
create_product "Aguacate Hass"              89.00  "kg"  "P-FV-003" "Aguacate hass de exportacion"                                 "$fyv" "$FYV"
create_product "Jitomate Saladette"         29.90  "kg"  "P-FV-004" "Jitomate saladette fresco para guisos"                        "$fyv" "$FYV"
create_product "Cebolla Blanca"             18.90  "kg"  "P-FV-005" "Cebolla blanca para todo tipo de platillos"                    "$fyv" "$FYV"
create_product "Papa Blanca"                21.50  "kg"  "P-FV-006" "Papa blanca lista para freir o guisar"                         "$fyv" "$FYV"

# Carniceria
create_product "Pechuga de Pollo"          129.00 "kg"  "P-CA-001" "Pechuga de pollo fresca sin piel"                                "$car" "$CAR"
create_product "Res Molida"                159.00 "kg"  "P-CA-002" "Res molida premium para hamburguesas y albondigas"              "$car" "$CAR"
create_product "Arrachera"                 349.00 "kg"  "P-CA-003" "Arrachera de res lista para la parrilla"                         "$car" "$CAR"
create_product "Costilla de Cerdo"          99.90 "kg"  "P-CA-004" "Costilla de cerdo para adobos"                                   "$car" "$CAR"
create_product "Filete de Pescado"         189.00 "kg"  "P-CA-005" "Filete de pescado blanco congelado"                              "$car" "$CAR"

# Panaderia
create_product "Bolillo"                     8.90 "pieza" "P-PA-001" "Bolillo fresco horneado en el dia"                                "$pan" "$PAN"
create_product "Barra de Pan Artesanal"     49.00 "pieza" "P-PA-002" "Barra crujiente de masa madre"                                    "$pan" "$PAN"
create_product "Pan de Caja Integral"       42.50 "pieza" "P-PA-003" "Pan de caja integral rebanado"                                    "$pan" "$PAN"
create_product "Concha"                     12.90 "pieza" "P-PA-004" "Concha de vainilla recien horneada"                                "$pan" "$PAN"
create_product "Pan Frances"                 39.00 "pieza" "P-PA-005" "Pan frances de 30 cm"                                             "$pan" "$PAN"

# Lacteos y Huevos
create_product "Leche Entera 1L"            27.90 "L"    "P-LA-001" "Leche de vaca entera ultrapasteurizada"                            "$lac" "$LAC"
create_product "Huevo Blanco (12 piezas)"   42.00 "caja" "P-LA-002" "Huevo blanco grado A de rancho"                                    "$lac" "$LAC"
create_product "Queso Manchego"             125.00 "kg"  "P-LA-003" "Queso manchego para derretir"                                      "$lac" "$LAC"
create_product "Yogurt Natural 1L"          35.50 "L"    "P-LA-004" "Yogurt natural sin azucar anadida"                                  "$lac" "$LAC"
create_product "Mantequilla 200g"           58.00 "pieza" "P-LA-005" "Mantequilla cremosa con sal"                                       "$lac" "$LAC"

# Abarrotes
create_product "Arroz Premium 1kg"          34.00 "bolsa" "P-AB-001" "Arroz blanco de grano largo"                                       "$aba" "$ABA"
create_product "Frijol Negro 1kg"           36.50 "bolsa" "P-AB-002" "Frijol negro seleccionado"                                          "$aba" "$ABA"
create_product "Aceite Vegetal 1L"          48.00 "L"    "P-AB-003" "Aceite vegetal comestible"                                          "$aba" "$ABA"
create_product "Azucar Estandar 1kg"        28.90 "bolsa" "P-AB-004" "Azucar refinada estandar"                                           "$aba" "$ABA"
create_product "Harina de Trigo 1kg"        22.50 "bolsa" "P-AB-005" "Harina de trigo para reposteria"                                    "$aba" "$ABA"
create_product "Cafe Molido 250g"            89.00 "pieza" "P-AB-006" "Cafe arábico molido de altura"                                      "$aba" "$ABA"

# Bebidas
create_product "Agua Natural 1L"            17.00 "L"    "P-BE-001" "Agua purificada sin gas"                                             "$beb" "$BEB"
create_product "Jugo de Naranja 1L"         32.00 "L"    "P-BE-002" "Jugo de naranja natural 100%"                                        "$beb" "$BEB"
create_product "Refresco de Cola 600ml"     22.00 "pieza" "P-BE-003" "Refresco de cola 600 mililitros"                                     "$beb" "$BEB"
create_product "Cerveza Lager 6 pack"      119.00 "pack" "P-BE-004" "Cerveza lager en botella de seis piezas"                             "$beb" "$BEB"
create_product "Agua Mineral 600ml"          15.00 "pieza" "P-BE-005" "Agua mineral con gas"                                                "$beb" "$BEB"

# Limpieza y Hogar
create_product "Detergente para Ropa 1kg"   78.00 "pieza" "P-LI-001" "Detergente en polvo para ropa blanca y de color"                     "$lim" "$LIM"
create_product "Jabon Liquido 500ml"        45.50 "pieza" "P-LI-002" "Jabon liquido antibacterial para manos"                              "$lim" "$LIM"
create_product "Cloro 2L"                   38.00 "L"    "P-LI-003" "Blanqueador a base de cloro"                                         "$lim" "$LIM"
create_product "Servilletas (200 pzas)"      52.00 "paquete" "P-LI-004" "Servilletas suaves de papel"                                        "$lim" "$LIM"
create_product "Jabon de Trastes 1L"         36.00 "L"    "P-LI-005" "Jabon desengrasante para trastes"                                    "$lim" "$LIM"

echo "Seeding completed!"