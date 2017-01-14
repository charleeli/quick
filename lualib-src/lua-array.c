#include <lua.h>
#include <lauxlib.h>
#include <stdio.h>

static int
lnewindex(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_Integer idx = luaL_checkinteger(L, 2);
	if (idx <= 0) {
		return luaL_error(L, "The index should be positive (%d)", (int)idx);
	}
	lua_settop(L, 3);
	lua_rawseti(L, 1, idx);
	size_t rawlen = lua_rawlen(L, 1);
	if (rawlen >= idx) {
		return 0;
	}
	lua_rawgeti(L, 1, 0);
	lua_Integer sparselen = luaL_checkinteger(L, -1);
	if (sparselen < 0)
		sparselen = -sparselen;
	++sparselen;

	lua_pushinteger(L, sparselen);
	lua_rawseti(L, 1, 0);
	lua_pushinteger(L, idx);
	lua_rawseti(L, 1, -sparselen);

	return 0;
}

static int
insert(lua_State *L, lua_Integer key, int n) {
	int begin = 0, end = n;
	int mid;
	while (begin < end) {
		mid = (begin + end)/2;
		lua_rawgeti(L, 1, -mid-1);
		lua_Integer v = luaL_checkinteger(L, -1);
		lua_pop(L, 1);
		if (v == key)
			return 0;	// replicate
		if (v < key)
			begin = mid + 1;
		else
			end = mid;
	}
	// insert before end
	int i;
	for (i=n;i>end;i--) {
		lua_rawgeti(L, 1, -i);
		lua_rawseti(L, 1, -i-1);
	}
	lua_pushinteger(L, key);
	lua_rawseti(L, 1, -end-1);
	return 1;
}

static lua_Integer
sort_sparse(lua_State *L, lua_Integer sparselen) {
	size_t rawlen = lua_rawlen(L, 1);
	lua_Integer i, n=0;
	// insertion sort
	for (i=0; i<sparselen; i++) {
		lua_rawgeti(L, 1, -i-1);
		lua_Integer idx = luaL_checkinteger(L, -1);
		lua_pop(L, 1);
		if (idx <= rawlen)
			continue;
		if (lua_rawgeti(L, 1, idx) == LUA_TNIL) {
			lua_pop(L, 1);	// value removed
			continue;
		}
		lua_pop(L, 1);
		if (insert(L, idx, n))
			++n;
	}
	for (i=n;i<sparselen;i++) {
		lua_pushnil(L);
		lua_rawseti(L, 1, -i-1);
	}
	lua_pushinteger(L, -n);
	lua_rawseti(L, 1, 0);

	return n;
}

static int
lsort(lua_State *L) {
	lua_Integer sparselen = luaL_checkinteger(L, 2);
	sparselen = sort_sparse(L, sparselen);
	lua_pushinteger(L, sparselen);
	return 1;
}

static int
lnext(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_Integer idx;
	if (lua_isnoneornil(L, 2)) {
		idx = 1;
	} else {
		if (!lua_isinteger(L, 2)) {
			return luaL_error(L, "last index should be integer");
		}
		idx = lua_tointeger(L, 2) + 1;
	}

	if (lua_rawgeti(L, 1, idx) != LUA_TNIL) {
		lua_pushinteger(L, idx);
		lua_pushvalue(L, -2);
		return 2;
	}

	size_t rawlen = lua_rawlen(L, 1);
	if (rawlen >= idx) {
		size_t i;
		for (i = idx + 1; i <= rawlen; i++) {
			if (lua_rawgeti(L, 1, i) != LUA_TNIL) {
				lua_pushinteger(L, i);
				lua_pushvalue(L, -2);
				return 2;
			}
			lua_pop(L, 1);
		}
		return luaL_error(L, "Invalid index %d", (int)idx);
	}

	if (lua_rawgeti(L, 1, 0) != LUA_TNUMBER)
		return luaL_error(L, "Invalid array");
	lua_Integer sparselen = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (sparselen == 0)
		return 0;
	if (sparselen > 0) {
		lua_pushcfunction(L, lsort);
		lua_pushvalue(L, 1);
		lua_pushinteger(L, sparselen);
		lua_call(L, 2, 1);	// resort sparse array
		sparselen = lua_tointeger(L, -1);
		lua_pop(L, 1);
	} else {
		sparselen = -sparselen;
	}

	// binary search
	lua_Integer begin = 0, end = sparselen;
	while (begin < end) {
		lua_Integer mid = (begin + end)/2;
		lua_rawgeti(L, 1, -mid-1);
		lua_Integer v = luaL_checkinteger(L, -1);
		lua_pop(L, 1);
		if (v > idx) {
			end = mid;
		} else if (v < idx) {
			begin = mid + 1;
		} else {
			begin = mid;
			break;
		}
	}
	if (begin >= sparselen)
		return 0;
	lua_rawgeti(L, 1, -begin-1);
	idx = luaL_checkinteger(L, -1);
	lua_rawgeti(L, 1, idx);

	return 2;
}

static int
lpairs(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_rawgeti(L, 1, 0);
	lua_Integer sparselen = luaL_checkinteger(L, -1);
	if (sparselen > 0) {
		sort_sparse(L, sparselen);
	}

	lua_pushcfunction(L, lnext);
	lua_pushvalue(L, 1);
	lua_pushnil(L);
	return 3;
}

static int
llen(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_rawgeti(L, 1, 0);
	lua_Integer sparselen = luaL_checkinteger(L, -1);
	if (sparselen > 0) {
		sparselen = sort_sparse(L, sparselen);
	} else {
		sparselen = -sparselen;
	}
	if (sparselen == 0) {
		lua_pushinteger(L, lua_rawlen(L, 1));
		return 1;
	}
	lua_rawgeti(L, 1, -sparselen);
	return 1;
}

static int
lnewarray(lua_State *L) {
	int n = lua_gettop(L);
	lua_createtable(L, n, 0);
	lua_pushvalue(L, lua_upvalueindex(1));
	lua_setmetatable(L, -2);
	int i;
	for (i=1;i<=n;i++) {
		lua_pushvalue(L, i);
		lua_rawseti(L, -2, i);
	}
	lua_pushinteger(L, 0);
	lua_rawseti(L, -2, 0);
	return 1;
}

LUAMOD_API int
luaopen_array(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg metatable[] = {
		{ "__newindex", lnewindex },
		{ "__pairs", lpairs },
		{ "__len", llen },
		{ NULL, NULL },
	};
	luaL_newlib(L, metatable);
	lua_pushcclosure(L, lnewarray, 1);

	return 1;
}
