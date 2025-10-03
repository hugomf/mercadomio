package services

import (
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// searchServiceImpl implements SearchService
type searchServiceImpl struct {
	productCollection *mongo.Collection
	categoryService   CategoryService
}

// Ensure searchServiceImpl implements SearchService
var _ SearchService = (*searchServiceImpl)(nil)

// NewSearchService creates a new SearchService
func NewSearchService(db *mongo.Database, categoryService CategoryService) SearchService {
	return &searchServiceImpl{
		productCollection: db.Collection("products"),
		categoryService:   categoryService,
	}
}

// SearchProducts performs product search with filters and pagination
func (ss *searchServiceImpl) SearchProducts(ctx context.Context, params SearchParams, page int, limit int) (*SearchResult, error) {
	filter := bson.M{}

	// Text search with fallback to regex
	if params.Query != "" {
		// First try regex search as fallback (more reliable than text search)
		filter["name"] = bson.M{"$regex": params.Query, "$options": "i"}
		// Comment out text search for now since no text index exists
		// filter["$text"] = bson.M{"$search": params.Query}
	}

	// Category filter (case-insensitive)
	if len(params.Categories) > 0 {
		// Filter by category name (case-insensitive)
		if len(params.Categories) == 1 {
			// Single category
			filter["category"] = bson.M{"$regex": params.Categories[0], "$options": "i"}
		} else {
			// Multiple categories - OR condition
			categoryFilters := make([]bson.M, len(params.Categories))
			for i, cat := range params.Categories {
				categoryFilters[i] = bson.M{"category": bson.M{"$regex": cat, "$options": "i"}}
			}
			filter["$or"] = categoryFilters
		}
	}

	// Price range filter
	if params.MinPrice > 0 || params.MaxPrice > 0 {
		priceFilter := bson.M{}
		if params.MinPrice > 0 {
			priceFilter["$gte"] = params.MinPrice
		}
		if params.MaxPrice > 0 {
			priceFilter["$lte"] = params.MaxPrice
		}
		filter["basePrice"] = priceFilter
	}

	// Product type filter
	if params.Type != "" {
		filter["type"] = params.Type
	}

	// Variant attribute filter
	if len(params.VariantAttributes) > 0 {
		filter["variants"] = bson.M{"$exists": true, "$not": bson.M{"$size": 0}}

		variantFilters := make([]bson.M, 0)
		for attr, value := range params.VariantAttributes {
			variantFilters = append(variantFilters, bson.M{
				"variants.attributes." + attr: value,
			})
		}
		filter["$and"] = variantFilters
	}

	// Get total count first
	totalItems, err := ss.productCollection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Apply sorting
	sortField := params.SortBy
	if sortField == "" || sortField == "name" {
		sortField = "name"
	}
	sortOrder := 1
	if params.SortOrder == "desc" {
		sortOrder = -1
	}

	// Apply pagination and sorting
	opts := options.Find().
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit)).
		SetSort(bson.D{{Key: sortField, Value: sortOrder}})

	cur, err := ss.productCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var products []Product
	for cur.Next(ctx) {
		var p Product
		if err := cur.Decode(&p); err != nil {
			return nil, err
		}
		products = append(products, p)
	}

	return &SearchResult{
		Data:       products,
		TotalItems: int(totalItems),
	}, nil
}
