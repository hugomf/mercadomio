package config

import "os"

type CloudinaryConfig struct {
	CloudName      string
	APIKey         string
	APISecret      string
	BaseURL        string
	ProductsFolder string
}

func GetCloudinaryConfig() CloudinaryConfig {
	return CloudinaryConfig{
		CloudName:      os.Getenv("CLOUDINARY_CLOUD_NAME"),
		APIKey:         os.Getenv("CLOUDINARY_API_KEY"),
		APISecret:      os.Getenv("CLOUDINARY_API_SECRET"),
		BaseURL:        os.Getenv("CLOUDINARY_BASE_URL"),
		ProductsFolder: os.Getenv("CLOUDINARY_PRODUCTS_FOLDER"),
	}
}
