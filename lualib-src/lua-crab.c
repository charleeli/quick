#include <stdlib.h>
#include <stdint.h>

#include "lua.h"
#include "lauxlib.h"
#include "crab.h"

Table *g_dict = NULL;

static int
dict_open(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);

    Table *dict = table_new();
    size_t len = lua_rawlen(L,1);
    size_t i;
    for(i=1;i<=len;i++) {
        lua_rawgeti(L, 1, i);
        if(!_dict_insert(L, dict)) {
            _dict_close(dict);
            return luaL_error(L, "illegal parameters in table index %d", i);
        }
        lua_pop(L, 1);
    }

    g_dict = dict;
    return 0;
}

static int
dict_filter(lua_State *L) {
    if(!g_dict) {
        return luaL_error(L, "need open first");
    }

    Table* dict = g_dict;
    luaL_checktype(L, 1, LUA_TTABLE);

    size_t len = lua_rawlen(L,1);
    size_t i,j;
    int flag = 0;
    for(i=1;i<=len;) {
        TableNode *node = NULL;
        int step = 0;
        for(j=i;j<=len;j++) {
            lua_rawgeti(L, 1, j);
            uint32_t rune = (uint32_t)lua_tointeger(L, -1);
            lua_pop(L, 1);

            if(node == NULL) {
                node = table_get(dict, rune);
            } else {
                node = table_get(node->value, rune);
            }

            if(node && node->flag == 'o') step = j - i + 1;
            if(!(node && node->value)) break;
        }
        if(step > 0) {
            for(j=0;j<step;j++) {
                lua_pushinteger(L, '*');
                lua_rawseti(L, 1, i+j);
            }
            flag = 1;
            i = i + step;
        } else {
            i++;
        }
    }
    lua_pushboolean(L, flag);
    return 1;
}

int
luaopen_lcrab(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"open", dict_open},
        {"filter", dict_filter},
        {NULL, NULL}
    };

    luaL_newlib(L, l);
    return 1;
}

