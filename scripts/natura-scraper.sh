#!/usr/bin/env bash
# natura-scraper.sh – fetch Natura MX products -> products.json
# macOS-friendly (no GNU grep, no mapfile)

set -euo pipefail

BASE_URL="https://www.natura.com.mx"
TMP_DIR="$(mktemp -d /tmp/natura-scraper.XXXXXX)"
OUT_FILE="products.json"
trap 'rm -rf "$TMP_DIR"' EXIT

# ------------------------------------------------------------
# 1. Main PLP URLs (hard-coded)
# ------------------------------------------------------------
CATEGORIES=(
  /c/perfumeria
  /c/cosmetica
  /c/cuidado-personal
  /c/cuidado-capilar
  /c/hombre
)

echo "[+] Found ${#CATEGORIES[@]} category pages"

# ------------------------------------------------------------
# 2. Scrape products
# ------------------------------------------------------------
echo "[*] Scraping products …"
: > "$TMP_DIR/products_raw.jsonl"

for cat in "${CATEGORIES[@]}"; do
    echo "   scraping $cat …" >&2
    html=$(curl -sL "${BASE_URL}${cat}")

    # Extract every <script type="application/ld+json">…</script>
    # Works with BSD grep + perl
    perl -0777 -nE '
        while (/<script\s+type="application\/ld\+json"\s*>(.*?)<\/script>/igs) {
            say $1 =~ s/\R//gr;
        }
    ' <<< "$html" \
    | while IFS= read -r json; do
          jq -c 'select(.["@type"]=="Product")' <<< "$json" 2>/dev/null || true
      done \
    >> "$TMP_DIR/products_raw.jsonl"
done

# ------------------------------------------------------------
# 3. Build clean JSON
# ------------------------------------------------------------
echo "[*] Normalising data …"
jq -s '
  map({
      sku:         (.sku // .mpn),
      name:        .name,
      brand:       (.brand // .manufacturer // "Natura"),
      category:    (.category // "Otros"),
      description: (.description // ""),
      price:       (.offers.price // .offers.lowPrice // ""),
      currency:    (.offers.priceCurrency // ""),
      imageURL:    (.image // ""),
      url:         (.url // "")
  })
' "$TMP_DIR/products_raw.jsonl" > "$OUT_FILE"

echo "[+] Done -> $(jq length "$OUT_FILE") products written to $OUT_FILE"