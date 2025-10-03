package services

import (
	"context"
	"errors"
	"time"

	"mercadomio-backend/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type productService struct {
	db              *mongo.Database
	collection      *mongo.Collection
	categoryService CategoryService
}

func NewProductService(db *mongo.Database, categoryService CategoryService) ProductService {
	return &productService{
		db:              db,
		collection:      db.Collection("products"),
		categoryService: categoryService,
	}
}

func (s *productService) GetProduct(ctx context.Context, id string) (*Product, error) {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	return s.GetProductByID(ctx, objID)
}

func (s *productService) GetProductByID(ctx context.Context, id primitive.ObjectID) (*Product, error) {
	var product Product
	err := s.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&product)
	if err != nil {
		return nil, err
	}
	return &product, nil
}

func (s *productService) GetVariant(ctx context.Context, productID string, variantID string) (*Variant, error) {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return nil, err
	}
	vID, err := primitive.ObjectIDFromHex(variantID)
	if err != nil {
		return nil, err
	}
	return s.GetVariantByID(ctx, objID, vID)
}

func (s *productService) GetVariantByID(ctx context.Context, productID, variantID primitive.ObjectID) (*Variant, error) {
	var product Product
	err := s.collection.FindOne(ctx, bson.M{
		"_id":          productID,
		"variants._id": variantID,
	}).Decode(&product)
	if err != nil {
		return nil, err
	}

	for _, v := range product.Variants {
		if v.VariantID == variantID.Hex() {
			return &v, nil
		}
	}
	return nil, errors.New("variant not found")
}

func (s *productService) CreateProduct(ctx context.Context, p *Product) error {
	p.ID = primitive.NewObjectID()
	p.CreatedAt = time.Now()
	p.UpdatedAt = time.Now()
	_, err := s.collection.InsertOne(ctx, p)
	return err
}

func (s *productService) UpdateProduct(ctx context.Context, id string, update map[string]interface{}) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	update["updatedAt"] = time.Now()
	_, err = s.collection.UpdateOne(
		ctx,
		bson.M{"_id": objID},
		bson.M{"$set": update},
	)
	return err
}

func (s *productService) DeleteProduct(ctx context.Context, id string) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = s.collection.DeleteOne(ctx, bson.M{"_id": objID})
	return err
}

func (s *productService) ListProducts(ctx context.Context, filter bson.M, page int, limit int) ([]Product, int64, error) {
	return s.ListProductsWithSort(ctx, filter, page, limit, "name", "asc")
}

func (s *productService) ListProductsWithSort(ctx context.Context, filter bson.M, page int, limit int, sortBy string, sortOrder string) ([]Product, int64, error) {
	// Validate sort field to prevent injection
	validFields := map[string]bool{
		"name":      true,
		"basePrice": true,
		"createdAt": true,
		"updatedAt": true,
	}

	sortField := "name"
	if validFields[sortBy] {
		sortField = sortBy
	}

	sortDirection := 1
	if sortOrder == "desc" {
		sortDirection = -1
	}

	opts := options.Find().
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: sortField, Value: sortDirection}})

	total, err := s.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	cursor, err := s.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var products []Product
	if err := cursor.All(ctx, &products); err != nil {
		return nil, 0, err
	}

	return products, total, nil
}

func (s *productService) AddVariant(ctx context.Context, productID string, variant Variant) error {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return err
	}

	_, err = s.collection.UpdateOne(
		ctx,
		bson.M{"_id": objID},
		bson.M{"$push": bson.M{"variants": variant}},
	)
	return err
}

func (s *productService) UpdateVariant(ctx context.Context, productID, variantID string, update bson.M) error {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return err
	}

	_, err = s.collection.UpdateOne(
		ctx,
		bson.M{"_id": objID, "variants.variantId": variantID},
		bson.M{"$set": bson.M{"variants.$": update}},
	)
	return err
}

func (s *productService) RemoveVariant(ctx context.Context, productID, variantID string) error {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return err
	}

	_, err = s.collection.UpdateOne(
		ctx,
		bson.M{"_id": objID},
		bson.M{"$pull": bson.M{"variants": bson.M{"variantId": variantID}}},
	)
	return err
}

func (s *productService) EnsureTextIndex(ctx context.Context) error {
	model := mongo.IndexModel{
		Keys: bson.D{
			{Key: "name", Value: "text"},
			{Key: "description", Value: "text"},
			{Key: "sku", Value: "text"},
		},
	}
	_, err := s.collection.Indexes().CreateOne(ctx, model)
	return err
}

func (s *productService) AddCategoryNameFilter(ctx context.Context, params *SearchParams, categoryNames []string) error {
	params.Categories = categoryNames
	return nil
}

func (s *productService) AddCategoryFilter(ctx context.Context, params *SearchParams, categoryIDs []primitive.ObjectID) error {
	if len(categoryIDs) == 0 {
		return nil
	}

	// Perform hierarchical filtering - include all child categories
	var allCategoryIDs []primitive.ObjectID

	for _, id := range categoryIDs {
		// Add the requested category ID
		allCategoryIDs = append(allCategoryIDs, id)

		// Get all child categories recursively
		childIDs, err := s.getAllChildCategoryIDs(ctx, id)
		if err != nil {
			return err
		}
		allCategoryIDs = append(allCategoryIDs, childIDs...)
	}

	params.CategoryIDs = allCategoryIDs
	return nil
}

func (s *productService) getAllChildCategoryIDs(ctx context.Context, parentID primitive.ObjectID) ([]primitive.ObjectID, error) {
	var result []primitive.ObjectID

	children, err := s.categoryService.GetChildCategories(ctx, parentID)
	if err != nil {
		return nil, err
	}

	for _, child := range children {
		result = append(result, child.ID)
		// Recursively get children of children
		grandchildren, err := s.getAllChildCategoryIDs(ctx, child.ID)
		if err != nil {
			return nil, err
		}
		result = append(result, grandchildren...)
	}

	return result, nil
}

func (s *productService) GetProductReviews(ctx context.Context, productID string) ([]models.Review, error) {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return nil, err
	}

	var product models.Product
	err = s.collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&product)
	if err != nil {
		return nil, err
	}

	return product.Reviews, nil
}

func (s *productService) GetRelatedProducts(ctx context.Context, productID string) ([]Product, error) {
	objID, err := primitive.ObjectIDFromHex(productID)
	if err != nil {
		return nil, err
	}

	var product models.Product
	err = s.collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&product)
	if err != nil {
		return nil, err
	}

	// For now, return products with same category, excluding the current product
	// This is a basic recommendation algorithm that can be enhanced later
	filter := bson.M{
		"category": product.Category,
		"_id":      bson.M{"$ne": objID},
	}

	cursor, err := s.collection.Find(ctx, filter, options.Find().SetLimit(5))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var relatedProducts []Product
	if err := cursor.All(ctx, &relatedProducts); err != nil {
		return nil, err
	}

	return relatedProducts, nil
}
