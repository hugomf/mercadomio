# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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