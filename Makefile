
VERSION = $(shell git log --format=%h .)

build: bin/ws-linux-amd64 bin/http-linux-amd64

bin/ws-linux-amd64: cmd/websocket/main.go *.go
	GOOS=linux GOARCH=amd64 go build -o bin/ws-linux-amd64 ./cmd/websocket/main.go

bin/http-linux-amd64: cmd/http/main.go *.go
	GOOS=linux GOARCH=amd64 go build -o bin/http-linux-amd64 ./cmd/http/main.go

.PHONY: build