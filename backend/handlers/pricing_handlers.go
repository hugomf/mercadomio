package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"

	"mercadomio-backend/middleware"
	"mercadomio-backend/models"
	"mercadomio-backend/services"
)

// PricingHandlers exposes price-set and price-schedule admin endpoints.
type PricingHandlers struct {
	pricingService *services.PricingService
}

// NewPricingHandlers creates a new pricing handlers struct.
func NewPricingHandlers(pricingService *services.PricingService) *PricingHandlers {
	return &PricingHandlers{pricingService: pricingService}
}

func pageLimit(c *fiber.Ctx) (int, int) {
	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	return page, limit
}

// ---- PriceSets ----

// ListPriceSets returns all price sets (paginated).
func (h *PricingHandlers) ListPriceSets(c *fiber.Ctx) error {
	page, limit := pageLimit(c)
	sets, total, err := h.pricingService.ListPriceSets(c.Context(), page, limit)
	if err != nil {
		return middleware.BadRequest("failed to list price sets: " + err.Error())
	}
	return middleware.SuccessPaginated(c, sets, int(total), page, limit)
}

// CreatePriceSet creates a new price set.
func (h *PricingHandlers) CreatePriceSet(c *fiber.Ctx) error {
	var set models.PriceSet
	if err := c.BodyParser(&set); err != nil {
		return middleware.BadRequest("invalid price set payload")
	}
	created, err := h.pricingService.CreatePriceSet(c.Context(), &set)
	if err != nil {
		return middleware.BadRequest("failed to create price set: " + err.Error())
	}
	return middleware.Created(c, created, "price set created successfully")
}

// UpdatePriceSet updates a price set.
func (h *PricingHandlers) UpdatePriceSet(c *fiber.Ctx) error {
	id := c.Params("id")
	var upd map[string]interface{}
	if err := c.BodyParser(&upd); err != nil {
		return middleware.BadRequest("invalid price set payload")
	}
	if err := h.pricingService.UpdatePriceSet(c.Context(), id, bson.M(upd)); err != nil {
		return middleware.BadRequest("failed to update price set: " + err.Error())
	}
	return middleware.SuccessMessage(c, "price set updated successfully")
}

// DeletePriceSet deletes a price set.
func (h *PricingHandlers) DeletePriceSet(c *fiber.Ctx) error {
	id := c.Params("id")
	if err := h.pricingService.DeletePriceSet(c.Context(), id); err != nil {
		return middleware.BadRequest("failed to delete price set: " + err.Error())
	}
	return middleware.SuccessMessage(c, "price set deleted successfully")
}

// ---- PriceSchedules ----

// ListPriceSchedules returns all price schedules (paginated).
func (h *PricingHandlers) ListPriceSchedules(c *fiber.Ctx) error {
	page, limit := pageLimit(c)
	schedules, total, err := h.pricingService.ListPriceSchedules(c.Context(), page, limit)
	if err != nil {
		return middleware.BadRequest("failed to list price schedules: " + err.Error())
	}
	return middleware.SuccessPaginated(c, schedules, int(total), page, limit)
}

// CreatePriceSchedule creates a new price schedule.
func (h *PricingHandlers) CreatePriceSchedule(c *fiber.Ctx) error {
	var sch models.PriceSchedule
	if err := c.BodyParser(&sch); err != nil {
		return middleware.BadRequest("invalid price schedule payload")
	}
	created, err := h.pricingService.CreatePriceSchedule(c.Context(), &sch)
	if err != nil {
		return middleware.BadRequest("failed to create price schedule: " + err.Error())
	}
	return middleware.Created(c, created, "price schedule created successfully")
}

// UpdatePriceSchedule updates a price schedule.
func (h *PricingHandlers) UpdatePriceSchedule(c *fiber.Ctx) error {
	id := c.Params("id")
	var upd map[string]interface{}
	if err := c.BodyParser(&upd); err != nil {
		return middleware.BadRequest("invalid price schedule payload")
	}
	if err := h.pricingService.UpdatePriceSchedule(c.Context(), id, bson.M(upd)); err != nil {
		return middleware.BadRequest("failed to update price schedule: " + err.Error())
	}
	return middleware.SuccessMessage(c, "price schedule updated successfully")
}

// DeletePriceSchedule deletes a price schedule.
func (h *PricingHandlers) DeletePriceSchedule(c *fiber.Ctx) error {
	id := c.Params("id")
	if err := h.pricingService.DeletePriceSchedule(c.Context(), id); err != nil {
		return middleware.BadRequest("failed to delete price schedule: " + err.Error())
	}
	return middleware.SuccessMessage(c, "price schedule deleted successfully")
}

// ---- Price history ----

// ListPriceHistory returns recent price history, optionally filtered by product.
func (h *PricingHandlers) ListPriceHistory(c *fiber.Ctx) error {
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	productID := c.Query("productId", "")
	entries, err := h.pricingService.ListPriceHistory(c.Context(), productID, limit)
	if err != nil {
		return middleware.BadRequest("failed to list price history: " + err.Error())
	}
	return middleware.Success(c, entries)
}

// ---- Resolution ----

// ResolvePricesPreview lets admin preview how a set of lines prices with given context.
func (h *PricingHandlers) ResolvePricesPreview(c *fiber.Ctx) error {
	var req struct {
		CouponCode   string `json:"couponCode"`
		CustomerTier string `json:"customerTier"`
		Lines        []struct {
			ProductID string `json:"productID"`
			VariantID string `json:"variantID"`
			Quantity  int    `json:"quantity"`
		} `json:"lines"`
	}
	if err := c.BodyParser(&req); err != nil {
		return middleware.BadRequest("invalid pricing payload")
	}
	ctx := c.Context()
	// Enrich lines with products so the engine has base prices/scopes.
	inputs := make([]services.PriceInput, 0, len(req.Lines))
	for _, line := range req.Lines {
		product, err := h.pricingService.GetProductForPrice(ctx, line.ProductID)
		if err != nil {
			return middleware.BadRequest("product not found: " + line.ProductID)
		}
		in := services.PriceInput{Product: product, Quantity: line.Quantity}
		if line.VariantID != "" {
			for i := range product.Variants {
				if product.Variants[i].VariantID == line.VariantID {
					in.Variant = &product.Variants[i]
					break
				}
			}
		}
		if in.Quantity <= 0 {
			in.Quantity = 1
		}
		inputs = append(inputs, in)
	}
	result, err := h.pricingService.ResolvePrices(ctx, inputs, services.PricingContext{
		CouponCode:   req.CouponCode,
		CustomerTier: req.CustomerTier,
	})
	if err != nil {
		return middleware.BadRequest("failed to resolve prices: " + err.Error())
	}
	return middleware.Success(c, result)
}