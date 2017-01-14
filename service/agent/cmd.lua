local skynet = require "skynet"
local notify = require 'notify'
local session_lock = require 'session_lock'
local Timer = require 'timer'
local date = require 'date'
local env = require 'env'

local M = {}

function M.verify(name)
    if not env.role and name ~= 'load_role' then
        return false
    end

    return true
end

function M.start(e)
    env.uid = e.uid
    env.subid = e.subid
    env.zinc_client = e.zinc_client

    if env.timer then
        env.timer:stop()
    end

    env.timer = Timer(10)

    if not e.uid then
        LOG_ERROR("msgagent start fail, no uid")
        return false
    end

    env.session_lock = session_lock()

    LOG_INFO('msgagent start, uid<%s>', e.uid)
    return true
end

-- 0-成功下线 1-下线失败 2-已经下线
local alread_close = false
function M.close()
    local ok, msg = pcall(function()
        if alread_close then
            LOG_ERROR("msgagent has been offline!")
            return 2
        end

        skynet.fork(function()
            local ts = date.second()
            while true do
                local now = date.second()
                if now - ts > 300 then
                    LOG_ERROR("msgagent close failed in 5 mins")
                    if env.role then
                        env.role:save_db()
                    end

                    LOG_ERROR("msgagent force offline!")
                    break
                end
                skynet.sleep(5*100)
            end
        end)
        alread_close = true

        if env.role then
            if not env.role:offline() then
                LOG_ERROR("msgagent offline failed!")
                return 1
            end
        end

        LOG_ERROR("msgagent offline succed!")
        return 0
    end)

    return ok
end


function M.query_proto_info()
    skynet.retpack(env.role:gen_proto())
end

return M
