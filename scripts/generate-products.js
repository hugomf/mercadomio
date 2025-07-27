#!/usr/bin/env node

const https = require('https');
const http = require('http');

// Configuration
const API_URL = process.env.API_URL || 'http://localhost:8080';
const TOTAL_PRODUCTS = 5000;
const BATCH_SIZE = 50; // Send products in batches to avoid overwhelming the server

// Realistic product data
const categories = [
  'Electronics', 'Clothing', 'Home & Garden', 'Sports & Outdoors', 'Books',
  'Health & Beauty', 'Toys & Games', 'Automotive', 'Food & Beverages', 'Office Supplies',
  'Pet Supplies', 'Jewelry', 'Music & Movies', 'Tools & Hardware', 'Baby & Kids'
];

const electronics = [
  'Smartphone', 'Laptop', 'Tablet', 'Headphones', 'Smart Watch', 'Camera', 'Speaker',
  'Monitor', 'Keyboard', 'Mouse', 'Charger', 'Power Bank', 'Smart TV', 'Gaming Console',
  'Drone', 'Fitness Tracker', 'Wireless Earbuds', 'Router', 'Hard Drive', 'Webcam'
];

const clothing = [
  'T-Shirt', 'Jeans', 'Dress', 'Jacket', 'Sweater', 'Shoes', 'Sneakers', 'Boots',
  'Hat', 'Scarf', 'Gloves', 'Socks', 'Underwear', 'Pajamas', 'Suit', 'Skirt',
  'Shorts', 'Hoodie', 'Coat', 'Sandals'
];

const homeGarden = [
  'Sofa', 'Chair', 'Table', 'Lamp', 'Curtains', 'Rug', 'Pillow', 'Blanket',
  'Plant Pot', 'Garden Tools', 'Watering Can', 'Seeds', 'Fertilizer', 'Outdoor Furniture',
  'Grill', 'Hose', 'Lawn Mower', 'Trimmer', 'Shovel', 'Rake'
];

const sportsOutdoors = [
  'Running Shoes', 'Yoga Mat', 'Dumbbell', 'Bicycle', 'Helmet', 'Backpack',
  'Tent', 'Sleeping Bag', 'Hiking Boots', 'Water Bottle', 'Protein Powder',
  'Resistance Bands', 'Basketball', 'Soccer Ball', 'Tennis Racket', 'Golf Clubs',
  'Fishing Rod', 'Camping Chair', 'Cooler', 'Sunglasses'
];

const books = [
  'Fiction Novel', 'Non-Fiction Book', 'Cookbook', 'Biography', 'Self-Help Book',
  'Children\'s Book', 'Textbook', 'Comic Book', 'Poetry Collection', 'Travel Guide',
  'History Book', 'Science Book', 'Art Book', 'Photography Book', 'Dictionary',
  'Encyclopedia', 'Journal', 'Notebook', 'Planner', 'Calendar'
];

const healthBeauty = [
  'Shampoo', 'Conditioner', 'Face Cream', 'Sunscreen', 'Toothbrush', 'Toothpaste',
  'Perfume', 'Makeup', 'Nail Polish', 'Hair Dryer', 'Electric Toothbrush',
  'Moisturizer', 'Cleanser', 'Serum', 'Mask', 'Vitamins', 'Supplements',
  'Essential Oils', 'Soap', 'Deodorant'
];

const productsByCategory = {
  'Electronics': electronics,
  'Clothing': clothing,
  'Home & Garden': homeGarden,
  'Sports & Outdoors': sportsOutdoors,
  'Books': books,
  'Health & Beauty': healthBeauty,
  'Toys & Games': ['Action Figure', 'Board Game', 'Puzzle', 'Doll', 'LEGO Set', 'Video Game', 'Toy Car', 'Stuffed Animal', 'Building Blocks', 'Art Supplies'],
  'Automotive': ['Car Parts', 'Motor Oil', 'Tire', 'Battery', 'Air Freshener', 'Car Cover', 'Jump Starter', 'Dash Cam', 'GPS', 'Car Charger'],
  'Food & Beverages': ['Coffee', 'Tea', 'Snacks', 'Pasta', 'Rice', 'Cereal', 'Juice', 'Water', 'Energy Drink', 'Protein Bar'],
  'Office Supplies': ['Pen', 'Pencil', 'Notebook', 'Stapler', 'Paper', 'Folder', 'Binder', 'Calculator', 'Desk Organizer', 'Printer'],
  'Pet Supplies': ['Dog Food', 'Cat Food', 'Pet Toy', 'Leash', 'Pet Bed', 'Litter Box', 'Pet Carrier', 'Collar', 'Pet Shampoo', 'Treats'],
  'Jewelry': ['Necklace', 'Ring', 'Earrings', 'Bracelet', 'Watch', 'Pendant', 'Brooch', 'Cufflinks', 'Anklet', 'Charm'],
  'Music & Movies': ['CD', 'DVD', 'Vinyl Record', 'Blu-ray', 'Headphones', 'Speakers', 'Microphone', 'Guitar', 'Piano', 'Drums'],
  'Tools & Hardware': ['Hammer', 'Screwdriver', 'Drill', 'Saw', 'Wrench', 'Pliers', 'Measuring Tape', 'Level', 'Screws', 'Nails'],
  'Baby & Kids': ['Baby Formula', 'Diapers', 'Baby Clothes', 'Stroller', 'Car Seat', 'High Chair', 'Baby Monitor', 'Pacifier', 'Baby Bottle', 'Toys']
};

const brands = [
  'Apple', 'Samsung', 'Nike', 'Adidas', 'Sony', 'LG', 'Dell', 'HP', 'Canon', 'Nikon',
  'Microsoft', 'Google', 'Amazon', 'IKEA', 'H&M', 'Zara', 'Uniqlo', 'Target', 'Walmart', 'Best Buy',
  'Generic', 'Premium', 'Pro', 'Elite', 'Classic', 'Modern', 'Vintage', 'Eco', 'Smart', 'Ultra'
];

const adjectives = [
  'Premium', 'Professional', 'Deluxe', 'Ultra', 'Super', 'Mega', 'Advanced', 'Smart',
  'Eco-Friendly', 'Wireless', 'Portable', 'Compact', 'Heavy-Duty', 'Lightweight',
  'Waterproof', 'Durable', 'Comfortable', 'Stylish', 'Modern', 'Classic'
];

// Generate random product
function generateProduct(index) {
  const category = categories[Math.floor(Math.random() * categories.length)];
  const productTypes = productsByCategory[category];
  const baseProduct = productTypes[Math.floor(Math.random() * productTypes.length)];
  const brand = brands[Math.floor(Math.random() * brands.length)];
  const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
  
  const name = Math.random() > 0.5 ? `${brand} ${adjective} ${baseProduct}` : `${adjective} ${baseProduct}`;
  
  // Generate realistic price based on category
  let basePrice;
  switch (category) {
    case 'Electronics':
      basePrice = Math.random() * 2000 + 50; // $50-$2050
      break;
    case 'Clothing':
      basePrice = Math.random() * 200 + 10; // $10-$210
      break;
    case 'Home & Garden':
      basePrice = Math.random() * 1000 + 20; // $20-$1020
      break;
    case 'Books':
      basePrice = Math.random() * 50 + 5; // $5-$55
      break;
    case 'Health & Beauty':
      basePrice = Math.random() * 100 + 5; // $5-$105
      break;
    default:
      basePrice = Math.random() * 500 + 10; // $10-$510
  }
  
  const sku = `${category.substring(0, 3).toUpperCase()}-${String(index).padStart(6, '0')}`;
  const barcode = `${Math.floor(Math.random() * 900000000) + 100000000}${String(index).padStart(4, '0')}`;
  
  const descriptions = [
    `High-quality ${baseProduct.toLowerCase()} perfect for everyday use.`,
    `Professional-grade ${baseProduct.toLowerCase()} with advanced features.`,
    `Durable and reliable ${baseProduct.toLowerCase()} built to last.`,
    `Stylish ${baseProduct.toLowerCase()} that combines form and function.`,
    `Premium ${baseProduct.toLowerCase()} designed for maximum performance.`
  ];
  
  return {
    name: name,
    description: descriptions[Math.floor(Math.random() * descriptions.length)],
    type: 'physical',
    category: category,
    basePrice: Math.round(basePrice * 100) / 100, // Round to 2 decimal places
    sku: sku,
    barcode: barcode,
    variants: [],
    customAttributes: {
      brand: brand,
      color: ['Black', 'White', 'Blue', 'Red', 'Green', 'Gray', 'Silver'][Math.floor(Math.random() * 7)],
      weight: `${(Math.random() * 10 + 0.1).toFixed(1)} lbs`,
      dimensions: `${Math.floor(Math.random() * 20 + 5)}" x ${Math.floor(Math.random() * 15 + 3)}" x ${Math.floor(Math.random() * 10 + 1)}"`
    },
    identifiers: {
      upc: barcode,
      model: `${brand}-${Math.floor(Math.random() * 9000 + 1000)}`
    }
  };
}

// Send HTTP request
function sendRequest(method, path, data) {
  return new Promise((resolve, reject) => {
    const url = new URL(API_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const client = url.protocol === 'https:' ? https : http;
    const req = client.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => responseData += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ statusCode: res.statusCode, data: responseData });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });

    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Main function
async function generateProducts() {
  console.log(`🚀 Starting to generate ${TOTAL_PRODUCTS} products...`);
  console.log(`📡 API URL: ${API_URL}`);
  console.log(`📦 Batch size: ${BATCH_SIZE}`);
  console.log('');

  let successCount = 0;
  let errorCount = 0;

  for (let i = 0; i < TOTAL_PRODUCTS; i += BATCH_SIZE) {
    const batchEnd = Math.min(i + BATCH_SIZE, TOTAL_PRODUCTS);
    const batchSize = batchEnd - i;
    
    console.log(`📦 Processing batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(TOTAL_PRODUCTS / BATCH_SIZE)} (products ${i + 1}-${batchEnd})`);
    
    const promises = [];
    for (let j = i; j < batchEnd; j++) {
      const product = generateProduct(j + 1);
      promises.push(
        sendRequest('POST', '/api/products', product)
          .then(() => {
            successCount++;
            if (successCount % 100 === 0) {
              console.log(`✅ Successfully created ${successCount} products`);
            }
          })
          .catch((error) => {
            errorCount++;
            if (errorCount <= 10) { // Only show first 10 errors to avoid spam
              console.error(`❌ Error creating product ${j + 1}:`, error.message);
            }
          })
      );
    }
    
    await Promise.all(promises);
    
    // Small delay between batches to be nice to the server
    if (i + BATCH_SIZE < TOTAL_PRODUCTS) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  console.log('');
  console.log('🎉 Product generation completed!');
  console.log(`✅ Successfully created: ${successCount} products`);
  console.log(`❌ Failed to create: ${errorCount} products`);
  console.log(`📊 Success rate: ${((successCount / TOTAL_PRODUCTS) * 100).toFixed(1)}%`);
}

// Run the script
if (require.main === module) {
  generateProducts().catch(console.error);
}
