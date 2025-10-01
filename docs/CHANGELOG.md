# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1/0/0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2025-10-01
### Added
- **Order Management Foundation**
  - **Order Model**: Complete order schema with status tracking and validation
  - **Order Status Management**: State machine for order lifecycle (pending → paid → shipped → completed)
  - **Order Validation**: Comprehensive data integrity checks and business rules
  - **Order Item Model**: Detailed order item structure with product references
  - **Test Suite**: TDD-validated order model tests ensuring proper validation and calculations

### Backend Improvements
- **Enhanced API Response Standards**: Consistent success/error response format across endpoints
- **Standardized Error Handling**: Unified error response structure with codes and messages
- **Paginated Response Support**: New pagination models for future list endpoints
- **Response Helper Functions**: Utility functions for consistent API responses

### Backend Improvements
- **Enhanced Category Filtering**: Fixed hierarchical category filtering to include parent/child category relationships
- **Category Hierarchy Support**: Products now correctly filter by parent categories including all child category products
- **Search Parameter Enhancement**: Added CategoryIDs field for efficient MongoDB ObjectID queries

### Testing & Documentation
- **Order Model Tests**: Comprehensive test coverage for order validation and transitions
- **TDD Implementation**: Test-first development approach for order functionality
- **Category Filter Tests**: Fixed and validated hierarchical category filtering
- **API Standards**: Documented response format guidelines for future endpoints

## [0.0.1] - 2025-10-01
### Added
- **Complete User Authentication System**
  - **JWT-based Authentication**: Secure token generation and validation using HMAC-SHA256
  - **User Registration & Login**: Complete user management with password hashing (bcrypt)
  - **User Types**: Support for individual and wholesale user accounts
  - **Profile Management**: User profile retrieval and updates via protected endpoints

### Backend (Go)
- **User Model**: Complete user schema with email, password hash, name, user type, rebate credits
- **Authentication Service**: Registration, login, profile operations with JWT token management
- **Authentication Middleware**: Route protection with required and optional auth patterns
- **Authentication Handlers**: RESTful API endpoints with proper validation and error handling
- **Secure Cart Endpoints**: Shopping cart modifications now require authentication
- **Environment Configuration**: JWT secret and database configuration support
- **Test Suite**: Comprehensive authentication tests for all auth operations

### Frontend (Flutter)
- **User Models**: Dart models matching backend schema with UserType enum
- **Authentication Service**: Reactive HTTP client with GetX state management
- **Authentication Guards**: Route protection widgets and conditional rendering
- **Login Screen**: Beautiful Material Design login/register interface with form validation
- **App Integration**: Protected main screen with user menu, logout functionality
- **Reactive State**: Real-time authentication state updates throughout the application

### API Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User authentication (returns JWT token)
- `GET /api/auth/profile` - Retrieve user profile (protected)
- `PUT /api/auth/profile` - Update user profile (protected)
- `GET /api/auth/verify` - Verify JWT token validity (protected)

### Security Features
- **Password Security**: Bcrypt hashing with default cost
- **Token Validation**: Secure JWT parsing and claims verification
- **Route Protection**: Middleware-based authentication enforcement
- **Error Handling**: Comprehensive error responses for auth failures
- **Input Validation**: Request validation for all auth endpoints

### Development Features
- **Demo Mode**: Configurable for development/testing environments
- **Fallback JWT Secret**: Development-friendly configuration
- **Comprehensive Tests**: Backend auth service test coverage
- **Environment Setup**: Proper .env configuration templates

## [1.2.1] - 2025-08-02
### Added
- **Enhanced Search Functionality**
  - **Real-time count updates** when searching for products like "Femenina"
  - **Temu-style clear search button** (rounded X icon) inside search field
  - **Search on Enter only** - no real-time typing triggers
  - **Proper count reset** when clearing search (shows "1677" instead of "0 of 1677")
  - **Combined search + category filtering** with consistent count display
  - **Clean count display format** ("1677" vs "X filtered products (of 1677)")

### Fixed
- **Search count display** now correctly shows filtered vs total counts
- **Count reset issue** when clearing search after zero results
- **Clear button visibility** with proper state management

### Frontend
- Enhanced `ProductListingWidget` with improved search UX
- Added StatefulBuilder for reactive clear button
- Updated search field decoration with rounded clear icon
- Improved error handling and state synchronization

## [1.2.0] - 2025-08-02
### Added
- **Compact Product Sorting Control**
  - Mobile-optimized 40x40px sorting button with PopupMenuButton
  - 4 sorting options: Price ascending (↑), Price descending (↓), Newest first, Oldest first
  - Real-time sorting without page reloads
  - Backend sorting integration with MongoDB queries
  - Full compatibility with existing search and category filters
  - Security field validation (name, basePrice, createdAt, updatedAt)

### Backend
- Added `sort` and `order` query parameters to `/api/products` endpoint
- Enhanced SearchService with sorting support
- Added ListProductsWithSort method to ProductService
- Updated SearchParams struct with SortBy/SortOrder fields

## [1.0.0] - 2025-08-02
### Added
- Initial stable release of MercadoMío e-commerce platform
- Fragment-based architecture for both backend and frontend
- Shopping cart implementation with Redis backend
- Product management system
- Directus CMS integration
- Basic branding and UI components
