# MercadoMío API Documentation

## Base URL
`https://api.mercadomio.mx/v1`

## Authentication
Currently uses simple API key authentication:
```
Authorization: Bearer {API_KEY}
```

## Endpoints

### Products
- `GET /products` - List all products
  - **Query Parameters:**
    - `page` (optional): Page number (default: 1)
    - `limit` (optional): Items per page (default: 20)
    - `q` (optional): Search query
    - `category` (optional): Category filter (comma-separated)
    - `minPrice` (optional): Minimum price filter
    - `maxPrice` (optional): Maximum price filter
    - `type` (optional): Product type filter
    - `sort` (optional): Sort field - `name`, `basePrice`, `createdAt`, `updatedAt` (default: `name`)
    - `order` (optional): Sort order - `asc`, `desc` (default: `asc`)
- `GET /products/:id` - Get product details
- `POST /products` - Create new product (admin only)
- `PUT /products/:id` - Update product (admin only)

### Cart
- `GET /cart/:cartId` - Get cart contents
- `POST /cart/:cartId/items` - Add item to cart
- `PUT /cart/:cartId/items/:productId` - Update item quantity
- `DELETE /cart/:cartId/items/:productId` - Remove item

### Users
- `POST /users/register` - Create new account
- `POST /users/login` - Authenticate user

## Error Codes
- 400 - Bad request
- 401 - Unauthorized
- 404 - Not found
- 500 - Server error

## Rate Limiting
100 requests/minute per IP address

## Examples
```javascript
// Get product list
fetch('https://api.mercadomio.mx/v1/products')
  .then(response => response.json())
  .then(products => console.log(products));

// Get products sorted by price ascending
fetch('https://api.mercadomio.mx/v1/products?sort=basePrice&order=asc')
  .then(response => response.json())
  .then(products => console.log(products));

// Get products sorted by newest first
fetch('https://api.mercadomio.mx/v1/products?sort=createdAt&order=desc')
  .then(response => response.json())
  .then(products => console.log(products));

// Get products with search and sorting
fetch('https://api.mercadomio.mx/v1/products?q=shirt&category=Electronics&sort=basePrice&order=desc')
  .then(response => response.json())
  .then(products => console.log(products));