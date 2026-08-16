package routes

import (
	"log"
	"mercadomio-backend/config"
	"mercadomio-backend/handlers"
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

// SetupRoutes configures all application routes
func SetupRoutes(app *fiber.App, deps *RouteDependencies) {
	// Setup middleware
	app.Use(logger.New())
	app.Use(middleware.SetupCORS())

	// Serve static images with CORS support
	imagesPath := os.Getenv("IMAGES_PATH")
	if imagesPath == "" {
		imagesPath = "./frontend/web/assets/images"
	}
	log.Printf("Setting up static file serving: /assets/images -> %s", imagesPath)

	// Configure static file serving for images
	app.Static("/assets/images", imagesPath, fiber.Static{
		Compress:      true,
		ByteRange:     true,
		Browse:        false,
		CacheDuration: 24 * 60 * 60 * 1000, // 24 hours
		MaxAge:        3600,                // 1 hour
	})

	// Initialize handlers
	productHandlers := handlers.NewProductHandlers(deps.ProductService, deps.SearchService, deps.AnalyticsService, deps.PricingService)
	cartHandlers := handlers.NewCartHandlers(deps.CartService)
	analyticsHandlers := handlers.NewAnalyticsHandlers(deps.AnalyticsService)

	// Initialize Cloudinary configuration
	cloudinaryConfig := config.GetCloudinaryConfig()
	cloudinaryHandlers := handlers.NewCloudinaryHandlers(
		cloudinaryConfig.CloudName,
		cloudinaryConfig.ProductsFolder,
	)

	// Initialize Directus handlers
	directusURL := os.Getenv("DIRECTUS_URL")
	if directusURL == "" {
		directusURL = "http://localhost:8055"
	}
	directusHandlers := handlers.NewDirectusHandlers(directusURL)

	imageHandlers := handlers.NewImageHandlers()
	categoryHandlers := handlers.NewCategoryHandlers(deps.CategoryService)
	authHandlers := handlers.NewAuthHandlers(deps.AuthService)
	orderHandlers := handlers.NewOrderHandlers(deps.OrderService, deps.CartService, deps.ProductService)
	paymentHandlers := handlers.NewPaymentHandlers(deps.PaymentService)
	paymentRoutes := NewPaymentHandlers(paymentHandlers)
	pricingHandlers := handlers.NewPricingHandlers(deps.PricingService)

	// Setup routes
	SetupProductRoutes(app, productHandlers)
	SetupCartRoutes(app, cartHandlers, deps.AuthService)
	SetupAnalyticsRoutes(app, analyticsHandlers)
	SetupImageRoutes(app, imageHandlers, cloudinaryHandlers, directusHandlers)
	SetupCategoryRoutes(app, categoryHandlers)
	SetupAuthRoutes(app, authHandlers)
	SetupOrderRoutes(app, orderHandlers, deps.AuthService)
	SetupPaymentRoutes(app, paymentRoutes)
	SetupPricingRoutes(app, pricingHandlers)

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "mercadomio-backend",
		})
	})
}

// RouteDependencies holds all the services needed for routes
type RouteDependencies struct {
	ProductService   services.ProductService
	SearchService    services.SearchService
	CartService      services.CartService
	AnalyticsService services.AnalyticsService
	CategoryService  services.CategoryService
	AuthService      *services.AuthService
	OrderService     *services.OrderService
	PaymentService   *services.PaymentService
	PricingService   *services.PricingService
}
