# 🌐 Natura Real Product Scraper

Estos scripts extraen productos **REALES** del sitio web oficial de Natura México (natura.com.mx) con sus imágenes, precios y descripciones auténticas.

## 🚀 Scripts Disponibles

### **Script Básico** (Recomendado para empezar)
```bash
cd scripts
./scrape-natura-real.sh
```

### **Script Avanzado** (Más robusto)
```bash
cd scripts
./scrape-natura-advanced.sh
```

## ⚙️ Requisitos

### **Dependencias Necesarias**
```bash
# macOS
brew install curl jq grep sed bc

# Ubuntu/Debian
sudo apt-get install curl jq grep sed bc

# CentOS/RHEL
sudo yum install curl jq grep sed bc
```

### **Verificar Instalación**
```bash
curl --version
jq --version
```

## 🛡️ Características de Seguridad

### **Comportamiento Respetuoso**
- ✅ **Delays entre requests**: 2 segundos por defecto
- ✅ **User-Agent realista**: Simula navegador real
- ✅ **Reintentos limitados**: Máximo 3 intentos por página
- ✅ **Timeouts**: 30 segundos máximo por request
- ✅ **Headers apropiados**: Accept-Language, Cache-Control, etc.

### **Límites de Protección**
- 📊 **Máximo 200 productos** por defecto
- ⏱️ **2 segundos de delay** entre requests
- 🔄 **3 reintentos máximo** por página fallida
- 📝 **Logging detallado** de todas las operaciones

## 📊 Datos Extraídos

### **Información de Productos**
- **Nombre**: Título exacto del producto
- **Precio**: Precio en pesos mexicanos (MXN)
- **Descripción**: Descripción oficial del producto
- **Imagen**: URL de imagen real del producto
- **Categoría**: Categoría detectada automáticamente
- **SKU**: Generado basado en el nombre real

### **Categorías Soportadas**
1. **Perfumería** - Fragancias, colonias, desodorantes
2. **Cuidado Personal** - Jabones, cremas corporales
3. **Maquillaje** - Bases, labiales, rímel, sombras
4. **Cuidado del Cabello** - Shampoos, acondicionadores
5. **Protección Solar** - Protectores solares, bronceadores
6. **Cuidado Facial** - Serums, cremas, limpiadores
7. **Cuidado Corporal** - Lociones, aceites corporales
8. **Hogar** - Productos para el hogar

## 🔧 Configuración Avanzada

### **Archivo de Configuración** (`natura-scraper-config.json`)
```json
{
  "baseUrl": "https://www.natura.com.mx",
  "maxProducts": 200,
  "delayBetweenRequests": 2,
  "categories": [...],
  "fallbackSelectors": {...}
}
```

### **Personalizar Límites**
```bash
# Cambiar número máximo de productos
sed -i 's/"maxProducts": 200/"maxProducts": 100/' natura-scraper-config.json

# Cambiar delay entre requests
sed -i 's/"delayBetweenRequests": 2/"delayBetweenRequests": 3/' natura-scraper-config.json
```

## 📋 Proceso de Scraping

### **Paso 1: Extracción de URLs**
```
🔍 Scanning category: https://www.natura.com.mx/perfumeria
📦 Found 45 product URLs in Perfumería
🔍 Scanning category: https://www.natura.com.mx/maquillaje
📦 Found 38 product URLs in Maquillaje
```

### **Paso 2: Extracción de Datos**
```
📦 Processing product 1/150: https://www.natura.com.mx/producto/kaiak-aventura
✅ Created: Kaiak Aventura Eau de Toilette ($450.00 MXN)
📦 Processing product 2/150: https://www.natura.com.mx/producto/luna-radiante
✅ Created: Luna Radiante Eau de Parfum ($680.00 MXN)
```

### **Paso 3: Resultados**
```
🎉 Scraping completed!
✅ Successfully created: 142 products
❌ Failed to create: 8 products
📊 Success rate: 94.7%
🖼️  Images downloaded to: ./natura_images
📋 Check log file: ./natura_scrape.log
```

## 🖼️ Manejo de Imágenes

### **Descarga Automática**
- Las imágenes se descargan a `./natura_images/`
- Formato: `natura_001.jpg`, `natura_002.png`, etc.
- Respaldo con placeholder si falla la descarga

### **URLs de Imagen**
- Se extraen URLs reales de imágenes de producto
- Se convierten URLs relativas a absolutas
- Se incluyen en el campo `imageUrl` del producto

## 📝 Logging y Debugging

### **Archivo de Log** (`natura_scrape.log`)
```
2024-01-15 10:30:15 - 🚀 Starting Natura scraping session
2024-01-15 10:30:16 - 📋 Configuration loaded: 200 max products, 2s delay
2024-01-15 10:30:17 - ✅ API connection successful
2024-01-15 10:30:18 - 🔍 Scanning category: https://www.natura.com.mx/perfumeria
2024-01-15 10:30:20 - 📦 Found 45 product URLs in Perfumería
```

### **Debugging**
```bash
# Ver log en tiempo real
tail -f natura_scrape.log

# Verificar productos creados
curl "$API_URL/api/products?q=Natura&limit=50"

# Verificar imágenes descargadas
ls -la natura_images/
```

## ⚠️ Consideraciones Importantes

### **Aspectos Legales**
- ✅ **Uso educativo/testing**: Apropiado para desarrollo
- ✅ **Respeto al sitio**: Delays y límites implementados
- ✅ **No comercial**: Solo para pruebas de funcionalidad
- ⚠️ **Términos de servicio**: Revisar términos de Natura

### **Aspectos Técnicos**
- 🔄 **Estructura del sitio**: Puede cambiar y afectar el scraping
- 📱 **Detección**: El sitio puede detectar scraping automatizado
- 🌐 **Conectividad**: Requiere conexión estable a internet
- 💾 **Espacio**: Las imágenes pueden ocupar varios MB

## 🚨 Solución de Problemas

### **Error: "Missing dependencies"**
```bash
# Instalar dependencias faltantes
brew install curl jq grep sed bc  # macOS
sudo apt-get install curl jq      # Ubuntu
```

### **Error: "Cannot connect to API"**
```bash
# Verificar que el backend esté corriendo
curl http://192.168.64.73:8080/api/products?page=1&limit=1

# Cambiar URL de API si es necesario
API_URL=http://localhost:8080 ./scrape-natura-real.sh
```

### **Error: "Failed to fetch category page"**
```bash
# Verificar conectividad
curl -I https://www.natura.com.mx

# El sitio puede haber cambiado estructura
# Revisar y actualizar URLs en el script
```

### **Pocos productos extraídos**
```bash
# Aumentar límite de productos
sed -i 's/MAX_PRODUCTS=200/MAX_PRODUCTS=500/' scrape-natura-real.sh

# Verificar selectores CSS en el archivo de configuración
# El sitio puede haber cambiado su estructura HTML
```

## 🎯 Resultados Esperados

### **Productos Típicos Extraídos**
```json
{
  "name": "Kaiak Aventura Eau de Toilette 100ml",
  "description": "Fragancia masculina con notas frescas y aventureras",
  "basePrice": 450.00,
  "category": "Perfumería",
  "imageUrl": "https://www.natura.com.mx/images/kaiak-aventura.jpg",
  "customAttributes": {
    "brand": "Natura",
    "realProduct": true,
    "scraped": true,
    "sourceUrl": "natura.com.mx"
  }
}
```

### **Estadísticas Típicas**
- **Tasa de éxito**: 85-95%
- **Productos por categoría**: 15-50
- **Tiempo total**: 10-30 minutos
- **Imágenes descargadas**: 80-90%

## 🔄 Integración con Otros Scripts

### **Workflow Completo**
```bash
# 1. Limpiar base de datos
./clear-products.sh

# 2. Extraer productos reales de Natura
./scrape-natura-real.sh

# 3. Complementar con productos generados si es necesario
./generate-natura-products.sh

# 4. Probar la aplicación con datos reales
```

¡Ahora tienes productos **100% reales** de Natura para probar tu aplicación! 🌿✨
