package websocket

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/apigatewaymanagementapi"
)

var apiClient *apigatewaymanagementapi.Client

func init() {
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
	)
	if err != nil {
		log.Printf("Error creating AWS session: %v", err)
		return
	}
	apiClient = apigatewaymanagementapi.NewFromConfig(cfg)
}

func publish(ctx context.Context, endpoint, id string, data []byte) error {
	if endpoint == "" {
		return errors.New("endpointunknown")
	}
	_, err := apiClient.PostToConnection(
		context.TODO(),
		&apigatewaymanagementapi.PostToConnectionInput{
			Data:         data,
			ConnectionId: &id,
		},
		apigatewaymanagementapi.WithEndpointResolver(
			apigatewaymanagementapi.EndpointResolverFromURL(endpoint),
		),
	)
	return err
}

func WebsocketHandler(_ context.Context, req *events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	b, err := json.Marshal(req)
	if err != nil {
		log.Printf("Error marshalling request: %v", err)
		return InternalServerErrorResponse(), nil
	}
	log.Printf("running, Method %s", string(b))
	ws := &WebsocketLambda{
		ConnectionID:      req.RequestContext.ConnectionID,
		EventType:         req.RequestContext.EventType,
		ChannelID:         "test",
		ResourceID:        req.RequestContext.ResourceID,
		ExtendedRequestID: req.RequestContext.ExtendedRequestID,
		RequestTimeEpoch:  req.RequestContext.RequestTimeEpoch,
		Endpoint:          fmt.Sprintf("https://%s/%s", req.RequestContext.DomainName, req.RequestContext.Stage),
	}

	switch ws.EventType {
	case "CONNECT":
		err := ws.save()
		if err != nil {
			log.Printf("Error connecting websocket: %v", err)
			return InternalServerErrorResponse(), err
		}
		return OkResponse(), nil
	case "DISCONNECT":
		err := ws.delete()
		if err != nil {
			log.Printf("Error disconnecting websocket: %v", err)
			return InternalServerErrorResponse(), err
		}
	default:
		msg := fmt.Sprintf("%s? Roger!)", req.Body)
		err := publish(context.TODO(), ws.Endpoint, ws.ConnectionID, []byte(msg))
		if err != nil {
			log.Printf("Error message websocket: %v", err)
			return InternalServerErrorResponse(), err
		}
		return OkResponse(), nil
	}
	return OkResponse(), nil
}

func HTTPHandler(_ context.Context, req *events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	b, err := json.Marshal(req)
	if err != nil {
		log.Printf("Error marshalling request: %v", err)
		return HTTPInternalServerErrorResponse(), nil
	}
	if req.RequestContext.HTTP.Method != "POST" {
		log.Printf("running, Method %s", string(b))
	}
	message := req.Body
	if req.IsBase64Encoded {
		data, err := base64.StdEncoding.DecodeString(message)
		if err != nil {
			log.Printf("Error decoding base64 body: %v", err)
			return HTTPInternalServerErrorResponse(), nil
		}
		message = string(data)
	}
	l, err := getWebsocketLambda("test")
	if err != nil {
		log.Printf("Error decoding base64 body: %v", err)
		return HTTPInternalServerErrorResponse(), nil
	}
	for _, v := range l {
		err = publish(context.TODO(), v.Endpoint, v.ConnectionID, []byte(message))
		if err != nil {
			log.Printf("Error sending message: %v", err)
		}
	}
	return HTTPOKResponse(), nil
}
