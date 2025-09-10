package models

import (
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Category struct {
	ID          primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	Name        string              `bson:"name" json:"name"`
	Description string              `bson:"description" json:"description"`
	ImageURL    string              `bson:"imageUrl" json:"imageUrl"`
	ParentID    *primitive.ObjectID `bson:"parentId,omitempty" json:"parentId"`
	Path        string              `bson:"path" json:"path"`
	Depth       int                 `bson:"depth" json:"depth"`
	Children    []*Category         `bson:"-" json:"children,omitempty"`
	CreatedAt   time.Time           `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time           `bson:"updatedAt" json:"updatedAt"`
}

func (c *Category) SetPath(parentPath string) {
	if parentPath == "" {
		c.Path = "/" + c.ID.Hex() + "/"
		c.Depth = 1
	} else {
		c.Path = parentPath + c.ID.Hex() + "/"
		c.Depth = strings.Count(parentPath, "/")
	}
}

func (c *Category) IsDescendantOf(parentID primitive.ObjectID) bool {
	return strings.Contains(c.Path, "/"+parentID.Hex()+"/")
}

func (c *Category) IsRoot() bool {
	return c.ParentID == nil
}
