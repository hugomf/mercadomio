#!/usr/bin/env node

const https = require('https');
const http = require('http');

// Configuration
const API_URL = process.env.API_URL || 'http://192.168.64.73:8080';
const BATCH_SIZE = 50; // Delete products in batches

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
          try {
            const parsed = responseData ? JSON.parse(responseData) : {};
            resolve({ statusCode: res.statusCode, data: parsed });
          } catch (e) {
            resolve({ statusCode: res.statusCode, data: responseData });
          }
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

// Get all products with pagination
async function getAllProducts() {
  console.log('📋 Fetching all products...');
  let allProducts = [];
  let page = 1;
  let hasMore = true;
  
  while (hasMore) {
    try {
      const response = await sendRequest('GET', `/api/products?page=${page}&limit=100`);
      const data = response.data;
      
      if (data.data && data.data.length > 0) {
        allProducts = allProducts.concat(data.data);
        console.log(`📦 Fetched page ${page}: ${data.data.length} products (total: ${allProducts.length})`);
        
        // Check if there are more pages
        const totalPages = data.meta?.totalPages || Math.ceil(data.meta?.totalItems / 100) || 1;
        hasMore = page < totalPages;
        page++;
      } else {
        hasMore = false;
      }
    } catch (error) {
      console.error(`❌ Error fetching page ${page}:`, error.message);
      hasMore = false;
    }
  }
  
  return allProducts;
}

// Delete products in batches
async function deleteProducts(products) {
  console.log(`🗑️  Starting to delete ${products.length} products...`);
  
  let successCount = 0;
  let errorCount = 0;
  
  for (let i = 0; i < products.length; i += BATCH_SIZE) {
    const batch = products.slice(i, i + BATCH_SIZE);
    const batchNumber = Math.floor(i / BATCH_SIZE) + 1;
    const totalBatches = Math.ceil(products.length / BATCH_SIZE);
    
    console.log(`🗂️  Processing batch ${batchNumber}/${totalBatches} (${batch.length} products)`);
    
    const promises = batch.map(async (product) => {
      try {
        await sendRequest('DELETE', `/api/products/${product.id}`);
        successCount++;
        return { success: true, id: product.id };
      } catch (error) {
        errorCount++;
        return { success: false, id: product.id, error: error.message };
      }
    });
    
    const results = await Promise.all(promises);
    
    // Show progress
    if (successCount % 100 === 0 || i + BATCH_SIZE >= products.length) {
      console.log(`✅ Deleted ${successCount} products so far...`);
    }
    
    // Small delay between batches
    if (i + BATCH_SIZE < products.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  return { successCount, errorCount };
}

// Confirm deletion
function confirmDeletion() {
  return new Promise((resolve) => {
    const readline = require('readline');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    rl.question('⚠️  This will DELETE ALL PRODUCTS from your database. Are you sure? (yes/no): ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y');
    });
  });
}

// Main function
async function clearAllProducts() {
  console.log('🧹 Product Cleanup Tool');
  console.log(`📡 API URL: ${API_URL}`);
  console.log('');
  
  // Check if we can connect to the API
  try {
    console.log('🔍 Checking API connection...');
    await sendRequest('GET', '/api/products?page=1&limit=1');
    console.log('✅ API connection successful');
  } catch (error) {
    console.error('❌ Cannot connect to API:', error.message);
    console.error('💡 Make sure your backend is running and accessible');
    process.exit(1);
  }
  
  // Get all products first
  const products = await getAllProducts();
  
  if (products.length === 0) {
    console.log('✨ No products found in database. Nothing to delete!');
    return;
  }
  
  console.log('');
  console.log(`📊 Found ${products.length} products in database`);
  console.log('');
  
  // Confirm deletion
  const confirmed = await confirmDeletion();
  
  if (!confirmed) {
    console.log('❌ Deletion cancelled by user');
    return;
  }
  
  console.log('');
  console.log('🚀 Starting deletion process...');
  
  // Delete all products
  const { successCount, errorCount } = await deleteProducts(products);
  
  console.log('');
  console.log('🎉 Cleanup completed!');
  console.log(`✅ Successfully deleted: ${successCount} products`);
  console.log(`❌ Failed to delete: ${errorCount} products`);
  console.log(`📊 Success rate: ${((successCount / products.length) * 100).toFixed(1)}%`);
  
  if (errorCount > 0) {
    console.log('');
    console.log('💡 Some products may have failed to delete due to:');
    console.log('   - Network timeouts');
    console.log('   - Products being referenced by other entities');
    console.log('   - Database constraints');
    console.log('   - API rate limiting');
  }
}

// Run the script
if (require.main === module) {
  clearAllProducts().catch((error) => {
    console.error('💥 Fatal error:', error.message);
    process.exit(1);
  });
}
