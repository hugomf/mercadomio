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