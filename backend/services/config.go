package services

import (
	"errors"
	"time"
)

// CartConfig holds configuration for cart operations
type CartConfig struct {
	DefaultTTL          time.Duration `json:"defaultTTL" bson:"defaultTTL" validate:"required"`
	AbandonedCartTTL    time.Duration `json:"abandonedCartTTL" bson:"abandonedCartTTL" validate:"required"`
	ActiveCartTTL       time.Duration `json:"activeCartTTL" bson:"activeCartTTL" validate:"required"`
	CleanupInterval     time.Duration `json:"cleanupInterval" bson:"cleanupInterval" validate:"required"`
	MaxInactiveDuration time.Duration `json:"maxInactiveDuration" bson:"maxInactiveDuration" validate:"required"`
}

// NewCartConfig creates a new CartConfig with default values
func NewCartConfig() *CartConfig {
	return &CartConfig{
		DefaultTTL:          30 * 24 * time.Hour, // 30 days
		AbandonedCartTTL:    7 * 24 * time.Hour,  // 7 days
		ActiveCartTTL:       90 * 24 * time.Hour, // 90 days
		CleanupInterval:     24 * time.Hour,      // Daily cleanup
		MaxInactiveDuration: 30 * time.Minute,    // 30 minutes
	}
}

// Validate validates the cart configuration
func (cc *CartConfig) Validate() error {
	if cc.DefaultTTL < time.Hour {
		return errors.New("default TTL must be at least 1 hour")
	}
	if cc.AbandonedCartTTL < time.Hour {
		return errors.New("abandoned cart TTL must be at least 1 hour")
	}
	if cc.ActiveCartTTL < time.Hour {
		return errors.New("active cart TTL must be at least 1 hour")
	}
	if cc.CleanupInterval < time.Hour {
		return errors.New("cleanup interval must be at least 1 hour")
	}
	return nil
}

// CartAnalyticsConfig holds configuration for cart analytics
type CartAnalyticsConfig struct {
	TrackAbandonedCarts bool          `json:"trackAbandonedCarts" bson:"trackAbandonedCarts"`
	TrackConversions    bool          `json:"trackConversions" bson:"trackConversions"`
	TrackItemViews      bool          `json:"trackItemViews" bson:"trackItemViews"`
	RetentionPeriod     time.Duration `json:"retentionPeriod" bson:"retentionPeriod" validate:"required"`
}

// NewCartAnalyticsConfig creates a new CartAnalyticsConfig with default values
func NewCartAnalyticsConfig() *CartAnalyticsConfig {
	return &CartAnalyticsConfig{
		TrackAbandonedCarts: true,
		TrackConversions:    true,
		TrackItemViews:      true,
		RetentionPeriod:     90 * 24 * time.Hour, // 90 days
	}
}

// Validate validates the cart analytics configuration
func (cac *CartAnalyticsConfig) Validate() error {
	if cac.RetentionPeriod < 24*time.Hour {
		return errors.New("retention period must be at least 24 hours")
	}
	return nil
}
