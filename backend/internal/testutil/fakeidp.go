package testutil

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/json"
	"net/http"
	"net/http/httptest"

	"github.com/MicahParks/jwkset"
	"github.com/golang-jwt/jwt/v5"
)

// FakeIDP is a minimal OIDC provider for tests: discovery document, JWKS
// endpoint and RS256 token signing.
type FakeIDP struct {
	Server     *httptest.Server
	store      jwkset.Storage
	privateKey *rsa.PrivateKey
	kid        string
}

// NewFakeIDP starts a fake identity provider serving one initial key.
func NewFakeIDP(t TestingT) *FakeIDP {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("failed to generate RSA key: %v", err)
	}

	store := jwkset.NewMemoryStorage()

	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/openid-configuration", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{
			"issuer":   r.Host,
			"jwks_uri": "http://" + r.Host + "/jwks.json",
		})
	})
	mux.HandleFunc("/jwks.json", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		jwks, _ := store.JSONPublic(r.Context())
		_, _ = w.Write(jwks)
	})

	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)

	idp := &FakeIDP{Server: server, store: store, privateKey: key, kid: "initial-key"}
	idp.publish("initial-key", &key.PublicKey)
	return idp
}

// PublishKey adds a new public key under the given KID.
func (idp *FakeIDP) PublishKey(kid string, pub *rsa.PublicKey) { idp.publish(kid, pub) }

// SignToken signs claims with the current private key.
func (idp *FakeIDP) SignToken(claims jwt.Claims, kid string) string {
	return idp.SignTokenWithKey(claims, kid, idp.privateKey)
}

// SignTokenWithKey signs claims with an arbitrary private key.
func (idp *FakeIDP) SignTokenWithKey(claims jwt.Claims, kid string, priv *rsa.PrivateKey) string {
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	token.Header["kid"] = kid
	signed, err := token.SignedString(priv)
	if err != nil {
		panic(err)
	}
	return signed
}

func (idp *FakeIDP) publish(kid string, pub *rsa.PublicKey) {
	jwk, err := jwkset.NewJWKFromKey(pub, jwkset.JWKOptions{
		Metadata: jwkset.JWKMetadataOptions{KID: kid},
	})
	if err != nil {
		panic(err)
	}
	_ = idp.store.KeyWrite(context.Background(), jwk)
}
