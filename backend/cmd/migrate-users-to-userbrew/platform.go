package main

import (
	"context"
	"crypto/rand"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func cryptorandRead(buf []byte) (int, error) {
	return rand.Read(buf)
}

func contextWithTimeout(d time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), d)
}

func fetchMongoUsers(ctx context.Context, uri, dbName string) ([]mongoUser, error) {
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		return nil, err
	}
	defer func() { _ = client.Disconnect(context.Background()) }()

	coll := client.Database(dbName).Collection("users")
	cursor, err := coll.Find(ctx, bson.M{}, options.Find().SetProjection(bson.M{
		"email":        1,
		"name":         1,
		"passwordHash": 1,
	}))
	if err != nil {
		return nil, err
	}
	var users []mongoUser
	if err := cursor.All(ctx, &users); err != nil {
		return nil, err
	}
	return users, nil
}
