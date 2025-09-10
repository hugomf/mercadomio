# Admin Console

Modern administrative interface for MercadoMio with responsive design and accessibility features.

## Features

- **Collapsible Navigation**:
  - Quick Actions section (⚡)
  - Admin Section (⚙️) with subsections:
    - Catalog Management (📋)
    - Product Management (🛍️)
    - Inventory (📦)
    - User Management (👥)
    - Settings (⚙️)

- **Responsive Design**:
  - Adapts to mobile, tablet and desktop screens
  - Hamburger menu toggle (☰) for small screens
  - Collapsible to icons-only mode

- **Theme Support**:
  - Light/dark mode toggle
  - System preference detection
  - Smooth theme transitions

- **Accessibility**:
  - Keyboard navigation
  - ARIA labels
  - Focus management
  - Proper contrast ratios

## Technical Details

### Widget Structure

- `NavigationDrawer`: Main collapsible navigation component
- `AdminConsoleHome`: Scaffold with responsive layout
- Theme configuration in `main.dart`

### Data Binding

Aligns with backend models:
- Product management
- Inventory tracking
- User management (pending API integration)

## Usage

1. Toggle navigation collapse with the header button
2. Switch themes using the theme toggle in app bar
3. Navigate between sections using keyboard or mouse

## Requirements

- Flutter 3.0+
- Material 3 design system

## Environment Configuration

The app uses environment variables for configuration. Create a `.env` file in the root directory based on the `.env.example` template:

```bash
# Copy the example file
cp .env.example .env

# Edit the configuration
nano .env  # or use your preferred editor
```

### Available Environment Variables:

- `API_BASE_URL`: Backend API endpoint (default: http://localhost:8080/api)
- `APP_ENV`: Application environment (development, staging, production)
- `ENABLE_ANALYTICS`: Enable analytics tracking (true/false)
- `ENABLE_DEBUG_LOGGING`: Enable debug logging (true/false)

### Configuration Service

Access environment variables through the [`ConfigService`](lib/services/config_service.dart:1):

```dart
String apiUrl = ConfigService.apiBaseUrl;
bool isDevelopment = ConfigService.isDevelopment;
bool analyticsEnabled = ConfigService.enableAnalytics;
```

### Git Ignore

The `.env` file is excluded from version control to protect sensitive configuration. The `.env.example` file serves as a template for required environment variables.
