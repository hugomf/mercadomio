// Command migrate-users-to-userbrew creates a userbrew account for every
// MercadoMío customer that has an email address. Passwords are randomized:
// users recover access through the password-reset flow or Google sign-in.
//
// Usage:
//
//	go run ./cmd/migrate-users-to-userbrew --dry-run
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/userbrew/userbrew-sdk-go"
)

type mongoUser struct {
	ID           string `bson:"_id"`
	Email        string `bson:"email"`
	Name         string `bson:"name"`
	PasswordHash string `bson:"passwordHash"`
}

func usernameFromEmail(email string) string {
	local := strings.SplitN(strings.ToLower(strings.TrimSpace(email)), "@", 2)[0]
	clean := strings.Map(func(r rune) rune {
		if r == '_' {
			return '.'
		}
		if r >= 'a' && r <= 'z' || r >= '0' && r <= '9' || r == '.' || r == '-' {
			return r
		}
		return -1
	}, local)
	if clean == "" {
		clean = "user"
	}
	return clean
}

func randomPassword() string {
	buf := make([]byte, 18)
	if _, err := cryptorandRead(buf); err != nil {
		log.Fatalf("crypto/rand failed: %v", err)
	}
	const alphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$"
	out := make([]byte, len(buf))
	for i, b := range buf {
		out[i] = alphabet[int(b)%len(alphabet)]
	}
	return string(out)
}

type loginResponse struct {
	AccessToken string `json:"access_token"`
}

func login(baseURL, identifier, password string) (string, error) {
	body, _ := json.Marshal(map[string]string{"identifier": identifier, "password": password})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	var out loginResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK || out.AccessToken == "" {
		return "", fmt.Errorf("login failed with status %d", resp.StatusCode)
	}
	return out.AccessToken, nil
}

func userExists(client *userbrew.Client, email string) bool {
	users, err := client.Users().List(&userbrew.UsersListParams{Email: &email})
	if err != nil {
		log.Printf("warning: could not look up %s: %v", email, err)
		return false
	}
	return len(users.Users) > 0
}

func createUser(client *userbrew.Client, u mongoUser) error {
	displayName := strings.TrimSpace(u.Name)
	var dn *string
	if displayName != "" {
		dn = &displayName
	}
	req := userbrew.CreateUserRequest{
		Email:       u.Email,
		Username:    usernameFromEmail(u.Email),
		Password:    randomPassword(),
		DisplayName: dn,
	}
	_, err := client.Users().Create(req)
	return err
}

func run() error {
	mongoURI := flag.String("mongo-uri", "mongodb://localhost:27017", "MongoDB connection URI")
	dbName := flag.String("db", "mercadomio", "MongoDB database name")
	userbrewURL := flag.String("userbrew-url", "http://localhost:8090", "userbrew base URL")
	adminEmail := flag.String("admin-email", os.Getenv("USERBREW_ADMIN_EMAIL"), "userbrew admin identifier")
	adminPassword := flag.String("admin-password", os.Getenv("USERBREW_ADMIN_PASSWORD"), "userbrew admin password")
	dryRun := flag.Bool("dry-run", false, "report what would happen without creating users")
	skipExisting := flag.Bool("skip-existing", true, "skip emails that already exist in userbrew")
	flag.Parse()

	if *adminEmail == "" || *adminPassword == "" {
		return fmt.Errorf("--admin-email and --admin-password are required")
	}

	token, err := login(*userbrewURL, *adminEmail, *adminPassword)
	if err != nil {
		return fmt.Errorf("userbrew login: %w", err)
	}
	client := userbrew.New(*userbrewURL, token)

	ctx, cancel := contextWithTimeout(5 * time.Minute)
	defer cancel()
	users, err := fetchMongoUsers(ctx, *mongoURI, *dbName)
	if err != nil {
		return fmt.Errorf("fetch mongo users: %w", err)
	}

	var created, skipped, failed int
	for _, u := range users {
		if strings.TrimSpace(u.Email) == "" {
			skipped++
			continue
		}
		if *skipExisting && userExists(client, u.Email) {
			fmt.Printf("SKIP   %s (already exists)\n", u.Email)
			skipped++
			continue
		}
		if *dryRun {
			fmt.Printf("CREATE %s (%s)\n", u.Email, usernameFromEmail(u.Email))
			created++
			continue
		}
		if err := createUser(client, u); err != nil {
			fmt.Printf("FAIL   %s: %v\n", u.Email, err)
			failed++
			continue
		}
		fmt.Printf("OK     %s -> %s\n", u.Email, usernameFromEmail(u.Email))
		created++
	}

	fmt.Printf("\nDone: %d created, %d skipped, %d failed (total %d).\n", created, skipped, failed, len(users))
	if !*dryRun {
		fmt.Println("Users must recover access via password reset or Google sign-in.")
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}
