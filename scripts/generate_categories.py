import json
from collections import defaultdict

# Sample product data with IDs from the API response
products = [
    {"id": "688d8ae93054eeaac26b0ad5", "name": "Pulpa hidratante para manos castaña", "customAttributes": {"brand": "Ekos"}},
    {"id": "688d8aea3054eeaac26b0ad6", "name": "Kaiak Oceano Masculino 100 ml", "customAttributes": {"brand": "Kaiak"}},
    {"id": "688d8aeb3054eeaac26b0ad7", "name": "Corrector cobertura extrema", "customAttributes": {"brand": "Una"}},
    {"id": "688d8aec3054eeaac26b0ad8", "name": "Meu Primeiro Humor eau de toilette femenina", "customAttributes": {"brand": "Humor"}},
    {"id": "688d8aee3054eeaac26b0ad9", "name": "Natura Homem eau de parfum masculino", "customAttributes": {"brand": "Homem"}},
    {"id": "688d8af03054eeaac26b0adb", "name": "Protector aclarador de manchas FPS 50", "customAttributes": {"brand": "Chronos Derma"}},
    {"id": "688d8af33054eeaac26b0add", "name": "Crema Nutritiva para Cuerpo", "customAttributes": {"brand": "Tododia"}},
    {"id": "688d8af53054eeaac26b0adf", "name": "Kriska eau de toilette femenina Shock", "customAttributes": {"brand": "Kriska"}},
    {"id": "688da20eeeee72acc43a2f48", "name": "iPhone 15 Pro", "customAttributes": None},
    {"id": "688da20eeeee72acc43a2f49", "name": "Men's T-Shirt", "customAttributes": None}
]

# Categorize products by type
product_types = {
    "Cosmetics": ["pulpa", "crema", "corrector", "protector", "bálsamo"],
    "Fragrances": ["eau de toilette", "parfum", "esencia"],
    "Electronics": ["iphone"],
    "Clothing": ["t-shirt", "dress"],
    "Gardening": ["tools"]
}

def get_category(product_name):
    name_lower = product_name.lower()
    for category, keywords in product_types.items():
        if any(keyword in name_lower for keyword in keywords):
            return category
    return "Other"

# Generate categories
categories = defaultdict(list)
for product in products:
    brand = product["customAttributes"]["brand"] if product["customAttributes"] else "Generic"
    category = get_category(product["name"])
    categories[category].append(brand)

# Generate API calls
print("Generated API calls:")
print("-------------------")
for category, brands in categories.items():
    print(f"# Create parent category: {category}")
    print(f"curl -X POST 'http://192.168.1.210:8080/api/categories' \\")
    print(f"  -H 'Content-Type: application/json' \\")
    print(f"  -d '{{\"name\": \"{category}\", \"description\": \"{category} products\"}}'")
    print()
    
    for brand in set(brands):
        print(f"# Create subcategory: {brand} under {category}")
        print(f"curl -X POST 'http://192.168.1.210:8080/api/categories' \\")
        print(f"  -H 'Content-Type: application/json' \\")
        print(f"  -d '{{\"name\": \"{brand}\", \"description\": \"{brand} {category}\"}}'")
        print()

print("# Assign products to categories")
for product in products:
    brand = product["customAttributes"]["brand"] if product["customAttributes"] else "Generic"
    category = get_category(product["name"])
    print(f"# Assign {product['name']} to {brand}/{category}")
    print(f"curl -X PUT 'http://192.168.1.210:8080/api/products/{product['id']}/categories' \\")
    print(f"  -H 'Content-Type: application/json' \\")
    print(f"  -d '{{\"categoryPath\": \"{category}/{brand}\"}}'")
    print()