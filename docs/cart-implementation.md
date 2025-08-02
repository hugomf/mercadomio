# Shopping Cart Implementation Guide

## Overview

This document describes the complete shopping cart implementation for the Mercado Mío e-commerce application, including both backend and frontend components.

## Architecture

The shopping cart system consists of:

### Backend (Go)
- **Redis-based storage** for high performance and session management
- **Event-driven architecture** with cart abandonment tracking
- **RESTful API** endpoints for cart operations
- **Automatic cleanup** of expired carts

### Frontend (Flutter)
- **GetX state management** for reactive updates
- **Real-time cart synchronization** with backend
- **Rich UI components** for cart management
- **Offline capability** with optimistic updates

## Backend Components

### 1. Cart Service (`backend/services/cart_service.go`)
- **Storage**: Redis with configurable TTL
- **Events**: Cart abandonment, item added/removed/updated
- **Cleanup**: Background routine for expired carts
- **Merge**: Guest cart merging with user cart

### 2. Cart Handlers (`backend/handlers/cart_handlers.go`)
- **GET** `/api/cart/:cartId` - Get cart contents
- **POST** `/api/cart/:cartId/items` - Add item to cart
- **PUT** `/api/cart/:cartId/items/:productId` - Update item quantity
- **DELETE** `/api/cart/:cartId/items/:productId` - Remove item from cart
- **POST** `/api/cart/merge` - Merge guest cart with user cart

### 3. Data Models (`backend/services/models.go`)
- **Cart**: Container for cart items
- **CartItem**: Individual cart item with product and quantity

## Frontend Components

### 1. Cart Service (`frontend/lib/services/cart_service.dart`)
- **REST API integration** with backend
- **Product enrichment** with detailed information
- **Error handling** and retry logic
- **Cart ID management** for guest/users

### 2. Cart Controller (`frontend/lib/services/cart_controller.dart`)
- **GetX controller** for state management
- **Reactive updates** with Rx observables
- **Loading states** and error handling
- **Real-time sync** with backend

### 3. UI Components
- **CartScreen**: Full cart management interface
- **CartIcon**: Badge showing item count
- **ProductListingWidget**: Add to cart functionality

## Usage

### Adding to Cart
```dart
final cartController = Get.find<CartController>();
cartController.addToCart(
  productId: 'product-123',
  quantity: 2,
);
```

### Getting Cart Contents
```dart
final cart = cartController.cart.value;
print('Total items: ${cart?.itemCount}');
print('Total price: \$${cart?.total.toStringAsFixed(2)}');
```

### Updating Quantity
```dart
cartController.updateQuantity(
  productId: 'product-123',
  quantity: 3,
);
```

### Removing Items
```dart
cartController.removeFromCart(productId: 'product-123');
```

## Configuration

### Environment Variables
```bash
# Frontend
API_URL=http://localhost:8080

# Backend
REDIS_URL=localhost:6379
CART_TTL_ACTIVE=24h
CART_TTL_ABANDONED=7d
```

### Cart TTL Configuration
- **Active cart**: 24 hours (configurable)
- **Abandoned cart**: 7 days (configurable)
- **Cleanup interval**: 1 hour

## Testing

### Backend Tests
```bash
cd backend
go test ./services/ -v
```

### Frontend Tests
```bash
cd frontend
flutter test lib/test/cart_test.dart
```

### Manual Testing
1. Start backend server: `make run-backend`
2. Start frontend: `flutter run`
3. Navigate to products page
4. Add items to cart
5. View cart and modify quantities
6. Test cart persistence across sessions

## Features

### ✅ Implemented
- Add items to cart
- Update item quantities
- Remove items from cart
- View cart contents
- Calculate totals
- Real-time updates
- Cart persistence
- Guest cart support
- Cart merging
- Event tracking

### 🔄 Next Phase
- User authentication integration
- Checkout process
- Payment integration
- Order management
- Inventory validation
- Promotions and discounts
- Wishlist integration

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cart/:cartId` | Get cart contents |
| POST | `/api/cart/:cartId/items` | Add item to cart |
| PUT | `/api/cart/:cartId/items/:productId` | Update item quantity |
| DELETE | `/api/cart/:cartId/items/:productId` | Remove item from cart |
| POST | `/api/cart/merge` | Merge guest cart with user cart |

## Error Handling

### Backend
- Validation errors with clear messages
- Product existence validation
- Quantity validation (positive integers)
- Cart ID validation

### Frontend
- Network error handling
- Retry mechanisms
- User-friendly error messages
- Loading states

## Security Considerations

- Input validation on all endpoints
- Rate limiting for cart operations
- Secure cart ID generation
- XSS prevention in frontend

## Performance Optimizations

- Redis caching for fast access
- Batch product loading
- Optimistic UI updates
- Lazy loading of product images

## Monitoring

- Cart abandonment events
- Cart value tracking
- Error rate monitoring
- Performance metrics