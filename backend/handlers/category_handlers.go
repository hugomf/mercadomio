package handlers

import (
	"context"
	"mercadomio-backend/services"

	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type CategoryHandlers struct {
	categoryService services.CategoryService
}

func NewCategoryHandlers(categoryService services.CategoryService) *CategoryHandlers {
	return &CategoryHandlers{
		categoryService: categoryService,
	}
}

func (h *CategoryHandlers) GetCategories(c *fiber.Ctx) error {
	ctx := context.Background()
	categories, err := h.categoryService.GetCategoryTree(ctx)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// Return empty array instead of nil if no categories exist
	if categories == nil {
		return c.JSON([]services.Category{})
	}

	return c.JSON(categories)
}

func (h *CategoryHandlers) CreateCategory(c *fiber.Ctx) error {
	ctx := context.Background()
	var category services.Category
	if err := c.BodyParser(&category); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	newCategory, err := h.categoryService.CreateCategory(ctx, &category)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}
	return c.Status(fiber.StatusCreated).JSON(newCategory)
}

func (h *CategoryHandlers) UpdateCategory(c *fiber.Ctx) error {
	ctx := context.Background()
	id, err := primitive.ObjectIDFromHex(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
		})
	}

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	if err := h.categoryService.UpdateCategory(ctx, id, updates); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}
	return c.SendStatus(fiber.StatusOK)
}

func (h *CategoryHandlers) DeleteCategory(c *fiber.Ctx) error {
	ctx := context.Background()
	id, err := primitive.ObjectIDFromHex(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
		})
	}

	if err := h.categoryService.DeleteCategory(ctx, id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *CategoryHandlers) SearchCategoryByName(c *fiber.Ctx) error {
	ctx := context.Background()
	categoryName := c.Query("name")
	if categoryName == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Category name parameter is required",
		})
	}

	category, err := h.categoryService.GetCategoryByName(ctx, categoryName)
	if err != nil {
		if err.Error() == "category not found" {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "Category not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(category)
}
