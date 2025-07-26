# MercadoMío Architecture Overview

## 1. Fragment-Based Architecture

- **Fragments (Backend):** Modular Golang components implementing the `Fragment` interface (Init, Execute, Shutdown). Examples: ProductFragment, PricingFragment, CartFragment.
- **FragmentWidgets (Frontend):** Flutter widgets for each feature, e.g., ProductListingFragmentWidget, PriceDisplayFragmentWidget.
- **ControlPanels:** Structs (backend) and widgets (frontend) for managing Fragment settings (e.g., pricing rules, plugin toggles).
- **FragmentRegistry:** Static import/registration for MVP, enabling pluggable features.

## 2. MongoDB Collections

- **products:** Flexible schema for physical goods, services, subscriptions, variants, dynamic attributes, identifiers, and pricing.
- **users:** Customer accounts, order history, rebate credits.
- **orders:** Purchases, rebates, payment status.
- **fragments:** Backend Fragment configurations.
- **control_panels:** Pricing rules, Fragment/ControlPanel settings.

## 3. Directus CMS

- Connects to MongoDB for non-technical management of products, prices, rules, Fragments, and ControlPanels.
- Collections mirror MongoDB schemas for easy admin.

## 4. Redis Stack

- Caching (product listings, cart sessions), Pub/Sub for event-driven Fragment communication.

## 5. Development Workflow

- **Backend:** Golang (Fiber), modular Fragments, MongoDB, Redis, Docker.
- **Frontend:** Flutter (GetX), FragmentWidgets, Dio for API, Docker.
- **Admin:** Directus for content, MongoDB Charts for dashboards.
- **DevOps:** Docker Compose for local dev, Render/Firebase for deployment.

## 6. AI-Assisted Development

- AI generates ~70-80% of code (Fragments, Widgets, ControlPanels, configs, tests).
- Developers integrate, customize, and test.
- Phased plan with clear milestones and checkpoints.

---

For more details, see the README and each phase’s documentation.
