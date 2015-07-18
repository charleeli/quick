#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/time.h>

struct UUID_DEF {
    uint64_t seq_id:45;
    uint64_t type:4;
    uint64_t server_id:15;
};

static uint64_t  
_hash(const char * str, int sz) { 
    uint32_t djb_hash = 5381; 
    uint32_t js_hash = 1315423911; 

    int i; 
    for (i=0;i<sz;i++) { 
        uint8_t c = (uint8_t)str[i]; 
        djb_hash += (djb_hash << 5) + c; 
        js_hash ^= ((js_hash << 5) + c + (js_hash >> 2)); 
    } 

    return (uint64_t)js_hash << 32 | djb_hash; 
} 

static int _l_hash(lua_State* L) {
    size_t len = 0;
    const char* str = luaL_checklstring(L, 1, &len);

    uint64_t n = _hash(str, len);
    lua_pushlightuserdata(L, (void*)n);
    return 1;
}

static int _l_gettimeofday(lua_State * L){
    struct timeval tv;
    gettimeofday(&tv, NULL);
    
    lua_pushinteger(L, tv.tv_sec);
    lua_pushinteger(L, tv.tv_usec);

    return 2;
}

static int _l_uuid(lua_State * L)
{
    struct UUID_DEF uuid;

    uuid.type       =   lua_tointeger(L, 1);
    uuid.server_id  =   lua_tointeger(L, 2);
    uuid.seq_id     =   lua_tointeger(L, 3);

    uint64_t ruuid  =   0;
    memcpy(&ruuid, &uuid, sizeof(ruuid));
    
    lua_pushlightuserdata(L, (void *)(intptr_t)ruuid);

    return 1;
}

static int
_from_string(lua_State* L) {
    const char* s = lua_tostring(L, 1);
    if (s == NULL) {
      s = "";
    }
    uint64_t n = 0;
    sscanf(s, "%llu", &n);
    lua_pushlightuserdata(L, (void *)(intptr_t)n);
    return 1;
}

static int
_netbytes2uint32(lua_State* L){
    const char* s = luaL_checkstring(L, 1);
    uint32_t a0 = (uint8_t)s[0] << 24;
    uint32_t a1 = (uint8_t)s[1] << 16;
    uint32_t a2 = (uint8_t)s[2] << 8;
    uint32_t a3 = (uint8_t)s[3];
    uint32_t ret = (uint32_t)(a0 | a1 | a2 | a3);
    lua_pushinteger(L, ret);
    return 1;
}

static int
_uint322netbytes(lua_State* L){
    uint32_t i = lua_tointeger(L, 1);
    char s[4];
    s[0] = (char)(i >> 24);
    s[1] = (char)(i >> 16);
    s[2] = (char)(i >> 8);
    s[3] = (char)(i);
    lua_pushlstring(L, s, 4);
    return 1;
}

int luaopen_lutil(lua_State *L) {
    luaL_Reg libs[] = {
        {"hash", _l_hash},
        {"gettimeofday", _l_gettimeofday},
        {"uuid", _l_uuid},
        {"from_string", _from_string},
        {"netbytes2uint32", _netbytes2uint32},
        {"uint322netbytes", _uint322netbytes},
        {NULL, NULL},
    };

    luaL_newlib(L, libs);
    return 1;
}

