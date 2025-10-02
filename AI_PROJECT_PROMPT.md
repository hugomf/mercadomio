### AI Prompt to Build an E-Commerce Platform: "MercadoMio"

**Project Overview:**

You are tasked with creating a modern, containerized e-commerce platform named "MercadoMio". The platform consists of a backend API, a customer-facing frontend application, an admin console, and a headless CMS for data management. The entire system will be orchestrated using Docker.

**Core Technologies:**

*   **Backend:** Go (Golang) with the Fiber web framework.
*   **Frontend:** Flutter (for cross-platform support: web, iOS, Android).
*   **Admin Console:** Flutter.
*   **Database:** MongoDB (for primary application data) and PostgreSQL (for the CMS).
*   **Cache:** Redis (for session management, cart data, etc.).
*   **Headless CMS:** Directus (backed by PostgreSQL).
*   **Containerization:** Docker and Docker Compose.

**Architectural Components & Requirements:**

**1. Docker Compose Setup (`docker-compose.yml`)**

Define a `docker-compose.yml` file to manage the following services:
*   `backend`: Builds from `./backend`, runs on port `8080`. Depends on `mongo` and `redis`.
*   `frontend`: Builds from `./frontend`, runs on port `3000`. Depends on `backend`.
*   `admin_console`: (Optional, if you build it) Builds from `./admin_console`.
*   `mongo`: Uses the `mongo:7` image.
*   `postgres`: Uses the `postgres:15` image.
*   `redis`: Uses the `redis/redis-stack:latest` image.
*   `directus`: Uses the `directus/directus:latest` image, runs on port `8055`, and connects to the `postgres` service. Configure it with basic admin credentials and enable CORS.

**2. Headless CMS (`Directus`)**

Configure Directus with the following data collections (schemas):

*   **`categories`**:
    *   `id`: Integer, Primary Key.
    *   `name`: String, Required.
    *   `description`: Text.
    *   `parent_id`: Integer (self-referencing foreign key to `categories.id`).
    *   `subcategories`: One-to-Many alias relationship based on `parent_id`.

*   **`products`**:
    *   `id`: Integer, Primary Key.
    *   `name`: String, Required.
    *   `description`: Text.
    *   `price`: Float, Required.
    *   `sku`: String.
    *   `category_id`: Integer (foreign key to `categories.id`), Required.
    *   `stock`: Integer, Required.
    *   `variants`: JSON (to store product variations like size or color).
    *   `images`: One-to-Many alias relationship to `directus_files`.

**3. Backend API (Go & Fiber)**

Create a Go application in the `/backend` directory.

*   **`main.go`**:
    *   Initialize connections to MongoDB and Redis using environment variables.
    *   Set up a Fiber app with a global error handler.
    *   Initialize and inject services (Product, Category, Cart, Search, Analytics) into the route handlers.
    *   Start the server on port `8080`.

*   **Data Models (`/models`)**:
    *   `product.go`: Define `Product` and `Variant` structs matching the MongoDB structure. Use `bson` tags.
    *   `category.go`: Define the `Category` struct with `bson` tags.

*   **API Routes (`/routes`)**:
    *   Use a `setup.go` file to orchestrate all routes.
    *   Implement CORS middleware.
    *   **Product Routes**:
        *   `GET /products`: List products (with pagination).
        *   `GET /products/:id`: Get a single product.
        *   `GET /products/search`: Search for products.
        *   `GET /products/category/:category`: Get products by category.
    *   **Category Routes**:
        *   `GET /categories`: Get all categories.
    *   **Cart Routes**:
        *   `GET /cart/:id`: Get a cart.
        *   `POST /cart/:id/add`: Add an item to the cart.
        *   `POST /cart/:id/remove`: Remove an item from the cart.
        *   `DELETE /cart/:id`: Clear the cart.
    *   **Analytics Routes**:
        *   `GET /analytics/summary`: Get an analytics summary.
    *   **Health Check**:
        *   `GET /health`: A simple health check endpoint.

*   **Services (`/services`)**:
    *   Implement the business logic for each domain (Products, Categories, Cart, etc.).
    *   `ProductService` and `CategoryService` should interact with the MongoDB database.
    *   `CartService` should use Redis for storing cart data.

**4. Frontend Application (Flutter)**

Create a Flutter application in the `/frontend` directory.

*   **`main.dart`**:
    *   Initialize the app using `GetMaterialApp` from the `get` package.
    *   Set up responsive breakpoints using the `responsive_framework` package.
    *   The main UI should be a `Scaffold` with a `BottomNavigationBar` for switching between the "Products" and "Cart" screens.
    *   The `AppBar` should display the store logo and name, and include a `CartIcon` widget that shows the number of items in the cart.

*   **Services / Controllers (`/services`)**:
    *   `CategoryService`: Fetches category data from the backend.
    *   `CartController`: Manages the state of the shopping cart using `GetX`.
    *   `ConfigService`: Manages application configuration.

*   **Widgets (`/widgets`)**:
    *   `ProductListingWidget`: The main widget on the home screen that displays a list or grid of products fetched from the backend.
    *   `CartScreen`: Displays the items in the cart, allows users to adjust quantities, and shows the total price.
    *   `CartIcon`: An icon (usually in the `AppBar`) that displays a badge with the current item count in the cart.

**5. Admin Console (Flutter)**

Create a placeholder Flutter application in the `/admin_console` directory. It should be a basic Flutter app that can be expanded later to include features for managing products, viewing orders, and checking analytics. For now, the default "counter app" template is sufficient as a starting point.
