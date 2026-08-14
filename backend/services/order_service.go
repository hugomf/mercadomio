package services

import (
	"context"
	"errors"
	"mercadomio-backend/models"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// OrderService handles order operations
type OrderService struct {
	db             *mongo.Database
	collection     *mongo.Collection
	productService ProductService
}

// NewOrderService creates a new order service
func NewOrderService(db *mongo.Database) *OrderService {
	return &OrderService{
		db:         db,
		collection: db.Collection("orders"),
	}
}

// SetProductService sets the product service for order enrichment
func (s *OrderService) SetProductService(productService ProductService) {
	s.productService = productService
}

// CreateOrderFromCart creates an order from cart items
func (s *OrderService) CreateOrderFromCart(ctx context.Context, userID string, cartItems []CartItem) (*models.Order, error) {
	// Validate user ID
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, errors.New("invalid user ID")
	}

	// Convert cart items to order items
	var orderItems []models.OrderItem
	total := 0.0

	for _, cartItem := range cartItems {
		if cartItem.Quantity <= 0 {
			return nil, errors.New("invalid item quantity")
		}

		// Get product details
		productID, err := primitive.ObjectIDFromHex(cartItem.ProductID)
		if err != nil {
			return nil, errors.New("invalid product ID: " + cartItem.ProductID)
		}
		product, err := s.productService.GetProductByID(ctx, productID)
		if err != nil {
			return nil, errors.New("product not found: " + cartItem.ProductID)
		}

		orderItem := models.OrderItem{
			ProductID:   productID,
			VariantID:   cartItem.VariantID,
			Quantity:    cartItem.Quantity,
			Price:       product.BasePrice, // Use base price, can be enhanced with variant pricing
			ProductName: product.Name,
			ImageURL:    product.ImageURL,
		}

		orderItems = append(orderItems, orderItem)
		total += orderItem.Price * float64(orderItem.Quantity)
	}

	if len(orderItems) == 0 {
		return nil, errors.New("no valid items in cart")
	}

	if total <= 0 {
		return nil, errors.New("invalid order total")
	}

	// Create order
	now := time.Now()
	order := &models.Order{
		ID:          primitive.NewObjectID(),
		UserID:      userObjID,
		Items:       orderItems,
		Total:       total,
		Status:      models.OrderStatusPending,
		PaymentInfo: nil,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	// Validate order
	if err := order.Validate(); err != nil {
		return nil, err
	}

	// Save to database
	_, err = s.collection.InsertOne(ctx, order)
	if err != nil {
		return nil, err
	}

	return order, nil
}

// GetOrderByID retrieves an order by ID
func (s *OrderService) GetOrderByID(ctx context.Context, orderID string) (*models.Order, error) {
	orderObjID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return nil, errors.New("invalid order ID")
	}

	var order models.Order
	err = s.collection.FindOne(ctx, bson.M{"_id": orderObjID}).Decode(&order)
	if err != nil {
		return nil, errors.New("order not found")
	}

	return &order, nil
}

// GetOrderByConektaID retrieves an order by its stored Conekta order ID
func (s *OrderService) GetOrderByConektaID(ctx context.Context, conektaOrderID string) (*models.Order, error) {
	var order models.Order
	err := s.collection.FindOne(ctx, bson.M{"paymentInfo.conekta_order_id": conektaOrderID}).Decode(&order)
	if err != nil {
		return nil, errors.New("order not found for conekta order: " + conektaOrderID)
	}
	return &order, nil
}

// AttachPaymentInfo stores payment reference details without changing order status
func (s *OrderService) AttachPaymentInfo(ctx context.Context, orderID string, paymentInfo map[string]interface{}) error {
	orderObjID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	update := bson.M{
		"paymentInfo": paymentInfo,
		"updatedAt":   time.Now(),
	}

	result, err := s.collection.UpdateOne(
		ctx,
		bson.M{"_id": orderObjID},
		bson.M{"$set": update},
	)
	if err != nil {
		return err
	}

	if result.ModifiedCount == 0 {
		return errors.New("order not updated")
	}

	return nil
}

// GetOrdersByUserID retrieves orders for a user with pagination
func (s *OrderService) GetOrdersByUserID(ctx context.Context, userID string, page, limit int) ([]*models.Order, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, errors.New("invalid user ID")
	}

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20 // Default limit
	}

	skip := (page - 1) * limit

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1}) // Most recent first

	cursor, err := s.collection.Find(ctx, bson.M{"userId": userObjID}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var orders []*models.Order
	for cursor.Next(ctx) {
		var order models.Order
		if err := cursor.Decode(&order); err != nil {
			return nil, err
		}
		orders = append(orders, &order)
	}

	return orders, cursor.Err()
}

// GetAllOrders retrieves all orders with pagination and optional status filter (admin)
func (s *OrderService) GetAllOrders(ctx context.Context, page, limit int, status string) ([]*models.Order, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20 // Default limit
	}

	skip := (page - 1) * limit

	filter := bson.M{}
	if status != "" {
		filter["status"] = models.OrderStatus(status)
	}

	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1}) // Most recent first

	cursor, err := s.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var orders []*models.Order
	for cursor.Next(ctx) {
		var order models.Order
		if err := cursor.Decode(&order); err != nil {
			return nil, err
		}
		orders = append(orders, &order)
	}

	return orders, cursor.Err()
}

// CountOrders returns the total number of orders, optionally filtered by status (admin)
func (s *OrderService) CountOrders(ctx context.Context, status string) (int64, error) {
	filter := bson.M{}
	if status != "" {
		filter["status"] = models.OrderStatus(status)
	}

	return s.collection.CountDocuments(ctx, filter)
}

// adjustStock applies a delta (-1 decrement, +1 restore) to each order item's variant stock.
func (s *OrderService) adjustStock(ctx context.Context, items []models.OrderItem, delta int) error {
	if s.productService == nil {
		return nil
	}

	for _, item := range items {
		if item.VariantID == "" {
			continue
		}
		var err error
		if delta < 0 {
			err = s.productService.DecrementStock(ctx, item.ProductID.Hex(), item.VariantID, item.Quantity)
		} else {
			err = s.productService.IncrementStock(ctx, item.ProductID.Hex(), item.VariantID, item.Quantity)
		}
		if err != nil {
			return err
		}
	}

	return nil
}

// UpdateOrderStatus updates the status of an order
func (s *OrderService) UpdateOrderStatus(ctx context.Context, orderID string, newStatus models.OrderStatus) error {
	orderObjID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	// Get current order
	order, err := s.GetOrderByID(ctx, orderID)
	if err != nil {
		return err
	}

	// Validate status transition
	if !order.CanTransitionTo(newStatus) {
		return errors.New("invalid status transition from " + string(order.Status) + " to " + string(newStatus))
	}

	// Inventory: decrement stock when an order becomes paid
	if newStatus == models.OrderStatusPaid && order.Status != models.OrderStatusPaid {
		if err := s.adjustStock(ctx, order.Items, -1); err != nil {
			return errors.New("failed to update inventory: " + err.Error())
		}
	}

	// Inventory: restore stock when a paid order is cancelled
	if newStatus == models.OrderStatusCancelled && order.Status == models.OrderStatusPaid {
		if err := s.adjustStock(ctx, order.Items, 1); err != nil {
			return errors.New("failed to restore inventory: " + err.Error())
		}
	}

	// Update status
	update := bson.M{
		"status":    newStatus,
		"updatedAt": time.Now(),
	}

	result, err := s.collection.UpdateOne(
		ctx,
		bson.M{"_id": orderObjID},
		bson.M{"$set": update},
	)

	if err != nil {
		return err
	}

	if result.ModifiedCount == 0 {
		return errors.New("order not updated")
	}

	return nil
}

// UpdateOrderPayment updates payment information
func (s *OrderService) UpdateOrderPayment(ctx context.Context, orderID string, paymentInfo map[string]interface{}) error {
	orderObjID, err := primitive.ObjectIDFromHex(orderID)
	if err != nil {
		return errors.New("invalid order ID")
	}

	update := bson.M{
		"paymentInfo": paymentInfo,
		"updatedAt":   time.Now(),
	}

	result, err := s.collection.UpdateOne(
		ctx,
		bson.M{"_id": orderObjID},
		bson.M{"$set": update},
	)

	if err != nil {
		return err
	}

	if result.ModifiedCount == 0 {
		return errors.New("order not updated")
	}

	// Auto-transition to paid status if payment info is provided
	return s.UpdateOrderStatus(ctx, orderID, models.OrderStatusPaid)
}

// GetOrderStats returns basic order statistics
func (s *OrderService) GetOrderStats(ctx context.Context) (map[string]int, error) {
	pipeline := []bson.M{
		{
			"$group": bson.M{
				"_id":   "$status",
				"count": bson.M{"$sum": 1},
			},
		},
	}

	cursor, err := s.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	stats := make(map[string]int)
	for cursor.Next(ctx) {
		var result struct {
			ID    string `bson:"_id"`
			Count int    `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			return nil, err
		}
		stats[result.ID] = result.Count
	}

	return stats, cursor.Err()
}
