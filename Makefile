git_repo_url = $(shell git remote get-url origin)
APP = $(shell echo $(shell basename $(git_repo_url)) | sed 's/\.git//')
APP_REPO = $(shell echo $(git_repo_url) | sed 's/git@/https:\/\//' | sed 's/:/\//' | sed 's/\.git//')
VERSION = $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)


include .env
export $(shell sed 's/=.*//' .env)
REGISTRY = $(REGISTRY_NAME)

TARGETS = linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64
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
	@echo "Building $(word 1, $(subst _, ,$@)) binary for $(word 2, $(subst _, ,$@))..."
	cd src && CGO_ENABLED=0 GOOS=$(word 1, $(subst _, ,$@)) GOARCH=$(word 2, $(subst _, ,$@)) go build -v -o ${OUT_DIR}/$@/${APP} -ldflags "-X="${APP_REPO}/cmd.appVersion=${VERSION} && cd ..

clean:
	@echo "All Docker imageges will be deleted"
	# ref: https://docs.docker.com/engine/cli/formatting/
	docker rmi $(shell docker images "$(REGISTRY)/$(APP)" --format "{{.Repository}}:{{.Tag}}" || true) || true
	rm -rf ${OUT_DIR)
