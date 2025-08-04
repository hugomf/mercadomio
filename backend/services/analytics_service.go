package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// AnalyticsEvent represents an analytics event stored in the database
type AnalyticsEvent struct {
	ID        primitive.ObjectID     `bson:"_id,omitempty" json:"id"`
	Type      string                 `bson:"type" json:"type"`
	CartID    string                 `bson:"cartId,omitempty" json:"cartId,omitempty"`
	UserID    string                 `bson:"userId,omitempty" json:"userId,omitempty"`
	ProductID string                 `bson:"productId,omitempty" json:"productId,omitempty"`
	Value     float64                `bson:"value,omitempty" json:"value,omitempty"`
	Metadata  map[string]interface{} `bson:"metadata,omitempty" json:"metadata,omitempty"`
	Timestamp time.Time              `bson:"timestamp" json:"timestamp"`
}

// parseTimeRange parses start and end time strings with proper validation
func parseTimeRange(start, end string) (time.Time, time.Time, error) {
	if start == "" {
		return time.Time{}, time.Time{}, errors.New("start date is required")
	}
	if end == "" {
		return time.Time{}, time.Time{}, errors.New("end date is required")
	}

	startTime, err := time.Parse("2006-01-02", start)
	if err != nil {
		return time.Time{}, time.Time{}, errors.New("invalid start date format, expected YYYY-MM-DD")
	}

	endTime, err := time.Parse("2006-01-02", end)
	if err != nil {
		return time.Time{}, time.Time{}, errors.New("invalid end date format, expected YYYY-MM-DD")
	}

	// Validate date range
	if endTime.Before(startTime) {
		return time.Time{}, time.Time{}, errors.New("end date cannot be before start date")
	}

	// Limit query range to prevent performance issues
	maxRange := 365 * 24 * time.Hour // 1 year
	if endTime.Sub(startTime) > maxRange {
		return time.Time{}, time.Time{}, errors.New("date range cannot exceed 365 days")
	}

	// Set end time to end of day in UTC (more precise than adding hours/minutes)
	endTime = endTime.Add(24*time.Hour - time.Nanosecond)

	return startTime.UTC(), endTime.UTC(), nil
}

// AnalyticsService handles all analytics operations separately from business logic
type AnalyticsService interface {
	// Event tracking
	Start() error
	Stop() error

	// Analytics queries
	GetAbandonedCartAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error)
	GetConversionAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error)
	GetProductViewAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error)

	// Infrastructure
	EnsureIndexes(ctx context.Context) error
}

// AnalyticsServiceImpl implements AnalyticsService
type AnalyticsServiceImpl struct {
	db       *mongo.Database
	config   *CartAnalyticsConfig
	eventBus EventBus
}

// NewAnalyticsService creates a new analytics service
func NewAnalyticsService(db *mongo.Database, config *CartAnalyticsConfig, eventBus EventBus) *AnalyticsServiceImpl {
	return &AnalyticsServiceImpl{
		db:       db,
		config:   config,
		eventBus: eventBus,
	}
}

// Start begins listening for domain events
func (as *AnalyticsServiceImpl) Start() error {
	// Subscribe to all cart-related events
	as.eventBus.Subscribe("cart.*", as.handleCartEvent)
	as.eventBus.Subscribe("product.viewed", as.handleProductViewed)

	// Ensure indexes are created
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	return as.EnsureIndexes(ctx)
}

// Stop stops the analytics service (cleanup if needed)
func (as *AnalyticsServiceImpl) Stop() error {
	// In a more sophisticated implementation, we would unsubscribe from events
	// For now, this is a no-op
	return nil
}

// handleCartEvent processes cart-related domain events
func (as *AnalyticsServiceImpl) handleCartEvent(ctx context.Context, event DomainEvent) error {
	switch e := event.(type) {
	case CartItemAdded:
		return as.handleCartItemAdded(ctx, e)
	case CartItemRemoved:
		return as.handleCartItemRemoved(ctx, e)
	case CartItemUpdated:
		return as.handleCartItemUpdated(ctx, e)
	case CartAbandoned:
		return as.handleCartAbandoned(ctx, e)
	case CartConverted:
		return as.handleCartConverted(ctx, e)
	case CartMerged:
		return as.handleCartMerged(ctx, e)
	default:
		return fmt.Errorf("unknown cart event type: %T", event)
	}
}

// handleCartItemAdded processes cart item added events
func (as *AnalyticsServiceImpl) handleCartItemAdded(ctx context.Context, event CartItemAdded) error {
	if !as.config.TrackItemViews {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "item_added",
		CartID:    event.CartID,
		ProductID: event.ProductID,
		UserID:    event.UserID,
		Value:     event.Value,
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"quantity":  event.Quantity,
			"variantId": event.VariantID,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleCartItemRemoved processes cart item removed events
func (as *AnalyticsServiceImpl) handleCartItemRemoved(ctx context.Context, event CartItemRemoved) error {
	if !as.config.TrackItemViews {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "item_removed",
		CartID:    event.CartID,
		ProductID: event.ProductID,
		UserID:    event.UserID,
		Value:     -event.Value, // Negative value for removal
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"quantity":  event.Quantity,
			"variantId": event.VariantID,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleCartItemUpdated processes cart item updated events
func (as *AnalyticsServiceImpl) handleCartItemUpdated(ctx context.Context, event CartItemUpdated) error {
	if !as.config.TrackItemViews {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "item_updated",
		CartID:    event.CartID,
		ProductID: event.ProductID,
		UserID:    event.UserID,
		Value:     event.ValueChange,
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"oldQuantity": event.OldQuantity,
			"newQuantity": event.NewQuantity,
			"variantId":   event.VariantID,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleCartAbandoned processes cart abandoned events
func (as *AnalyticsServiceImpl) handleCartAbandoned(ctx context.Context, event CartAbandoned) error {
	if !as.config.TrackAbandonedCarts {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "abandoned",
		CartID:    event.CartID,
		UserID:    event.UserID,
		Value:     event.Value,
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"itemCount": event.ItemCount,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleCartConverted processes cart converted events
func (as *AnalyticsServiceImpl) handleCartConverted(ctx context.Context, event CartConverted) error {
	if !as.config.TrackConversions {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "conversion",
		CartID:    event.CartID,
		UserID:    event.UserID,
		Value:     event.Value,
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"orderId":   event.OrderID,
			"itemCount": event.ItemCount,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleCartMerged processes cart merged events
func (as *AnalyticsServiceImpl) handleCartMerged(ctx context.Context, event CartMerged) error {
	analyticsEvent := AnalyticsEvent{
		Type:      "cart_merged",
		CartID:    event.UserCartID,
		UserID:    event.UserID,
		Value:     event.Value,
		Timestamp: event.Timestamp,
		Metadata: map[string]interface{}{
			"guestCartId": event.GuestCartID,
			"itemCount":   event.ItemCount,
		},
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// handleProductViewed processes product viewed events
func (as *AnalyticsServiceImpl) handleProductViewed(ctx context.Context, event DomainEvent) error {
	productEvent, ok := event.(ProductViewed)
	if !ok {
		return fmt.Errorf("expected ProductViewed event, got %T", event)
	}

	if !as.config.TrackItemViews {
		return nil
	}

	analyticsEvent := AnalyticsEvent{
		Type:      "product_view",
		ProductID: productEvent.ProductID,
		UserID:    productEvent.UserID,
		Timestamp: productEvent.Timestamp,
		Metadata: map[string]interface{}{
			"source":    productEvent.Source,
			"sessionId": productEvent.SessionID,
		},
	}

	// Add any additional metadata
	for k, v := range productEvent.Metadata {
		analyticsEvent.Metadata[k] = v
	}

	return as.trackEvent(ctx, analyticsEvent)
}

// trackEvent stores an analytics event in the database
func (as *AnalyticsServiceImpl) trackEvent(ctx context.Context, event AnalyticsEvent) error {
	if as.db == nil {
		return errors.New("database connection not initialized")
	}

	event.ID = primitive.NewObjectID()
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	collection := as.db.Collection("cart_analytics")
	_, err := collection.InsertOne(ctx, event)
	if err != nil {
		return fmt.Errorf("failed to track analytics event: %w", err)
	}

	return nil
}

// GetAbandonedCartAnalytics returns abandoned cart analytics
func (as *AnalyticsServiceImpl) GetAbandonedCartAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error) {
	if !as.config.TrackAbandonedCarts {
		return []CartAnalyticsResult{}, nil
	}

	startTime, endTime, err := parseTimeRange(start, end)
	if err != nil {
		return nil, err
	}

	pipeline := []bson.M{
		{
			"$match": bson.M{
				"type": "abandoned",
				"timestamp": bson.M{
					"$gte": startTime,
					"$lte": endTime,
				},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m-%d",
						"date":   "$timestamp",
					},
				},
				"count": bson.M{"$sum": 1},
				"value": bson.M{"$sum": "$value"},
			},
		},
	}

	return as.runAnalyticsQuery(ctx, pipeline)
}

// GetConversionAnalytics returns conversion analytics
func (as *AnalyticsServiceImpl) GetConversionAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error) {
	if !as.config.TrackConversions {
		return []CartAnalyticsResult{}, nil
	}

	startTime, endTime, err := parseTimeRange(start, end)
	if err != nil {
		return nil, err
	}

	pipeline := []bson.M{
		{
			"$match": bson.M{
				"type": "conversion",
				"timestamp": bson.M{
					"$gte": startTime,
					"$lte": endTime,
				},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m-%d",
						"date":   "$timestamp",
					},
				},
				"count": bson.M{"$sum": 1},
				"value": bson.M{"$sum": "$value"},
			},
		},
	}

	return as.runAnalyticsQuery(ctx, pipeline)
}

// GetProductViewAnalytics returns product view analytics
func (as *AnalyticsServiceImpl) GetProductViewAnalytics(ctx context.Context, start, end string) ([]CartAnalyticsResult, error) {
	if !as.config.TrackItemViews {
		return []CartAnalyticsResult{}, nil
	}

	startTime, endTime, err := parseTimeRange(start, end)
	if err != nil {
		return nil, err
	}

	pipeline := []bson.M{
		{
			"$match": bson.M{
				"type": "product_view",
				"timestamp": bson.M{
					"$gte": startTime,
					"$lte": endTime,
				},
			},
		},
		{
			"$group": bson.M{
				"_id": bson.M{
					"$dateToString": bson.M{
						"format": "%Y-%m-%d",
						"date":   "$timestamp",
					},
				},
				"count": bson.M{"$sum": 1},
			},
		},
	}

	return as.runAnalyticsQuery(ctx, pipeline)
}

// runAnalyticsQuery executes an analytics aggregation query
func (as *AnalyticsServiceImpl) runAnalyticsQuery(ctx context.Context, pipeline []bson.M) ([]CartAnalyticsResult, error) {
	if as.db == nil {
		return nil, errors.New("database connection not initialized")
	}

	collection := as.db.Collection("cart_analytics")
	opts := options.Aggregate().SetMaxTime(30 * time.Second)

	cursor, err := collection.Aggregate(ctx, pipeline, opts)
	if err != nil {
		return nil, errors.New("analytics query failed: " + err.Error())
	}
	defer cursor.Close(ctx)

	var results []CartAnalyticsResult
	if err := cursor.All(ctx, &results); err != nil {
		return nil, errors.New("failed to decode analytics results: " + err.Error())
	}

	// Return empty slice if no results found instead of nil
	if results == nil {
		results = []CartAnalyticsResult{}
	}

	return results, nil
}

// EnsureIndexes creates necessary indexes for analytics queries
func (as *AnalyticsServiceImpl) EnsureIndexes(ctx context.Context) error {
	if as.db == nil {
		return errors.New("database connection not initialized")
	}

	collection := as.db.Collection("cart_analytics")

	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "type", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("type_timestamp_idx"),
		},
		{
			Keys: bson.D{
				{Key: "cartId", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("cartId_timestamp_idx"),
		},
		{
			Keys: bson.D{
				{Key: "productId", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("productId_timestamp_idx"),
		},
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("userId_timestamp_idx"),
		},
		{
			Keys: bson.D{
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("timestamp_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		return errors.New("failed to create analytics indexes: " + err.Error())
	}

	return nil
}
