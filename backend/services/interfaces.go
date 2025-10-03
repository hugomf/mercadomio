package services

import (
	"context"

	"mercadomio-backend/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type (
	CategoryService interface {
		CreateCategory(ctx context.Context, category *Category) (*Category, error)
		GetCategoryByID(ctx context.Context, id primitive.ObjectID) (*Category, error)
		GetCategoryByName(ctx context.Context, name string) (*Category, error)
		GetChildCategories(ctx context.Context, parentID primitive.ObjectID) ([]Category, error)
		UpdateCategory(ctx context.Context, id primitive.ObjectID, updates bson.M) error
		DeleteCategory(ctx context.Context, id primitive.ObjectID) error
		GetCategoryTree(ctx context.Context) ([]Category, error)
	}

	ProductService interface {
		GetProduct(ctx context.Context, id string) (*Product, error)
		GetProductByID(ctx context.Context, id primitive.ObjectID) (*Product, error)
		GetVariant(ctx context.Context, productID, variantID string) (*Variant, error)
		GetVariantByID(ctx context.Context, productID, variantID primitive.ObjectID) (*Variant, error)
		ListProducts(ctx context.Context, filter bson.M, page int, limit int) ([]Product, int64, error)
		ListProductsWithSort(ctx context.Context, filter bson.M, page int, limit int, sortBy string, sortOrder string) ([]Product, int64, error)
		CreateProduct(ctx context.Context, p *Product) error
		UpdateProduct(ctx context.Context, id string, update map[string]interface{}) error
		DeleteProduct(ctx context.Context, id string) error
		AddCategoryFilter(ctx context.Context, params *SearchParams, categoryIDs []primitive.ObjectID) error
		AddCategoryNameFilter(ctx context.Context, params *SearchParams, categoryNames []string) error
		GetProductReviews(ctx context.Context, productID string) ([]models.Review, error)
		GetRelatedProducts(ctx context.Context, productID string) ([]Product, error)
	}

	SearchService interface {
		SearchProducts(ctx context.Context, params SearchParams, page int, limit int) (*SearchResult, error)
	}

	CartService interface {
		GetCart(ctx context.Context, cartID string) (*Cart, error)
		AddToCart(ctx context.Context, cartID string, item CartItem) error
		UpdateCartItem(ctx context.Context, cartID, productID, variantID string, quantity int) error
		RemoveFromCart(ctx context.Context, cartID, productID, variantID string) error
		MergeCarts(ctx context.Context, guestCartID, userCartID string) error
	}
)
