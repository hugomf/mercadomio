#!/usr/bin/env bash
# natura-scraper.sh – fetch Natura MX products -> products.json
# macOS: needs curl + jq (brew install jq)

set -euo pipefail

BASE_URL="https://www.natura.com.mx"
TMP_DIR="$(mktemp -d)"
OUT_FILE="products.json"

# 1. Collect the PLP (category) links from the home page
echo "[*] Discovering category pages …"
mapfile -t CATEGORIES < <(
  curl -sL "$BASE_URL" \
  | grep -oE 'href="([^"]+/c/[^"]+)"' \
  | cut -d'"' -f2 \
  | sort -u
)

echo "[+] Found ${#CATEGORIES[@]} category pages"

# 2. For every category page, grab the JSON-LD product blocks
echo "[*] Scraping products …"
: > "$TMP_DIR/products_raw.jsonl"

for cat in "${CATEGORIES[@]}"; do
  # Fetch the listing page
  html=$(curl -sL "${BASE_URL}${cat}")

  # Extract each <script type="application/ld+json"> that contains "@type":"Product"
  jq -c '.[] | select(.["@type"]=="Product")' \
     <<< "$(echo "$html" | pup 'script[type="application/ld+json"] text{}' 2>/dev/null || true)" \
  >> "$TMP_DIR/products_raw.jsonl" || true
done

# 3. Build a clean JSON array with the fields we care about
echo "[*] Normalising data …"
jq -s '
  map({
      sku:      (.sku // .mpn),
      name:     .name,
      brand:    (.brand // .manufacturer // "Natura"),
      category: (.category // "Otros"),
      description: (.description // ""),
      price:    (.offers.price // .offers.lowPrice // ""),
      currency: (.offers.priceCurrency // ""),
      imageURL: (.image // ""),
      url:      (.url // "")
  })
' "$TMP_DIR/products_raw.jsonl" > "$OUT_FILE"

echo "[+] Done -> $(wc -l < "$OUT_FILE") products written to $OUT_FILE"