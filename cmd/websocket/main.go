package main

import (
  websocket "github.com/carnage-sh/lambda-go-websocket"
  runtime "github.com/aws/aws-lambda-go/lambda"
)

func main() {
  runtime.Start(websocket.WebsocketHandler)
}

