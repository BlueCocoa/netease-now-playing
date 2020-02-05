all:
	mkdir -p build
	clang -shared -Os -undefined dynamic_lookup -o build/libncmnp.dylib ncmnp.mm
