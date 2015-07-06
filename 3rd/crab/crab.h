#ifndef _CRAB_H_
#define _CRAB_H_

typedef struct _TableNode {
    uint32_t key;
    int next;

    char flag; // 0: empty, 'n': non-terminator, 'o': terminator
    void* value;
} TableNode;

typedef struct _Table {
    int capacity;

    TableNode* node;
    TableNode* lastfree;
} Table;

void initnode(TableNode *node);
int tisnil(TableNode* node);
TableNode* tnode(Table *t, int index);
int tindex(Table *t, TableNode *node);
TableNode* mainposition(Table *t, uint32_t key);
TableNode* getfreenode(Table *t);
void table_expand(Table *t);
TableNode* table_newkey(Table *t, uint32_t key);
TableNode* table_get(Table *t, uint32_t key);
TableNode* table_insert(Table *t, uint32_t key);
Table* table_new();
void _dict_close(Table *t);
void _dict_dump(Table *t, int indent);
int _dict_insert(lua_State *L, Table* dict);

#endif
