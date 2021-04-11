
VERSION = $(shell git log --format=%h .)

build: terraform/bin/ws-linux-amd64 terraform/bin/http-linux-amd64

terraform/bin/ws-linux-amd64: cmd/websocket/main.go *.go
	GOOS=linux GOARCH=amd64 go build -o terraform/bin/ws-linux-amd64 ./cmd/websocket/main.go

terraform/bin/http-linux-amd64: cmd/http/main.go *.go
	GOOS=linux GOARCH=amd64 go build -o terraform/bin/http-linux-amd64 ./cmd/http/main.go

.PHONY: build
