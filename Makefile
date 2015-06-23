.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
BUILD_DIR=./build

LUA_CLIB_PATH = $(BUILD_DIR)/luaclib

CFLAGS = -g -O2 -Wall

LUA_CLIB = log

all : skynet build

build:
	-mkdir $(BUILD_DIR)
	-mkdir $(LUA_CLIB_PATH)

skynet/Makefile :
	git submodule update --init

skynet : skynet/Makefile
	cd 3rd/skynet && $(MAKE) $(PLAT) && cd ../..

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	-rm -rf build
	cd 3rd/skynet && $(MAKE) clean
	
