package main

import (
	"context"
	"fmt"
	"log"
	"mercadomio-backend/middleware"
	"mercadomio-backend/routes"
	"mercadomio-backend/services"
	"os"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Environment variables
	mongoURI := os.Getenv("MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	// Create context for connection attempts
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Connect to MongoDB
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal("MongoDB connection error:", err)
	}
	db := client.Database("mercadomio")

	// Connect to Redis
	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatal("Redis connection error:", err)
	}

	log.Println("Connected to MongoDB and Redis")

	// Initialize Event Bus
	eventBus := services.NewInMemoryEventBus()

	// Initialize Services
	categoryService := services.NewCategoryService(db)
	productService := services.NewProductService(db, categoryService)
	searchService := services.NewSearchService(db, categoryService)
	cartConfig := services.NewCartConfig()
	cartAnalyticsConfig := services.NewCartAnalyticsConfig()

	// Initialize cart service with event bus
	cartService := services.NewCartService(rdb, productService, cartConfig, db, eventBus)

	// Initialize Analytics Service
	analyticsService := services.NewAnalyticsService(db, cartAnalyticsConfig, eventBus)

	// Initialize Auth Service
	authService := services.NewAuthService(db)

	// Initialize OIDC token validator against the userbrew IdP.
	// Non-fatal: if the IdP is unreachable (e.g. local dev without userbrew),
	// the backend still starts and serves public/optional-auth routes.
	oidcIssuer := os.Getenv("USERBREW_ISSUER")
	if oidcIssuer == "" {
		oidcIssuer = "http://localhost:8090"
	}
	oidcDiscoveryURL := os.Getenv("USERBREW_DISCOVERY_URL")
	if oidcDiscoveryURL == "" {
		oidcDiscoveryURL = fmt.Sprintf("%s/.well-known/openid-configuration", oidcIssuer)
	}
	oidcAudiences := []string{"mercadomio-storefront", "mercadomio-admin"}
	if raw := os.Getenv("USERBREW_AUDIENCES"); raw != "" {
		oidcAudiences = strings.Split(raw, ",")
	}
	var oidcService *services.OidcService
	for attempt := 1; attempt <= 10; attempt++ {
		oidcService, err = services.NewOidcServiceAt(oidcDiscoveryURL, oidcIssuer, oidcAudiences)
		if err == nil {
			break
		}
		log.Printf("userbrew discovery not ready (attempt %d/10): %v", attempt, err)
		time.Sleep(3 * time.Second)
	}
	if oidcService == nil {
		log.Printf("WARNING: could not reach userbrew discovery at %s — auth-required routes will reject tokens", oidcIssuer)
	}

	// Initialize Order Service
	orderService := services.NewOrderService(db)
	orderService.SetProductService(productService)

	// Initialize Pricing Service
	pricingService := services.NewPricingService(db, productService)
	orderService.SetPricingService(pricingService)

	// Initialize Payment Service
	paymentService := services.NewPaymentService(orderService)

	// Start analytics service to begin listening for events
	if err := analyticsService.Start(); err != nil {
		log.Printf("Warning: Failed to start analytics service: %v", err)
	}

	// Set up Fiber app with error handling
	app := fiber.New(fiber.Config{
		ErrorHandler: middleware.ErrorHandler(),
	})

	// Setup routes with dependencies
	routeDeps := &routes.RouteDependencies{
		ProductService:   productService,
		SearchService:    searchService,
		CartService:      cartService,
		AnalyticsService: analyticsService,
		CategoryService:  categoryService,
		AuthService:      authService,
		OidcService:      oidcService,
		OrderService:     orderService,
		PaymentService:   paymentService,
		PricingService:   pricingService,
	}

	routes.SetupRoutes(app, routeDeps)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
