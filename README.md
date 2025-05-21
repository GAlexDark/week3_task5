# Week 3 Task5

ToDo
```
OS := $(shell uname -s)

ifeq ($(OS), Linux)
	include makefile.linux
else ifeq ($(OS), Darwin)  # macOS тоже Unix-подобный, если вдруг понадобится
	include makefile.mac
else ifeq ($(OS), Windows_NT)
	include makefile.win
else
$(error "Unknown platform: $(OS)")
endif
```
