package services

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type categoryService struct {
	db         *mongo.Database
	collection *mongo.Collection
}

func NewCategoryService(db *mongo.Database) CategoryService {
	return &categoryService{
		db:         db,
		collection: db.Collection("categories"),
	}
}

// CreateCategory creates a new category
func (s *categoryService) CreateCategory(ctx context.Context, category *Category) (*Category, error) {
	category.ID = primitive.NewObjectID()
	category.CreatedAt = time.Now()
	category.UpdatedAt = time.Now()

	if category.ParentID != nil {
		// Verify parent exists
		count, err := s.collection.CountDocuments(ctx, bson.M{"_id": *category.ParentID})
		if err != nil {
			return nil, err
		}
		if count == 0 {
			return nil, errors.New("parent category not found")
		}
	}

	_, err := s.collection.InsertOne(ctx, category)
	if err != nil {
		return nil, err
	}
	return category, nil
}

// GetCategoryByID retrieves a category by ID
func (s *categoryService) GetCategoryByID(ctx context.Context, id primitive.ObjectID) (*Category, error) {
	var category Category
	err := s.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&category)
	if err != nil {
		return nil, err
	}
	return &category, nil
}

// GetChildCategories retrieves all child categories
func (s *categoryService) GetCategoryByName(ctx context.Context, name string) (*Category, error) {
	var category Category
	err := s.collection.FindOne(ctx, bson.M{"name": name}).Decode(&category)
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (s *categoryService) GetChildCategories(ctx context.Context, parentID primitive.ObjectID) ([]Category, error) {
	cursor, err := s.collection.Find(ctx, bson.M{"parentId": parentID})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var categories []Category
	if err = cursor.All(ctx, &categories); err != nil {
		return nil, err
	}
	return categories, nil
}

// UpdateCategory updates an existing category
func (s *categoryService) UpdateCategory(ctx context.Context, id primitive.ObjectID, updates bson.M) error {
	updates["updatedAt"] = time.Now()
	_, err := s.collection.UpdateOne(
		ctx,
		bson.M{"_id": id},
		bson.M{"$set": updates},
	)
	return err
}

// DeleteCategory removes a category
func (s *categoryService) DeleteCategory(ctx context.Context, id primitive.ObjectID) error {
	// Check if category has children
	count, err := s.collection.CountDocuments(ctx, bson.M{"parentId": id})
	if err != nil {
		return err
	}
	if count > 0 {
		return errors.New("cannot delete category with children")
	}

	// Check if category is used by any products
	productCount, err := s.db.Collection("products").CountDocuments(ctx, bson.M{"categories": id})
	if err != nil {
		return err
	}
	if productCount > 0 {
		return errors.New("cannot delete category used by products")
	}

	_, err = s.collection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// CategoryNode is the hydrated category tree node returned by the API.
// Unlike the stored Category (whose children are ObjectID references), a node
// nests full child category objects so the storefront can render subcategories
// without additional lookups.
type CategoryNode struct {
	ID          primitive.ObjectID `json:"id"`
	Name        string             `json:"name"`
	Slug        string             `json:"slug"`
	Description string             `json:"description"`
	ParentID    *primitive.ObjectID `json:"parentId"`
	ImageURL    string             `json:"imageUrl"`
	IsActive    bool               `json:"isActive"`
	CreatedAt   time.Time          `json:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt"`
	Children    []*CategoryNode    `json:"children"`
}

// GetCategoryTree returns the full category hierarchy with hydrated children.
func (s *categoryService) GetCategoryTree(ctx context.Context) ([]*CategoryNode, error) {
	// Get all root categories (no parent), ordered by name for a stable UI.
	cursor, err := s.collection.Find(
		ctx,
		bson.M{"parentId": nil},
		options.Find().SetSort(bson.D{{Key: "name", Value: 1}}),
	)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var rootCategories []Category
	if err = cursor.All(ctx, &rootCategories); err != nil {
		return nil, err
	}

	nodes := make([]*CategoryNode, 0, len(rootCategories))
	for i := range rootCategories {
		node, err := s.hydrateNode(ctx, &rootCategories[i])
		if err != nil {
			return nil, err
		}
		nodes = append(nodes, node)
	}

	return nodes, nil
}

// hydrateNode converts a stored category into a node with fully hydrated,
// recursively nested children.
func (s *categoryService) hydrateNode(ctx context.Context, category *Category) (*CategoryNode, error) {
	node := &CategoryNode{
		ID:          category.ID,
		Name:        category.Name,
		Slug:        category.Slug,
		Description: category.Description,
		ParentID:    category.ParentID,
		ImageURL:    category.ImageURL,
		IsActive:    category.IsActive,
		CreatedAt:   category.CreatedAt,
		UpdatedAt:   category.UpdatedAt,
	}

	children, err := s.GetChildCategories(ctx, category.ID)
	if err != nil {
		return nil, err
	}
	node.Children = make([]*CategoryNode, 0, len(children))
	for i := range children {
		childNode, err := s.hydrateNode(ctx, &children[i])
		if err != nil {
			return nil, err
		}
		node.Children = append(node.Children, childNode)
	}

	return node, nil
}
