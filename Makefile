NAME=monorepo-diff-buildkite-plugin
RELEASE_VERSION?= "0.0.0"
ARCH?= "amd64"
COMMIT=$(shell git rev-parse --short=7 HEAD)
TIMESTAMP:=$(shell date -u '+%Y-%m-%dT%I:%M:%SZ')

LDFLAGS += -X main.BuildTime=${TIMESTAMP}
LDFLAGS += -X main.BuildSHA=${COMMIT}
LDFLAGS += -X main.Version=${RELEASE_VERSION}

HAS_DOCKER=$(shell command -v docker;)

.PHONY: all
all: quality test

.PHONY: test-go
test-go:
	go test -race -coverprofile=coverage.out -covermode=atomic

.PHONY: build-docker-test
build-docker-test:
ifneq (${HAS_DOCKER},)
	docker-compose build plugin_test
endif

.PHONY: test-docker
test-docker: build-docker-test
ifneq (${HAS_DOCKER},)
	docker-compose run --rm plugin_test
endif

.PHONY: test
test: test-go test-docker

.PHONY: quality
quality:
	go vet
	go fmt
	go mod tidy
ifneq (${HAS_DOCKER},)
	docker-compose run --rm plugin_lint
endif

.PHONY: clean
clean-%:
	rm -f coverage.out
	rm -rf ${NAME}-$*-${ARCH}

.PHONY: build
build-%: clean-%
	GOOS=$* GOARCH=${ARCH} CGO_ENABLED=0 go build -ldflags '${LDFLAGS}' -o ${PWD}/${NAME}-$*-${ARCH}
