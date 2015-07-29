local Skynet = require 'skynet'
local Config = require 'config'
local Mongo = require "mongo"
local MongoObj = require 'mongo_obj'

local db

local CMD = {}

function CMD.insert(tname, db_tbl)
    Skynet.retpack(db:insert(tname, db_tbl))
end

function CMD.update(tname, selector_tbl, db_tbl, upsert, multi)
    Skynet.retpack(db:update(tname, selector_tbl, db_tbl, upsert, multi))
end

function CMD.delete(tname, selector_tbl)
    Skynet.retpack(db:delete(tname, selector_tbl))
end

function CMD.find(tname, selector_tbl, field_selector_tbl)
    local c = db:find(tname, selector_tbl, field_selector_tbl)
    local items = {}
    while c:hasNext() do
        table.insert( items, c:next() )
    end
    Skynet.retpack( items )
end

function CMD.find_one(tname, selector_tbl, field_selector_tbl)
    Skynet.retpack(db:find_one(tname, selector_tbl, field_selector_tbl))
end

function CMD.get_role_count()
    local c = db:find("role", {}, {})
    return Skynet.retpack(c:count())
end

local function get_mongodb(name)
    local mdb_file = Skynet.getenv('database')
    local mdb_cfg = Config(mdb_file)
    local db_cfg = mdb_cfg[name] 
    if not db_cfg then
        return nil
    end
    return db_cfg
end

local function init_db()
    local db_cfg = get_mongodb('gamedb')
    if not db_cfg then
        error("no gamedb cfg!")
    end

    db = MongoObj.new(db_cfg)
end

local function init_index()
    local role = db._db['role']
    --给role集合建立索引
    role:ensureIndex( { account = 1 },{ } )
    role:ensureIndex( { uid = 1 }, { unique = true } )
    role:ensureIndex( { uuid = 1 }, { unique = true } )

    --给mailbox集合建立索引
    local mailbox = db._db['mailbox']
    mailbox:ensureIndex( { role_uuid = 1 }, { unique = true } )
end

Skynet.start(function()
    init_db()
    init_index()

    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(CMD[cmd])
        f(...)
    end)

    Skynet.register(".gamedb")
    LOG_INFO("gamedb service booted")
end)

