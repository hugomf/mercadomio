package tests

import (
	"context"
	"testing"
	"time"

	"mercadomio-backend/models"
	"mercadomio-backend/services"

	"github.com/stretchr/testify/suite"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// OrderServiceIntegrationSuite defines integration tests for order operations
type OrderServiceIntegrationSuite struct {
	orderService   *services.OrderService
	productService services.ProductService
	db             *mongo.Database
	testUserID     string
	testProductID  string
}

func (suite *OrderServiceIntegrationSuite) SetupTest() {
	// Setup test database
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		panic("Failed to connect to MongoDB: " + err.Error())
	}

	suite.db = client.Database("mercadomio_test")

	// Clean test data
	suite.db.Collection("orders").Drop(ctx)
	suite.db.Collection("products").Drop(ctx)
	suite.db.Collection("categories").Drop(ctx)

	// Initialize services with interfaces
	categoryService := services.NewCategoryService(suite.db)

	// Create a test category
	testCategory := &services.Category{
		Name: "Test Category",
		Slug: "test-category",
	}
	testCategory, err = categoryService.CreateCategory(ctx, testCategory)
	if err != nil {
		panic("Failed to create category: " + err.Error())
	}

	// Initialize product service
	suite.productService = services.NewProductService(suite.db, categoryService)

	// Create a test product
	testProduct := &services.Product{
		Name:        "Test Product",
		Description: "Integration test product",
		BasePrice:   29.99,
		Categories:  []primitive.ObjectID{testCategory.ID},
		SKU:         "TEST-001",
	}
	err = suite.productService.CreateProduct(ctx, testProduct)
	if err != nil {
		panic("Failed to create product: " + err.Error())
	}

	// Initialize order service
	suite.orderService = services.NewOrderService(suite.db)
	// Note: We'll set product service per test since it's an interface

	// Store test IDs
	suite.testUserID = primitive.NewObjectID().Hex()
	suite.testProductID = testProduct.ID.Hex()
}

func (suite *OrderServiceIntegrationSuite) TearDownTest() {
	if suite.db != nil {
		suite.db.Collection("orders").Drop(context.Background())
		suite.db.Collection("products").Drop(context.Background())
		suite.db.Collection("categories").Drop(context.Background())
	}
}

func (suite *OrderServiceIntegrationSuite) TestCreateOrderFromCart() {
	ctx := context.Background()

	// Create cart items
	cartItems := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  2,
			Price:     29.99,
		},
	}

	// Create order
	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)
	suite.NoError(err)
	suite.NotNil(order)
	suite.Equal(order.Status, models.OrderStatusPending)
	suite.Equal(order.UserID.Hex(), suite.testUserID)
	suite.Equal(order.Total, 59.98) // 2 * 29.99
	suite.Len(order.Items, 1)
	suite.Equal(order.Items[0].Quantity, 2)
}

func (suite *OrderServiceIntegrationSuite) TestCreateOrderFromCart_EmptyCart() {
	ctx := context.Background()

	// Try to create order with empty cart
	emptyCart := []services.CartItem{}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, emptyCart)

	suite.Error(err)
	suite.Nil(order)
	suite.Contains(err.Error(), "no valid items in cart")
}

func (suite *OrderServiceIntegrationSuite) TestCreateOrderFromCart_InvalidProduct() {
	ctx := context.Background()

	// Try to create order with non-existent product
	cartItems := []services.CartItem{
		{
			ProductID: "nonexistentproductid",
			Quantity:  1,
			Price:     10.00,
		},
	}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)

	suite.Error(err)
	suite.Nil(order)
	suite.Contains(err.Error(), "product not found")
}

func (suite *OrderServiceIntegrationSuite) TestGetOrderByID() {
	ctx := context.Background()

	// First create an order
	cartItems := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  1,
			Price:     29.99,
		},
	}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)
	suite.NoError(err)
	suite.NotNil(order)

	// Now retrieve it
	retrievedOrder, err := suite.orderService.GetOrderByID(ctx, order.ID.Hex())
	suite.NoError(err)
	suite.NotNil(retrievedOrder)
	suite.Equal(retrievedOrder.ID, order.ID)
	suite.Equal(retrievedOrder.UserID, order.UserID)
	suite.Equal(retrievedOrder.Status, order.Status)
}

func (suite *OrderServiceIntegrationSuite) TestGetOrderByID_NotFound() {
	ctx := context.Background()

	// Try to get non-existent order
	fakeOrderID := primitive.NewObjectID().Hex()
	order, err := suite.orderService.GetOrderByID(ctx, fakeOrderID)

	suite.Error(err)
	suite.Nil(order)
	suite.Contains(err.Error(), "order not found")
}

func (suite *OrderServiceIntegrationSuite) TestGetOrdersByUserID() {
	ctx := context.Background()

	// Create multiple orders for the same user
	cartItems1 := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  1,
			Price:     29.99,
		},
	}

	cartItems2 := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  3,
			Price:     29.99,
		},
	}

	order1, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems1)
	suite.NoError(err)

	order2, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems2)
	suite.NoError(err)

	// Retrieve orders for user
	orders, err := suite.orderService.GetOrdersByUserID(ctx, suite.testUserID, 1, 10)
	suite.NoError(err)
	suite.Len(orders, 2)

	// Orders should be sorted by creation date (newest first)
	// Note: order2 was created after order1, so it should appear first
	suite.Equal(orders[0].ID, order2.ID)
	suite.Equal(orders[1].ID, order1.ID)
}

func (suite *OrderServiceIntegrationSuite) TestUpdateOrderStatus() {
	ctx := context.Background()

	// Create an order
	cartItems := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  1,
			Price:     29.99,
		},
	}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)
	suite.NoError(err)

	// Update status
	err = suite.orderService.UpdateOrderStatus(ctx, order.ID.Hex(), models.OrderStatusPaid)
	suite.NoError(err)

	// Verify status was updated
	updatedOrder, err := suite.orderService.GetOrderByID(ctx, order.ID.Hex())
	suite.NoError(err)
	suite.Equal(updatedOrder.Status, models.OrderStatusPaid)
}

func (suite *OrderServiceIntegrationSuite) TestUpdateOrderStatus_InvalidTransition() {
	ctx := context.Background()

	// Create an order
	cartItems := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  1,
			Price:     29.99,
		},
	}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)
	suite.NoError(err)

	// Try invalid transition: pending -> completed (should be pending -> paid -> completed)
	err = suite.orderService.UpdateOrderStatus(ctx, order.ID.Hex(), models.OrderStatusCompleted)
	suite.Error(err)
	suite.Contains(err.Error(), "invalid status transition")
}

func (suite *OrderServiceIntegrationSuite) TestUpdateOrderPayment() {
	ctx := context.Background()

	// Create an order
	cartItems := []services.CartItem{
		{
			ProductID: suite.testProductID,
			Quantity:  1,
			Price:     29.99,
		},
	}

	order, err := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, cartItems)
	suite.NoError(err)

	// Add payment info
	paymentInfo := map[string]interface{}{
		"provider":       "stripe",
		"transaction_id": "txn_12345",
		"amount":         29.99,
	}

	err = suite.orderService.UpdateOrderPayment(ctx, order.ID.Hex(), paymentInfo)
	suite.NoError(err)

	// Verify payment was added and status changed
	updatedOrder, err := suite.orderService.GetOrderByID(ctx, order.ID.Hex())
	suite.NoError(err)
	suite.Equal(updatedOrder.Status, models.OrderStatusPaid)
	suite.NotNil(updatedOrder.PaymentInfo)
}

func (suite *OrderServiceIntegrationSuite) TestOrderStats() {
	ctx := context.Background()

	// Create orders with different statuses
	pendingOrder, _ := suite.orderService.CreateOrderFromCart(ctx, suite.testUserID, []services.CartItem{
		{ProductID: suite.testProductID, Quantity: 1, Price: 10.0},
	})

	paidOrder, _ := suite.orderService.CreateOrderFromCart(ctx, "user2", []services.CartItem{
		{ProductID: suite.testProductID, Quantity: 1, Price: 20.0},
	})

	// Update paid order status
	_ = suite.orderService.UpdateOrderStatus(ctx, paidOrder.ID.Hex(), models.OrderStatusPaid)

	// Get stats
	stats, err := suite.orderService.GetOrderStats(ctx)
	suite.NoError(err)
	suite.NotNil(stats)

	// Should have at least pending and paid orders
	suite.Contains(stats, "pending")
	suite.Contains(stats, "paid")
	suite.True(stats["pending"] >= 1) // At least the pending order
	suite.True(stats["paid"] >= 1)    // At least the paid order
}

// TestOrderServiceIntegration runs the integration test suite
func TestOrderServiceIntegration(t *testing.T) {
	suite.Run(t, new(OrderServiceIntegrationSuite))
}
