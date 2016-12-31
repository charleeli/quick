.PHONY: all skynet clean

TOP=$(PWD)
BUILD_DIR =             $(PWD)/build
BUILD_BIN_DIR =         $(BUILD_DIR)/bin
BUILD_INCLUDE_DIR =     $(BUILD_DIR)/include
BUILD_LUALIB_DIR =      $(BUILD_DIR)/lualib
BUILD_CLIB_DIR =        $(BUILD_DIR)/clib
BUILD_LUACLIB_DIR =     $(BUILD_DIR)/luaclib
BUILD_STATIC_LIB_DIR =  $(BUILD_DIR)/staticlib
BUILD_CSERVICE_DIR =    $(BUILD_DIR)/cservice
BUILD_SPROTO_DIR =      $(BUILD_DIR)/sproto

PLAT ?= linux
SHARED := -fPIC --shared
CFLAGS = -g -O2 -Wall -I$(BUILD_INCLUDE_DIR) 
LDFLAGS= -L$(BUILD_CLIB_DIR) -Wl,-rpath $(BUILD_CLIB_DIR) -lpthread -lm -ldl -lrt
DEFS = -DHAS_SOCKLEN_T=1 -DLUA_COMPAT_APIINTCASTS=1 

all : build skynet lua53 Penlight argparse libenet.so libunqlite.so libcrab.so redis

build:
	-mkdir $(BUILD_DIR)
	-mkdir $(BUILD_BIN_DIR)
	-mkdir $(BUILD_INCLUDE_DIR)
	-mkdir $(BUILD_LUALIB_DIR)
	-mkdir $(BUILD_LUALIB_DIR)/pl/
	-mkdir $(BUILD_CLIB_DIR)
	-mkdir $(BUILD_LUACLIB_DIR)
	-mkdir $(BUILD_STATIC_LIB_DIR)
	-mkdir $(BUILD_CSERVICE_DIR)
	-mkdir $(BUILD_SPROTO_DIR)

lua53:
	cd 3rd/skynet/3rd/lua/ && $(MAKE) MYCFLAGS="-O2 -fPIC -g" linux
	install -p -m 0755 3rd/skynet/3rd/lua/lua $(BUILD_BIN_DIR)/lua
	install -p -m 0755 3rd/skynet/3rd/lua/luac $(BUILD_BIN_DIR)/luac
	install -p -m 0644 3rd/skynet/3rd/lua/liblua.a $(BUILD_STATIC_LIB_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lua.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lauxlib.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lualib.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/luaconf.h $(BUILD_INCLUDE_DIR)

Penlight:
	cp -r 3rd/Penlight/lua/pl/* $(BUILD_LUALIB_DIR)/pl/

argparse:
	cp 3rd/argparse/src/argparse.lua $(BUILD_LUALIB_DIR)/

libenet.so:3rd/enet/callbacks.c 3rd/enet/compress.c 3rd/enet/host.c \
           3rd/enet/list.c 3rd/enet/packet.c 3rd/enet/peer.c \
           3rd/enet/protocol.c 3rd/enet/unix.c
	cp -r 3rd/enet/include/enet/ $(BUILD_INCLUDE_DIR)/
	$(CC) $(DEFS) $(CFLAGS) $(SHARED) $^ -o $(BUILD_CLIB_DIR)/libenet.so

libunqlite.so : 3rd/unqlite/unqlite.c
	cp 3rd/unqlite/unqlite.h $(BUILD_INCLUDE_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $(BUILD_CLIB_DIR)/libunqlite.so

libcrab.so : 3rd/crab/crab.c
	cp 3rd/crab/crab.h $(BUILD_INCLUDE_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $(BUILD_CLIB_DIR)/libcrab.so

redis:
	cd 3rd/redis/ && make
	install -p -m 0755 3rd/redis/src/redis-cli $(BUILD_BIN_DIR)/redis-cli
	install -p -m 0755 3rd/redis/src/redis-server $(BUILD_BIN_DIR)/redis-server

skynet/Makefile :
	git submodule update --init

skynet : skynet/Makefile
	cd 3rd/skynet && $(MAKE) $(PLAT) && cd ../..
	cp 3rd/skynet/skynet-src/skynet_malloc.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet_env.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet_socket.h $(BUILD_INCLUDE_DIR)
	install -p -m 0755 3rd/skynet/skynet $(BUILD_BIN_DIR)/skynet
	
LUACLIB = lsocket enet log ctime lfs lcrab unqlite cjson
CSERVICE = zinc_client

all : \
  $(foreach v, $(CSERVICE), $(BUILD_CSERVICE_DIR)/$(v).so)\
  $(foreach v, $(LUACLIB), $(BUILD_LUACLIB_DIR)/$(v).so) 
  
$(BUILD_CLIB_DIR) :
	mkdir $(BUILD_CLIB_DIR)

$(BUILD_LUACLIB_DIR) :
	mkdir $(BUILD_LUACLIB_DIR)
	
$(BUILD_CSERVICE_DIR) :
	mkdir $(BUILD_CSERVICE_DIR)

$(BUILD_LUACLIB_DIR)/lsocket.so:3rd/lsocket/lsocket.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_LUACLIB_DIR)/enet.so : lualib-src/lua-enet.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(DEFS) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS) -lenet

$(BUILD_LUACLIB_DIR)/unqlite.so : lualib-src/lua-unqlite.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(DEFS) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS) -lunqlite
	
$(BUILD_LUACLIB_DIR)/lcrab.so : lualib-src/lua-crab.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS) -lcrab 

$(BUILD_LUACLIB_DIR)/log.so : lualib-src/lua-log.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_LUACLIB_DIR)/ctime.so: lualib-src/lua-ctime.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_LUACLIB_DIR)/lfs.so: 3rd/luafilesystem/src/lfs.c | $(BUILD_LUACLIB_DIR) 
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(BUILD_LUACLIB_DIR)/cjson.so: 3rd/lua-cjson/lua_cjson.c 3rd/lua-cjson/fpconv.c \
    3rd/lua-cjson/strbuf.c| $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_CSERVICE_DIR)/zinc_client.so : service-src/zinc_client.c | $(BUILD_CSERVICE_DIR) 
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
all : spb

spb:
	cd $(TOP) && cp $(TOP)/3rd/skynet/luaclib/lpeg.so $(TOP)/3rd/sproto_dump/

	cd $(TOP)/3rd/sproto_dump/ && $(BUILD_BIN_DIR)/lua sprotodump.lua \
	-spb `find -L $(TOP)/service/agent/sproto/client  -name "*.sproto"`   \
	`find -L $(TOP)/service/agent/sproto/common  -name "*.sproto"`    \
	-o $(BUILD_SPROTO_DIR)/c2s.spb

	cd $(TOP)/3rd/sproto_dump/ && $(BUILD_BIN_DIR)/lua sprotodump.lua \
	-spb `find -L $(TOP)/service/agent/sproto/server  -name "*.sproto"`   \
	`find -L $(TOP)/service/agent/sproto/common  -name "*.sproto"`    \
	-o $(BUILD_SPROTO_DIR)/s2c.spb

clean :
	-rm -rf build
	-rm -rf log
