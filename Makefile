git_repo_url = $(shell git remote get-url origin)
APP = $(shell echo $(shell basename $(git_repo_url)) | sed 's/\.git//')
APP_REPO = $(shell echo $(git_repo_url) | sed 's/git@/https:\/\//' | sed 's/:/\// | sed 's/\.git//')
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)


include .env
export $(shell sed 's/=.*//' .env)
REGISTRY = $(REGISTRY_NAME)

TARGETS = linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64
OUT_DIR = bin

.PHONY: all $(TARGETS)

all: $(TARGETS)

format:
	gofmt -s -w ./src

get:
	go get

$(TARGETS): format get
	@echo "Building ${GOOS} binary for ${GOARCH}..."
	GOOS = $(word 1, $(subst _, ,$@)) GOARCH = $(word 2, $(subst _, ,$@)) go build -o ${OUT_DIR}/$@/app src/main.go -ldflags "-X="${APP_REPO}/cmd.appVersion=$(VERSION)

.PHONY: clean
clean:
	TARGETARCH = $(word 2, $(subst _, ,$@))
	# ref: https://docs.docker.com/engine/cli/formatting/
	docker rmi $(shell docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}" | grep "$(TARGETARCH)" || true) || true
	rm -rf ${OUT_DIR)
