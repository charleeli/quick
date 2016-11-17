#include "skynet.h"
#include "skynet_socket.h"

#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

#define PTYPE_ZINC_CLIENT 16

struct client {
  int    id;
};

static int _cb(struct skynet_context * context, 
                void * ud, 
                int stype, 
                int session, 
                uint32_t source, 
                const void * msg, 
                size_t sz) 
{
    if (sz > 65535){
        skynet_error(context, 
            "too large package source:<%x> size:<%d>, stype:<%d>", 
            source, (int)sz, stype
        );
        return 0; 
    }
    
    if (stype != PTYPE_RESPONSE && stype != PTYPE_ZINC_CLIENT) {
        skynet_error(context, 
            "send unkown msg type, source:%d, Stype:%d", 
            source, stype
        );
        return 0;
    }

    struct client * c = (struct client*) ud;

    uint8_t *buffer = malloc(sz);
    memcpy(buffer, msg, sz);
    skynet_socket_send(context, c->id, buffer, sz);

    return 0;
}

int zinc_client_init(struct client* c, 
                    struct skynet_context *ctx, 
                    const char * args) 
{
    int id = 0;
    sscanf(args, "%d", &id);
    c->id = id;
    skynet_callback(ctx, c, _cb);
    return 0;
}

struct client * zinc_client_create(void) 
{
    struct client *c = malloc(sizeof(*c));
    memset(c,0,sizeof(*c));
    return c;
}

void zinc_client_release(struct client *c) 
{
    free(c);
}

