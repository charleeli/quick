#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "lua.h"
#include "lualib.h"
#include "crab.h"

void initnode(TableNode *node) {
    node->next = -1;

    node->flag = 0;
    node->value = NULL;
}

int tisnil(TableNode* node) {
    return node->flag == 0;
}

TableNode* tnode(Table *t, int index) {
    return t->node + index;
}

int tindex(Table *t, TableNode *node) {
    return node - t->node;
}

TableNode* mainposition(Table *t, uint32_t key) {
    return &t->node[(key & (t->capacity -1))];
}

TableNode* getfreenode(Table *t) {
    while(t->lastfree >= t->node) {
        if(tisnil(t->lastfree)) {
            return t->lastfree;
        }
        t->lastfree--;
    }
    return NULL;
}

void table_expand(Table *t) {
    int capacity = t->capacity;
    TableNode *node = t->node;

    t->capacity = t->capacity * 2;
    t->node = calloc(t->capacity, sizeof(TableNode));
    int i;
    for(i=0; i<t->capacity; i++) {
        initnode(t->node + i);
    }
    t->lastfree = t->node + (t->capacity - 1);

    for(i=0; i< capacity; i++) {
        TableNode *old = node + i;
        if(tisnil(old)) {
            continue;
        }
        TableNode *new = table_newkey(t, old->key);
        new->flag = old->flag;
        new->value = old->value;
    }
    // free old node
    free(node);
}

/*
** inserts a new key into a hash table; first, check whether key's main
** position is free. If not, check whether colliding node is in its main
** position or not: if it is not, move colliding node to an empty place and
** put new key in its main position; otherwise (colliding node is in its main
** position), new key goes to an empty position.
*/
TableNode* table_newkey(Table *t, uint32_t key) {
    TableNode *mp = mainposition(t, key);
    if(!tisnil(mp)) {
        TableNode *n = getfreenode(t);
        if(n == NULL) {
            table_expand(t);
            return table_newkey(t, key);
        }
        TableNode *othern = mainposition(t, mp->key);
        if (othern != mp) {
            int mindex = tindex(t, mp);
            while(othern->next != mindex) {
                othern = tnode(t, othern->next);
            }
            othern->next = tindex(t, n);
            *n = *mp;
            initnode(mp);
        } else {
            n->next = mp->next;
            mp->next = tindex(t, n);
            mp = n;
        }
    }
    mp->key = key;
    mp->flag = 'n';
    return mp;
}

TableNode* table_get(Table *t, uint32_t key) {
    TableNode *n = mainposition(t, key);
    while(!tisnil(n)) {
        if(n->key == key) {
            return n;
        }
        if(n->next < 0) {
            break;
        }
        n = tnode(t, n->next);
    }
    return NULL;
}

TableNode* table_insert(Table *t, uint32_t key) {
    TableNode *node = table_get(t, key);
    if(node) {
        return node;
    }
    return table_newkey(t, key);
}

Table* table_new() {
    Table *t = malloc(sizeof(Table));
    t->capacity = 1;

    t->node = malloc(sizeof(TableNode));
    initnode(t->node);
    t->lastfree = t->node;
    return t;
}

// construct dictinory tree
void _dict_close(Table *t) {
    if(t == NULL) {
        return;
    }
    int i = 0;
    for(i=0; i<t->capacity; i++) {
        TableNode *node = t->node + i;
        if(node->flag != 0) {
            _dict_close(node->value);
        }
    }
    free(t->node);
}

void _dict_dump(Table *t, int indent) {
    if(t == NULL) {
        return;
    }
    int i = 0;
    for(i=0; i<t->capacity; i++) {
        TableNode *node = t->node + i;
        printf("%*s", indent, " ");
        if(node->flag != 0) {
            printf("0x%x\n", node->key);
            _dict_dump(node->value, indent + 8);
        } else {
            printf("%s\n", "nil");
        }
    }
}

int _dict_insert(lua_State *L, Table* dict) {
    if(!lua_istable(L, -1)) {
        return 0;
    }

    size_t len = lua_rawlen(L, -1);
    size_t i;
    uint32_t rune;
    TableNode *node = NULL;
    for(i=1; i<=len; i++) {
        lua_rawgeti(L, -1, i);
 
        int isnum;
        rune = (uint32_t)lua_tointegerx(L, -1, &isnum);
        lua_pop(L, 1);

        if(!isnum) {
            return 0;
        }

        Table *tmp;
        if(node == NULL) {
            tmp = dict;
        } else {
            if(node->value == NULL) {
                node->value = table_new();
            } 
            tmp = node->value;
        }
        node = table_insert(tmp, rune);
    }
    if(node) {
        node->flag = 'o';
    }
    return 1;
}
