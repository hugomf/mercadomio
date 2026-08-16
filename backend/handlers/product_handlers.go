package handlers

import (
	"context"
	"log"
	"math"
	"strconv"
	"strings"

	"mercadomio-backend/middleware"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
)

type ProductHandlers struct {
	ProductService   services.ProductService
	SearchService    services.SearchService
	AnalyticsService services.AnalyticsService
	PricingService   *services.PricingService
}

func NewProductHandlers(productService services.ProductService, searchService services.SearchService, analyticsService services.AnalyticsService, pricingService *services.PricingService) *ProductHandlers {
	return &ProductHandlers{
		ProductService:   productService,
		SearchService:    searchService,
		AnalyticsService: analyticsService,
		PricingService:   pricingService,
	}
}

// enrichCatalogPrices resolves each product's effective price through the
// pricing engine (schedules + active price sets) and attaches the derived
// price, discount percent, and unit to the product's customAttributes.
//
// The engine is the single source of truth for pricing: the catalog only
// carries base prices, while discounts come from PriceSchedules/PriceSets.
// None of the attached values are persisted — they are computed per-request.
// If resolution fails, the product is left untouched (never fail a read).
func (h *ProductHandlers) enrichCatalogPrices(ctx context.Context, products []*services.Product) {
	if h.PricingService == nil || len(products) == 0 {
		return
	}

	inputs := make([]services.PriceInput, 0, len(products))
	for _, product := range products {
		in := services.PriceInput{Product: product, Quantity: 1}
		if len(product.Variants) > 0 {
			in.Variant = &product.Variants[0]
		}
		inputs = append(inputs, in)
	}

	result, err := h.PricingService.ResolvePrices(ctx, inputs, services.PricingContext{})
	if err != nil {
		log.Printf("pricing enrichment skipped for %d products: %v", len(products), err)
		return
	}

	for i, line := range result.Lines {
		if i >= len(products) {
			break
		}
		applyCatalogPrice(products[i], line)
	}
}

// applyCatalogPrice writes the resolved unit price, discount percent, and unit
// label into a product's customAttributes (transient, per-request).
func applyCatalogPrice(product *services.Product, line services.PricedLine) {
	if product.CustomAttributes == nil {
		product.CustomAttributes = map[string]interface{}{}
	}

	product.CustomAttributes["effectivePrice"] = line.UnitPrice

	discountPct := 0.0
	if line.BasePrice > 0 {
		discountPct = math.Round((line.BasePrice - line.UnitPrice) / line.BasePrice * 100)
	}
	product.CustomAttributes["discountPercent"] = discountPct

	if productUnit(product) == "" {
		product.CustomAttributes["unit"] = firstVariantUnit(product)
	}
}

// productUnit returns the unit label already present on the product, if any.
func productUnit(product *services.Product) string {
	unit, _ := product.CustomAttributes["unit"].(string)
	return unit
}

// firstVariantUnit returns the unit label of the first variant, if any.
func firstVariantUnit(product *services.Product) string {
	if len(product.Variants) == 0 {
		return ""
	}
	unit, _ := product.Variants[0].Attributes["unit"].(string)
	return unit
}

// productsOf converts a value slice into a pointer slice so enrichment can
// mutate every product in place.
func productsOf(products []services.Product) []*services.Product {
	ptrs := make([]*services.Product, len(products))
	for i := range products {
		ptrs[i] = &products[i]
	}
	return ptrs
}

// GetProducts handles GET /api/products
func (h *ProductHandlers) GetProducts(c *fiber.Ctx) error {
	// Parse query parameters
	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	query := c.Query("q", "")
	minPrice, _ := strconv.ParseFloat(c.Query("minPrice", "0"), 64)
	maxPrice, _ := strconv.ParseFloat(c.Query("maxPrice", "0"), 64)
	productType := c.Query("type")
	categoryParams := c.Query("category")
	sortBy := c.Query("sort", "name")
	sortOrder := c.Query("order", "asc")

	// Use SearchService for complex queries
	if query != "" || categoryParams != "" || minPrice > 0 || maxPrice > 0 || productType != "" {
		searchParams := services.SearchParams{
			Query:     query,
			MinPrice:  minPrice,
			MaxPrice:  maxPrice,
			Type:      productType,
			SortBy:    sortBy,
			SortOrder: sortOrder,
		}

		// Handle comma-separated category parameters
		if categoryParams != "" {
			categories := strings.Split(categoryParams, ",")
			if err := h.ProductService.AddCategoryNameFilter(c.Context(), &searchParams, categories); err != nil {
				return middleware.BadRequest("Invalid category filter")
			}
		}

		result, err := h.SearchService.SearchProducts(c.Context(), searchParams, page, limit)
		if err != nil {
			return middleware.InternalError("Failed to search products")
		}
		h.enrichCatalogPrices(c.Context(), productsOf(result.Data))

		return c.JSON(fiber.Map{
			"data":  result.Data,
			"total": result.TotalItems,
			"page":  page,
			"limit": limit,
		})
	}

	// For simple listing, use ProductService with sorting
	filter := make(map[string]interface{})
	products, total, err := h.ProductService.ListProductsWithSort(c.Context(), filter, page, limit, sortBy, sortOrder)
	if err != nil {
		return middleware.InternalError("Failed to fetch products")
	}
	h.enrichCatalogPrices(c.Context(), productsOf(products))

	return c.JSON(fiber.Map{
		"data":  products,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetProduct handles GET /api/products/:id
func (h *ProductHandlers) GetProduct(c *fiber.Ctx) error {
	id := c.Params("id")

	product, err := h.ProductService.GetProduct(c.Context(), id)
	if err != nil {
		return middleware.NotFound("Product not found")
	}
	h.enrichCatalogPrices(c.Context(), []*services.Product{product})

	return c.JSON(product)
}

// CreateProduct handles POST /api/products
func (h *ProductHandlers) CreateProduct(c *fiber.Ctx) error {
	var product services.Product
	if err := c.BodyParser(&product); err != nil {
		return middleware.BadRequest("Invalid input")
	}

	if err := h.ProductService.CreateProduct(c.Context(), &product); err != nil {
		return middleware.BadRequest("Failed to create product: " + err.Error())
	}

	return c.Status(201).JSON(product)
}

// UpdateProduct handles PUT /api/products/:id
func (h *ProductHandlers) UpdateProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	var update map[string]interface{}
	if err := c.BodyParser(&update); err != nil {
		return middleware.BadRequest("Invalid input")
	}

	if err := h.ProductService.UpdateProduct(c.Context(), id, update); err != nil {
		return middleware.InternalError("Failed to update product")
	}

	return c.SendStatus(204)
}

// DeleteProduct handles DELETE /api/products/:id
func (h *ProductHandlers) DeleteProduct(c *fiber.Ctx) error {
	id := c.Params("id")

	if err := h.ProductService.DeleteProduct(c.Context(), id); err != nil {
		return middleware.InternalError("Failed to delete product")
	}

	return c.SendStatus(204)
}

// GetVariants handles GET /api/variants
func (h *ProductHandlers) GetVariants(c *fiber.Ctx) error {
	// Demo endpoint: return a static list of variants
	return c.JSON([]string{"Small", "Medium", "Large", "XL"})
}

// GetProductReviews handles GET /api/products/:id/reviews
func (h *ProductHandlers) GetProductReviews(c *fiber.Ctx) error {
	id := c.Params("id")

	reviews, err := h.ProductService.GetProductReviews(c.Context(), id)
	if err != nil {
		return middleware.NotFound("Product reviews not found")
	}

	return c.JSON(reviews)
}

// GetRelatedProducts handles GET /api/products/:id/related
func (h *ProductHandlers) GetRelatedProducts(c *fiber.Ctx) error {
	id := c.Params("id")

	relatedProducts, err := h.ProductService.GetRelatedProducts(c.Context(), id)
	if err != nil {
		return middleware.NotFound("Related products not found")
	}

	return c.JSON(relatedProducts)
}

// UpdateVariantStock handles PUT /api/products/:id/variants/:variantId/stock
func (h *ProductHandlers) UpdateVariantStock(c *fiber.Ctx) error {
	id := c.Params("id")
	variantID := c.Params("variantId")

	var body struct {
		Stock int `json:"stock"`
	}
	if err := c.BodyParser(&body); err != nil {
		return middleware.BadRequest("Invalid input")
	}

	if err := h.ProductService.SetVariantStock(c.Context(), id, variantID, body.Stock); err != nil {
		return middleware.BadRequest(err.Error())
	}

	return middleware.SuccessMessage(c, "Stock updated")
}
