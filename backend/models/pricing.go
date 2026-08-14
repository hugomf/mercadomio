package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PriceRule describes a single pricing adjustment within a PriceSet.
type PriceRule struct {
	Kind        RuleKind  `json:"kind" bson:"kind"`
	Amount      float64   `json:"amount" bson:"amount"`
	Scope       RuleScope `json:"scope" bson:"scope"`
	ScopeRefs   []string  `json:"scopeRefs,omitempty" bson:"scopeRefs,omitempty"`
	MaxDiscount float64   `json:"maxDiscount,omitempty" bson:"maxDiscount,omitempty"`
	Priority    int       `json:"priority" bson:"priority"`
}

// RuleKind mirrors the standard pricing operators.
type RuleKind string

const (
	RuleKindPercentage RuleKind = "percentage"
	RuleKindAbsolute   RuleKind = "absolute"
	RuleKindOverride   RuleKind = "override"
)

// RuleScope controls which items a rule targets.
type RuleScope string

const (
	RuleScopeAll      RuleScope = "all"
	RuleScopeProduct  RuleScope = "product"
	RuleScopeCategory RuleScope = "category"
	RuleScopeVariant  RuleScope = "variant"
	RuleScopeSKU      RuleScope = "sku"
)

// PriceConditions gate whether a PriceSet applies to a given pricing context.
// All non-zero conditions must match (AND semantics).
type PriceConditions struct {
	CouponCode  string   `json:"couponCode,omitempty" bson:"couponCode,omitempty"`
	MinSubtotal float64  `json:"minSubtotal,omitempty" bson:"minSubtotal,omitempty"`
	MinQuantity int      `json:"minQuantity,omitempty" bson:"minQuantity,omitempty"`
	CustomerTier string `json:"customerTier,omitempty" bson:"customerTier,omitempty"`
	CustomerIDs []string `json:"customerIDs,omitempty" bson:"customerIDs,omitempty"`
}

// PriceSet is an ordered, condition-gated bundle of price rules.
type PriceSet struct {
	ID                primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name              string             `json:"name" bson:"name"`
	Description       string             `json:"description,omitempty" bson:"description,omitempty"`
	Priority          int                `json:"priority" bson:"priority"`
	StopFurtherRules  bool               `json:"stopFurtherRules" bson:"stopFurtherRules"`
	Conditions        PriceConditions    `json:"conditions" bson:"conditions"`
	Rules             []PriceRule        `json:"rules" bson:"rules"`
	MaxUses           int                `json:"maxUses,omitempty" bson:"maxUses,omitempty"`
	UsedCount         int                `json:"usedCount" bson:"usedCount"`
	MaxUsesPerCustomer int               `json:"maxUsesPerCustomer,omitempty" bson:"maxUsesPerCustomer,omitempty"`
	Active            bool               `json:"active" bson:"active"`
	StartsAt          *time.Time         `json:"startsAt,omitempty" bson:"startsAt,omitempty"`
	EndsAt            *time.Time         `json:"endsAt,omitempty" bson:"endsAt,omitempty"`
	CreatedAt         time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt         time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// PriceSchedule applies a time-based price formula to a scope (inflation/market).
type PriceSchedule struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name          string             `json:"name" bson:"name"`
	Description   string             `json:"description,omitempty" bson:"description,omitempty"`
	Scope         ScheduleScope      `json:"scope" bson:"scope"`
	ScopeRefs     []string           `json:"scopeRefs,omitempty" bson:"scopeRefs,omitempty"`
	Mode          ScheduleMode       `json:"mode" bson:"mode"`
	Value         float64            `json:"value" bson:"value"`
	Priority      int                `json:"priority" bson:"priority"`
	Active        bool               `json:"active" bson:"active"`
	EffectiveFrom time.Time          `json:"effectiveFrom" bson:"effectiveFrom"`
	EffectiveTo   *time.Time         `json:"effectiveTo,omitempty" bson:"effectiveTo,omitempty"`
	CreatedAt     time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt" bson:"updatedAt"`
}

type ScheduleScope string

const (
	ScheduleScopeGlobal   ScheduleScope = "global"
	ScheduleScopeCategory ScheduleScope = "category"
	ScheduleScopeProduct  ScheduleScope = "product"
	ScheduleScopeVariant  ScheduleScope = "variant"
)

type ScheduleMode string

const (
	ScheduleModePercentage ScheduleMode = "percentage"
	ScheduleModeAbsolute   ScheduleMode = "absolute"
	ScheduleModeFixed      ScheduleMode = "fixed"
)

// PriceHistoryEntry records a single effective price change (audit trail).
type PriceHistoryEntry struct {
	ProductID   string    `json:"productId" bson:"productId"`
	VariantID   string    `json:"variantId,omitempty" bson:"variantId,omitempty"`
	OldPrice    float64   `json:"oldPrice" bson:"oldPrice"`
	NewPrice    float64   `json:"newPrice" bson:"newPrice"`
	Reason      string    `json:"reason,omitempty" bson:"reason,omitempty"`
	SourceType  string    `json:"sourceType" bson:"sourceType"`
	SourceRef   string    `json:"sourceRef,omitempty" bson:"sourceRef,omitempty"`
	EffectiveAt time.Time `json:"effectiveAt" bson:"effectiveAt"`
}

// AppliedPriceRule records which set/rule produced a discount (for order Pricing map).
type AppliedPriceRule struct {
	SetID    string   `json:"setId" bson:"setId"`
	SetName  string   `json:"setName" bson:"setName"`
	Kind     RuleKind `json:"kind" bson:"kind"`
	Amount   float64  `json:"amount" bson:"amount"`
	Discount float64  `json:"discount" bson:"discount"`
}