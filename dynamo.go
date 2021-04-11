package websocket

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type WebsocketLambda struct {
	ConnectionID      string `json:"ConnectionID"`
	ChannelID         string `json:"ChannelID"`
	RequestTimeEpoch  int64  `json:"RequestTimeEpoch"`
	ResourceID        string `json:"ResourceID"`
	EventType         string `json:"EventType"`
	ExtendedRequestID string `json:"ExtendedRequestID"`
	Endpoint          string `json:"Endpoint"`
}

var (
	dynClient *dynamodb.Client
	tableName = "WebsocketLambda"
)

func init() {
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
	)
	if err != nil {
		log.Printf("Error creating AWS session: %v", err)
		return
	}
	dynClient = dynamodb.NewFromConfig(cfg)
	if os.Getenv("LAMBDA_TABLE") != "" {
		tableName = os.Getenv("LAMBDA_TABLE")
	}
}

func (ws *WebsocketLambda) save() error {
	av, err := attributevalue.MarshalMap(ws)
	if err != nil {
		log.Fatalf("Got error marshalling new movie item: %s", err)
	}

	input := &dynamodb.PutItemInput{
		Item:      av,
		TableName: aws.String(tableName),
	}

	_, err = dynClient.PutItem(context.TODO(), input)
	if err != nil {
		log.Printf("Got error calling PutItem: %s", err)
		return err
	}
	return nil
}

func (ws *WebsocketLambda) delete() error {
	tableName := tableName
	input := &dynamodb.DeleteItemInput{
		Key: map[string]types.AttributeValue{
			"ConnectionID": &types.AttributeValueMemberS{
				Value: ws.ConnectionID,
			},
		},
		TableName: &tableName,
	}

	_, err := dynClient.DeleteItem(context.TODO(), input)
	if err != nil {
		log.Fatalf("Got error calling DeleteItem: %s", err)
		return err
	}
	return nil
}

func getWebsocketLambda(channel string) ([]WebsocketLambda, error) {
	wsTable := []WebsocketLambda{}
	filt := expression.Name("ChannelID").Equal(expression.Value(channel))
	proj := expression.NamesList(expression.Name("ChannelID"), expression.Name("ConnectionID"), expression.Name("Endpoint"))

	expr, err := expression.NewBuilder().WithFilter(filt).WithProjection(proj).Build()
	if err != nil {
		log.Fatalf("Got error building expression: %s", err)
		return wsTable, err
	}

	for {
		input := &dynamodb.ScanInput{
			ExpressionAttributeNames:  expr.Names(),
			ExpressionAttributeValues: expr.Values(),
			FilterExpression:          expr.Filter(),
			ProjectionExpression:      expr.Projection(),
			TableName:                 aws.String(tableName),
		}

		result, err := dynClient.Scan(context.TODO(), input)
		if err != nil {
			log.Fatalf("Query API call failed: %s", err)
			return wsTable, err
		}
		for _, v := range result.Items {
			ws := WebsocketLambda{}
			switch w := v["ChannelID"].(type) {
			case *types.AttributeValueMemberS:
				ws.ChannelID = w.Value
			default:
				log.Fatalf("Type error, ChannelID is actually %T", v)
			}
			switch w := v["ConnectionID"].(type) {
			case *types.AttributeValueMemberS:
				ws.ConnectionID = w.Value
			default:
				log.Fatalf("Type error, ConnectionID is actually %T", v)
			}
			switch w := v["Endpoint"].(type) {
			case *types.AttributeValueMemberS:
				ws.Endpoint = w.Value
			default:
				log.Fatalf("Type error, Endpoint is actually %T", v)
			}
			wsTable = append(wsTable, ws)
		}
		input.ExclusiveStartKey = result.LastEvaluatedKey

		if input.ExclusiveStartKey == nil {
			break
		}
	}
	return wsTable, nil
}
