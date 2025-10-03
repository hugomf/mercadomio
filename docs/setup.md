# MercadoMío Local Development Setup

## Prerequisites
- Docker & Docker Compose installed
- (Optional) Figma for UI design


## Getting Started
1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your changes
4. Make your changes
5. Push to your fork and submit a pull request

## 1. Clone the Repository
```
git clone <your-repo-url>
cd mercadomio
```

## 2. Start All Services
```
docker-compose up --build
```
- This will start backend (Golang), frontend (Flutter web), MongoDB, Redis Stack, and Directus.
- Backend: http://localhost:8080
- Frontend: http://localhost:3000
- Directus: http://localhost:8055
- RedisInsight: http://localhost:8001

## 3. Directus Setup
- Go to http://localhost:8055
- Log in with:
  - Email: admin@mercadomio.mx
  - Password: admin123
- Create collections for products, users, orders, fragments, control_panels (matching the provided schemas).
- Use Directus’s content builder to add fields as per the MongoDB schemas in /backend/schemas.

## 4. MongoDB
- MongoDB is available at mongodb://localhost:27017/mercadomio
- Use Adminer, MongoDB Compass, or Directus for management.

## 5. Development
- Backend code: /backend
- Frontend code: /frontend
- Docs: /docs

## 6. Testing Features
- **Product Sorting**: Use the sort button (↕️) next to the search bar to test price and date sorting
- **API Testing**: Use curl commands to test sorting endpoints:
  ```bash
  curl "http://localhost:8080/api/products?sort=basePrice&order=asc"
  curl "http://localhost:8080/api/products?sort=createdAt&order=desc"
  ```

## 6. Stopping Services
```
docker-compose down
```
