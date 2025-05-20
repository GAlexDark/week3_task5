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
	@target=$@; \
	os=$$(echo $$target | cut -d_ -f1); \
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
		. ;

image:
	docker buildx create --use
	@for target in $(TARGETS); do \
		os=$$(echo $$target | cut -d_ -f1); \
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
	done

clean:
	@echo "All builded Docker images will be deleted"
	# ref: https://docs.docker.com/engine/cli/formatting/
	@if [ -n "$$(docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}")" ]; then \
	docker rmi $(shell docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}"); \
	else echo "The Docker images not found"; fi
	if [ -d "${ROOT_DIR}/${OUT_DIR}" ]; then (rm -rf "${ROOT_DIR}/${OUT_DIR}") fi
