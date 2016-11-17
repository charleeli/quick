#include <stdio.h>
#include <sys/time.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static int
microtime(lua_State *L) {
    struct timeval time;

    gettimeofday(&time, NULL);

    double second = time.tv_sec;
    double usec = time.tv_usec;
    double microsecond = second*1000000+usec;

    lua_pushnumber(L, microsecond);

    return 1;
}

static int
timestamp(lua_State *L) {
    struct timeval time;

    gettimeofday(&time, NULL);

    double second = time.tv_sec;
    double usec = time.tv_usec;
    double microsecond = second+usec*0.000001;

    lua_pushnumber(L, microsecond);

    return 1;
}

int 
luaopen_ctime(lua_State *L) { 
    luaL_checkversion(L); 
    luaL_Reg l[] ={ 
        {"microtime", microtime},
        {"timestamp", timestamp},
        { NULL, NULL }, 
    }; 
 
    luaL_newlib(L,l); 
    return 1; 
} 

