#ifndef LUA_UNQLITE
#define LUA_UNQLITE

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "unqlite.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define UNQLITE_LUA "lua-unqlite"

int luaopen_unqlite(lua_State* L);

#endif // LUA_UNQLITE

#define SETLITERAL(n,v) (lua_pushliteral(L, n), lua_pushliteral(L, v), lua_settable(L, -3))
#define SETINT(n,v) (lua_pushliteral(L, n), lua_pushinteger(L, v), lua_settable(L, -3))

static void fatal(lua_State* L, unqlite *db,const char *zMsg)
{
    if( db )
    {
        const char *zErr;
        int iLen = 0;

        unqlite_config(db,UNQLITE_CONFIG_ERR_LOG,&zErr,&iLen);
        if( iLen > 0 )
        {
            luaL_error(L, zErr);
        }
    }
    else
    {
        if( zMsg )
        {
            luaL_error(L, zMsg);
        }
    }
}

static int _unqlite_open(lua_State* L)
{
    const char* file_name = luaL_checkstring(L, 1);
    unsigned int i_mode = luaL_optinteger(L, 2, 0);

    if (i_mode == 0)
        i_mode = UNQLITE_OPEN_CREATE | UNQLITE_OPEN_READWRITE;

    unqlite *db;
    int rc = unqlite_open(&db, file_name, i_mode);

    if (rc != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushlightuserdata(L, db);
        return 1;
    }
}

static int _unqlite_close(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_close(db);
    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }

}

static int _unqlite_kv_store(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    size_t keylen;
    void* key = (void* )luaL_checklstring(L, 2, &keylen);
    size_t contentlen;
    void* content = (void* )luaL_checklstring(L, 3, &contentlen);

    if (keylen <= 0 || contentlen <= 0 || key == NULL || content == NULL)
    {
        luaL_argerror(L, 2, "unqlite: invalid key or content");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_kv_store(db, key, keylen, content, contentlen);

    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: k-v store failed");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }

}

static int _unqlite_kv_append(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    size_t keylen;
    void* key = (void* )luaL_checklstring(L, 2, &keylen);
    size_t contentlen;
    void* content = (void* )luaL_checklstring(L, 3, &contentlen);

    if (keylen <= 0 || contentlen <= 0 || key == NULL || content == NULL)
    {
        luaL_argerror(L, 2, "unqlite: invalid key or content");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_kv_append(db, key, keylen, content, contentlen);

    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }
}

static int _unqlite_kv_fetch(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    size_t keylen;
    void* key = (void* )luaL_checklstring(L, 2, &keylen);

    if (keylen <= 0 || key == NULL )
    {
        luaL_argerror(L, 2, "unqlite: invalid key");
        lua_pushboolean(L,0);
        return 0;
    }

    unqlite_int64 buflen = 0;
    unqlite_kv_fetch(db, key, keylen, NULL, &buflen);

    char* buf = (char *)malloc(sizeof(char)*buflen);
    unqlite_kv_fetch(db, key, keylen, buf, &buflen);

    if (buf == NULL)
    {
        printf("unqlite: nil buf");
        lua_pushnil(L);
    }
    else
    {
        lua_pushlstring(L, (const char *)buf, buflen);
        free(buf);
    }

    return 1;
}

static int _unqlite_kv_delete(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    size_t keylen;
    void* key = (void* )luaL_checklstring(L, 2, &keylen);

    if (keylen <= 0 || key == NULL )
    {
        luaL_argerror(L, 2, "unqlite: invalid key");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_kv_delete(db, key, keylen);

    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }
}

static int _unqlite_begin(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_begin(db);
    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }
}

static int _unqlite_commit(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_commit(db);
    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }
}

static int _unqlite_rollback(lua_State* L)
{
    unqlite* db = (unqlite*)lua_touserdata(L, 1);
    if (NULL == db)
    {
        luaL_argerror(L, 1,  "unqlite: close get null db");
        lua_pushboolean(L,0);
        return 0;
    }

    int rs = unqlite_rollback(db);
    if (rs != UNQLITE_OK)
    {
        fatal(L, db, "unqlite: out of memory");
        lua_pushboolean(L,0);
        return 0;
    }
    else
    {
        lua_pushboolean(L,1);
        return 1;
    }
}

static const luaL_Reg unqlite_functions[] =
{
    { "open", _unqlite_open },
    { "close", _unqlite_close },
    { "store", _unqlite_kv_store },
    { "fetch", _unqlite_kv_fetch },
    { "delete", _unqlite_kv_delete },
    { "begin", _unqlite_begin },
    { "commit", _unqlite_commit },
    { NULL, NULL}
};

int luaopen_unqlite(lua_State* L)
{
    luaL_newlib(L, unqlite_functions);

    SETINT("UNQLITE_OPEN_READONLY", UNQLITE_OPEN_READONLY);
    SETINT("UNQLITE_OPEN_READWRITE", UNQLITE_OPEN_READWRITE);
    SETINT("UNQLITE_OPEN_CREATE", UNQLITE_OPEN_CREATE);
    SETINT("UNQLITE_OPEN_EXCLUSIVE", UNQLITE_OPEN_EXCLUSIVE);
    SETINT("UNQLITE_OPEN_TEMP_DB", UNQLITE_OPEN_TEMP_DB);
    SETINT("UNQLITE_OPEN_NOMUTEX", UNQLITE_OPEN_NOMUTEX);
    SETINT("UNQLITE_OPEN_OMIT_JOURNALING", UNQLITE_OPEN_OMIT_JOURNALING);
    SETINT("UNQLITE_OPEN_IN_MEMORY", UNQLITE_OPEN_IN_MEMORY);
    SETINT("UNQLITE_OPEN_MMAP", UNQLITE_OPEN_MMAP);
    return 1;
}
