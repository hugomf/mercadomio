# Product Generation Scripts

This directory contains scripts to populate your database with realistic test products for testing pagination and search functionality.

## 🚀 Quick Start

### Option 1: Node.js Script (Recommended)
```bash
# Make sure your backend is running on localhost:8080
cd scripts
node generate-products.js
```

### Option 2: Bash Script
```bash
# Make sure your backend is running on localhost:8080
cd scripts
./generate-products.sh
```

### Option 3: Custom API URL
```bash
# If your backend is running on a different URL
API_URL=http://192.168.64.73:8080 node generate-products.js
# or
API_URL=http://192.168.64.73:8080 ./generate-products.sh
```

## 📊 What Gets Generated

The scripts will create **5,000 realistic products** with:

### Categories (15 total)
- Electronics (smartphones, laptops, headphones, etc.)
- Clothing (t-shirts, jeans, shoes, etc.)
- Home & Garden (furniture, plants, tools, etc.)
- Sports & Outdoors (equipment, gear, etc.)
- Books (novels, cookbooks, textbooks, etc.)
- Health & Beauty (cosmetics, supplements, etc.)
- Toys & Games, Automotive, Food & Beverages, Office Supplies, Pet Supplies, Jewelry, Music & Movies, Tools & Hardware, Baby & Kids

### Realistic Data
- **Names**: Brand + Adjective + Product (e.g., "Apple Premium Smartphone")
- **Prices**: Category-appropriate pricing ($5-$2000+ based on category)
- **SKUs**: Formatted like "ELE-000001", "CLO-000002", etc.
- **Barcodes**: 13-digit realistic barcodes
- **Descriptions**: Contextual product descriptions
- **Attributes**: Brand, color, weight, dimensions
- **Identifiers**: UPC codes, model numbers

### Sample Products
```json
{
  "name": "Samsung Ultra Smart Watch",
  "description": "Professional-grade smart watch with advanced features.",
  "type": "physical",
  "category": "Electronics",
  "basePrice": 299.99,
  "sku": "ELE-001234",
  "barcode": "1234567890123",
  "customAttributes": {
    "brand": "Samsung",
    "color": "Black",
    "weight": "2.3 lbs"
  }
}
```

## ⚡ Performance

### Node.js Script
- **Batch processing**: Sends 50 products at once
- **Concurrent requests**: Faster execution
- **Progress tracking**: Shows real-time progress
- **Error handling**: Continues on individual failures
- **Estimated time**: ~2-3 minutes for 5,000 products

### Bash Script
- **Sequential processing**: One product at a time
- **Simple and reliable**: Uses curl
- **Progress tracking**: Shows every 250 products
- **Error handling**: Continues on failures
- **Estimated time**: ~5-8 minutes for 5,000 products

## 🧪 Testing Pagination

After running the script, you can test:

### Frontend Pagination
1. **Normal browsing**: Should show 10 products per page with infinite scroll
2. **Search functionality**: Try searching for "Samsung", "Electronics", "Premium"
3. **Category filtering**: Backend supports category-based searches
4. **Performance**: Should handle large result sets smoothly

### API Testing
```bash
# Test pagination
curl "http://localhost:8080/api/products?page=1&limit=10"

# Test search with pagination
curl "http://localhost:8080/api/products?q=Samsung&page=1&limit=10"

# Test category filtering
curl "http://localhost:8080/api/products?category=Electronics&page=1&limit=10"

# Test price filtering
curl "http://localhost:8080/api/products?minPrice=100&maxPrice=500&page=1&limit=10"
```

## 🔧 Customization

### Modify Product Count
Edit the scripts to change `TOTAL_PRODUCTS`:
```javascript
// In generate-products.js
const TOTAL_PRODUCTS = 1000; // Generate 1,000 products instead

# In generate-products.sh
TOTAL_PRODUCTS=1000 # Generate 1,000 products instead
```

### Add More Categories/Products
Edit the arrays in the scripts to add more variety:
```javascript
const categories = [
  'Electronics', 'Clothing', 'Your New Category'
];
```

## 🚨 Prerequisites

1. **Backend running**: Make sure your Go backend is running on port 8080
2. **Database connected**: Ensure MongoDB is connected and accessible
3. **API accessible**: Test with `curl http://localhost:8080/api/products`

## 📈 Expected Results

After successful execution:
- ✅ 5,000 products in your database
- ✅ Realistic distribution across categories
- ✅ Proper pagination testing data
- ✅ Search functionality testing data
- ✅ Performance testing capabilities

## 🐛 Troubleshooting

### Connection Errors
```bash
# Check if backend is running
curl http://localhost:8080/api/products

# Check if MongoDB is connected
# Look for MongoDB connection logs in your backend
```

### Slow Performance
- Reduce `TOTAL_PRODUCTS` for testing
- Increase `BATCH_SIZE` in Node.js script
- Check your MongoDB performance

### Partial Success
- Scripts continue on individual failures
- Check the final success rate
- Individual product validation errors are normal (some random data might not pass validation)

## 🎯 Next Steps

After generating products:
1. **Test frontend pagination** - Browse through pages
2. **Test search functionality** - Search for brands, categories
3. **Performance testing** - Monitor app performance with large datasets
4. **API testing** - Test various API endpoints with realistic data
