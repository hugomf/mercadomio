Generated API calls:
-------------------
# Create parent category: Cosmetics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Cosmetics", "description": "Cosmetics products"}'

# Create subcategory: Una under Cosmetics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Una", "description": "Una Cosmetics"}'

# Create subcategory: Chronos Derma under Cosmetics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Chronos Derma", "description": "Chronos Derma Cosmetics"}'

# Create subcategory: Tododia under Cosmetics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Tododia", "description": "Tododia Cosmetics"}'

# Create subcategory: Ekos under Cosmetics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Ekos", "description": "Ekos Cosmetics"}'

# Create parent category: Other
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Other", "description": "Other products"}'

# Create subcategory: Kaiak under Other
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Kaiak", "description": "Kaiak Other"}'

# Create parent category: Fragrances
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Fragrances", "description": "Fragrances products"}'

# Create subcategory: Humor under Fragrances
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Humor", "description": "Humor Fragrances"}'

# Create subcategory: Kriska under Fragrances
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Kriska", "description": "Kriska Fragrances"}'

# Create subcategory: Homem under Fragrances
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Homem", "description": "Homem Fragrances"}'

# Create parent category: Electronics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Electronics", "description": "Electronics products"}'

# Create subcategory: Generic under Electronics
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Generic", "description": "Generic Electronics"}'

# Create parent category: Clothing
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Clothing", "description": "Clothing products"}'

# Create subcategory: Generic under Clothing
curl -X POST 'http://192.168.1.210:8080/api/categories' \
  -H 'Content-Type: application/json' \
  -d '{"name": "Generic", "description": "Generic Clothing"}'

# Assign products to categories
# Assign Pulpa hidratante para manos castaña to Ekos/Cosmetics
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8ae93054eeaac26b0ad5/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Cosmetics/Ekos"}'

# Assign Kaiak Oceano Masculino 100 ml to Kaiak/Other
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8aea3054eeaac26b0ad6/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Other/Kaiak"}'

# Assign Corrector cobertura extrema to Una/Cosmetics
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8aeb3054eeaac26b0ad7/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Cosmetics/Una"}'

# Assign Meu Primeiro Humor eau de toilette femenina to Humor/Fragrances
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8aec3054eeaac26b0ad8/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Fragrances/Humor"}'

# Assign Natura Homem eau de parfum masculino to Homem/Fragrances
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8aee3054eeaac26b0ad9/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Fragrances/Homem"}'

# Assign Protector aclarador de manchas FPS 50 to Chronos Derma/Cosmetics
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8af03054eeaac26b0adb/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Cosmetics/Chronos Derma"}'

# Assign Crema Nutritiva para Cuerpo to Tododia/Cosmetics
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8af33054eeaac26b0add/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Cosmetics/Tododia"}'

# Assign Kriska eau de toilette femenina Shock to Kriska/Fragrances
curl -X PUT 'http://192.168.1.210:8080/api/products/688d8af53054eeaac26b0adf/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Fragrances/Kriska"}'

# Assign iPhone 15 Pro to Generic/Electronics
curl -X PUT 'http://192.168.1.210:8080/api/products/688da20eeeee72acc43a2f48/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Electronics/Generic"}'

# Assign Men's T-Shirt to Generic/Clothing
curl -X PUT 'http://192.168.1.210:8080/api/products/688da20eeeee72acc43a2f49/categories' \
  -H 'Content-Type: application/json' \
  -d '{"categoryPath": "Clothing/Generic"}'

