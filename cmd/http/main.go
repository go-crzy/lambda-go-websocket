package main

import (
	runtime "github.com/aws/aws-lambda-go/lambda"
	http "github.com/carnage-sh/lambda-go-websocket"
)

func main() {
	runtime.Start(http.HTTPHandler)
}
