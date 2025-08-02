# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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