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
