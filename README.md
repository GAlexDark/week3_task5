# Week 3 Task5

ToDo
```
OS := $(shell uname -s) # base host linux

ifeq ($(OS), Linux)
    all:
        $(MAKE) -f makefile.linux $(ARGS)
else ifeq ($(OS), Darwin)
    all:
        $(MAKE) -f makefile.mac $(ARGS)
else ifeq ($(OS), Windows_NT)
    all:
        $(MAKE) -f makefile.win $(ARGS)
else
$(error "Unknown platform: $(OS)")
endif
```

Docker Desktop for Mac handles this by running a virtual machine that hosts the Docker engine, allowing Linux containers to run seamlessly on macOS. When building Docker images for different architectures, including darwin/amd64 or darwin/arm64, Docker's buildx tool can be used for cross-compilation. This enables the creation of binaries for macOS within a Linux-based Docker container. However, running a Darwin-based Docker image directly is not a common use case, as macOS does not natively support the same containerization mechanisms as Linux. Instead, the focus is usually on building and running applications within Linux containers on macOS using Docker Desktop's virtualization capabilities.
