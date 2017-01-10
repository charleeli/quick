#include <lua.h>
#include <lauxlib.h>

#include <math.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

static unsigned int rand_seed = 1;

static bool is_seed_set = false;

static
unsigned int _random()
{
    if(!is_seed_set)
    {
        is_seed_set = true;
        struct timeval now_time;
        gettimeofday(&now_time, NULL);
        rand_seed = (unsigned int)(now_time.tv_usec + getpid());
    }

	unsigned int next = rand_seed;
    unsigned int result;

    next *= 1103515245;
    next += 12345;
    result = (unsigned int) (next >> 16) & 0x07ff;

    next *= 1103515245;
    next += 12345;
    result <<= 10;
    result ^= (unsigned int) (next >> 16) & 0x03ff;

    next *= 1103515245;
    next += 12345;
    result <<= 10;
    result ^= (unsigned int) (next >> 16) & 0x03ff;

    rand_seed = next;

    return result;
}

unsigned int random1(unsigned int range)
{
    if(0 == range) return 0;
    return _random() % range;
}

unsigned int random2(unsigned int min_range, unsigned int max_range)
{
    if(min_range == max_range) return max_range;

    if(min_range > max_range)
        return random1(min_range - max_range) + max_range;

    return random1(max_range - min_range) + min_range;
}

static
int lrandom (lua_State *L) {
    lua_Integer min_range = luaL_checkinteger(L, 1);
    if(lua_isnone(L, 2))
    {
        lua_pushinteger(L, random1(min_range));
    }
    else
    {
        lua_Integer max_range = luaL_checkinteger(L, 2);
        lua_pushinteger(L, random2(min_range, max_range));
    }

    return 1;
}

int
luaopen_random(lua_State *L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{ "random", lrandom },
		{ NULL, NULL },
	};

	luaL_newlib(L,l);
	return 1;
}
