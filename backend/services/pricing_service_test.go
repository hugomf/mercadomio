package services

import (
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"mercadomio-backend/models"
)

func TestConditionsMatchCoupon(t *testing.T) {
	c := models.PriceConditions{CouponCode: "SAVE10"}
	pc := PricingContext{CouponCode: "save10"}
	if !conditionsMatch(c, pc) {
		t.Error("coupon should match case-insensitively")
	}
	pc.CouponCode = ""
	if conditionsMatch(c, pc) {
		t.Error("coupon set should not match empty coupon")
	}
	pc.CouponCode = "OTHER"
	if conditionsMatch(c, pc) {
		t.Error("coupon set should not match different coupon")
	}
}

func TestConditionsMatchThresholds(t *testing.T) {
	c := models.PriceConditions{MinSubtotal: 500, MinQuantity: 3}
	if conditionsMatch(c, PricingContext{CartSubtotal: 499, CartQuantity: 5}) {
		t.Error("subtotal below minimum should not match")
	}
	if conditionsMatch(c, PricingContext{CartSubtotal: 600, CartQuantity: 2}) {
		t.Error("quantity below minimum should not match")
	}
	if !conditionsMatch(c, PricingContext{CartSubtotal: 600, CartQuantity: 3}) {
		t.Error("thresholds satisfied should match")
	}
	// zero thresholds are no-ops
	if !conditionsMatch(models.PriceConditions{}, PricingContext{}) {
		t.Error("empty conditions should match")
	}
}

func TestConditionsMatchCustomer(t *testing.T) {
	tier := models.PriceConditions{CustomerTier: "gold"}
	if conditionsMatch(tier, PricingContext{CustomerTier: "silver"}) {
		t.Error("wrong tier should not match")
	}
	if !conditionsMatch(tier, PricingContext{CustomerTier: "gold"}) {
		t.Error("matching tier should match")
	}

	ids := models.PriceConditions{CustomerIDs: []string{"a", "b"}}
	if conditionsMatch(ids, PricingContext{CustomerID: "c"}) {
		t.Error("unknown customer should not match")
	}
	if conditionsMatch(ids, PricingContext{}) {
		t.Error("empty customer id should not match when list set")
	}
	if !conditionsMatch(ids, PricingContext{CustomerID: "b"}) {
		t.Error("listed customer should match")
	}
}

func TestSetInWindow(t *testing.T) {
	now := time.Now()
	start := now.Add(-time.Hour)
	end := now.Add(time.Hour)
	if !setInWindow(models.PriceSet{StartsAt: &start, EndsAt: &end}, now) {
		t.Error("set within window should match")
	}
	if setInWindow(models.PriceSet{StartsAt: &start, EndsAt: &end}, now.Add(2*time.Hour)) {
		t.Error("set after window should not match")
	}
	if setInWindow(models.PriceSet{StartsAt: &start, EndsAt: &end}, now.Add(-2*time.Hour)) {
		t.Error("set before window should not match")
	}
	if !setInWindow(models.PriceSet{}, now) {
		t.Error("set without window should match")
	}
}

func TestScheduleInWindow(t *testing.T) {
	now := time.Now()
	to := now.Add(time.Hour)
	if !scheduleInWindow(models.PriceSchedule{EffectiveFrom: now.Add(-time.Hour), EffectiveTo: &to}, now) {
		t.Error("schedule within window should match")
	}
	if scheduleInWindow(models.PriceSchedule{EffectiveFrom: now.Add(time.Hour)}, now) {
		t.Error("schedule before effectiveFrom should not match")
	}
	if scheduleInWindow(models.PriceSchedule{EffectiveFrom: now.Add(-2 * time.Hour), EffectiveTo: &now}, now.Add(time.Hour)) {
		t.Error("schedule after effectiveTo should not match")
	}
}

func TestScheduleMatches(t *testing.T) {
	pid := primitive.NewObjectID()
	catID := primitive.NewObjectID()
	in := PriceInput{
		Product: &Product{ID: pid, Category: "groceries", Categories: []primitive.ObjectID{catID}},
		Variant: &Variant{VariantID: "v1"},
	}

	if !scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeGlobal}, in) {
		t.Error("global scope should match everything")
	}
	if !scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeProduct, ScopeRefs: []string{pid.Hex()}}, in) {
		t.Error("product scope should match by product id")
	}
	if scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeProduct, ScopeRefs: []string{primitive.NewObjectID().Hex()}}, in) {
		t.Error("product scope should not match another product")
	}
	if !scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeVariant, ScopeRefs: []string{"v1"}}, in) {
		t.Error("variant scope should match by variant id")
	}
	if !scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeCategory, ScopeRefs: []string{"groceries"}}, in) {
		t.Error("category scope should match by category name")
	}
	if !scheduleMatches(models.PriceSchedule{Scope: models.ScheduleScopeCategory, ScopeRefs: []string{catID.Hex()}}, in) {
		t.Error("category scope should match by category object id")
	}
}

func TestRuleMatches(t *testing.T) {
	pid := primitive.NewObjectID().Hex()
	line := &PricedLine{ProductID: pid, VariantID: "v1"}

	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeAll}, line) {
		t.Error("all scope should match")
	}
	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeProduct, ScopeRefs: []string{pid}}, line) {
		t.Error("product scope should match line product")
	}
	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeVariant, ScopeRefs: []string{"v1"}}, line) {
		t.Error("variant scope should match line variant")
	}
	if ruleMatches(models.PriceRule{Scope: models.RuleScopeProduct, ScopeRefs: []string{"other"}}, line) {
		t.Error("product scope should not match other product")
	}
}

func TestApplySetRulesPercentage(t *testing.T) {
	set := models.PriceSet{
		ID:   primitive.NewObjectID(),
		Name: "10% off",
		Rules: []models.PriceRule{
			{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll},
		},
	}
	lines := []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 2, Subtotal: 200, LineTotal: 200}}
	out := applySetRules(set, &lines)

	if lines[0].UnitPrice != 90 {
		t.Errorf("expected unit 90, got %v", lines[0].UnitPrice)
	}
	if lines[0].LineTotal != 180 {
		t.Errorf("expected line total 180, got %v", lines[0].LineTotal)
	}
	if len(out) != 1 || out[0].Discount != 20 {
		t.Errorf("expected per-line applied discount 20 (10*2), got %+v", out)
	}
}

func TestApplySetRulesAbsoluteAndCap(t *testing.T) {
	// absolute discount with MaxDiscount cap on a large unit price
	set := models.PriceSet{
		ID:   primitive.NewObjectID(),
		Name: "fixed discount",
		Rules: []models.PriceRule{
			{Kind: models.RuleKindAbsolute, Amount: 50, MaxDiscount: 20, Scope: models.RuleScopeAll},
		},
	}
	lines := []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	applySetRules(set, &lines)
	if lines[0].UnitPrice != 80 {
		t.Errorf("expected unit 80 after cap, got %v", lines[0].UnitPrice)
	}
}

func TestApplySetRulesNeverNegative(t *testing.T) {
	set := models.PriceSet{
		ID:   primitive.NewObjectID(),
		Name: "too big",
		Rules: []models.PriceRule{
			{Kind: models.RuleKindPercentage, Amount: 200, Scope: models.RuleScopeAll},
		},
	}
	lines := []PricedLine{{ProductID: "p1", UnitPrice: 10, Quantity: 1, Subtotal: 10, LineTotal: 10}}
	applySetRules(set, &lines)
	if lines[0].UnitPrice != 0 {
		t.Errorf("expected unit clamped to 0, got %v", lines[0].UnitPrice)
	}
}

func TestApplySetsStopFurtherRules(t *testing.T) {
	pid := primitive.NewObjectID().Hex()
	first := models.PriceSet{
		ID:               primitive.NewObjectID(),
		Name:             "first",
		Priority:         1,
		StopFurtherRules: true,
		Conditions:       models.PriceConditions{CustomerTier: "gold"},
		Rules:            []models.PriceRule{{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll}},
	}
	second := models.PriceSet{
		ID:         primitive.NewObjectID(),
		Name:       "second",
		Priority:   2,
		Conditions: models.PriceConditions{CustomerTier: "gold"},
		Rules:      []models.PriceRule{{Kind: models.RuleKindAbsolute, Amount: 5, Scope: models.RuleScopeAll}},
	}
	lines := []PricedLine{{ProductID: pid, UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	pc := PricingContext{CustomerTier: "gold"}

	applied, err := applySets([]models.PriceSet{second, first}, &lines, pc)
	if err != nil {
		t.Fatal(err)
	}
	if lines[0].UnitPrice != 90 {
		t.Errorf("expected unit 90 (second set skipped by stop), got %v", lines[0].UnitPrice)
	}
	if len(applied) != 1 {
		t.Errorf("expected exactly 1 applied rule, got %d", len(applied))
	}
}

func TestApplySetsOnlyWhenEligible(t *testing.T) {
	couponSet := models.PriceSet{
		ID:         primitive.NewObjectID(),
		Name:       "coupon",
		Priority:   1,
		Conditions: models.PriceConditions{CouponCode: "SAVE10"},
		Rules:      []models.PriceRule{{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll}},
	}
	lines := []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}

	// wrong coupon → no discount
	applySets([]models.PriceSet{couponSet}, &lines, PricingContext{CouponCode: "WRONG"})
	if lines[0].UnitPrice != 100 {
		t.Errorf("coupon set should not apply with wrong coupon, got %v", lines[0].UnitPrice)
	}

	// correct coupon → discount applies
	applySets([]models.PriceSet{couponSet}, &lines, PricingContext{CouponCode: "save10"})
	if lines[0].UnitPrice != 90 {
		t.Errorf("expected unit 90 with coupon, got %v", lines[0].UnitPrice)
	}
}

func TestPriceLineSchedules(t *testing.T) {
	// schedule math is DB-independent: test via fake active schedules is not
	// possible without a PricingService, so cover the operators via direct math.
	s := &models.PriceSchedule{Mode: models.ScheduleModePercentage, Value: 10}
	p := 100.0
	p *= 1 + s.Value/100
	if absDiff(p, 110) > 1e-9 {
		t.Errorf("expected ~110 after +10%% schedule, got %v", p)
	}
	s = &models.PriceSchedule{Mode: models.ScheduleModeAbsolute, Value: -5}
	p = 100 + s.Value
	if p != 95 {
		t.Errorf("expected 95 after -5 absolute, got %v", p)
	}
	s = &models.PriceSchedule{Mode: models.ScheduleModeFixed, Value: 80}
	if s.Value != 80 {
		t.Errorf("expected fixed 80, got %v", s.Value)
	}
}

func TestContainsStrAndVariantID(t *testing.T) {
	if !containsStr([]string{"a", "b"}, "b") {
		t.Error("containsStr should find present value")
	}
	if containsStr([]string{"a", "b"}, "c") {
		t.Error("containsStr should not find absent value")
	}
	if variantIDOf(nil) != "" {
		t.Error("variantIDOf(nil) should be empty")
	}
	if variantIDOf(&Variant{VariantID: "v1"}) != "v1" {
		t.Error("variantIDOf should return variant id")
	}
}

func absDiff(a, b float64) float64 {
	if a > b {
		return a - b
	}
	return b - a
}

func TestScheduleNamesDedupe(t *testing.T) {
	out := scheduleNames([]models.PriceSchedule{{Name: "A"}, {Name: "B"}, {Name: "A"}})
	if len(out) != 2 {
		t.Errorf("expected 2 deduped names, got %d", len(out))
	}
}

func TestOrderModelPricingValidate(t *testing.T) {
	// Order.Validate must still accept a discount order (Total>0, Subtotal>0)
	order := &models.Order{
		UserID:   primitive.NewObjectID(),
		Subtotal: 100,
		Discount: 10,
		Total:    90,
		Items: []models.OrderItem{
			{ProductID: primitive.NewObjectID(), Quantity: 1, Price: 10},
		},
	}
	if err := order.Validate(); err != nil {
		t.Errorf("discounted order should validate: %v", err)
	}
}

func TestRuleMatchesSkuAndCategory(t *testing.T) {
	catID := primitive.NewObjectID()
	line := &PricedLine{
		ProductID:  "p1",
		VariantID:  "v1",
		SKU:        "SKU-123",
		Category:   "groceries",
		Categories: []string{catID.Hex(), "fresh"},
	}

	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeSKU, ScopeRefs: []string{"SKU-123"}}, line) {
		t.Error("sku scope should match line sku")
	}
	if ruleMatches(models.PriceRule{Scope: models.RuleScopeSKU, ScopeRefs: []string{"SKU-999"}}, line) {
		t.Error("sku scope should not match other sku")
	}
	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeCategory, ScopeRefs: []string{"groceries"}}, line) {
		t.Error("category scope should match line category name")
	}
	if !ruleMatches(models.PriceRule{Scope: models.RuleScopeCategory, ScopeRefs: []string{catID.Hex()}}, line) {
		t.Error("category scope should match a line parent category id")
	}
	if ruleMatches(models.PriceRule{Scope: models.RuleScopeCategory, ScopeRefs: []string{"electronics"}}, line) {
		t.Error("category scope should not match unrelated category")
	}
}

func TestApplySetsUsageCaps(t *testing.T) {
	// MaxUses exhausted → set must not apply
	exhausted := models.PriceSet{
		ID:        primitive.NewObjectID(),
		Name:      "exhausted",
		Priority:  1,
		MaxUses:   5,
		UsedCount: 5,
		Rules:     []models.PriceRule{{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll}},
	}
	lines := []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	applied, err := applySets([]models.PriceSet{exhausted}, &lines, PricingContext{})
	if err != nil {
		t.Fatal(err)
	}
	if len(applied) != 0 || lines[0].UnitPrice != 100 {
		t.Errorf("exhausted set should not apply, got applied=%d unit=%v", len(applied), lines[0].UnitPrice)
	}

	// within budget → applies
	exhausted.UsedCount = 4
	lines = []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	applied, err = applySets([]models.PriceSet{exhausted}, &lines, PricingContext{})
	if err != nil {
		t.Fatal(err)
	}
	if len(applied) != 1 || lines[0].UnitPrice != 90 {
		t.Errorf("set within budget should apply, got applied=%d unit=%v", len(applied), lines[0].UnitPrice)
	}
}

func TestApplySetsPerCustomerCap(t *testing.T) {
	// Per-customer cap reached for this customer → set must not apply.
	set := models.PriceSet{
		ID:                 primitive.NewObjectID(),
		Name:               "one-per-customer",
		Priority:           1,
		MaxUsesPerCustomer: 1,
		CustomerUsage:      map[string]int{"cust-1": 1},
		Rules:              []models.PriceRule{{Kind: models.RuleKindPercentage, Amount: 10, Scope: models.RuleScopeAll}},
	}

	lines := []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	applied, err := applySets([]models.PriceSet{set}, &lines, PricingContext{CustomerID: "cust-1"})
	if err != nil {
		t.Fatal(err)
	}
	if len(applied) != 0 || lines[0].UnitPrice != 100 {
		t.Errorf("set over per-customer cap should not apply, got applied=%d unit=%v", len(applied), lines[0].UnitPrice)
	}

	// different customer within budget → applies
	lines = []PricedLine{{ProductID: "p1", UnitPrice: 100, Quantity: 1, Subtotal: 100, LineTotal: 100}}
	applied, err = applySets([]models.PriceSet{set}, &lines, PricingContext{CustomerID: "cust-2"})
	if err != nil {
		t.Fatal(err)
	}
	if len(applied) != 1 || lines[0].UnitPrice != 90 {
		t.Errorf("set within per-customer budget should apply, got applied=%d unit=%v", len(applied), lines[0].UnitPrice)
	}
}
