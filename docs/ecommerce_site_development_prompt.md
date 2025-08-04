

# Ecommerce Site Development Prompt

## Objective
Create a scalable, user-friendly ecommerce website/app for selling a variety of products (physical goods like gadgets, clothes, shoes; services like consultancies; and subscriptions like phone plans with 3GB for 1 month or 10GB for 15 days) targeting teens, mature women, and men in Mexico. The site must use **Golang** for a robust backend, **Flutter** for a mobile-first frontend, and **MongoDB** as the sole NoSQL database to ensure flexibility, scalability, and rapid development. Implement a **plugin-based architecture** inspired by portlets, where features (e.g., product listing, search, cart, payments, pricing) are modular, pluggable components—backend plugins (Golang interfaces) and frontend widget plugins (Flutter)—to adhere to the **Open/Closed Principle (OCP)**. Model products to support diverse types, variants (e.g., color, size, duration), dynamic attributes (e.g., material, data limit), and standard identifiers (e.g., SKUs, barcodes), with a flexible pricing model supporting uniform pricing, variant-specific pricing, campaigns/seasonal promotions, customer-specific pricing (e.g., wholesale vs. individual), discounts (percentage or fixed), and rebates (post-purchase credits). Use a hybrid pricing approach (embedded in products for MVP, separated with a custom Golang-based rule engine for future rules) to prepare for new pricing models without complex BPM tools like Drools. The system must be developer-friendly for a software engineer proficient in Java, Golang, React, and Flutter, while providing an intuitive interface for a non-technical user (e.g., a spouse) to manage products, prices, rules, orders, and plugins. The project should be developed by a team of 1-2 developers with AI assistance generating ~70-80% of the code (backend plugins, frontend widgets, configurations, tests) and providing guidance, using additional tools (e.g., GitHub Copilot, fiber, GetX, Directus) to achieve a fast timeline (7-9 weeks for 1 developer, 4-5 weeks for 2 developers) with clear phases and milestones to ensure rapid delivery and scalability, given uncertainty about the app’s success.

## Requirements

### General
- **Target Audience:** Teens, mature women, and men in Mexico, with a focus on broad appeal and mobile-first design (90%+ of Mexican ecommerce traffic is mobile).
- **Timeline:** Deliver MVP in 7-9 weeks (1 developer) or 4-5 weeks (2 developers), with iterative enhancements planned post-launch, leveraging AI-generated code (~70-80%) and enhanced tools.
- **Branding:** Incorporate a unique, Mexican-inspired name (e.g., TiendaFiesta, CompraMex, MercadoMío, RápidoCompra, or TandaShop) that is not already in use. Ensure domain availability (e.g., .mx) and a vibrant, culturally resonant design.
- **Language:** Primary language is Spanish, with English as an optional secondary language.

### Technical
- **Backend:** Use **Golang** with **fiber** (or Gin/Fiber as fallback) frameworks for a lightweight, high-performance, API-driven backend. Implement a **plugin architecture** where features (e.g., product listing, search, cart, payments, pricing) are modular plugins, each defined by a `Plugin` interface (e.g., `Init()`, `Execute()`, `Shutdown()`). Use a **plugin registry** with static imports for simplicity in the MVP. Integrate **MongoDB** using the `mongo-go-driver` for flexible schema design, storing plugin configurations, product data, and pricing rules in `plugins`, `products`, and `pricingRules` collections. Use **Redis Stack** for caching (e.g., product listings, cart sessions) and JSON/search capabilities, with **Redis Pub/Sub** or **RabbitMQ** for event-driven communication between plugins (e.g., `OrderPlaced` event). Apply **dependency injection** to ensure OCP compliance, allowing new plugins (e.g., pricing rules) without modifying core logic. Use **go-playground/validator** for input validation.
- **Frontend:** Use **Flutter** with **GetX** (or Provider/Riverpod) for state management to create a mobile-first app with web support. Implement features as **visual plugin widgets** (e.g., `ProductListingWidget`, `SearchWidget`, `CartWidget`, `VariantSelectorWidget`, `PriceDisplayWidget`), managed by a **widget registry** (configured via MongoDB) and inspired by portlets. Each widget is reusable, configurable, and fetches data from backend APIs, using **Dio** for HTTP requests and **cached_network_image** for optimized image loading. Use static widget imports for the MVP, with plans for dynamic loading (e.g., code-push via Firebase) post-MVP.
- **CMS:** Integrate **Directus** (or Strapi) with MongoDB support for non-technical users to manage products, variants, dynamic attributes, pricing, rules (discounts, rebates), and plugin/widget configurations via an intuitive dashboard. Use dynamic collections/JSON fields for extensibility (e.g., analytics dashboard). Use **MongoDB Charts** for sales/rebate dashboards.
- **Alternative Option:** Consider **React** with **Next.js** and **Tailwind CSS** for rapid web development, with modular components as visual plugins, ensuring OCP via dependency injection and a component registry.
- **Hosting:** Deploy backend on **Render** (or AWS/DigitalOcean) with MongoDB Atlas and Redis Stack. Host Flutter app/web on **Firebase** or **Vercel**. Use **Docker** and **Kubernetes** for containerized deployment, with **Terraform** for infrastructure automation in Phase 5 or post-MVP.
- **Development Tools:**
  - **AI Tools:** Use **GitHub Copilot** for code completion, **Claude** for supplementary code/documentation, and **ChatGPT** for UI/marketing content.
  - **Libraries:** Use `go-playground/validator` (Golang), `jsonparser` (MongoDB JSON), `GetX`, `Dio`, `cached_network_image` (Flutter).
  - **Testing/DevOps:** Use **Postman** for API testing, **Figma** for UI prototyping, **Sentry** for error tracking, **Adminer** for MongoDB management, and **GitHub Actions** for CI/CD.
  - Write **unit tests** and **integration tests** (using Go’s `testing` package and Flutter’s testing tools) for plugins/widgets to ensure reliability.

### Product Modeling
- **Core Model:** Design a flexible MongoDB schema in the `products` collection to support diverse product types (physical goods, services, subscriptions) with:
  - **Base Attributes:** `name`, `description`, `type` (e.g., "physical", "service", "subscription"), `category`, `basePrice`, `sku`, `barcode`.
  - **Variants:** Array of variants with `variantId`, `attributes` (e.g., color, size, duration), `priceAdjustment`, `sku`, `barcode`, and `stock` (0 for services/subscriptions).
  - **Dynamic Attributes:** A `customAttributes` object for extensible fields (e.g., "material", "dataLimit", "warranty", "discount", "rebate").
  - **Identifiers:** Support SKUs and barcodes at product and variant levels, with flexibility for custom IDs (e.g., ISBN) via `customAttributes` or a dedicated `identifiers` field.
- **Product Types:**
  - **Physical Products:** Support variants (e.g., color, size) with stock tracking. Example: T-shirt with variants for size (S, M, L) and color (Red, Blue), each with unique SKU and price adjustment.
  - **Services:** No stock; use `customAttributes` for details (e.g., "duration": "1 hour"). Example: Consultancy session with customizable expertise.
  - **Subscriptions:** Use variants for plan options (e.g., "3GB for 1 month", "10GB for 15 days") with recurring billing logic. Example: Phone plan with data limit and duration attributes.
- **Management:** Allow non-technical users to add products, variants, and dynamic attributes via Directus/Strapi’s content type builder (e.g., JSON field for `customAttributes`). Generate SKUs automatically or allow manual input.
- **Plugin Integration:** Implement product types and features as plugins (e.g., `PhysicalProductPlugin`, `VariantPlugin`) with corresponding Flutter widgets (e.g., `VariantSelectorWidget`). Use events (e.g., `ProductUpdated`) to sync plugins.

### Pricing Model
- **MVP (Integrated Pricing):** Embed pricing in the `products` collection:
  - **Base Price:** `basePrice` for the product (e.g., 200 MXN for a T-shirt).
  - **Variant Pricing:** `priceAdjustment` for variants (e.g., +50 MXN for XL, +100 MXN for 10GB plan).
  - **Discounts:** Use `customAttributes.discount` for simple discounts (e.g., 10% off for a campaign, 50 MXN off for orders over 1000 MXN).
  - **Rebates:** Use `customAttributes.rebate` for post-purchase incentives (e.g., 100 MXN credit for next purchase). Log rebates in orders for processing.
  - **Customer-Specific Pricing:** Use `customAttributes.wholesaleDiscount` for wholesale customers, validated by the `UserPlugin`.
  - **Logic:** Calculate final price as `basePrice + variant.priceAdjustment - customAttributes.discount`. Example: T-shirt with base price 200 MXN, +50 MXN for XL, -20 MXN for a promotion, with a 100 MXN rebate logged.
- **Post-MVP (Separated Pricing with Custom Rule Engine):** Plan a `pricingRules` collection for advanced scenarios:
  - **Schema:**
    ```json
    {
      "_id": ObjectId,
      "productId": ObjectId,
      "variantId": String,
      "ruleType": String, // e.g., "discount", "rebate", "wholesale", "seasonal"
      "conditions": {
        "startDate": Date,
        "endDate": Date,
        "customerType": String, // e.g., "wholesale", "individual"
        "minQuantity": Number, // e.g., 10
        "category": String // e.g., "Electronics"
      },
      "action": {
        "type": String, // e.g., "percentage_discount", "fixed_discount", "rebate_credit"
        "value": Number // e.g., 20% or 50 MXN for discounts, 100 MXN for rebates
      },
      "priority": Number // Resolve conflicts
    }
    ```
  - **Rule Engine:** Implement a lightweight Golang-based rule engine in the `PricingPlugin` (custom structs) to evaluate rules based on conditions (e.g., `user.type == wholesale`, `quantity >= 10`). Apply discounts at checkout and log rebates for post-purchase processing (e.g., store credit in `users` collection). Plan for integration of `grule-rule-engine` post-MVP if needed.
  - **Logic:** Combine `basePrice`, `variant.priceAdjustment`, and applicable rules from `pricingRules` (highest priority wins). Example: 20% discount on electronics during Black Friday, 100 MXN rebate for wholesale orders.
- **Plugin Integration:** Implement a `PricingPlugin` with a `CalculatePrice(product, variant, user, context)` method to handle MVP pricing (embedded) and future dynamic rules (via `pricingRules`). Use a `PriceDisplayWidget` in Flutter to show prices and rebates dynamically. Implement a `RebatePlugin` for post-purchase rebate processing (e.g., issue credits via MongoDB or refunds via Mercado Pago).
- **Management:** Allow non-technical users to manage prices, discounts, and rebates via Directus/Strapi’s `Product` content type (MVP) and a future `PricingRule` content type (post-MVP) with fields for conditions and actions. Use JSON fields for flexibility.

### Time and Effort Estimation
- **Team:** 1-2 developers (proficient in Java, Golang, React, Flutter) with AI assistance generating ~70-80% of code (backend plugins, frontend widgets, configurations, tests) and providing guidance, enhanced by tools like GitHub Copilot, fiber, GetX, and Directus.
- **Total Timeline (MVP):**
  - **1 Developer:** 7-9 weeks (~280-360 hours).
  - **2 Developers:** 4-5 weeks (~160-200 hours per developer, ~320-400 hours total).
  - **AI and Tool Assistance:** AI generates ~70-80% of code, and tools (Copilot, fiber, GetX, Directus) reduce coding time by ~50-60% (~3-4 weeks saved for 1 developer, ~2-3 weeks for 2 developers).
- **Phased Development Plan:**
  - **Phase 1: Planning and Setup (0.5-1 week, 20-30 hours)**
    - **Tasks:** Define architecture, set up Git, CI/CD (GitHub Actions), MongoDB schemas (`products`, `users`, `orders`), Directus/Strapi, Redis Stack, and development environment. Use Figma for UI mockups and Adminer for MongoDB management.
    - **AI Assistance:** Generate MongoDB schemas, Golang plugin interfaces (fiber), Flutter widget templates (GetX), Directus/Strapi setup scripts, and Dockerfiles (~80% of setup code).
    - **Tools:** GitHub Copilot for setup scripts, Figma for UI planning, Adminer for MongoDB.
    - **Milestone:** Project setup complete, Directus/Strapi connects to MongoDB, initial code committed.
    - **Proceed When:** Developer confirms setup is functional (e.g., Directus/Strapi UI works, local dev environment runs).
  - **Phase 2: Core Backend Development (1.5-2 weeks for 1 developer, 1 week for 2 developers, 50-80 hours)**
    - **Tasks:** Implement `ProductPlugin`, `PricingPlugin` (with custom rule engine for embedded discounts/rebates), `UserPlugin`, and APIs using fiber. Set up MongoDB/Redis Stack. Use `go-playground/validator` for input validation.
    - **AI Assistance:** Generate plugin code, API handlers, MongoDB queries, and unit tests (~80% of backend code).
    - **Tools:** Copilot for code completion, Postman for API testing, Sentry for error tracking.
    - **Milestone:** Backend APIs are functional, passing unit tests, integrated with MongoDB/Redis.
    - **Proceed When:** Developer tests APIs (e.g., via Postman) and confirms product creation, pricing calculations, and authentication work.
  - **Phase 3: Core Frontend Development (1.5-2 weeks for 1 developer, 1 week for 2 developers, 50-80 hours)**
    - **Tasks:** Implement Flutter widgets (`ProductListingWidget`, `SearchWidget`, `CartWidget`, `VariantSelectorWidget`, `PriceDisplayWidget`) with GetX. Connect to APIs using Dio. Optimize images with `cached_network_image`. Build basic admin panel or use Directus/Strapi UI.
    - **AI Assistance:** Generate widget code, API integration logic, state management, and widget tests (~80% of frontend code).
    - **Tools:** Copilot for widget completion, Figma for styling, Sentry for error tracking.
    - **Milestone:** Frontend displays products, supports variant selection, shows prices/rebates, and enables admin tasks.
    - **Proceed When:** Developer tests app on iOS/Android simulators and confirms UI functionality and API integration.
  - **Phase 4: Integration and Testing (1-1.5 weeks, 40-60 hours)**
    - **Tasks:** Integrate payment gateways (Mercado Pago, OpenPay) via `PaymentPlugin`. Implement `RebatePlugin`. Conduct integration and end-to-end tests. Fix bugs using Sentry.
    - **AI Assistance:** Generate payment integration code, test scripts, and debugging guidance (~70% of integration code).
    - **Tools:** Postman for API testing, Sentry for error tracking.
    - **Milestone:** App supports end-to-end flows (browse, select variants, checkout, apply discounts/rebates) with passing tests.
    - **Proceed When:** Developer confirms all core features work, payments process, and tests pass.
  - **Phase 5: Deployment and Admin Setup (0.5-1 week, 20-30 hours)**
    - **Tasks:** Deploy backend on Render (or AWS/DigitalOcean) with MongoDB Atlas and Redis Stack. Deploy Flutter app/web on Firebase/Vercel. Configure Docker/Kubernetes with Terraform (optional). Set up Directus/Strapi for management. Write admin guide with MongoDB Charts for dashboards.
    - **AI Assistance:** Generate Dockerfiles, Kubernetes/Terraform configs, Directus/Strapi scripts, and admin guide (~80% of deployment configs).
    - **Tools:** Render for hosting, MongoDB Charts for dashboards, ChatGPT for admin guide content.
    - **Milestone:** App is live, Directus/Strapi is accessible, and non-technical user can manage products/prices.
    - **Proceed When:** Developer confirms deployment is stable and non-technical user can perform tasks.
  - **Phase 6: Post-MVP Enhancements (Optional, 2-4 weeks, 80-160 hours)**
    - **Tasks:** Implement `pricingRules` collection, enhance rule engine, add plugins (e.g., WhatsApp, reviews), explore dynamic plugin loading.
    - **AI Assistance:** Generate code for new plugins, rule engine enhancements, and integrations (~70% of code).
    - **Tools:** Redis Stack for advanced caching/search, Terraform for scaling.
    - **Milestone:** New features are live, dynamic rules manageable via Directus/Strapi.
    - **Proceed When:** Developer decides to scale based on app success.

### Workflow with AI Assistance
- **Code Generation:** AI provides complete, production-ready code (e.g., Golang plugins, Flutter widgets, MongoDB schemas, Directus/Strapi configs) for each phase, covering ~70-80% of development, tailored to requirements. GitHub Copilot enhances code customization.
- **Implementation:** Developers integrate code, customize as needed (e.g., business-specific logic, UI styling), and run tests, using Postman and Sentry for validation.
- **Checkpoints:** After each phase, developers share progress (e.g., test results, deployed app status, Git repository link). AI reviews and confirms milestones or suggests fixes for issues (e.g., bugs, integration errors).
- **Phase Transition:** AI advises moving to the next phase when milestones are met (e.g., APIs work, UI is functional, deployment is stable). If blockers arise, AI provides updated code or guidance.
- **Feedback Loop:** Developers report blockers or customization needs; AI generates revised code or solutions to ensure progress.

## Working Agreement with AI


To ensure clarity and consistency throughout the development process, follow these working rules:

- **Phased Execution:**  
  The coding and design work will be divided into clearly defined **phases** (see: Phased Development Plan).  
  👉 You will manually confirm when to **begin each phase**.

- **Solution Persistence:**  
  ChatGPT will **persist the same solution structure** (e.g., plugins, schema) once generated. Future changes will only happen **if explicitly requested** by you.  
  👉 Avoid suggesting new methods unless asked.

- **Step-by-Step for Large Phases:**  
  If a phase is too long to fit in one message, it will be divided into **manageable steps**.  
  👉 You will **confirm when to proceed** to the next step.

- **Recap and Confirm:**  
  After each step or phase, ChatGPT will present a short **recap**, and wait for confirmation before continuing.

- **Documentation Included:**  
  Each deliverable includes light, readable documentation to support onboarding and reuse.

### Features (MVP)
- **Product Listing Plugin:** Display products with images, descriptions, prices, categories, variants, and rebates, stored in MongoDB. Implement as a backend `ProductPlugin` and frontend `ProductListingWidget`, extensible for new product types or layouts.
- **Search Plugin:** Provide basic product search using MongoDB’s text index or Redis Stack (including `customAttributes`), implemented as a `SearchPlugin` and `SearchWidget`, extensible for advanced search (e.g., Elasticsearch).
- **Cart Plugin:** Implement a simple cart with checkout, using a `CartPlugin` and `CartWidget`, storing data in MongoDB and supporting extensions (e.g., discount codes, rebate logging).
- **Payment Plugin:** Integrate Mexico-friendly payment gateways (**Mercado Pago**, **OpenPay**) with a `PaymentPlugin` interface, supporting cards and cash payments (e.g., OXXO), extensible for new providers.
- **User Accounts Plugin:** Provide basic login and order history, using a `UserPlugin` with JWT-based authentication and MongoDB storage, extensible for features like loyalty programs or rebate credits.
- **Pricing Plugin:** Calculate prices based on `basePrice`, `variant.priceAdjustment`, and `customAttributes.discount/rebate`, with a `PriceDisplayWidget` for dynamic UI updates, extensible for `pricingRules` post-MVP.
- **Rebate Plugin:** Log and process rebates (e.g., store credits, refunds) post-purchase, integrated with `UserPlugin` and payment gateways.
- **Mobile Optimization:** Leverage Flutter’s native-like performance with GetX and `cached_network_image` for a seamless mobile experience, with adaptive layouts for web and pluggable widgets for extensibility.
- **Basic SEO:** Optimize for local keywords (e.g., "comprar gadgets en México") using metadata and structured data, supported by a `SEOPlugin` and Flutter’s web capabilities or Next.js (if used).

### Nice-to-Have Features
- **WhatsApp Integration Plugin:** Use **WhatsApp Business API** (via **Twilio**) for order notifications and customer support, implemented as a `NotificationPlugin` and `NotificationWidget` with MongoDB for logs, extensible for new channels (e.g., SMS).
- **Future Enhancements:** Plan for plugins like product reviews, personalized recommendations (using MongoDB’s aggregation or ML), loyalty programs, analytics, and advanced pricing rules (via `pricingRules` and rule engine), implemented as new plugins/widgets or event subscribers without modifying core code.

### Management
- Ensure non-technical users can update products, variants, dynamic attributes, prices, discounts, rebates, rules, and plugin/widget configurations via Directus/Strapi’s user-friendly dashboard (connected to MongoDB) or a custom Flutter admin panel with pluggable widgets like `ProductEditorWidget` and `PriceEditorWidget`. Use MongoDB Charts for sales/rebate dashboards.
- Provide clear documentation (AI-generated via Claude/ChatGPT) for managing the CMS, plugins/widgets, products, prices, discounts, rebates, and rules, with MongoDB Atlas’s interface for basic monitoring.

### Marketing & Traffic
- **SEO:** Optimize for Mexican search terms and local shopping trends, using **Google Search Console** for monitoring, extensible via a `SEOPlugin`. Use ChatGPT for content generation.
- **Social Media:** Support integration with Instagram, Facebook, and TikTok for product promotion, with Flutter widgets for social sharing, designed as pluggable components.
- **Paid Ads:** Enable setup for **Google Ads** or **Meta Ads** targeting diverse audiences, with tracking via an `AnalyticsPlugin` using Golang APIs and MongoDB.
- **Email Marketing:** Include email capture for campaigns, using **SendGrid** integrated with a `MarketingPlugin` for future extensions, with content generated by ChatGPT.

### Constraints
- Avoid payment gateways with complex setup in Mexico (e.g., Stripe).
- Ensure the platform is low-maintenance for non-technical users, with robust error handling and logging (via Sentry) in Golang and MongoDB. Keep plugin/widget architecture, product modeling, and pricing simple in the MVP (static imports, embedded pricing, lightweight Golang rule engine) to avoid complexity, given uncertainty about the app’s success.
- Prioritize frameworks (fiber, Flutter/GetX, MongoDB) and tools (Copilot, Directus, Redis Stack) for rapid development, ensuring scalability, OCP compliance, and a plugin-based design to avoid major refactoring for future features.

## Deliverables
- A fully functional MVP ecommerce website/app with pluggable features (product listing, search, cart, payments, user accounts, pricing, rebates) and a flexible product model supporting physical goods, services, subscriptions, variants, dynamic attributes, identifiers, and pricing (uniform, variant-specific, promotional, customer-specific, discounts, rebates), built using Golang (fiber), Flutter (GetX), and MongoDB, following a plugin-based architecture with widget plugins inspired by portlets and a lightweight Golang-based rule engine for future pricing models.
- Source code for backend (Golang, MongoDB, Redis Stack) and frontend (Flutter or React/Next.js), hosted in a Git repository, with plugins defined by interfaces and widget plugins managed by a registry for extensibility, including a custom Golang rule engine for pricing (~70-80% AI-generated).
- A deployed instance on Render (or AWS/DigitalOcean) with MongoDB Atlas and Firebase/Vercel, using Docker for consistency and Kubernetes/Terraform for scalability.
- A simple admin guide (AI-generated via Claude/ChatGPT) for non-technical users to manage the store, products, variants, prices, discounts, rebates, rules, and plugins/widgets via Directus/Strapi, with MongoDB Charts for dashboards.
- Recommendations for domain registration (e.g., .mx) and branding setup, with Figma UI mockups.
- A phased development plan with fast timelines (7-9 weeks for 1 developer, 4-5 weeks for 2 developers), milestones, and AI-generated code for each phase, with guidance on when to proceed to the next phase.
- A roadmap for post-MVP enhancements, including WhatsApp integration, advanced plugins/widgets (e.g., reviews, analytics), dynamic pricing rules with a Golang rule engine, and potential dynamic plugin/widget loading (e.g., code-push) if the app succeeds.

