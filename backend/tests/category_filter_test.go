package tests

import (
	"context"
	"testing"
	"time"

	"mercadomio-backend/services"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func TestHierarchicalCategoryFilter(t *testing.T) {
	// Setup test database
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		t.Fatal("Failed to connect to MongoDB:", err)
	}
	defer client.Disconnect(ctx)

	db := client.Database("mercadomio_test")

	// Initialize services
	categoryService := services.NewCategoryService(db)
	productService := services.NewProductService(db, categoryService)

	// Create test categories
	parentCategory := &services.Category{
		Name: "Parent Category",
		Slug: "parent-category",
	}

	childCategory := &services.Category{
		Name:     "Child Category",
		Slug:     "child-category",
		ParentID: &parentCategory.ID,
	}

	// Save categories
	parentCategory, err = categoryService.CreateCategory(ctx, parentCategory)
	if err != nil {
		t.Fatal("Failed to create parent category:", err)
	}

	childCategory, err = categoryService.CreateCategory(ctx, childCategory)
	if err != nil {
		t.Fatal("Failed to create child category:", err)
	}

	// Create test products
	parentProduct := &services.Product{
		Name:       "Parent Product",
		Categories: []primitive.ObjectID{parentCategory.ID},
		BasePrice:  100,
	}

	childProduct := &services.Product{
		Name:       "Child Product",
		Categories: []primitive.ObjectID{childCategory.ID},
		BasePrice:  50,
	}

	// Save products
	if err := productService.CreateProduct(ctx, parentProduct); err != nil {
		t.Fatal("Failed to create parent product:", err)
	}
	if err := productService.CreateProduct(ctx, childProduct); err != nil {
		t.Fatal("Failed to create child product:", err)
	}

	// Test filtering by parent category
	t.Run("Filter by parent category", func(t *testing.T) {
		params := &services.SearchParams{}
		err := productService.AddCategoryFilter(ctx, params, []primitive.ObjectID{parentCategory.ID})
		if err != nil {
			t.Fatal("Failed to add category filter:", err)
		}

		products, _, err := productService.ListProducts(ctx, bson.M{
			"categories": bson.M{"$in": params.Categories},
		}, 1, 10)

		if err != nil {
			t.Fatal("Failed to list products:", err)
		}

		if len(products) != 2 {
			t.Errorf("Expected 2 products, got %d", len(products))
		}
	})

	// Cleanup
	db.Collection("categories").Drop(ctx)
	db.Collection("products").Drop(ctx)
}
