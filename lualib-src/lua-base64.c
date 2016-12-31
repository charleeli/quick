#include <stdlib.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#define BASE64_LUA "lua-base64"

int luaopen_base64(lua_State *L);


static const char b64tbl[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char b64equ = '=';

int base64_encode(const unsigned char *src, size_t srclen, char *dst, size_t dstlen)
{
	size_t idx = 0;
	unsigned char input[3];
	unsigned char output[4];
	size_t i;
	while (2 < srclen)
	{
		input[0] = *src++;
		input[1] = *src++;
		input[2] = *src++;
		srclen -= 3;
		output[0] = input[0] >> 2;
		output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
		output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
		output[3] = input[2] & 0x3f;
		if (idx + 4 > dstlen)
			return -1;
		dst[idx++] = b64tbl[output[0]];
		dst[idx++] = b64tbl[output[1]];
		dst[idx++] = b64tbl[output[2]];
		dst[idx++] = b64tbl[output[3]];
	}
	if (0 != srclen)
	{
		input[0] = input[1] = input[2] = '\0';
		for (i = 0; i < srclen; i++)
			input[i] = *src++;
		output[0] = input[0] >> 2;
		output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
		output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);

		if (idx + 4 > dstlen)
			return -1;
		dst[idx++] = b64tbl[output[0]];
		dst[idx++] = b64tbl[output[1]];
		if (srclen == 1)
			dst[idx++] = b64equ;
		else
			dst[idx++] = b64tbl[output[2]];
		dst[idx++] = b64equ;
	}
	if (idx >= dstlen)
		return -1;
	dst[idx] = '\0';
	return idx;
}

int base64_decode(const char *src, unsigned char *dst, size_t dstlen)
{
	int idx = 0, state = 0, ch;
	char *pos;
	while ((ch = *src++) != '\0')
	{
		if (isspace(ch))
			continue;
		if (ch == b64equ)
			break;
		pos = strchr(b64tbl, ch);
		if (pos == 0)
			return -1;
		switch (state)
		{
		case 0:
			if (dst)
			{
				if (idx >= dstlen)
					return -1;
				dst[idx] = (pos - b64tbl) << 2;
			}
			state = 1;
			break;
		case 1:
			if (dst)
			{
				if (idx + 1 >= dstlen)
					return -1;
				dst[idx] |= (pos - b64tbl) >> 4;
				dst[idx + 1] = ((pos - b64tbl) & 0x0f) << 4;
			}
			idx++;
			state = 2;
			break;
		case 2:
			if (dst)
			{
				if (idx + 1 >= dstlen)
					return -1;
				dst[idx] |= (pos - b64tbl) >> 2;
				dst[idx + 1] = ((pos - b64tbl) & 0x03) << 6;
			}
			idx++;
			state = 3;
			break;
		case 3:
			if (dst)
			{
				if (idx >= dstlen)
					return -1;
				dst[idx] |= (pos - b64tbl);
			}
			idx++;
			state = 0;
			break;
		default:
			abort();
		}
	}
	if (ch == b64equ)
	{
		ch = *src++;
		switch (state)
		{
		case 0:
		case 1:
			return -1;
		case 2:
			for (; ch != '\0'; ch = *src++)
			{
				if (!isspace(ch))
					break;
			}
			if (ch != b64equ)
				return -1;
			ch = *src++;
		case 3:
			for (; ch != '\0'; ch = *src++)
			{
				if (!isspace(ch))
					return -1;
			}
			if (dst && dst[idx] != 0)
				return -1;
		}
	}
	else
	{
		if (state != 0)
			return -1;
	}
	return idx;
}

static int lb64enc(lua_State *L)
{
	size_t len;
	const unsigned char* src = luaL_tolstring(L, 1, &len);
	size_t dstlen = ((len - 1) / 3) * 4 + 4;
	char *dst = (char*)malloc(dstlen);

	if (dst == NULL)
	{
		lua_pushnil(L);
	}
	else
	{
		base64_encode(src, len, dst, dstlen);
		lua_pushlstring(L, (const char *)dst, dstlen);
		free(dst);
	}
	return 1;
}

static int lb64dec(lua_State *L)
{
	size_t len;
	const char* src = luaL_tolstring(L, 1, &len);
	char *dst = (char*)malloc(len);

	if (dst == NULL)
	{
		lua_pushnil(L);
	}
	else
	{
		int dstlen = base64_decode(src, dst, len);
		lua_pushlstring(L, (const char *)dst, dstlen);
		free(dst);
	}
	return 1;
}

int luaopen_base64(lua_State *L)
{
	static const luaL_Reg base64[] =
	{
		{"encode", lb64enc},
		{"decode", lb64dec},
		{NULL, NULL}
	};

	luaL_newlib(L, base64);
	return 1;
}
