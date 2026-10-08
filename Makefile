PROTO_DSL := proto/szse_bin_v1.29.pdsl
OUTPUT_DIR := src/
FIN_PROTOC ?= $(HOME)/workspace/fin-protoc/bin/fin-protoc

.PHONY: compile test example all

compile:
	$(FIN_PROTOC) -f $(PROTO_DSL) -z $(OUTPUT_DIR)

test: compile
	zig build test

example: compile
	zig build example

all: test
