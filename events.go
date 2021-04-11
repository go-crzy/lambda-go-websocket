package websocket

import (
	"net/http"

	"github.com/aws/aws-lambda-go/events"
)

func InternalServerErrorResponse() events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
	}
}

func BadRequestResponse() events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusBadRequest,
	}
}

func OkResponse() events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
	}
}

func HTTPInternalServerErrorResponse() events.APIGatewayV2HTTPResponse {
	return events.APIGatewayV2HTTPResponse{
		StatusCode:      http.StatusInternalServerError,
		Body:            `{"code": 500, "message": "Internal Server Error"}`,
		IsBase64Encoded: false,
	}
}

func HTTPBadRequestResponse() events.APIGatewayV2HTTPResponse {
	return events.APIGatewayV2HTTPResponse{
		StatusCode:      http.StatusBadRequest,
		Body:            `{"code": 400, "message": "Bad Request"}`,
		IsBase64Encoded: false,
	}
}

func HTTPOKResponse() events.APIGatewayV2HTTPResponse {
	return events.APIGatewayV2HTTPResponse{
		StatusCode:      http.StatusOK,
		Body:            `{"code": 200, "message": "OK"}`,
		IsBase64Encoded: false,
	}
}
