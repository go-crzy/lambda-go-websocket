package websocket

import (
	"context"
	"os"
	"testing"

	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

func TestDynamoDBResources(t *testing.T) {
	if os.Getenv("INTEGRATION") != "true" {
		t.Skipf("not integration")
	}
	tableName := tableName
	input := &dynamodb.DescribeTableInput{TableName: &tableName}

	result, err := dynClient.DescribeTable(context.TODO(), input)
	if err != nil {
		t.Errorf("Error: %s", err.Error())
	}
	if result == nil || result.Table.TableName == nil || *result.Table.TableName != tableName {
		t.Errorf("Error, table name should be %s", tableName)
	}
}

func TestWebsocketLambdaSave(t *testing.T) {
	if os.Getenv("INTEGRATION") != "true" {
		t.Skipf("not integration")
	}
	ws := &WebsocketLambda{
		ConnectionID:      "123",
		ChannelID:         "test",
		RequestTimeEpoch:  0,
		ResourceID:        "",
		EventType:         "CONNECT",
		ExtendedRequestID: "123",
	}
	err := ws.save()
	if err != nil {
		t.Errorf("Error: %s", err.Error())
	}
	err = ws.delete()
	if err != nil {
		t.Errorf("Error: %s", err.Error())
	}
}

func TestWebsocketLambdaList(t *testing.T) {
	if os.Getenv("INTEGRATION") != "true" {
		t.Skipf("not integration")
	}
	l, err := getWebsocketLambda("test")
	if err != nil {
		t.Errorf("Error: %s", err.Error())
	}
	if len(l) != 1 {
		t.Errorf("connect to the api with wscat to run integration tests")
	}
	err = publish(context.TODO(), l[0].Endpoint, l[0].ConnectionID, []byte("sending from server..."))
	if err != nil {
		t.Errorf("Error: %s", err.Error())
	}
}
