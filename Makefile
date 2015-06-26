.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
BUILD_DIR=build

TOP=$(PWD)
BIN_DIR=$(BUILD_DIR)/bin
INCLUDE_DIR=$(BUILD_DIR)/include
LUA_CLIB_PATH = $(BUILD_DIR)/luaclib
SPROTO_DIR=$(BUILD_DIR)/sproto
BUILD_STATIC_LIB=$(BUILD_DIR)/static_lib

CFLAGS = -g -O2 -Wall

LUA_CLIB = log ctime lfs

all : skynet build lua53 proto

build:
	-mkdir $(BUILD_DIR)
	-mkdir $(BIN_DIR)
	-mkdir $(INCLUDE_DIR)
	-mkdir $(LUA_CLIB_PATH)
	-mkdir $(BUILD_STATIC_LIB)
	-mkdir $(SPROTO_DIR)
	
lua53:
	cd 3rd/skynet/3rd/lua/ && $(MAKE) MYCFLAGS="-O2 -fPIC -g" linux
	install -p -m 0755 3rd/skynet/3rd/lua/lua $(BIN_DIR)/lua
	install -p -m 0755 3rd/skynet/3rd/lua/luac $(BIN_DIR)/luac
	install -p -m 0644 3rd/skynet/3rd/lua/liblua.a $(BUILD_STATIC_LIB)
	install -p -m 0644 3rd/skynet/3rd/lua/lua.h $(INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lauxlib.h $(INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lualib.h $(INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/luaconf.h $(INCLUDE_DIR)

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
	
$(LUA_CLIB_PATH)/ctime.so: lualib-src/lua-ctime.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(LUA_CLIB_PATH)/lfs.so: 3rd/luafilesystem/src/lfs.c | $(LUA_CLIB_PATH) 
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
proto:
	cd $(TOP) && cp 3rd/skynet/luaclib/lpeg.so $(TOP)/3rd/sproto_dump/

	cd $(TOP)/3rd/sproto_dump/ && $(TOP)/$(BUILD_DIR)/bin/lua sprotodump.lua \
	-o $(TOP)/$(BUILD_DIR)/sproto/c2s.spb \
	-spb `find -L $(TOP)/service/agent/sproto/client  -name "*.sproto"` \
	`find -L $(TOP)/service/agent/sproto/common  -name "*.sproto"`

	cd $(TOP)/3rd/sproto_dump/ && $(TOP)/$(BUILD_DIR)/bin/lua sprotodump.lua \
	-o $(TOP)/$(BUILD_DIR)/sproto/s2c.spb \
	-spb `find -L $(TOP)/service/agent/sproto/server  -name "*.sproto"` \
	`find -L $(TOP)/service/agent/sproto/common  -name "*.sproto"`

	rm $(TOP)/3rd/sproto_dump/lpeg.so

clean :
	-rm -rf build
	cd 3rd/skynet && $(MAKE) clean
	
