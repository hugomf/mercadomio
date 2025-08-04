package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Category struct {
	ID          primitive.ObjectID   `bson:"_id,omitempty" json:"id"`
	Name        string               `bson:"name" json:"name"`
	Description string               `bson:"description" json:"description"`
	ParentID    *primitive.ObjectID  `bson:"parentId,omitempty" json:"parentId"`
	Children    []primitive.ObjectID `bson:"children,omitempty" json:"children"`
	CreatedAt   time.Time            `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time            `bson:"updatedAt" json:"updatedAt"`
}
