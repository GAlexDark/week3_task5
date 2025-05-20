ifeq ($(OS), Windows_NT)
shell := cmd.exe
ROOT_DIR = $(echo $(shell echo %CD%))
else
shell := /bin/sh
ROOT_DIR = $(shell pwd)
endif

git_repo_url = $(shell git remote get-url origin)
APP = $(shell echo $(shell basename $(git_repo_url)) | sed 's/\.git//')
APP_REPO = $(shell echo $(git_repo_url) | sed 's/git@/https:\/\//' | sed 's/:/\//' | sed 's/\.git//')
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

include .env
export $(shell sed 's/=.*//' .env)
REGISTRY = $(REGISTRY_NAME)

TARGETS = linux_amd64 linux_arm64 linux_386 darwin_amd64 darwin_arm64 windows_amd64
OUT_DIR=bin
supported_platforms=$(shell docker buildx inspect --bootstrap | awk -F: '{if (NR==11) print $$2}' | sed 's/Platforms://')
GO_BUILD_CMD = go build -v -o ${ROOT_DIR}/${OUT_DIR}/$${target:-$@}/${APP} -ldflags "-X="${APP_REPO}/cmd.appVersion=${VERSION}

.PHONY: all $(TARGETS)

all: $(TARGETS)

go_init:
	# fix error if go.mod already exists
	[ -f src/go.mod ] || (cd src && go mod init $(APP))
	## force dependency update
	cd src && go get && cd ..

lint:
	cd src && golint  && cd ..

format:
	gofmt -s -w ./src

$(TARGETS): format go_init
	@echo "Building special targets"
	# using Make functions word & subst
	@if [ -z $(findstring $(subst _, /,$@), $(supported_platforms)) ]; then \
		echo "This builder does not supported on this host"; \
		exit 1; \
	fi; \
	@echo "Building $(word 1, $(subst _, ,$@)) binary for $(word 2, $(subst _, ,$@))..."
	cd src && CGO_ENABLED=0 GOOS=$(word 1, $(subst _, ,$@)) GOARCH=$(word 2, $(subst _, ,$@)) $(GO_BUILD_CMD) && cd ..

linux: format go_init
	@echo "Create app supported on this host platform\n"
	@if [ -z $(findstring $@, $(supported_platforms)) ]; then \
		echo "This builder does not supported on this host"; \
		exit 1; \
	else \
		for target in $(TARGETS); do \
			os=$$(echo $$target | cut -d_ -f1); \
			if [ "$$os" = $@ ]; then \
				arch=$$(echo $$target | cut -d_ -f2); \
				echo "Building $$os binary for $$arch..."; \
				cd src && CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch $(GO_BUILD_CMD) && cd ..; \
			fi; \
		done \
	fi; \

windows: format go_init
	@echo "Create app supported on this host platform\n"
	@if [ -z $(findstring $@, $(supported_platforms)) ]; then \
		echo "This builder does not supported on this host"; \
		exit 1; \
	else \
		for target in $(TARGETS); do \
			os=$$(echo $$target | cut -d_ -f1); \
			if [ "$$os" = $@ ]; then \
				arch=$$(echo $$target | cut -d_ -f2); \
				echo "Building $$os binary for $$arch..."; \
				cd src && CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch $(GO_BUILD_CMD) && cd ..; \
			fi; \
		done \
	fi; \

darwin: format go_init
	@echo "Create app supported on this host platform\n"
	@if [ -z $(findstring $@, $(supported_platforms)) ]; then \
		echo "This builder does not supported on this host"; \
		exit 1; \
	else \
		for target in $(TARGETS); do \
			os=$$(echo $$target | cut -d_ -f1); \
			if [ "$$os" = $@ ]; then \
				arch=$$(echo $$target | cut -d_ -f2); \
				echo "Building $$os binary for $$arch..."; \
				cd src && CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch $(GO_BUILD_CMD) && cd ..; \
			fi; \
		done \
	fi; \

image:
	@echo "Create images supported on this host platform\n"
	docker buildx create --use
	@for target in $(TARGETS); do \
		os=$$(echo $$target | cut -d_ -f1); \
		if echo "$(supported_platforms)" | grep -q "$$os/"; then \
			arch=$$(echo $$target | cut -d_ -f2); \
			echo "Building Docker image for $$target (OS: $$os, ARCH: $$arch)..."; \
			docker buildx build \
				--platform $$os/$$arch \
				--build-arg BASE_IMAGE=$(BASE_IMAGE) \
				--build-arg GO_TAG=$(GO_TAG) \
				--build-arg TARGETOS=$$os \
				--build-arg TARGETARCH=$$arch \
				--build-arg VERSION=$(VERSION) \
				--build-arg APP_REPO=$(APP_REPO) \
				--output type=docker \
				--tag $(REGISTRY)/$(APP):${VERSION}-$$target \
				. ; \
		else \
			echo "The $$target builder does not supported on this host"; \
		fi; \
	done

clean:
	@echo "All builded Docker images will be deleted"
	# ref: https://docs.docker.com/engine/cli/formatting/
	@if [ -n "$$(docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}")" ]; then \
	docker rmi $(shell docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}"); \
	else echo "The Docker images not found"; fi
	if [ -d "${ROOT_DIR}/${OUT_DIR}" ]; then (rm -rf "${ROOT_DIR}/${OUT_DIR}") fi
