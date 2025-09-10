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
