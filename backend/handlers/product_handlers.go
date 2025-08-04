package handlers

import (
	"mercadomio-backend/middleware"
	"mercadomio-backend/services"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type ProductHandlers struct {
	ProductService   services.ProductService
	SearchService    services.SearchService
	AnalyticsService services.AnalyticsService
}

func NewProductHandlers(productService services.ProductService, searchService services.SearchService, analyticsService services.AnalyticsService) *ProductHandlers {
	return &ProductHandlers{
		ProductService:   productService,
		SearchService:    searchService,
		AnalyticsService: analyticsService,
	}
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
