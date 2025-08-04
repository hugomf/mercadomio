package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"go.mongodb.org/mongo-driver/mongo"
)

// CartServiceImpl implements CartService
type CartServiceImpl struct {
	redis          *redis.Client
	productService ProductService
	config         *CartConfig
	db             *mongo.Database
	eventBus       EventBus
	lastActivity   map[string]time.Time // Tracks last activity per cart
}

// Ensure CartServiceImpl implements CartService
var _ CartService = (*CartServiceImpl)(nil)

// NewCartService creates a new CartService
func NewCartService(redis *redis.Client, ps ProductService, config *CartConfig, db *mongo.Database, eventBus EventBus) *CartServiceImpl {
	cs := &CartServiceImpl{
		redis:          redis,
		productService: ps,
		config:         config,
		db:             db,
		eventBus:       eventBus,
		lastActivity:   make(map[string]time.Time),
	}

	go cs.startCleanupRoutine()
	return cs
}

// startCleanupRoutine starts the background cleanup routine
func (cs *CartServiceImpl) startCleanupRoutine() {
	ticker := time.NewTicker(cs.config.CleanupInterval)
	defer ticker.Stop()

	for range ticker.C {
		cs.cleanupExpiredCarts()
	}
}

// cleanupExpiredCarts removes expired carts and publishes abandonment events
func (cs *CartServiceImpl) cleanupExpiredCarts() {
	ctx := context.Background()
	now := time.Now()

	for cartID, lastActive := range cs.lastActivity {
		inactiveDuration := now.Sub(lastActive)
		var ttl time.Duration

		switch {
		case inactiveDuration > cs.config.MaxInactiveDuration:
			ttl = cs.config.AbandonedCartTTL
		default:
			ttl = cs.config.ActiveCartTTL
		}

		if now.Sub(lastActive) > ttl {
			// Publish cart abandonment event before deletion
			if inactiveDuration > cs.config.MaxInactiveDuration {
				cart, err := cs.GetCart(ctx, cartID)
				if err == nil && len(cart.Items) > 0 {
					cartValue := cs.calculateCartValue(ctx, cart)

					// Publish abandonment event (non-blocking)
					event := CartAbandoned{
						CartID:    cartID,
						UserID:    cart.UserID,
						Value:     cartValue,
						ItemCount: len(cart.Items),
						Timestamp: now,
					}
					cs.eventBus.Publish(ctx, event)
				}
			}

			cs.redis.Del(ctx, cs.getCartKey(cartID))
			delete(cs.lastActivity, cartID)
		}
	}
}

// updateActivity updates the last activity time for a cart
func (cs *CartServiceImpl) updateActivity(cartID string) {
	cs.lastActivity[cartID] = time.Now()
}

// getCartKey returns the Redis key for a cart
func (cs *CartServiceImpl) getCartKey(cartID string) string {
	return "cart:" + cartID
}

// calculateCartValue calculates the total value of items in a cart
func (cs *CartServiceImpl) calculateCartValue(ctx context.Context, cart *Cart) float64 {
	if cart == nil || len(cart.Items) == 0 {
		return 0.0
	}

	var totalValue float64
	for _, item := range cart.Items {
		// Get product to calculate value
		product, err := cs.productService.GetProduct(ctx, item.ProductID)
		if err != nil {
			continue // Skip items we can't price
		}

		itemPrice := product.BasePrice
		// Add variant price adjustment if applicable
		if item.VariantID != "" {
			variant, err := cs.productService.GetVariant(ctx, item.ProductID, item.VariantID)
			if err == nil {
				itemPrice += variant.PriceAdjustment
			}
		}

		totalValue += itemPrice * float64(item.Quantity)
	}

	return totalValue
}

// GetCart retrieves a cart by ID
func (cs *CartServiceImpl) GetCart(ctx context.Context, cartID string) (*Cart, error) {
	data, err := cs.redis.Get(ctx, cs.getCartKey(cartID)).Result()
	if err == redis.Nil {
		return &Cart{
			ID:        cartID,
			Items:     []CartItem{},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}, nil
	}
	if err != nil {
		return nil, err
	}

	var cart Cart
	if err := json.Unmarshal([]byte(data), &cart); err != nil {
		return nil, err
	}
	return &cart, nil
}

// SaveCart saves a cart to Redis
func (cs *CartServiceImpl) SaveCart(ctx context.Context, cart *Cart) error {
	if cart == nil {
		return errors.New("cart cannot be nil")
	}
	if cart.ID == "" {
		return errors.New("cart ID cannot be empty")
	}

	cart.UpdatedAt = time.Now()
	data, err := json.Marshal(cart)
	if err != nil {
		return err
	}

	// Update activity tracking
	cs.updateActivity(cart.ID)

	// Determine TTL based on activity
	inactiveDuration := time.Since(cs.lastActivity[cart.ID])
	var ttl time.Duration

	switch {
	case inactiveDuration > cs.config.MaxInactiveDuration:
		ttl = cs.config.AbandonedCartTTL
	default:
		ttl = cs.config.ActiveCartTTL
	}

	return cs.redis.Set(ctx, cs.getCartKey(cart.ID), data, ttl).Err()
}

// AddToCart adds an item to a cart
func (cs *CartServiceImpl) AddToCart(ctx context.Context, cartID string, item CartItem) error {
	if cartID == "" {
		return errors.New("cart ID cannot be empty")
	}
	if item.Quantity <= 0 {
		return errors.New("quantity must be positive")
	}

	// Validate product exists
	product, err := cs.productService.GetProduct(ctx, item.ProductID)
	if err != nil {
		return fmt.Errorf("product validation failed: %w", err)
	}

	// Validate variant if specified
	var variant *Variant
	if item.VariantID != "" {
		variant, err = cs.productService.GetVariant(ctx, item.ProductID, item.VariantID)
		if err != nil {
			return fmt.Errorf("variant validation failed: %w", err)
		}
	}

	cart, err := cs.GetCart(ctx, cartID)
	if err != nil {
		return err
	}

	// Calculate item value for event
	itemPrice := product.BasePrice
	if variant != nil {
		itemPrice += variant.PriceAdjustment
	}
	itemValue := itemPrice * float64(item.Quantity)

	// Update quantity if item already exists
	for i, existing := range cart.Items {
		if existing.ProductID == item.ProductID && existing.VariantID == item.VariantID {
			cart.Items[i].Quantity += item.Quantity
			err = cs.SaveCart(ctx, cart)
			if err != nil {
				return err
			}

			// Publish item added event
			event := CartItemAdded{
				CartID:    cartID,
				ProductID: item.ProductID,
				VariantID: item.VariantID,
				UserID:    cart.UserID,
				Quantity:  item.Quantity,
				Value:     itemValue,
				Timestamp: time.Now(),
			}
			cs.eventBus.Publish(ctx, event)
			return nil
		}
	}

	// Add new item
	cart.Items = append(cart.Items, item)
	err = cs.SaveCart(ctx, cart)
	if err != nil {
		return err
	}

	// Publish item added event
	event := CartItemAdded{
		CartID:    cartID,
		ProductID: item.ProductID,
		VariantID: item.VariantID,
		UserID:    cart.UserID,
		Quantity:  item.Quantity,
		Value:     itemValue,
		Timestamp: time.Now(),
	}
	cs.eventBus.Publish(ctx, event)
	return nil
}

// RemoveFromCart removes an item from a cart
func (cs *CartServiceImpl) RemoveFromCart(ctx context.Context, cartID string, productID string, variantID string) error {
	cart, err := cs.GetCart(ctx, cartID)
	if err != nil {
		return err
	}

	for i, item := range cart.Items {
		if item.ProductID == productID && item.VariantID == variantID {
			// Calculate item value for event
			product, err := cs.productService.GetProduct(ctx, productID)
			if err != nil {
				return fmt.Errorf("product validation failed: %w", err)
			}

			itemPrice := product.BasePrice
			if variantID != "" {
				variant, err := cs.productService.GetVariant(ctx, productID, variantID)
				if err == nil {
					itemPrice += variant.PriceAdjustment
				}
			}
			itemValue := itemPrice * float64(item.Quantity)

			// Remove item
			cart.Items = append(cart.Items[:i], cart.Items[i+1:]...)
			err = cs.SaveCart(ctx, cart)
			if err != nil {
				return err
			}

			// Publish item removed event
			event := CartItemRemoved{
				CartID:    cartID,
				ProductID: productID,
				VariantID: variantID,
				UserID:    cart.UserID,
				Quantity:  item.Quantity,
				Value:     itemValue,
				Timestamp: time.Now(),
			}
			cs.eventBus.Publish(ctx, event)
			return nil
		}
	}

	return nil
}

// UpdateCartItem updates the quantity of an item in a cart
func (cs *CartServiceImpl) UpdateCartItem(ctx context.Context, cartID string, productID string, variantID string, quantity int) error {
	if quantity <= 0 {
		return cs.RemoveFromCart(ctx, cartID, productID, variantID)
	}

	cart, err := cs.GetCart(ctx, cartID)
	if err != nil {
		return err
	}

	for i, item := range cart.Items {
		if item.ProductID == productID && item.VariantID == variantID {
			oldQuantity := item.Quantity

			// Calculate value change for event
			product, err := cs.productService.GetProduct(ctx, productID)
			if err != nil {
				return fmt.Errorf("product validation failed: %w", err)
			}

			itemPrice := product.BasePrice
			if variantID != "" {
				variant, err := cs.productService.GetVariant(ctx, productID, variantID)
				if err == nil {
					itemPrice += variant.PriceAdjustment
				}
			}
			valueChange := itemPrice * float64(quantity-oldQuantity)

			// Update quantity
			cart.Items[i].Quantity = quantity
			err = cs.SaveCart(ctx, cart)
			if err != nil {
				return err
			}

			// Publish item updated event
			event := CartItemUpdated{
				CartID:      cartID,
				ProductID:   productID,
				VariantID:   variantID,
				UserID:      cart.UserID,
				OldQuantity: oldQuantity,
				NewQuantity: quantity,
				ValueChange: valueChange,
				Timestamp:   time.Now(),
			}
			cs.eventBus.Publish(ctx, event)
			return nil
		}
	}

	return errors.New("item not found in cart")
}

// ClearCart clears all items from a cart
func (cs *CartServiceImpl) ClearCart(ctx context.Context, cartID string) error {
	return cs.redis.Del(ctx, cs.getCartKey(cartID)).Err()
}

// MergeCarts merges a guest cart into a user cart
func (cs *CartServiceImpl) MergeCarts(ctx context.Context, guestCartID string, userCartID string) error {
	guestCart, err := cs.GetCart(ctx, guestCartID)
	if err != nil {
		return err
	}

	userCart, err := cs.GetCart(ctx, userCartID)
	if err != nil {
		return err
	}

	// Calculate merge value
	mergeValue := cs.calculateCartValue(ctx, guestCart)
	itemCount := len(guestCart.Items)

	// Merge items by combining quantities of identical items
	for _, guestItem := range guestCart.Items {
		found := false
		for i, userItem := range userCart.Items {
			if userItem.ProductID == guestItem.ProductID && userItem.VariantID == guestItem.VariantID {
				userCart.Items[i].Quantity += guestItem.Quantity
				found = true
				break
			}
		}
		if !found {
			userCart.Items = append(userCart.Items, guestItem)
		}
	}

	// Save merged cart
	if err := cs.SaveCart(ctx, userCart); err != nil {
		return err
	}

	// Publish cart merged event
	event := CartMerged{
		GuestCartID: guestCartID,
		UserCartID:  userCartID,
		UserID:      userCart.UserID,
		ItemCount:   itemCount,
		Value:       mergeValue,
		Timestamp:   time.Now(),
	}
	cs.eventBus.Publish(ctx, event)

	// Clear guest cart
	return cs.ClearCart(ctx, guestCartID)
}
