#include <lua.h>
#include <lauxlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <memory.h>
#include <assert.h>

#define TNOM 100
#define MAX_KEY_LEN 5

typedef struct _tpl_block_t
{
    struct _tpl_block_t         *suiv;
    struct _tpl_block_t         *prec;
    char                        *data;
    char                        *name;
    int                         ndata;
    int                         type;
    int                         alloc;
}tpl_block_t;

typedef struct _tpl_ptr_t
{
    char                        *name;
    tpl_block_t                 *block;
}tpl_ptr_t;

typedef struct _quick_table_t
{
    tpl_ptr_t                   *pst;
    int                         nlength;
}quick_table_t;

typedef struct _buffer_t
{
    char                        *pch;
    int                         length;
}buffer_t;

enum
{
    TEMP_HTML,
    TEMP_VAR,
    TEMP_BEGINBLOCK,
    TEMP_ENDBLOCK
};

static buffer_t                 m_buf;
static quick_table_t            m_vartable;
static quick_table_t            m_blocktable;
static tpl_block_t *            m_head;
static char *                   result;
static int                      length;

int load(const char * filename);
void set(const char *  token, const char *  val);
void set_block(const char *  block);
void render();

static void init();
static void parse();
static void release();
static void gen_block(tpl_block_t *curr, tpl_block_t *suiv);
static void del_block(tpl_block_t *pst);

static tpl_ptr_t * find(const char * elem,
                    const quick_table_t *base,
                    int(* cmpfunc)(const void *, const void *),
                    int * nb);

int cmp_block(const void *a, const void *b)
{
    return(strcmp(((tpl_ptr_t *)a)->name, ((tpl_ptr_t *)b)->name));
}

int cmp_block_n(const void *a, const void *b)
{
    return(strcmp((char *)a, ((tpl_ptr_t *)b)->name));
}

void init()
{
    bzero(&m_buf, sizeof(buffer_t));
    bzero(&m_vartable, sizeof(quick_table_t));
    bzero(&m_blocktable, sizeof(quick_table_t));
    m_head = NULL;
    result = NULL;
    length = 0;
}

int load(const char * filename)
{
    FILE        *fp;

    init();

    if((fp = fopen(filename, "r")) == NULL)
        return -1;

    release();

    fseek(fp, 0, SEEK_END);
    m_buf.length = ftell(fp);
    rewind(fp);
    m_buf.pch = (char *)malloc(sizeof(char) * m_buf.length + MAX_KEY_LEN);
    assert(NULL != m_buf.pch);

    fread(m_buf.pch, 1, m_buf.length, fp);
    fclose(fp);
    m_buf.pch[m_buf.length] = 0;

    parse();
    
    return 0;
}

void parse()
{
    m_head = (tpl_block_t *)malloc(sizeof(tpl_block_t));
    assert(NULL != m_head);

    memset(m_head, 0, sizeof(tpl_block_t));

    tpl_block_t *pst = m_head;

    int pos = 0, offset = 0;
    while(pos < m_buf.length)
    {
        if(m_buf.pch[pos] == '#' && m_buf.pch[pos + 1] == '#')
        {
            pst->suiv = (tpl_block_t *)malloc(sizeof(tpl_block_t));
            assert(NULL != pst->suiv);

            bzero(pst->suiv, sizeof(tpl_block_t));
            
            pst->suiv->prec = pst;
            pst->data = m_buf.pch + offset;
            pst->ndata = pos - offset;
            pst->type = TEMP_HTML;
            pst = pst->suiv;
            offset = pos;

            pos += 2;
            int namelen = 0;
            char name[TNOM + 1] = {0};
            while(m_buf.pch[pos + namelen] != '\0' && m_buf.pch[pos + namelen] != '#' && namelen < TNOM)
                namelen++;

            memcpy(name, m_buf.pch + pos, namelen);
            name[namelen] = '\0';

            pst->suiv = (tpl_block_t *)malloc(sizeof(tpl_block_t));
            assert(NULL != pst->suiv);

            memset(pst->suiv, 0, sizeof(tpl_block_t));
            
            pst->suiv->prec = pst;
            pst->type = TEMP_VAR;
            pst->name = strdup(name);
            
            assert(NULL != pst->name);

            m_vartable.pst = (tpl_ptr_t *)realloc(m_vartable.pst, sizeof(tpl_ptr_t) * (m_vartable.nlength + 1));
            assert(NULL != m_vartable.pst);
            m_vartable.pst[m_vartable.nlength].name = strdup(name);
            assert(NULL != m_vartable.pst[m_vartable.nlength].name);
            m_vartable.pst[m_vartable.nlength].block = pst;
            m_vartable.nlength++;

            pst = pst->suiv;
            pos += namelen + 2;
            offset = pos;
        }
        else if(m_buf.pch[pos] == '<' && m_buf.pch[pos + 1] == '!' 
            && m_buf.pch[pos + 2] == '-' && m_buf.pch[pos + 3] == '-')
        {
            pst->suiv = (tpl_block_t *)malloc(sizeof(tpl_block_t));
            assert(NULL != pst->suiv);

            memset(pst->suiv, 0, sizeof(tpl_block_t));
            pst->suiv->prec = pst;
            pst->data = m_buf.pch + offset;
            pst->ndata = pos - offset;
            pst->type = TEMP_HTML;
            pst = pst->suiv;
            offset = pos;

            pos += 4;   
            
            while (isspace(m_buf.pch[pos]))
                pos ++;

            int nlen = 0;
            char token[TNOM + 1] = {0};
            while (m_buf.pch[pos] != '-' && m_buf.pch[pos] != '>'
                && !isspace(m_buf.pch[pos]) && nlen < TNOM)
            {
                token[nlen++] = m_buf.pch[pos];
                pos++;
            }
            
            token[nlen] = '\0';
            
            while (isspace(m_buf.pch[pos]))
                pos++;
            
            nlen = 0;
            char name[TNOM + 1] = {0};
            while (m_buf.pch[pos] != '-' && m_buf.pch[pos] != '>'
                && !isspace(m_buf.pch[pos]) && nlen < TNOM)
            {
                name[nlen++] = m_buf.pch[pos];
                pos++;
            }
            
            name[nlen] = '\0';

            while (!(m_buf.pch[pos] == '>' || m_buf.pch[pos] == '#'))
                pos++;

            int type = -1;

            if (strcmp(token, "#BeginBlock") == 0)
                type = TEMP_BEGINBLOCK;
            else if(strcmp(token, "#EndBlock") == 0)
                type = TEMP_ENDBLOCK;

            if (type != -1)
            {
                pst->suiv = (tpl_block_t *)malloc(sizeof(tpl_block_t));
                assert(NULL != pst->suiv);
                bzero(pst->suiv, sizeof(tpl_block_t));
                pst->type = type;
                pst->suiv->prec = pst;
                pst->name = strdup(name);

                assert(NULL != pst->name);

                if(TEMP_BEGINBLOCK == type)
                {
                    m_blocktable.pst = (tpl_ptr_t *)realloc(m_blocktable.pst,
                            sizeof(tpl_ptr_t) * (m_blocktable.nlength + 1));

                    assert(NULL != m_blocktable.pst);

                    m_blocktable.pst[m_blocktable.nlength].name = strdup(name);

                    assert(NULL != m_blocktable.pst[m_blocktable.nlength].name);

                    m_blocktable.pst[m_blocktable.nlength].block = pst;
                    m_blocktable.nlength++;
                }
          
                pst = pst->suiv;
            }
            else
            {
                /* the whole block is taken for html */
                pst->suiv = (tpl_block_t *)malloc(sizeof(tpl_block_t));
                assert(NULL != pst->suiv);
                bzero(pst->suiv, sizeof(tpl_block_t));
                pst->suiv->prec = pst;
                pst->data = m_buf.pch + offset;
                pst->ndata = pos - offset + 1;
                pst->type = TEMP_HTML;
                pst = pst->suiv;                
            }

            offset = pos + 1;
        }

        pos++;
    }

    if (offset < m_buf.length)
    {
        pst->suiv = NULL;
        pst->data = m_buf.pch + offset;
        pst->ndata = m_buf.length - offset;
        pst->type = TEMP_HTML;
    }

    qsort(m_vartable.pst, m_vartable.nlength, sizeof(tpl_ptr_t), cmp_block);
    qsort(m_blocktable.pst, m_blocktable.nlength, sizeof(tpl_ptr_t), cmp_block);
}

void render()
{
    tpl_block_t         *pst = m_head;
    char                *ptr = NULL;

    while(pst != NULL)
    {
        if(pst->type == TEMP_BEGINBLOCK)
        {
            char *pch = strdup(pst->name);

            assert(NULL != pch);

            pst = pst->suiv;

            while (pst && !(pst->type == TEMP_ENDBLOCK && strcmp(pst->name, pch) == 0))             
                pst = pst->suiv;

            if(pch != NULL)
            {
                free(pch);
                pch = NULL;
            }
        }
        
        if(pst && (pst->type == TEMP_HTML || pst->type == TEMP_VAR))
        {
            if(NULL != pst->data && pst->ndata != 0)
            {
                ptr = (char *)malloc(pst->ndata + 1);
                assert(NULL != ptr);
                memcpy(ptr, pst->data, pst->ndata);
                ptr[pst->ndata] = '\0';

                result = (char *)realloc(result, length + pst->ndata + 1);
                memcpy(result + length, pst->data, pst->ndata);
                result[length + pst->ndata] = '\0';
                length += pst->ndata;

                free(ptr);
            }
        }

        if(pst == NULL)
            break;
        
        pst = pst->suiv;
    }
}

tpl_ptr_t * find(const char * elem,
                const quick_table_t *base,
                int(* cmpfunc)(const void *, const void *),
                int * nb)
{
    void        *ptr = NULL;
    int         pos = 0;
    
    *nb = 0;

    ptr = bsearch((const void *)elem, (void *)base->pst, base->nlength, sizeof(tpl_ptr_t), cmpfunc);
    if (!ptr)
        return NULL;

    pos = ((char *)ptr - (char *)base->pst) / sizeof(tpl_ptr_t);

    while(pos > 0 && cmpfunc(elem, (const void *)((char *)base->pst + (pos - 1 ) * sizeof(tpl_ptr_t))) == 0)
        pos--;

    while(pos + *nb < base->nlength && cmpfunc(elem, (const void *)((char *)base->pst + (pos + *nb) * sizeof(tpl_ptr_t))) == 0)
        (*nb)++;

    return((tpl_ptr_t *)(((char *)base->pst) + pos * sizeof(tpl_ptr_t)));
}

void set(const char * token, const char *  val)
{
    tpl_block_t         *pst;
    tpl_ptr_t           *result;
    int i, nb;

    result = find(token, &m_vartable, cmp_block_n, &nb);
    if (result)
    {
        for (i = 0; i < nb; i++)
        {
            pst = result[i].block;
            
            if(pst->data != NULL)
                free(pst->data);
            
            pst->data = strdup(val);

            assert(NULL != pst->data);

            pst->ndata = strlen(val);
        }
    }
}

void gen_block(tpl_block_t * curr, tpl_block_t * suiv)
{
    tpl_block_t *pst;

    pst = (tpl_block_t *)malloc(sizeof(tpl_block_t));
    assert(NULL != pst);
    memset(pst, 0, sizeof(tpl_block_t));

    if(curr->ndata != 0)
    {
        pst->data = (char *)malloc(curr->ndata);
        assert(NULL != pst->data);
        memcpy(pst->data, curr->data, curr->ndata);
        pst->ndata = curr->ndata;
        pst->alloc = 1;
        pst->type = TEMP_HTML;

        pst->prec = suiv->prec;
        if(suiv->prec)
            suiv->prec->suiv = pst;
        pst->suiv = suiv;
        suiv->prec = pst;
    }
}

void del_block(tpl_block_t * pst)
{
    pst->prec->suiv = pst->suiv;
    pst->suiv->prec = pst->prec;

    tpl_block_t * tmp = pst->prec;
    free(pst);

    pst = tmp;
}

void set_block(const char * block)
{
    tpl_block_t     *pst, *begin;
    int             i, nb;
    tpl_ptr_t       *result;


    result = find(block, &m_blocktable, cmp_block_n, &nb);
    if(result)
    {
        for (i = 0; i < nb; i++) 
        {
            pst = begin = result[i].block;
            pst = pst->suiv;

            //  we go through all the blocks till the corresponding ENDTABLE
            while (pst && !(pst->type == TEMP_ENDBLOCK && strcmp(pst->name, block) == 0))
            {
                if(pst->type == TEMP_BEGINBLOCK)
                {
                    char *pch = strdup(pst->name);

                    assert(NULL != pch);

                    pst = pst->suiv;
                    while (pst && !(pst->type == TEMP_ENDBLOCK && strcmp(pst->name, pch) == 0))
                        pst = pst->suiv;

                    if(NULL != pch)
                        free(pch);
                }
                else
                {
                    gen_block(pst, begin);

                    if(pst->alloc == 1)
                        del_block(pst);
                }

                if(pst == NULL)
                    break;

                pst = pst->suiv;
            }           
        }
    }
}

void release()
{
    tpl_block_t *pst, *tmp;
    
    pst = m_head;
    while (pst)
    {
        if (pst->name)  
            free(pst->name);
        
        if (pst->alloc && pst->data)
            free(pst->data);
        
        tmp = pst;
        pst = pst->suiv;

        free(tmp);
    }
    
    m_head = NULL;
    
    for(int i = 0; i < m_vartable.nlength; i++)
        free(m_vartable.pst[i].name);

    for(int i = 0; i < m_blocktable.nlength; i++)
        free(m_blocktable.pst[i].name);

    if (m_vartable.pst)
    {
        free(m_vartable.pst);
        bzero(&m_vartable, sizeof(quick_table_t));
    }
    
    if (m_blocktable.pst)
    {
        free(m_blocktable.pst);
        bzero(&m_blocktable, sizeof(quick_table_t));
    }
    

    if (m_buf.pch)
    {
        free(m_buf.pch);
        bzero(&m_buf, sizeof(buffer_t));
    }
}

static
int lload (lua_State *L) {
    size_t l;
    const char *filename = luaL_checklstring(L, 1, &l);
    load(filename);
    return 0;
}

static
int lset (lua_State *L) {
    size_t l1;
    size_t l2;
    const char *token = luaL_checklstring(L, 1, &l1);
    const char *val = luaL_checklstring(L, 2, &l2);
    set(token, val);
    return 0;
}

static
int lset_block (lua_State *L) {
    size_t l;
    const char *block = luaL_checklstring(L, 1, &l);
    set_block(block);
    return 0;
}

static
int lrender (lua_State *L) {
    render();
    lua_pushlstring(L, result, length);
    free(result);
    return 1;
}

int
luaopen_webpage(lua_State *L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{ "load", lload },
		{ "set", lset },
		{ "set_block", lset_block },
		{ "render", lrender },
		{ NULL, NULL },
	};

	luaL_newlib(L,l);

	return 1;
}
