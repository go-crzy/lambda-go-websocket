package websocket

import (
	"context"
	"log"
	"os"
	"testing"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/joho/godotenv"
)

func setup() {
	err := godotenv.Load()
	if err == nil {
		log.Printf("Configuration loaded from .env")
	}
	if os.Getenv("INTEGRATION") == "true" {
		cfg, err := config.LoadDefaultConfig(
			context.TODO(),
		)
		if err != nil {
			log.Printf("Error creating AWS session: %v", err)
			return
		}
		dynClient = dynamodb.NewFromConfig(cfg)
	}
	if os.Getenv("LAMBDA_TABLE") != "" {
		tableName = os.Getenv("LAMBDA_TABLE")
	}
}

func TestMain(m *testing.M) {
	setup()
	code := m.Run()
	os.Exit(code)
}
