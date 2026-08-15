package services

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"mercadomio-backend/models"
)

// PricingContext carries the "who/what/when" inputs to price resolution.
type PricingContext struct {
	Date         time.Time
	CustomerID   string
	CustomerTier string
	CouponCode   string
	CartSubtotal float64
	CartQuantity int
}

// PriceInput is a single purchasable line to price.
type PriceInput struct {
	Product  *Product
	Variant  *Variant
	Quantity int
}

// PricedLine is the resolved result for a single line.
type PricedLine struct {
	ProductID   string
	VariantID   string
	BasePrice   float64
	UnitPrice   float64
	Quantity    int
	Subtotal    float64 // base * qty
	LineTotal   float64 // unit * qty
	Discount    float64 // subtotal - linetotal
	AppliedSets []models.AppliedPriceRule
}

// PriceResult is the aggregate resolution for an order.
type PriceResult struct {
	Subtotal         float64
	Discount         float64
	Total            float64
	Lines            []PricedLine
	AppliedSets      []models.AppliedPriceRule
	AppliedScheduleNames []string
}

// PricingService exposes CRUD + resolution.
type PricingService struct {
	db             *mongo.Database
	sets           *mongo.Collection // price_sets
	schedules      *mongo.Collection // price_schedules
	history        *mongo.Collection // price_history
	productService ProductService
}

func NewPricingService(db *mongo.Database, productService ProductService) *PricingService {
	return &PricingService{
		db:             db,
		sets:           db.Collection("price_sets"),
		schedules:      db.Collection("price_schedules"),
		history:        db.Collection("price_history"),
		productService: productService,
	}
}

// SetProductService wires the product service used to enrich lines.
func (s *PricingService) SetProductService(productService ProductService) {
	s.productService = productService
}

// GetProductForPrice loads a product by id for pricing resolution.
func (s *PricingService) GetProductForPrice(ctx context.Context, productID string) (*Product, error) {
	return s.productService.GetProduct(ctx, productID)
}

// ---- PriceSet CRUD ----

func (s *PricingService) ListPriceSets(ctx context.Context, page, limit int) ([]models.PriceSet, int64, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "priority", Value: 1}, {Key: "createdAt", Value: -1}}).
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit))
	total, _ := s.sets.CountDocuments(ctx, bson.M{})
	cursor, err := s.sets.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, err
	}
	var out []models.PriceSet
	if err := cursor.All(ctx, &out); err != nil {
		return nil, 0, err
	}
	return out, total, nil
}

func (s *PricingService) GetPriceSet(ctx context.Context, id string) (*models.PriceSet, error) {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var set models.PriceSet
	if err := s.sets.FindOne(ctx, bson.M{"_id": objID}).Decode(&set); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, errors.New("price set not found")
		}
		return nil, err
	}
	return &set, nil
}

func (s *PricingService) CreatePriceSet(ctx context.Context, set *models.PriceSet) (*models.PriceSet, error) {
	set.ID = primitive.NewObjectID()
	now := time.Now()
	set.CreatedAt = now
	set.UpdatedAt = now
	_, err := s.sets.InsertOne(ctx, set)
	if err != nil {
		return nil, err
	}
	return set, nil
}

func (s *PricingService) UpdatePriceSet(ctx context.Context, id string, update bson.M) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	update["updatedAt"] = time.Now()
	res, err := s.sets.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return errors.New("price set not found")
	}
	return nil
}

func (s *PricingService) DeletePriceSet(ctx context.Context, id string) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	res, err := s.sets.DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return errors.New("price set not found")
	}
	return nil
}

// ---- PriceSchedule CRUD ----

func (s *PricingService) ListPriceSchedules(ctx context.Context, page, limit int) ([]models.PriceSchedule, int64, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "effectiveFrom", Value: -1}}).
		SetSkip(int64((page - 1) * limit)).
		SetLimit(int64(limit))
	total, _ := s.schedules.CountDocuments(ctx, bson.M{})
	cursor, err := s.schedules.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, err
	}
	var out []models.PriceSchedule
	if err := cursor.All(ctx, &out); err != nil {
		return nil, 0, err
	}
	return out, total, nil
}

func (s *PricingService) GetPriceSchedule(ctx context.Context, id string) (*models.PriceSchedule, error) {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var sch models.PriceSchedule
	if err := s.schedules.FindOne(ctx, bson.M{"_id": objID}).Decode(&sch); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, errors.New("price schedule not found")
		}
		return nil, err
	}
	return &sch, nil
}

func (s *PricingService) CreatePriceSchedule(ctx context.Context, sch *models.PriceSchedule) (*models.PriceSchedule, error) {
	sch.ID = primitive.NewObjectID()
	now := time.Now()
	sch.CreatedAt = now
	sch.UpdatedAt = now
	_, err := s.schedules.InsertOne(ctx, sch)
	if err != nil {
		return nil, err
	}
	return sch, nil
}

func (s *PricingService) UpdatePriceSchedule(ctx context.Context, id string, update bson.M) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	update["updatedAt"] = time.Now()
	res, err := s.schedules.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return errors.New("price schedule not found")
	}
	return nil
}

func (s *PricingService) DeletePriceSchedule(ctx context.Context, id string) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	res, err := s.schedules.DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return errors.New("price schedule not found")
	}
	return nil
}

// ---- Price history ----

func (s *PricingService) ListPriceHistory(ctx context.Context, productID string, limit int) ([]models.PriceHistoryEntry, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	opts := options.Find().SetSort(bson.D{{Key: "effectiveAt", Value: -1}}).SetLimit(int64(limit))
	filter := bson.M{}
	if productID != "" {
		if objID, err := primitive.ObjectIDFromHex(productID); err == nil {
			filter["productId"] = objID.Hex()
		}
	}
	cursor, err := s.history.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	var out []models.PriceHistoryEntry
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *PricingService) RecordPriceHistory(ctx context.Context, entries []models.PriceHistoryEntry) error {
	if len(entries) == 0 {
		return nil
	}
	docs := make([]interface{}, len(entries))
	for i, e := range entries {
		if e.EffectiveAt.IsZero() {
			e.EffectiveAt = time.Now()
		}
		docs[i] = e
	}
	_, err := s.history.InsertMany(ctx, docs)
	return err
}

// ---- PricingEngine ----

// ResolvePrices prices all lines through schedules and eligible sets.
func (s *PricingService) ResolvePrices(ctx context.Context, inputs []PriceInput, pc PricingContext) (*PriceResult, error) {
	if pc.Date.IsZero() {
		pc.Date = time.Now()
	}

	lines := make([]PricedLine, 0, len(inputs))
	var schedules []models.PriceSchedule
	for i := range inputs {
		base := inputs[i].Product.BasePrice
		priced, sch, err := s.priceLine(ctx, inputs[i], base, pc.Date)
		if err != nil {
			return nil, err
		}
		schedules = append(schedules, sch...)
		lines = append(lines, priced)
	}

	pc.CartSubtotal = subtotalOf(lines)
	pc.CartQuantity = quantityOf(inputs)

	allSets, err := s.loadActiveSets(ctx)
	if err != nil {
		return nil, err
	}
	applied, stopErr := applySets(allSets, &lines, pc)
	if stopErr != nil {
		return nil, stopErr
	}

	res := &PriceResult{
		Lines:                lines,
		AppliedSets:          applied,
		AppliedScheduleNames: scheduleNames(schedules),
	}
	for i := range lines {
		lines[i].Discount = lines[i].Subtotal - lines[i].LineTotal
		res.Subtotal += lines[i].Subtotal
		res.Discount += lines[i].Discount
		res.Total += lines[i].LineTotal
	}
	return res, nil
}

// priceLine returns the resolved line (schedules already applied to unit price).
func (s *PricingService) priceLine(ctx context.Context, in PriceInput, base float64, date time.Time) (PricedLine, []models.PriceSchedule, error) {
	line := PricedLine{
		ProductID: in.Product.ID.Hex(),
		VariantID: variantIDOf(in.Variant),
		BasePrice: base,
		UnitPrice: base,
		Quantity:  in.Quantity,
	}

	all, err := s.loadActiveSchedules(ctx)
	if err != nil {
		return line, nil, err
	}
	sort.SliceStable(all, func(i, j int) bool { return all[i].Priority < all[j].Priority })

	var applied []models.PriceSchedule
	price := base
	for _, sch := range all {
		if !scheduleInWindow(sch, date) || !scheduleMatches(sch, in) {
			continue
		}
		applied = append(applied, sch)
		switch sch.Mode {
		case models.ScheduleModePercentage:
			price *= 1 + sch.Value/100
		case models.ScheduleModeAbsolute:
			price += sch.Value
		case models.ScheduleModeFixed:
			price = sch.Value
		}
		if price < 0 {
			price = 0
		}
	}

	line.UnitPrice = price
	line.Subtotal = base * float64(in.Quantity)
	line.LineTotal = price * float64(in.Quantity)
	line.Discount = line.Subtotal - line.LineTotal
	return line, applied, nil
}

func (s *PricingService) loadActiveSchedules(ctx context.Context) ([]models.PriceSchedule, error) {
	cursor, err := s.schedules.Find(ctx, bson.M{"active": true})
	if err != nil {
		return nil, err
	}
	var out []models.PriceSchedule
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func (s *PricingService) loadActiveSets(ctx context.Context) ([]models.PriceSet, error) {
	cursor, err := s.sets.Find(ctx, bson.M{"active": true})
	if err != nil {
		return nil, err
	}
	var out []models.PriceSet
	if err := cursor.All(ctx, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func scheduleInWindow(sch models.PriceSchedule, d time.Time) bool {
	if d.Before(sch.EffectiveFrom) {
		return false
	}
	if sch.EffectiveTo != nil && d.After(*sch.EffectiveTo) {
		return false
	}
	return true
}

func scheduleMatches(sch models.PriceSchedule, in PriceInput) bool {
	switch sch.Scope {
	case models.ScheduleScopeGlobal:
		return true
	case models.ScheduleScopeProduct:
		return in.Product != nil && containsStr(sch.ScopeRefs, in.Product.ID.Hex())
	case models.ScheduleScopeVariant:
		return in.Variant != nil && containsStr(sch.ScopeRefs, in.Variant.VariantID)
	case models.ScheduleScopeCategory:
		if in.Product == nil {
			return false
		}
		if containsStr(sch.ScopeRefs, in.Product.Category) {
			return true
		}
		for _, c := range in.Product.Categories {
			if containsStr(sch.ScopeRefs, c.Hex()) {
				return true
			}
		}
	}
	return false
}

func scheduleNames(schs []models.PriceSchedule) []string {
	out := make([]string, 0, len(schs))
	seen := map[string]bool{}
	for _, s := range schs {
		if !seen[s.Name] {
			seen[s.Name] = true
			out = append(out, s.Name)
		}
	}
	return out
}

func variantIDOf(v *Variant) string {
	if v == nil {
		return ""
	}
	return v.VariantID
}

func subtotalOf(lines []PricedLine) float64 {
	t := 0.0
	for _, l := range lines {
		t += l.Subtotal
	}
	return t
}

func quantityOf(inputs []PriceInput) int {
	q := 0
	for _, in := range inputs {
		q += in.Quantity
	}
	return q
}

func containsStr(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

// applySets applies eligible sets to lines; increments usage for coupon sets.
func applySets(all []models.PriceSet, lines *[]PricedLine, pc PricingContext) ([]models.AppliedPriceRule, error) {
	sort.SliceStable(all, func(i, j int) bool { return all[i].Priority < all[j].Priority })

	var applied []models.AppliedPriceRule
	for _, set := range all {
		if !setInWindow(set, pc.Date) || !conditionsMatch(set.Conditions, pc) {
			continue
		}
		setApplied := applySetRules(set, lines)
		if len(setApplied) > 0 {
			applied = append(applied, setApplied...)
		}
		if setApplied != nil && set.StopFurtherRules {
			break
		}
	}
	return applied, nil
}

func setInWindow(set models.PriceSet, d time.Time) bool {
	if set.StartsAt != nil && d.Before(*set.StartsAt) {
		return false
	}
	if set.EndsAt != nil && d.After(*set.EndsAt) {
		return false
	}
	return true
}

func conditionsMatch(c models.PriceConditions, pc PricingContext) bool {
	if c.CouponCode != "" {
		if pc.CouponCode == "" || !strings.EqualFold(c.CouponCode, pc.CouponCode) {
			return false
		}
	}
	if c.MinSubtotal > 0 && pc.CartSubtotal < c.MinSubtotal {
		return false
	}
	if c.MinQuantity > 0 && pc.CartQuantity < c.MinQuantity {
		return false
	}
	if c.CustomerTier != "" && c.CustomerTier != pc.CustomerTier {
		return false
	}
	if len(c.CustomerIDs) > 0 && (pc.CustomerID == "" || !containsStr(c.CustomerIDs, pc.CustomerID)) {
		return false
	}
	return true
}

func applySetRules(set models.PriceSet, lines *[]PricedLine) []models.AppliedPriceRule {
	rules := append([]models.PriceRule(nil), set.Rules...)
	sort.SliceStable(rules, func(i, j int) bool { return rules[i].Priority < rules[j].Priority })

	var applied []models.AppliedPriceRule
	for li := range *lines {
		line := &(*lines)[li]
		for _, rule := range rules {
			if !ruleMatches(rule, line) {
				continue
			}
			discount := 0.0
			switch rule.Kind {
			case models.RuleKindPercentage:
				discount = line.UnitPrice * rule.Amount / 100
			case models.RuleKindAbsolute:
				discount = rule.Amount
			case models.RuleKindOverride:
				discount = line.UnitPrice - rule.Amount
			}
			if rule.MaxDiscount > 0 && discount > rule.MaxDiscount {
				discount = rule.MaxDiscount
			}
			if discount < 0 || discount > line.UnitPrice {
				discount = line.UnitPrice
			}
			if discount <= 0 {
				continue
			}
			line.UnitPrice -= discount
			line.LineTotal = line.UnitPrice * float64(line.Quantity)
			applied = append(applied, models.AppliedPriceRule{
				SetID:    set.ID.Hex(),
				SetName:  set.Name,
				Kind:     rule.Kind,
				Amount:   rule.Amount,
				Discount: discount * float64(line.Quantity),
			})
		}
	}
	return applied
}

func ruleMatches(rule models.PriceRule, line *PricedLine) bool {
	switch rule.Scope {
	case models.RuleScopeAll:
		return true
	case models.RuleScopeProduct:
		return containsStr(rule.ScopeRefs, line.ProductID)
	case models.RuleScopeVariant:
		return line.VariantID != "" && containsStr(rule.ScopeRefs, line.VariantID)
	}
	return false
}