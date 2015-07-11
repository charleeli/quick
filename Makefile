.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
CFLAGS = -g -O2 -Wall -I$(BUILD_INCLUDE_DIR) 
LDFLAGS= -L$(BUILD_CLIB_DIR) -Wl,-rpath $(BUILD_CLIB_DIR) -pthread -lm -ldl -lrt
DEFS = -DHAS_SOCKLEN_T=1 -DLUA_COMPAT_APIINTCASTS=1 

TOP=$(PWD)
BUILD_DIR =             build
BUILD_BIN_DIR =         $(BUILD_DIR)/bin
BUILD_INCLUDE_DIR =     $(BUILD_DIR)/include
BUILD_LUACLIB_DIR =     $(BUILD_DIR)/luaclib
BUILD_SPROTO_DIR =      $(BUILD_DIR)/sproto
BUILD_STATIC_LIB_DIR =  $(BUILD_DIR)/static_lib
BUILD_CLIB_DIR =        $(BUILD_DIR)/clib
BUILD_CSERVICE_DIR =    $(BUILD_DIR)/cservice

all : build skynet libenet.so libcrab.so lua53 proto res

build:
	-mkdir $(BUILD_DIR)
	-mkdir $(BUILD_BIN_DIR)
	-mkdir $(BUILD_INCLUDE_DIR)
	-mkdir $(BUILD_LUACLIB_DIR)
	-mkdir $(BUILD_STATIC_LIB_DIR)
	-mkdir $(BUILD_CSERVICE_DIR)
	-mkdir $(BUILD_SPROTO_DIR)
	-mkdir $(BUILD_CLIB_DIR)
	
libenet.so:3rd/enet/callbacks.c 3rd/enet/compress.c 3rd/enet/host.c \
           3rd/enet/list.c 3rd/enet/packet.c 3rd/enet/peer.c \
           3rd/enet/protocol.c 3rd/enet/unix.c
	$(CC) $(DEFS) $(CFLAGS) $(SHARED) $^ -o $(BUILD_CLIB_DIR)/libenet.so 
	cp -r 3rd/enet/include/enet/ $(BUILD_INCLUDE_DIR)/
	
libcrab.so : 3rd/crab/crab.c
	cp 3rd/crab/crab.h $(BUILD_INCLUDE_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $(BUILD_CLIB_DIR)/libcrab.so
	
lua53:
	cd 3rd/skynet/3rd/lua/ && $(MAKE) MYCFLAGS="-O2 -fPIC -g" linux
	install -p -m 0755 3rd/skynet/3rd/lua/lua $(BUILD_BIN_DIR)/lua
	install -p -m 0755 3rd/skynet/3rd/lua/luac $(BUILD_BIN_DIR)/luac
	install -p -m 0644 3rd/skynet/3rd/lua/liblua.a $(BUILD_STATIC_LIB_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lua.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lauxlib.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/lualib.h $(BUILD_INCLUDE_DIR)
	install -p -m 0644 3rd/skynet/3rd/lua/luaconf.h $(BUILD_INCLUDE_DIR)

skynet/Makefile :
	git submodule update --init

skynet : skynet/Makefile
	cd 3rd/skynet && $(MAKE) $(PLAT) && cd ../..
	cp 3rd/skynet/skynet-src/skynet_malloc.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet_env.h $(BUILD_INCLUDE_DIR)
	cp 3rd/skynet/skynet-src/skynet_socket.h $(BUILD_INCLUDE_DIR)
	
LUACLIB = log ctime lfs lcrab lenet
CSERVICE = zinc_client

all : \
  $(foreach v, $(CSERVICE), $(BUILD_CSERVICE_DIR)/$(v).so)\
  $(foreach v, $(LUACLIB), $(BUILD_LUACLIB_DIR)/$(v).so) 
  

$(BUILD_LUACLIB_DIR) :
	mkdir $(BUILD_LUACLIB_DIR)
	
$(BUILD_CSERVICE_DIR) :
	mkdir $(BUILD_CSERVICE_DIR)
	
$(BUILD_CLIB_DIR) :
	mkdir $(BUILD_CLIB_DIR)
	
$(BUILD_LUACLIB_DIR)/lenet.so : 3rd/lua-enet/enet.c  | $(BUILD_LUACLIB_DIR)
	$(CC) $(DEFS) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS) -lenet 
	
$(BUILD_LUACLIB_DIR)/lcrab.so : lualib-src/lua-crab.c  | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS) -lcrab 

$(BUILD_LUACLIB_DIR)/log.so : lualib-src/lua-log.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_LUACLIB_DIR)/ctime.so: lualib-src/lua-ctime.c | $(BUILD_LUACLIB_DIR)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_LUACLIB_DIR)/lfs.so: 3rd/luafilesystem/src/lfs.c | $(BUILD_LUACLIB_DIR) 
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
	
$(BUILD_CSERVICE_DIR)/zinc_client.so : service-src/zinc_client.c | $(BUILD_CSERVICE_DIR) 
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
	
res:
	cd ./tools/xls2lua && sh run.sh

clean :
	-rm -rf build
	-rm -rf log
	cd 3rd/skynet && $(MAKE) clean
	
